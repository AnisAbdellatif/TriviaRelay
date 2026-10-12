import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/connection_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz_direction.dart';
import 'game_screen.dart';

/// A floating action button shown in the lobby and during the game when the
/// kick bypass is active. Tapping opens a sheet with:
///   - "Become host" (when not already the host), and
///   - "Kick a player" (opens a player-picker with all players, including away).
///
/// Only shown when bypass is active, the seat is interactive and the game is
/// in progress (not ended, not leaving).
class BypassFab extends ConsumerWidget {
  const BypassFab({super.key, required this.state});

  final SeatState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(kickBypassTokenProvider).value;
    if (token == null) return const SizedBox.shrink();
    if (!ref.watch(seatInteractiveProvider)) return const SizedBox.shrink();

    return FloatingActionButton.small(
      key: const Key('bypassFab'),
      tooltip: 'Bypass menu',
      backgroundColor: FzColors.ac2,
      foregroundColor: FzColors.ink,
      onPressed: () => _showBypassSheet(context, ref, state, token),
      child: const Icon(Icons.admin_panel_settings_outlined),
    );
  }
}

Future<void> _showBypassSheet(
  BuildContext context,
  WidgetRef ref,
  SeatState state,
  String token,
) async {
  final action = await showModalBottomSheet<_BypassAction>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _BypassSheet(state: state),
  );
  if (action == null || !context.mounted) return;

  switch (action) {
    case _BypassAction.becomeHost:
      await act(context, ref, (c) => c.claimHost(token), pending: 'claim_host');

    case _BypassAction.kickPlayer:
      if (!context.mounted) return;
      await _showKickPicker(context, ref, state, token);
  }
}

/// Opens a sheet listing all players (including away) for the host to kick.
Future<void> _showKickPicker(
  BuildContext context,
  WidgetRef ref,
  SeatState state,
  String token,
) async {
  final target = await showModalBottomSheet<PlayerView>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _KickPicker(state: state),
  );
  if (target == null || !context.mounted) return;

  // Reuse the existing confirmation dialog from player_menu.dart.
  final confirmed = await _confirmKick(context, target);
  if (confirmed != true || !context.mounted) return;

  final awayBypass = !target.connected;
  await act(
    context,
    ref,
    (c) => c.remove(
      target.peerId,
      ban: true,
      bypassToken: awayBypass ? token : null,
    ),
    pending: 'player:${target.peerId}',
  );
}

Future<bool?> _confirmKick(BuildContext context, PlayerView player) {
  final name = player.name.trim();
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: FzDirection(text: name, child: Text('Kick $name?')),
      content: Text(
        player.connected
            ? "They leave the game and can’t come back to it."
            : "They are away — this will end their seat and they can’t rejoin.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const Key('confirmBypassKickButton'),
          style: TextButton.styleFrom(foregroundColor: FzColors.ac2),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Kick'),
        ),
      ],
    ),
  );
}

enum _BypassAction { becomeHost, kickPlayer }

class _BypassSheet extends StatelessWidget {
  const _BypassSheet({required this.state});

  final SeatState state;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final others = [
      for (final p in state.players)
        if (p.peerId != state.you.peerId) p,
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: Text('Bypass actions', style: fz.h(18)),
            ),
            if (!state.you.host)
              ListTile(
                key: const Key('bypassBecomeHost'),
                leading: const Icon(Icons.star_outline),
                title: Text('Become host', style: fz.h(16)),
                subtitle: Text(
                  'Take over the game',
                  style: fz.m(12, color: FzColors.dim),
                ),
                onTap: () =>
                    Navigator.of(context).pop(_BypassAction.becomeHost),
              ),
            ListTile(
              key: const Key('bypassKickPlayer'),
              leading: const Icon(Icons.block, color: FzColors.ac2),
              title: Text(
                'Kick a player',
                style: fz.h(16, color: FzColors.ac2),
              ),
              subtitle: Text(
                others.isEmpty ? 'No other players' : 'Pick a player to remove',
                style: fz.m(12, color: FzColors.dim),
              ),
              enabled: others.isNotEmpty,
              onTap: others.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_BypassAction.kickPlayer),
            ),
          ],
        ),
      ),
    );
  }
}

class _KickPicker extends StatelessWidget {
  const _KickPicker({required this.state});

  final SeatState state;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final others = [
      for (final p in state.players)
        if (p.peerId != state.you.peerId) p,
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: Text('Kick who?', style: fz.h(18)),
            ),
            for (final player in others)
              ListTile(
                key: Key('kickTarget-${player.peerId}'),
                leading: Icon(
                  player.connected
                      ? Icons.person_outline
                      : Icons.person_off_outlined,
                  color: player.connected ? FzColors.ink : FzColors.dim,
                ),
                title: FzDirection(
                  text: player.name,
                  child: Text(
                    player.name.trim(),
                    style: fz.h(16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                subtitle: Text(
                  player.connected ? 'Connected' : 'Away',
                  style: fz.m(12, color: FzColors.dim),
                ),
                onTap: () => Navigator.of(context).pop(player),
              ),
          ],
        ),
      ),
    );
  }
}
