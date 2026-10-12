import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/config_providers.dart';
import '../../core/providers/connection_providers.dart';
import '../../core/time/server_clock.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz.dart';
import '../../shared/widgets/fz_motion.dart';

/// The count down before the game's first question ("We're starting in") and
/// the final one ("Final question in"), on every phone at once: the relay
/// times it, so everybody's reaches zero together (protocol/PROTOCOL.md §5.1).
/// Until then it stands in for [child], the question, whose clock starts when
/// it ends.
class CountdownGate extends ConsumerStatefulWidget {
  const CountdownGate({
    super.key,
    required this.countdown,
    required this.child,
  });

  final StartCountdown? countdown;
  final Widget child;

  @override
  ConsumerState<CountdownGate> createState() => _CountdownGateState();
}

class _CountdownGateState extends ConsumerState<CountdownGate> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(CountdownGate old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  int _left() {
    final countdown = widget.countdown;
    if (countdown == null) return 0;
    return remainingMs(
      deadline: countdown.until,
      offsetMs: ref.read(serverClockOffsetProvider),
      localNowMs: ref.read(clockProvider)().millisecondsSinceEpoch,
    );
  }

  void _sync() {
    if (_left() <= 0) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    _ticker ??= Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      setState(() {});
      if (_left() <= 0) {
        _ticker?.cancel();
        _ticker = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(serverClockOffsetProvider);
    final left = _left();
    final countdown = widget.countdown;
    if (countdown == null || left <= 0) return widget.child;

    final fz = FzTheme.of(context);
    final seconds = (left / 1000).ceil();
    final isFinal = countdown.kind == StartCountdown.finalQuestion;
    final color = isFinal ? FzColors.ac2 : FzColors.ac;
    final label = isFinal ? 'Final question in' : 'We’re starting in';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Semantics(
          key: const Key('startCountdown'),
          liveRegion: true,
          label: '$label $seconds',
          excludeSemantics: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FzEyebrow(label, color: color, size: 13),
              const SizedBox(height: 12),
              FzPop(
                trigger: seconds,
                scale: 1.3,
                child: Text(
                  '$seconds',
                  key: const Key('startCountdownSeconds'),
                  style: fz.t(120, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
