import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/account_providers.dart';
import '../../core/providers/connection_providers.dart';
import '../../shared/navigation.dart';
import '../../shared/seat_flow.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz.dart';
import '../../shared/widgets/update_banner.dart';
import '../host/host_setup_screen.dart';
import '../settings/settings_screen.dart';

/// Join a game by its code, host one, or go back to the game this phone is in.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  static bool validCode(String code) => RegExp(r'^\d{4,8}$').hasMatch(code);

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (error) {
      if (mounted) showError(context, ref, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() => _run(() async {
    final account = ref.read(accountProvider).value;
    if (account == null) return;
    final code = _code.text.trim();
    await openSeat(
      context,
      ref,
      () => ref.read(relayApiProvider).join(account, code),
    );
  });

  Future<void> _resume() => _run(() async {
    final seat = ref.read(currentSeatProvider).value;
    if (seat != null) await attachSeat(context, ref, seat);
  });

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final account = ref.watch(accountProvider).value;
    final seat = ref.watch(currentSeatProvider).value;
    final code = _code.text.trim();

    return Scaffold(
      body: FzPage(
        header: Row(
          children: [
            Expanded(
              child: FzEyebrow('Signed in as ${account?.handle ?? '…'}'),
            ),
            FzCircleButton(
              key: const Key('settingsButton'),
              icon: Icons.settings_outlined,
              tooltip: 'Settings',
              onPressed: () => Navigator.of(
                context,
              ).push(FzPageRoute<void>(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const UpdateBanner(),
            if (seat != null) ...[
              FzButton(
                key: const Key('resumeButton'),
                label: 'Back to game ${seat.gameCode}',
                trailing: 'your seat is held',
                kind: FzButtonKind.pink,
                onPressed: _busy ? null : _resume,
              ),
              const SizedBox(height: 11),
            ],
            FzButton(
              key: const Key('hostButton'),
              label: 'Host a game',
              trailing: 'pick a pack',
              kind: FzButtonKind.outline,
              onPressed: _busy
                  ? null
                  : () => Navigator.of(context).push(
                      FzPageRoute<void>(
                        builder: (_) => const HostSetupScreen(),
                      ),
                    ),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Trivia Relay', style: fz.t(40)),
              const SizedBox(height: 16),
              Container(width: 78, height: 5, color: FzColors.ac2),
              const SizedBox(height: 18),
              Text(
                'Drop out, come back: your seat, your answers and your '
                'score wait for you.',
                style: fz.m(
                  15,
                  weight: FontWeight.w400,
                  color: FzColors.dim,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 34),
              const FzEyebrow('Join a game'),
              const SizedBox(height: 10),
              TextField(
                key: const Key('codeField'),
                controller: _code,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                textAlign: TextAlign.center,
                style: fz.m(30, tracking: .3),
                decoration: const InputDecoration(hintText: 'Game code'),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => validCode(code) ? _join() : null,
              ),
              const SizedBox(height: 12),
              FzButton(
                key: const Key('joinButton'),
                label: _busy ? 'Joining…' : 'Join',
                onPressed: validCode(code) && !_busy ? _join : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
