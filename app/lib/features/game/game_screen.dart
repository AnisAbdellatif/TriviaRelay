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
/// Closing this screen doesn't leave the game: the relay keeps the seat, and
/// home offers the way back. Only the leave button leaves.
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave the game?'),
        content: const Text(
          'You give up your seat. To step away and come back, just close this '
          'screen: your seat is held for you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            key: const Key('confirmLeaveButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave != true) return;
    await ref.read(seatConnectionProvider).leave();
    await ref.read(currentSeatProvider.notifier).set(null);
    if (context.mounted) goHome(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final closed = ref.watch(seatClosedProvider);
    final state = ref.watch(seatStateProvider).value;

    ref.listen(seatClosedProvider, (_, reason) {
      if (reason != null) {
        unawaited(ref.read(currentSeatProvider.notifier).set(null));
      }
    });

    final Widget body;
    if (closed != null) {
      body = ClosedView(reason: closed);
    } else if (state == null) {
      body = const Center(child: FzWaiting('Taking your seat'));
    } else {
      body = _PhaseView(state: state);
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        // Stop listening; the relay holds the seat for the way back.
        if (didPop && closed == null) ref.invalidate(seatConnectionProvider);
      },
      child: Scaffold(
        body: FzBackground(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameTopBar(
                  label: _label(state),
                  onLeave: closed != null
                      ? () => goHome(context)
                      : () => _leave(context, ref),
                  trailing: state == null
                      ? null
                      : FzTag('game ${state.gameCode}', color: FzColors.ac),
                ),
                const ConnectionBanner(),
                if (state != null && closed == null) _StatusLine(state),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _label(SeatState? state) {
    if (state == null) return 'Trivia Relay';
    final q = state.question;
    return switch (state.phase) {
      Phase.lobby => state.pack?.name ?? 'Lobby',
      Phase.question || Phase.reveal when q != null =>
        'Question ${q.index + 1} of ${state.options.questionsPerGame}',
      Phase.finalVote ||
      Phase.finalWager ||
      Phase.finalQuestion ||
      Phase.finalReveal => 'Final round',
      Phase.finalScores => 'Final scores',
      _ => state.pack?.name ?? '',
    };
  }
}

/// What the relay says about its own connection to the game, when that isn't
/// simply "in it".
class _StatusLine extends StatelessWidget {
  const _StatusLine(this.state);

  final SeatState state;

  @override
  Widget build(BuildContext context) {
    final text = switch (state.status) {
      SeatStatus.connecting => 'Joining the game…',
      SeatStatus.lost => 'The relay lost its connection to this game.',
      _ => null,
    };
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
      child: FzEyebrow(
        text,
        color: state.status == SeatStatus.lost ? FzColors.ac2 : FzColors.dim,
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
Future<void> act(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function(SeatConnection connection) intent,
) async {
  try {
    await intent(ref.read(seatConnectionProvider));
  } on Object catch (error) {
    if (context.mounted) showError(context, ref, error);
  }
}
