import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trivia_relay/core/api/relay_api.dart';
import 'package:trivia_relay/core/models/models.dart';
import 'package:trivia_relay/core/sporcle/sporcle_login.dart';

const account = SporcleAccount(
  playerId: 'p1',
  token: 't0k3n',
  handle: 'Joiner',
  deviceId: '0123456789abcdef',
);

void main() {
  group('RelayApi', () {
    test('joins with the player in the body and returns the seat', () async {
      final api = RelayApi(
        baseUrl: 'https://relay.example/',
        client: MockClient((request) async {
          expect(request.url.toString(), 'https://relay.example/api/seats');
          expect(jsonDecode(request.body), {
            'code': '624949',
            'player': account.player,
          });
          return http.Response(
            jsonEncode({
              'seat_id': 's1',
              'seat_token': 'st',
              'game_code': '624949',
            }),
            201,
          );
        }),
      );
      expect(
        await api.join(account, '624949'),
        const SeatTicket(seatId: 's1', seatToken: 'st', gameCode: '624949'),
      );
    });

    test('hosts with the options the relay takes', () async {
      final api = RelayApi(
        baseUrl: 'https://relay.example',
        client: MockClient((request) async {
          expect(jsonDecode(request.body)['options'], {
            'questions_per_game': 5,
            'question_seconds': 15,
            'audience': 'private',
          });
          return http.Response(
            '{"seat_id":"s","seat_token":"t","game_code":"1"}',
            201,
          );
        }),
      );
      await api.host(
        account,
        7,
        const HostOptions(questionsPerGame: 5, questionSeconds: 15),
      );
    });

    test('changes the pack with the seat token and the player', () async {
      final api = RelayApi(
        baseUrl: 'https://relay.example',
        client: MockClient((request) async {
          expect(request.url.path, '/api/seats/pack');
          final body = jsonDecode(request.body);
          expect(body['seat_token'], 'st');
          expect(body['pack_id'], 268682);
          expect(body['player'], account.player);
          return http.Response('', 204);
        }),
      );
      await api.changePack(
        account,
        const SeatTicket(seatId: 's1', seatToken: 'st', gameCode: '624949'),
        268682,
      );
    });

    test('searches with credentials in headers, never the URL', () async {
      final api = RelayApi(
        baseUrl: 'https://relay.example',
        client: MockClient((request) async {
          expect(request.url.queryParameters, {'q': 'flags', 'page': '0'});
          expect(request.headers['x-player-token'], 't0k3n');
          expect(request.url.toString(), isNot(contains('t0k3n')));
          return http.Response(
            jsonEncode({
              'packs': [
                {'id': 7, 'name': 'Flags', 'num_questions': 169},
              ],
            }),
            200,
          );
        }),
      );
      final page = await api.searchPacks(account, query: 'flags');
      expect(page.packs.single.name, 'Flags');
    });

    test('browses a list a page at a time', () async {
      final api = RelayApi(
        baseUrl: 'https://relay.example',
        client: MockClient((request) async {
          expect(request.url.queryParameters, {
            'q': '',
            'list': 'popular',
            'page': '2',
          });
          return http.Response(
            jsonEncode({
              'packs': [
                {'id': 7, 'name': 'Flags', 'image_url': null},
              ],
              'next_page': 3,
            }),
            200,
          );
        }),
      );
      final page = await api.searchPacks(
        account,
        list: PackList.popular,
        page: 2,
      );
      expect(page.nextPage, 3);
      expect(page.packs.single.imageUrl, isNull);
    });

    test("the relay's errors arrive as GameErrors with its code", () async {
      final api = RelayApi(
        baseUrl: 'https://relay.example',
        client: MockClient(
          (_) async => http.Response(
            '{"code":"game_refused","message":"Game not found"}',
            409,
          ),
        ),
      );
      expect(
        api.join(account, '1234'),
        throwsA(
          const GameError(code: 'game_refused', message: 'Game not found'),
        ),
      );
    });
  });

  group('SporcleLogin', () {
    test('primes party context, then reads the token from login.php', () async {
      var primed = false;
      final login = SporcleLogin(
        client: MockClient((request) async {
          switch (request.url.path) {
            case '/login/':
              expect(request.url.queryParameters['party_udid'], 'dev123');
              primed = true;
              return http.Response(
                '<html>login</html>',
                200,
                headers: {'set-cookie': 'sporid=xAc71a08as%7Csig; Path=/'},
              );
            case '/auth/ajax/login.php':
              expect(
                primed,
                isTrue,
                reason: 'must load /login/?party_udid first',
              );
              expect(request.bodyFields['passwd'], 'secret');
              expect(request.headers['cookie'], contains('sporid='));
              return http.Response(
                '{"success":true,"logged_in":true,"user_id":"xAc71a08as",'
                '"handle":"Anis-Abdellatif","token":"${'a' * 64}"}',
                200,
              );
          }
          fail('unexpected ${request.url}');
        }),
      );
      final result = await login.login('a@b.c', 'secret', 'dev123');
      expect(result.playerId, 'xAc71a08as');
      expect(result.token.length, 64);
      expect(result.handle, 'Anis-Abdellatif');
    });

    test('a wrong password is login_failed', () async {
      final login = SporcleLogin(
        client: MockClient((request) async {
          if (request.url.path == '/login/') return http.Response('ok', 200);
          return http.Response('{"success":false,"logged_in":false}', 200);
        }),
      );
      expect(
        login.login('a@b.c', 'nope', 'dev123'),
        throwsA(isA<GameError>().having((e) => e.code, 'code', 'login_failed')),
      );
    });

    test('cookies from a comma-joined Set-Cookie', () {
      expect(
        SporcleLogin.cookieHeader(
          'sess=abc; expires=Wed, 01 Oct 2026 00:00:00 GMT; Path=/, uid=7; Path=/',
        ),
        'sess=abc; uid=7',
      );
    });
  });
}
