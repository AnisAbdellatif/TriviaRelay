import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_relay/core/providers/account_providers.dart';
import 'package:trivia_relay/features/host/host_setup_screen.dart';
import 'package:trivia_relay/main.dart';

import '../support/app.dart';
import '../support/pump.dart';

void main() {
  testWidgets('with no account, the app asks for a Sporcle sign-in', (
    tester,
  ) async {
    String? used;
    await pumpApp(
      tester,
      const RootScreen(),
      overrides: [
        loginRunnerProvider.overrideWithValue((
          email,
          password,
          deviceId,
        ) async {
          used = '$email:$password';
          return (playerId: 'p1', token: 't', handle: 'QuizFan');
        }),
      ],
    );
    expect(find.byKey(const Key('signInButton')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('emailField')), 'a@b.c');
    await tester.enterText(find.byKey(const Key('passwordField')), 'secret');
    await settle(tester);
    await tapKey(tester, const Key('signInButton'));

    expect(used, 'a@b.c:secret');
    expect(find.text('SIGNED IN AS QUIZFAN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('host setup defaults to an invite-only game', (tester) async {
    await pumpApp(tester, const HostSetupScreen());
    final chip = tester.widget<ChoiceChip>(
      find.byKey(const Key('audience-Audience.private')),
    );
    expect(chip.selected, isTrue);
    await tapKey(tester, const Key('audience-Audience.anyone'));
    expect(find.textContaining('strangers join'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
