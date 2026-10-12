import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:phoenix_socket/phoenix_socket.dart';
import 'package:trivia_relay/core/connection/phoenix_seat_connection.dart';
import 'package:trivia_relay/core/connection/seat_connection.dart';
import 'package:trivia_relay/core/models/models.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../support/protocol_fixtures.dart';

/// The relay's end of one WebSocket, in V2 frames
/// (`[join_ref, ref, topic, event, payload]`): it answers heartbeats and
/// joins, and sends whatever a test tells it to.
class _Relay {
  final _toApp = StreamController<dynamic>();
  final frames = <List<dynamic>>[];
  bool closed = false;
  String? joinRef;
  String? topic;

  late final WebSocketChannel channel = _Channel(this);

  void _fromApp(dynamic data) {
    final frame = jsonDecode(data as String) as List<dynamic>;
    frames.add(frame);
    final [join, ref, topic, event, _] = frame;
    if (event == 'heartbeat' || event == 'phx_join') {
      if (event == 'phx_join') {
        joinRef = join as String?;
        this.topic = topic as String;
      }
      send([
        join,
        ref,
        topic,
        'phx_reply',
        {'status': 'ok', 'response': <String, dynamic>{}},
      ]);
    }
  }

  void send(List<dynamic> frame) => _toApp.add(jsonEncode(frame));

  /// A message on the joined seat's channel.
  void push(String event, Map<String, dynamic> payload) =>
      send([joinRef, null, topic, event, payload]);

  int get joins => frames.where((f) => f[3] == 'phx_join').length;
}

class _Channel implements WebSocketChannel {
  _Channel(this.relay);

  final _Relay relay;

  @override
  Stream<dynamic> get stream => relay._toApp.stream;

  @override
  WebSocketSink get sink => _Sink(relay);

  @override
  Future<void> get ready => Future.value();

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Sink implements WebSocketSink {
  _Sink(this.relay);

  final _Relay relay;

  @override
  void add(dynamic data) => relay._fromApp(data);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    relay.closed = true;
  }

  @override
  Future<void> get done => Future.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const ticket = SeatTicket(seatId: 's1', seatToken: 'tok', gameCode: '624949');

  Future<(PhoenixSeatConnection, _Relay, List<ConnectionStatus>)>
  attached() async {
    final relay = _Relay();
    final connection = PhoenixSeatConnection(
      baseUrl: 'http://relay.test',
      socketFactory: (endpoint) => PhoenixSocket(
        endpoint,
        webSocketChannelFactory: (_) => relay.channel,
      ),
    );
    final statuses = <ConnectionStatus>[];
    connection.status.listen(statuses.add);
    await connection.attach(ticket);
    await pumpEventQueue();
    return (connection, relay, statuses);
  }

  test('joins the seat with its token and the protocol major', () async {
    final (connection, relay, statuses) = await attached();
    final join = relay.frames.firstWhere((f) => f[3] == 'phx_join');
    expect(join[2], 'seat:s1');
    expect(join[4], {'seat_token': 'tok', 'protocol_version': 1});
    expect(statuses.last, ConnectionStatus.connected);
    await connection.dispose();
  });

  test(
    'a channel closed without seat_closed: displaced, and no rejoin',
    () async {
      final (connection, relay, statuses) = await attached();
      relay.push('state', ProtocolFixtures.load('snapshots/lobby_host.json'));
      await pumpEventQueue();
      expect(await connection.state.first, isA<SeatState>());

      relay.push('phx_close', {});
      await pumpEventQueue();

      expect(statuses.last, ConnectionStatus.displaced);
      expect(relay.closed, isTrue, reason: 'the socket is let go');
      expect(relay.joins, 1, reason: 'never joins again by itself');
      var ended = false;
      unawaited(connection.closed.then((_) => ended = true));
      await pumpEventQueue();
      expect(ended, isFalse, reason: 'the seat itself goes on');
      await connection.dispose();
    },
  );

  test('the chat and reactions go as the relay\'s intents', () async {
    final (connection, relay, _) = await attached();
    for (final intent in <Future<void> Function()>[
      connection.chatOpen,
      () => connection.chatSend('hi'),
      () => connection.chatTyping(true),
      connection.chatMore,
      () => connection.react(1),
      () => connection.react(3, type: 'clap'),
      connection.chatClose,
    ]) {
      unawaited(intent().catchError((Object _) {}));
    }
    await pumpEventQueue();
    final sent = [
      for (final f in relay.frames)
        if (f[3] != 'phx_join' && f[3] != 'heartbeat') [f[3], f[4]],
    ];
    expect(sent, [
      ['chat_open', <String, dynamic>{}],
      [
        'chat_send',
        {'text': 'hi'},
      ],
      [
        'chat_typing',
        {'typing': true},
      ],
      ['chat_more', <String, dynamic>{}],
      [
        'honk',
        {'peer_id': 1},
      ],
      [
        'react',
        {'peer_id': 3, 'type': 'clap'},
      ],
      ['chat_close', <String, dynamic>{}],
    ]);
    await connection.dispose();
  });

  test('seat_closed then the channel closing is the seat ending', () async {
    final (connection, relay, statuses) = await attached();
    relay
      ..push('seat_closed', {'reason': 'left', 'replaced': true})
      ..push('phx_close', {});
    expect(await connection.closed, SeatClosedReason.moved);
    await pumpEventQueue();
    expect(statuses, isNot(contains(ConnectionStatus.displaced)));
    await connection.dispose();
  });
}
