import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/app_identity.dart';

/// YomiHub 0.1.5: loading screen with the app logo.
///
/// The native splash (Android launch theme / Android 12 SplashScreen) covers
/// the engine start; this widget continues it inside Flutter while the
/// library, extensions and VPN state finish loading, then fades away. It is
/// shown once per process (not again after a hot restart of the router).
class YomiSplash extends StatefulWidget {
  final Widget child;
  const YomiSplash({super.key, required this.child});

  static bool _shown = false;

  /// Lets slow start-up work keep the splash up a little longer (capped).
  static final ready = Completer<void>();
  static void markReady() {
    if (!ready.isCompleted) ready.complete();
  }

  @override
  State<YomiSplash> createState() => _YomiSplashState();
}

class _YomiSplashState extends State<YomiSplash>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF10142A);
  late final AnimationController _c;
  bool _visible = !YomiSplash._shown;
  bool _removed = YomiSplash._shown;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    if (!_removed) {
      YomiSplash._shown = true;
      _hideLater();
    }
  }

  Future<void> _hideLater() async {
    final minShow = Future<void>.delayed(const Duration(milliseconds: 900));
    // Wait for the app to report ready, but never longer than 3 s.
    await Future.any([
      Future.wait([minShow, YomiSplash.ready.future]),
      Future<void>.delayed(const Duration(seconds: 3)),
    ]);
    if (!mounted) return;
    setState(() => _visible = false);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    _c.stop();
    setState(() => _removed = true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_removed) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          ignoring: !_visible,
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            child: Material(
              color: _bg,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _c,
                      builder: (context, child) {
                        // gentle "breathing" of the logo
                        final t = (_c.value * 2 - 1).abs();
                        return Transform.scale(
                          scale: 0.96 + 0.04 * (1 - t),
                          child: child,
                        );
                      },
                      child: Image.asset(
                        'assets/app_icons/yomihub_splash.png',
                        width: 132,
                        height: 132,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      AppIdentity.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Comic · Film & Movie · Novel',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 140,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF4FA3FF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
