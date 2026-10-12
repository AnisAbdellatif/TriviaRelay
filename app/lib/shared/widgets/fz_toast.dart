import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/fz_theme.dart';
import 'fz_motion.dart';

OverlayEntry? _current;

/// A short message at the top of the screen for a few seconds: a refusal
/// from the relay, "Copied".
///
/// At the top rather than a snackbar at the bottom, because the bottom of
/// every screen here is its main button, and a snackbar sat on "Lock it in"
/// for four seconds. It lets taps through to whatever it covers, so it never
/// stands in the way of the top bar, and it is announced to screen readers.
/// A new one replaces the last.
void showFzToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _dismiss(_current);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Toast(
      key: const Key('toast'),
      message: message,
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

class _Toast extends StatefulWidget {
  const _Toast({
    super.key,
    required this.message,
    required this.duration,
    required this.onDone,
  });

  final String message;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> {
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
    final quick = reduceMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AnimatedOpacity(
                opacity: _shown ? 1 : 0,
                duration: quick,
                child: Semantics(
                  liveRegion: true,
                  child: Material(
                    color: FzColors.bgGlow,
                    elevation: 6,
                    shadowColor: Colors.black,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Text(widget.message, style: fz.m(13, height: 1.4)),
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
