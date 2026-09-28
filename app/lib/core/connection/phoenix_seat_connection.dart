import 'dart:async';
import 'dart:developer' as developer;

import 'package:phoenix_socket/phoenix_socket.dart';

import '../models/models.dart';
import 'replay_latest.dart';
import 'seat_connection.dart';

/// [SeatConnection] over Phoenix channels (protocol/PROTOCOL.md §2, §4).
///
/// Reconnects and heartbeats are `phoenix_socket`'s, and every automatic
/// rejoin re-sends the channel's parameters: the seat token, which is the whole
/// of who this phone is. So a phone that drops comes back to the same seat,
/// and to a complete snapshot of everything it missed.
///
/// Adapted from FazouraParty's `PhoenixGameConnection`.
class PhoenixSeatConnection implements SeatConnection {
  PhoenixSeatConnection({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 15),
    PhoenixSocket Function(String endpoint)? socketFactory,
  }) : _socketFactory = socketFactory ?? PhoenixSocket.new;

  /// What this app sends as `protocol_version`: its major, which is the whole
  /// of the compatibility check (§1.1). A test holds it to constants.json.
  static const int protocolMajor = 1;

  static Map<String, dynamic> joinPayload(SeatTicket ticket) => {
    'seat_token': ticket.seatToken,
    'protocol_version': protocolMajor,
  };

  final String baseUrl;
  final Duration timeout;
  final PhoenixSocket Function(String endpoint) _socketFactory;

  final ReplayLatest<SeatState> _state = ReplayLatest<SeatState>();
  final ReplayLatest<ConnectionStatus> _status = ReplayLatest<ConnectionStatus>(
    ConnectionStatus.disconnected,
  );
  final Completer<SeatClosedReason> _closed = Completer<SeatClosedReason>();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  PhoenixSocket? _socket;
  PhoenixChannel? _channel;
  bool _attaching = false;
  bool _joined = false;
  bool _done = false;

  /// `<base>/socket/websocket?vsn=2.0.0` with an http→ws / https→wss scheme.
  static Uri socketUri(String baseUrl) {
    final base = Uri.parse(baseUrl);
    final scheme = switch (base.scheme) {
      'https' || 'wss' => 'wss',
      _ => 'ws',
    };
    var path = base.path;
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return base.replace(
      scheme: scheme,
      path: '$path/socket/websocket',
      queryParameters: const {'vsn': '2.0.0'},
    );
  }

  @override
  Stream<SeatState> get state => _state.stream;

  @override
  Stream<ConnectionStatus> get status => _status.stream;

  @override
  Future<SeatClosedReason> get closed => _closed.future;

  @override
  Future<void> attach(SeatTicket ticket) async {
    if (_done) throw StateError('This connection has ended.');
    if (_attaching || _joined) throw StateError('Already attached.');
    _attaching = true;
    _status.add(ConnectionStatus.connecting);

    final socket = _socketFactory(socketUri(baseUrl).toString());
    _socket = socket;
    _subscriptions
      ..add(socket.closeStream.listen((_) => _onSocketDown()))
      ..add(socket.errorStream.listen((_) => _onSocketDown()));

    try {
      try {
        await socket.connect().timeout(timeout);
      } on TimeoutException {
        throw const GameError(
          code: GameError.connectionFailed,
          message: 'Could not reach the relay.',
        );
      }

      final channel = socket.addChannel(
        topic: 'seat:${ticket.seatId}',
        parameters: joinPayload(ticket),
      );
      _channel = channel;
      _subscriptions.add(channel.messages.listen(_onChannelMessage));

      final PushResponse reply;
      try {
        reply = await channel.join().future.timeout(timeout);
      } on Object {
        throw const GameError(
          code: GameError.connectionFailed,
          message: 'The relay did not answer.',
        );
      }

      if (!reply.isOk) {
        final error = _errorFrom(reply.response);
        if (error.code == 'seat_not_found' || error.code == 'invalid_token') {
          _completeClosed(SeatClosedReason.notFound);
        }
        throw error;
      }

      _joined = true;
      _status.add(ConnectionStatus.connected);
    } catch (_) {
      _teardown();
      if (!_done) _status.add(ConnectionStatus.disconnected);
      rethrow;
    } finally {
      _attaching = false;
    }
  }

  @override
  Future<void> ready(bool ready) => _push('ready', {'ready': ready});

  @override
  Future<void> draft(String text, int? wager) =>
      _push('draft', {'text': text, 'wager': wager});

  @override
  Future<void> answer(String text, int wager) =>
      _push('answer', {'text': text, 'wager': wager});

  @override
  Future<void> finalVote(String choice) =>
      _push('final_vote', {'choice': choice});

  @override
  Future<void> finalWager(int amount) =>
      _push('final_wager', {'amount': amount});

  @override
  Future<void> start() => _push('start', const {});

  @override
  Future<void> options(HostOptions options) => _push('options', {
    'questions_per_game': options.questionsPerGame,
    'question_seconds': options.questionSeconds,
    'audience': options.audience.name,
  });

  @override
  Future<void> reveal() => _push('reveal', const {});

  @override
  Future<void> judge(int peerId, bool correct) =>
      _push('judge', {'peer_id': peerId, 'correct': correct});

  @override
  Future<void> judgeSubmit() => _push('judge_submit', const {});

  @override
  Future<void> next() => _push('next', const {});

  @override
  Future<void> playAgain() => _push('play_again', const {});

  @override
  Future<void> leave() async {
    if (_done) return;
    if (_joined) {
      try {
        await _push('leave', const {}).timeout(const Duration(seconds: 3));
      } on Object {
        // Best effort: without an answer the hold ends the seat anyway.
      }
    }
    _completeClosed(SeatClosedReason.left);
    await dispose();
  }

  @override
  Future<void> dispose() async {
    if (_done) return;
    _done = true;
    _teardown();
    _status.add(ConnectionStatus.disconnected);
    await _state.close();
    await _status.close();
  }

  Future<void> _push(String event, Map<String, dynamic> payload) async {
    final channel = _channel;
    if (channel == null || !_joined) {
      throw const GameError(
        code: GameError.notJoined,
        message: 'Not connected to the relay.',
      );
    }
    final PushResponse reply;
    try {
      reply = await channel.push(event, payload).future;
    } on ChannelTimeoutException {
      throw const GameError(
        code: GameError.timeout,
        message: 'The relay did not answer.',
      );
    } on Object {
      throw const GameError(
        code: GameError.connectionFailed,
        message: 'The connection to the relay was lost.',
      );
    }
    if (!reply.isOk) throw _errorFrom(reply.response);
  }

  void _onChannelMessage(Message message) {
    switch (message.event.value) {
      case 'state':
        try {
          _state.add(SeatState.fromJson(_asMap(message.payload)));
        } catch (error, stackTrace) {
          developer.log(
            'Ignoring malformed state payload',
            name: 'PhoenixSeatConnection',
            error: error,
            stackTrace: stackTrace,
          );
        }
      case 'seat_closed':
        _completeClosed(_reasonFrom(_asMap(message.payload)['reason']));
        _shutdown();
      default:
        final channel = _channel;
        if (_joined &&
            channel != null &&
            message.event.isChannelReply &&
            message.ref != null &&
            message.ref == channel.joinRef) {
          _onRejoinReply(PushResponse.fromMessage(message));
        }
    }
  }

  /// The reply to an automatic rejoin after a reconnect.
  void _onRejoinReply(PushResponse reply) {
    if (reply.isOk) {
      _status.add(ConnectionStatus.connected);
      return;
    }
    if (!reply.isError) return;
    final error = _errorFrom(reply.response);
    // The seat ended while this phone was away: it is gone for good, and
    // rejoining as anybody else would be wrong (§4.1).
    if (error.code == 'seat_not_found' || error.code == 'invalid_token') {
      _completeClosed(SeatClosedReason.notFound);
    }
    _shutdown();
  }

  void _onSocketDown() {
    if (_done || _closed.isCompleted) return;
    if (_joined) _status.add(ConnectionStatus.reconnecting);
  }

  void _completeClosed(SeatClosedReason reason) {
    if (!_closed.isCompleted) _closed.complete(reason);
  }

  void _shutdown() {
    _teardown();
    if (!_done) _status.add(ConnectionStatus.disconnected);
  }

  void _teardown() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _socket?.dispose();
    _socket = null;
    _channel = null;
    _joined = false;
  }

  static GameError _errorFrom(Object? response) {
    final map = _asMap(response);
    final code = map['code'];
    final message = map['message'];
    return GameError(
      code: code is String ? code : 'unknown_error',
      message: message is String ? message : null,
    );
  }

  static SeatClosedReason _reasonFrom(Object? reason) => switch (reason) {
    'left' => SeatClosedReason.left,
    'expired' => SeatClosedReason.expired,
    'removed' => SeatClosedReason.removed,
    _ => SeatClosedReason.shutdown,
  };

  static Map<String, dynamic> _asMap(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}
