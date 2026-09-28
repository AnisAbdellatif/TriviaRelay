import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trivia_relay/core/providers/config_providers.dart';
import 'package:trivia_relay/core/providers/connection_providers.dart';
import 'package:trivia_relay/shared/theme/fz_theme.dart';

import 'fake_seat_connection.dart';
import 'pump.dart';

/// The fixtures' server clock (protocol/fixtures/snapshots): questions opened at
/// this moment, with 15 s to go.
const fixtureNow = 1790000000000;

/// Pumps [home] as the app would show it, at a phone's size unless [size] says
/// otherwise, with [connection] as the seat.
Future<void> pumpApp(
  WidgetTester tester,
  Widget home, {
  FakeSeatConnection? connection,
  Size size = const Size(360, 740),
  List overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (connection != null)
          seatConnectionProvider.overrideWithValue(connection),
        clockProvider.overrideWithValue(
          () => DateTime.fromMillisecondsSinceEpoch(fixtureNow),
        ),
        ...overrides,
      ],
      child: MaterialApp(
        theme: buildFzTheme(
          fz: FzTheme.fallback,
          applyTextFont: (base) => base.apply(fontFamily: 'Figtree'),
        ),
        home: home,
      ),
    ),
  );
  await settle(tester);
}
