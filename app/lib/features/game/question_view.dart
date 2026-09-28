import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/connection_providers.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/countdown.dart';
import '../../shared/widgets/fz.dart';
import '../../shared/widgets/fz_direction.dart';
import 'game_screen.dart';
import 'players.dart';

/// An open question, regular or final. The player types an answer and picks a
/// wager from those left this game (the final's wager was chosen before).
///
/// Once the answer is locked in, everybody's guess shows as it comes in, as on
/// the official app's waiting screen (protocol/PROTOCOL.md §6.2).
///
/// What is typed goes to the relay as a draft as it changes: if time runs out
/// before the answer is sent, the relay sends the draft, as the official app
/// would (protocol/PROTOCOL.md §6.3). So does a phone that dropped out.
class QuestionView extends ConsumerStatefulWidget {
  const QuestionView({super.key, required this.state});

  final SeatState state;

  @override
  ConsumerState<QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends ConsumerState<QuestionView> {
  final _answer = TextEditingController();
  int? _wager;
  Timer? _draft;
  int? _index;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(QuestionView old) {
    super.didUpdateWidget(old);
    if (widget.state.question?.index != _index) _reset();
  }

  @override
  void dispose() {
    _draft?.cancel();
    _answer.dispose();
    super.dispose();
  }

  void _reset() {
    _index = widget.state.question?.index;
    _answer.clear();
    final choices = widget.state.you.wagerChoices;
    // The official app's default: the highest wager left.
    _wager = choices.isEmpty ? null : choices.last;
  }

  bool get _final => widget.state.phase == Phase.finalQuestion;

  void _changed() {
    setState(() {});
    _draft?.cancel();
    _draft = Timer(const Duration(milliseconds: 400), () {
      unawaited(
        ref
            .read(seatConnectionProvider)
            .draft(_answer.text, _final ? null : _wager)
            .catchError((Object _) {}),
      );
    });
  }

  Future<void> _submit() async {
    final text = _answer.text.trim();
    final wager = _final ? (widget.state.finalRound?.wager ?? 0) : _wager;
    if (text.isEmpty || wager == null) return;
    _draft?.cancel();
    await act(context, ref, (c) => c.answer(text, wager));
  }

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final state = widget.state;
    final question = state.question;
    if (question == null) {
      return const Center(child: FzWaiting('Next question'));
    }

    final mine = state.you.answer;
    final answered = state.players.where((p) => p.answered).length;
    final canSubmit =
        mine == null &&
        _answer.text.trim().isNotEmpty &&
        (_final || _wager != null);

    return FzBody(
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mine == null)
            FzButton(
              key: const Key('submitAnswerButton'),
              label: 'Lock it in',
              trailing: _final
                  ? 'wager ${state.finalRound?.wager ?? 0}'
                  : _wager == null
                  ? null
                  : 'wager $_wager',
              onPressed: canSubmit ? _submit : null,
            ),
          if (state.you.host) ...[
            if (mine == null) const SizedBox(height: 11),
            FzButton(
              key: const Key('revealButton'),
              label: 'Reveal the answer',
              trailing: '$answered/${state.players.length} answered',
              kind: FzButtonKind.pink,
              // As in the official app: once everyone has answered, or
              // a few seconds after time runs out (the relay decides).
              onPressed: state.you.canReveal
                  ? () => act(context, ref, (c) => c.reveal())
                  : null,
            ),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FzEyebrow(
                  _final
                      ? 'Final · ${state.finalRound?.picked ?? ''}'
                      : question.category ?? '',
                  color: _final ? FzColors.ac2 : FzColors.dim,
                ),
              ),
              if (question.difficulty != null)
                FzTag('${question.difficulty}% get it'),
            ],
          ),
          const SizedBox(height: 12),
          Countdown(
            deadline: state.deadline,
            pausedRemainingMs: null,
            timeLimitMs: state.options.questionSeconds * 1000,
          ),
          const SizedBox(height: 20),
          FzDirection(
            text: question.text,
            child: Text(
              question.text,
              key: const Key('questionText'),
              style: fz.h(
                _isShort(question.text) ? 64 : 26,
                height: 1.28,
                tracking: -.01,
              ),
            ),
          ),
          if (question.imageUrl != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ColoredBox(
                color: FzColors.photoMat,
                child: Image.network(
                  question.imageUrl!,
                  height: 220,
                  fit: BoxFit.contain,
                  // Sporcle's image hosts send no CORS headers: on the web
                  // the picture is a plain <img>, which needs none.
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          if (mine != null)
            FzPanel(
              key: const Key('lockedIn'),
              color: Colors.transparent,
              borderColor: FzColors.ok,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: FzColors.ok, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FzDirection(
                      text: mine.text,
                      child: Text(
                        mine.text.isEmpty ? '(no answer)' : mine.text,
                        style: fz.h(18),
                      ),
                    ),
                  ),
                  FzTag('wager ${mine.wager}', color: FzColors.ok),
                ],
              ),
            )
          else ...[
            FzTypingDirection(
              controller: _answer,
              child: TextField(
                key: const Key('answerField'),
                controller: _answer,
                autofocus: true,
                textInputAction: TextInputAction.done,
                style: fz.h(18, weight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'Your answer',
                  enabledBorder: fzFieldBorder(FzColors.ac),
                ),
                onChanged: (_) => _changed(),
                onSubmitted: (_) => canSubmit ? _submit() : null,
              ),
            ),
            if (!_final) ...[
              const SizedBox(height: 18),
              const FzEyebrow('Wager · each once a game'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final w in state.you.wagerChoices)
                    ChoiceChip(
                      key: Key('wager-$w'),
                      // At least the design's 48px, however short the number.
                      label: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 22),
                        child: Text(
                          '$w',
                          textAlign: TextAlign.center,
                          style: fz.m(16),
                        ),
                      ),
                      selected: w == _wager,
                      onSelected: (_) {
                        _wager = w;
                        _changed();
                      },
                    ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 22),
          FzEyebrow('$answered of ${state.players.length} answered'),
          if (mine != null) ...[
            const SizedBox(height: 6),
            for (final player in state.players)
              PlayerRow(
                key: ValueKey('guess-${player.peerId}'),
                player: player,
                you: player.peerId == state.you.peerId,
                note: switch (player.guess) {
                  final guess? => '"${guess.isEmpty ? '—' : guess}"',
                  null => player.answered ? 'answered' : 'thinking',
                },
                trailing: player.answered
                    ? const Icon(
                        Icons.check_circle,
                        color: FzColors.ok,
                        size: 20,
                      )
                    : const Icon(
                        Icons.hourglass_empty,
                        color: FzColors.faint,
                        size: 20,
                      ),
              ),
          ],
        ],
      ),
    );
  }

  /// A flag, an emoji, a word: drawn large, as the official app does.
  static bool _isShort(String text) => text.characters.length <= 3;
}
