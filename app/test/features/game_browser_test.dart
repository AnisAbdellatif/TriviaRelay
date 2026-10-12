import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trivia_relay/core/api/relay_api.dart';
import 'package:trivia_relay/core/models/models.dart';
import 'package:trivia_relay/core/providers/account_providers.dart';
import 'package:trivia_relay/core/providers/connection_providers.dart';
import 'package:trivia_relay/features/home/home_screen.dart';
import 'package:trivia_relay/features/join/game_browser_screen.dart';

import '../support/app.dart';
import '../support/fake_seat_connection.dart';
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

Map<String, dynamic> _game(
  String code,
  String list,
  String stage, {
  int? question,
  String pack = 'Flags',
}) => {
  'code': code,
  'list': list,
  'pack': {'id': 7, 'name': pack, 'description': null, 'image_url': null},
  'host': 'Hosty',
  'player_count': 4,
  'stage': stage,
  'question_number': question,
  'has_images': false,
};

void main() {
  /// The home screen, with a relay that lists [games] (or fails, if null) and
  /// seats anybody who joins. Returns every request it got.
  Future<List<http.Request>> pumpHome(
    WidgetTester tester, {
    List<Map<String, dynamic>>? games = const [],
    FakeSeatConnection? connection,
  }) async {
    final requests = <http.Request>[];
    final api = RelayApi(
      baseUrl: 'https://relay.example',
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/seats') {
          final code = (jsonDecode(request.body) as Map)['code'];
          return http.Response(
            jsonEncode({
              'seat_id': 's1',
              'seat_token': 'tok',
              'game_code': code,
            }),
            201,
          );
        }
        if (games == null) {
          return http.Response(
            jsonEncode({'code': 'sporcle_unavailable', 'message': 'down'}),
            502,
          );
        }
        // Bytes: a String body is Latin-1, and pack names often aren't.
        return http.Response.bytes(
          utf8.encode(jsonEncode({'games': games})),
          200,
        );
      }),
    );
    await pumpApp(
      tester,
      const HomeScreen(),
      connection: connection ?? FakeSeatConnection(),
      overrides: [
        accountProvider.overrideWith(_SignedIn.new),
        relayApiProvider.overrideWithValue(api),
      ],
    );
    return requests;
  }

  testWidgets('lists the games to join, with where each one is', (
    tester,
  ) async {
    final requests = await pumpHome(
      tester,
      games: [
        _game('111', 'invited', 'question', question: 3),
        _game('222', 'public', 'lobby', pack: 'علم الدول'),
        _game('333', 'public', 'final'),
      ],
    );
    await tapKey(tester, const Key('browseGamesButton'));

    final get = requests.single;
    expect(get.url.path, '/api/games');
    expect(get.url.query, isEmpty, reason: 'credentials never in the URL');
    expect(get.headers['x-player-token'], 't0k3n');

    expect(find.text('INVITED'), findsOneWidget);
    expect(find.text('PUBLIC GAMES'), findsOneWidget);
    expect(find.text("FRIENDS' GAMES"), findsNothing);
    expect(find.text('QUESTION 3'), findsOneWidget);
    expect(find.text('LOBBY'), findsOneWidget);
    expect(find.text('FINAL QUESTION'), findsOneWidget);
    expect(find.text('علم الدول'), findsOneWidget);
    expect(find.text('Hosted by '), findsNWidgets(3));
    expect(find.byKey(const Key('gameHost')), findsNWidgets(3));
    expect(find.text('3 games'), findsOneWidget);
  });

  testWidgets('searching narrows the list by pack, host or code', (
    tester,
  ) async {
    final requests = await pumpHome(
      tester,
      games: [
        _game('111', 'public', 'lobby', pack: 'World Flags'),
        _game('222', 'public', 'lobby', pack: 'علم الدول'),
        {
          ..._game('333', 'public', 'lobby', pack: 'Movies'),
          'host': 'Cinephile',
        },
      ],
    );
    await tapKey(tester, const Key('browseGamesButton'));

    await tester.enterText(find.byKey(const Key('gameSearchField')), 'FLAGS');
    await settle(tester);
    expect(find.byKey(const Key('game-111')), findsOneWidget);
    expect(find.byKey(const Key('game-222')), findsNothing);
    expect(find.text('1 game'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('gameSearchField')), 'cine');
    await settle(tester);
    expect(find.byKey(const Key('game-333')), findsOneWidget);
    expect(find.byKey(const Key('game-111')), findsNothing);

    await tester.enterText(find.byKey(const Key('gameSearchField')), 'علم');
    await settle(tester);
    expect(find.byKey(const Key('game-222')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('gameSearchField')), 'nothing');
    await settle(tester);
    expect(find.text('No games match "nothing".'), findsOneWidget);

    await tapKey(tester, const Key('clearGameSearchButton'));
    expect(find.text('3 games'), findsOneWidget);
    expect(requests, hasLength(1), reason: 'searching never asks the relay');
  });

  testWidgets('tapping a game joins it by its code', (tester) async {
    final connection = FakeSeatConnection();
    final requests = await pumpHome(
      tester,
      games: [_game('222', 'public', 'lobby')],
      connection: connection,
    );
    await tapKey(tester, const Key('browseGamesButton'));
    await tapKey(tester, const Key('game-222'));

    final join = requests.last;
    expect(join.url.path, '/api/seats');
    expect((jsonDecode(join.body) as Map)['code'], '222');
    expect(connection.calls, contains('attach:s1'));
  });

  testWidgets('a game in progress is joined only once confirmed', (
    tester,
  ) async {
    final connection = FakeSeatConnection();
    final requests = await pumpHome(
      tester,
      games: [_game('111', 'public', 'question', question: 8)],
      connection: connection,
    );
    await tapKey(tester, const Key('browseGamesButton'));
    await tapKey(tester, const Key('game-111'));
    expect(find.text('Join a game in progress?'), findsOneWidget);
    expect(find.textContaining('Question 8'), findsWidgets);
    await tester.tap(find.text('Not now'));
    await settle(tester);
    expect(requests.where((r) => r.url.path == '/api/seats'), isEmpty);

    await tapKey(tester, const Key('game-111'));
    await tapKey(tester, const Key('confirmJoinButton'));
    expect(requests.last.url.path, '/api/seats');
    expect(connection.calls, contains('attach:s1'));
  });

  test('a refresh keeps the games in the places they had', () {
    JoinableGame game(String code, [int players = 4]) => JoinableGame.fromJson({
      ..._game(code, 'public', 'lobby'),
      'player_count': players,
    });
    final before = [game('1'), game('2'), game('3')];
    final fresh = [game('4'), game('3', 9), game('1')];
    expect(keepOrder(before, fresh).map((g) => g.code), ['1', '3', '4']);
    expect(
      keepOrder(before, fresh)[1].playerCount,
      9,
      reason: 'kept in place, with what is new about it',
    );
  });

  testWidgets('the list refreshes while it is open, and stops after', (
    tester,
  ) async {
    final requests = await pumpHome(tester);
    await tapKey(tester, const Key('browseGamesButton'));
    expect(find.byKey(const Key('noGames')), findsOneWidget);
    expect(requests, hasLength(1));

    await tester.pump(GameBrowserScreen.refreshEvery);
    await settle(tester);
    expect(requests, hasLength(2));

    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    await tester.pump(GameBrowserScreen.refreshEvery * 2);
    expect(requests, hasLength(2));
  });

  testWidgets('a failed load can be tried again', (tester) async {
    final requests = await pumpHome(tester, games: null);
    await tapKey(tester, const Key('browseGamesButton'));
    expect(find.text("Couldn't load games."), findsOneWidget);

    await tapKey(tester, const Key('retryGamesButton'));
    expect(requests, hasLength(2));
  });

  test('a search matches the code too', () {
    final game = JoinableGame.fromJson(_game('787720', 'public', 'lobby'));
    expect(matchesSearch(game, '7877'), isTrue);
    expect(matchesSearch(game, ' '), isTrue);
    expect(matchesSearch(game, '999'), isFalse);
  });

  test('a stage or list this app does not know still parses', () {
    final game = JoinableGame.fromJson({
      ..._game('1', 'someday', 'intermission'),
    });
    expect(game.stage, GameStage.playing);
    expect(game.list, GameList.public);
    expect(gameStage(game), 'Playing');
  });
}
