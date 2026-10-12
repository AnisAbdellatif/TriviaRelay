import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_relay/core/game/game_cues.dart';
import 'package:trivia_relay/core/models/models.dart';

import '../support/protocol_fixtures.dart';

void main() {
  final lobby = ProtocolFixtures.snapshot('lobby_host');
  final question = ProtocolFixtures.snapshot('question_player');
  final answered = ProtocolFixtures.snapshot('question_host_answered');
  // Player 2 answered "germany", marked right; player 1 "nope", wrong.
  final revealRight = ProtocolFixtures.snapshot('reveal_judged_player');
  final revealWrong = ProtocolFixtures.snapshot('reveal_host');

  test('the first question after the lobby starts the game', () {
    expect(cuesFor(lobby, question), [GameCue.start]);
  });

  test('a later question opening is its own cue', () {
    final next = question.copyWith(
      question: question.question!.copyWith(index: 1),
    );
    expect(cuesFor(question, next), [GameCue.question]);
    expect(cuesFor(revealRight, question.copyWith(question: next.question)), [
      GameCue.question,
    ]);
  });

  test(
    'the first snapshot marks nothing: that is where the player came in',
    () {
      for (final state in [lobby, question, answered, revealRight]) {
        expect(cuesFor(null, state), isEmpty);
      }
      expect(
        cuesFor(lobby.copyWith(gameCode: '1111'), question),
        isEmpty,
        reason: 'another game',
      );
    },
  );

  test("the player's own answer locking in", () {
    final before = answered.copyWith(you: answered.you.copyWith(answer: null));
    expect(cuesFor(before, answered), [GameCue.submit]);
    expect(cuesFor(answered, answered), isEmpty, reason: 'only once');
  });

  test('the reveal says right or wrong for this player only', () {
    final waitingRight = question.copyWith(you: revealRight.you);
    expect(cuesFor(waitingRight, revealRight), [GameCue.correct]);

    final waitingWrong = answered.copyWith(you: revealWrong.you);
    expect(cuesFor(waitingWrong, revealWrong), [GameCue.wrong]);

    // A player who gave no answer hears nothing.
    final spectator = revealRight.copyWith(
      you: revealRight.you.copyWith(peerId: 9),
    );
    expect(cuesFor(question, spectator), isEmpty);
    // Nor again while the reveal goes on.
    expect(cuesFor(revealRight, revealRight), isEmpty);
  });

  test(
    'the countdown is only for a question this player has yet to answer',
    () {
      final deadline = question.deadline!;
      expect(secondsToAnswer(question, deadline - 15000), 15);
      expect(secondsToAnswer(question, deadline - 4200), 5);
      expect(secondsToAnswer(question, deadline - 1), 1);
      expect(secondsToAnswer(question, deadline), 0);
      expect(secondsToAnswer(answered, deadline - 3000), isNull);
      expect(secondsToAnswer(lobby, 0), isNull);
      expect(
        secondsToAnswer(
          question.copyWith(phase: Phase.reveal),
          deadline - 3000,
        ),
        isNull,
      );
    },
  );
}
