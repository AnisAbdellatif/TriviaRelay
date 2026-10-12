import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/game/social.dart';
import '../../core/models/models.dart';
import '../../core/providers/config_providers.dart';
import '../../core/providers/connection_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../shared/seat_flow.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz_direction.dart';
import '../../shared/widgets/fz_toast.dart';
import 'game_effects.dart';
import 'game_screen.dart';

part 'player_menu.g.dart';

/// What a player can do to another from the official app's player menu: send
/// them a sound (the honk), and, for the host, hand them the host or take them
/// out of the game, for now ("Remove", they may join again) or for good
/// ("Kick"). The host's ask first.
enum PlayerAction { honk, makeHost, remove, kick }

/// Whether this seat may open [player]'s menu: anybody, on anybody else who is
/// there, as the official app offers it (not on a player who is away).
/// With [bypass] the connected check is waived (bypass secret is set in Settings).
bool canOpenMenu(SeatState state, PlayerView player, {bool bypass = false}) =>
    player.peerId != state.you.peerId && (player.connected || bypass);

/// What tapping [player]'s row does here: their menu, when this seat may open
/// it and the game can be acted on; nothing otherwise.
VoidCallback? managePlayer(
  BuildContext context,
  WidgetRef ref,
  SeatState state,
  PlayerView player,
) {
  final bypass = ref.watch(kickBypassTokenProvider).value != null;
  if (!canOpenMenu(state, player, bypass: bypass) ||
      !ref.watch(seatInteractiveProvider)) {
    return null;
  }
  return () => showPlayerMenu(context, ref, player, host: state.you.host);
}

/// What a screen reader says a player row's tap does.
const playerMenuHint = 'open the player menu';

/// When this app last sent a reaction: the relay takes one every
/// [GameRules.reactionGapMs], as the official app sends them.
@Riverpod(keepAlive: true)
class LastReaction extends _$LastReaction {
  @override
  DateTime? build() => null;

  void sent(DateTime at) => state = at;
}

/// Whether a reaction may be sent now, or the last is too recent.
bool reactionReady(WidgetRef ref) {
  final last = ref.read(lastReactionProvider);
  if (last == null) return true;
  final since = ref.read(clockProvider)().difference(last).inMilliseconds;
  return since >= GameRules.reactionGapMs;
}

/// [player]'s menu, then (for the host's actions) the confirmation, then the
/// intent. [host] adds the host's actions.
///
/// When the bypass token is active and [player] is away, only Remove and Kick are
/// offered (Honk and Make Host require the player to be connected). The token
/// persists — the host may kick multiple away players without re-entering anything.
Future<void> showPlayerMenu(
  BuildContext context,
  WidgetRef ref,
  PlayerView player, {
  required bool host,
}) async {
  final bypassToken = ref.read(kickBypassTokenProvider).value;
  final awayBypass = bypassToken != null && !player.connected;

  final action = await showModalBottomSheet<PlayerAction>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _PlayerMenu(
      player: player,
      host: host,
      canReact: reactionReady(ref),
      awayBypass: awayBypass,
    ),
  );
  if (action == null || !context.mounted) return;
  if (action == PlayerAction.honk) return _honk(context, ref, player);
  if (await _confirm(context, action, player) != true || !context.mounted) {
    return;
  }
  await act(
    context,
    ref,
    (c) => switch (action) {
      PlayerAction.honk => c.react(player.peerId),
      PlayerAction.makeHost => c.makeHost(player.peerId),
      PlayerAction.remove => c.remove(
        player.peerId,
        ban: false,
        bypassToken: awayBypass ? bypassToken : null,
      ),
      PlayerAction.kick => c.remove(
        player.peerId,
        ban: true,
        bypassToken: awayBypass ? bypassToken : null,
      ),
    },
    pending: 'player:${player.peerId}',
  );
}

/// The honk: played here too, as the official app does, and said.
Future<void> _honk(
  BuildContext context,
  WidgetRef ref,
  PlayerView player,
) async {
  const type = 'goose';
  ref.read(lastReactionProvider.notifier).sent(ref.read(clockProvider)());
  ref.read(gameEffectsProvider.notifier).playReaction(type);
  try {
    await ref.read(seatConnectionProvider).react(player.peerId, type: type);
    if (context.mounted) {
      showFzToast(
        context,
        'You honked at ${isolate(player.name.trim())}',
        duration: const Duration(seconds: 2),
      );
    }
  } on Object catch (error) {
    if (context.mounted) showError(context, ref, error);
  }
}

Future<bool?> _confirm(
  BuildContext context,
  PlayerAction action,
  PlayerView player,
) {
  final name = player.name.trim();
  final (title, body, verb) = switch (action) {
    PlayerAction.makeHost => (
      'Make $name the host?',
      'They run the game from now on, and you play like everybody else.',
      'Make host',
    ),
    PlayerAction.remove => (
      'Remove $name?',
      'They leave the game, and can join again with the code.',
      'Remove',
    ),
    PlayerAction.kick || PlayerAction.honk => (
      'Kick $name?',
      'They leave the game and can’t come back to it.',
      'Kick',
    ),
  };
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: FzDirection(text: name, child: Text(title)),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const Key('confirmPlayerActionButton'),
          style: TextButton.styleFrom(
            foregroundColor: action == PlayerAction.makeHost
                ? FzColors.ac
                : FzColors.ac2,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(verb),
        ),
      ],
    ),
  );
}

class _PlayerMenu extends StatelessWidget {
  const _PlayerMenu({
    required this.player,
    required this.host,
    required this.canReact,
    this.awayBypass = false,
  });

  final PlayerView player;
  final bool host;

  /// False just after a reaction was sent: the next waits a moment.
  final bool canReact;

  /// True when the host opened this menu for an away player using the bypass
  /// secret: Honk and Make Host are hidden (they require the player to be there).
  final bool awayBypass;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    Widget item(
      PlayerAction action,
      IconData icon,
      String label,
      String detail, {
      Color color = FzColors.ink,
      bool enabled = true,
    }) => ListTile(
      key: Key('playerAction-${action.name}'),
      minTileHeight: 56,
      enabled: enabled,
      leading: Icon(icon, color: enabled ? color : FzColors.faint),
      title: Text(
        label,
        style: fz.h(16, color: enabled ? color : FzColors.dim),
      ),
      subtitle: Text(detail, style: fz.m(12, color: FzColors.dim)),
      onTap: () => Navigator.of(context).pop(action),
    );

    final reactions = player.reactions.total;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FzDirection(
                    text: player.name,
                    child: Text(
                      player.name.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: fz.h(20),
                    ),
                  ),
                  if (reactions > 0)
                    Text(
                      reactions == 1
                          ? '1 reaction this game'
                          : '$reactions reactions this game',
                      style: fz.m(12, color: FzColors.dim),
                    ),
                ],
              ),
            ),
            if (!awayBypass)
              item(
                PlayerAction.honk,
                Icons.campaign_outlined,
                'Honk',
                canReact ? 'A honk plays on their phone' : 'Wait a moment',
                color: FzColors.ac,
                enabled: canReact,
              ),
            if (host) ...[
              if (!awayBypass)
                item(
                  PlayerAction.makeHost,
                  Icons.star_outline,
                  'Make host',
                  'Hand them the game',
                ),
              item(
                PlayerAction.remove,
                Icons.logout,
                'Remove',
                'They can join again',
              ),
              item(
                PlayerAction.kick,
                Icons.block,
                'Kick',
                'They can’t come back',
                color: FzColors.ac2,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
