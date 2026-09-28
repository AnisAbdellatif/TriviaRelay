import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_relay/core/connection/phoenix_seat_connection.dart';
import 'package:trivia_relay/core/models/models.dart';

import '../support/protocol_fixtures.dart';

void main() {
  final constants = ProtocolFixtures.load('constants.json');

  test('the app speaks the relay\'s protocol major', () {
    final major = int.parse(
      (constants['protocol_version'] as String).split('.').first,
    );
    expect(PhoenixSeatConnection.protocolMajor, major);
  });

  test('the host options offered are the ones the relay allows', () {
    expect(
      HostOptions.questionsPerGameChoices,
      constants['questions_per_game'],
    );
    expect(HostOptions.questionSecondsChoices, constants['question_seconds']);
    expect(Audience.values.map((a) => a.name).toList(), constants['audiences']);
    expect(
      HostOptions.questionsPerGameChoices,
      contains(const HostOptions().questionsPerGame),
    );
    expect(const HostOptions().audience, Audience.private);
  });

  test('the pack lists are the relay\'s', () {
    expect(
      PackList.values.map((l) => l.name).toList(),
      constants['pack_lists'],
    );
  });

  test('the final vote offers what the relay takes', () {
    expect(FinalRound.voteChoices, constants['final_votes']);
  });

  group('every snapshot the relay sends parses', () {
    for (final name in ProtocolFixtures.snapshotNames()) {
      test(name, () => ProtocolFixtures.snapshot(name));
    }
  });

  test('a snapshot reads as the relay meant it', () {
    final reveal = ProtocolFixtures.snapshot('reveal_host');
    expect(reveal.phase, Phase.reveal);
    expect(reveal.you.host, isTrue);
    expect(reveal.question!.text, '🇮🇳');
    expect(reveal.reveal!.answer, 'الهند');
    expect(reveal.reveal!.answers.map((a) => a.text), ['nope', 'germany']);

    final open = ProtocolFixtures.snapshot('question_host_answered');
    expect(open.reveal, isNull, reason: 'hidden until the host reveals');
    expect(open.players.every((p) => p.answered), isTrue);
    expect(open.players.map((p) => p.guess), ['nope', 'germany']);
    expect(open.you.canReveal, isTrue, reason: 'everyone has answered');
    expect(
      ProtocolFixtures.snapshot('question_player').players.map((p) => p.guess),
      everyElement(isNull),
      reason: "nobody's guess before you've answered",
    );
    expect(open.you.answer, const OwnAnswer(text: 'nope', wager: 2));

    final wager = ProtocolFixtures.snapshot('final_wager_host');
    expect(wager.phase, Phase.finalWager);
    expect(wager.you.wagerChoices, constants['final_wagers']);
    expect(wager.finalRound!.picked, 'easy');

    final scores = ProtocolFixtures.snapshot('final_scores_host');
    expect(scores.standings.first.name, 'Joiner');
    expect(scores.standings.map((p) => p.score), [11, -20]);

    final finalQuestion = ProtocolFixtures.snapshot('final_question_player');
    expect(finalQuestion.question!.isFinal, isTrue);
  });
}
