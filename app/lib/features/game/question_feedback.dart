import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/connection_providers.dart';
import '../../shared/theme/fz_theme.dart';
import 'game_screen.dart';

/// A thumb up or down on the question on screen, and a way to report it, as
/// the official app offers them once the player has answered and while the
/// answer is shown (protocol/PROTOCOL.md §4.2). Nothing when [You.canRate] is
/// false.
class QuestionFeedback extends ConsumerWidget {
  const QuestionFeedback({super.key, required this.state});

  final SeatState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final you = state.you;
    if (!you.canRate) return const SizedBox.shrink();
    final fz = FzTheme.of(context);
    final canAct = ref.watch(seatInteractiveProvider);
    final pending = ref.watch(pendingIntentsProvider);
    // A thumb just tapped shows at once, ahead of the relay.
    final rating = pending['rate'] as int? ?? you.rating;

    Widget thumb(int value, IconData icon, String label, Color color) {
      final chosen = rating == value;
      return Semantics(
        selected: chosen,
        child: IconButton(
          key: Key('rate-$value'),
          tooltip: label,
          isSelected: chosen,
          onPressed: canAct
              ? () => act(
                  context,
                  ref,
                  // Tapping the chosen thumb again takes it back.
                  (c) => c.rate(chosen ? 0 : value),
                  pending: 'rate',
                  value: chosen ? 0 : value,
                )
              : null,
          icon: Icon(icon, color: chosen ? color : FzColors.dim),
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: chosen ? color.withValues(alpha: .14) : null,
          ),
        ),
      );
    }

    return Wrap(
      key: const Key('questionFeedback'),
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        thumb(1, Icons.thumb_up_outlined, 'Good question', FzColors.ok),
        thumb(-1, Icons.thumb_down_outlined, 'Bad question', FzColors.ac2),
        TextButton.icon(
          key: const Key('reportQuestionButton'),
          onPressed: you.reported || !canAct
              ? null
              : () => _report(context, ref),
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: FzColors.dim,
            textStyle: fz.m(13),
          ),
          icon: Icon(you.reported ? Icons.flag : Icons.outlined_flag, size: 18),
          label: Text(you.reported ? 'Reported' : 'Report'),
        ),
      ],
    );
  }

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _ReportDialog(),
    );
    if (reason == null || !context.mounted) return;
    await act(context, ref, (c) => c.report(reason), pending: 'report');
  }
}

/// The official app's reasons, one to pick, then "Report".
class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String? _reason;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report the question'),
      scrollable: true,
      content: RadioGroup<String>(
        groupValue: _reason,
        onChanged: (reason) => setState(() => _reason = reason),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('What’s wrong with it?'),
            const SizedBox(height: 8),
            for (final MapEntry(key: reason, value: label)
                in GameRules.reportReasons.entries)
              RadioListTile<String>(
                key: Key('reportReason-$reason'),
                value: reason,
                contentPadding: EdgeInsets.zero,
                title: Text(label),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const Key('confirmReportButton'),
          style: TextButton.styleFrom(foregroundColor: FzColors.ac2),
          onPressed: _reason == null
              ? null
              : () => Navigator.of(context).pop(_reason),
          child: const Text('Report'),
        ),
      ],
    );
  }
}
