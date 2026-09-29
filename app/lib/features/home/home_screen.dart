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
import '../join/game_browser_screen.dart';
import '../settings/settings_screen.dart';

/// Join a game by its code or from the games open to join, host one, or go
/// back to the game this phone is in.
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

  Future<void> _join() => _joinCode(_code.text.trim());

  Future<void> _browse() async {
    final game = await GameBrowserScreen.pick(context);
    if (game != null) await _joinCode(game.code);
  }

  Future<void> _joinCode(String code) => _run(() async {
    final account = ref.read(accountProvider).value;
    if (account == null) return;
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
            const FzMark(size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: FzEyebrow(
                'Signed in as ${account?.handle ?? '…'}',
                maxLines: 2,
              ),
            ),
            FzCircleButton(
              key: const Key('settingsButton'),
              icon: Icons.tune,
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
          padding: const EdgeInsets.only(top: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // In the page rather than over the buttons, where it pushed the
              // code field off a small screen.
              const UpdateBanner(),
              Text('Trivia Relay', style: fz.t(44)),
              const SizedBox(height: 16),
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: FzAccentBars(),
              ),
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
              const SizedBox(height: 32),
              const FzEyebrow('Join a game'),
              const SizedBox(height: 10),
              // Already 30px: at twice that, six digits ran off a small
              // phone's field. Large text still gets half as big again.
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.5,
                child: TextField(
                  key: const Key('codeField'),
                  controller: _code,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  textAlign: TextAlign.center,
                  style: fz.m(30, tracking: .3),
                  // Room below it for the Join button as it scrolls into view
                  // over the keyboard.
                  scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                  decoration: InputDecoration(
                    hintText: 'Game code',
                    enabledBorder: fzKeyFieldBorder,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => validCode(code) ? _join() : null,
                ),
              ),
              const SizedBox(height: 10),
              FzButton(
                key: const Key('joinButton'),
                label: _busy ? 'Joining…' : 'Join',
                onPressed: validCode(code) && !_busy ? _join : null,
              ),
              const SizedBox(height: 11),
              FzButton(
                key: const Key('browseGamesButton'),
                label: 'Find a game',
                trailing: 'open to join',
                kind: FzButtonKind.outline,
                onPressed: _busy ? null : _browse,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
