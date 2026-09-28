import 'package:flutter/material.dart';

import '../theme/fz_theme.dart';
import 'fz_motion.dart';

/// Flat deep navy with the design's rings spreading from the top corner.
///
/// The rings are a sibling of [child] behind their own [RepaintBoundary], not
/// its parent: as a parent they shared one layer with the page, so every tick
/// of the question clock re-recorded them along with it. On their own layer
/// they are painted once and composited after that, whatever the page in
/// front of them is doing.
class FzBackground extends StatelessWidget {
  const FzBackground({
    super.key,
    required this.child,
    this.arcs = FzColors.arcs,
  });

  final Widget child;

  /// The rings' colour; null draws none.
  final Color? arcs;

  static const _corner = FzRings(
    color: FzColors.arcs,
    first: 90,
    step: 70,
    count: 5,
  );

  @override
  Widget build(BuildContext context) {
    final arcs = this.arcs;
    return Stack(
      // Tight constraints for [child], as it had when it was the painter's
      // child: a Stack loosens its non-positioned children by default, and a
      // loose width would stop every `stretch` Column filling the screen.
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: ColoredBox(color: FzColors.bgDeep)),
        if (arcs != null)
          // Centred just off the top right corner, as in the design.
          Positioned(
            top: -30 - _corner.radius,
            right: 10 - _corner.radius,
            child: RepaintBoundary(child: _corner.withColor(arcs)),
          ),
        child,
      ],
    );
  }
}

/// Concentric hairline rings, in a box just big enough for the outermost: the
/// rings in the corner of every screen, and the ones behind a winner.
class FzRings extends StatelessWidget {
  const FzRings({
    super.key,
    required this.color,
    required this.first,
    required this.step,
    required this.count,
  });

  final Color color;
  final double first;
  final double step;
  final int count;

  /// The outermost ring's radius, half the box.
  double get radius => first + step * (count - 1);

  FzRings withColor(Color color) =>
      FzRings(color: color, first: first, step: step, count: count);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _RingsPainter(color, first, step, count),
        isComplex: true,
        size: Size.square(radius * 2 + 2),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  const _RingsPainter(this.color, this.first, this.step, this.count);

  final Color color;
  final double first;
  final double step;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final center = size.center(Offset.zero);
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(center, first + step * i, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.color != color ||
      old.first != first ||
      old.step != step ||
      old.count != count;
}

/// The Trivia Relay mark: a question mark run in two legs, Signal handing on
/// to Flare, with a seam where one passes the other.
///
/// [ground] is the colour behind it, which the seam is cut in. [faded] is the
/// broken mark of a seat that was let go.
class FzMark extends StatelessWidget {
  const FzMark({
    super.key,
    this.size = 72,
    this.ground = FzColors.bgDeep,
    this.faded = false,
  });

  final double size;
  final Color ground;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _MarkPainter(ground: ground, faded: faded),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.ground, required this.faded});

  final Color ground;
  final bool faded;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn in the design's 100-unit box, which sits 3 units high.
    final scale = size.width / 100;
    canvas
      ..scale(scale)
      ..translate(0, -3);
    // Thinner strokes vanish at launcher-row sizes; the design thickens them.
    final width = size.width < 40 ? 13.0 : 12.0;

    Paint stroke(Color color, [double? w]) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w ?? width;

    final first = Path()
      ..moveTo(33.58, 35.6)
      ..arcToPoint(
        const Offset(58.5, 25.28),
        radius: const Radius.circular(17),
      );
    Path second(Offset from) => Path()
      ..moveTo(from.dx, from.dy)
      ..arcToPoint(
        const Offset(63.93, 49.75),
        radius: const Radius.circular(17),
      )
      ..cubicTo(58.8, 57.1, 50, 58, 50, 66);
    const dot = Offset(50, 85);

    if (faded) {
      final ghost = FzColors.ink.withValues(alpha: .18);
      canvas
        ..drawPath(first, stroke(ghost))
        ..drawPath(
          second(const Offset(60.5, 29)),
          stroke(FzColors.ac2.withValues(alpha: .35)),
        );
      // The dot, only its dashed outline: nobody is sitting there.
      final ring = Path()..addOval(Rect.fromCircle(center: dot, radius: 7));
      final dashes = Path();
      for (final metric in ring.computeMetrics()) {
        for (var d = 0.0; d < metric.length; d += 7) {
          dashes.addPath(metric.extractPath(d, d + 3), Offset.zero);
        }
      }
      canvas.drawPath(dashes, stroke(ghost, 3)..strokeCap = StrokeCap.butt);
      return;
    }

    final handOff = second(const Offset(54.4, 23.58));
    canvas
      ..drawPath(first, stroke(FzColors.ac))
      ..drawPath(handOff, stroke(ground, width + 6))
      ..drawPath(handOff, stroke(FzColors.ac2))
      ..drawCircle(dot, width / 12 * 7, Paint()..color = FzColors.ac);
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.ground != ground || old.faded != faded;
}

/// The two short bars under a title: Signal, then Flare.
class FzAccentBars extends StatelessWidget {
  const FzAccentBars({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, Color color) => Container(
      width: width,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        bar(48, FzColors.ac),
        const SizedBox(width: 6),
        bar(30, FzColors.ac2),
      ],
    );
  }
}

/// Phone-width column: scrolling [child] with an optional [footer] pinned to
/// the bottom. No background; use inside [FzPage] or a game shell.
class FzBody extends StatelessWidget {
  const FzBody({super.key, required this.child, this.footer});

  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                child: child,
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

/// Full screen: background, safe area, optional [header] row, [FzBody].
class FzPage extends StatelessWidget {
  const FzPage({super.key, required this.child, this.header, this.footer});

  final Widget child;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return FzBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null)
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                    child: header,
                  ),
                ),
              ),
            Expanded(
              child: FzBody(footer: footer, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

enum FzButtonKind { primary, pink, outline }

/// The design's big rounded buttons: flat Signal or Flare, or a hairline
/// outline. Built on Material buttons so disabled state and semantics come for
/// free.
class FzButton extends StatelessWidget {
  const FzButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = FzButtonKind.primary,
    this.trailing,
    this.height = 60,
    this.fontSize = 17,
    this.radius = 16,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final FzButtonKind kind;

  /// Small DM Mono hint on the right (e.g. "host").
  final String? trailing;
  final double height;
  final double fontSize;
  final double radius;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final enabled = onPressed != null;
    final filled = kind != FzButtonKind.outline;
    final fill = kind == FzButtonKind.pink ? FzColors.ac2 : FzColors.ac;
    final fg = !enabled
        ? FzColors.faint
        : filled
        ? FzColors.bgDeep
        : FzColors.ink;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final minimumSize = Size(expand ? double.infinity : 0, height);
    const padding = EdgeInsets.symmetric(horizontal: 22);

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: trailing == null
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: fz.h(fontSize, color: fg),
          ),
        ),
        if (trailing != null)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              trailing!,
              style: fz.m(
                13,
                color: filled ? fg.withValues(alpha: .75) : FzColors.dim,
              ),
            ),
          ),
      ],
    );

    return filled
        ? FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: fill,
              foregroundColor: FzColors.bgDeep,
              disabledBackgroundColor: FzColors.panel,
              disabledForegroundColor: FzColors.faint,
              minimumSize: minimumSize,
              padding: padding,
              shape: shape,
              elevation: 0,
            ),
            child: content,
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: FzColors.ink,
              minimumSize: minimumSize,
              padding: padding,
              shape: shape,
              side: const BorderSide(color: FzColors.line, width: 1.5),
            ),
            child: content,
          );
  }
}

/// Small outlined pill ("Share", "Pause").
class FzPill extends StatelessWidget {
  const FzPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = FzColors.dim,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final fg = onPressed == null ? FzColors.faint : color;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: FzColors.faint,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: const StadiumBorder(),
        side: const BorderSide(color: FzColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(label, style: fz.m(11, color: fg, tracking: .04)),
        ],
      ),
    );
  }
}

/// Round 44px outlined icon button (back, leave, settings).
class FzCircleButton extends StatelessWidget {
  const FzCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      style: IconButton.styleFrom(
        foregroundColor: FzColors.ink,
        fixedSize: const Size(44, 44),
        minimumSize: const Size(44, 44),
        side: const BorderSide(color: FzColors.line, width: 1.5),
        shape: const CircleBorder(),
      ),
    );
  }
}

/// Small DM Mono uppercase label with wide tracking.
class FzEyebrow extends StatelessWidget {
  const FzEyebrow(
    this.text, {
    super.key,
    this.color = FzColors.dim,
    this.size = 11,
  });

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: FzTheme.of(context).m(size, color: color, tracking: .16),
    );
  }
}

/// Tiny uppercase tag (YOU, HOST, READY).
class FzTag extends StatelessWidget {
  const FzTag(this.text, {super.key, this.color = FzColors.dim});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: FzTheme.of(context).m(10, color: color, tracking: .1),
    );
  }
}

/// Translucent rounded card.
class FzPanel extends StatelessWidget {
  const FzPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = FzColors.panel,
    this.borderColor,
    this.radius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 1.5),
      ),
      child: child,
    );
  }
}

/// Circle with the player's initial on their colour.
///
/// [hue] is the server-assigned `avatar_hue` (protocol v4), so every device
/// shows the same colour; the id-derived colour is only a fallback.
class FzAvatar extends StatelessWidget {
  const FzAvatar({
    super.key,
    required this.id,
    required this.name,
    this.hue,
    this.size = 46,
  });

  final String id;
  final String name;
  final int? hue;
  final double size;

  static Color colorForHue(int hue) =>
      HSLColor.fromAHSL(1, (hue % 360).toDouble(), .9, .72).toColor();

  static Color colorFor(String id) {
    var hash = 0;
    for (final unit in id.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return HSLColor.fromAHSL(1, (hash % 360).toDouble(), .9, .72).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : trimmed.characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hue == null ? colorFor(id) : colorForHue(hue!),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: FzTheme.of(context).h(size * .42, color: FzColors.bgDeep),
      ),
    );
  }
}

/// A line that says the app is waiting on somebody else, with a pulsing dot
/// in front of it ("Waiting for the host to start…").
///
/// Only the dot pulses. The whole line used to, and at the bottom of the pulse
/// the text was a third of its colour — unreadable for half of every second,
/// on the screens people stare at longest while they wait.
class FzWaiting extends StatelessWidget {
  const FzWaiting(this.text, {super.key, this.color = FzColors.dim});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FzBlink(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: FzTheme.of(context).m(12.5, color: color, height: 1.4),
          ),
        ),
      ],
    );
  }
}

/// Endless soft opacity pulse (the dot in [FzWaiting]).
class FzBlink extends StatefulWidget {
  const FzBlink({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1100),
  });

  final Widget child;
  final Duration period;

  @override
  State<FzBlink> createState() => _FzBlinkState();
}

class _FzBlinkState extends State<FzBlink> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The only animation in the app that never stops, so the one that matters
    // most to anybody who asked for less of them.
    if (reduceMotion(context)) return widget.child;

    return FadeTransition(
      opacity: Tween<double>(
        begin: 1,
        end: .35,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

/// One-shot entrance: fade + scale from .92 (the design's `pop`), or a 10px
/// rise when [rise] is true.
///
/// [delay] holds it still first, so a list can be given one per row and land
/// as a run rather than all at once. The delay is folded into the one
/// animation as a leading flat stretch, which keeps this a single cheap
/// `TweenAnimationBuilder` and means nothing is left pending if the widget
/// goes away early.
class FzEnter extends StatelessWidget {
  const FzEnter({
    super.key,
    required this.child,
    this.rise = false,
    this.delay = Duration.zero,
  });

  final Widget child;
  final bool rise;
  final Duration delay;

  static const _travel = Duration(milliseconds: 240);

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;

    final total = delay + _travel;
    final start = delay.inMicroseconds / total.inMicroseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOut),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: rise
            ? Transform.translate(offset: Offset(0, 10 * (1 - t)), child: child)
            : Transform.scale(scale: .92 + .08 * t, child: child),
      ),
      child: child,
    );
  }
}
