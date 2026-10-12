import 'package:flutter/material.dart';

import '../../core/connection/seat_connection.dart';
import '../../shared/navigation.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/fz.dart';

/// Why this seat ended (protocol/PROTOCOL.md §5.2), and the way back in when
/// there is one.
class ClosedView extends StatelessWidget {
  const ClosedView({
    super.key,
    required this.reason,
    this.gameCode,
    this.onJoinAgain,
    this.joining = false,
  });

  final SeatClosedReason reason;

  /// The game this seat was in, if the app knew it.
  final String? gameCode;

  /// Takes a new seat in [gameCode]; offered only where Sporcle would have
  /// the player back.
  final VoidCallback? onJoinAgain;
  final bool joining;

  /// Whether a seat that ended this way can be taken again with the code:
  /// not a kick (Sporcle refuses), and not one the player gave up or moved.
  static bool canJoinAgain(SeatClosedReason reason) => switch (reason) {
    SeatClosedReason.removed ||
    SeatClosedReason.shutdown ||
    SeatClosedReason.expired ||
    SeatClosedReason.notFound => true,
    SeatClosedReason.left ||
    SeatClosedReason.kicked ||
    SeatClosedReason.moved => false,
  };

  @override
  Widget build(BuildContext context) {
    final code = gameCode;
    final (title, text) = switch (reason) {
      SeatClosedReason.left => ('You left', 'Your seat has been given up.'),
      SeatClosedReason.expired => (
        'Your seat was let go',
        'You were away longer than the relay holds a seat.',
      ),
      SeatClosedReason.removed => (
        'You were removed',
        'The host removed you from this game. You can join it again'
            '${code == null ? '' : ' with the code $code'}.',
      ),
      SeatClosedReason.kicked => (
        'You were kicked',
        "The host removed you from this game, and it won't let you "
            'back in.',
      ),
      SeatClosedReason.moved => (
        'Your seat moved to another device',
        'You took a seat somewhere else with this account, so this one was '
            'let go.',
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
    final again = onJoinAgain != null && code != null && canJoinAgain(reason);
    return _EndedView(
      title: title,
      text: text,
      actions: [
        if (again) ...[
          FzButton(
            key: const Key('joinAgainButton'),
            label: joining ? 'Joining…' : 'Join again',
            trailing: joining ? null : 'game $code',
            busy: joining,
            onPressed: onJoinAgain,
          ),
          const SizedBox(height: 11),
        ],
        FzButton(
          key: const Key('homeButton'),
          label: 'Home',
          kind: again ? FzButtonKind.outline : FzButtonKind.primary,
          onPressed: () => goHome(context),
        ),
      ],
    );
  }
}

/// This app was let go of a seat that goes on: it was open on more apps than
/// the relay takes, and this one had joined first (protocol/PROTOCOL.md
/// §3.3). The seat is still held, so home still offers the way back.
class DisplacedView extends StatelessWidget {
  const DisplacedView({super.key, required this.onTakeBack});

  final VoidCallback onTakeBack;

  @override
  Widget build(BuildContext context) {
    return _EndedView(
      title: 'Open on other devices',
      text:
          'Your seat was opened on more phones than it takes, so this one '
          'let go. The seat is still held for you.',
      actions: [
        FzButton(
          key: const Key('takeBackButton'),
          label: 'Use it here',
          onPressed: onTakeBack,
        ),
        const SizedBox(height: 11),
        FzButton(
          key: const Key('homeButton'),
          label: 'Home',
          kind: FzButtonKind.outline,
          onPressed: () => goHome(context),
        ),
      ],
    );
  }
}

class _EndedView extends StatelessWidget {
  const _EndedView({
    required this.title,
    required this.text,
    required this.actions,
  });

  final String title;
  final String text;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    return FzBody(
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: actions,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          // The mark with its legs apart: nobody is holding this seat now.
          Transform.translate(
            offset: const Offset(-24, 0),
            child: const FzMark(size: 150, faded: true),
          ),
          const SizedBox(height: 18),
          Semantics(
            header: true,
            child: Text(title, key: const Key('closedTitle'), style: fz.t(36)),
          ),
          const SizedBox(height: 14),
          Text(text, style: fz.m(15, color: FzColors.dim, height: 1.55)),
        ],
      ),
    );
  }
}
