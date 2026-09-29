import 'package:flutter/material.dart';

import '../theme/fz_theme.dart';
import 'fz.dart';

/// Top row of the game screen: a way back home that keeps the seat, where the
/// game is, its code when there is room, and a way to leave it.
///
/// The label is one line. When it doesn't fit, [shortLabel] stands in, and
/// the code is the first thing to go: it is in the lobby, and on home's "Back
/// to game" button.
class GameTopBar extends StatelessWidget {
  const GameTopBar({
    super.key,
    required this.label,
    required this.onBack,
    this.shortLabel,
    this.gameCode,
    this.onLeave,
    this.color = FzColors.dim,
  });

  final String label;

  /// Stands in for [label] when that doesn't fit ("Q1 of 5").
  final String? shortLabel;

  /// The label's colour: Flare through the final round.
  final Color color;

  /// Home, keeping the seat.
  final VoidCallback onBack;

  /// Leaving the game; no leave button when null.
  final VoidCallback? onLeave;
  final String? gameCode;

  static const leaveKey = Key('leaveButton');

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final leaveStyle = fz.h(15, weight: FontWeight.w700);
    final codeStyle = fz.m(10, tracking: .1);

    double width(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = painter.width;
      painter.dispose();
      return w;
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 14, 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // What is left for the label and the code, beside the buttons.
              var room = constraints.maxWidth - 48 - 12;
              if (onLeave != null) room -= width('Leave', leaveStyle) + 24 + 4;
              final eyebrow = FzEyebrow.style(context);
              final full = width(label.toUpperCase(), eyebrow);
              final code = gameCode == null ? null : 'game $gameCode';
              final showCode =
                  code != null &&
                  room >= full + 12 + width(code.toUpperCase(), codeStyle);
              final text = full > room && shortLabel != null
                  ? shortLabel!
                  : label;
              return Row(
                children: [
                  FzCircleButton(
                    key: const Key('backButton'),
                    icon: Icons.arrow_back,
                    tooltip: 'Home. Your seat is held',
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: FzEyebrow(text, color: color, maxLines: 1),
                    ),
                  ),
                  if (showCode) ...[
                    const SizedBox(width: 12),
                    FzTag(code, color: FzColors.ac),
                  ],
                  if (onLeave != null) ...[
                    const SizedBox(width: 4),
                    TextButton(
                      key: leaveKey,
                      onPressed: onLeave,
                      style: TextButton.styleFrom(
                        foregroundColor: FzColors.ac2,
                        textStyle: leaveStyle,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Leave'),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
