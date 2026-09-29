import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
    // The page is a Material, not a painted box: ink (a tile's splash, its
    // hover and focus wash) is drawn on the nearest Material, and an opaque
    // box above the Scaffold's hid all of it.
    return Material(
      color: FzColors.bgDeep,
      child: Stack(
        // Tight constraints for [child], as it had when it was the painter's
        // child: a Stack loosens its non-positioned children by default, and
        // a loose width would stop every `stretch` Column filling the screen.
        fit: StackFit.expand,
        children: [
          if (arcs != null)
            // Centred just off the top right corner, as in the design.
            Positioned(
              top: -30 - _corner.radius,
              right: 10 - _corner.radius,
              child: RepaintBoundary(child: _corner.withColor(arcs)),
            ),
          child,
        ],
      ),
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

/// Phone-width column: scrolling [child], an optional [top] pinned above it
/// and an optional [footer] pinned below it. No background; use inside
/// [FzPage] or a game shell.
///
/// The footer is pinned while that leaves the content room to be read. When it
/// wouldn't (a phone on its side, large text, an open keyboard, a footer of
/// several buttons), it scrolls with the content instead, after it: a pinned
/// footer taller than the screen left nothing to scroll, and in landscape a
/// sliver of page.
class FzBody extends StatefulWidget {
  const FzBody({
    super.key,
    required this.child,
    this.footer,
    this.top,
    this.header,
  });

  final Widget child;
  final Widget? footer;

  /// Kept in view above the scrolling content (the question clock).
  final Widget? top;

  /// A screen's own top row ([FzPage]'s). Pinned while there is room; on a
  /// short screen (a phone on its side, the keyboard up) it scrolls away with
  /// the content, since every one of them has a system back as well.
  final Widget? header;

  /// Below this height the [header] scrolls with the content.
  static const shortHeight = 480.0;

  /// Whether a footer [footer] tall can stay pinned in [available] height: it
  /// must leave the content more than half of it, and never less than 240px.
  static bool footerFits({required double available, required double footer}) =>
      available - footer >= math.max(240, available * .55);

  @override
  State<FzBody> createState() => _FzBodyState();
}

class _FzBodyState extends State<FzBody> {
  static const _side = 22.0;

  /// The footer's height, and the part of the height the pinned top takes,
  /// as last laid out. Neither depends on where the footer sits, so the
  /// choice made from them is stable.
  double? _footer;
  double _above = 0;

  /// The choice the last build made, and the height it had to go on.
  bool _inline = false;
  double _height = double.infinity;
  bool _rechecking = false;

  bool _decide(double height) {
    final footer = _footer;
    if (footer == null) return false;
    return !FzBody.footerFits(available: height - _above, footer: footer);
  }

  /// A new measurement that changes the choice (the first layout, a footer
  /// that grew) rebuilds once the frame is done. A change of room (the
  /// keyboard, a turned phone) needs none: the build it causes decides with
  /// the room it has, in the same frame, so a field that scrolls itself into
  /// view above the keyboard does it against the final layout.
  void _measured() {
    if (_rechecking || _decide(_height) == _inline) return;
    _rechecking = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rechecking = false;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _height = constraints.maxHeight;
            final inline = _inline = _decide(_height);
            final header = widget.header == null
                ? null
                : _ordered(
                    1,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(_side, 12, _side, 0),
                      child: widget.header,
                    ),
                  );
            final headerInline = header != null && _height < FzBody.shortHeight;
            final footer = widget.footer == null
                ? null
                : _ordered(
                    4,
                    _ReportHeight(
                      onHeight: (height) {
                        _footer = height;
                        _measured();
                      },
                      child: widget.footer!,
                    ),
                  );
            final top = widget.top == null
                ? null
                : _ordered(
                    2,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(_side, 8, _side, 4),
                      child: widget.top,
                    ),
                  );
            final above = [if (header != null && !headerInline) header, ?top];
            final scroll = SingleChildScrollView(
              // The content keeps its key wherever the header and footer go,
              // so moving them never rebuilds it: a focused field in it
              // would lose its focus, and with it the keyboard that made the
              // move.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (headerInline)
                    KeyedSubtree(key: _headerKey, child: header),
                  KeyedSubtree(
                    key: _contentKey,
                    child: _ordered(
                      3,
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          _side,
                          12,
                          _side,
                          16,
                        ),
                        child: widget.child,
                      ),
                    ),
                  ),
                  if (footer != null && inline)
                    KeyedSubtree(
                      key: _footerKey,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(_side, 6, _side, 22),
                        child: footer,
                      ),
                    ),
                ],
              ),
            );
            // Tab goes header and clock, then content, then footer, each
            // read in its own order: by position alone, content scrolled
            // under a pinned footer was visited in among its buttons.
            return FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: ClipRect(
                child: CustomMultiChildLayout(
                  delegate: _BodyLayout(),
                  children: [
                    if (above.isNotEmpty)
                      LayoutId(
                        id: _BodySlot.top,
                        child: _ReportHeight(
                          onHeight: (height) {
                            _above = height;
                            _measured();
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: above,
                          ),
                        ),
                      ),
                    LayoutId(id: _BodySlot.scroll, child: scroll),
                    if (footer != null && !inline)
                      LayoutId(
                        id: _BodySlot.footer,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            _side,
                            8,
                            _side,
                            22,
                          ),
                          child: footer,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// One region of the page for the keyboard: read in its own order, and
  /// [order]th among the regions.
  static Widget _ordered(double order, Widget child) => FocusTraversalOrder(
    order: NumericFocusOrder(order),
    child: FocusTraversalGroup(child: child),
  );

  static const _headerKey = ValueKey('header');
  static const _contentKey = ValueKey('content');
  static const _footerKey = ValueKey('footer');
}

enum _BodySlot { top, scroll, footer }

/// Top, then the footer at its natural height at the bottom, then the scroll
/// in what is left. Never reports an overflow: a footer taller than the room
/// is drawn cut off for the one frame before [FzBody] moves it into the
/// scroll.
class _BodyLayout extends MultiChildLayoutDelegate {
  @override
  void performLayout(Size size) {
    final width = BoxConstraints.tightFor(width: size.width);
    var top = 0.0;
    if (hasChild(_BodySlot.top)) {
      top = layoutChild(_BodySlot.top, width).height;
      positionChild(_BodySlot.top, Offset.zero);
    }
    final available = math.max(0.0, size.height - top);
    var footer = 0.0;
    if (hasChild(_BodySlot.footer)) {
      footer = math.min(available, layoutChild(_BodySlot.footer, width).height);
      positionChild(_BodySlot.footer, Offset(0, size.height - footer));
    }
    layoutChild(
      _BodySlot.scroll,
      BoxConstraints.tightFor(
        width: size.width,
        height: math.max(0.0, available - footer),
      ),
    );
    positionChild(_BodySlot.scroll, Offset(0, top));
  }

  @override
  bool shouldRelayout(_BodyLayout oldDelegate) => false;
}

/// Tells [onHeight] its child's height after every layout.
class _ReportHeight extends SingleChildRenderObjectWidget {
  const _ReportHeight({required this.onHeight, super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReportHeight(onHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderReportHeight renderObject,
  ) => renderObject.onHeight = onHeight;
}

class _RenderReportHeight extends RenderProxyBox {
  _RenderReportHeight(this.onHeight);

  ValueChanged<double> onHeight;

  @override
  void performLayout() {
    super.performLayout();
    onHeight(size.height);
  }
}

/// Full screen: background, safe area, and [FzBody] with an optional [header]
/// row.
class FzPage extends StatelessWidget {
  const FzPage({super.key, required this.child, this.header, this.footer});

  final Widget child;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return FzBackground(
      child: SafeArea(
        child: FzBody(header: header, footer: footer, child: child),
      ),
    );
  }
}

enum FzButtonKind { primary, pink, outline }

/// The design's big rounded buttons: flat Signal or Flare, or a hairline
/// outline. Built on Material buttons so disabled state and semantics come for
/// free.
///
/// The label always wins the room: the [trailing] hint moves under it when the
/// two don't fit on one line (large text, a narrow phone), rather than cutting
/// the label short.
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
    this.selected = false,
    this.busy = false,
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

  /// The choice made (a final vote): drawn in its colour with a check, never
  /// greyed out, and not pressed again.
  final bool selected;

  /// Sent, waiting on the relay: drawn as it was, with a spinner in place of
  /// the hint, and not pressed again until the answer comes.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    // Selected and busy look live but take no press.
    final live = onPressed != null || selected || busy;
    final press = selected || busy ? null : onPressed;
    final filled = kind != FzButtonKind.outline;
    final fill = kind == FzButtonKind.pink ? FzColors.ac2 : FzColors.ac;
    final fg = !live
        ? FzColors.faint
        : filled
        ? FzColors.bgDeep
        : FzColors.ink;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final minimumSize = Size(expand ? double.infinity : 0, height);
    const padding = EdgeInsets.symmetric(horizontal: 22, vertical: 8);

    final Widget? hint = busy
        ? SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : trailing == null
        ? null
        : Text(
            trailing!,
            style: fz.m(
              13,
              // Full strength on a fill: at 75% the hint was 4.4:1 on Flare.
              color: filled || !live ? fg : FzColors.dim,
            ),
          );
    final text = Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: hint == null ? TextAlign.center : TextAlign.start,
      style: fz.h(fontSize, color: fg),
    );
    final title = selected
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 20, color: fg),
              const SizedBox(width: 8),
              Flexible(child: text),
            ],
          )
        : text;

    Widget content = hint == null
        ? title
        : Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 2,
            children: [title, hint],
          );
    // A Wrap is only as wide as its longest line; spreading the hint to the
    // far edge needs the button's whole width.
    if (hint != null && expand) {
      content = SizedBox(width: double.infinity, child: content);
    }

    final button = filled
        ? FilledButton(
            onPressed: press,
            style: FilledButton.styleFrom(
              backgroundColor: fill,
              foregroundColor: FzColors.bgDeep,
              disabledBackgroundColor: live ? fill : FzColors.panel,
              disabledForegroundColor: live ? FzColors.bgDeep : fg,
              minimumSize: minimumSize,
              padding: padding,
              shape: shape,
              elevation: 0,
            ).copyWith(side: fzFocusRing()),
            child: content,
          )
        : OutlinedButton(
            onPressed: press,
            style:
                OutlinedButton.styleFrom(
                  foregroundColor: FzColors.ink,
                  disabledForegroundColor: fg,
                  minimumSize: minimumSize,
                  padding: padding,
                  shape: shape,
                ).copyWith(
                  side: fzFocusRing(
                    otherwise: BorderSide(
                      color: live ? FzColors.edge : FzColors.line,
                      width: 1.5,
                    ),
                  ),
                ),
            child: content,
          );
    if (!selected) return button;
    return MergeSemantics(child: Semantics(selected: true, child: button));
  }
}

/// Round 44px outlined icon button (back, leave, settings), in a 48px target.
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
      style:
          IconButton.styleFrom(
            foregroundColor: FzColors.ink,
            fixedSize: const Size(44, 44),
            minimumSize: const Size(44, 44),
            shape: const CircleBorder(),
          ).copyWith(
            side: fzFocusRing(
              otherwise: const BorderSide(color: FzColors.edge, width: 1.5),
            ),
          ),
    );
  }
}

/// A tappable card or row: ink on press and hover, and a ring while it has
/// keyboard focus, which Material's faint focus wash alone didn't show.
///
/// It brings its own transparent Material, so the ink shows whatever is
/// painted behind the tile.
class FzTile extends StatefulWidget {
  const FzTile({
    super.key,
    required this.onTap,
    required this.child,
    this.radius = 16,
  });

  final VoidCallback? onTap;
  final Widget child;
  final double radius;

  @override
  State<FzTile> createState() => _FzTileState();
}

class _FzTileState extends State<FzTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.radius);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: radius,
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: Container(
          foregroundDecoration: _focused
              ? BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: FzColors.focus, width: 2.5),
                )
              : null,
          child: widget.child,
        ),
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
    this.maxLines,
  });

  final String text;
  final Color color;
  final double size;

  /// Cut short with an ellipsis past this many lines; unlimited if null.
  final int? maxLines;

  static TextStyle style(BuildContext context, {double size = 11}) =>
      FzTheme.of(context).m(size, tracking: .16);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: maxLines,
      softWrap: maxLines != 1,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
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
    this.away = false,
  });

  final String id;
  final String name;
  final int? hue;
  final double size;

  /// Not connected: the colour fades and the initial turns light, so the
  /// letter stays readable (a faded whole avatar left it at 1.4:1).
  final bool away;

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
    final color = hue == null ? colorFor(id) : colorForHue(hue!);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: away ? color.withValues(alpha: .28) : color,
        shape: BoxShape.circle,
        border: away
            ? Border.all(color: color.withValues(alpha: .6), width: 1.5)
            : null,
      ),
      // The name is always beside it; the initial read out as well was noise.
      child: ExcludeSemantics(
        child: Text(
          initial,
          style: FzTheme.of(context)
              .h(size * .42, color: away ? FzColors.ink : FzColors.bgDeep),
        ),
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
