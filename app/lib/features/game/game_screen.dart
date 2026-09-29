import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connection/seat_connection.dart';
import '../../core/models/models.dart';
import '../../core/providers/connection_providers.dart';
import '../../shared/navigation.dart';
import '../../shared/seat_flow.dart';
import '../../shared/theme/fz_theme.dart';
import '../../shared/widgets/connection_banner.dart';
import '../../shared/widgets/fz.dart';
import '../../shared/widgets/game_top_bar.dart';
import 'closed_view.dart';
import 'final_views.dart';
import 'lobby_view.dart';
import 'question_view.dart';
import 'reveal_view.dart';

/// The game, one phase at a time (protocol/PROTOCOL.md §6.1).
///
/// Going back from this screen doesn't leave the game: the relay keeps the
/// seat, and home offers the way back. Only the leave button leaves.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  /// Saying goodbye to the relay, which may take a few seconds.
  bool _leaving = false;

  /// Taking a new seat in the same game.
  bool _rejoining = false;

  /// The game this screen was last showing, for joining it again once the
  /// seat has ended.
  String? _gameCode;

  Future<void> _back() async {
    final navigator = Navigator.of(context);
    if (!await navigator.maybePop()) {
      if (mounted) goHome(context);
    }
  }

  Future<void> _leave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave the game?'),
        content: const Text(
          'You give up your seat. To step away and come back, go back '
          'instead: your seat is held for you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            key: const Key('confirmLeaveButton'),
            style: TextButton.styleFrom(foregroundColor: FzColors.ac2),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    setState(() => _leaving = true);
    // Best effort, and a few seconds at most: without an answer the hold
    // ends the seat anyway.
    await ref.read(seatConnectionProvider).leave();
    await ref.read(currentSeatProvider.notifier).set(null);
    if (mounted) goHome(context);
  }

  /// A new seat in [code], in place of the one lost or ended.
  Future<void> _rejoin(String code) async {
    if (_rejoining) return;
    setState(() => _rejoining = true);
    try {
      await rejoinSeat(ref, code);
    } on Object catch (error) {
      if (mounted) showError(context, ref, error);
    } finally {
      if (mounted) setState(() => _rejoining = false);
    }
  }

  /// Back to this seat after another app took its place, or the relay
  /// turned a rejoin down.
  Future<void> _takeBack() async {
    final seat = ref.read(currentSeatProvider).value;
    if (seat == null) return goHome(context);
    ref.invalidate(seatConnectionProvider);
    try {
      await ref.read(seatConnectionProvider).attach(seat);
    } on Object catch (error) {
      if (mounted) showError(context, ref, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final closed = ref.watch(seatClosedProvider);
    final state = ref.watch(seatStateProvider).value;
    final displaced =
        ref.watch(connectionStatusProvider).value == ConnectionStatus.displaced;
    _gameCode = state?.gameCode ?? _gameCode;
    final code = _gameCode;

    ref.listen(seatClosedProvider, (_, reason) {
      if (reason != null) {
        unawaited(ref.read(currentSeatProvider.notifier).set(null));
      }
    });

    final ended = closed != null || displaced;
    final Widget body;
    if (_leaving) {
      body = const Center(child: FzWaiting('Leaving the game…'));
    } else if (closed != null) {
      body = ClosedView(
        reason: closed,
        gameCode: code,
        onJoinAgain: code == null ? null : () => _rejoin(code),
        joining: _rejoining,
      );
    } else if (displaced) {
      body = DisplacedView(onTakeBack: _takeBack);
    } else if (state == null) {
      body = Center(
        child: FzWaiting(_rejoining ? 'Joining again' : 'Taking your seat'),
      );
    } else {
      body = _PhaseView(state: state);
    }

    return PopScope(
      canPop: !_leaving,
      onPopInvokedWithResult: (didPop, _) {
        // Stop listening; the relay holds the seat for the way back.
        if (didPop && closed == null) ref.invalidate(seatConnectionProvider);
      },
      child: Scaffold(
        body: FzBackground(
          arcs: ended ? null : _arcs(state),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // An ended seat's screen has its own way home and nothing to
                // leave.
                if (!ended && !_leaving)
                  GameTopBar(
                    label: _label(state),
                    shortLabel: _shortLabel(state),
                    color: _finalRound(state) ? FzColors.ac2 : FzColors.dim,
                    onBack: _back,
                    onLeave: _leave,
                    gameCode: state?.gameCode,
                  ),
                if (!ended && !_leaving) ...[
                  ConnectionBanner(onReconnect: _takeBack),
                  if (state != null)
                    _StatusBanner(
                      state: state,
                      rejoining: _rejoining,
                      onRejoin: () => _rejoin(state.gameCode),
                    ),
                ],
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool _finalRound(SeatState? state) => switch (state?.phase) {
    Phase.finalVote ||
    Phase.finalWager ||
    Phase.finalQuestion ||
    Phase.finalReveal => true,
    _ => false,
  };

  /// Signal rings in the corner; Flare through the final round; none behind
  /// the final scores, which ring the winner instead.
  static Color? _arcs(SeatState? state) {
    if (state?.phase == Phase.finalScores) return null;
    return _finalRound(state) ? FzColors.flareArcs : FzColors.arcs;
  }

  static String _label(SeatState? state) {
    if (state == null) return 'Trivia Relay';
    final q = state.question;
    return switch (state.phase) {
      // The pack is in the lobby's own panel; a long name here took five
      // lines.
      Phase.lobby => 'Lobby',
      Phase.question || Phase.reveal when q != null =>
        'Question ${q.index + 1} of ${state.options.questionsPerGame}',
      Phase.finalVote ||
      Phase.finalWager ||
      Phase.finalQuestion ||
      Phase.finalReveal => 'Final round',
      Phase.finalScores => 'Final scores',
      _ => 'Trivia Relay',
    };
  }

  static String? _shortLabel(SeatState? state) {
    if (state == null) return null;
    final q = state.question;
    return switch (state.phase) {
      Phase.question || Phase.reveal when q != null =>
        'Q${q.index + 1} of ${state.options.questionsPerGame}',
      Phase.finalVote ||
      Phase.finalWager ||
      Phase.finalQuestion ||
      Phase.finalReveal => 'Final',
      Phase.finalScores => 'Scores',
      _ => null,
    };
  }
}

/// What the relay says about its own connection to the game, when that isn't
/// simply "in it": joining, or lost, with the way back in.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.state,
    required this.rejoining,
    required this.onRejoin,
  });

  final SeatState state;
  final bool rejoining;
  final VoidCallback onRejoin;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final Widget child;
    switch (state.status) {
      case SeatStatus.connecting:
        child = const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: FzWaiting('Joining the game…'),
        );
      case SeatStatus.lost:
        child = Container(
          key: const Key('lostBanner'),
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: BoxDecoration(
            color: FzColors.ac2.withValues(alpha: .12),
            border: Border.all(color: FzColors.ac2, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Semantics(
            liveRegion: true,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 8,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lost the game', style: fz.h(15, color: FzColors.ac2)),
                    const SizedBox(height: 2),
                    Text(
                      "The relay can't get back in by itself.",
                      style: fz.m(12, color: FzColors.ink, height: 1.35),
                    ),
                  ],
                ),
                FzButton(
                  key: const Key('rejoinButton'),
                  label: rejoining ? 'Rejoining…' : 'Rejoin',
                  kind: FzButtonKind.pink,
                  expand: false,
                  height: 44,
                  fontSize: 15,
                  radius: 12,
                  busy: rejoining,
                  onPressed: onRejoin,
                ),
              ],
            ),
          ),
        );
      case SeatStatus.live || SeatStatus.removed:
        return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 2),
          child: child,
        ),
      ),
    );
  }
}

class _PhaseView extends StatelessWidget {
  const _PhaseView({required this.state});

  final SeatState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.phase) {
      Phase.lobby => LobbyView(state: state),
      Phase.question || Phase.finalQuestion => QuestionView(state: state),
      Phase.reveal || Phase.finalReveal => RevealView(state: state),
      Phase.finalVote => FinalVoteView(state: state),
      Phase.finalWager => FinalWagerView(state: state),
      Phase.finalScores => FinalScoresView(state: state),
    };
  }
}

/// Runs an intent, showing the relay's refusal if there is one.
///
/// With [pending], the intent shows as waiting under that key until a snapshot
/// shows it done ([PendingIntents]); [value] is what it sent, for a screen to
/// show ahead of the relay.
Future<void> act(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function(SeatConnection connection) intent, {
  String? pending,
  Object? value,
}) async {
  final connection = ref.read(seatConnectionProvider);
  try {
    if (pending == null) {
      await intent(connection);
    } else {
      await ref
          .read(pendingIntentsProvider.notifier)
          .run(pending, () => intent(connection), value: value);
    }
  } on Object catch (error) {
    if (context.mounted) showError(context, ref, error);
  }
}
