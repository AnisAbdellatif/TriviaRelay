import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fz = FzTheme.of(context);
    final reveal = state.reveal;
    final host = state.you.host;
    final judged = state.you.judged;

    final gains = {
      if (judged)
        for (final a in reveal?.answers ?? const <RevealAnswer>[])
          a.peerId: _correct(a) ? a.wager : (_final ? -a.wager : 0),
    };

    return FzBody(
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
                    onPressed: () => act(context, ref, (c) => c.judgeSubmit()),
                  ),
                  const SizedBox(height: 11),
                ],
                FzButton(
                  key: const Key('nextButton'),
                  label: _nextLabel,
                  kind: judged ? FzButtonKind.pink : FzButtonKind.outline,
                  onPressed: () => act(context, ref, (c) => c.next()),
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
                note: [
                  '"${(answer.text ?? '').isEmpty ? '—' : answer.text}"',
                  'wager ${answer.wager}',
                  if (_remarked(answer)) 'marked by host',
                ].join(' · '),
                highlight: _remarked(answer)
                    ? (_correct(answer) ? FzColors.ok : FzColors.ac2)
                          .withValues(alpha: .08)
                    : null,
                onTap: host && !judged
                    ? () => act(
                        context,
                        ref,
                        (c) => c.judge(answer.peerId, !_correct(answer)),
                      )
                    : null,
                // While the host marks, each guess is a switch: on is right.
                // Once marked, or for everybody else, the verdict.
                trailing: host && !judged
                    ? Switch(
                        key: ValueKey('mark-${answer.peerId}'),
                        value: _correct(answer),
                        activeTrackColor: FzColors.ok,
                        trackOutlineColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? FzColors.ok
                              : FzColors.line,
                        ),
                        onChanged: (right) => act(
                          context,
                          ref,
                          (c) => c.judge(answer.peerId, right),
                        ),
                      )
                    : Icon(
                        _correct(answer) ? Icons.check_circle : Icons.cancel,
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
