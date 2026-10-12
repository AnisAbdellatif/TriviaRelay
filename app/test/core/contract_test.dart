import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_relay/core/connection/phoenix_seat_connection.dart';
import 'package:trivia_relay/core/connection/seat_connection.dart';
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

  test('the joinable game lists are the relay\'s', () {
    expect(
      GameList.values.map((l) => l.name).toList(),
      constants['game_lists'],
    );
  });

  test('a seat closed by the host says whether it may come back', () {
    SeatClosedReason closed(Map<String, dynamic> payload) =>
        PhoenixSeatConnection.reasonFrom(payload);
    expect(
      closed({'reason': 'removed', 'can_rejoin': true}),
      SeatClosedReason.removed,
    );
    expect(
      closed({'reason': 'removed', 'can_rejoin': false}),
      SeatClosedReason.kicked,
    );
    expect(
      closed({'reason': 'removed'}),
      SeatClosedReason.removed,
      reason: 'a 1.1 relay never said',
    );
    expect(
      closed({'reason': 'left', 'replaced': true}),
      SeatClosedReason.moved,
    );
    expect(
      closed({'reason': 'left', 'replaced': false}),
      SeatClosedReason.left,
    );
    expect(closed({'reason': 'left'}), SeatClosedReason.left);
    expect(closed({'reason': 'someday'}), SeatClosedReason.shutdown);
  });

  test('the final vote offers what the relay takes', () {
    expect(FinalRound.voteChoices, constants['final_votes']);
  });

  test("the game's rules are the relay's", () {
    expect(GameRules.answerMaxLength, constants['answer_max_length']);
    expect(GameRules.maxPackVotes, constants['max_pack_votes']);
    expect(GameRules.startCountdownMs, constants['start_countdown_ms']);
    expect(GameRules.finalCountdownMs, constants['final_countdown_ms']);
    expect(
      GameRules.reportReasons.keys.toList(),
      constants['question_report_reasons'],
    );
  });

  test('the chat and reactions are the relay\'s', () {
    expect(GameRules.chatMaxLength, constants['chat_max_length']);
    expect(GameRules.reactionTypes, constants['reaction_types']);
    expect(GameRules.reactionSounds, constants['reaction_sounds']);
    expect(GameRules.reactionGapMs, constants['reaction_gap_ms']);
    expect(GameRules.reactionMs, constants['reaction_ms']);
  });

  test('the chat, reactions and Poppers read as the relay meant them', () {
    final chat = ProtocolFixtures.snapshot('lobby_chat_player').chat;
    expect(chat.messages.map((m) => m.id), ['m1', 'm2', 'm3', 'm4']);
    expect(chat.messages.map((m) => m.own), [false, false, true, false]);
    expect(chat.messages[0].peerId, 1);
    expect(chat.messages[0].name, 'Host');
    expect(chat.messages[1].system, isTrue);
    expect(chat.messages[1].name, isNull);
    expect((chat.unread, chat.open, chat.hasMore), (1, false, false));
    expect(chat.typing, ['Host']);

    final reacted = ProtocolFixtures.snapshot('reveal_reactions_player');
    expect(reacted.reactions.single.type, 'goose');
    expect(reacted.reactions.single.peerId, 1);
    expect(reacted.player(2)!.reactions.total, 3);
    expect(reacted.player(2)!.reactions.recent, ['goose', 'clap', 'goose']);

    final spent = ProtocolFixtures.snapshot('question_popper_notice_player');
    expect(spent.you.poppers, 2);
    expect(spent.notice!.kind, Notice.popperSpent);
    expect(ProtocolFixtures.snapshot('lobby_host').you.poppers, isNull);
  });

  test('the snapshots of 1.2 read as the relay meant them', () {
    final votes = ProtocolFixtures.snapshot('lobby_player_votes');
    expect(votes.packVotes.map((v) => (v.pack.id, v.votes, v.you)), [
      (268682, 2, true),
      (1001, 1, false),
    ]);
    expect(votes.packVotes.first.voters, [1, 2]);

    final spectator = ProtocolFixtures.snapshot('question_spectator_host');
    expect(spectator.you.spectating, isTrue);
    expect(spectator.me!.spectating, isTrue);
    expect(spectator.playing.map((p) => p.peerId), [2]);
    expect(spectator.players.map((p) => p.guess), everyElement(isNull));

    final countdown = ProtocolFixtures.snapshot('question_countdown_player');
    expect(countdown.countdown!.kind, StartCountdown.start);
    expect(countdown.deadline, countdown.countdown!.until + 15000);

    final rejoined = ProtocolFixtures.snapshot('question_rejoined_player');
    expect(rejoined.you.answer, const OwnAnswer(text: 'france', wager: 2));
    expect(rejoined.you.wagerChoices, [3, 4, 5]);
    expect(rejoined.you.canRate, isTrue);

    final rated = ProtocolFixtures.snapshot('reveal_rated_player');
    expect((rated.you.rating, rated.you.reported), (1, true));

    final notice = ProtocolFixtures.snapshot('lobby_notice_player').notice!;
    expect((notice.kind, notice.level), (Notice.server, 'warn'));
    expect(notice.title, 'Scheduled maintenance');

    final left = ProtocolFixtures.snapshot('final_scores_left_behind_player');
    expect(left.finalRound!.nextGameCode, '771204');
    expect(left.players.map((p) => p.readyForNextGame), everyElement(isTrue));
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
