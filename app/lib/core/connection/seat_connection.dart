import 'dart:async';

import '../models/models.dart';

/// The app's connection to its seat on the relay (protocol/PROTOCOL.md §4–5).
/// Providers and screens depend on this, never on the transport.
///
/// One instance serves one seat: [attach] once, then [leave] (the seat leaves
/// the Sporcle game) or [dispose] (the app stops listening; the relay keeps the
/// seat for its hold, and attaching again picks it up).
abstract class SeatConnection {
  /// Complete snapshots, the latest replayed to each new listener.
  Stream<SeatState> get state;

  Stream<ConnectionStatus> get status;

  /// Completes when the seat has ended, with why.
  Future<SeatClosedReason> get closed;

  Future<void> attach(SeatTicket ticket);

  Future<void> ready(bool ready);

  /// What is typed so far: the relay answers with it if time runs out.
  Future<void> draft(String text, int? wager);
  Future<void> answer(String text, int wager);
  Future<void> finalVote(String choice);
  Future<void> finalWager(int amount);

  // The host's (§4.2).
  Future<void> start();
  Future<void> options(HostOptions options);
  Future<void> reveal();
  Future<void> judge(int peerId, bool correct);
  Future<void> judgeSubmit();
  Future<void> next();
  Future<void> playAgain();

  /// Leaves the game: the seat closes, and the relay leaves Sporcle.
  Future<void> leave();

  /// Stops listening without leaving: the relay holds the seat.
  Future<void> dispose();
}

enum ConnectionStatus { connecting, connected, reconnecting, disconnected }

/// Why a seat ended (protocol/PROTOCOL.md §5.2), plus [notFound] for a seat
/// that was already gone when the app came back to it.
enum SeatClosedReason { left, expired, removed, shutdown, notFound }
