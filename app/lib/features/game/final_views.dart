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
          Text('Final round', style: fz.t(34)),
          const SizedBox(height: 8),
          Text(
            'One last question, and you wager 0, 10 or 20 on it. A wrong '
            'answer costs what you wagered. First: how hard should it be?',
            style: fz.m(14, color: FzColors.dim, height: 1.5),
          ),
          const SizedBox(height: 14),
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
          Text('Your wager', style: fz.t(34)),
          const SizedBox(height: 8),
          Text(
            picked == null
                ? 'Right adds it, wrong takes it away.'
                : 'The final question is $picked. Right adds your wager, '
                      'wrong takes it away.',
            style: fz.m(14, color: FzColors.dim, height: 1.5),
          ),
          const SizedBox(height: 14),
          Countdown(
            deadline: state.deadline,
            pausedRemainingMs: null,
            timeLimitMs: 30000,
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              for (final amount in state.you.wagerChoices)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FzButton(
                      key: Key('finalWager-$amount'),
                      label: '$amount',
                      kind: mine == amount
                          ? FzButtonKind.pink
                          : FzButtonKind.outline,
                      onPressed: mine == null
                          ? () => act(context, ref, (c) => c.finalWager(amount))
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const FzEyebrow('Standings'),
          const SizedBox(height: 6),
          for (final player in state.standings)
            PlayerRow(
              player: player,
              you: player.peerId == state.you.peerId,
              note: player.finalWagered ? 'wagered' : null,
              trailing: Text('${player.score}', style: fz.m(20)),
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
          const SizedBox(height: 8),
          const FzEyebrow('Final scores'),
          const SizedBox(height: 8),
          Text(
            winners.isEmpty
                ? 'Game over'
                : winners.length == 1
                ? '${winners.first.name} wins'
                : '${winners.map((p) => p.name).join(' & ')} tie',
            key: const Key('winner'),
            style: fz.t(34, color: FzColors.ac),
          ),
          const SizedBox(height: 22),
          Standings(state: state),
        ],
      ),
    );
  }
}
