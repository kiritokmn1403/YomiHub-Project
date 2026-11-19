// YomiHub New Version (Mangayomi v0.9.96) Design Tokens & Theme for Flutter 3.47.6.
// Adapted from Mangayomi 0.9.96 (Shiori + material_ui) without Flutter 3.50 dependencies.
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:mangayomi/utils/platform_utils.dart';
import 'package:mangayomi/yomihub/ui/liquid_glass.dart';

/// Spacing scale on a 4-point grid.
abstract final class Mv2Space {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
}

/// Corner radii tokens per UI role.
abstract final class Mv2Shape {
  /// Pills and compact status badges.
  static const double badge = 4;

  /// Series covers: soft rectangular book corners.
  static const double cover = 6;

  /// Cards, menus, snackbars and input fields.
  static const double card = 12;

  /// Dialogs, bottom sheets and navigation rail indicators.
  static const double sheet = 20;

  /// Capsule buttons, segmented controls, chips and floating bar.
  static const double pill = 999;
}

/// Motion durations and Material 3 easing curves.
abstract final class Mv2Motion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 220);
  static const Duration enter = Duration(milliseconds: 350);
  static const Duration exitSlow = Duration(milliseconds: 500);
  static const Duration ambient = Duration(milliseconds: 1100);
  static const Duration pageTransition = Duration(milliseconds: 300);

  static const Curve standardCurve = Cubic(0.2, 0, 0, 1);
  static const Curve enterCurve = Cubic(0.05, 0.7, 0.1, 1);
  static const Curve exitCurve = Cubic(0.3, 0, 0.8, 0.15);

  /// Returns [Duration.zero] when platform reduced-motion is enabled.
  static Duration of(BuildContext context, Duration duration) =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
          ? Duration.zero
          : duration;
}

/// Alpha ladder for translucent washes, borders and focus states.
abstract final class Mv2Alphas {
  static const double tint = 0.08;
  static const double hairline = 0.16;
  static const double focus = 0.14;
  static const double accentTint = 0.16;
  static const double secondary = 0.70;
  static const double tvFocus = 0.45;
  static const double disabled = 0.38;
  static const double chrome = 0.92;
}

/// Fixed scrim overlays drawn over cover artwork or video frames.
abstract final class Mv2Scrim {
  static const Color onImage = Color(0x66000000);
  static const Color shadow = Color(0x66000000);
  static const Color underText = Color(0x99000000);
  static const Color panel = Color(0xC7000000);
}

/// Standard 2:3 aspect ratio for manga, anime and novel covers.
const double kMv2CoverAspect = 2 / 3;

/// Neutral ink surface ramp (cool paper in light mode, ink in dark mode).
@immutable
class Mv2Neutrals {
  const Mv2Neutrals({
    required this.lowest,
    required this.ground,
    required this.low,
    required this.base,
    required this.high,
    required this.highest,
    required this.dim,
    required this.bright,
    required this.fg,
    required this.fgMuted,
    required this.outline,
    required this.outlineVariant,
    required this.inverse,
    required this.onInverse,
  });

  final Color lowest;
  final Color ground;
  final Color low;
  final Color base;
  final Color high;
  final Color highest;
  final Color dim;
  final Color bright;
  final Color fg;
  final Color fgMuted;
  final Color outline;
  final Color outlineVariant;
  final Color inverse;
  final Color onInverse;

  static const light = Mv2Neutrals(
    lowest: Color(0xFFFFFFFF),
    ground: Color(0xFFF6F6F9),
    low: Color(0xFFF1F1F6),
    base: Color(0xFFECECF2),
    high: Color(0xFFE5E6EE),
    highest: Color(0xFFDEDFE8),
    dim: Color(0xFFD9DAE3),
    bright: Color(0xFFFFFFFF),
    fg: Color(0xFF15161D),
    fgMuted: Color(0xFF4B4D5C),
    outline: Color(0xFF777A8C),
    outlineVariant: Color(0xFFC6C8D4),
    inverse: Color(0xFF2A2B36),
    onInverse: Color(0xFFF1F1F6),
  );

  static const dark = Mv2Neutrals(
    lowest: Color(0xFF0A0B10),
    ground: Color(0xFF0F1016),
    low: Color(0xFF14151D),
    base: Color(0xFF171823),
    high: Color(0xFF20212F),
    highest: Color(0xFF292A3A),
    dim: Color(0xFF0F1016),
    bright: Color(0xFF2E3042),
    fg: Color(0xFFECEDF5),
    fgMuted: Color(0xFFA3A5B8),
    outline: Color(0xFF6E7084),
    outlineVariant: Color(0xFF34364A),
    inverse: Color(0xFFECEDF5),
    onInverse: Color(0xFF171823),
  );

  static const pureBlack = Mv2Neutrals(
    lowest: Color(0xFF000000),
    ground: Color(0xFF000000),
    low: Color(0xFF0A0A0F),
    base: Color(0xFF111118),
    high: Color(0xFF1A1B24),
    highest: Color(0xFF23242F),
    dim: Color(0xFF000000),
    bright: Color(0xFF26283A),
    fg: Color(0xFFECEDF5),
    fgMuted: Color(0xFFA3A5B8),
    outline: Color(0xFF6E7084),
    outlineVariant: Color(0xFF2C2E3F),
    inverse: Color(0xFFECEDF5),
    onInverse: Color(0xFF111118),
  );

  static Mv2Neutrals of(Brightness brightness, {bool pureBlack = false}) =>
      brightness == Brightness.light
          ? light
          : (pureBlack ? Mv2Neutrals.pureBlack : dark);

  /// Applies this neutral surface ramp onto [scheme] while keeping palette accents.
  ColorScheme applyTo(ColorScheme scheme) => scheme.copyWith(
        surface: ground,
        onSurface: fg,
        onSurfaceVariant: fgMuted,
        surfaceDim: dim,
        surfaceBright: bright,
        surfaceContainerLowest: lowest,
        surfaceContainerLow: low,
        surfaceContainer: base,
        surfaceContainerHigh: high,
        surfaceContainerHighest: highest,
        outline: outline,
        outlineVariant: outlineVariant,
        inverseSurface: inverse,
        onInverseSurface: onInverse,
        shadow: const Color(0xFF000000),
        scrim: const Color(0xFF000000),
        surfaceTint: const Color(0x00000000),
      );
}

/// Semantic status identifiers for badges and indicators.
enum Mv2StatusKind {
  unread,
  downloaded,
  read,
  offline,
  completed,
  newChapter,
  error,
}

/// Background/foreground color pair for status pills.
@immutable
class Mv2Status {
  const Mv2Status(this.background, this.foreground);

  final Color background;
  final Color foreground;

  static Mv2Status lerp(Mv2Status a, Mv2Status b, double t) => Mv2Status(
        Color.lerp(a.background, b.background, t)!,
        Color.lerp(a.foreground, b.foreground, t)!,
      );
}

/// Semantic color tokens derived from the active [ColorScheme].
@immutable
class Mv2Colors {
  const Mv2Colors({
    required this.ink0,
    required this.ink1,
    required this.ink2,
    required this.ink3,
    required this.fg,
    required this.fgMuted,
    required this.hairline,
    required this.accent,
    required this.accentInk,
    required this.onAccent,
    required this.unread,
    required this.downloaded,
    required this.read,
    required this.offline,
    required this.completed,
    required this.newChapter,
    required this.error,
  });

  final Color ink0;
  final Color ink1;
  final Color ink2;
  final Color ink3;
  final Color fg;
  final Color fgMuted;
  final Color hairline;
  final Color accent;
  final Color accentInk;
  final Color onAccent;

  final Mv2Status unread;
  final Mv2Status downloaded;
  final Mv2Status read;
  final Mv2Status offline;
  final Mv2Status completed;
  final Mv2Status newChapter;
  final Mv2Status error;

  /// Picks pure black or white with higher WCAG contrast on [fill].
  static Color onFill(Color fill) {
    final l = fill.computeLuminance();
    final onBlack = (l + 0.05) / 0.05;
    final onWhite = 1.05 / (l + 0.05);
    return onBlack >= onWhite
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
  }

  /// Nudges [accent] toward black or white until contrast on [ground] >= [target].
  static Color legibleOn(Color accent, Color ground, {double target = 4.5}) {
    double ratio(Color c) {
      final a = c.computeLuminance();
      final b = ground.computeLuminance();
      return (a > b ? a + 0.05 : b + 0.05) / (a > b ? b + 0.05 : a + 0.05);
    }

    if (ratio(accent) >= target) return accent;
    final toward = ground.computeLuminance() > 0.18
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
    for (var t = 0.05; t < 1; t += 0.05) {
      final c = Color.lerp(accent, toward, t)!;
      if (ratio(c) >= target) return c;
    }
    return toward;
  }

  factory Mv2Colors.fromScheme(ColorScheme scheme, {Color? ground}) {
    final dark = scheme.brightness == Brightness.dark;
    final accent = scheme.primary;
    final ink0 = ground ?? scheme.surface;
    final onAccent = onFill(accent);
    return Mv2Colors(
      ink0: ink0,
      ink1: scheme.surfaceContainer,
      ink2: scheme.surfaceContainerHigh,
      ink3: scheme.surfaceContainerHighest,
      fg: scheme.onSurface,
      fgMuted: scheme.onSurfaceVariant,
      hairline: scheme.onSurface.withValues(alpha: Mv2Alphas.hairline),
      accent: accent,
      accentInk: legibleOn(accent, ink0),
      onAccent: onAccent,
      unread: Mv2Status(accent, onAccent),
      downloaded: Mv2Status(scheme.surfaceContainerHigh, scheme.onSurface),
      read: Mv2Status(scheme.surfaceContainerHigh, scheme.onSurfaceVariant),
      offline: dark
          ? const Mv2Status(Color(0xFF3A2F12), Color(0xFFF0BD5D))
          : const Mv2Status(Color(0xFFFBEFD5), Color(0xFF7A5200)),
      completed: dark
          ? const Mv2Status(Color(0xFF13301F), Color(0xFF6FD3A0))
          : const Mv2Status(Color(0xFFDDF3E6), Color(0xFF1F6B44)),
      newChapter: dark
          ? const Mv2Status(Color(0xFF2E1830), Color(0xFFE7A6F0))
          : const Mv2Status(Color(0xFFF6E3F8), Color(0xFF7E2D8C)),
      error: dark
          ? const Mv2Status(Color(0xFF3B1714), Color(0xFFFFB4AB))
          : const Mv2Status(Color(0xFFFCE4E1), Color(0xFFA3261B)),
    );
  }

  Mv2Status statusFor(Mv2StatusKind kind) => switch (kind) {
        Mv2StatusKind.unread => unread,
        Mv2StatusKind.downloaded => downloaded,
        Mv2StatusKind.read => read,
        Mv2StatusKind.offline => offline,
        Mv2StatusKind.completed => completed,
        Mv2StatusKind.newChapter => newChapter,
        Mv2StatusKind.error => error,
      };

  static Mv2Colors lerp(Mv2Colors a, Mv2Colors b, double t) => Mv2Colors(
        ink0: Color.lerp(a.ink0, b.ink0, t)!,
        ink1: Color.lerp(a.ink1, b.ink1, t)!,
        ink2: Color.lerp(a.ink2, b.ink2, t)!,
        ink3: Color.lerp(a.ink3, b.ink3, t)!,
        fg: Color.lerp(a.fg, b.fg, t)!,
        fgMuted: Color.lerp(a.fgMuted, b.fgMuted, t)!,
        hairline: Color.lerp(a.hairline, b.hairline, t)!,
        accent: Color.lerp(a.accent, b.accent, t)!,
        accentInk: Color.lerp(a.accentInk, b.accentInk, t)!,
        onAccent: Color.lerp(a.onAccent, b.onAccent, t)!,
        unread: Mv2Status.lerp(a.unread, b.unread, t),
        downloaded: Mv2Status.lerp(a.downloaded, b.downloaded, t),
        read: Mv2Status.lerp(a.read, b.read, t),
        offline: Mv2Status.lerp(a.offline, b.offline, t),
        completed: Mv2Status.lerp(a.completed, b.completed, t),
        newChapter: Mv2Status.lerp(a.newChapter, b.newChapter, t),
        error: Mv2Status.lerp(a.error, b.error, t),
      );
}

/// Platform density scale for touch, desktop and 10-foot TV UI.
enum Mv2Density {
  phone(minTarget: 48, rowHeight: 56, typeScale: 1.0),
  desktop(minTarget: 36, rowHeight: 44, typeScale: 0.94),
  tv(minTarget: 56, rowHeight: 64, typeScale: 1.33);

  const Mv2Density({
    required this.minTarget,
    required this.rowHeight,
    required this.typeScale,
  });

  final double minTarget;
  final double rowHeight;
  final double typeScale;

  static Mv2Density resolve() => isTv
      ? Mv2Density.tv
      : isDesktop
          ? Mv2Density.desktop
          : Mv2Density.phone;
}

/// Nine-role typographic hierarchy scaled by [Mv2Density.typeScale].
@immutable
class Mv2Type {
  const Mv2Type._({
    required this.screenTitle,
    required this.seriesTitle,
    required this.section,
    required this.card,
    required this.body,
    required this.row,
    required this.meta,
    required this.badge,
    required this.overline,
  });

  factory Mv2Type.scaled(double scale, {String? fontFamily}) {
    TextStyle s(
      double size,
      FontWeight weight, {
      double tracking = 0,
      double? height,
      bool tabular = false,
    }) =>
        TextStyle(
          fontFamily: fontFamily,
          fontSize: size * scale,
          fontWeight: weight,
          letterSpacing: tracking * size * scale,
          height: height,
          fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
        );
    return Mv2Type._(
      screenTitle: s(28, FontWeight.w800, tracking: -0.02),
      seriesTitle: s(22, FontWeight.w800, tracking: -0.015),
      section: s(17, FontWeight.w700),
      card: s(14, FontWeight.w600),
      body: s(15, FontWeight.w400, height: 1.45),
      row: s(14, FontWeight.w500),
      meta: s(12, FontWeight.w500, tabular: true),
      badge: s(11, FontWeight.w800, tabular: true),
      overline: s(11, FontWeight.w700, tracking: 0.12),
    );
  }

  final TextStyle screenTitle;
  final TextStyle seriesTitle;
  final TextStyle section;
  final TextStyle card;
  final TextStyle body;
  final TextStyle row;
  final TextStyle meta;
  final TextStyle badge;
  final TextStyle overline;

  static final Mv2Type reference = Mv2Type.scaled(1.0);

  static Mv2Type lerp(Mv2Type a, Mv2Type b, double t) => Mv2Type._(
        screenTitle: TextStyle.lerp(a.screenTitle, b.screenTitle, t)!,
        seriesTitle: TextStyle.lerp(a.seriesTitle, b.seriesTitle, t)!,
        section: TextStyle.lerp(a.section, b.section, t)!,
        card: TextStyle.lerp(a.card, b.card, t)!,
        body: TextStyle.lerp(a.body, b.body, t)!,
        row: TextStyle.lerp(a.row, b.row, t)!,
        meta: TextStyle.lerp(a.meta, b.meta, t)!,
        badge: TextStyle.lerp(a.badge, b.badge, t)!,
        overline: TextStyle.lerp(a.overline, b.overline, t)!,
      );
}

/// ThemeExtension carrying resolved colors, typography and density tokens.
@immutable
class Mv2Tokens extends ThemeExtension<Mv2Tokens> {
  Mv2Tokens({
    required this.color,
    required this.density,
    String? fontFamily,
  }) : text = Mv2Type.scaled(density.typeScale, fontFamily: fontFamily);

  const Mv2Tokens._(this.color, this.text, this.density);

  final Mv2Colors color;
  final Mv2Type text;
  final Mv2Density density;

  double scaled(double value) => value * density.typeScale;

  TextStyle get caption => text.meta.copyWith(color: color.fgMuted);

  TextStyle get groupLabel => text.overline.copyWith(color: color.accentInk);

  @override
  Mv2Tokens copyWith({Mv2Colors? color, Mv2Density? density}) => Mv2Tokens._(
        color ?? this.color,
        density == null ? text : Mv2Type.scaled(density.typeScale),
        density ?? this.density,
      );

  @override
  Mv2Tokens lerp(covariant Mv2Tokens? other, double t) {
    if (other == null) return this;
    return Mv2Tokens._(
      Mv2Colors.lerp(color, other.color, t),
      Mv2Type.lerp(text, other.text, t),
      t < 0.5 ? density : other.density,
    );
  }
}

/// Convenience accessor `context.mv2` with safe fallback outside [Mv2Theme].
extension Mv2ThemeContext on BuildContext {
  Mv2Tokens get mv2 {
    final theme = Theme.of(this);
    return theme.extension<Mv2Tokens>() ??
        Mv2Tokens(
          color: Mv2Colors.fromScheme(theme.colorScheme),
          density: Mv2Density.phone,
        );
  }
}

/// Pill indicator for [TabBar] matching Mangayomi 0.9.96.
class Mv2TabIndicator extends Decoration {
  const Mv2TabIndicator({
    required this.color,
    this.height = 32,
    this.horizontalInset = Mv2Space.s12,
  });

  final Color color;
  final double height;
  final double horizontalInset;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _Mv2TabIndicatorPainter(this);

  @override
  bool operator ==(Object other) =>
      other is Mv2TabIndicator &&
      other.color == color &&
      other.height == height &&
      other.horizontalInset == horizontalInset;

  @override
  int get hashCode => Object.hash(color, height, horizontalInset);
}

class _Mv2TabIndicatorPainter extends BoxPainter {
  _Mv2TabIndicatorPainter(this.decoration);

  final Mv2TabIndicator decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null || size.isEmpty) return;
    final height = decoration.height.clamp(0.0, size.height - Mv2Space.s8);
    final rect = Rect.fromCenter(
      center: (offset & size).center,
      width: size.width + decoration.horizontalInset * 2,
      height: height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(height / 2)),
      Paint()..color = decoration.color,
    );
  }
}

/// Horizontal shared-axis page transition (Material Motion X-axis).
class Mv2PageTransitionsBuilder extends PageTransitionsBuilder {
  const Mv2PageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return child;
    }
    return Mv2SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

class Mv2SharedAxisTransition extends StatelessWidget {
  const Mv2SharedAxisTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    this.slideDistance = 30.0,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;
  final double slideDistance;

  static const Curve _linearOutSlowIn = Cubic(0, 0, 0.2, 1);
  static const Curve _fastOutLinearIn = Cubic(0.4, 0, 1, 1);
  static final _slide = CurveTween(curve: Curves.fastOutSlowIn);
  static final _fadeIn = CurveTween(
    curve: const Interval(0.35, 1.0, curve: _linearOutSlowIn),
  );
  static final _fadeOut = Tween<double>(begin: 1.0, end: 0.0).chain(
    CurveTween(curve: const Interval(0.0, 0.35, curve: _fastOutLinearIn)),
  );

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final sign = rtl ? -1.0 : 1.0;
    final enterSlide = animation.drive(_slide);
    final exitSlide = secondaryAnimation.drive(_slide);
    return AnimatedBuilder(
      animation: Listenable.merge([enterSlide, exitSlide]),
      builder: (context, inner) => Transform.translate(
        offset: Offset(
          sign * slideDistance * ((1 - enterSlide.value) - exitSlide.value),
          0,
        ),
        child: inner,
      ),
      child: FadeTransition(
        opacity: secondaryAnimation.drive(_fadeOut),
        child: FadeTransition(opacity: animation.drive(_fadeIn), child: child),
      ),
    );
  }
}

/// Builds light and dark [ThemeData] for YomiHub New Version (Mangayomi v0.9.96).
class Mv2Theme {
  Mv2Theme._();

  static const _subThemes = FlexSubThemesData(
    blendOnLevel: 10,
    thinBorderWidth: 2.0,
    unselectedToggleIsColored: true,
    inputDecoratorRadius: Mv2Shape.card,
    chipRadius: Mv2Shape.pill,
    cardRadius: Mv2Shape.card,
    popupMenuRadius: Mv2Shape.card,
    menuRadius: Mv2Shape.card,
    tooltipRadius: Mv2Shape.badge,
    snackBarRadius: Mv2Shape.card,
    dialogRadius: Mv2Shape.sheet,
    datePickerDialogRadius: Mv2Shape.sheet,
    timePickerDialogRadius: Mv2Shape.sheet,
    bottomSheetRadius: Mv2Shape.sheet,
  );

  static ThemeData light({
    required FlexSchemeColor colors,
    bool tintSurfaces = false,
    int blendLevel = 0,
    Mv2Density? density,
    String? fontFamily,
    LiquidGlassConfig? glass,
    bool? tvFocusOverride,
  }) =>
      build(
        brightness: Brightness.light,
        colors: colors,
        tintSurfaces: tintSurfaces,
        blendLevel: blendLevel,
        density: density,
        fontFamily: fontFamily,
        glass: glass,
        tvFocusOverride: tvFocusOverride,
      );

  static ThemeData dark({
    required FlexSchemeColor colors,
    bool tintSurfaces = false,
    int blendLevel = 0,
    bool pureBlack = false,
    Mv2Density? density,
    String? fontFamily,
    LiquidGlassConfig? glass,
    bool? tvFocusOverride,
  }) =>
      build(
        brightness: Brightness.dark,
        colors: colors,
        tintSurfaces: tintSurfaces,
        blendLevel: blendLevel,
        pureBlack: pureBlack,
        density: density,
        fontFamily: fontFamily,
        glass: glass,
        tvFocusOverride: tvFocusOverride,
      );

  static ThemeData build({
    required Brightness brightness,
    required FlexSchemeColor colors,
    bool tintSurfaces = false,
    int blendLevel = 0,
    bool pureBlack = false,
    Mv2Density? density,
    String? fontFamily,
    LiquidGlassConfig? glass,
    bool? tvFocusOverride,
  }) {
    final resolvedDensity = density ?? Mv2Density.resolve();
    final isLight = brightness == Brightness.light;
    final pure = !isLight && pureBlack;

    late final ThemeData baseTheme;
    if (tintSurfaces) {
      baseTheme = isLight
          ? FlexThemeData.light(
              colors: colors,
              surfaceMode: FlexSurfaceMode.highScaffoldLevelSurface,
              blendLevel: blendLevel,
              appBarOpacity: 0.00,
              subThemesData: _subThemes,
              useMaterial3ErrorColors: true,
              visualDensity: FlexColorScheme.comfortablePlatformDensity,
              useMaterial3: true,
              fontFamily: fontFamily,
            )
          : FlexThemeData.dark(
              colors: colors,
              surfaceMode: FlexSurfaceMode.level,
              blendLevel: pure ? 0 : blendLevel,
              appBarOpacity: 0.00,
              darkIsTrueBlack: pure,
              subThemesData: _subThemes,
              useMaterial3ErrorColors: true,
              visualDensity: FlexColorScheme.comfortablePlatformDensity,
              useMaterial3: true,
              fontFamily: fontFamily,
            );
    } else {
      final neutrals = Mv2Neutrals.of(brightness, pureBlack: pure);
      final paletteScheme = isLight
          ? FlexColorScheme.light(
              colors: colors,
              useMaterial3: true,
              useMaterial3ErrorColors: true,
            ).toScheme
          : FlexColorScheme.dark(
              colors: colors,
              useMaterial3: true,
              useMaterial3ErrorColors: true,
            ).toScheme;
      final scheme = neutrals.applyTo(paletteScheme);

      baseTheme = isLight
          ? FlexThemeData.light(
              colorScheme: scheme,
              blendLevel: 0,
              scaffoldBackground: neutrals.ground,
              appBarOpacity: 0.00,
              subThemesData: _subThemes,
              useMaterial3ErrorColors: true,
              visualDensity: FlexColorScheme.comfortablePlatformDensity,
              useMaterial3: true,
              fontFamily: fontFamily,
            )
          : FlexThemeData.dark(
              colorScheme: scheme,
              blendLevel: 0,
              scaffoldBackground: neutrals.ground,
              appBarOpacity: 0.00,
              darkIsTrueBlack: pure,
              subThemesData: _subThemes,
              useMaterial3ErrorColors: true,
              visualDensity: FlexColorScheme.comfortablePlatformDensity,
              useMaterial3: true,
              fontFamily: fontFamily,
            );
    }

    var themed = _withTokens(
      baseTheme,
      density: resolvedDensity,
      fontFamily: fontFamily,
    );
    if (tvFocusOverride ?? isTv) {
      themed = _applyTvFocus(themed);
    }
    if (glass != null) {
      themed = applyLiquidGlass(themed, glass);
    }
    return themed;
  }

  static ThemeData _withTokens(
    ThemeData theme, {
    required Mv2Density density,
    String? fontFamily,
  }) {
    final mv2Colors = Mv2Colors.fromScheme(
      theme.colorScheme,
      ground: theme.scaffoldBackgroundColor,
    );
    final tokens = Mv2Tokens(
      color: mv2Colors,
      density: density,
      fontFamily: fontFamily,
    );
    final t = tokens.text;
    return theme.copyWith(
      textTheme: _mapTextTheme(theme.textTheme, t),
      dividerColor: mv2Colors.hairline,
      dividerTheme: DividerThemeData(
        color: mv2Colors.hairline,
        thickness: 0.5,
      ),
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle: t.section.copyWith(color: mv2Colors.fg),
        surfaceTintColor: Colors.transparent,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: Mv2PageTransitionsBuilder(),
          TargetPlatform.fuchsia: Mv2PageTransitionsBuilder(),
          TargetPlatform.linux: Mv2PageTransitionsBuilder(),
          TargetPlatform.windows: Mv2PageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: mv2Colors.accent,
        foregroundColor: mv2Colors.onAccent,
        extendedTextStyle: t.row.copyWith(fontWeight: FontWeight.w700),
        shape: const StadiumBorder(),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: mv2Colors.accentInk,
        unselectedLabelColor: mv2Colors.fgMuted,
        labelStyle: t.row.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: t.row.copyWith(fontWeight: FontWeight.w500),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStatePropertyAll(
          mv2Colors.fg.withValues(alpha: Mv2Alphas.tint),
        ),
        splashBorderRadius: BorderRadius.circular(Mv2Shape.pill),
        indicator: Mv2TabIndicator(
          color: mv2Colors.accent.withValues(alpha: Mv2Alphas.accentTint),
          height: 32 * density.typeScale,
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: t.body.copyWith(
          color: mv2Colors.fg,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
        subtitleTextStyle: t.meta.copyWith(color: mv2Colors.fgMuted),
        leadingAndTrailingTextStyle: t.meta.copyWith(color: mv2Colors.fgMuted),
        iconColor: mv2Colors.fgMuted,
        selectedColor: mv2Colors.accentInk,
        minTileHeight: density.rowHeight,
        contentPadding: const EdgeInsets.symmetric(horizontal: Mv2Space.s16),
      ),
      extensions: [
        ...theme.extensions.values,
        tokens,
      ],
    );
  }

  static ThemeData _applyTvFocus(ThemeData theme) {
    final ring = WidgetStateProperty.resolveWith<BorderSide?>(
      (states) => states.contains(WidgetState.focused)
          ? BorderSide(color: theme.colorScheme.onSurface, width: 2.5)
          : null,
    );
    ButtonStyle withRing(ButtonStyle? base) =>
        (base ?? const ButtonStyle()).copyWith(side: ring);
    return theme.copyWith(
      focusColor: theme.colorScheme.primary.withValues(alpha: Mv2Alphas.tvFocus),
      textButtonTheme: TextButtonThemeData(
        style: withRing(theme.textButtonTheme.style),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: withRing(theme.elevatedButtonTheme.style),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: withRing(theme.filledButtonTheme.style),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: withRing(theme.outlinedButtonTheme.style),
      ),
    );
  }

  static TextTheme _mapTextTheme(TextTheme base, Mv2Type t) {
    TextStyle? onto(TextStyle? style, TextStyle role, {FontWeight? weight}) =>
        style?.copyWith(
          fontSize: role.fontSize,
          fontWeight: weight ?? role.fontWeight,
          height: role.height,
          letterSpacing: role.letterSpacing,
        );
    return base.copyWith(
      headlineLarge: onto(base.headlineLarge, t.screenTitle),
      headlineMedium: onto(base.headlineMedium, t.screenTitle),
      headlineSmall: onto(base.headlineSmall, t.seriesTitle),
      titleLarge: onto(base.titleLarge, t.seriesTitle, weight: FontWeight.w700),
      titleMedium: onto(base.titleMedium, t.section, weight: FontWeight.w600),
      titleSmall: onto(base.titleSmall, t.row),
      bodyLarge: onto(base.bodyLarge, t.body),
      bodyMedium: onto(base.bodyMedium, t.row, weight: FontWeight.w400),
      bodySmall: onto(base.bodySmall, t.meta, weight: FontWeight.w400),
      labelLarge: onto(base.labelLarge, t.row, weight: FontWeight.w600),
      labelMedium: onto(base.labelMedium, t.meta),
      labelSmall: onto(base.labelSmall, t.badge, weight: FontWeight.w600),
    );
  }
}
