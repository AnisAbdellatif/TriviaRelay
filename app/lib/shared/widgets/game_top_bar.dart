import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/fz_theme.dart';
import 'fz.dart';

/// Top row of the game screen: a way back home that keeps the seat, where the
/// game is, its code when there is room, the chat, and a way to leave it.
///
/// The label is one line. When it doesn't fit, [shortLabel] stands in, and
/// the code is the first thing to go: it is in the lobby, and on home's "Back
/// to game" button. When even that leaves too little, Leave goes into the
/// menu.
class GameTopBar extends StatelessWidget {
  const GameTopBar({
    super.key,
    required this.label,
    required this.onBack,
    this.shortLabel,
    this.gameCode,
    this.onLeave,
    this.onMenu,
    this.hostMenu = false,
    this.onChat,
    this.chatUnread = 0,
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

  /// The game menu; it is told whether it has to offer leaving too. The
  /// button shows when the menu has the host's own items ([hostMenu]), or
  /// when, on a narrow screen with large text, the leave button has to make
  /// way and goes into it.
  final ValueChanged<bool>? onMenu;

  /// The menu has the host's items (back to the lobby).
  final bool hostMenu;

  /// Opens the chat; no chat button when null.
  final VoidCallback? onChat;

  /// Messages the chat has had since it was last open: a badge on its button.
  final int chatUnread;
  final String? gameCode;

  static const leaveKey = Key('leaveButton');
  static const menuKey = Key('hostMenuButton');
  static const chatKey = Key('chatButton');

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
              final leave = onLeave == null
                  ? 0.0
                  : width('Leave', leaveStyle) + 24 + 4;
              final chat = onChat;
              if (chat != null) room -= 48 + 4;
              // The menu goes beside Leave when there is room for both and a
              // little of the label; otherwise Leave goes into the menu.
              final menu = onMenu;
              final eyebrow = FzEyebrow.style(context);
              // Enough of the label to read: its short form, when it has one.
              final need = math.min(
                width((shortLabel ?? label).toUpperCase(), eyebrow) + 4,
                120.0,
              );
              final leaveInMenu =
                  menu != null && room - leave - (hostMenu ? 52 : 0) < need;
              final showMenu = menu != null && (hostMenu || leaveInMenu);
              room -= leaveInMenu ? 0 : leave;
              if (showMenu) room -= 48 + 4;
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
                  if (chat != null) ...[
                    const SizedBox(width: 4),
                    _ChatButton(unread: chatUnread, onPressed: chat),
                  ],
                  if (showMenu) ...[
                    const SizedBox(width: 4),
                    FzCircleButton(
                      key: menuKey,
                      icon: Icons.more_vert,
                      tooltip: !hostMenu
                          ? 'Leave the game'
                          : leaveInMenu
                          ? 'Host menu and leave'
                          : 'Host menu',
                      onPressed: () => menu(leaveInMenu),
                    ),
                  ],
                  if (onLeave != null && !leaveInMenu) ...[
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

/// The chat's button, with a badge counting what came while it was closed.
class _ChatButton extends StatelessWidget {
  const _ChatButton({required this.unread, required this.onPressed});

  final int unread;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final label = switch (unread) {
      0 => 'Chat',
      1 => 'Chat, 1 new message',
      _ => 'Chat, $unread new messages',
    };
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FzCircleButton(
          key: GameTopBar.chatKey,
          icon: unread > 0 ? Icons.chat_bubble : Icons.chat_bubble_outline,
          tooltip: label,
          onPressed: onPressed,
        ),
        if (unread > 0)
          Positioned(
            top: 2,
            right: 0,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: Container(
                  key: const Key('chatUnreadBadge'),
                  constraints: const BoxConstraints(minWidth: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: FzColors.ac2,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    textAlign: TextAlign.center,
                    // Fixed: a badge that grows with the text would cover the
                    // button; the count is in the tooltip at any size.
                    textScaler: TextScaler.noScaling,
                    style: fz.m(11, color: FzColors.bgDeep, height: 1.6),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
