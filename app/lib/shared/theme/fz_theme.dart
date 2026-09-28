import 'package:flutter/material.dart';

/// Colour tokens from the Trivia Relay design canvas
/// (https://claude.ai/artifact/Paezq4BHSeaUd4XLqfiZTt, "Identity").
///
/// Signal is the first leg of the relay: primary actions, the game code, the
/// leader. Flare is the second: host actions, the held seat, the final round.
/// Red is reserved for a clock running out.
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

  /// Navy: the card ground.
  static const bg = Color(0xFF111729);

  /// Darkest navy, behind everything, and the text colour on Signal or Flare.
  static const bgDeep = Color(0xFF0A0E1A);

  /// Raised navy: placeholders for pictures that haven't come.
  static const bgGlow = Color(0xFF1B2442);
  static const panel = Color(0x0FF1F0EA);

  /// The mat behind a question's photo. Near-opaque warm white rather than the
  /// translucent [panel]: photos are letterboxed to fit (`BoxFit.contain`), and
  /// over the dark page that made a diagram, a product shot or anything else
  /// on a white ground read as a hole with the subject floating in it. A light
  /// mat gives it an edge, the way a print has one.
  static const photoMat = Color(0xF7F1F0EA);

  /// Hairline borders: fields, outlined buttons, chips.
  static const line = Color(0x33F1F0EA);

  /// The empty part of a progress bar.
  static const track = Color(0x1AF1F0EA);
  static const ok = Color(0xFF3EE0A1);

  /// Red, for a clock that is running out and nothing else: Flare already
  /// means "wrong", and time running out has to read as a louder thing.
  static const alarm = Color(0xFFFF3B30);

  /// The Signal rings in the top corner of every screen.
  static const arcs = Color(0x12FFD23F);

  /// The rings of the final round.
  static const flareArcs = Color(0x17FF4F7B);
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
    double height = 1.05,
    double tracking = -.025,
  }) => titleFont(
    TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: size * tracking,
    ),
  );

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

/// A field's outline. Fields are hairline until focused; the one field a
/// screen is for (the game code, the answer) is Signal from the start.
OutlineInputBorder fzFieldBorder(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(14),
  borderSide: BorderSide(color: color, width: 1.5),
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
      onPrimary: FzColors.bgDeep,
      secondary: FzColors.ac2,
      onSecondary: FzColors.bgDeep,
      tertiary: FzColors.ok,
      onTertiary: FzColors.bgDeep,
      error: FzColors.ac2,
      onError: FzColors.bgDeep,
      surface: FzColors.bg,
      onSurface: FzColors.ink,
      onSurfaceVariant: FzColors.dim,
      outline: FzColors.line,
      outlineVariant: FzColors.line,
    ),
    scaffoldBackgroundColor: FzColors.bgDeep,
    textTheme: applyTextFont == null ? baseText : applyTextFont(baseText),
    extensions: [fz],
    dividerTheme: const DividerThemeData(color: FzColors.line, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: fz.m(15, color: FzColors.faint),
      labelStyle: fz.m(13, color: FzColors.dim),
      floatingLabelStyle: fz.m(13, color: FzColors.ac),
      errorStyle: fz.m(11, color: FzColors.ac2),
      counterStyle: fz.m(10, color: FzColors.faint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: border(FzColors.line),
      enabledBorder: border(FzColors.line),
      focusedBorder: border(FzColors.ac),
      disabledBorder: border(FzColors.panel),
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
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => selected(states) ? FzColors.bgDeep : FzColors.dim,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => selected(states) ? FzColors.ac : FzColors.panel,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => selected(states) ? FzColors.ac : FzColors.line,
      ),
    ),
    // One dialog shape for every dialog: the design's type rather than
    // Material's, and never wider than the phone column it opens over — on a
    // desktop the default stretched a short form across the whole window.
    dialogTheme: DialogThemeData(
      backgroundColor: FzColors.bg,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 480),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: fz.t(24),
      contentTextStyle: fz.m(13, color: FzColors.dim, height: 1.5),
    ),
    // Every choice in the app (wagers, options, pack lists) is a ChoiceChip:
    // a hairline box that turns Signal when chosen. Each call site sets only
    // its label.
    chipTheme: ChipThemeData(
      showCheckmark: false,
      color: WidgetStateProperty.resolveWith(
        (states) => selected(states)
            ? FzColors.ac.withValues(alpha: .24)
            : Colors.transparent,
      ),
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: selected(states) ? FzColors.ac : FzColors.line,
          width: 1.5,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      labelStyle: fz.m(14),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: FzColors.ac,
        disabledForegroundColor: FzColors.faint,
        textStyle: fz.h(15, weight: FontWeight.w700),
        minimumSize: const Size(48, 44),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: FzColors.bgGlow,
      contentTextStyle: fz.m(13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: FzColors.ac,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: FzColors.bg,
      showDragHandle: true,
      dragHandleColor: FzColors.line,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: FzColors.ac,
      selectionColor: Color(0x55FFD23F),
      selectionHandleColor: FzColors.ac,
    ),
  );
}
