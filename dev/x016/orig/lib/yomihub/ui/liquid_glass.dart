import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

/// YomiHub 0.1.5: "Liquid Glass" look for menus, settings and extension
/// screens (Settings › Giao diện › Liquid Glass).
///
/// Re-implemented in Flutter after the CSS/React projects listed in the
/// GitHub sheet (liquid-glass, liquid-glass-react, liquid-glass-js): a
/// frosted backdrop blur, a translucent tint, a thin bright rim and a soft
/// specular highlight along the top edge. Nothing is copied from those
/// projects – they are web components; this is a native widget.
class LiquidGlassConfig {
  final bool enabled;

  /// Backdrop blur sigma (6–30).
  final double blur;

  /// 0 = clear glass, 1 = milky glass.
  final double frost;
  const LiquidGlassConfig({
    this.enabled = false,
    this.blur = 18,
    this.frost = 0.45,
  });
}

class LiquidGlassNotifier extends Notifier<LiquidGlassConfig> {
  @override
  LiquidGlassConfig build() {
    void listener() => state = _read();
    YomiPrefs.changes.addListener(listener);
    ref.onDispose(() => YomiPrefs.changes.removeListener(listener));
    return _read();
  }

  static LiquidGlassConfig _read() => LiquidGlassConfig(
    enabled: YomiPrefs.get<bool>('liquidGlass', false),
    blur: YomiPrefs.get<double>('liquidGlassBlur', 18),
    frost: YomiPrefs.get<double>('liquidGlassFrost', 0.45),
  );

  Future<void> setEnabled(bool v) => YomiPrefs.set('liquidGlass', v);
  Future<void> setBlur(double v) => YomiPrefs.set('liquidGlassBlur', v);
  Future<void> setFrost(double v) => YomiPrefs.set('liquidGlassFrost', v);
}

final liquidGlassProvider =
    NotifierProvider<LiquidGlassNotifier, LiquidGlassConfig>(
      LiquidGlassNotifier.new,
    );

/// Translucent surfaces for dialogs, sheets, menus, cards and the nav bar so
/// the blurred backdrop shows through.
ThemeData applyLiquidGlass(ThemeData t, LiquidGlassConfig cfg) {
  if (!cfg.enabled) return t;
  final dark = t.brightness == Brightness.dark;
  final a = (0.62 + cfg.frost * 0.30).clamp(0.5, 0.95);
  // menus / dialogs carry text over busy content: keep them more opaque
  Color solid(Color c) => c.withValues(alpha: (a + 0.12).clamp(0.0, 0.97));
  Color glass(Color c) => c.withValues(alpha: a);
  final rim = BorderSide(
    color: (dark ? Colors.white : Colors.white).withValues(
      alpha: dark ? 0.16 : 0.55,
    ),
    width: 1,
  );
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(22),
    side: rim,
  );
  final cs = t.colorScheme;
  return t.copyWith(
    dialogTheme: t.dialogTheme.copyWith(
      backgroundColor: solid(cs.surfaceContainerHigh),
      shape: shape,
    ),
    bottomSheetTheme: t.bottomSheetTheme.copyWith(
      backgroundColor: glass(cs.surfaceContainerLow),
      modalBackgroundColor: glass(cs.surfaceContainerLow),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
    ),
    popupMenuTheme: t.popupMenuTheme.copyWith(
      color: solid(cs.surfaceContainer),
      shape: shape,
    ),
    cardTheme: t.cardTheme.copyWith(
      color: glass(cs.surfaceContainerLow),
      shape: shape,
    ),
    navigationBarTheme: t.navigationBarTheme.copyWith(
      backgroundColor: glass(cs.surfaceContainer),
    ),
    navigationRailTheme: t.navigationRailTheme.copyWith(
      backgroundColor: glass(cs.surfaceContainer),
    ),
    appBarTheme: t.appBarTheme.copyWith(
      backgroundColor: glass(cs.surface),
      surfaceTintColor: Colors.transparent,
    ),
  );
}

/// A frosted glass panel.
class LiquidGlassPanel extends ConsumerWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  /// When false the child is returned unchanged unless Liquid Glass is on.
  final bool force;
  const LiquidGlassPanel({
    super.key,
    required this.child,
    this.radius = 18,
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    this.padding = EdgeInsets.zero,
    this.force = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(liquidGlassProvider);
    if (!cfg.enabled && !force) return child;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = dark ? Colors.white : Colors.white;
    final r = BorderRadius.circular(radius);
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: cfg.blur, sigmaY: cfg.blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: r,
              border: Border.all(
                color: tint.withValues(alpha: dark ? 0.14 : 0.6),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withValues(alpha: (dark ? 0.10 : 0.55) * (0.5 + cfg.frost)),
                  tint.withValues(alpha: (dark ? 0.03 : 0.22) * (0.5 + cfg.frost)),
                ],
              ),
            ),
            child: Stack(
              children: [
                // specular highlight along the top edge
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 18,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            tint.withValues(alpha: dark ? 0.12 : 0.35),
                            tint.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: padding,
                  child: Material(type: MaterialType.transparency, child: child),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft colour field behind a glass screen so the blur has something to
/// refract. Static (no animation) to stay cheap on old phones.
class LiquidGlassBackdrop extends ConsumerWidget {
  final Widget child;
  const LiquidGlassBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(liquidGlassProvider).enabled) return child;
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

/// Settings › Giao diện: switch + intensity sliders.
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
          subtitle: const Text(
            'Hiệu ứng kính mờ cho menu, cài đặt, hộp thoại, thanh điều hướng và màn hình tiện ích',
          ),
          value: cfg.enabled,
          onChanged: n.setEnabled,
        ),
        if (cfg.enabled) ...[
          ListTile(
            title: const Text('Độ mờ nền'),
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
            title: const Text('Độ trong / đục của kính'),
            subtitle: Slider(
              min: 0,
              max: 1,
              divisions: 10,
              value: cfg.frost.clamp(0, 1),
              onChanged: n.setFrost,
            ),
          ),
          const LiquidGlassPanel(
            margin: EdgeInsets.fromLTRB(16, 4, 16, 12),
            padding: EdgeInsets.all(14),
            child: Text('Xem trước: bảng kính Liquid Glass'),
          ),
        ],
      ],
    );
  }
}
