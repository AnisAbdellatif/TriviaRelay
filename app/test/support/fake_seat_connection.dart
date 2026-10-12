import 'dart:async';

import 'package:trivia_relay/core/connection/replay_latest.dart';
import 'package:trivia_relay/core/connection/seat_connection.dart';
import 'package:trivia_relay/core/models/models.dart';

/// A [SeatConnection] that records what the app asks of it, and says whatever
/// the test tells it to.
class FakeSeatConnection implements SeatConnection {
  final ReplayLatest<SeatState> _state = ReplayLatest<SeatState>();
  final ReplayLatest<ConnectionStatus> _status = ReplayLatest(
    ConnectionStatus.connected,
  );
  final Completer<SeatClosedReason> closedCompleter = Completer();

  /// Every call, as `name` or `name:args`.
  final List<String> calls = [];

  /// Thrown by the next intent, if set.
  GameError? intentError;

  /// While set and not complete, [leave] waits on it, as a slow relay would.
  Completer<void>? holdLeave;

  /// While set and not complete, every intent waits on it before answering.
  Completer<void>? holdIntents;

  void emit(SeatState state) => _state.add(state);
  void emitStatus(ConnectionStatus status) => _status.add(status);

  @override
  Stream<SeatState> get state => _state.stream;

  @override
  Stream<ConnectionStatus> get status => _status.stream;

  @override
  Future<SeatClosedReason> get closed => closedCompleter.future;

  Future<void> _record(String call) async {
    calls.add(call);
    final hold = holdIntents;
    if (hold != null && !call.startsWith('attach')) await hold.future;
    final error = intentError;
    intentError = null;
    if (error != null) throw error;
  }

  @override
  Future<void> attach(SeatTicket ticket) => _record('attach:${ticket.seatId}');
  @override
  Future<void> ready(bool ready) => _record('ready:$ready');
  @override
  Future<void> draft(String text, int? wager) => _record('draft:$text:$wager');
  @override
  Future<void> answer(String text, int wager) => _record('answer:$text:$wager');
  @override
  Future<void> finalVote(String choice) => _record('final_vote:$choice');
  @override
  Future<void> finalWager(int amount) => _record('final_wager:$amount');
  @override
  Future<void> rate(int rating) => _record('rate:$rating');
  @override
  Future<void> report(String reason) => _record('report:$reason');
  @override
  Future<void> packVote(int packId, {required bool vote}) =>
      _record('pack_vote:$packId:$vote');
  @override
  Future<void> start() => _record('start');
  @override
  Future<void> options(HostOptions options) => _record(
    'options:${options.questionsPerGame}:${options.questionSeconds}:'
    '${options.audience.name}:${options.spectate}',
  );
  @override
  Future<void> reveal() => _record('reveal');
  @override
  Future<void> judge(int peerId, bool correct) =>
      _record('judge:$peerId:$correct');
  @override
  Future<void> judgeSubmit() => _record('judge_submit');
  @override
  Future<void> next() => _record('next');
  @override
  Future<void> remove(int peerId, {required bool ban}) =>
      _record('remove:$peerId:$ban');
  @override
  Future<void> makeHost(int peerId) => _record('make_host:$peerId');
  @override
  Future<void> toLobby() => _record('to_lobby');
  @override
  Future<void> playAgain() => _record('play_again');
  @override
  Future<void> chatOpen() => _record('chat_open');
  @override
  Future<void> chatClose() => _record('chat_close');
  @override
  Future<void> chatSend(String text) => _record('chat_send:$text');
  @override
  Future<void> chatTyping(bool typing) => _record('chat_typing:$typing');
  @override
  Future<void> chatMore() => _record('chat_more');
  @override
  Future<void> react(int peerId, {String type = 'goose'}) =>
      _record('react:$peerId:$type');
  @override
  Future<void> leave() async {
    calls.add('leave');
    await holdLeave?.future;
    if (!closedCompleter.isCompleted) {
      closedCompleter.complete(SeatClosedReason.left);
    }
  }

  @override
  Future<void> dispose() async => calls.add('dispose');
}
