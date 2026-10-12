import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz.dart';
import '../../shared/widgets/fz_direction.dart';
import '../../shared/widgets/fz_toast.dart';
import '../../core/providers/account_providers.dart';
import '../../core/providers/connection_providers.dart';
import '../../shared/seat_flow.dart';
import '../../shared/share_invite.dart';
import '../host/pack_browser_screen.dart';
import '../host/pack_tile.dart';
import '../host/spectate_switch.dart';
import '../invite/invite_friends_sheet.dart';
import 'game_screen.dart';
import 'pack_votes.dart';
import 'player_menu.dart';
import 'players.dart';

/// Before the game: the code to share, the pack, who's here and who's ready.
/// The host starts it.
class LobbyView extends ConsumerWidget {
  const LobbyView({super.key, required this.state});

  final SeatState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fz = FzTheme.of(context);
    final canAct = ref.watch(seatInteractiveProvider);
    final pending = ref.watch(pendingIntentsProvider);
    final me = state.me;
    final ready = me?.ready ?? false;
    final pack = state.pack;

    return FzBody(
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FzButton(
            key: const Key('readyButton'),
            label: ready ? "You're ready" : "I'm ready",
            trailing: ready ? 'tap to undo' : null,
            kind: ready ? FzButtonKind.outline : FzButtonKind.primary,
            busy: pending.containsKey('ready'),
            onPressed: canAct
                ? () => act(
                    context,
                    ref,
                    (c) => c.ready(!ready),
                    pending: 'ready',
                  )
                : null,
          ),
          if (state.you.host) ...[
            const SizedBox(height: 11),
            FzButton(
              key: const Key('startButton'),
              label: 'Start the game',
              trailing:
                  '${state.players.where((p) => p.ready).length}'
                  '/${state.players.length} ready',
              kind: FzButtonKind.pink,
              busy: pending.containsKey('start'),
              onPressed: canAct ? () => _start(context, ref) : null,
            ),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const FzEyebrow('Game code'),
          const SizedBox(height: 6),
          Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    state.gameCode,
                    key: const Key('gameCode'),
                    style: fz.m(44, color: FzColors.ac, tracking: .12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FzCircleButton(
                key: const Key('copyCodeButton'),
                icon: Icons.copy,
                tooltip: 'Copy the code',
                onPressed: () => _copy(context, state.gameCode, 'Code copied.'),
              ),
              const SizedBox(width: 4),
              // A link to the game on the relay (/join/<code>), through the
              // share sheet, or the clipboard where there is none.
              FzCircleButton(
                key: const Key('shareInviteButton'),
                icon: Icons.ios_share,
                tooltip: 'Share an invite link',
                onPressed: () => shareInvite(context, ref, state.gameCode),
              ),
            ],
          ),
          if (pack != null) ...[
            const SizedBox(height: 8),
            FzButton(
              key: const Key('inviteFriendsButton'),
              label: 'Invite friends',
              kind: FzButtonKind.outline,
              height: 48,
              fontSize: 15,
              onPressed: () =>
                  InviteFriendsSheet.show(context, packId: pack.id),
            ),
          ],
          const SizedBox(height: 14),
          if (pack != null)
            FzPanel(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PackImage(url: pack.imageUrl, size: 56),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FzDirection(
                          text: pack.name,
                          child: Text(pack.name.trim(), style: fz.h(20)),
                        ),
                      ),
                    ],
                  ),
                  if ((pack.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    FzDirection(
                      text: pack.description!,
                      child: Text(
                        pack.description!.trim(),
                        style: fz.m(13, color: FzColors.dim, height: 1.4),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  FzTag(
                    '${state.options.questionsPerGame} questions · '
                    '${state.options.questionSeconds}s each · final round',
                    color: FzColors.ac,
                  ),
                ],
              ),
            ),
          if (state.you.host) ...[
            const SizedBox(height: 11),
            FzButton(
              key: const Key('changePackButton'),
              label: 'Change the pack',
              kind: FzButtonKind.outline,
              height: 48,
              fontSize: 15,
              onPressed: canAct ? () => _changePack(context, ref) : null,
            ),
            const SizedBox(height: 16),
            _HostOptions(state: state),
          ],
          PackVotesPanel(state: state),
          const SizedBox(height: 22),
          FzEyebrow('Players · ${state.players.length}'),
          const SizedBox(height: 6),
          for (final player in state.players)
            PlayerRow(
              key: ValueKey('player-${player.peerId}'),
              player: player,
              you: player.peerId == state.you.peerId,
              onTap: managePlayer(context, ref, state, player),
              tapHint: playerMenuHint,
              trailing: player.ready
                  ? const Icon(
                      Icons.check_circle,
                      color: FzColors.ok,
                      size: 20,
                      semanticLabel: 'Ready',
                    )
                  : const Icon(
                      Icons.radio_button_unchecked,
                      color: FzColors.faint,
                      size: 20,
                      semanticLabel: 'Not ready',
                    ),
            ),
        ],
      ),
    );
  }

  static Future<void> _copy(
    BuildContext context,
    String text,
    String done,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) showFzToast(context, done);
  }

  /// Starts the game; with somebody not ready, asks first, as the official
  /// app does.
  Future<void> _start(BuildContext context, WidgetRef ref) async {
    if (state.players.any((p) => !p.ready)) {
      final start = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Not everyone is ready'),
          content: const Text('Start the game anyway?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              key: const Key('confirmStartButton'),
              style: TextButton.styleFrom(foregroundColor: FzColors.ac2),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Start the game'),
            ),
          ],
        ),
      );
      if (start != true || !context.mounted) return;
    }
    await act(context, ref, (c) => c.start(), pending: 'start');
  }

  /// The host picks another pack; everybody stays. The lobby shows it once
  /// Sporcle has it.
  Future<void> _changePack(BuildContext context, WidgetRef ref) async {
    final pack = await PackBrowserScreen.pick(
      context,
      selectedId: state.pack?.id,
    );
    final account = ref.read(accountProvider).value;
    final seat = ref.read(currentSeatProvider).value;
    if (pack == null || account == null || seat == null) return;
    if (pack.id == state.pack?.id) return;
    try {
      await ref.read(relayApiProvider).changePack(account, seat, pack.id);
    } on Object catch (error) {
      if (context.mounted) showError(context, ref, error);
    }
  }
}

/// The host's options, changed in the lobby with `edit_options`. Who may join
/// was chosen when the game was created and isn't reported back, so changing
/// the rest keeps it invite-only.
class _HostOptions extends ConsumerWidget {
  const _HostOptions({required this.state});

  final SeatState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fz = FzTheme.of(context);
    final canAct = ref.watch(seatInteractiveProvider);
    // A change just sent shows at once, ahead of the relay.
    final current =
        ref.watch(pendingIntentsProvider)['options'] as HostOptions? ??
        HostOptions(
          questionsPerGame: state.options.questionsPerGame,
          questionSeconds: state.options.questionSeconds,
          spectate: state.you.spectating,
        );

    void change(HostOptions options) => act(
      context,
      ref,
      (c) => c.options(options),
      pending: 'options',
      value: options,
    );

    Widget chips(
      String prefix,
      List<int> values,
      int selected,
      String Function(int) label,
      HostOptions Function(int) changed,
    ) => Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final value in values)
          ChoiceChip(
            key: Key('$prefix-$value'),
            label: Text(label(value), style: fz.m(12)),
            selected: value == selected,
            onSelected: canAct ? (_) => change(changed(value)) : null,
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        chips(
          'lobbyQuestions',
          HostOptions.questionsPerGameChoices,
          current.questionsPerGame,
          (n) => '$n questions',
          (n) => current.copyWith(questionsPerGame: n),
        ),
        const SizedBox(height: 8),
        chips(
          'lobbySeconds',
          HostOptions.questionSecondsChoices,
          current.questionSeconds,
          (n) => '${n}s',
          (n) => current.copyWith(questionSeconds: n),
        ),
        const SizedBox(height: 4),
        SpectateSwitch(
          key: const Key('lobbySpectate'),
          value: current.spectate,
          onChanged: canAct
              ? (spectate) => change(current.copyWith(spectate: spectate))
              : null,
        ),
      ],
    );
  }
}
