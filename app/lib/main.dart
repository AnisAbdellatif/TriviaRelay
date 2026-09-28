import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/account/sign_in_screen.dart';
import 'features/home/home_screen.dart';
import 'core/providers/account_providers.dart';
import 'shared/theme/fz_theme.dart';
import 'shared/widgets/fz.dart';

void main() {
  runApp(const ProviderScope(child: TriviaRelayApp()));
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
      home: const RootScreen(),
    );
  }
}

/// Sign-in until there is an account, then home.
class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(accountProvider)) {
      AsyncData(value: null) => const SignInScreen(),
      AsyncData() => const HomeScreen(),
      _ => const Scaffold(
        body: FzBackground(child: Center(child: FzWaiting('Loading'))),
      ),
    };
  }
}
