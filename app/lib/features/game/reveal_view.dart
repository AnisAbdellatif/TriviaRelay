import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/connection_providers.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz.dart';
import '../../shared/widgets/fz_direction.dart';
import 'game_screen.dart';
import 'players.dart';

/// A revealed question: the answer and everybody's guess. The host marks each
/// guess right or wrong (Sporcle's own check is exact-match, so a spelling or
/// another language needs a person), confirms, and moves on.
class RevealView extends ConsumerWidget {
  const RevealView({super.key, required this.state});

  final SeatState state;

  bool get _final => state.phase == Phase.finalReveal;

  /// The host's mark while judging, else what Sporcle decided.
  bool _correct(RevealAnswer answer) =>
      state.you.judgements['${answer.peerId}'] ?? answer.correct;

  /// The host marked it otherwise than Sporcle's exact match did.
  bool _remarked(RevealAnswer answer) => _correct(answer) != answer.correct;

  String get _nextLabel {
    if (_final) return 'Show the final scores';
    final index = state.question?.index ?? 0;
    return index >= state.options.questionsPerGame - 1
        ? 'On to the final round'
        : 'Next question';
  }

  /// Moving on before the marks are confirmed scores nothing for the
  /// question (protocol/PROTOCOL.md §6.1), so it is asked first.
  Future<void> _next(BuildContext context, WidgetRef ref) async {
    if (!state.you.judged) {
      final skip = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            _final ? 'Skip scoring the final?' : 'Skip scoring this question?',
          ),
          content: const Text(
            "The marks aren't confirmed, so nobody scores for it. To score "
            'it, go back and confirm the marks first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Go back'),
            ),
            TextButton(
              key: const Key('confirmSkipButton'),
              style: TextButton.styleFrom(foregroundColor: FzColors.ac2),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Skip scoring'),
            ),
          ],
        ),
      );
      if (skip != true || !context.mounted) return;
    }
    await act(context, ref, (c) => c.next(), pending: 'next');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fz = FzTheme.of(context);
    final reveal = state.reveal;
    final host = state.you.host;
    final judged = state.you.judged;
    final canAct = ref.watch(seatInteractiveProvider);
    final pending = ref.watch(pendingIntentsProvider);

    /// The mark shown: the one just sent, ahead of the relay, else the
    /// snapshot's.
    bool mark(RevealAnswer answer) =>
        pending['judge:${answer.peerId}'] as bool? ?? _correct(answer);

    void judge(RevealAnswer answer, bool right) => act(
      context,
      ref,
      (c) => c.judge(answer.peerId, right),
      pending: 'judge:${answer.peerId}',
      value: right,
    );

    final gains = {
      if (judged)
        for (final a in reveal?.answers ?? const <RevealAnswer>[])
          a.peerId: _correct(a) ? a.wager : (_final ? -a.wager : 0),
    };

    return FzBody(
      // While the marks are open, confirming them is the main action; moving
      // on without them asks first, since it scores nothing.
      footer: host
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!judged) ...[
                  FzButton(
                    key: const Key('confirmMarksButton'),
                    label: 'Confirm the marks',
                    trailing: 'scores them',
                    busy: pending.containsKey('judgeSubmit'),
                    onPressed: canAct
                        ? () => act(
                            context,
                            ref,
                            (c) => c.judgeSubmit(),
                            pending: 'judgeSubmit',
                          )
                        : null,
                  ),
                  const SizedBox(height: 11),
                ],
                FzButton(
                  key: const Key('nextButton'),
                  label: _nextLabel,
                  trailing: judged ? null : 'without scores',
                  kind: judged ? FzButtonKind.pink : FzButtonKind.outline,
                  busy: pending.containsKey('next'),
                  onPressed: canAct ? () => _next(context, ref) : null,
                ),
              ],
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          if (state.question != null)
            FzDirection(
              text: state.question!.text,
              child: Text(
                state.question!.text,
                style: fz.h(
                  state.question!.text.characters.length <= 3 ? 44 : 17,
                  weight: FontWeight.w700,
                  color: FzColors.dim,
                  height: 1.35,
                ),
              ),
            ),
          const SizedBox(height: 14),
          const FzEyebrow('The answer'),
          const SizedBox(height: 6),
          FzPanel(
            color: FzColors.ac.withValues(alpha: .08),
            borderColor: FzColors.ac,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: FzDirection(
              text: reveal?.answer ?? '',
              child: Text(
                reveal?.answer ?? '…',
                key: const Key('correctAnswer'),
                style: fz.h(28, color: FzColors.ac),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FzEyebrow(
            host && !judged
                ? 'Switch on the right guesses'
                : judged
                ? 'Marked'
                : 'The host is marking the guesses',
          ),
          const SizedBox(height: 6),
          for (final answer in reveal?.answers ?? const <RevealAnswer>[])
            if (state.player(answer.peerId) case final player?)
              PlayerRow(
                key: ValueKey('guess-${answer.peerId}'),
                player: player,
                you: player.peerId == state.you.peerId,
                guess: answer.text ?? '',
                note: [
                  'wager ${answer.wager}',
                  if (_remarked(answer)) 'marked by host',
                ].join(' · '),
                highlight: _remarked(answer)
                    ? (_correct(answer) ? FzColors.ok : FzColors.ac2)
                          .withValues(alpha: .08)
                    : null,
                merge: true,
                onTap: host && !judged && canAct
                    ? () => judge(answer, !mark(answer))
                    : null,
                // While the host marks, each guess is a switch: on is right.
                // Once marked, or for everybody else, the verdict.
                trailing: host && !judged
                    ? Semantics(
                        label: mark(answer) ? 'Marked right' : 'Marked wrong',
                        // The row is the one stop for the keyboard; the switch
                        // is there to see and to tap.
                        child: ExcludeFocus(
                          child: Switch(
                            key: ValueKey('mark-${answer.peerId}'),
                            value: mark(answer),
                            activeTrackColor: FzColors.ok,
                            trackOutlineColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.selected)
                                  ? FzColors.ok
                                  : FzColors.edge,
                            ),
                            onChanged: canAct
                                ? (right) => judge(answer, right)
                                : null,
                          ),
                        ),
                      )
                    : Icon(
                        _correct(answer) ? Icons.check_circle : Icons.cancel,
                        semanticLabel: _correct(answer) ? 'Right' : 'Wrong',
                        color: _correct(answer) ? FzColors.ok : FzColors.ac2,
                      ),
              ),
          const SizedBox(height: 22),
          const FzEyebrow('Standings'),
          const SizedBox(height: 6),
          Standings(state: state, gains: gains),
        ],
      ),
    );
  }
}
