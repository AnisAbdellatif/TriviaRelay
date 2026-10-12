import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trivia_relay/core/api/relay_api.dart';
import 'package:trivia_relay/core/connection/seat_connection.dart';
import 'package:trivia_relay/core/models/models.dart';
import 'package:trivia_relay/core/providers/account_providers.dart';
import 'package:trivia_relay/core/providers/connection_providers.dart';
import 'package:trivia_relay/features/game/game_screen.dart';
import 'package:trivia_relay/shared/theme/fz_theme.dart';
import 'package:trivia_relay/shared/widgets/countdown.dart';
import 'package:trivia_relay/shared/widgets/fz.dart';
import 'package:trivia_relay/shared/widgets/game_top_bar.dart';

import '../support/app.dart';
import '../support/fake_seat_connection.dart';
import '../support/protocol_fixtures.dart';
import '../support/pump.dart';

const _account = SporcleAccount(
  playerId: 'p1',
  token: 't0k3n',
  handle: 'Player',
  deviceId: 'd1',
);

class _SignedIn extends Account {
  @override
  Future<SporcleAccount?> build() async => _account;
}

/// A signed-in player and a relay that seats anybody who joins, as `s2`;
/// [requests] gets each request as "METHOD /path body".
List _relay(List<String> requests) => [
  accountProvider.overrideWith(_SignedIn.new),
  relayApiProvider.overrideWithValue(
    RelayApi(
      baseUrl: 'https://relay.example',
      client: MockClient((request) async {
        final body = jsonDecode(request.body) as Map;
        requests.add(
          '${request.method} ${request.url.path} '
          '${jsonEncode({'code': body['code']})}',
        );
        return http.Response(
          jsonEncode({
            'seat_id': 's2',
            'seat_token': 'tok2',
            'game_code': body['code'],
          }),
          201,
        );
      }),
    ),
  ),
];

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
        matching: find.text('germany'),
      ),
      findsOneWidget,
      reason:
          "once you've answered, everybody's guess shows, as written, as it "
          'does in the official app',
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

    // Each guess is a switch while the host marks.
    expect(find.byKey(const ValueKey('mark-1')), findsOneWidget);
    await tapKey(tester, const ValueKey('mark-1'));
    expect(connection.calls, contains('judge:1:true'));

    await tapKey(tester, const Key('confirmMarksButton'));
    expect(connection.calls, contains('judge_submit'));
    connection.emit(
      ProtocolFixtures.snapshot('reveal_host').copyWith.you(judged: true),
    );
    await settle(tester);

    // Once marked, moving on asks nothing.
    await tapKey(tester, const Key('nextButton'));
    expect(find.byType(AlertDialog), findsNothing);
    expect(connection.calls, containsAllInOrder(['judge_submit', 'next']));
  });

  testWidgets('moving on before the marks are confirmed asks first', (
    tester,
  ) async {
    final connection = await show(tester, 'reveal_host');
    final confirm = tester.widget<FzButton>(
      find.byKey(const Key('confirmMarksButton')),
    );
    expect(
      confirm.kind,
      FzButtonKind.primary,
      reason: 'confirming the marks is the main action while they are open',
    );

    await tapKey(tester, const Key('nextButton'));
    expect(find.text('Skip scoring this question?'), findsOneWidget);
    await tester.tap(find.text('Go back'));
    await settle(tester);
    expect(connection.calls, isNot(contains('next')));

    await tapKey(tester, const Key('nextButton'));
    await tapKey(tester, const Key('confirmSkipButton'));
    expect(connection.calls, contains('next'));
    expect(connection.calls, isNot(contains('judge_submit')));
  });

  testWidgets(
    'a mark shows at once, and the switch reads as one with its row',
    (tester) async {
      final handle = tester.ensureSemantics();
      final connection = await show(tester, 'reveal_host')
        ..holdIntents = Completer();
      await tester.tap(find.byKey(const ValueKey('mark-2')));
      await tester.pump();
      expect(
        tester.widget<Switch>(find.byKey(const ValueKey('mark-2'))).value,
        isTrue,
        reason: 'the mark sent shows before the relay answers',
      );
      expect(
        tester.getSemantics(find.byKey(const ValueKey('guess-2'))),
        matchesSemantics(
          label: 'Joiner\ngermany\nWAGER 1\nMarked right',
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      connection.holdIntents!.complete();
      await settle(tester);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    },
  );

  testWidgets('a player waits while the host marks', (tester) async {
    await show(tester, 'reveal_judged_player');
    expect(find.byKey(const Key('confirmMarksButton')), findsNothing);
    expect(find.byKey(const Key('nextButton')), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('the vote cast shows chosen, not greyed out', (tester) async {
    final handle = tester.ensureSemantics();
    final vote = ProtocolFixtures.snapshot('final_vote_player');
    final connection = FakeSeatConnection()
      ..emit(
        vote.copyWith(
          finalRound: vote.finalRound!.copyWith(
            vote: 'hard',
            votes: {'hard': 1},
          ),
        ),
      );
    await pumpApp(tester, const GameScreen(), connection: connection);

    final hard = tester.widget<FzButton>(find.byKey(const Key('vote-hard')));
    expect(hard.selected, isTrue);
    expect(
      find.descendant(
        of: find.byKey(const Key('vote-hard')),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
    final fill = tester
        .widget<FilledButton>(
          find.descendant(
            of: find.byKey(const Key('vote-hard')),
            matching: find.byType(FilledButton),
          ),
        )
        .style!
        .backgroundColor!
        .resolve({WidgetState.disabled});
    expect(fill, FzColors.ac2, reason: 'drawn in Flare, not disabled grey');
    expect(
      tester.getSemantics(find.byKey(const Key('vote-hard'))),
      matchesSemantics(
        isSelected: true,
        hasSelectedState: true,
        isButton: true,
        hasEnabledState: true,
        label: 'Hard\nyour vote',
      ),
    );
    await tapKey(tester, const Key('vote-easy'));
    expect(connection.calls, isEmpty, reason: 'one vote only');
    handle.dispose();
  });

  testWidgets('an answer being sent shows as locking, and takes one tap', (
    tester,
  ) async {
    final connection = await show(tester, 'question_player')
      ..holdIntents = Completer();
    await tester.enterText(find.byKey(const Key('answerField')), 'india');
    await settle(tester);
    connection.holdIntents = Completer();
    await tester.tap(find.byKey(const Key('submitAnswerButton')));
    await tester.pump();
    expect(find.text('Locking…'), findsOneWidget);
    await tester.tap(find.byKey(const Key('submitAnswerButton')));
    await tester.pump();
    expect(
      connection.calls.where((c) => c.startsWith('answer:')),
      hasLength(1),
    );

    connection.holdIntents!.complete();
    await settle(tester);
    // Accepted: it waits for the snapshot that shows it, then lets go.
    connection.emit(ProtocolFixtures.snapshot('question_player'));
    await settle(tester);
    expect(find.text('Locking…'), findsNothing);
  });

  testWidgets('a refused answer is shown clear of the answer button', (
    tester,
  ) async {
    final connection = await show(tester, 'question_player')
      ..intentError = null;
    await tester.enterText(find.byKey(const Key('answerField')), 'india');
    await settle(tester);
    connection.intentError = const GameError(code: 'already_answered');
    await tapKey(tester, const Key('submitAnswerButton'));
    final toast = find.text('You already answered.');
    expect(toast, findsOneWidget);
    expect(
      tester
          .getRect(toast)
          .overlaps(
            tester.getRect(find.byKey(const Key('submitAnswerButton'))),
          ),
      isFalse,
    );
    expect(find.text('Lock it in'), findsOneWidget);
  });

  testWidgets('a short clock turns red for its last third only', (
    tester,
  ) async {
    expect(Countdown.warningSecondsFor(15000), 5);
    expect(Countdown.warningSecondsFor(60000), 10);
    expect(Countdown.warningSecondsFor(null), 10);
  });

  testWidgets("at zero the clock says so, and the field closes", (
    tester,
  ) async {
    var now = fixtureNow;
    final connection = FakeSeatConnection()
      ..emit(ProtocolFixtures.snapshot('question_player'));
    await pumpApp(
      tester,
      const GameScreen(),
      connection: connection,
      clock: () => DateTime.fromMillisecondsSinceEpoch(now),
    );
    await tester.enterText(find.byKey(const Key('answerField')), 'ind');
    now = fixtureNow + 15500;
    await settle(tester);
    expect(find.text("Time's up"), findsWidgets);
    expect(
      tester.widget<TextField>(find.byKey(const Key('answerField'))).readOnly,
      isTrue,
    );
    expect(
      connection.calls,
      contains('draft:ind:5'),
      reason: 'what was typed went to the relay before it answers for you',
    );
    expect(
      tester
          .widget<FzButton>(find.byKey(const Key('submitAnswerButton')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('the host is told when Reveal opens', (tester) async {
    final connection = FakeSeatConnection()
      ..emit(
        ProtocolFixtures.snapshot('question_host_answered').copyWith
            .you(canReveal: false),
      );
    await pumpApp(tester, const GameScreen(), connection: connection);
    expect(find.byKey(const Key('revealHint')), findsOneWidget);
    expect(
      find.textContaining('5 seconds after time runs out'),
      findsOneWidget,
    );
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

  testWidgets('removed by the host: may join again, with the code', (
    tester,
  ) async {
    final connection = await show(tester, 'question_player');
    connection.closedCompleter.complete(SeatClosedReason.removed);
    await settle(tester);
    expect(find.text('You were removed'), findsOneWidget);
    expect(find.textContaining('join it again with the code'), findsOneWidget);
  });

  testWidgets('kicked by the host: not shown as a lost connection', (
    tester,
  ) async {
    final connection = await show(tester, 'question_player');
    connection.closedCompleter.complete(SeatClosedReason.kicked);
    await settle(tester);
    expect(find.text('You were kicked'), findsOneWidget);
    expect(find.textContaining("won't let you back in"), findsOneWidget);
    expect(find.textContaining('lost its connection'), findsNothing);
  });

  testWidgets('back goes home and keeps the seat; leave asks, then leaves', (
    tester,
  ) async {
    final connection = FakeSeatConnection()
      ..emit(ProtocolFixtures.snapshot('question_player'))
      ..holdLeave = Completer();
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            key: const Key('open'),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const GameScreen())),
            child: const Text('open'),
          ),
        ),
      ),
      connection: connection,
    );
    await tapKey(tester, const Key('open'));
    expect(find.byTooltip('Home. Your seat is held'), findsOneWidget);
    await tapKey(tester, const Key('backButton'));
    expect(find.byType(GameScreen), findsNothing);
    expect(connection.calls, isNot(contains('leave')));

    await tapKey(tester, const Key('open'));
    await tapKey(tester, GameTopBar.leaveKey);
    expect(find.text('Leave the game?'), findsOneWidget);
    await tapKey(tester, const Key('confirmLeaveButton'));
    expect(connection.calls, contains('leave'));
    expect(find.text('Leaving the game…'), findsOneWidget);
    connection.holdLeave!.complete();
    await settle(tester);
    expect(find.byType(GameScreen), findsNothing);
  });

  testWidgets('a long lobby label never takes more than a line', (
    tester,
  ) async {
    final lobby = ProtocolFixtures.snapshot('lobby_host');
    final connection = FakeSeatConnection()
      ..emit(
        lobby.copyWith(
          pack: lobby.pack!.copyWith(name: 'A very long pack name ' * 6),
        ),
      );
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await pumpApp(
      tester,
      const GameScreen(),
      connection: connection,
      size: const Size(320, 568),
    );
    expect(find.text('LOBBY'), findsOneWidget);
    expect(find.text('GAME ${lobby.gameCode}'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a lost game says so, holds still, and offers to rejoin', (
    tester,
  ) async {
    final requests = <String>[];
    final connection = FakeSeatConnection()
      ..emit(
        ProtocolFixtures.snapshot('question_player')
            .copyWith(status: SeatStatus.lost),
      );
    await pumpApp(
      tester,
      const GameScreen(),
      connection: connection,
      overrides: _relay(requests),
    );
    expect(find.byKey(const Key('lostBanner')), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byKey(const Key('answerField'))).readOnly,
      isTrue,
    );
    await tester.enterText(find.byKey(const Key('answerField')), 'india');
    expect(
      tester
          .widget<FzButton>(find.byKey(const Key('submitAnswerButton')))
          .onPressed,
      isNull,
    );

    await tapKey(tester, const Key('rejoinButton'));
    expect(requests, ['POST /api/seats {"code":"624949"}']);
    expect(connection.calls, contains('attach:s2'));
  });

  testWidgets('removed: join again with the known code', (tester) async {
    final requests = <String>[];
    final connection = FakeSeatConnection()
      ..emit(ProtocolFixtures.snapshot('question_player'));
    await pumpApp(
      tester,
      const GameScreen(),
      connection: connection,
      overrides: _relay(requests),
    );
    connection.closedCompleter.complete(SeatClosedReason.removed);
    await settle(tester);
    expect(find.byType(GameTopBar), findsNothing, reason: 'no pack, no X');
    await tapKey(tester, const Key('joinAgainButton'));
    expect(requests, ['POST /api/seats {"code":"624949"}']);
    expect(connection.calls, contains('attach:s2'));
  });

  testWidgets('kicked or left: no joining again', (tester) async {
    for (final reason in [SeatClosedReason.kicked, SeatClosedReason.left]) {
      final connection = FakeSeatConnection()
        ..emit(ProtocolFixtures.snapshot('question_player'));
      await pumpApp(tester, const GameScreen(), connection: connection);
      connection.closedCompleter.complete(reason);
      await settle(tester);
      expect(find.byKey(const Key('joinAgainButton')), findsNothing);
      expect(find.byKey(const Key('homeButton')), findsOneWidget);
    }
  });

  testWidgets('a seat taken elsewhere says it moved', (tester) async {
    final connection = await show(tester, 'lobby_host');
    connection.closedCompleter.complete(SeatClosedReason.moved);
    await settle(tester);
    expect(find.text('Your seat moved to another device'), findsOneWidget);
    expect(find.byKey(const Key('joinAgainButton')), findsNothing);
  });

  testWidgets('let go for another app: says so, and waits to be asked', (
    tester,
  ) async {
    final connection = await show(tester, 'lobby_host');
    connection.emitStatus(ConnectionStatus.displaced);
    await settle(tester);
    expect(find.text('Open on other devices'), findsOneWidget);
    expect(find.byKey(const Key('readyButton')), findsNothing);
    expect(connection.calls, isEmpty, reason: 'never rejoins by itself');
  });

  testWidgets('copying the code says so', (tester) async {
    final copied = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') copied.add(call.arguments);
        return null;
      },
    );
    await show(tester, 'lobby_host');
    await tapKey(tester, const Key('copyCodeButton'));
    expect(find.text('Code copied.'), findsOneWidget);
    await tapKey(tester, const Key('shareInviteButton'));
    expect(find.textContaining('Invite copied'), findsOneWidget);
    expect(copied, [
      {'text': '624949'},
      {
        'text':
            'Join my Trivia Relay game: http://localhost:4100/join/624949 '
            '(code 624949)',
      },
    ]);
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
