import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trivia_relay/core/api/relay_api.dart';
import 'package:trivia_relay/core/models/models.dart';
import 'package:trivia_relay/core/providers/account_providers.dart';
import 'package:trivia_relay/core/providers/connection_providers.dart';
import 'package:trivia_relay/features/host/host_setup_screen.dart';

import '../support/app.dart';
import '../support/pump.dart';

const _account = SporcleAccount(
  playerId: 'p1',
  token: 't0k3n',
  handle: 'Host',
  deviceId: 'd1',
);

class _SignedIn extends Account {
  @override
  Future<SporcleAccount?> build() async => _account;
}

void main() {
  /// Host setup with a relay that has [pages] of packs in each list, 20 a
  /// page as Sporcle's are, and records every request.
  Future<List<Uri>> pumpSetup(
    WidgetTester tester, {
    Map<String, int> pages = const {'popular': 3},
  }) async {
    final requests = <Uri>[];
    final api = RelayApi(
      baseUrl: 'https://relay.example',
      client: MockClient((request) async {
        requests.add(request.url);
        final list = request.url.queryParameters['list']!;
        final page = int.parse(request.url.queryParameters['page']!);
        final full = page < (pages[list] ?? 0);
        return http.Response(
          jsonEncode({
            'packs': [
              if (full)
                for (var i = 0; i < 20; i++)
                  {
                    'id': page * 20 + i + (list == 'popular' ? 0 : 1000),
                    'name': '$list pack ${page * 20 + i}',
                    'num_questions': 50,
                    'play_count': 143060,
                    'image_url': null,
                  },
            ],
            'next_page': full ? page + 1 : null,
          }),
          200,
        );
      }),
    );
    await pumpApp(
      tester,
      const HostSetupScreen(),
      overrides: [
        accountProvider.overrideWith(_SignedIn.new),
        relayApiProvider.overrideWithValue(api),
      ],
    );
    return requests;
  }

  testWidgets('the host browses popular packs first, page by page', (
    tester,
  ) async {
    final requests = await pumpSetup(tester);
    await tapKey(tester, const Key('choosePackButton'));

    expect(requests.first.queryParameters, {
      'q': '',
      'list': 'popular',
      'page': '0',
    });
    expect(find.text('popular pack 0'), findsOneWidget);
    expect(find.textContaining('143K PLAYS'), findsWidgets);

    // Scrolling to the end fetches the pages after it, until an empty one.
    for (var i = 0; i < 12; i++) {
      await tester.drag(
        find.byKey(const Key('packList')),
        const Offset(0, -2000),
      );
      await settle(tester);
    }
    expect(
      requests.map((u) => u.queryParameters['page']),
      containsAllInOrder(['0', '1', '2', '3']),
    );
    expect(requests.length, 4, reason: 'nothing after the empty page');
    expect(find.text('60 packs'), findsOneWidget);
  });

  testWidgets('another list starts again from its first page', (tester) async {
    final requests = await pumpSetup(tester, pages: {'popular': 3, 'fresh': 1});
    await tapKey(tester, const Key('choosePackButton'));
    await tapKey(tester, const Key('packList-fresh'));

    expect(requests.last.queryParameters['list'], 'fresh');
    expect(requests.last.queryParameters['page'], '0');
    expect(find.text('fresh pack 0'), findsOneWidget);
    expect(find.text('popular pack 0'), findsNothing);
  });

  testWidgets('an empty list says what would be in it', (tester) async {
    await pumpSetup(tester);
    await tapKey(tester, const Key('choosePackButton'));
    await tapKey(tester, const Key('packList-bookmarked'));
    expect(find.byKey(const Key('noPacks')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('noPacks'))).data,
      contains('bookmark'),
    );
  });

  testWidgets('searching searches the list, and a pack tapped is chosen', (
    tester,
  ) async {
    final requests = await pumpSetup(tester);
    await tapKey(tester, const Key('choosePackButton'));
    await tester.enterText(find.byKey(const Key('packSearchField')), 'flags');
    await settle(tester);
    expect(requests.last.queryParameters, {
      'q': 'flags',
      'list': 'popular',
      'page': '0',
    });

    await tapKey(tester, const Key('pack-3'));
    expect(find.byKey(const Key('packSearchField')), findsNothing);
    expect(find.text('popular pack 3'), findsOneWidget);
    final create = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('createGameButton')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(create.onPressed, isNotNull);
  });
}
