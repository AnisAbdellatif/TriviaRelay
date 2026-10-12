import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/account_providers.dart';
import '../../core/providers/config_providers.dart';
import '../../core/providers/connection_providers.dart';
import '../../core/update/app_version.dart';
import '../../shared/navigation.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz.dart';
import '../../shared/widgets/update_banner.dart';
import 'setting_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final _server = TextEditingController(
    text: ref.read(serverBaseUrlProvider),
  );
  bool _signingOut = false;

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  /// Signing out forgets the seat this phone holds, so it leaves it too, after
  /// asking: a seat nobody can come back to would only sit in the game until
  /// its hold ran out.
  Future<void> _signOut() async {
    final seat = ref.read(currentSeatProvider).value;
    if (seat != null) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign out?'),
          content: Text(
            'You’re still in game ${seat.gameCode}. Signing out leaves it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay'),
            ),
            TextButton(
              key: const Key('confirmSignOutButton'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Leave and sign out'),
            ),
          ],
        ),
      );
      if (leave != true || !mounted) return;
    }
    setState(() => _signingOut = true);
    try {
      if (seat != null) await ref.read(currentSeatProvider.notifier).leave();
      await ref.read(accountProvider.notifier).signOut();
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
    if (mounted) goHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final account = ref.watch(accountProvider).value;

    return Scaffold(
      body: FzPage(
        header: Row(
          children: [
            FzCircleButton(
              icon: Icons.arrow_back,
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 12),
            const Expanded(child: FzEyebrow('Settings')),
          ],
        ),
        footer: FzButton(
          key: const Key('signOutButton'),
          label: _signingOut ? 'Signing out…' : 'Sign out',
          kind: FzButtonKind.outline,
          onPressed: _signingOut ? null : _signOut,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const FzEyebrow('Sporcle account'),
            const SizedBox(height: 8),
            Text(account?.handle ?? '—', style: fz.h(22)),
            const SizedBox(height: 26),
            const DisplayNameField(),
            const SizedBox(height: 26),
            const FzEyebrow('In a game'),
            const SizedBox(height: 4),
            const GameFeedbackSwitches(),
            const SizedBox(height: 26),
            const FzEyebrow('This app'),
            const SizedBox(height: 8),
            Text(
              appVersion.isEmpty ? 'Development build' : 'Version $appVersion',
              style: fz.m(14, color: FzColors.dim),
            ),
            const SizedBox(height: 8),
            const UpdateBanner(),
            if (kDebugMode) ...[
              const SizedBox(height: 26),
              const FzEyebrow('Relay (debug builds only)'),
              const SizedBox(height: 8),
              TextField(
                key: const Key('serverField'),
                controller: _server,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  hintText: 'http://localhost:4100',
                ),
                onSubmitted: (value) => ref
                    .read(serverBaseUrlProvider.notifier)
                    .setDebugOverride(value),
              ),
            ],
            const SizedBox(height: 26),
            Text(
              'Trivia Relay is not made by Sporcle. It plays Sporcle Party '
              'games with your own account, through a relay that holds your '
              'seat while your phone is away.',
              style: fz.m(12, color: FzColors.faint, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
