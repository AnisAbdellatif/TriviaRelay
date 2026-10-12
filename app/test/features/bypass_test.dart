import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trivia_relay/core/api/relay_api.dart';
import 'package:trivia_relay/core/models/models.dart';
import 'package:trivia_relay/core/providers/connection_providers.dart';
import 'package:trivia_relay/core/providers/settings_providers.dart';
import 'package:trivia_relay/features/game/game_screen.dart';

import '../support/app.dart';
import '../support/fake_seat_connection.dart';
import '../support/protocol_fixtures.dart';

const _key = 'trivia_relay.bypass_token';

/// A relay whose `/api/bypass/check` answers [status]; [checks] counts them.
RelayApi _relay(int status, {List<String>? checks}) => RelayApi(
  baseUrl: 'https://relay.example',
  client: MockClient((request) async {
    checks?.add(request.headers['x-bypass-token'] ?? '');
    return status == 204
        ? http.Response('', 204)
        : http.Response(
            jsonEncode({'code': 'bypass_revoked', 'message': 'Revoked.'}),
            status,
          );
  }),
);

RelayApi _offline() => RelayApi(
  baseUrl: 'https://relay.example',
  client: MockClient((_) async => throw const _Unreachable()),
);

class _Unreachable implements Exception {
  const _Unreachable();
}

/// The token the provider holds once its check with the relay has settled.
Future<String?> _settled(ProviderContainer container) async {
  await container.read(kickBypassTokenProvider.future);
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return container.read(kickBypassTokenProvider).value;
}

void main() {
  group('a stored bypass token is checked with the relay', () {
    Future<(String?, String?)> run(RelayApi api, {List<String>? checks}) async {
      SharedPreferences.setMockInitialValues({_key: 'tok'});
      final container = ProviderContainer(
        overrides: [relayApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      final held = await _settled(container);
      final prefs = await SharedPreferences.getInstance();
      return (held, prefs.getString(_key));
    }

    test('and forgotten once revoked', () async {
      final checks = <String>[];
      expect(await run(_relay(403, checks: checks)), (null, null));
      expect(checks, ['tok']);
    });

    test('and kept while the relay honours it', () async {
      expect(await run(_relay(204)), ('tok', 'tok'));
    });

    test('and kept when the relay can not be reached', () async {
      expect(await run(_offline()), ('tok', 'tok'));
    });
  });

  testWidgets('an action refused as revoked forgets the token', (tester) async {
    final connection = FakeSeatConnection()
      ..emit(ProtocolFixtures.snapshot('lobby_player_votes'));
    await pumpApp(
      tester,
      const GameScreen(),
      connection: connection,
      prefs: {_key: 'tok'},
      overrides: [relayApiProvider.overrideWithValue(_relay(204))],
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bypassFab')), findsOneWidget);

    connection.intentError = const GameError(code: 'bypass_revoked');
    await tester.tap(find.byKey(const Key('bypassFab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bypassBecomeHost')));
    await tester.pumpAndSettle();

    expect(connection.calls, contains('claim_host'));
    expect(find.text('Your bypass access was revoked.'), findsOneWidget);
    expect(find.byKey(const Key('bypassFab')), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_key), isNull);
  });
}
