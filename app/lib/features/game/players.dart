import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz.dart';
import '../../shared/widgets/fz_direction.dart';
import '../../shared/widgets/fz_motion.dart';

/// One player in a list: avatar, name, what's true of them now, and a trailing
/// widget (a score, a mark).
class PlayerRow extends StatelessWidget {
  const PlayerRow({
    super.key,
    required this.player,
    this.you = false,
    this.note,
    this.trailing,
    this.onTap,
    this.highlight,
  });

  final PlayerView player;
  final bool you;
  final String? note;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// A faint wash behind the row, a little wider than it (a guess the host
  /// re-marked).
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final notes = [
      if (you) 'you',
      if (player.host) 'host',
      if (!player.connected) 'away',
      ?note,
    ];
    final row = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Opacity(
              opacity: player.connected ? 1 : .45,
              child: FzAvatar(
                id: '${player.peerId}',
                name: player.name,
                size: 38,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FzDirection(
                    text: player.name,
                    child: Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: fz.h(16, weight: FontWeight.w700),
                    ),
                  ),
                  if (notes.isNotEmpty) FzTag(notes.join(' · ')),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
    final highlight = this.highlight;
    if (highlight == null) return row;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -8,
          right: -8,
          top: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: highlight,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        row,
      ],
    );
  }
}

/// Everybody by score, with the change a question made counting up.
class Standings extends StatelessWidget {
  const Standings({super.key, required this.state, this.gains = const {}});

  final SeatState state;

  /// What the question just scored each player, by peer id.
  final Map<int, int> gains;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final standings = state.standings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (rank, player) in standings.indexed)
          PlayerRow(
            key: ValueKey('standing-${player.peerId}'),
            player: player,
            you: player.peerId == state.you.peerId,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((gains[player.peerId] ?? 0) != 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      _signed(gains[player.peerId]!),
                      style: fz.m(
                        13,
                        color: gains[player.peerId]! > 0
                            ? FzColors.ok
                            : FzColors.ac2,
                      ),
                    ),
                  ),
                FzCountUp(
                  from: player.score - (gains[player.peerId] ?? 0),
                  to: player.score,
                  style: fz.m(
                    20,
                    color: rank == 0 ? FzColors.ac : FzColors.ink,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _signed(int n) => n > 0 ? '+$n' : '$n';
}
