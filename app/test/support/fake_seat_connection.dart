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
  Future<void> start() => _record('start');
  @override
  Future<void> options(HostOptions options) => _record(
    'options:${options.questionsPerGame}:${options.questionSeconds}:'
    '${options.audience.name}',
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
  Future<void> playAgain() => _record('play_again');
  @override
  Future<void> leave() async {
    calls.add('leave');
    if (!closedCompleter.isCompleted) {
      closedCompleter.complete(SeatClosedReason.left);
    }
  }

  @override
  Future<void> dispose() async => calls.add('dispose');
}
