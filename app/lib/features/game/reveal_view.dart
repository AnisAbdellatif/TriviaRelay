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
                  state.question!.text.characters.length <= 3 ? 44 : 18,
                  color: FzColors.dim,
                ),
              ),
            ),
          const SizedBox(height: 12),
          const FzEyebrow('The answer'),
          const SizedBox(height: 6),
          FzPanel(
            borderColor: FzColors.ac,
            child: FzDirection(
              text: reveal?.answer ?? '',
              child: Text(
                reveal?.answer ?? '…',
                key: const Key('correctAnswer'),
                style: fz.h(26, color: FzColors.ac),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FzEyebrow(
            host && !judged
                ? 'Tap a guess to mark it'
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
                note:
                    '"${(answer.text ?? '').isEmpty ? '—' : answer.text}" · '
                    'wager ${answer.wager}',
                onTap: host && !judged
                    ? () => act(
                        context,
                        ref,
                        (c) => c.judge(answer.peerId, !_correct(answer)),
                      )
                    : null,
                trailing: Icon(
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
