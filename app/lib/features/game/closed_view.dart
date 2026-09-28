import 'package:flutter/material.dart';

import '../../core/connection/seat_connection.dart';
import '../../shared/navigation.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz.dart';

/// Why this seat ended (protocol/PROTOCOL.md §5.2).
class ClosedView extends StatelessWidget {
  const ClosedView({super.key, required this.reason});

  final SeatClosedReason reason;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final (title, text) = switch (reason) {
      SeatClosedReason.left => ('You left', 'Your seat has been given up.'),
      SeatClosedReason.expired => (
        'Your seat was let go',
        'You were away longer than the relay holds a seat.',
      ),
      SeatClosedReason.removed => (
        'You were removed',
        'The host removed you from this game.',
      ),
      SeatClosedReason.shutdown => (
        'The relay restarted',
        'Its seats were closed. Join the game again with its code.',
      ),
      SeatClosedReason.notFound => (
        'That game is over for you',
        'The seat had already been let go.',
      ),
    };
    return FzBody(
      footer: FzButton(
        key: const Key('homeButton'),
        label: 'Home',
        onPressed: () => goHome(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(title, key: const Key('closedTitle'), style: fz.t(32)),
          const SizedBox(height: 12),
          Text(text, style: fz.m(15, color: FzColors.dim, height: 1.5)),
        ],
      ),
    );
  }
}
