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
      padding: const EdgeInsets.only(bottom: 11),
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
          const SizedBox(height: 8),
          Text('Final round', style: fz.t(40)),
          const SizedBox(height: 10),
          Text(
            spectating
                ? 'One last question, and the players wager 0, 10 or 20 on '
                      'it. They vote for how hard it is; you’re hosting as a '
                      'spectator.'
                : 'One last question, and you wager 0, 10 or 20 on it. A '
                      'wrong answer costs what you wagered. First: how hard '
                      'should it be?',
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
          Standings(
            state: state,
            onTap: (p) => managePlayer(context, ref, state, p),
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
          const SizedBox(height: 8),
          Text(spectating ? 'The wagers' : 'Your wager', style: fz.t(40)),
          const SizedBox(height: 10),
          Text(
            spectating
                ? 'The players wager on the final question'
                      '${picked == null ? '' : ', which is $picked'}. You’re '
                      'hosting as a spectator.'
                : picked == null
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
          const SizedBox(height: 26),
          const FzEyebrow('Standings'),
          const SizedBox(height: 4),
          for (final (rank, player) in state.standings.indexed)
            PlayerRow(
              player: player,
              you: player.peerId == state.you.peerId,
              note: player.finalWagered ? 'wagered' : null,
              onTap: managePlayer(context, ref, state, player),
              tapHint: playerMenuHint,
              trailing: player.spectating
                  ? null
                  : Text(
                      '${player.score}',
                      style: fz.m(
                        20,
                        color: rank == 0 ? FzColors.ac : FzColors.ink,
                      ),
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
          Standings(
            state: state,
            onTap: (p) => managePlayer(context, ref, state, p),
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
    required this.chosen,
    required this.onPressed,
  });

  final int amount;
  final bool chosen;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final button = OutlinedButton(
      onPressed: onPressed,
      style:
          OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(88),
            padding: EdgeInsets.zero,
            backgroundColor: chosen
                ? FzColors.ac2.withValues(alpha: .14)
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ).copyWith(
            side: fzFocusRing(
              otherwise: BorderSide(
                color: chosen ? FzColors.ac2 : FzColors.edge,
                width: 1.5,
              ),
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
    return Semantics(selected: chosen, child: button);
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
