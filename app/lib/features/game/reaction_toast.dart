import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/game/social.dart';
import '../../core/models/models.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz_motion.dart';

OverlayEntry? _current;

/// Says who sent this player [reaction], for a few seconds under the top bar
/// ("Hosta honked at you"), as the sound plays. Apart from the app's other
/// toasts, so a reaction never hides a refusal; a new one replaces the last. It
/// lets taps through, and is announced.
void showReactionToast(
  BuildContext context,
  Reaction reaction,
  String? name, {
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _dismiss(_current);
  final who = isolate((name ?? '').trim().isEmpty ? 'Someone' : name!.trim());
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ReactionToast(
      key: const Key('reactionToast'),
      message: '$who ${reactionWords(reaction.type)}',
      duration: duration,
      onDone: () => _dismiss(entry),
    ),
  );
  _current = entry;
  overlay.insert(entry);
}

void _dismiss(OverlayEntry? entry) {
  if (entry == null) return;
  if (identical(_current, entry)) _current = null;
  if (entry.mounted) {
    entry
      ..remove()
      ..dispose();
  }
}

class _ReactionToast extends StatefulWidget {
  const _ReactionToast({
    super.key,
    required this.message,
    required this.duration,
    required this.onDone,
  });

  final String message;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_ReactionToast> createState() => _ReactionToastState();
}

class _ReactionToastState extends State<_ReactionToast> {
  Timer? _timer;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, widget.onDone);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final still = reduceMotion(context);
    final quick = still ? Duration.zero : const Duration(milliseconds: 180);
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            // Under the game's top bar.
            padding: const EdgeInsets.fromLTRB(16, 64, 16, 0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AnimatedSlide(
                offset: _shown || still ? Offset.zero : const Offset(0, -.3),
                duration: quick,
                child: AnimatedOpacity(
                  opacity: _shown ? 1 : 0,
                  duration: quick,
                  child: Semantics(
                    liveRegion: true,
                    child: Material(
                      color: FzColors.bgGlow,
                      elevation: 6,
                      shadowColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                        side: const BorderSide(color: FzColors.ac, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.campaign_outlined,
                              color: FzColors.ac,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                widget.message,
                                style: fz.m(13, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
