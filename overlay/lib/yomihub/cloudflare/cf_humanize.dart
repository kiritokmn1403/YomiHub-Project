import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// YomiHub 0.1.8: "humanize" for Cloudflare Turnstile, ported from
/// CloakBrowser's human layer (human/mouse.py: Bézier paths with jitter,
/// eased speed, overshoot; human/actionability.py: wait until the element is
/// visible and stable before clicking).
///
/// The events go through Flutter's own pointer pipeline into the WebView
/// (Android: real MotionEvents, Windows: WebView2 mouse input), so the page
/// receives trusted input exactly as if the user had clicked, unlike a
/// JavaScript `click()`.
class CfHumanize {
  static final _rnd = Random();
  static int _pointer = 7000;

  /// Where the Turnstile checkbox is, in CSS pixels of the page, or null.
  static const _findScript = r"""
(() => {
  const f = document.querySelector('iframe[src*="challenges.cloudflare.com"], iframe[title*="Cloudflare"], iframe[id^="cf-chl-widget"]');
  const box = f || document.querySelector('.cf-turnstile, #turnstile-wrapper, #challenge-stage, [data-sitekey]');
  if (!box) return null;
  const r = box.getBoundingClientRect();
  if (r.width < 30 || r.height < 30) return null;
  const st = getComputedStyle(box);
  if (st.visibility === 'hidden' || st.display === 'none' || st.opacity === '0') return null;
  return JSON.stringify({ x: r.left, y: r.top, w: r.width, h: r.height, vw: window.innerWidth, vh: window.innerHeight });
})()
""";

  /// Finds the checkbox and clicks it like a person. [webKey] is the key of
  /// the InAppWebView widget (for its position on screen).
  static Future<bool> clickTurnstile(InAppWebViewController c, GlobalKey webKey) async {
    String? raw;
    try {
      raw = (await c.evaluateJavascript(source: _findScript))?.toString();
    } catch (_) {
      return false;
    }
    if (raw == null || raw == 'null' || raw.isEmpty) return false;
    final m = RegExp(r'"(\w+)":(-?[\d.]+)').allMatches(raw);
    final v = {for (final e in m) e.group(1)!: double.parse(e.group(2)!)};
    final box = webKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || (v['vw'] ?? 0) <= 0) return false;
    final scale = box.size.width / v['vw']!;
    // the checkbox sits at the left of the widget, vertically centred
    final cssX = v['x']! + min(30.0, v['w']! * 0.12) + _rnd.nextDouble() * 6 - 3;
    final cssY = v['y']! + v['h']! / 2 + _rnd.nextDouble() * 6 - 3;
    final target = box.localToGlobal(Offset(cssX * scale, cssY * scale));
    // actionability: the box must not move between two reads
    await Future.delayed(Duration(milliseconds: 350 + _rnd.nextInt(400)));
    await _move(target, box);
    await _click(target);
    return true;
  }

  /// Bézier path from a random point of the view to [to], eased, with jitter.
  static Future<void> _move(Offset to, RenderBox box) async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return; // touch: no hover
    final origin = box.localToGlobal(Offset.zero);
    final from = origin +
        Offset(box.size.width * (0.3 + _rnd.nextDouble() * 0.5), box.size.height * (0.5 + _rnd.nextDouble() * 0.4));
    final c1 = from + Offset((to.dx - from.dx) * 0.3 + _rnd.nextDouble() * 80 - 40, (to.dy - from.dy) * 0.1 - 30);
    final c2 = from + Offset((to.dx - from.dx) * 0.8 + _rnd.nextDouble() * 40 - 20, (to.dy - from.dy) * 0.9 + 20);
    final steps = 18 + _rnd.nextInt(14);
    for (var i = 1; i <= steps; i++) {
      // ease in-out
      final t0 = i / steps;
      final t = t0 < 0.5 ? 2 * t0 * t0 : 1 - pow(-2 * t0 + 2, 2) / 2;
      final p = _bezier(from, c1, c2, to, t.toDouble()) + Offset(_rnd.nextDouble() - 0.5, _rnd.nextDouble() - 0.5);
      GestureBinding.instance.handlePointerEvent(
        PointerHoverEvent(position: p, kind: PointerDeviceKind.mouse, device: 1),
      );
      await Future.delayed(Duration(milliseconds: 8 + _rnd.nextInt(14)));
    }
  }

  static Offset _bezier(Offset a, Offset b, Offset c, Offset d, double t) {
    final u = 1 - t;
    return a * (u * u * u) + b * (3 * u * u * t) + c * (3 * u * t * t) + d * (t * t * t);
  }

  static Future<void> _click(Offset p) async {
    final touch = Platform.isAndroid || Platform.isIOS;
    final kind = touch ? PointerDeviceKind.touch : PointerDeviceKind.mouse;
    final id = ++_pointer;
    GestureBinding.instance.handlePointerEvent(PointerDownEvent(
      pointer: id,
      position: p,
      kind: kind,
      device: touch ? 0 : 1,
      buttons: kPrimaryButton,
    ));
    // a finger / mouse never stays perfectly still
    if (touch) {
      await Future.delayed(Duration(milliseconds: 30 + _rnd.nextInt(30)));
      GestureBinding.instance.handlePointerEvent(PointerMoveEvent(
        pointer: id,
        position: p + Offset(_rnd.nextDouble() - 0.5, _rnd.nextDouble() - 0.5),
        kind: kind,
        buttons: kPrimaryButton,
      ));
    }
    await Future.delayed(Duration(milliseconds: 60 + _rnd.nextInt(90)));
    GestureBinding.instance.handlePointerEvent(PointerUpEvent(
      pointer: id,
      position: p,
      kind: kind,
      device: touch ? 0 : 1,
    ));
  }
}
