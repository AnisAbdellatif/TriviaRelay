import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trivia_relay/core/api/relay_api.dart';
import 'package:trivia_relay/core/models/models.dart';
import 'package:trivia_relay/core/providers/account_providers.dart';
import 'package:trivia_relay/core/providers/connection_providers.dart';
import 'package:trivia_relay/features/game/game_screen.dart';
import 'package:trivia_relay/features/host/host_setup_screen.dart';
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

class _Seated extends CurrentSeat {
  @override
  Future<SeatTicket?> build() async =>
      const SeatTicket(seatId: 's1', seatToken: 'tok1', gameCode: '624949');
}

/// A signed-in player in seat `s1`, and a relay that answers every request;
/// [requests] gets each as "METHOD /path {body}", credentials left out.
List _relay(List<String> requests) => [
  accountProvider.overrideWith(_SignedIn.new),
  currentSeatProvider.overrideWith(_Seated.new),
  relayApiProvider.overrideWithValue(
    RelayApi(
      baseUrl: 'https://relay.example',
      client: MockClient((request) async {
        final body = Map<String, dynamic>.from(jsonDecode(request.body) as Map)
          ..remove('player');
        requests.add(
          '${request.method} ${request.url.path} ${jsonEncode(body)}',
        );
        if (request.url.path == '/api/seats/pack') {
          return http.Response('', 204);
        }
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
    SeatState state, {
    List overrides = const [],
    Size size = const Size(360, 740),
    DateTime Function()? clock,
  }) async {
    final connection = FakeSeatConnection()..emit(state);
    await pumpApp(
      tester,
      const GameScreen(),
      connection: connection,
      overrides: overrides,
      size: size,
      clock: clock,
    );
    return connection;
  }

  SeatState snapshot(String name) => ProtocolFixtures.snapshot(name);

  group('the smallest phone, text at twice its size', () {
    for (final name in ProtocolFixtures.snapshotNames()) {
      testWidgets('$name fits', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await show(tester, snapshot(name), size: const Size(320, 568));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the player menu and its questions fit', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await show(tester, snapshot('lobby_host'), size: const Size(320, 568));
      await tapKey(tester, const ValueKey('player-2'));
      expect(find.byKey(const Key('playerAction-kick')), findsOneWidget);
      await tapKey(tester, const Key('playerAction-kick'));
      expect(
        find.byKey(const Key('confirmPlayerActionButton')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets("the host's menu takes Leave when the bar is full", (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await show(tester, snapshot('reveal_host'), size: const Size(320, 568));
      expect(find.byKey(GameTopBar.leaveKey), findsNothing);
      await tapKey(tester, GameTopBar.menuKey);
      await tapKey(tester, const Key('leaveItem'));
      expect(find.text('Leave the game?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reporting a question fits', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await show(
        tester,
        snapshot('reveal_judged_player'),
        size: const Size(320, 568),
      );
      await tapKey(tester, const Key('reportQuestionButton'));
      expect(find.byKey(const Key('reportReason-typo')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('every new control is big enough and says what it is', () {
    for (final (name, host) in const [
      ('lobby_player_votes', false),
      ('lobby_player_votes', true),
      ('reveal_rated_player', false),
      ('question_spectator_host', true),
      ('lobby_notice_player', false),
    ]) {
      testWidgets('$name${host ? ' as host' : ''}', (tester) async {
        final handle = tester.ensureSemantics();
        final state = snapshot(name);
        await show(
          tester,
          host ? state.copyWith(you: state.you.copyWith(host: true)) : state,
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group("the host's player menu", () {
    for (final (action, call) in const [
      ('remove', 'remove:2:false'),
      ('kick', 'remove:2:true'),
      ('makeHost', 'make_host:2'),
    ]) {
      testWidgets('$action asks, then goes to the relay', (tester) async {
        final connection = await show(tester, snapshot('lobby_host'));
        await tapKey(tester, const ValueKey('player-2'));
        await tapKey(tester, Key('playerAction-$action'));
        expect(connection.calls, isNot(contains(call)), reason: 'asked first');
        await tapKey(tester, const Key('confirmPlayerActionButton'));
        expect(connection.calls, contains(call));
      });
    }

    testWidgets('a change of mind sends nothing', (tester) async {
      final connection = await show(tester, snapshot('lobby_host'));
      await tapKey(tester, const ValueKey('player-2'));
      await tapKey(tester, const Key('playerAction-kick'));
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(connection.calls.where((c) => c.startsWith('remove')), isEmpty);
    });

    testWidgets('opens from the standings too', (tester) async {
      final connection = await show(tester, snapshot('reveal_host'));
      await tapKey(tester, const ValueKey('standing-2'));
      await tapKey(tester, const Key('playerAction-remove'));
      await tapKey(tester, const Key('confirmPlayerActionButton'));
      expect(connection.calls, contains('remove:2:false'));
    });

    testWidgets('is only the host’s, on somebody else who is there', (
      tester,
    ) async {
      await show(tester, snapshot('reveal_judged_player'));
      await tester.tap(find.byKey(const ValueKey('standing-1')));
      await settle(tester);
      expect(find.byKey(const Key('playerAction-kick')), findsNothing);

      final lobby = snapshot('lobby_host');
      await show(
        tester,
        lobby.copyWith(
          players: [
            for (final p in lobby.players)
              p.peerId == 2 ? p.copyWith(connected: false) : p,
          ],
        ),
      );
      await tester.tap(find.byKey(const ValueKey('player-2')));
      await tester.tap(find.byKey(const ValueKey('player-1')));
      await settle(tester);
      expect(find.byKey(const Key('playerAction-kick')), findsNothing);
    });
  });

  group('back to the lobby', () {
    testWidgets('the host asks, then everyone goes', (tester) async {
      final connection = await show(tester, snapshot('reveal_host'));
      await tapKey(tester, GameTopBar.menuKey);
      await tapKey(tester, const Key('toLobbyItem'));
      expect(find.text('Return everyone to the lobby?'), findsOneWidget);
      await tapKey(tester, const Key('confirmToLobbyButton'));
      expect(connection.calls, contains('to_lobby'));
    });

    testWidgets('only the host has the menu, and not in the lobby', (
      tester,
    ) async {
      await show(tester, snapshot('reveal_judged_player'));
      expect(find.byKey(GameTopBar.menuKey), findsNothing);
      await show(tester, snapshot('lobby_host'));
      expect(find.byKey(GameTopBar.menuKey), findsNothing);
    });

    testWidgets('the others are told, for a moment', (tester) async {
      var now = fixtureNow;
      final lobby = snapshot('lobby_player_votes').copyWith(
        notice: const Notice(kind: Notice.toLobby, until: fixtureNow + 5000),
      );
      await show(
        tester,
        lobby,
        clock: () => DateTime.fromMillisecondsSinceEpoch(now),
      );
      expect(find.byKey(const Key('noticeBanner')), findsOneWidget);
      expect(find.text('The host returned everyone to the lobby.'), findsOne);

      now += 6000;
      await tester.pump(const Duration(seconds: 6));
      await settle(tester);
      expect(find.byKey(const Key('noticeBanner')), findsNothing);
    });
  });

  testWidgets("a message from the game shows in its words, and closes", (
    tester,
  ) async {
    await show(tester, snapshot('lobby_notice_player'));
    expect(find.text('Scheduled maintenance'), findsOneWidget);
    await tapKey(tester, const Key('closeNoticeButton'));
    expect(find.byKey(const Key('noticeBanner')), findsNothing);
  });

  group('hosting as a spectator', () {
    testWidgets('no answer to give; reveal once the players are in', (
      tester,
    ) async {
      final connection = await show(
        tester,
        snapshot('question_spectator_host'),
      );
      expect(find.byKey(const Key('answerField')), findsNothing);
      expect(find.byKey(const Key('submitAnswerButton')), findsNothing);
      expect(find.byKey(const Key('spectatingPanel')), findsOneWidget);
      expect(find.text('1 OF 1 ANSWERED'), findsOneWidget);
      expect(find.text('germany'), findsNothing, reason: 'not before reveal');
      await tapKey(tester, const Key('revealButton'));
      expect(connection.calls, contains('reveal'));
    });

    testWidgets('no vote and no wager in the final', (tester) async {
      final vote = snapshot('final_vote_player');
      await show(
        tester,
        vote.copyWith(
          you: vote.you.copyWith(spectating: true),
          finalRound: vote.finalRound!.copyWith(vote: null),
        ),
      );
      expect(
        tester.widget<FzButton>(find.byKey(const Key('vote-easy'))).onPressed,
        isNull,
      );
    });

    testWidgets('comes last in the standings, with no score, and never wins', (
      tester,
    ) async {
      final scores = snapshot('final_scores_host');
      await show(
        tester,
        scores.copyWith(
          players: [
            for (final p in scores.players)
              p.peerId == 2 ? p.copyWith(spectating: true, score: 99) : p,
          ],
        ),
      );
      expect(find.text('Joiner wins'), findsNothing);
      expect(find.textContaining('WATCHING'), findsOneWidget);
    });

    testWidgets('is chosen when creating the game', (tester) async {
      await pumpApp(tester, const HostSetupScreen());
      final before = tester.widget<SwitchListTile>(
        find.descendant(
          of: find.byKey(const Key('spectateSwitch')),
          matching: find.byType(SwitchListTile),
        ),
      );
      expect(before.value, isFalse);
      await tapKey(tester, const Key('spectateSwitch'));
      expect(
        tester
            .widget<SwitchListTile>(
              find.descendant(
                of: find.byKey(const Key('spectateSwitch')),
                matching: find.byType(SwitchListTile),
              ),
            )
            .value,
        isTrue,
      );
    });

    testWidgets('and changed in the lobby', (tester) async {
      final connection = await show(tester, snapshot('lobby_host'));
      await tapKey(tester, const Key('lobbySpectate'));
      expect(connection.calls, contains('options:5:15:private:true'));
    });
  });

  group('the start', () {
    testWidgets('with somebody not ready, the host is asked first', (
      tester,
    ) async {
      final lobby = snapshot('lobby_host');
      final connection = await show(
        tester,
        lobby.copyWith(
          players: [
            for (final p in lobby.players)
              p.peerId == 2 ? p.copyWith(ready: false) : p,
          ],
        ),
      );
      await tapKey(tester, const Key('startButton'));
      expect(find.text('Not everyone is ready'), findsOneWidget);
      expect(connection.calls, isNot(contains('start')));
      await tapKey(tester, const Key('confirmStartButton'));
      expect(connection.calls, contains('start'));
    });

    testWidgets('counts down on every phone, then shows the question', (
      tester,
    ) async {
      var now = fixtureNow;
      await show(
        tester,
        snapshot('question_countdown_player'),
        clock: () => DateTime.fromMillisecondsSinceEpoch(now),
      );
      expect(find.byKey(const Key('startCountdown')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.byKey(const Key('questionText')), findsNothing);

      now += 3000;
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      expect(find.byKey(const Key('startCountdown')), findsNothing);
      expect(find.byKey(const Key('questionText')), findsOneWidget);
    });
  });

  testWidgets('an answer is at most as long as the official app takes', (
    tester,
  ) async {
    await show(tester, snapshot('question_player'));
    await tester.enterText(
      find.byKey(const Key('answerField')),
      List.filled(100, 'a').join(),
    );
    await settle(tester);
    final field = tester.widget<TextField>(
      find.byKey(const Key('answerField')),
    );
    expect(field.controller!.text.length, GameRules.answerMaxLength);
    expect(find.text('80/80'), findsOneWidget);
  });

  testWidgets('a rejoin lands on the answered question', (tester) async {
    await show(tester, snapshot('question_rejoined_player'));
    expect(find.byKey(const Key('lockedIn')), findsOneWidget);
    expect(find.text('france'), findsOneWidget);
  });

  group('rating and reporting a question', () {
    testWidgets('a thumb, and a report for a reason', (tester) async {
      final connection = await show(tester, snapshot('reveal_judged_player'));
      await tapKey(tester, const Key('rate-1'));
      expect(connection.calls, contains('rate:1'));

      await tapKey(tester, const Key('reportQuestionButton'));
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('confirmReportButton')))
            .onPressed,
        isNull,
        reason: 'a reason first',
      );
      await tapKey(tester, const Key('reportReason-typo'));
      await tapKey(tester, const Key('confirmReportButton'));
      expect(connection.calls, contains('report:typo'));
    });

    testWidgets('what was given shows, and a report is once', (tester) async {
      final connection = await show(tester, snapshot('reveal_rated_player'));
      expect(
        tester.widget<IconButton>(find.byKey(const Key('rate-1'))).isSelected,
        isTrue,
      );
      expect(find.text('Reported'), findsOneWidget);
      await tapKey(tester, const Key('rate-1'));
      expect(connection.calls, contains('rate:0'), reason: 'taken back');
    });

    testWidgets('not before answering', (tester) async {
      await show(tester, snapshot('question_player'));
      expect(find.byKey(const Key('questionFeedback')), findsNothing);
    });
  });

  group('pack votes', () {
    testWidgets('a player votes, and takes a vote back', (tester) async {
      final connection = await show(tester, snapshot('lobby_player_votes'));
      expect(find.text('World Capitals'), findsOneWidget);
      expect(find.text('4 of 5 left'), findsOneWidget);
      await tapKey(tester, const Key('packVote-1001'));
      expect(connection.calls, contains('pack_vote:1001:true'));
      await tapKey(tester, const Key('packVote-268682'));
      expect(connection.calls, contains('pack_vote:268682:false'));
    });

    testWidgets('a new pack comes from the catalog', (tester) async {
      await show(tester, snapshot('lobby_player_votes'));
      await tapKey(tester, const Key('votePackButton'));
      expect(find.byKey(const Key('packSearchField')), findsOneWidget);
    });

    testWidgets('the host sees the tallies and plays one', (tester) async {
      final requests = <String>[];
      final lobby = snapshot('lobby_player_votes');
      final connection = await show(
        tester,
        lobby.copyWith(you: lobby.you.copyWith(host: true)),
        overrides: _relay(requests),
      );
      expect(find.byKey(const Key('votePackButton')), findsNothing);
      expect(find.text('2 VOTES'), findsOneWidget);
      await tapKey(tester, const Key('packVote-268682'));
      expect(requests, [
        'POST /api/seats/pack {"seat_token":"tok1","pack_id":268682}',
      ]);
      expect(connection.calls.where((c) => c.startsWith('pack_vote')), isEmpty);
    });
  });

  testWidgets('play again joins the next game when it started without you', (
    tester,
  ) async {
    final requests = <String>[];
    final connection = await show(
      tester,
      snapshot('final_scores_left_behind_player'),
      overrides: _relay(requests),
    );
    expect(find.textContaining('771204'), findsOneWidget);
    await tapKey(tester, const Key('playAgainButton'));
    expect(requests, ['POST /api/seats {"code":"771204"}']);
    expect(connection.calls, isNot(contains('play_again')));
  });
}
