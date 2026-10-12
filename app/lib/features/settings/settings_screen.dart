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
            const FzEyebrow('Host tools'),
            const SizedBox(height: 8),
            const _KickBypassField(),
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
          const Icon(Icons.check_circle_outline, size: 18, color: FzColors.ac),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Bypass active', style: fz.m(14, color: FzColors.ac)),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('kickBypassField'),
                controller: _controller,
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                enabled: !_loading,
                decoration: const InputDecoration(
                  hintText: 'One-time bypass code',
                ),
                onSubmitted: (_) => _activate(),
              ),
            ),
            const SizedBox(width: 8),
            _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: _activate,
                    child: const Text('Activate'),
                  ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_error!, style: fz.m(11, color: FzColors.ac2)),
          ),
      ],
    );
  }
}
