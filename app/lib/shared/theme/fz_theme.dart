import 'package:flutter/material.dart';

/// Colour tokens from the Trivia Relay redesign ("Baton system",
/// `design/ui-inventory.md` and the Claude Design boards it produced).
///
/// What each colour may mean: Signal is your move (the primary action, your
/// row, what is chosen, the rings). Flare is the stakes (the final round,
/// wagers, leaving, kicking). OK is confirmed truth only (locked in, right,
/// ready). Alarm is the clock and nothing else, never an error.
///
/// Four surfaces, darkest first: [bgDeep] behind the phone column, [bg] under
/// every screen, [bgGlow] for sheets and pressed tiles, [lift] for the only
/// floating layer (dialogs and toasts). Hairlines, not shadows, separate them.
abstract final class FzColors {
  /// Signal yellow, primary.
  static const ac = Color(0xFFFFD23F);

  /// Flare pink, secondary and "wrong".
  static const ac2 = Color(0xFFFF4F7B);
  static const ink = Color(0xFFF1F0EA);

  /// Secondary text. 66% ink: at least 4.5:1 on every ground the app draws.
  static const dim = Color(0xA8F1F0EA);

  /// Placeholders, fine print, disabled labels: text nobody has to read to
  /// play. 50% ink, still 3:1 on the page.
  static const faint = Color(0x80F1F0EA);

  /// Ground: every screen's background, and the text colour on Signal or
  /// Flare.
  static const bg = Color(0xFF111729);

  /// Void: behind the phone column on a wide screen.
  static const bgDeep = Color(0xFF0A0E1A);

  /// Raised: sheets, pressed tiles, placeholders for pictures that haven't
  /// come.
  static const bgGlow = Color(0xFF1B2442);

  /// Lift: dialogs and toasts, the only layer that floats.
  static const lift = Color(0xFF232C4D);

  /// The faintest wash: a tile at rest.
  static const wash = Color(0x0AFFFFFF);

  /// A panel's wash.
  static const panel = Color(0x12FFFFFF);

  /// A stronger wash: an empty switch track, a skeleton row.
  static const wash3 = Color(0x1FFFFFFF);

  /// The mat behind a question's photo. Near-opaque warm white rather than the
  /// translucent [panel]: photos are letterboxed to fit (`BoxFit.contain`), and
  /// over the dark page that made a diagram, a product shot or anything else
  /// on a white ground read as a hole with the subject floating in it. A light
  /// mat gives it an edge, the way a print has one.
  static const photoMat = Color(0xF7F1F0EA);

  /// Hairline borders that only decorate: dividers between rows, panels,
  /// tiles. 12% ink.
  static const line = Color(0x1FF1F0EA);

  /// The stronger hairline: sheets, dialogs, toasts, tags. 24% ink.
  static const hairline = Color(0x3DF1F0EA);

  /// The outline that tells a control apart from the page: fields, chips,
  /// outlined and round buttons. 40% ink, 3:1 on the page (WCAG 1.4.11),
  /// where the design's 24% [hairline] would be 1.9:1.
  static const edge = Color(0x66F1F0EA);

  /// The ring around whatever has keyboard focus: ink, not the design's
  /// Signal, because a Signal ring with no gap merged into a Signal button.
  static const focus = ink;

  /// The empty part of a progress bar.
  static const track = wash3;
  static const ok = Color(0xFF3EE0A1);

  /// Red, for a clock that is running out and nothing else: Flare already
  /// means "wrong", and time running out has to read as a louder thing.
  static const alarm = Color(0xFFFF3B30);

  /// The Signal rings in the top corner of every screen, at their brightest
  /// (they fade out from the corner).
  static const arcs = Color(0x33FFD23F);

  /// The rings of the final round.
  static const flareArcs = Color(0x42FF4F7B);

  /// An accent's wash and its hairline: a chosen tile, a banner, a re-marked
  /// guess.
  static Color washOf(Color accent) => accent.withValues(alpha: .09);
  static Color edgeOf(Color accent) => accent.withValues(alpha: .48);
}

typedef FontApplier = TextStyle Function(TextStyle style);

/// Fonts for the design: Figtree for questions, body and buttons, DM Mono for
/// labels, codes and numbers, Bricolage Grotesque for screen titles, and Noto
/// Naskh Arabic behind all three for anything written in Arabic.
///
/// All three are bundled with the app (pubspec `fonts:`) and referenced by
/// family name, so nothing is ever fetched over the network — the design holds
/// on a LAN with no internet, and no page load waits on a third party.
@immutable
class FzTheme extends ThemeExtension<FzTheme> {
  const FzTheme({
    required this.displayFont,
    required this.monoFont,
    required this.titleFont,
  });

  final FontApplier displayFont;
  final FontApplier monoFont;
  final FontApplier titleFont;

  /// The Latin fonts carry no Arabic, so everything written in it — a quiz, a
  /// name, an answer — is drawn by the fallback. Naskh is the shape Arabic is
  /// read in, and the one to hand a question to.
  ///
  /// Bundled rather than left to the system, because without a fallback that
  /// covers Arabic, Flutter Web fetches one from fonts.gstatic.com on first
  /// paint — a third-party request, and blank text at a party with no internet.
  static const _arabicFallback = ['Noto Naskh Arabic'];

  static TextStyle _figtree(TextStyle style) => style.copyWith(
    fontFamily: 'Figtree',
    fontFamilyFallback: _arabicFallback,
  );

  static TextStyle _dmMono(TextStyle style) => style.copyWith(
    fontFamily: 'DM Mono',
    fontFamilyFallback: const [..._arabicFallback, 'monospace'],
  );

  /// Bricolage Grotesque is one variable file. Its axes are set explicitly,
  /// weight and optical size (which the browser would match to the font size),
  /// so every platform draws the same heavy, tight title.
  static TextStyle _bricolage(TextStyle style) => style.copyWith(
    fontFamily: 'Bricolage Grotesque',
    fontFamilyFallback: _arabicFallback,
    fontVariations: [
      FontVariation.weight((style.fontWeight ?? FontWeight.w800).value * 1.0),
      FontVariation.opticalSize((style.fontSize ?? 14).clamp(12, 96) * 1.0),
    ],
  );

  /// The design's fonts, by the family names the bundled files declare.
  /// Named `fallback` because it is also what a widget test gets when no theme
  /// extension is installed; since the fonts were bundled it is the real thing
  /// in both cases.
  static const fallback = FzTheme(
    displayFont: _figtree,
    monoFont: _dmMono,
    titleFont: _bricolage,
  );

  static FzTheme of(BuildContext context) =>
      Theme.of(context).extension<FzTheme>() ?? fallback;

  /// Figtree. [tracking] is letter-spacing in em, as in the design's CSS.
  TextStyle h(
    double size, {
    FontWeight weight = FontWeight.w800,
    Color color = FzColors.ink,
    double? height,
    double tracking = 0,
  }) => displayFont(
    TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: size * tracking,
    ),
  );

  /// DM Mono. [tracking] is letter-spacing in em.
  TextStyle m(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = FzColors.ink,
    double? height,
    double tracking = 0,
  }) => monoFont(
    TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: size * tracking,
    ),
  );

  /// Bricolage Grotesque ExtraBold, the design's screen titles: tight
  /// letters, tight lines ("Pick a pack", "Your wager", "Trivia Relay").
  TextStyle t(
    double size, {
    FontWeight weight = FontWeight.w800,
    Color color = FzColors.ink,
    double height = 1.0,
    double tracking = -.02,
  }) => titleFont(
    TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: size * tracking,
    ),
  );

  /// The type scale. Display: a screen's hero title (Bricolage 40/40).
  TextStyle display([double size = 40, Color color = FzColors.ink]) =>
      t(size, color: color);

  /// Title: a phase's or a screen's title (Bricolage 28/31).
  TextStyle title([double size = 28, Color color = FzColors.ink]) =>
      t(size, color: color, height: 1.1, tracking: -.015);

  /// Heading: a pack's name, a sheet's title (Figtree 700 20/25).
  TextStyle heading([double size = 20, Color color = FzColors.ink]) =>
      h(size, weight: FontWeight.w700, color: color, height: 1.25);

  /// Body: explanations under a title (Figtree 16/23), dim unless told.
  TextStyle body([double size = 16, Color color = FzColors.dim]) =>
      h(size, weight: FontWeight.w400, color: color, height: 1.45);

  /// Small: notes under a control (Figtree 13.5/19), dim unless told.
  TextStyle small([double size = 13.5, Color color = FzColors.dim]) =>
      h(size, weight: FontWeight.w400, color: color, height: 1.4);

  /// A big number: a score, a wager, the clock (Bricolage 800, even digits).
  TextStyle numeral(double size, [Color color = FzColors.ink]) => t(
    size,
    color: color,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  @override
  FzTheme copyWith({
    FontApplier? displayFont,
    FontApplier? monoFont,
    FontApplier? titleFont,
  }) => FzTheme(
    displayFont: displayFont ?? this.displayFont,
    monoFont: monoFont ?? this.monoFont,
    titleFont: titleFont ?? this.titleFont,
  );

  @override
  FzTheme lerp(FzTheme? other, double t) => this;
}

/// A field's outline. Fields are an [FzColors.edge] outline until focused,
/// then a thicker Signal one; the one field a screen is for (the game code,
/// the answer) wears a softer Signal from the start ([fzKeyFieldBorder]).
OutlineInputBorder fzFieldBorder(Color color, {double width = 1.5}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );

/// The unfocused outline of the one field a screen is for: Signal, but softer
/// and thinner than the focused outline, so focus still shows (the focused
/// one adds a band of full Signal, 13:1 on the page).
final fzKeyFieldBorder = fzFieldBorder(FzColors.ac.withValues(alpha: .6));

/// A focused field: full Signal, thick enough to read as a change.
final fzFocusedFieldBorder = fzFieldBorder(FzColors.ac, width: 2);

/// A button's outline while it has keyboard focus: a ring outside its edge,
/// [FzColors.focus] against the page. [otherwise] is its outline the rest of
/// the time.
WidgetStateProperty<BorderSide?> fzFocusRing({BorderSide? otherwise}) =>
    WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.focused)
          ? const BorderSide(
              color: FzColors.focus,
              width: 2.5,
              strokeAlign: BorderSide.strokeAlignOutside,
            )
          : otherwise,
    );

/// The app's single dark theme.
ThemeData buildFzTheme({
  FzTheme fz = FzTheme.fallback,
  TextTheme Function(TextTheme base)? applyTextFont,
}) {
  const border = fzFieldBorder;
  bool selected(Set<WidgetState> states) =>
      states.contains(WidgetState.selected);

  final baseText = Typography.material2021().white.apply(
    bodyColor: FzColors.ink,
    displayColor: FzColors.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: FzColors.ac,
      onPrimary: FzColors.bg,
      secondary: FzColors.ac2,
      onSecondary: FzColors.bg,
      tertiary: FzColors.ok,
      onTertiary: FzColors.bg,
      error: FzColors.ac2,
      onError: FzColors.bg,
      surface: FzColors.bg,
      onSurface: FzColors.ink,
      onSurfaceVariant: FzColors.dim,
      outline: FzColors.edge,
      outlineVariant: FzColors.line,
      surfaceContainerHigh: FzColors.lift,
      surfaceContainerLow: FzColors.bgGlow,
    ),
    scaffoldBackgroundColor: FzColors.bgDeep,
    textTheme: applyTextFont == null ? baseText : applyTextFont(baseText),
    extensions: [fz],
    dividerTheme: const DividerThemeData(color: FzColors.line, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x4D000000),
      hintStyle: fz.h(17, weight: FontWeight.w500, color: FzColors.faint),
      labelStyle: fz.small(),
      floatingLabelStyle: fz.small(13.5, FzColors.ac),
      errorStyle: fz.small(13.5, FzColors.ac2),
      counterStyle: fz.m(12, color: FzColors.faint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: border(FzColors.edge),
      enabledBorder: border(FzColors.edge),
      focusedBorder: fzFocusedFieldBorder,
      disabledBorder: border(FzColors.line),
      errorBorder: border(FzColors.ac2),
      focusedErrorBorder: border(FzColors.ac2),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 6,
      activeTrackColor: FzColors.ac,
      inactiveTrackColor: FzColors.track,
      thumbColor: FzColors.ac,
      overlayColor: FzColors.ac.withValues(alpha: .16),
      activeTickMarkColor: FzColors.bgDeep.withValues(alpha: .35),
      inactiveTickMarkColor: FzColors.line,
      disabledActiveTrackColor: FzColors.faint,
      disabledThumbColor: FzColors.faint,
      valueIndicatorColor: FzColors.ac,
      valueIndicatorTextStyle: fz.m(14, color: FzColors.bgDeep),
    ),
    switchTheme: SwitchThemeData(
      // A 52 by 32 track, empty until on, with a round thumb: ink at rest,
      // Ground on the Signal track.
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => selected(states) ? FzColors.bg : FzColors.ink,
      ),
      thumbIcon: const WidgetStatePropertyAll(Icon(null)),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => selected(states) ? FzColors.ac : FzColors.wash3,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => selected(states) ? FzColors.ac : FzColors.edge,
      ),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? FzColors.focus.withValues(alpha: .4)
            : null,
      ),
    ),
    // One dialog shape for every dialog: the design's type rather than
    // Material's, and never wider than the phone column it opens over — on a
    // desktop the default stretched a short form across the whole window.
    dialogTheme: DialogThemeData(
      backgroundColor: FzColors.lift,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 480),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: FzColors.hairline),
      ),
      titleTextStyle: fz.heading(),
      contentTextStyle: fz.body(15),
      actionsPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
    ),
    // Every choice in the app (wagers, options, pack lists) is a ChoiceChip:
    // an outlined box that fills Signal, with a check, when chosen, so the
    // choice never rests on colour alone. Call sites give a plain label
    // ([fzChoiceChip]), which also sets the accent.
    chipTheme: ChipThemeData(
      showCheckmark: true,
      checkmarkColor: FzColors.bg,
      color: WidgetStateProperty.resolveWith(
        (states) => selected(states) ? FzColors.ac : Colors.transparent,
      ),
      side: WidgetStateBorderSide.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? const BorderSide(color: FzColors.focus, width: 2.5)
            : selected(states)
            ? BorderSide.none
            : const BorderSide(color: FzColors.edge, width: 1.5),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      labelStyle: fz
          .h(16, weight: FontWeight.w600)
          .copyWith(
            color: WidgetStateColor.resolveWith(
              (states) => selected(states) ? FzColors.bg : FzColors.ink,
            ),
          ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: FzColors.ink,
        disabledForegroundColor: FzColors.faint,
        textStyle: fz.h(16, weight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(48, 48),
      ).copyWith(side: fzFocusRing()),
    ),
    // Icon buttons without an outline of their own (a field's clear button,
    // the update banner's close) still show where the keyboard is.
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(side: fzFocusRing()),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: FzColors.lift,
      contentTextStyle: fz.h(15, weight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: FzColors.ac,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1A2240),
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: FzColors.hairline,
      dragHandleSize: Size(40, 5),
      modalBarrierColor: Color(0x9E05070E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: FzColors.hairline),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: FzColors.ink,
      titleTextStyle: fz.h(16, weight: FontWeight.w700),
      subtitleTextStyle: fz.small(),
      minVerticalPadding: 10,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: FzColors.ac,
      selectionColor: Color(0x55FFD23F),
      selectionHandleColor: FzColors.ac,
    ),
  );
}
