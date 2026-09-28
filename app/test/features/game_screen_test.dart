import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_relay/core/connection/seat_connection.dart';
import 'package:trivia_relay/core/models/models.dart';
import 'package:trivia_relay/features/game/game_screen.dart';

import '../support/app.dart';
import '../support/fake_seat_connection.dart';
import '../support/protocol_fixtures.dart';
import '../support/pump.dart';

void main() {
  Future<FakeSeatConnection> show(
    WidgetTester tester,
    String snapshot, {
    Size size = const Size(360, 740),
  }) async {
    final connection = FakeSeatConnection()
      ..emit(ProtocolFixtures.snapshot(snapshot));
    await pumpApp(
      tester,
      const GameScreen(),
      connection: connection,
      size: size,
    );
    return connection;
  }

  group('every snapshot renders without overflowing', () {
    for (final name in ProtocolFixtures.snapshotNames()) {
      for (final size in const [Size(360, 740), Size(1280, 800)]) {
        testWidgets('$name at ${size.width.toInt()}', (tester) async {
          await show(tester, name, size: size);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('a player answers with a wager left this game', (tester) async {
    final connection = await show(tester, 'question_player');
    expect(find.byKey(const Key('questionText')), findsOneWidget);
    expect(find.byKey(const Key('revealButton')), findsNothing);
    expect(find.byKey(const ValueKey('guess-1')), findsNothing);

    await tester.enterText(find.byKey(const Key('answerField')), 'india');
    await tapKey(tester, const Key('wager-3'));
    await tapKey(tester, const Key('submitAnswerButton'));

    expect(connection.calls, contains('answer:india:3'));
    expect(
      connection.calls.where((c) => c.startsWith('draft:')),
      isNotEmpty,
      reason:
          'what is typed goes to the relay, which sends it if time runs out',
    );
  });

  testWidgets('an answer that is in shows as locked, and the host can reveal', (
    tester,
  ) async {
    final connection = await show(tester, 'question_host_answered');
    expect(find.byKey(const Key('lockedIn')), findsOneWidget);
    expect(find.byKey(const Key('answerField')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('guess-2')),
        matching: find.textContaining('GERMANY'),
      ),
      findsOneWidget,
      reason:
          "once you've answered, everybody's guess shows, as it does in "
          'the official app',
    );
    await tapKey(tester, const Key('revealButton'));
    expect(connection.calls, contains('reveal'));
  });

  testWidgets('the host can reveal only when the relay allows it', (
    tester,
  ) async {
    final connection = FakeSeatConnection()
      ..emit(
        ProtocolFixtures.snapshot('question_host_answered').copyWith
            .you(canReveal: false),
      );
    await pumpApp(tester, const GameScreen(), connection: connection);
    await tester.tap(find.byKey(const Key('revealButton')));
    await tester.pump();
    expect(connection.calls, isNot(contains('reveal')));
  });

  testWidgets('the host marks guesses, confirms, and moves on', (tester) async {
    final connection = await show(tester, 'reveal_host');
    expect(find.text('الهند'), findsOneWidget);

    await tapKey(tester, const ValueKey('guess-2'));
    expect(connection.calls, contains('judge:2:true'));

    await tapKey(tester, const Key('confirmMarksButton'));
    await tapKey(tester, const Key('nextButton'));
    expect(connection.calls, containsAllInOrder(['judge_submit', 'next']));
  });

  testWidgets('a player waits while the host marks', (tester) async {
    await show(tester, 'reveal_judged_player');
    expect(find.byKey(const Key('confirmMarksButton')), findsNothing);
    expect(find.byKey(const Key('nextButton')), findsNothing);
  });

  testWidgets('the final round: vote, then wager', (tester) async {
    var connection = await show(tester, 'final_vote_player');
    for (final choice in ['easy', 'medium', 'hard']) {
      expect(find.byKey(Key('vote-$choice')), findsOneWidget);
    }
    await tapKey(tester, const Key('vote-hard'));
    expect(connection.calls, contains('final_vote:hard'));

    connection = await show(tester, 'final_wager_host');
    await tapKey(tester, const Key('finalWager-10'));
    await tapKey(tester, const Key('nextButton'));
    expect(connection.calls, containsAllInOrder(['final_wager:10', 'next']));
  });

  testWidgets('the final answer is staked with the final wager', (
    tester,
  ) async {
    await show(tester, 'final_question_player');
    expect(find.byKey(const Key('wager-1')), findsNothing);
    expect(find.textContaining('wager'), findsWidgets);
  });

  testWidgets('the final scores name the winner; the host can play again', (
    tester,
  ) async {
    final connection = await show(tester, 'final_scores_host');
    expect(find.text('Joiner wins'), findsOneWidget);
    await tapKey(tester, const Key('playAgainButton'));
    expect(connection.calls, contains('play_again'));
  });

  testWidgets('anybody can ask to play again, then waits for the host', (
    tester,
  ) async {
    final scores = ProtocolFixtures.snapshot('final_scores_host');
    final connection = FakeSeatConnection()
      ..emit(scores.copyWith.you(host: false));
    await pumpApp(tester, const GameScreen(), connection: connection);
    await tapKey(tester, const Key('playAgainButton'));
    expect(connection.calls, contains('play_again'));

    connection.emit(scores.copyWith.you(host: false, playedAgain: true));
    await settle(tester);
    expect(find.text('Waiting for the host'), findsOneWidget);
  });

  testWidgets('the lobby: the host starts, anybody readies', (tester) async {
    final connection = await show(tester, 'lobby_host');
    expect(find.text('624949'), findsOneWidget);
    await tapKey(tester, const Key('readyButton'));
    await tapKey(tester, const Key('startButton'));
    expect(connection.calls, containsAllInOrder(['ready:false', 'start']));

    await tapKey(tester, const Key('changePackButton'));
    expect(find.byKey(const Key('packSearchField')), findsOneWidget);
    expect(find.byKey(const Key('packList-popular')), findsOneWidget);
  });

  testWidgets("the relay's refusal is shown", (tester) async {
    final connection = await show(tester, 'lobby_host')
      ..intentError = const GameError(code: 'not_host');
    await tapKey(tester, const Key('startButton'));
    expect(find.text('Only the host can do that.'), findsOneWidget);
    expect(connection.calls, contains('start'));
  });

  testWidgets('a seat that ends says why', (tester) async {
    final connection = await show(tester, 'question_player');
    connection.closedCompleter.complete(SeatClosedReason.expired);
    await settle(tester);
    expect(find.text('Your seat was let go'), findsOneWidget);
  });

  testWidgets('a dropped connection is shown while it comes back', (
    tester,
  ) async {
    final connection = await show(tester, 'question_player');
    connection.emitStatus(ConnectionStatus.reconnecting);
    await settle(tester);
    expect(find.text('RECONNECTING…'), findsOneWidget);
  });
}
