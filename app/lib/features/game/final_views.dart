import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/connection_providers.dart';
import '../../shared/seat_flow.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/countdown.dart';
import '../../shared/widgets/fz.dart';
import 'game_screen.dart';
import 'player_menu.dart';
import 'players.dart';

/// The final round's vote: an easy, medium or hard last question. Once everybody has
/// voted, the game moves on by itself; the host can move it on sooner.
class FinalVoteView extends ConsumerWidget {
  const FinalVoteView({super.key, required this.state});

  final SeatState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fz = FzTheme.of(context);
    final canAct = ref.watch(seatInteractiveProvider);
    final pending = ref.watch(pendingIntentsProvider);
    final sending = pending['vote'] as String?;
    final vote = state.finalRound?.vote;
    final votes = state.finalRound?.votes ?? const {};
    // A spectating host doesn't vote, as in the official app.
    final spectating = state.you.spectating;

    // The vote cast is shown chosen, with a check, not greyed out like the
    // two left behind.
    Widget choice(String value) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FzButton(
        key: Key('vote-$value'),
        label: _label(value),
        trailing: vote == value
            ? 'your vote'
            : '${votes[value] ?? 0} vote${votes[value] == 1 ? '' : 's'}',
        kind: vote == value || sending == value
            ? FzButtonKind.pink
            : FzButtonKind.outline,
        selected: vote == value,
        busy: sending == value,
        onPressed: vote == null && sending == null && canAct && !spectating
            ? () => act(
                context,
                ref,
                (c) => c.finalVote(value),
                pending: 'vote',
                value: value,
              )
            : null,
      ),
    );

    return FzBody(
      footer: state.you.host
          ? FzButton(
              key: const Key('nextButton'),
              label: 'Move on without the rest',
              kind: FzButtonKind.outline,
              busy: pending.containsKey('next'),
              onPressed: canAct
                  ? () => act(context, ref, (c) => c.next(), pending: 'next')
                  : null,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Text('Final round', style: fz.display(36)),
          const SizedBox(height: 12),
          const FzAccentBars(flare: true),
          const SizedBox(height: 12),
          Text(
            spectating
                ? 'One last question, and the players wager 0, 10 or 20 on '
                      'it. They vote for how hard it is; you’re hosting as a '
                      'spectator.'
                : 'One last question, and you wager 0, 10 or 20 on it. A '
                      'wrong answer costs what you wagered. First: how hard '
                      'should it be?',
            style: fz.body(),
          ),
          const SizedBox(height: 16),
          Countdown(
            deadline: state.deadline,
            pausedRemainingMs: null,
            timeLimitMs: 15000,
          ),
          const SizedBox(height: 20),
          for (final value in FinalRound.voteChoices) choice(value),
          const SizedBox(height: 10),
          const FzEyebrow('Standings'),
          const SizedBox(height: 8),
          FzPanel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Standings(
              state: state,
              onTap: (p) => managePlayer(context, ref, state, p),
            ),
          ),
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
    final canAct = ref.watch(seatInteractiveProvider);
    final pending = ref.watch(pendingIntentsProvider);
    final sending = pending['wager'] as int?;
    final mine = state.finalRound?.wager;
    final picked = state.finalRound?.picked;
    final playing = state.playing;
    final wagered = playing.where((p) => p.finalWagered).length;
    // A spectating host doesn't wager, as in the official app.
    final spectating = state.you.spectating;

    return FzBody(
      footer: state.you.host
          ? FzButton(
              key: const Key('nextButton'),
              label: 'Ask the final question',
              trailing: '$wagered/${playing.length} wagered',
              kind: FzButtonKind.pink,
              busy: pending.containsKey('next'),
              onPressed: canAct
                  ? () => act(context, ref, (c) => c.next(), pending: 'next')
                  : null,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Text(spectating ? 'The wagers' : 'Your wager', style: fz.display(36)),
          const SizedBox(height: 12),
          const FzAccentBars(flare: true),
          const SizedBox(height: 12),
          Text(
            spectating
                ? 'The players wager on the final question'
                      '${picked == null ? '' : ', which is $picked'}. You’re '
                      'hosting as a spectator.'
                : picked == null
                ? 'Right adds it, wrong takes it away.'
                : 'The final question is $picked. Right adds your wager, '
                      'wrong takes it away.',
            style: fz.body(),
          ),
          const SizedBox(height: 16),
          Countdown(
            deadline: state.deadline,
            pausedRemainingMs: null,
            timeLimitMs: 30000,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (final (i, amount) in state.you.wagerChoices.indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _WagerTile(
                    key: Key('finalWager-$amount'),
                    amount: amount,
                    caption: i == 0
                        ? 'safe'
                        : i == state.you.wagerChoices.length - 1
                        ? 'bold'
                        : 'steady',
                    chosen: mine == amount || sending == amount,
                    onPressed:
                        mine == null && sending == null && canAct && !spectating
                        ? () => act(
                            context,
                            ref,
                            (c) => c.finalWager(amount),
                            pending: 'wager',
                            value: amount,
                          )
                        : null,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          const FzEyebrow('Standings'),
          const SizedBox(height: 8),
          FzPanel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                for (final (rank, player) in state.standings.indexed)
                  PlayerRow(
                    player: player,
                    you: player.peerId == state.you.peerId,
                    rank: player.spectating ? null : rank + 1,
                    tag: player.spectating
                        ? null
                        : player.finalWagered
                        ? const FzTag('wagered', color: FzColors.ok)
                        : const FzTag('choosing'),
                    onTap: managePlayer(context, ref, state, player),
                    tapHint: playerMenuHint,
                    trailing: player.spectating
                        ? null
                        : Text(
                            '${player.score}',
                            style: fz.numeral(
                              20,
                              rank == 0 ? FzColors.ac : FzColors.ink,
                            ),
                          ),
                  ),
              ],
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
    final canAct = ref.watch(seatInteractiveProvider);
    final asking = ref.watch(pendingIntentsProvider).containsKey('playAgain');
    // A spectating host didn't play, so can't win.
    final standings = state.standings.where((p) => !p.spectating).toList();
    final top = standings.isEmpty ? null : standings.first.score;
    final winners = standings.where((p) => p.score == top).toList();
    final next = state.finalRound?.nextGameCode;

    return FzBody(
      // Anybody can ask, as in the official app; the host's asking starts
      // the next game in the same room. When it started without this player,
      // Play again joins it by its code.
      footer: next != null
          ? FzButton(
              key: const Key('playAgainButton'),
              label: 'Play again',
              trailing: 'next game $next',
              busy: asking,
              onPressed: () => _joinNext(context, ref, next),
            )
          : FzButton(
              key: const Key('playAgainButton'),
              label: state.you.playedAgain && !state.you.host
                  ? 'Waiting for the host'
                  : 'Play again',
              trailing: state.you.playedAgain ? null : 'same room',
              busy: asking,
              onPressed: state.you.playedAgain || !canAct
                  ? null
                  : () => act(
                      context,
                      ref,
                      (c) => c.playAgain(),
                      pending: 'playAgain',
                    ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const Center(child: FzEyebrow('Final scores', color: FzColors.ac)),
          const SizedBox(height: 10),
          Text(
            winners.isEmpty
                ? 'Game over'
                : winners.length == 1
                ? '${winners.first.name} wins'
                : '${winners.map((p) => p.name).join(' & ')} tie',
            key: const Key('winner'),
            textAlign: TextAlign.center,
            style: fz.display(36),
          ),
          const SizedBox(height: 12),
          const Center(child: FzAccentBars()),
          const SizedBox(height: 40),
          if (winners.isNotEmpty)
            Center(child: _Winners(winners: winners.take(3).toList())),
          const SizedBox(height: 40),
          FzPanel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Standings(
              state: state,
              onTap: (p) => managePlayer(context, ref, state, p),
            ),
          ),
        ],
      ),
    );
  }

  /// The next game started without this player (Sporcle's `leave_behind`):
  /// a seat in it, by its code, in place of this one.
  Future<void> _joinNext(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    try {
      await ref
          .read(pendingIntentsProvider.notifier)
          .run('playAgain', () => rejoinSeat(ref, code));
    } on Object catch (error) {
      if (context.mounted) showError(context, ref, error);
    }
  }
}

/// One of the final wager's three big choices: a hairline tile that turns
/// Flare when it's the one.
class _WagerTile extends StatelessWidget {
  const _WagerTile({
    super.key,
    required this.amount,
    required this.caption,
    required this.chosen,
    required this.onPressed,
  });

  final int amount;

  /// What the amount means (safe, bold), or "chosen" once it is.
  final String caption;
  final bool chosen;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final button = OutlinedButton(
      onPressed: onPressed,
      style:
          OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(120),
            padding: const EdgeInsets.all(12),
            backgroundColor: chosen
                ? FzColors.washOf(FzColors.ac2)
                : FzColors.wash,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ).copyWith(
            side: fzFocusRing(
              otherwise: BorderSide(
                color: chosen ? FzColors.edgeOf(FzColors.ac2) : FzColors.line,
              ),
            ),
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$amount',
            style: fz.numeral(
              48,
              // Once one is chosen the others fade; the chosen one is Flare.
              chosen
                  ? FzColors.ac2
                  : onPressed == null
                  ? FzColors.faint
                  : FzColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (chosen) ...[
                const Icon(Icons.check, size: 14, color: FzColors.ac2),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: FzEyebrow(
                  chosen ? 'chosen' : caption,
                  color: chosen ? FzColors.ac2 : FzColors.dim,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return Semantics(selected: chosen, child: button);
  }
}

/// The winner, or those tied, large and ringed in Signal, with rings spreading
/// behind.
class _Winners extends StatelessWidget {
  const _Winners({required this.winners});

  final List<PlayerView> winners;

  static const _rings = FzRings(
    color: Color(0x38FFD23F),
    first: 62,
    step: 63,
    count: 6,
  );

  @override
  Widget build(BuildContext context) {
    // Each avatar is ringed (16px) and spaced (18px); a tie of three shrinks
    // them to fit a narrow phone rather than running off it.
    final room = math.min(MediaQuery.sizeOf(context).width, 480) - 44;
    final fit = (room - 18 * (winners.length - 1)) / winners.length - 16;
    final size = math.min(winners.length == 1 ? 96.0 : 72.0, fit);
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
                    color: FzColors.bg,
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
