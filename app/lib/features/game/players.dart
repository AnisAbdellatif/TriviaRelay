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
    this.guess,
    this.merge = false,
  });

  final PlayerView player;
  final bool you;
  final String? note;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// What they answered, as they wrote it: its own line, at reading size, in
  /// its own direction. An empty guess shows as a dash.
  final String? guess;

  /// Read out as one thing with its [trailing] control (a guess and the
  /// switch that marks it): one stop for a screen reader, not two.
  final bool merge;

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
    final guess = this.guess;
    Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          FzAvatar(
            id: '${player.peerId}',
            name: player.name,
            size: 38,
            away: !player.connected,
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
                if (guess != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1, bottom: 1),
                    child: FzDirection(
                      text: guess,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          guess.trim().isEmpty ? '—' : guess.trim(),
                          style: fz.h(15, weight: FontWeight.w500, height: 1.3),
                        ),
                      ),
                    ),
                  ),
                if (notes.isNotEmpty) FzTag(notes.join(' · ')),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
    if (onTap != null) {
      row = FzTile(onTap: onTap, radius: 14, child: row);
    }
    if (merge) row = MergeSemantics(child: row);
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
    // Overtaking somebody slides the rows to their new places.
    return FzReorder(
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
