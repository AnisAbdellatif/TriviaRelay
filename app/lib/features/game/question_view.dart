import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/config_providers.dart';
import '../../core/providers/connection_providers.dart';
import '../../core/time/server_clock.dart';
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
  /// In the last seconds a draft goes at once, not after a pause in typing,
  /// so the one the relay answers with is the latest.
  static const _eager = Duration(seconds: 3);

  final _answer = TextEditingController();
  int? _wager;
  Timer? _draft;
  int? _index;

  /// The clock has run out: the field is closed, and the relay answers with
  /// the last draft (protocol/PROTOCOL.md §6.3).
  bool _timeUp = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(QuestionView old) {
    super.didUpdateWidget(old);
    if (widget.state.question?.index != _index ||
        widget.state.phase != old.state.phase) {
      _reset();
    } else if (widget.state.deadline != old.state.deadline) {
      _timeUp = false;
    }
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
    _timeUp = false;
    final choices = widget.state.you.wagerChoices;
    // The official app's default: the highest wager left.
    _wager = choices.isEmpty ? null : choices.last;
  }

  bool get _final => widget.state.phase == Phase.finalQuestion;

  int? _remainingMs() {
    final deadline = widget.state.deadline;
    if (deadline == null) return null;
    return remainingMs(
      deadline: deadline,
      offsetMs: ref.read(serverClockOffsetProvider),
      localNowMs: ref.read(clockProvider)().millisecondsSinceEpoch,
    );
  }

  void _changed() {
    setState(() {});
    _draft?.cancel();
    final left = _remainingMs();
    final wait = left != null && left <= _eager.inMilliseconds
        ? Duration.zero
        : const Duration(milliseconds: 400);
    _draft = Timer(wait, _sendDraft);
  }

  void _sendDraft() {
    unawaited(
      ref
          .read(seatConnectionProvider)
          .draft(_answer.text, _final ? null : _wager)
          .catchError((Object _) {}),
    );
  }

  void _expired() {
    if (_timeUp) return;
    // Whatever is typed goes now, in case the last change was still waiting.
    if (widget.state.you.answer == null && _draft?.isActive == true) {
      _draft?.cancel();
      _sendDraft();
    }
    setState(() => _timeUp = true);
  }

  Future<void> _submit() async {
    final text = _answer.text.trim();
    final wager = _final ? (widget.state.finalRound?.wager ?? 0) : _wager;
    if (text.isEmpty || wager == null || _timeUp) return;
    _draft?.cancel();
    await act(context, ref, (c) => c.answer(text, wager), pending: 'answer');
  }

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final state = widget.state;
    final question = state.question;
    if (question == null) {
      return const Center(child: FzWaiting('Next question'));
    }

    final canAct = ref.watch(seatInteractiveProvider);
    final locking = ref.watch(pendingIntentsProvider).containsKey('answer');
    final mine = state.you.answer;
    final answered = state.players.where((p) => p.answered).length;
    final canSubmit =
        mine == null &&
        canAct &&
        !_timeUp &&
        !locking &&
        _answer.text.trim().isNotEmpty &&
        (_final || _wager != null);
    final hasImage = question.imageUrl != null;

    return FzBody(
      // Pinned, so the clock stays in sight while the keyboard is up.
      top: Countdown(
        deadline: state.deadline,
        pausedRemainingMs: null,
        timeLimitMs: state.options.questionSeconds * 1000,
        onExpired: _expired,
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mine == null)
            FzButton(
              key: const Key('submitAnswerButton'),
              label: locking
                  ? 'Locking…'
                  : _timeUp
                  ? "Time's up"
                  : 'Lock it in',
              trailing: _timeUp
                  ? null
                  : _final
                  ? 'wager ${state.finalRound?.wager ?? 0}'
                  : _wager == null
                  ? null
                  : 'wager $_wager',
              busy: locking,
              onPressed: canSubmit ? _submit : null,
            ),
          if (state.you.host) ...[
            if (mine == null) const SizedBox(height: 11),
            if (!state.you.canReveal) ...[
              Text(
                'Reveal opens once everyone has answered, or 5 seconds '
                'after time runs out.',
                key: const Key('revealHint'),
                style: fz.m(12, color: FzColors.dim, height: 1.4),
              ),
              const SizedBox(height: 8),
            ],
            FzButton(
              key: const Key('revealButton'),
              label: 'Reveal the answer',
              trailing: '$answered/${state.players.length} answered',
              kind: FzButtonKind.pink,
              busy: ref.watch(pendingIntentsProvider).containsKey('reveal'),
              // As in the official app: once everyone has answered, or
              // a few seconds after time runs out (the relay decides).
              onPressed: state.you.canReveal && canAct
                  ? () =>
                        act(context, ref, (c) => c.reveal(), pending: 'reveal')
                  : null,
            ),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
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
          const SizedBox(height: 16),
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
          if (hasImage) ...[
            const SizedBox(height: 14),
            QuestionImage(url: question.imageUrl!),
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
                  const Icon(
                    Icons.lock_outline,
                    color: FzColors.ok,
                    size: 18,
                    semanticLabel: 'Locked in',
                  ),
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
                // Not over a picture: the keyboard would cover it.
                autofocus: !hasImage,
                readOnly: _timeUp || !canAct || locking,
                textInputAction: TextInputAction.done,
                style: fz.h(18, weight: FontWeight.w700),
                // Room below for the wagers, as the field scrolls into view.
                scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                decoration: InputDecoration(
                  hintText: _timeUp ? "Time's up" : 'Your answer',
                  enabledBorder: _timeUp ? null : fzKeyFieldBorder,
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
                      tooltip: 'Wager $w',
                      selected: w == _wager,
                      onSelected: _timeUp
                          ? null
                          : (_) {
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
                guess: player.guess,
                note: player.guess != null
                    ? null
                    : player.answered
                    ? 'answered'
                    : 'thinking',
                trailing: player.answered
                    ? const Icon(
                        Icons.check_circle,
                        color: FzColors.ok,
                        size: 20,
                        semanticLabel: 'Answered',
                      )
                    : const Icon(
                        Icons.hourglass_empty,
                        color: FzColors.faint,
                        size: 20,
                        semanticLabel: 'Thinking',
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

/// A question's picture on its mat, [height] tall and as wide as there is
/// room.
///
/// The box is the same height from the start, so the page doesn't jump when
/// the picture arrives; until then it shows that one is coming, and if it
/// never does, says so rather than vanishing.
///
/// Sporcle's image hosts send no CORS headers: on the web the picture is a
/// plain <img>, which needs none, and which the browser sizes itself. Android
/// decodes it no larger than the box it is shown in, so a huge upload costs a
/// screenful of memory rather than its own size.
class QuestionImage extends StatelessWidget {
  const QuestionImage({super.key, required this.url, this.height = 220});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    Widget waiting(Widget child) => ColoredBox(
      color: FzColors.bgGlow,
      child: Center(child: child),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final ImageProvider network = NetworkImage(
              url,
              webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            );
            final ratio = MediaQuery.devicePixelRatioOf(context);
            // The column is always bounded; the square is only a guard.
            final width =
                constraints.hasBoundedWidth && constraints.maxWidth > 0
                ? constraints.maxWidth
                : height;
            return Image(
              key: const Key('questionImage'),
              image: kIsWeb
                  ? network
                  : ResizeImage(
                      network,
                      width: (width * ratio).round(),
                      height: (height * ratio).round(),
                      policy: ResizeImagePolicy.fit,
                    ),
              height: height,
              width: width,
              fit: BoxFit.contain,
              semanticLabel: 'The question’s picture',
              frameBuilder: (_, child, frame, synchronous) =>
                  synchronous || frame != null
                  // A light mat gives a picture on a white ground an edge.
                  ? ColoredBox(color: FzColors.photoMat, child: child)
                  : waiting(
                      const SizedBox.square(
                        key: Key('questionImageLoading'),
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
              errorBuilder: (_, _, _) => waiting(
                Column(
                  key: const Key('questionImageFailed'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.broken_image_outlined,
                      color: FzColors.dim,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "The picture didn't load.",
                      style: fz.m(12, color: FzColors.dim),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
