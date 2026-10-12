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

  /// A thumb on the question on screen: 1 up, -1 down, 0 neither (since 1.2).
  Future<void> rate(int rating);

  /// Reports the question on screen, for one of [GameRules.reportReasons]
  /// (since 1.2).
  Future<void> report(String reason);

  /// A vote for a lobby pack somebody already voted for, or taking one's own
  /// back (since 1.2). A pack nobody voted for yet is voted for over HTTP,
  /// like the host's change of pack.
  Future<void> packVote(int packId, {required bool vote});

  // The host's (§4.2).
  Future<void> start();
  Future<void> options(HostOptions options);
  Future<void> reveal();
  Future<void> judge(int peerId, bool correct);
  Future<void> judgeSubmit();
  Future<void> next();

  /// Takes [peerId] out of the game: for good ([ban], "Kick"), or free to
  /// join again (since 1.2).
  Future<void> remove(int peerId, {required bool ban});

  /// Hands the host to [peerId] (since 1.2).
  Future<void> makeHost(int peerId);

  /// Everyone back to the lobby, from anywhere in a game (since 1.2).
  Future<void> toLobby();

  Future<void> playAgain();

  /// This app shows the game's chat ([chatClose]: no longer). The relay has
  /// the chat open with the game while any app shows it (since 1.2).
  Future<void> chatOpen();
  Future<void> chatClose();

  /// A message to everyone in the game (since 1.2).
  Future<void> chatSend(String text);

  /// The player started or stopped typing in the chat (since 1.2).
  Future<void> chatTyping(bool typing);

  /// Earlier chat messages (since 1.2).
  Future<void> chatMore();

  /// A reaction sound to [peerId]: one of [GameRules.reactionTypes], the
  /// goose (the honk) by default (since 1.2).
  Future<void> react(int peerId, {String type = 'goose'});

  /// Leaves the game: the seat closes, and the relay leaves Sporcle.
  Future<void> leave();

  /// Stops listening without leaving: the relay holds the seat.
  Future<void> dispose();
}

enum ConnectionStatus {
  connecting,
  connected,
  reconnecting,
  disconnected,

  /// The relay closed this app's channel while the seat goes on: more apps
  /// joined the seat than it takes, and this one had joined first
  /// (protocol/PROTOCOL.md §3.3). Final for this connection, and not retried,
  /// or two phones would take the seat from each other forever.
  displaced,
}

/// Why a seat ended (protocol/PROTOCOL.md §5.2), plus [notFound] for a seat
/// that was already gone when the app came back to it.
enum SeatClosedReason {
  left,
  expired,

  /// The host removed the player, who may join the game again.
  removed,

  /// The host removed the player for good: Sporcle won't let them back in.
  kicked,

  /// The player took another seat, on this app or another (`left` with
  /// `replaced`, since 1.2).
  moved,
  shutdown,
  notFound,
}
