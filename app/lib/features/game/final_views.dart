import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/countdown.dart';
import '../../shared/widgets/fz.dart';
import 'game_screen.dart';
import 'players.dart';

/// The final round's vote: an easy, medium or hard last question. Once everybody has
/// voted, the game moves on by itself; the host can move it on sooner.
class FinalVoteView extends ConsumerWidget {
  const FinalVoteView({super.key, required this.state});

  final SeatState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fz = FzTheme.of(context);
    final vote = state.finalRound?.vote;
    final votes = state.finalRound?.votes ?? const {};

    Widget choice(String value) => Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: FzButton(
        key: Key('vote-$value'),
        label: _label(value),
        trailing: vote == value
            ? 'your vote'
            : '${votes[value] ?? 0} vote${votes[value] == 1 ? '' : 's'}',
        kind: vote == value ? FzButtonKind.pink : FzButtonKind.outline,
        onPressed: vote == null
            ? () => act(context, ref, (c) => c.finalVote(value))
            : null,
      ),
    );

    return FzBody(
      footer: state.you.host
          ? FzButton(
              key: const Key('nextButton'),
              label: 'Move on without the rest',
              kind: FzButtonKind.outline,
              onPressed: () => act(context, ref, (c) => c.next()),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text('Final round', style: fz.t(40)),
          const SizedBox(height: 10),
          Text(
            'One last question, and you wager 0, 10 or 20 on it. A wrong '
            'answer costs what you wagered. First: how hard should it be?',
            style: fz.m(15, color: FzColors.dim, height: 1.55),
          ),
          const SizedBox(height: 16),
          Countdown(
            deadline: state.deadline,
            pausedRemainingMs: null,
            timeLimitMs: 15000,
          ),
          const SizedBox(height: 22),
          for (final value in FinalRound.voteChoices) choice(value),
          const SizedBox(height: 14),
          const FzEyebrow('Standings'),
          const SizedBox(height: 6),
          Standings(state: state),
        ],
      ),
    );
  }

  static String _label(String choice) =>
      choice[0].toUpperCase() + choice.substring(1);
}

/// The final wager: 0, 10 or 20, once. The host asks the final question when
/// the wagers are in.
class FinalWagerView extends ConsumerWidget {
  const FinalWagerView({super.key, required this.state});

  final SeatState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fz = FzTheme.of(context);
    final mine = state.finalRound?.wager;
    final picked = state.finalRound?.picked;
    final wagered = state.players.where((p) => p.finalWagered).length;

    return FzBody(
      footer: state.you.host
          ? FzButton(
              key: const Key('nextButton'),
              label: 'Ask the final question',
              trailing: '$wagered/${state.players.length} wagered',
              kind: FzButtonKind.pink,
              onPressed: () => act(context, ref, (c) => c.next()),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text('Your wager', style: fz.t(40)),
          const SizedBox(height: 10),
          Text(
            picked == null
                ? 'Right adds it, wrong takes it away.'
                : 'The final question is $picked. Right adds your wager, '
                      'wrong takes it away.',
            style: fz.m(15, color: FzColors.dim, height: 1.55),
          ),
          const SizedBox(height: 16),
          Countdown(
            deadline: state.deadline,
            pausedRemainingMs: null,
            timeLimitMs: 30000,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              for (final (i, amount) in state.you.wagerChoices.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _WagerTile(
                    key: Key('finalWager-$amount'),
                    amount: amount,
                    chosen: mine == amount,
                    onPressed: mine == null
                        ? () => act(context, ref, (c) => c.finalWager(amount))
                        : null,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 26),
          const FzEyebrow('Standings'),
          const SizedBox(height: 4),
          for (final (rank, player) in state.standings.indexed)
            PlayerRow(
              player: player,
              you: player.peerId == state.you.peerId,
              note: player.finalWagered ? 'wagered' : null,
              trailing: Text(
                '${player.score}',
                style: fz.m(20, color: rank == 0 ? FzColors.ac : FzColors.ink),
              ),
            ),
        ],
      ),
    );
  }
}

/// The end of the game.
class FinalScoresView extends ConsumerWidget {
  const FinalScoresView({super.key, required this.state});

  final SeatState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fz = FzTheme.of(context);
    final standings = state.standings;
    final top = standings.isEmpty ? null : standings.first.score;
    final winners = standings.where((p) => p.score == top).toList();

    return FzBody(
      // Anybody can ask, as in the official app; the host's asking starts
      // the next game in the same room.
      footer: FzButton(
        key: const Key('playAgainButton'),
        label: state.you.playedAgain && !state.you.host
            ? 'Waiting for the host'
            : 'Play again',
        trailing: state.you.playedAgain ? null : 'same room',
        onPressed: state.you.playedAgain
            ? null
            : () => act(context, ref, (c) => c.playAgain()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 22),
          if (winners.isNotEmpty)
            Center(child: _Winners(winners: winners.take(3).toList())),
          const SizedBox(height: 14),
          const Center(child: FzEyebrow('Final scores')),
          const SizedBox(height: 14),
          Text(
            winners.isEmpty
                ? 'Game over'
                : winners.length == 1
                ? '${winners.first.name} wins'
                : '${winners.map((p) => p.name).join(' & ')} tie',
            key: const Key('winner'),
            textAlign: TextAlign.center,
            style: fz.t(48, color: FzColors.ac),
          ),
          const SizedBox(height: 14),
          const Center(child: FzAccentBars()),
          const SizedBox(height: 30),
          Standings(state: state),
        ],
      ),
    );
  }
}

/// One of the final wager's three big choices: a hairline tile that turns
/// Flare when it's the one.
class _WagerTile extends StatelessWidget {
  const _WagerTile({
    super.key,
    required this.amount,
    required this.chosen,
    required this.onPressed,
  });

  final int amount;
  final bool chosen;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(88),
        padding: EdgeInsets.zero,
        backgroundColor: chosen
            ? FzColors.ac2.withValues(alpha: .14)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(
          color: chosen ? FzColors.ac2 : FzColors.line,
          width: 1.5,
        ),
      ),
      child: Text(
        '$amount',
        style: fz.m(
          34,
          weight: FontWeight.w400,
          // Once one is chosen the others fade; the chosen one stays bright.
          color: onPressed == null && !chosen ? FzColors.faint : FzColors.ink,
        ),
      ),
    );
  }
}

/// The winner, or those tied, large and ringed in Signal, with rings spreading
/// behind.
class _Winners extends StatelessWidget {
  const _Winners({required this.winners});

  final List<PlayerView> winners;

  static const _rings = FzRings(
    color: Color(0x1AFFD23F),
    first: 70,
    step: 60,
    count: 6,
  );

  @override
  Widget build(BuildContext context) {
    final size = winners.length == 1 ? 96.0 : 72.0;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          left: -_rings.radius,
          right: -_rings.radius,
          top: -_rings.radius,
          bottom: -_rings.radius,
          child: const Center(child: _rings),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, player) in winners.indexed) ...[
              if (i > 0) const SizedBox(width: 18),
              // A gap of page, then a Signal ring.
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: FzColors.ac,
                ),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: FzColors.bgDeep,
                  ),
                  child: FzAvatar(
                    id: '${player.peerId}',
                    name: player.name,
                    size: size,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
