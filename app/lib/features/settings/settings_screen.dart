import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/account_providers.dart';
import '../../core/providers/config_providers.dart';
import '../../core/providers/connection_providers.dart';
import '../../core/providers/settings_providers.dart';
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
    final seat = ref.watch(currentSeatProvider).value;

    return Scaffold(
      body: FzPage(
        header: const FzHeaderRow(title: 'Settings', eyebrow: true),
        footer: FzButton(
          key: const Key('signOutButton'),
          label: _signingOut ? 'Signing out…' : 'Sign out',
          kind: FzButtonKind.danger,
          onPressed: _signingOut ? null : _signOut,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            FzPanel(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  FzAvatar(
                    id: account?.handle ?? '',
                    name: account?.shownName ?? account?.handle ?? '?',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FzEyebrow('Sporcle account'),
                        const SizedBox(height: 2),
                        Text(
                          account?.handle ?? '—',
                          style: fz.h(16, weight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const DisplayNameField(),
            const SizedBox(height: 20),
            const FzEyebrow('In a game'),
            const SizedBox(height: 8),
            const GameFeedbackSwitches(),
            if (seat != null) ...[
              const SizedBox(height: 14),
              FzPanel.tone(
                FzColors.ok,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    FzBanner.dot(FzColors.ok),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your seat in ${seat.gameCode} is held.',
                        style: fz.small(13.5, FzColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            const FzEyebrow('This app'),
            const SizedBox(height: 6),
            Text(
              appVersion.isEmpty ? 'Development build' : 'Version $appVersion',
              style: fz.small(13.5, FzColors.ink),
            ),
            const SizedBox(height: 8),
            const UpdateBanner(),
            if (kDebugMode) ...[
              const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            const FzEyebrow('Host tools'),
            const SizedBox(height: 8),
            const _KickBypassField(),
            const SizedBox(height: 24),
            Text(
              'Trivia Relay is not made by Sporcle. It plays Sporcle Party '
              'games with your own account, through a relay that holds your '
              'seat while your phone is away.',
              style: fz.small(13, FzColors.faint),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lets the host activate (redeem a one-time code) or deactivate the kick bypass.
/// While active, the player menu opens for away players too.
/// The bearer token persists across app restarts.
class _KickBypassField extends ConsumerStatefulWidget {
  const _KickBypassField();

  @override
  ConsumerState<_KickBypassField> createState() => _KickBypassFieldState();
}

class _KickBypassFieldState extends ConsumerState<_KickBypassField> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(kickBypassTokenProvider.notifier).activate(code);
      _controller.clear();
    } on Object catch (e) {
      setState(() => _error = _describeError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _describeError(Object e) {
    if (e is GameError) {
      return switch (e.code) {
        'not_found' => 'Code not found.',
        'already_used' => 'Code already used.',
        'bypass_disabled' => 'Bypass not enabled on this relay.',
        _ => e.message ?? 'Activation failed.',
      };
    }
    return 'Could not reach the relay.';
  }

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final tokenState = ref.watch(kickBypassTokenProvider);
    final active = tokenState.value != null;

    if (active) {
      return Row(
        children: [
          const Icon(Icons.check, size: 22, color: FzColors.ok),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bypass active',
              style: fz.h(15, weight: FontWeight.w600, color: FzColors.ok),
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(kickBypassTokenProvider.notifier).deactivate(),
            child: const Text('Deactivate'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FzInlineAction(
          field: TextField(
            key: const Key('kickBypassField'),
            controller: _controller,
            obscureText: true,
            keyboardType: TextInputType.visiblePassword,
            enabled: !_loading,
            decoration: const InputDecoration(hintText: 'One-time bypass code'),
            onSubmitted: (_) => _activate(),
          ),
          action: FzButton(
            label: 'Activate',
            kind: FzButtonKind.outline,
            expand: false,
            height: 56,
            fontSize: 16,
            radius: 16,
            busy: _loading,
            onPressed: _activate,
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: fz.small(13.5, FzColors.ac2)),
          ),
      ],
    );
  }
}
