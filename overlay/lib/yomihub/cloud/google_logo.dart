// YomiHub 0.6.0 – Google "G" mark for "Sao lưu lên Google Drive" / sign in
// with Google (sheet YomiHub Update: the icon of this setting is the Google
// logo image linked in the sheet). The linked file (vecteezy) refuses
// automated downloads, so the same four-colour "G" is drawn as a vector:
// sharp at any size and no extra asset in the APK.
import 'dart:math' as math;

import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: GoogleLogoPainter()),
      );
}

class GoogleLogoPainter extends CustomPainter {
  static const blue = Color(0xFF4285F4);
  static const red = Color(0xFFEA4335);
  static const yellow = Color(0xFFFBBC05);
  static const green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    final stroke = s * 0.2;
    final r = (s - stroke) / 2;
    final c = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: c, radius: r);
    Paint p(Color col) => Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    double deg(double d) => d * math.pi / 180;
    // Arcs clockwise from 3 o'clock: blue (-10°..45°), green (45..135),
    // yellow (135..200), red (200..315). The gap at the top-right is the "G".
    canvas.drawArc(rect, deg(-12), deg(57), false, p(blue));
    canvas.drawArc(rect, deg(45), deg(90), false, p(green));
    canvas.drawArc(rect, deg(135), deg(65), false, p(yellow));
    canvas.drawArc(rect, deg(200), deg(115), false, p(red));
    // Crossbar of the G.
    final bar = Paint()..color = blue;
    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - stroke / 2, r + stroke / 2, stroke),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
