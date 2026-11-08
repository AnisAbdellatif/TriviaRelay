import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/fz_theme.dart';
import 'fz_direction.dart';
import 'fz_motion.dart';

/// Flat Ground navy with the design's rings spreading from just off the top
/// right corner, fading out as they go.
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

  @override
  Widget build(BuildContext context) {
    final arcs = this.arcs;
    // The page is a Material, not a painted box: ink (a tile's splash, its
    // hover and focus wash) is drawn on the nearest Material, and an opaque
    // box above the Scaffold's hid all of it.
    return Material(
      color: FzColors.bg,
      child: Stack(
        // Tight constraints for [child], as it had when it was the painter's
        // child: a Stack loosens its non-positioned children by default, and
        // a loose width would stop every `stretch` Column filling the screen.
        fit: StackFit.expand,
        children: [
          if (arcs != null)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(painter: _CornerRingsPainter(arcs)),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Concentric hairline rings, in a box just big enough for the outermost,
/// fading out towards it: the ones behind a winner.
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
    final center = size.center(Offset.zero);
    final outer = first + step * count;
    for (var i = 0; i < count; i++) {
      final r = first + step * i;
      canvas.drawCircle(center, r, _ringPaint(color, 1 - r / outer));
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.color != color ||
      old.first != first ||
      old.step != step ||
      old.count != count;
}

/// A ring's hairline, [color] at [strength] of its alpha.
Paint _ringPaint(Color color, double strength) => Paint()
  ..color = color.withValues(alpha: color.a * strength.clamp(0, 1))
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1;

/// The rings behind every screen: centred just off the top right corner
/// (108% across, 6% above), one every 47px, fading to nothing at 72% of the
/// way to the far corner. Painted once, on their own layer.
class _CornerRingsPainter extends CustomPainter {
  const _CornerRingsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 1.08, -size.height * .06);
    final reach = (center - size.bottomLeft(Offset.zero)).distance * .72;
    for (var r = 46.5; r < reach; r += 47) {
      canvas.drawCircle(center, r, _ringPaint(color, 1 - r / reach));
    }
  }

  @override
  bool shouldRepaint(_CornerRingsPainter old) => old.color != color;
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
    this.ground = FzColors.bg,
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

/// The two short bars under a title: Signal, then Flare; all Flare through
/// the final round ([flare]).
class FzAccentBars extends StatelessWidget {
  const FzAccentBars({super.key, this.flare = false});

  final bool flare;

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
        bar(36, flare ? FzColors.ac2 : FzColors.ac),
        const SizedBox(width: 6),
        bar(16, FzColors.ac2),
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
  static const _side = 20.0;

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
                            14,
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

/// [danger] is an outline in Flare: a way out (sign out, leave).
enum FzButtonKind { primary, pink, outline, danger }

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
    this.fontSize = 18,
    this.radius = 18,
    this.expand = true,
    this.selected = false,
    this.busy = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final FzButtonKind kind;

  /// Drawn before the label (a selected button shows its check instead).
  final IconData? icon;

  /// Small DM Mono hint on the right (e.g. "host", "wager 10").
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
    final filled = kind == FzButtonKind.primary || kind == FzButtonKind.pink;
    final danger = kind == FzButtonKind.danger;
    final fill = kind == FzButtonKind.pink ? FzColors.ac2 : FzColors.ac;
    // Disabled is the whole button at 38% (below), so its colours stay.
    final fg = filled
        ? FzColors.bg
        : danger
        ? FzColors.ac2
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
            trailing!.toUpperCase(),
            semanticsLabel: trailing,
            style: fz.m(
              10.5,
              // Full strength on a fill: at 75% the hint was 4.4:1 on Flare.
              color: filled ? fg : FzColors.dim,
              tracking: .08,
            ),
          );
    final text = Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: hint == null ? TextAlign.center : TextAlign.start,
      style: fz.h(fontSize, weight: FontWeight.w700, color: fg),
    );
    final lead = selected ? Icons.check : icon;
    final title = lead != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(lead, size: 22, color: fg),
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
              foregroundColor: FzColors.bg,
              disabledBackgroundColor: fill,
              disabledForegroundColor: FzColors.bg,
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
                  foregroundColor: fg,
                  disabledForegroundColor: fg,
                  minimumSize: minimumSize,
                  padding: padding,
                  shape: shape,
                ).copyWith(
                  side: fzFocusRing(
                    otherwise: BorderSide(
                      color: danger
                          ? FzColors.ac2.withValues(alpha: .6)
                          : FzColors.edge,
                      width: 2,
                    ),
                  ),
                ),
            child: content,
          );
    if (!live) return Opacity(opacity: .38, child: button);
    if (!selected) return button;
    return MergeSemantics(child: Semantics(selected: true, child: button));
  }
}

/// Round 44px outlined icon button (back, settings, copy, chat), in a 48px
/// target. With [fill] it is a solid disc instead (send, the bypass button).
class FzCircleButton extends StatelessWidget {
  const FzCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.fill,
    this.size = 44,
    this.outlined = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? fill;
  final double size;

  /// False for a bare icon (a banner's close).
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final fill = this.fill;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      style:
          IconButton.styleFrom(
            foregroundColor: fill == null ? FzColors.ink : FzColors.bg,
            backgroundColor: fill,
            disabledBackgroundColor: fill?.withValues(alpha: .38),
            fixedSize: Size.square(size),
            minimumSize: Size.square(size),
            shape: const CircleBorder(),
          ).copyWith(
            side: fzFocusRing(
              otherwise: fill != null || !outlined
                  ? null
                  : const BorderSide(color: FzColors.edge, width: 1.5),
            ),
          ),
    );
  }
}

/// The unread count on a circle button: a Flare pill over its corner.
class FzBadge extends StatelessWidget {
  const FzBadge({super.key, required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -2,
          right: -2,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: Container(
                constraints: const BoxConstraints(minWidth: 19),
                height: 19,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FzColors.ac2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: FzTheme.of(context)
                      .h(11, weight: FontWeight.w700, color: FzColors.bg),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A tappable card or row: ink on press and hover, and a ring while it has
/// keyboard focus, which Material's faint focus wash alone didn't show.
///
/// It brings its own transparent Material, so the ink shows whatever is
/// painted behind the tile. [framed] draws the design's tile around [child]:
/// a faint wash and hairline, 64px tall at least, or an [accent] wash and
/// edge when it is the chosen one.
class FzTile extends StatefulWidget {
  const FzTile({
    super.key,
    required this.onTap,
    required this.child,
    this.radius = 18,
    this.framed = false,
    this.accent,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  });

  final VoidCallback? onTap;
  final Widget child;
  final double radius;
  final bool framed;
  final Color? accent;
  final EdgeInsetsGeometry padding;

  @override
  State<FzTile> createState() => _FzTileState();
}

class _FzTileState extends State<FzTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.radius);
    final accent = widget.accent;
    final frame = widget.framed
        ? BoxDecoration(
            color: accent == null ? FzColors.wash : FzColors.washOf(accent),
            borderRadius: radius,
            border: Border.all(color: accent ?? FzColors.line),
          )
        : null;
    Widget child = widget.child;
    if (widget.framed) {
      child = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(padding: widget.padding, child: child),
      );
    }
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: frame,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: radius,
          highlightColor: FzColors.bgGlow.withValues(alpha: .6),
          onFocusChange: (focused) => setState(() => _focused = focused),
          child: Container(
            foregroundDecoration: _focused
                ? BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: FzColors.focus, width: 2.5),
                  )
                : null,
            child: child,
          ),
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
      FzTheme.of(context).m(size, tracking: .14);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: maxLines,
      softWrap: maxLines != 1,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: FzTheme.of(context).m(size, color: color, tracking: .14),
    );
  }
}

/// Tiny uppercase tag in a hairline box (YOU, HOST, READY, "wager 10"):
/// dim, or an accent's colour with its edge, or [filled] Signal (YOU).
class FzTag extends StatelessWidget {
  const FzTag(
    this.text, {
    super.key,
    this.color = FzColors.dim,
    this.filled = false,
  });

  final String text;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final plain = color == FzColors.dim;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : null,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: filled
              ? color
              : plain
              ? FzColors.hairline
              : FzColors.edgeOf(color),
        ),
      ),
      child: Text(
        text.toUpperCase(),
        style: FzTheme.of(context).m(
          10.5,
          color: filled ? FzColors.bg : color,
          tracking: .08,
          height: 1,
        ),
      ),
    );
  }
}

/// Translucent rounded card with a hairline edge; [FzPanel.tone] washes it
/// in an accent (the game code, the answer, a warning).
class FzPanel extends StatelessWidget {
  const FzPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = FzColors.panel,
    this.borderColor = FzColors.line,
    this.radius = 22,
  });

  FzPanel.tone(
    Color accent, {
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
  }) : color = FzColors.washOf(accent),
       borderColor = FzColors.edgeOf(accent);

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
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      // Ink (a switch row, a tile) inside paints on the panel, not under it.
      child: Material(type: MaterialType.transparency, child: child),
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
    this.size = 40,
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
      HSLColor.fromAHSL(1, (hue % 360).toDouble(), .75, .7).toColor();

  static Color colorFor(String id) {
    var hash = 0;
    for (final unit in id.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return colorForHue(hash % 360);
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
        color: away ? FzColors.panel : color,
        shape: BoxShape.circle,
      ),
      // The name is always beside it; the initial read out as well was noise.
      child: ExcludeSemantics(
        child: Text(
          initial,
          style: FzTheme.of(context).h(
            size * .42,
            weight: FontWeight.w700,
            color: away ? FzColors.faint : FzColors.bg,
          ),
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
  const FzWaiting(
    this.text, {
    super.key,
    this.color = FzColors.dim,
    this.dot = FzColors.ac,
  });

  final String text;
  final Color color;

  /// The dot's colour: Signal, or Flare for leaving.
  final Color dot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FzBlink(
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(text, style: FzTheme.of(context).small(15, color)),
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
    this.period = const Duration(milliseconds: 700),
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

/// One choice among a few (a wager, a number of questions, a list): the
/// theme's [ChoiceChip] with a plain label, filled in [accent] with a check
/// when chosen. The key lands on the chip itself.
ChoiceChip fzChoiceChip({
  Key? key,
  required String label,
  required bool selected,
  required ValueChanged<bool>? onSelected,
  Color accent = FzColors.ac,
  String? tooltip,
  Widget? child,
}) => ChoiceChip(
  key: key,
  // At least the design's 48px, however short the label.
  label:
      child ??
      ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 22),
        child: Text(label, textAlign: TextAlign.center),
      ),
  tooltip: tooltip,
  selected: selected,
  onSelected: onSelected,
  color: WidgetStateProperty.resolveWith(
    (states) =>
        states.contains(WidgetState.selected) ? accent : Colors.transparent,
  ),
);

/// A strip under the top bar: a [title], an optional [detail] under it, a
/// [leading] dot or icon, and a [trailing] action. Flare by default (the
/// connection), Signal for good news, or neutral ([FzColors.ink]).
class FzBanner extends StatelessWidget {
  const FzBanner({
    super.key,
    required this.title,
    this.detail,
    this.leading,
    this.trailing,
    this.tone = FzColors.ac2,
    this.margin = const EdgeInsets.fromLTRB(12, 0, 12, 8),
  });

  final Widget title;
  final String? detail;
  final Widget? leading;
  final Widget? trailing;
  final Color tone;
  final EdgeInsetsGeometry margin;

  /// A small round dot, steady or pulsing.
  static Widget dot(Color color, {bool pulse = false}) {
    final dot = Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    return pulse ? FzBlink(child: dot) : dot;
  }

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final neutral = tone == FzColors.ink;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      margin: margin,
      padding: EdgeInsets.fromLTRB(14, 8, trailing == null ? 14 : 6, 8),
      decoration: BoxDecoration(
        color: neutral ? FzColors.panel : tone.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: neutral ? FzColors.hairline : FzColors.edgeOf(tone),
        ),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle.merge(
                  style: fz.h(14, weight: FontWeight.w600, height: 1.3),
                  child: title,
                ),
                if (detail != null)
                  FzDirection(
                    text: detail!,
                    child: Text(detail!, style: fz.small(13)),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

/// A list's empty, no-match or failed state: a quiet icon, a bold line, a
/// dim one under it, and an action when there is one.
class FzNotice extends StatelessWidget {
  const FzNotice({
    super.key,
    required this.icon,
    required this.title,
    this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    return FzPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, size: 30, color: FzColors.faint),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: fz.h(16, weight: FontWeight.w700),
          ),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(detail!, textAlign: TextAlign.center, style: fz.small()),
          ],
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

/// A pushed screen's top row: back, a title, and an action or two.
class FzHeaderRow extends StatelessWidget {
  const FzHeaderRow({
    super.key,
    required this.title,
    this.eyebrow = false,
    this.actions = const [],
    this.onBack,
    this.backTooltip = 'Back',
  });

  final String title;

  /// The title as a small eyebrow (a form) rather than a heading (a list).
  final bool eyebrow;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final String backTooltip;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    return Row(
      children: [
        FzCircleButton(
          icon: Icons.arrow_back,
          tooltip: backTooltip,
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Semantics(
            header: true,
            child: eyebrow
                ? FzEyebrow(title, color: FzColors.ink, maxLines: 1)
                : Text(title, style: fz.heading()),
          ),
        ),
        for (final action in actions) ...[const SizedBox(width: 8), action],
      ],
    );
  }
}

/// Two placeholder rows while a list loads: the shape of what is coming,
/// so nothing jumps when it arrives.
class FzSkeletonRows extends StatelessWidget {
  const FzSkeletonRows({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height, Color color) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
    Widget row(double opacity, double width) => Opacity(
      opacity: opacity,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: FzColors.wash,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: FzColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: FzColors.wash3,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(width, 14, FzColors.wash3),
                const SizedBox(height: 8),
                bar(width * .64, 11, FzColors.panel),
              ],
            ),
          ],
        ),
      ),
    );
    return Semantics(
      label: 'Loading',
      child: Column(
        children: [row(.7, 140), const SizedBox(height: 8), row(.45, 110)],
      ),
    );
  }
}

/// A field with its button beside it (join, save, activate); stacked under
/// it when large text leaves no room.
class FzInlineAction extends StatelessWidget {
  const FzInlineAction({
    super.key,
    required this.field,
    required this.action,
    this.actionWidth,
  });

  final Widget field;
  final Widget action;

  /// The button's width beside the field; its own width when null.
  final double? actionWidth;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(10) > 13) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [field, const SizedBox(height: 10), action],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: field),
        const SizedBox(width: 8),
        if (actionWidth case final width?)
          SizedBox(width: width, child: action)
        else
          action,
      ],
    );
  }
}

/// A row in a menu sheet: a 44px rounded icon square, a bold label and a dim
/// line under it. [color] tints the icon and label (Flare for kick, leave).
class FzMenuRow extends StatelessWidget {
  const FzMenuRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.detail,
    this.color = FzColors.ink,
  });

  final IconData icon;
  final Widget label;
  final String? detail;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fz = FzTheme.of(context);
    final enabled = onTap != null;
    return ListTile(
      minTileHeight: 64,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      horizontalTitleGap: 14,
      enabled: enabled,
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: FzColors.panel,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 22, color: enabled ? color : FzColors.faint),
      ),
      title: DefaultTextStyle.merge(
        style: fz.h(
          16,
          weight: FontWeight.w700,
          color: enabled ? color : FzColors.dim,
        ),
        child: label,
      ),
      subtitle: detail == null ? null : Text(detail!, style: fz.small()),
    );
  }
}

/// A menu sheet's small heading, at the gutter.
class FzSheetHeading extends StatelessWidget {
  const FzSheetHeading(this.text, {super.key, this.color = FzColors.dim});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: FzEyebrow(text, color: color),
    ),
  );
}
