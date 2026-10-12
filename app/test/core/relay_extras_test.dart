import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trivia_relay/core/api/relay_api.dart';
import 'package:trivia_relay/core/models/models.dart';

import '../support/protocol_fixtures.dart';

const _account = SporcleAccount(
  playerId: 'p1',
  token: 't0k3n',
  handle: 'Handle',
  deviceId: '0123456789abcdef',
);

void main() {
  test('the report reasons offered are the relay\'s', () {
    final constants = ProtocolFixtures.load('constants.json');
    expect(
      ReportReason.values.map((r) => r.name).toList(),
      constants['pack_report_reasons'],
    );
  });

  test('a chosen name goes with the player; none, and the handle stands', () {
    expect(_account.player.containsKey('name'), isFalse);
    expect(_account.shownName, 'Handle');
    final named = _account.copyWith(displayName: 'Quiz Wiz');
    expect(named.player['name'], 'Quiz Wiz');
    expect(named.player['handle'], 'Handle');
    expect(named.shownName, 'Quiz Wiz');
  });

  group('the relay calls since 1.2', () {
    late List<http.Request> requests;

    RelayApi api(Object body, {int status = 200}) {
      requests = [];
      return RelayApi(
        baseUrl: 'https://relay.example',
        client: MockClient((request) async {
          requests.add(request);
          return http.Response.bytes(utf8.encode(jsonEncode(body)), status);
        }),
      );
    }

    void credentialsInHeaders() {
      for (final request in requests) {
        expect(request.headers['x-player-token'], 't0k3n');
        expect(request.url.query, isNot(contains('t0k3n')));
        expect(request.body, isNot(contains('t0k3n')));
      }
    }

    test('bookmarking and reporting a pack', () async {
      expect(
        await api({'bookmarked': true}).setBookmarked(_account, 7, true),
        isTrue,
      );
      expect(requests.single.url.path, '/api/packs/7/bookmark');
      expect(jsonDecode(requests.single.body), {'bookmarked': true});
      credentialsInHeaders();

      await api(const <String, dynamic>{})
          .reportPack(_account, 7, ReportReason.inaccurate, 'Q3 is wrong');
      expect(requests.single.url.path, '/api/packs/7/report');
      expect(jsonDecode(requests.single.body), {
        'reason': 'inaccurate',
        'details': 'Q3 is wrong',
      });
      credentialsInHeaders();
    });

    test('a pack, and a random one, with what the player did to it', () async {
      final pack = await api({
        'pack': {'id': 3, 'name': 'Rivers', 'bookmarked': true},
      }).randomPack(_account);
      expect(requests.single.url.path, '/api/packs/random');
      expect(pack.bookmarked, isTrue);
      expect(pack.subscribed, isNull);
      credentialsInHeaders();
    });

    test('claiming poppers', () async {
      final balance = await api({'poppers': 3, 'last_claim': 1790000000000})
          .claimPoppers(_account);
      expect(requests.single.url.path, '/api/poppers/claim');
      expect(
        balance,
        const PopperBalance(poppers: 3, lastClaim: 1790000000000),
      );
      credentialsInHeaders();
    });

    test('friends, and inviting one or all of them', () async {
      final page = await api({
        'friends': [
          {'id': 'xA1', 'name': 'Ana', 'handle': 'ana'},
        ],
        'next_page': 1,
      }).friends(_account);
      expect(
        page.friends.single,
        const Friend(id: 'xA1', name: 'Ana', handle: 'ana'),
      );
      expect(page.nextPage, 1);
      credentialsInHeaders();

      const seat = SeatTicket(seatId: 's', seatToken: 'st', gameCode: '1234');
      final relay = api(const <String, dynamic>{});
      await relay.invite(_account, seat, packId: 7, friendId: 'xA1');
      await relay.invite(_account, seat, packId: 7);
      expect(requests.map((r) => jsonDecode(r.body)), [
        {'seat_token': 'st', 'code': '1234', 'pack_id': 7, 'friend_id': 'xA1'},
        {'seat_token': 'st', 'code': '1234', 'pack_id': 7, 'friend_id': null},
      ]);
      credentialsInHeaders();
    });

    test('a seat says how many poppers the player had', () async {
      final ticket = await api({
        'seat_id': 's',
        'seat_token': 't',
        'game_code': '1234',
        'poppers': 4,
      }, status: 201).join(_account, '1234');
      expect(ticket.poppers, 4);
    });

    test('refusals keep their code', () async {
      await expectLater(
        api({
          'code': 'insufficient_poppers',
          'message': 'none left',
        }, status: 409).join(_account, '1234'),
        throwsA(
          isA<GameError>().having(
            (e) => e.code,
            'code',
            'insufficient_poppers',
          ),
        ),
      );
    });
  });
}
