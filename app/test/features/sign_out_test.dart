import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trivia_relay/core/models/models.dart';
import 'package:trivia_relay/core/providers/account_providers.dart';
import 'package:trivia_relay/core/providers/config_providers.dart';
import 'package:trivia_relay/core/providers/connection_providers.dart';
import 'package:trivia_relay/features/game/question_view.dart';
import 'package:trivia_relay/main.dart';

import '../support/app.dart';
import '../support/fake_seat_connection.dart';
import '../support/pump.dart';

const _alice = SporcleAccount(
  playerId: 'p1',
  token: 't1',
  handle: 'Alice',
  deviceId: '0123456789abcdef',
);

const _seat = SeatTicket(seatId: 's1', seatToken: 'st1', gameCode: '4321');

/// What the device keeps for [account] in [seat] (lib/core/storage/app_store.dart).
Map<String, Object> _kept({
  SporcleAccount? account = _alice,
  SeatTicket? seat = _seat,
  String seatOwner = 'p1',
}) => {
  if (account != null) 'trivia_relay.account': jsonEncode(account.toJson()),
  'trivia_relay.device_id': '0123456789abcdef',
  if (seat != null)
    'trivia_relay.seat': jsonEncode({
      'player_id': seatOwner,
      'ticket': seat.toJson(),
    }),
};

LoginRunner _loginAs(String playerId, String handle) =>
    (email, password, deviceId) async =>
        (playerId: playerId, token: 'fresh', handle: handle);

void main() {
  testWidgets('signing out with a held seat asks, leaves it, and forgets it', (
    tester,
  ) async {
    final connection = FakeSeatConnection();
    await pumpApp(
      tester,
      const RootScreen(),
      connection: connection,
      prefs: _kept(),
    );
    expect(find.byKey(const Key('resumeButton')), findsOneWidget);

    await tapKey(tester, const Key('settingsButton'));
    await tapKey(tester, const Key('signOutButton'));
    expect(find.textContaining('still in game 4321'), findsOneWidget);

    // Staying changes nothing.
    await tester.tap(find.text('Stay'));
    await settle(tester);
    expect(connection.calls, isEmpty);
    expect(find.byKey(const Key('signOutButton')), findsOneWidget);

    await tapKey(tester, const Key('signOutButton'));
    await tapKey(tester, const Key('confirmSignOutButton'));

    expect(connection.calls, containsAllInOrder(['attach:s1', 'leave']));
    expect(find.byKey(const Key('signInButton')), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('trivia_relay.account'), isNull);
    expect(prefs.getString('trivia_relay.seat'), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signing out with no seat just signs out', (tester) async {
    final connection = FakeSeatConnection();
    await pumpApp(
      tester,
      const RootScreen(),
      connection: connection,
      prefs: _kept(seat: null),
    );
    expect(find.byKey(const Key('resumeButton')), findsNothing);

    await tapKey(tester, const Key('settingsButton'));
    await tapKey(tester, const Key('signOutButton'));

    expect(find.byType(AlertDialog), findsNothing);
    expect(connection.calls, isEmpty);
    expect(find.byKey(const Key('signInButton')), findsOneWidget);
  });

  test('an expired sign-in keeps the seat, for the same player only', () async {
    SharedPreferences.setMockInitialValues(_kept());
    var login = _loginAs('p1', 'Alice');
    final container = ProviderContainer(
      overrides: [
        loginRunnerProvider.overrideWith(
          (ref) =>
              (email, password, deviceId) => login(email, password, deviceId),
        ),
      ],
    );
    addTearDown(container.dispose);
    final account = container.read(accountProvider.notifier);

    expect(await container.read(currentSeatProvider.future), _seat);

    await account.expire();
    expect(await container.read(currentSeatProvider.future), isNull);

    // The same player, signing in again, is offered the seat back.
    await account.signIn('alice@example.com', 'pw');
    expect(await container.read(currentSeatProvider.future), _seat);

    // Anybody else is not, and it is gone for good.
    await account.expire();
    login = _loginAs('p2', 'Bob');
    await account.signIn('bob@example.com', 'pw');
    expect(await container.read(currentSeatProvider.future), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('trivia_relay.seat'), isNull);
  });

  test('a seat kept for another player is not offered', () async {
    SharedPreferences.setMockInitialValues(_kept(seatOwner: 'p2'));
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(await container.read(currentSeatProvider.future), isNull);
  });

  testWidgets('a build with no relay says so instead of signing in', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const RootScreen(),
      overrides: [relayConfiguredProvider.overrideWithValue(false)],
    );
    expect(find.byKey(const Key('noRelay')), findsOneWidget);
    expect(find.byKey(const Key('signInButton')), findsNothing);
  });

  testWidgets('a question image is decoded no larger than its box', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(devicePixelRatio: 2),
        child: Center(
          child: SizedBox(
            width: 300,
            child: QuestionImage(url: 'https://images.invalid/huge.png'),
          ),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byKey(const Key('questionImage')));
    final resized = image.image as ResizeImage;
    expect(resized.width, 600);
    expect(resized.height, 440);
    expect(resized.policy, ResizeImagePolicy.fit);
    expect(resized.imageProvider, isA<NetworkImage>());
  });
}
