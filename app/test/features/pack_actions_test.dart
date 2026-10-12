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
import 'package:trivia_relay/features/host/pack_sheet.dart';

import '../support/app.dart';
import '../support/pump.dart';

const _account = SporcleAccount(
  playerId: 'p1',
  token: 't0k3n',
  handle: 'Host',
  deviceId: '0123456789abcdef',
);

class _SignedIn extends Account {
  @override
  Future<SporcleAccount?> build() async => _account;
}

Map<String, dynamic> _pack(int id, {bool? bookmarked}) => {
  'id': id,
  'name': 'Pack $id',
  'description': 'All about $id',
  'num_questions': 40,
  'has_images': false,
  'play_count': 1200,
  'image_url': null,
  'bookmarked': bookmarked,
};

Finder _bookmarkLabel(String text) => find.descendant(
  of: find.byKey(const Key('bookmarkPackButton')),
  matching: find.text(text),
);

void main() {
  /// Host setup against a relay with two popular packs; [bookmarked] is what
  /// Sporcle says of pack 1 up close. Returns every request.
  Future<List<http.Request>> pumpSetup(
    WidgetTester tester, {
    bool bookmarked = false,
    Size size = const Size(360, 740),
  }) async {
    final requests = <http.Request>[];
    final api = RelayApi(
      baseUrl: 'https://relay.example',
      client: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        final Object body = switch (path) {
          '/api/packs' => {
            'packs': [_pack(1), _pack(2)],
            'next_page': null,
          },
          '/api/packs/random' => {'pack': _pack(99)},
          '/api/packs/1' => {'pack': _pack(1, bookmarked: bookmarked)},
          '/api/packs/1/bookmark' => {
            'bookmarked': (jsonDecode(request.body) as Map)['bookmarked'],
          },
          _ => <String, dynamic>{},
        };
        return http.Response(
          jsonEncode(body),
          path.endsWith('/report') ? 204 : 200,
        );
      }),
    );
    await pumpApp(
      tester,
      const HostSetupScreen(),
      size: size,
      overrides: [
        accountProvider.overrideWith(_SignedIn.new),
        relayApiProvider.overrideWithValue(api),
      ],
    );
    await tapKey(tester, const Key('choosePackButton'));
    return requests;
  }

  testWidgets('a pack up close is bookmarked from there, and says so', (
    tester,
  ) async {
    final requests = await pumpSetup(tester);
    await tapKey(tester, const Key('packMore-1'));

    expect(find.byKey(const Key('packSheet')), findsOneWidget);
    expect(requests.last.url.path, '/api/packs/1');
    expect(requests.last.headers['x-player-token'], 't0k3n');
    expect(_bookmarkLabel('Bookmark'), findsOneWidget);

    await tapKey(tester, const Key('bookmarkPackButton'));
    expect(requests.last.url.path, '/api/packs/1/bookmark');
    expect(jsonDecode(requests.last.body), {'bookmarked': true});
    expect(_bookmarkLabel('Bookmarked'), findsOneWidget);
    expect(find.text('Bookmarked.'), findsOneWidget, reason: 'the toast');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a bookmarked pack can be let go of', (tester) async {
    final requests = await pumpSetup(tester, bookmarked: true);
    await tapKey(tester, const Key('packMore-1'));
    expect(_bookmarkLabel('Bookmarked'), findsOneWidget);
    await tapKey(tester, const Key('bookmarkPackButton'));
    expect(jsonDecode(requests.last.body), {'bookmarked': false});
    expect(_bookmarkLabel('Bookmark'), findsOneWidget);
  });

  testWidgets('choosing from up close picks the pack', (tester) async {
    await pumpSetup(tester);
    await tapKey(tester, const Key('packMore-2'));
    await tapKey(tester, const Key('choosePackSheetButton'));
    expect(find.byKey(const Key('packSheet')), findsNothing);
    expect(find.text('Pack 2'), findsOneWidget, reason: 'back in setup');
  });

  testWidgets('a random pack is shown up close, to host or not', (
    tester,
  ) async {
    final requests = await pumpSetup(tester);
    await tapKey(tester, const Key('randomPackButton'));
    expect(requests.any((r) => r.url.path == '/api/packs/random'), isTrue);
    expect(find.text('Pack 99'), findsWidgets);
    await tapKey(tester, const Key('choosePackSheetButton'));
    expect(find.text('Pack 99'), findsOneWidget, reason: 'chosen');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a report needs a reason and words, and asks before sending', (
    tester,
  ) async {
    final requests = await pumpSetup(tester);
    await tapKey(tester, const Key('packMore-1'));
    await tapKey(tester, const Key('reportPackButton'));

    Finder send() => find.byKey(const Key('sendReportButton'));
    bool enabled() =>
        tester
            .widget<FilledButton>(
              find.descendant(of: send(), matching: find.byType(FilledButton)),
            )
            .onPressed !=
        null;
    expect(enabled(), isFalse);

    await tapKey(tester, const Key('reportReason-inaccurate'));
    expect(enabled(), isFalse, reason: 'no words yet');
    await tester.enterText(
      find.byKey(const Key('reportDetailsField')),
      'Question 3 is wrong',
    );
    await settle(tester);
    expect(enabled(), isTrue);

    // Asked first; "Not now" sends nothing.
    await tapKey(tester, const Key('sendReportButton'));
    expect(find.text('Send this report?'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await settle(tester);
    expect(requests.where((r) => r.url.path.endsWith('/report')), isEmpty);

    await tapKey(tester, const Key('sendReportButton'));
    await tapKey(tester, const Key('confirmReportButton'));
    final report = requests.lastWhere((r) => r.url.path.endsWith('/report'));
    expect(report.url.path, '/api/packs/1/report');
    expect(jsonDecode(report.body), {
      'reason': 'inaccurate',
      'details': 'Question 3 is wrong',
    });
    expect(find.text('Report sent. Thank you.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the sheet and the report fit a small phone at twice the text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await pumpSetup(tester, size: const Size(320, 568));
    await tapKey(tester, const Key('packMore-1'));
    expect(tester.takeException(), isNull);
    await tapKey(tester, const Key('reportPackButton'));
    expect(find.byKey(const Key('sendReportButton')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('every reason has words', () {
    for (final reason in ReportReason.values) {
      expect(reasonLabel(reason), isNotEmpty);
    }
  });
}
