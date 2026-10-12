import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/account/sign_in_screen.dart';
import 'features/home/home_screen.dart';
import 'core/invite/invite_link.dart';
import 'core/providers/account_providers.dart';
import 'core/providers/config_providers.dart';
import 'core/providers/settings_providers.dart';
import 'shared/platform/platform.dart';
import 'shared/theme/fz_theme.dart';
import 'shared/widgets/fz.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Flutter's web build draws on a canvas and only builds the tree a screen
  // reader reads once somebody asks for it, which most never find how to do.
  // Built from the start, the web app is readable, and its buttons are real
  // buttons to the browser. The handle is never disposed: on for good.
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();

  final container = ProviderContainer();
  // An invite link (`/join/<code>`) the app was opened at, and any that come
  // in while it runs (Android hands those over as routes): each is offered on
  // the home screen, never joined by itself. Registered before the app, so
  // this is the first to see a link and the Navigator never tries it as a
  // route.
  final invites = container.read(pendingInviteProvider.notifier);
  invites.offer(inviteCodeFromRoute(launchRoute()));
  WidgetsBinding.instance.addObserver(_InviteLinks(invites.offer));

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TriviaRelayApp(),
    ),
  );
}

/// Takes an invite link pushed to the running app, and nothing else.
class _InviteLinks with WidgetsBindingObserver {
  _InviteLinks(this.offer);

  final void Function(String? code) offer;

  @override
  Future<bool> didPushRouteInformation(RouteInformation info) async {
    final code = inviteCode(info.uri);
    if (code == null) return false;
    offer(code);
    return true;
  }
}

class TriviaRelayApp extends StatelessWidget {
  const TriviaRelayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trivia Relay',
      debugShowCheckedModeBanner: false,
      // The fonts are bundled (pubspec `fonts:`): nothing is fetched at runtime.
      theme: buildFzTheme(
        fz: FzTheme.fallback,
        applyTextFont: (base) => base.apply(fontFamily: 'Figtree'),
      ),
      // One screen to start on, whatever route the app was opened at: an
      // invite link's path is read above, not pushed as pages.
      onGenerateInitialRoutes: (_) => [
        MaterialPageRoute<void>(builder: (_) => const RootScreen()),
      ],
      onGenerateRoute: (settings) => settings.name == Navigator.defaultRouteName
          ? MaterialPageRoute<void>(builder: (_) => const RootScreen())
          : null,
    );
  }
}

/// Sign-in until there is an account, then home. A build with no relay to talk
/// to shows only that.
class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(relayConfiguredProvider)) return const _NoRelayScreen();
    return switch (ref.watch(accountProvider)) {
      AsyncData(value: null) => const SignInScreen(),
      AsyncData() => const HomeScreen(),
      _ => const Scaffold(
        body: FzBackground(child: Center(child: FzWaiting('Loading'))),
      ),
    };
  }
}

/// A release build made without SERVER_URL: it has nowhere to send a sign-in,
/// and must not guess. Only a hand-made build gets here; `scripts/ci.sh apk`
/// refuses to make one.
class _NoRelayScreen extends StatelessWidget {
  const _NoRelayScreen();

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    return Scaffold(
      body: FzPage(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            key: const Key('noRelay'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FzEyebrow('This build is not set up'),
              const SizedBox(height: 14),
              Text('No relay', style: fz.t(44)),
              const SizedBox(height: 18),
              Text(
                'This copy of Trivia Relay was built without the address of '
                'its relay, so it has nowhere to sign you in. Install the '
                'release from GitHub instead.',
                style: fz.m(
                  15,
                  weight: FontWeight.w400,
                  color: FzColors.dim,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
