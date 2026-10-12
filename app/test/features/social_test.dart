import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trivia_relay/core/api/relay_api.dart';
import 'package:trivia_relay/core/models/models.dart';
import 'package:trivia_relay/core/providers/account_providers.dart';
import 'package:trivia_relay/core/providers/connection_providers.dart';
import 'package:trivia_relay/core/providers/settings_providers.dart';
import 'package:trivia_relay/features/game/game_screen.dart';
import 'package:trivia_relay/features/home/home_screen.dart';
import 'package:trivia_relay/features/settings/settings_screen.dart';

import '../support/app.dart';
import '../support/fake_seat_connection.dart';
import '../support/protocol_fixtures.dart';
import '../support/pump.dart';

const _account = SporcleAccount(
  playerId: 'p1',
  token: 't0k3n',
  handle: 'Handle',
  deviceId: '0123456789abcdef',
);

/// A relay that answers [routes] by path (a body, or a `(status, body)`
/// record), `{}` otherwise, and records every request.
({RelayApi api, List<http.Request> requests}) _relay(
  Map<String, Object Function(http.Request)> routes,
) {
  final requests = <http.Request>[];
  final api = RelayApi(
    baseUrl: 'https://relay.example',
    client: MockClient((request) async {
      requests.add(request);
      final answer =
          routes[request.url.path]?.call(request) ?? <String, dynamic>{};
      final (status, body) = answer is (int, Object) ? answer : (200, answer);
      return http.Response.bytes(utf8.encode(jsonEncode(body)), status);
    }),
  );
  return (api: api, requests: requests);
}

Map<String, Object> _signedIn([SporcleAccount account = _account]) => {
  'trivia_relay.account': jsonEncode(account.toJson()),
};

Map<String, dynamic> _game(String code, {bool images = false}) => {
  'code': code,
  'list': 'public',
  'pack': {'id': 7, 'name': 'Flags', 'image_url': null},
  'host': 'Hosty',
  'player_count': 3,
  'stage': 'lobby',
  'has_images': images,
};

void main() {
  group('Party Poppers', () {
    testWidgets('a game with pictures says it costs one, and asks first', (
      tester,
    ) async {
      final relay = _relay({
        '/api/games': (_) => {
          'games': [_game('111', images: true), _game('222')],
        },
        '/api/seats': (_) => (
          201,
          {'seat_id': 's', 'seat_token': 't', 'game_code': '111', 'poppers': 3},
        ),
      });
      await pumpApp(
        tester,
        const HomeScreen(),
        connection: FakeSeatConnection(),
        prefs: {
          ..._signedIn(),
          'trivia_relay.poppers': jsonEncode({
            'p1': {'poppers': 4, 'last_claim': null},
          }),
        },
        overrides: [relayApiProvider.overrideWithValue(relay.api)],
      );
      await tapKey(tester, const Key('browseGamesButton'));

      expect(find.textContaining('1 POPPER'), findsOneWidget);
      expect(find.byKey(const Key('poppersPanel')), findsOneWidget);
      expect(find.textContaining('You have 4.'), findsOneWidget);

      await tapKey(tester, const Key('game-111'));
      expect(find.text('Spend a Party Popper?'), findsOneWidget);
      expect(find.textContaining('You have 4.'), findsWidgets);
      await tester.tap(find.text('Not now'));
      await settle(tester);
      expect(relay.requests.where((r) => r.url.path == '/api/seats'), isEmpty);

      await tapKey(tester, const Key('game-111'));
      await tapKey(tester, const Key('confirmJoinButton'));
      expect(relay.requests.last.url.path, '/api/seats');
      expect(tester.takeException(), isNull);
    });

    testWidgets('claiming the free ones says what came of it', (tester) async {
      var poppers = 2;
      final relay = _relay({
        '/api/games': (_) => {
          'games': [_game('111', images: true)],
        },
        '/api/poppers/claim': (_) => {
          'poppers': poppers,
          'last_claim': 1790000000000,
        },
      });
      await pumpApp(
        tester,
        const HomeScreen(),
        prefs: _signedIn(),
        overrides: [relayApiProvider.overrideWithValue(relay.api)],
      );
      await tapKey(tester, const Key('browseGamesButton'));
      await tapKey(tester, const Key('claimPoppersButton'));
      expect(relay.requests.last.url.path, '/api/poppers/claim');
      expect(relay.requests.last.headers['x-player-token'], 't0k3n');
      expect(find.text('You have 2 Party Poppers.'), findsOneWidget);
      expect(find.textContaining('You have 2.'), findsOneWidget);

      await tapKey(tester, const Key('claimPoppersButton'));
      expect(find.textContaining('None to claim yet'), findsOneWidget);

      poppers = 3;
      await tapKey(tester, const Key('claimPoppersButton'));
      expect(find.text('You have 3 Party Poppers.'), findsOneWidget);
    });

    testWidgets('no poppers left is said plainly when joining', (tester) async {
      final relay = _relay({
        '/api/seats': (_) =>
            (409, {'code': 'insufficient_poppers', 'message': 'x'}),
      });
      await pumpApp(
        tester,
        const HomeScreen(),
        prefs: _signedIn(),
        overrides: [relayApiProvider.overrideWithValue(relay.api)],
      );
      await tester.enterText(find.byKey(const Key('codeField')), '624949');
      await settle(tester);
      await tapKey(tester, const Key('joinButton'));
      expect(find.textContaining('takes a Party Popper'), findsOneWidget);
    });
  });

  group('inviting friends from the lobby', () {
    testWidgets('lists the friends, and invites one or all', (tester) async {
      final relay = _relay({
        '/api/friends': (request) => request.url.queryParameters['page'] == '0'
            ? {
                'friends': [
                  {'id': 'xA1', 'name': 'Ana', 'handle': 'ana'},
                  {'id': 'xB2', 'name': 'زيد', 'handle': 'zed'},
                ],
                'next_page': 1,
              }
            : {'friends': <Object>[], 'next_page': null},
      });
      final lobby = ProtocolFixtures.snapshot('lobby_host');
      await pumpApp(
        tester,
        const GameScreen(),
        connection: FakeSeatConnection()..emit(lobby),
        prefs: {
          ..._signedIn(),
          'trivia_relay.seat': jsonEncode({
            'player_id': 'p1',
            'ticket': {
              'seat_id': 's1',
              'seat_token': 'st',
              'game_code': lobby.gameCode,
            },
          }),
        },
        overrides: [relayApiProvider.overrideWithValue(relay.api)],
      );
      await tapKey(tester, const Key('inviteFriendsButton'));
      expect(find.byKey(const Key('inviteFriendsSheet')), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('زيد'), findsOneWidget);
      expect(find.text('@zed'), findsOneWidget);

      await tapKey(tester, const Key('inviteFriend-xA1'));
      final one = relay.requests.last;
      expect(one.url.path, '/api/invites');
      expect(one.headers['x-player-token'], 't0k3n');
      expect(jsonDecode(one.body), {
        'seat_token': 'st',
        'code': lobby.gameCode,
        'pack_id': lobby.pack!.id,
        'friend_id': 'xA1',
      });
      expect(find.text('Invited'), findsOneWidget);

      await tapKey(tester, const Key('inviteAllButton'));
      expect(jsonDecode(relay.requests.last.body)['friend_id'], isNull);
      expect(find.text('All invited'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the sheet fits a small phone at twice the text', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final relay = _relay({
        '/api/friends': (_) => {
          'friends': [
            {'id': 'x', 'name': 'A rather long friend name ' * 3},
          ],
          'next_page': null,
        },
      });
      await pumpApp(
        tester,
        const GameScreen(),
        size: const Size(320, 568),
        connection: FakeSeatConnection()
          ..emit(ProtocolFixtures.snapshot('lobby_host')),
        prefs: _signedIn(),
        overrides: [relayApiProvider.overrideWithValue(relay.api)],
      );
      await tapKey(tester, const Key('inviteFriendsButton'));
      await tester.scrollUntilVisible(
        find.byKey(const Key('inviteFriend-x')),
        100,
        scrollable: find.descendant(
          of: find.byKey(const Key('inviteFriendsSheet')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.byKey(const Key('inviteFriend-x')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('settings', () {
    testWidgets('a name others see is checked with Sporcle, then kept', (
      tester,
    ) async {
      final relay = _relay({
        '/api/names/check': (request) {
          final name = (jsonDecode(request.body) as Map)['name'] as String;
          return {'name': name.trim(), 'allowed': name != 'rude'};
        },
      });
      final container = await _pumpSettings(tester, relay.api);

      await tester.enterText(find.byKey(const Key('displayNameField')), 'rude');
      await settle(tester);
      await tapKey(tester, const Key('saveNameButton'));
      expect(find.textContaining("won't show that name"), findsOneWidget);
      expect(container().displayName, isNull);

      await tester.enterText(
        find.byKey(const Key('displayNameField')),
        'Quiz Wiz',
      );
      await settle(tester);
      await tapKey(tester, const Key('saveNameButton'));
      expect(relay.requests.last.headers['x-player-token'], 't0k3n');
      expect(container().displayName, 'Quiz Wiz');
      expect(container().player['name'], 'Quiz Wiz');

      // The handle again, and nothing asked of Sporcle for it.
      final asked = relay.requests.length;
      await tester.enterText(find.byKey(const Key('displayNameField')), '');
      await settle(tester);
      await tapKey(tester, const Key('saveNameButton'));
      expect(relay.requests.length, asked);
      expect(container().displayName, isNull);
    });

    testWidgets('sounds can be turned off, and stay off', (tester) async {
      await _pumpSettings(tester, _relay({}).api);
      await tapKey(tester, const Key('soundSwitch'));
      final element = tester.element(find.byType(SettingsScreen));
      final settings = await ProviderScope.containerOf(element)
          .read(settingsProvider.future);
      expect(settings.sound, isFalse);
      expect(settings.haptics, isTrue);
    });

    testWidgets('settings fit a small phone at twice the text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await _pumpSettings(tester, _relay({}).api, size: const Size(320, 568));
      expect(tester.takeException(), isNull);
    });
  });

  group('invite links', () {
    testWidgets('a link offers its game, and joins only on a yes', (
      tester,
    ) async {
      final relay = _relay({
        '/api/seats': (_) =>
            (201, {'seat_id': 's', 'seat_token': 't', 'game_code': '624949'}),
      });
      final connection = FakeSeatConnection();
      await pumpApp(
        tester,
        const HomeScreen(),
        connection: connection,
        prefs: _signedIn(),
        overrides: [relayApiProvider.overrideWithValue(relay.api)],
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );

      container.read(pendingInviteProvider.notifier).offer('624949');
      await settle(tester);
      expect(find.text('Join game 624949?'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await settle(tester);
      expect(relay.requests, isEmpty, reason: 'never joins by itself');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('codeField')))
            .controller!
            .text,
        '624949',
        reason: 'the code is left ready',
      );

      container.read(pendingInviteProvider.notifier).offer('624949');
      await settle(tester);
      await tapKey(tester, const Key('confirmInviteButton'));
      expect(relay.requests.single.url.path, '/api/seats');
      expect(jsonDecode(relay.requests.single.body)['code'], '624949');
    });

    testWidgets('anything but a game code is no invite', (tester) async {
      await pumpApp(
        tester,
        const HomeScreen(),
        prefs: _signedIn(),
        overrides: [relayApiProvider.overrideWithValue(_relay({}).api)],
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      for (final code in ['12', 'abcd', '123456789', '']) {
        container.read(pendingInviteProvider.notifier).offer(code);
      }
      await settle(tester);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}

/// Settings for a signed-in player; returns a reader of the account as the
/// app has it.
Future<SporcleAccount Function()> _pumpSettings(
  WidgetTester tester,
  RelayApi api, {
  Size size = const Size(360, 740),
}) async {
  await pumpApp(
    tester,
    const SettingsScreen(),
    size: size,
    prefs: _signedIn(),
    overrides: [relayApiProvider.overrideWithValue(api)],
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(SettingsScreen)),
  );
  return () => container.read(accountProvider).value!;
}
