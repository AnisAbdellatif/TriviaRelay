import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/account_providers.dart';
import '../../core/providers/config_providers.dart';
import '../../core/update/app_version.dart';
import '../../shared/navigation.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz.dart';
import '../../shared/widgets/update_banner.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final _server = TextEditingController(
    text: ref.read(serverBaseUrlProvider),
  );

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
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
          label: 'Sign out',
          kind: FzButtonKind.outline,
          onPressed: () async {
            await ref.read(accountProvider.notifier).signOut();
            if (context.mounted) goHome(context);
          },
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const FzEyebrow('Sporcle account'),
            const SizedBox(height: 8),
            Text(account?.handle ?? '—', style: fz.h(22)),
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
