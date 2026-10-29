import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:mangayomi/utils/platform_utils.dart';
import 'package:mangayomi/yomihub/app_identity.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

/// YomiHub 0.1.8: redesigned loading screen, still exactly 5 seconds.
/// 0.1.9: the logo morphs from the square app icon into a round logo.
///
/// Timeline (one controller, 5 000 ms, nothing waits on anything else):
///  0.00–0.16  aurora background fades in, logo pops from the native splash
///             size inside a glass disc
///  0.12–0.40  three category badges (Comic, Film & Movie, Novel) fly out
///             and settle into an orbit around the logo
///  0.22–0.42  name appears with a light sweep, tagline under it
///  0.30–0.90  progress bar fills (status follows start-up)
///  0.90–1.00  exit: a circle opens from the logo and reveals the app
///
/// Everything is painted by two CustomPainters and a handful of transforms
/// under one RepaintBoundary, so the animation costs little on old phones
/// and the app keeps loading underneath at full speed.
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
  static const _bg = Color(0xFF0B1024);
  static const _c1 = Color(0xFF4FA3FF); // blue
  static const _c2 = Color(0xFFB36BFF); // violet
  static const _c3 = Color(0xFFFF6B9A); // pink
  late final AnimationController _c;
  bool _removed = YomiSplash._shown;

  @override
  void initState() {
    super.initState();
    // preserve: keep the full 5 s even when the system "remove animations"
    // setting is on.
    _c = AnimationController(
      vsync: this,
      duration: YomiSplash.total,
      animationBehavior: AnimationBehavior.preserve,
    );
    if (!_removed) {
      YomiSplash._shown = true;
      _c.forward().whenComplete(() {
        if (mounted) setState(() => _removed = true);
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static double _seg(double t, double a, double b, [Curve c = Curves.linear]) =>
      c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  String _status(double p) {
    if (YomiSplash.ready.isCompleted && p > 0.75) return tr('Sẵn sàng');
    if (p < 0.3) return tr('Đang khởi động…');
    if (p < 0.55) return tr('Đang tải thư viện…');
    if (p < 0.8) return tr('Đang nạp tiện ích…');
    return tr('Đang chuẩn bị giao diện…');
  }

  @override
  Widget build(BuildContext context) {
    if (_removed) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value;
              final intro = _seg(t, 0.0, 0.16, Curves.easeOutBack);
              final orbitIn = _seg(t, 0.12, 0.40, Curves.easeOutCubic);
              final text = _seg(t, 0.22, 0.42, Curves.easeOut);
              final prog = _seg(t, 0.30, 0.90, Curves.easeInOut);
              final exit = _seg(t, 0.90, 1.0, Curves.easeInCubic);
              final size = MediaQuery.sizeOf(context);
              // starts where the native launch logo is (screen centre), then glides up
              final lift = _seg(t, 0.10, 0.30, Curves.easeInOutCubic);
              final center = Offset(size.width / 2, size.height * (0.5 - 0.09 * lift));
              final maxR = math.sqrt(size.width * size.width + size.height * size.height);
              return IgnorePointer(
                ignoring: exit > 0.5,
                child: ClipPath(
                  // exit: a hole opens from the logo outwards
                  clipper: _HoleClipper(center, exit * maxR),
                  child: Material(
                    color: _bg,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _AuroraPainter(t, intro, [_c1, _c2, _c3]),
                          ),
                        ),
                        // orbit + logo
                        Positioned(
                          left: center.dx - 120,
                          top: center.dy - 120,
                          width: 240,
                          height: 240,
                          child: CustomPaint(
                            painter: _OrbitPainter(t, orbitIn, [_c1, _c2, _c3]),
                            child: Center(
                              child: Transform.scale(
                                scale: (0.6 + 0.4 * intro) * (1 + 0.25 * exit),
                                child: _logo(t),
                              ),
                            ),
                          ),
                        ),
                        if (isTv)
                          _badge(1, t, orbitIn, center)
                        else
                          for (var i = 0; i < 3; i++) _badge(i, t, orbitIn, center),
                        // name, tagline, progress
                        Positioned(
                          left: 0,
                          right: 0,
                          top: center.dy + 128 + 18 * (1 - text),
                          child: Opacity(
                            opacity: text * (1 - exit),
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (r) => LinearGradient(
                                    colors: const [Colors.white, _c1, Colors.white, Colors.white],
                                    stops: [
                                      0,
                                      (t * 1.6 - 0.35).clamp(0.0, 1.0),
                                      (t * 1.6 - 0.2).clamp(0.0, 1.0),
                                      1,
                                    ],
                                  ).createShader(r),
                                  child: Text(
                                    AppIdentity.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  // Section names in app language (TV shows only Film & Movie)
                                  isTv
                                      ? YomiTr.term(1)
                                      : '${YomiTr.term(0)} · ${YomiTr.term(1)} · ${YomiTr.term(2)}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13,
                                    letterSpacing: 0.4,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                _progress(prog),
                                const SizedBox(height: 10),
                                Text(
                                  _status(prog),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontSize: 11.5,
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
        ),
      ],
    );
  }

  /// YomiHub 0.4.3 (Feature Check 25): the app logo itself morphs from the
  /// rounded-square app icon into a round logo (one clip whose radius grows
  /// to half the size), and is decoded before the first frame so it is
  /// visible from the start (0.4.2 showed an empty blue disc for ~1 s while
  /// the PNG was still decoding).
  static const _logoImg = ResizeImage(
    AssetImage('assets/app_icons/yomihub_splash.png'),
    width: 384,
  );
  bool _logoCached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_logoCached) {
      _logoCached = true;
      precacheImage(_logoImg, context).catchError((_) {});
    }
  }

  Widget _logo(double t) {
    final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 4);
    final morph = _seg(t, 0.05, 0.35, Curves.easeInOutCubic);
    const size = 132.0;
    // 0.22 × size ≈ the icon's own corner radius → 0.5 × size = full circle
    final r = size * (0.22 + 0.28 * morph);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        boxShadow: [
          BoxShadow(
            color: _c1.withValues(alpha: 0.35 + 0.15 * pulse),
            blurRadius: 24, // static radius: no GPU repaint storm
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Transform.scale(
          // crops the icon's white rim while it becomes round
          scale: 1.0 + 0.14 * morph,
          child: const Image(
            image: _logoImg,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }

  static const _icons = [
    Icons.menu_book_rounded,
    Icons.movie_filter_rounded,
    Icons.auto_stories_rounded,
  ];
  static List<String> get _labels => [YomiTr.term(0), YomiTr.term(1), YomiTr.term(2)];

  Widget _badge(int i, double t, double orbitIn, Offset center) {
    final colors = [_c1, _c2, _c3];
    // three evenly spaced badges turning slowly around the logo
    final a = -math.pi / 2 + i * 2 * math.pi / 3 + t * math.pi * 0.9;
    final r = 108.0 * orbitIn;
    final p = center + Offset(math.cos(a) * r, math.sin(a) * r * 0.92);
    final o = _seg(t, 0.12 + i * 0.05, 0.30 + i * 0.05);
    return Positioned(
      left: p.dx - 22,
      top: p.dy - 22,
      child: Opacity(
        opacity: o * (1 - _seg(t, 0.9, 1.0)),
        child: Semantics(
          label: _labels[i],
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors[i].withValues(alpha: 0.85),
              border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
              boxShadow: [BoxShadow(color: colors[i].withValues(alpha: 0.6), blurRadius: 16)],
            ),
            child: Icon(_icons[i], color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _progress(double p) {
    return SizedBox(
      width: 190,
      height: 6,
      child: CustomPaint(painter: _BarPainter(p, [_c1, _c2, _c3])),
    );
  }
}

class _HoleClipper extends CustomClipper<Path> {
  final Offset c;
  final double r;
  _HoleClipper(this.c, this.r);
  @override
  Path getClip(Size size) {
    final p = Path()..addRect(Offset.zero & size);
    if (r <= 0) return p;
    return Path.combine(
      PathOperation.difference,
      p,
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldReclip(_HoleClipper o) => o.r != r || o.c != c;
}

/// Moving colour fields + drifting sparkles.
class _AuroraPainter extends CustomPainter {
  final double t;
  final double a;
  final List<Color> colors;
  _AuroraPainter(this.t, this.a, this.colors);

  static final _stars = List.generate(46, (i) {
    final r = math.Random(i * 7919);
    return (r.nextDouble(), r.nextDouble(), 0.6 + r.nextDouble() * 1.8, r.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    for (var i = 0; i < 3; i++) {
      final ph = t * math.pi * 2 * (0.35 + i * 0.12) + i * 2.1;
      final c = Offset(
        w * (0.5 + 0.38 * math.cos(ph)),
        h * (0.38 + 0.28 * math.sin(ph * 1.3)),
      );
      final rad = math.max(w, h) * (0.55 + 0.08 * i);
      canvas.drawCircle(
        c,
        rad,
        Paint()
          ..shader = RadialGradient(
            colors: [
              colors[i].withValues(alpha: 0.30 * a),
              colors[i].withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: rad)),
      );
    }
    final star = Paint();
    for (final st in _stars) {
      final y = (st.$2 - t * 0.12 * (0.5 + st.$4)) % 1.0;
      final tw = 0.35 + 0.65 * (0.5 + 0.5 * math.sin((t * 8 + st.$4 * 6) * math.pi));
      star.color = Colors.white.withValues(alpha: 0.55 * tw * a);
      canvas.drawCircle(Offset(st.$1 * w, y * h), st.$3, star);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter o) => o.t != t || o.a != a;
}

/// Orbit ring and a light sweeping around it.
class _OrbitPainter extends CustomPainter {
  final double t;
  final double k;
  final List<Color> colors;
  _OrbitPainter(this.t, this.k, this.colors);

  @override
  void paint(Canvas canvas, Size s) {
    if (k <= 0) return;
    final c = s.center(Offset.zero);
    final rect = Rect.fromCenter(center: c, width: 216 * k, height: 216 * 0.92 * k);
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.18 * k),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2 + t * math.pi * 4,
      math.pi * 0.8,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [colors[0].withValues(alpha: 0), colors[1], colors[2]],
          transform: GradientRotation(-math.pi / 2 + t * math.pi * 4),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter o) => o.t != t || o.k != k;
}

class _BarPainter extends CustomPainter {
  final double p;
  final List<Color> colors;
  _BarPainter(this.p, this.colors);

  @override
  void paint(Canvas canvas, Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(s.height / 2));
    canvas.drawRRect(r, Paint()..color = Colors.white.withValues(alpha: 0.12));
    if (p <= 0) return;
    final fill = Rect.fromLTWH(0, 0, s.width * p, s.height);
    final paint = Paint()
      ..shader = LinearGradient(colors: colors).createShader(Offset.zero & s);
    canvas.drawRRect(
      RRect.fromRectAndRadius(fill, Radius.circular(s.height / 2)),
      paint,
    );
    // glowing head
    canvas.drawCircle(
      Offset(s.width * p, s.height / 2),
      s.height * 1.2,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(_BarPainter o) => o.p != p;
}
