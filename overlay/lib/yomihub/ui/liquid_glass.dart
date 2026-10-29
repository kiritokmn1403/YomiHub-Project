import 'package:mangayomi/yomihub/perf/perf_watchdog.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

/// YomiHub 0.1.6: "Liquid Glass" (Settings › Giao diện › Liquid Glass).
///
/// Native Flutter re-implementation of the look of the web projects listed in
/// the GitHub sheet (liquid-glass, liquid-glass-react, liquid-glass-js): a
/// frosted backdrop blur, a translucent tint, a thin bright rim and a soft
/// specular highlight. 0.1.6 splits it into areas that can be switched on
/// and off one by one:
///  * controls  – switches, sliders, buttons, chips, segmented buttons
///  * menus     – settings / More menus, dialogs, sheets, popup menus, cards
///  * nav       – the bottom bar / rail (Comic, Film & Movie, Novel, …)
///  * browser   – the in-app browser toolbar, address bar and tab sheet
///
/// Performance: every glass panel uses [BackdropFilter.grouped] under one
/// [BackdropGroup] (installed in MaterialApp.builder), so a screen full of
/// glass rows costs one backdrop read instead of one per row. Controls use
/// translucent colours only (no blur) – they are small and numerous.
class LiquidGlassConfig {
  final bool enabled;
  final double blur;
  final double frost;
  final double radius;
  final bool controls;
  final bool menus;
  final bool nav;
  final bool browser;
  const LiquidGlassConfig({
    this.enabled = false,
    this.blur = 18,
    this.frost = 0.45,
    this.radius = 20,
    this.controls = true,
    this.menus = true,
    this.nav = true,
    this.browser = true,
  });

  bool get onControls => enabled && controls;
  bool get onMenus => enabled && menus;
  bool get onNav => enabled && nav;
  bool get onBrowser => enabled && browser;
}

class LiquidGlassNotifier extends Notifier<LiquidGlassConfig> {
  @override
  LiquidGlassConfig build() {
    void listener() {
      final n = _read();
      if (!_same(n, state)) state = n;
    }

    YomiPrefs.changes.addListener(listener);
    ref.onDispose(() => YomiPrefs.changes.removeListener(listener));
    return _read();
  }

  static bool _same(LiquidGlassConfig a, LiquidGlassConfig b) =>
      a.enabled == b.enabled &&
      a.blur == b.blur &&
      a.frost == b.frost &&
      a.radius == b.radius &&
      a.controls == b.controls &&
      a.menus == b.menus &&
      a.nav == b.nav &&
      a.browser == b.browser;

  static LiquidGlassConfig _read() => LiquidGlassConfig(
    enabled: YomiPrefs.get<bool>('liquidGlass', false),
    blur: YomiPrefs.get<double>('liquidGlassBlur', 18),
    frost: YomiPrefs.get<double>('liquidGlassFrost', 0.45),
    radius: YomiPrefs.get<double>('liquidGlassRadius', 20),
    controls: true,
    menus: true,
    nav: true,
    browser: true,
  );

  Future<void> setEnabled(bool v) => YomiPrefs.set('liquidGlass', v);
  Future<void> setBlur(double v) => YomiPrefs.set('liquidGlassBlur', v);
  Future<void> setFrost(double v) => YomiPrefs.set('liquidGlassFrost', v);
  Future<void> setRadius(double v) => YomiPrefs.set('liquidGlassRadius', v);
}

final liquidGlassProvider =
    NotifierProvider<LiquidGlassNotifier, LiquidGlassConfig>(
      LiquidGlassNotifier.new,
    );

Color _rimColor(bool dark) => Colors.white.withValues(alpha: dark ? 0.18 : 0.6);

/// Theme part of Liquid Glass: translucent surfaces (menus area) and glass
/// controls (controls area).
ThemeData applyLiquidGlass(ThemeData t, LiquidGlassConfig cfg) {
  if (!cfg.enabled) return t;
  final dark = t.brightness == Brightness.dark;
  final cs = t.colorScheme;
  final a = (0.62 + cfg.frost * 0.30).clamp(0.5, 0.95);
  Color solid(Color c) => c.withValues(alpha: (a + 0.12).clamp(0.0, 0.97));
  Color glass(Color c) => c.withValues(alpha: a);
  final rim = BorderSide(color: _rimColor(dark), width: 1);
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(cfg.radius + 2),
    side: rim,
  );
  var out = t;

  if (cfg.menus) {
    out = out.copyWith(
      dialogTheme: out.dialogTheme.copyWith(
        backgroundColor: solid(cs.surfaceContainerHigh),
        shape: shape,
      ),
      bottomSheetTheme: out.bottomSheetTheme.copyWith(
        backgroundColor: glass(cs.surfaceContainerLow),
        modalBackgroundColor: glass(cs.surfaceContainerLow),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(cfg.radius + 6),
          ),
        ),
      ),
      popupMenuTheme: out.popupMenuTheme.copyWith(
        color: solid(cs.surfaceContainer),
        shape: shape,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(solid(cs.surfaceContainer)),
          shape: WidgetStatePropertyAll(shape),
        ),
      ),
      cardTheme: out.cardTheme.copyWith(
        color: glass(cs.surfaceContainerLow),
        shape: shape,
      ),
      appBarTheme: out.appBarTheme.copyWith(
        backgroundColor: glass(cs.surface),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  if (cfg.nav) {
    out = out.copyWith(
      navigationBarTheme: out.navigationBarTheme.copyWith(
        backgroundColor: glass(cs.surfaceContainer).withValues(alpha: a * 0.8),
        surfaceTintColor: Colors.transparent,
        indicatorColor: cs.primary.withValues(alpha: 0.22),
        indicatorShape: StadiumBorder(side: rim),
      ),
      navigationRailTheme: out.navigationRailTheme.copyWith(
        backgroundColor: glass(cs.surfaceContainer),
        indicatorColor: cs.primary.withValues(alpha: 0.22),
        indicatorShape: StadiumBorder(side: rim),
      ),
      tabBarTheme: out.tabBarTheme.copyWith(
        indicator: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(cfg.radius),
          border: Border.fromBorderSide(rim),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
    );
  }

  if (cfg.controls) {
    final glassFill = Colors.white.withValues(alpha: dark ? 0.10 : 0.45);
    final pressed = Colors.white.withValues(alpha: dark ? 0.18 : 0.6);
    final btnShape = WidgetStatePropertyAll<OutlinedBorder>(
      StadiumBorder(side: rim),
    );
    ButtonStyle glassBtn({required bool tinted}) => ButtonStyle(
      shape: btnShape,
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) {
          return glassFill.withValues(alpha: 0.05);
        }
        final base = tinted ? cs.primary.withValues(alpha: 0.55) : glassFill;
        return s.contains(WidgetState.pressed)
            ? Color.alphaBlend(pressed, base)
            : base;
      }),
      side: WidgetStatePropertyAll(rim),
    );
    out = out.copyWith(
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Colors.white
              : Colors.white.withValues(alpha: dark ? 0.75 : 0.95),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? cs.primary.withValues(alpha: 0.65)
              : glassFill,
        ),
        trackOutlineColor: WidgetStatePropertyAll(_rimColor(dark)),
        thumbIcon: const WidgetStatePropertyAll(null),
      ),
      sliderTheme: out.sliderTheme.copyWith(
        trackHeight: 6,
        activeTrackColor: cs.primary.withValues(alpha: 0.7),
        inactiveTrackColor: glassFill,
        thumbColor: Colors.white,
        overlayColor: Colors.white.withValues(alpha: 0.15),
        valueIndicatorColor: solid(cs.surfaceContainerHighest),
        valueIndicatorTextStyle: TextStyle(color: cs.onSurface),
      ),
      checkboxTheme: out.checkboxTheme.copyWith(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? cs.primary.withValues(alpha: 0.7)
              : glassFill,
        ),
        side: rim,
      ),
      radioTheme: out.radioTheme.copyWith(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? cs.primary : _rimColor(dark),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: glassBtn(tinted: true).merge(out.filledButtonTheme.style),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: glassBtn(tinted: false).merge(out.elevatedButtonTheme.style),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: glassBtn(tinted: false).merge(out.outlinedButtonTheme.style),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(rim),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? cs.primary.withValues(alpha: 0.35)
                : glassFill,
          ),
        ),
      ),
      chipTheme: out.chipTheme.copyWith(
        backgroundColor: glassFill,
        selectedColor: cs.primary.withValues(alpha: 0.35),
        side: rim,
        shape: StadiumBorder(side: rim),
      ),
      floatingActionButtonTheme: out.floatingActionButtonTheme.copyWith(
        backgroundColor: cs.primaryContainer.withValues(alpha: 0.8),
        elevation: 0,
        shape: StadiumBorder(side: rim),
      ),
    );
  }
  return out;
}

/// Shared blur group for every glass panel (installed once at app root).
class LiquidGlassScope extends StatelessWidget {
  final Widget child;
  const LiquidGlassScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      _grouped ? BackdropGroup(child: child) : child;
}

/// Shared backdrop groups only on phones: on Windows (Impeller GLES SDF)
/// a root BackdropGroup stopped the window from ever painting.
final bool _grouped = Platform.isAndroid || Platform.isIOS;

Widget _backdrop({required ImageFilter filter, required Widget child}) =>
    _grouped
        ? BackdropFilter.grouped(filter: filter, child: child)
        : BackdropFilter(filter: filter, child: child);

/// YomiHub 0.2.1: blur cost grows with sigma and with the number of glass
/// panels on screen. Phones with ≤4 cores (typical 2-3 GB devices) and the
/// ungrouped desktop path get a capped sigma – the look stays the same, the
/// frame time drops (reports of lag with Liquid Glass on).
final bool _lowEnd = (Platform.isAndroid && Platform.numberOfProcessors <= 4);

double _sigma(LiquidGlassConfig cfg, {bool panel = false}) {
  var s = cfg.blur;
  if (_lowEnd) s = s.clamp(0, 8).toDouble();
  // 0.2.2: lowered for the session when the GPU is overloaded
  if (YomiPerf.reduceEffects) s = s.clamp(0, 4).toDouble();
  if (panel && !_grouped) s = (s * 0.6).clamp(0, 12).toDouble();
  return s;
}

/// A frosted glass panel (settings rows, More menu rows, extension sheet…).
class LiquidGlassPanel extends ConsumerWidget {
  final Widget child;
  final double? radius;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  /// Show the glass even when the menus area is off (previews).
  final bool force;
  const LiquidGlassPanel({
    super.key,
    required this.child,
    this.radius,
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    this.padding = EdgeInsets.zero,
    this.force = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(liquidGlassProvider);
    if (!cfg.onMenus && !force) return child;
    return Padding(
      padding: margin,
      child: LiquidGlassSurface(
        cfg: cfg,
        radius: radius ?? cfg.radius - 2,
        child: Padding(
          padding: padding,
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    );
  }
}

/// The glass material itself; used by panels, the nav bar and the browser.
class LiquidGlassSurface extends StatelessWidget {
  final LiquidGlassConfig cfg;
  final double radius;
  final Widget child;
  final BorderRadius? borderRadius;
  const LiquidGlassSurface({
    super.key,
    required this.cfg,
    required this.child,
    this.radius = 18,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? BorderRadius.circular(radius);
    final k = 0.5 + cfg.frost;
    final sg = _sigma(cfg, panel: true);
    return RepaintBoundary(child: ClipRRect(
      borderRadius: r,
      child: _backdrop(
        filter: ImageFilter.blur(sigmaX: sg, sigmaY: sg),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: r,
            border: Border.all(color: _rimColor(dark)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: (dark ? 0.10 : 0.55) * k),
                Colors.white.withValues(alpha: (dark ? 0.03 : 0.22) * k),
              ],
            ),
          ),
          child: DecoratedBox(
            // specular highlight along the top edge, painted without an
            // extra Stack/Positioned layer.
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: const Alignment(0, -0.55),
                colors: [
                  Colors.white.withValues(alpha: dark ? 0.10 : 0.30),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    ));
  }
}

/// Glass behind a bottom navigation bar / app bar (no rounded corners).
class LiquidGlassBar extends ConsumerWidget {
  final Widget child;

  /// 'nav', 'rail' (desktop side bar, 0.2.1) or 'browser' – which area
  /// switch controls it.
  final String area;
  const LiquidGlassBar({super.key, required this.child, this.area = 'nav'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(liquidGlassProvider);
    final on = area == 'browser' ? cfg.onBrowser : cfg.onNav;
    if (!on) return child;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sg = _sigma(cfg);
    return RepaintBoundary(child: ClipRect(
      child: _backdrop(
        filter: ImageFilter.blur(sigmaX: sg, sigmaY: sg),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              right: area == 'rail'
                  ? BorderSide(color: _rimColor(dark))
                  : BorderSide.none,
              top: area == 'nav'
                  ? BorderSide(color: _rimColor(dark))
                  : BorderSide.none,
              bottom: area == 'browser'
                  ? BorderSide(color: _rimColor(dark))
                  : BorderSide.none,
            ),
          ),
          child: child,
        ),
      ),
    ));
  }
}

/// Soft colour field behind a glass screen so the blur has something to
/// refract. Static (no animation) to stay cheap on old phones.
class LiquidGlassBackdrop extends ConsumerWidget {
  final Widget child;
  const LiquidGlassBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(liquidGlassProvider).onMenus) return child;
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final o = dark ? 0.32 : 0.22;
    Widget blob(Alignment a, Color c, double size) => Align(
      alignment: a,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [c.withValues(alpha: o), c.withValues(alpha: 0)],
          ),
        ),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                blob(const Alignment(-1.1, -0.9), cs.primary, 420),
                blob(const Alignment(1.2, -0.2), cs.tertiary, 380),
                blob(const Alignment(-0.6, 1.1), cs.secondary, 460),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Settings: one application-wide switch and shared appearance sliders.
class LiquidGlassSettings extends ConsumerWidget {
  const LiquidGlassSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(liquidGlassProvider);
    final n = ref.read(liquidGlassProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.blur_on),
          title: const Text('Liquid Glass'),
          subtitle: Text(tr('Hiệu ứng kính mờ cho toàn bộ giao diện')),
          value: cfg.enabled,
          onChanged: n.setEnabled,
        ),
        if (cfg.enabled) ...[
          ListTile(
            title: Text(tr('Độ mờ nền: {p0}', {'p0': cfg.blur.round()})),
            subtitle: Slider(
              min: 6,
              max: 30,
              divisions: 12,
              value: cfg.blur.clamp(6, 30),
              label: cfg.blur.round().toString(),
              onChanged: n.setBlur,
            ),
          ),
          ListTile(
            title: Text(tr('Độ trong / đục của kính')),
            subtitle: Slider(
              min: 0,
              max: 1,
              divisions: 10,
              value: cfg.frost.clamp(0, 1),
              onChanged: n.setFrost,
            ),
          ),
          ListTile(
            title: Text(tr('Bo góc: {p0}', {'p0': cfg.radius.round()})),
            subtitle: Slider(
              min: 8,
              max: 32,
              divisions: 12,
              value: cfg.radius.clamp(8, 32),
              onChanged: n.setRadius,
            ),
          ),
          LiquidGlassPanel(
            force: true,
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(child: Text(tr('Xem trước'))),
                Switch(value: true, onChanged: (_) {}),
                const SizedBox(width: 8),
                FilledButton(onPressed: () {}, child: Text(tr('Nút'))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
