import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/app_identity.dart';

/// YomiHub 0.1.6: animated loading screen (5 s).
///
/// Timeline (one controller, 5 000 ms):
///  0.00–0.18  logo grows in from the native splash size (same position, so
///             the hand-off from the Android launch theme is seamless)
///  0.18–0.34  logo glides up, ring of light sweeps around it,
///             name + tagline slide/fade in under it
///  0.34–0.92  progress bar fills; status text follows real start-up work
///  0.92–1.00  exit: logo zooms through and the whole layer fades out,
///             revealing the app underneath
/// The app keeps loading underneath during all of this, so the extra time
/// costs nothing; if start-up work is still running at the end the splash
/// waits for it (max +3 s).
class YomiSplash extends StatefulWidget {
  final Widget child;
  const YomiSplash({super.key, required this.child});

  static bool _shown = false;
  static const total = Duration(milliseconds: 5000);

  static final ready = Completer<void>();
  static void markReady() {
    if (!ready.isCompleted) ready.complete();
  }

  @override
  State<YomiSplash> createState() => _YomiSplashState();
}

class _YomiSplashState extends State<YomiSplash> with TickerProviderStateMixin {
  static const _bg = Color(0xFF10142A);
  static const _accent = Color(0xFF4FA3FF);
  late final AnimationController _c;
  bool _removed = YomiSplash._shown;

  @override
  void initState() {
    super.initState();
    // preserve: keep the full 5 s even when the system "remove animations"
    // setting is on (Flutter would otherwise shorten it to ~0.25 s).
    _c = AnimationController(
      vsync: this,
      duration: YomiSplash.total,
      animationBehavior: AnimationBehavior.preserve,
    );
    if (!_removed) {
      YomiSplash._shown = true;
      _run();
    }
  }

  Future<void> _run() async {
    // Play up to the exit phase, wait for start-up work, then play the exit.
    await _c.animateTo(0.92, duration: YomiSplash.total * 0.92);
    await Future.any([
      YomiSplash.ready.future,
      Future<void>.delayed(const Duration(seconds: 3)),
    ]);
    if (!mounted) return;
    await _c.animateTo(1.0, duration: YomiSplash.total * 0.08);
    if (!mounted) return;
    setState(() => _removed = true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static double _seg(double t, double a, double b, [Curve c = Curves.linear]) =>
      c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  String _status(double p) {
    if (YomiSplash.ready.isCompleted && p > 0.8) return 'Sẵn sàng';
    if (p < 0.35) return 'Đang khởi động…';
    if (p < 0.6) return 'Đang tải thư viện…';
    if (p < 0.8) return 'Đang nạp tiện ích…';
    return 'Đang chuẩn bị giao diện…';
  }

  @override
  Widget build(BuildContext context) {
    if (_removed) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final grow = _seg(t, 0.0, 0.18, Curves.easeOutBack);
            final lift = _seg(t, 0.18, 0.34, Curves.easeInOutCubic);
            final text = _seg(t, 0.22, 0.38, Curves.easeOut);
            final prog = _seg(t, 0.34, 0.92, Curves.easeInOut);
            final exit = _seg(t, 0.92, 1.0, Curves.easeInCubic);
            final ring = _seg(t, 0.16, 0.40);
            final size = MediaQuery.sizeOf(context);
            return IgnorePointer(
              ignoring: exit > 0.6,
              child: Opacity(
                opacity: 1 - exit,
                child: Material(
                  color: _bg,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // soft glow behind the logo
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(0, -0.18 * lift),
                              radius: 0.6 + 0.3 * prog,
                              colors: [
                                _accent.withValues(alpha: 0.18 * grow),
                                _bg.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, -size.height * 0.07 * lift),
                        child: Transform.scale(
                          scale: (0.72 + 0.28 * grow) * (1 + 1.6 * exit),
                          child: SizedBox(
                            width: 150,
                            height: 150,
                            child: CustomPaint(
                              painter: _RingPainter(ring, _accent),
                              child: Padding(
                                padding: const EdgeInsets.all(9),
                                child: Image.asset(
                                  'assets/app_icons/yomihub_splash.png',
                                  filterQuality: FilterQuality.medium,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, size.height * 0.08 + 24 * (1 - text)),
                        child: Opacity(
                          opacity: text * (1 - exit),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                AppIdentity.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
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
                              const SizedBox(height: 26),
                              SizedBox(
                                width: 160,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: prog,
                                    minHeight: 3,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.12),
                                    valueColor:
                                        const AlwaysStoppedAnimation(_accent),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _status(prog),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// A light arc that sweeps once around the logo.
class _RingPainter extends CustomPainter {
  final double t;
  final Color color;
  _RingPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final r = Offset.zero & size;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        transform: GradientRotation(-math.pi / 2 + t * math.pi * 2),
        colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.9 * (1 - t))],
      ).createShader(r);
    canvas.drawArc(r.deflate(2), -math.pi / 2, math.pi * 2 * t, false, p);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.t != t;
}
