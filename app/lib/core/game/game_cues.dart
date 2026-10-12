import '../models/models.dart';

/// A moment of the game the app marks with a sound (and, on a phone, a buzz).
enum GameCue {
  /// The game begins: the lobby gives way to the first question.
  start,

  /// A question opens (the final one too).
  question,

  /// This player's answer is locked in.
  submit,

  /// The host revealed the question, and this player got it right.
  correct,

  /// The host revealed the question, and this player got it wrong.
  wrong,

  /// One of the last seconds of a question this player hasn't answered.
  tick,
}

/// How many of the last seconds tick.
const tickSeconds = 5;

/// What the change from snapshot [before] to [after] calls for, from nothing
/// to a couple of cues, in order.
///
/// Only changes: the first snapshot of a seat ([before] null, or another
/// game's) is where the player came in, and marks nothing, so opening the game
/// in the middle of a question doesn't sound as if it had just opened.
List<GameCue> cuesFor(SeatState? before, SeatState after) {
  if (before == null || before.gameCode != after.gameCode) return const [];
  final cues = <GameCue>[];

  final opened =
      after.phase.isOpenQuestion &&
      (!before.phase.isOpenQuestion ||
          before.question?.index != after.question?.index);
  if (opened) {
    cues.add(before.phase == Phase.lobby ? GameCue.start : GameCue.question);
  } else if (after.phase.isOpenQuestion &&
      before.you.answer == null &&
      after.you.answer != null) {
    cues.add(GameCue.submit);
  }

  final revealed =
      after.phase.isReveal &&
      (!before.phase.isReveal ||
          before.question?.index != after.question?.index);
  if (revealed) {
    final mine = _myAnswer(after);
    if (mine != null) cues.add(mine.correct ? GameCue.correct : GameCue.wrong);
  }
  return cues;
}

/// The whole seconds left to answer the open question, while this player
/// hasn't: 1 in its last second, 0 once time is up. Null when there is nothing
/// to count down for them.
int? secondsToAnswer(SeatState state, int serverNowMs) {
  final deadline = state.deadline;
  if (!state.phase.isOpenQuestion || deadline == null) return null;
  if (state.you.answer != null) return null;
  final left = deadline - serverNowMs;
  if (left <= 0) return 0;
  return (left + 999) ~/ 1000;
}

/// This player's answer in the reveal, if they gave one.
RevealAnswer? _myAnswer(SeatState state) {
  final me = state.you.peerId;
  if (me == null) return null;
  for (final answer in state.reveal?.answers ?? const <RevealAnswer>[]) {
    if (answer.peerId == me && (answer.text ?? '').trim().isNotEmpty) {
      return answer;
    }
  }
  return null;
}
