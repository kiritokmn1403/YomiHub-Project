import 'dart:math';

import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

/// YomiHub 0.5.7 (YomiHub Update: "Browser Fingerprint, Anti-bot Signature")
///
/// Until 0.5.6 the "Bảo vệ dấu vân tay" switch of the in-app browser was only
/// stored: nothing read it. This is the script it now injects at document
/// start in the browser tabs (not in the WebView that solves Cloudflare –
/// that one must look exactly like the browser that earned `cf_clearance`).
///
/// What it does, in the spirit of FingerprintJS counter-measures:
/// * Canvas `toDataURL` / `toBlob` / `getImageData`: a few low bits change –
///   the same for one site during one app session (a value that changes on
///   every call is itself a fingerprint), different between sites.
/// * AudioContext `getChannelData` / `getFloatFrequencyData`: same idea.
/// * WebGL `UNMASKED_VENDOR/RENDERER`: a common generic GPU name.
/// * `navigator.hardwareConcurrency` / `deviceMemory`: common values.
/// * `navigator.webdriver`: false (anti-bot checks).
/// User-Agent, language and screen size are NOT changed: they must stay the
/// same as what the HTTP requests and the Cloudflare cookies carry.
class YomiAntiFingerprint {
  YomiAntiFingerprint._();

  static const prefKey = 'browser_fingerprint_protection';

  /// On by default (the switch showed "on" since 0.3.x).
  static bool get enabled => YomiPrefs.get<bool>(prefKey, true);

  /// One random value per app run; mixed with the host in the page.
  static final int sessionSeed = Random.secure().nextInt(0x7fffffff);

  /// The script, or '' when protection is off.
  static String scriptOrEmpty() => enabled ? script(sessionSeed) : '';

  static String script(int seed) => '''
(function(){
  try {
    if (window.__yhAfp) return; window.__yhAfp = 1;
    var h = 2166136261 ^ $seed;
    var host = (location && location.hostname) || '';
    for (var i = 0; i < host.length; i++) { h ^= host.charCodeAt(i); h = Math.imul(h, 16777619); }
    function rnd(n){ var x = Math.imul(h ^ (n * 2654435761), 1597334677); x ^= x >>> 15; return (x >>> 0) / 4294967296; }
    function def(o, k, v){ try { Object.defineProperty(o, k, { get: function(){ return v; }, configurable: true }); } catch(e){} }
    function noise(img){
      var d = img.data, step = Math.max(4, ((d.length / 400) | 0) * 4);
      for (var i = 0, n = 0; i < d.length; i += step, n++) { if (rnd(n) < 0.5) d[i] = d[i] ^ 1; }
      return img;
    }
    var C = window.CanvasRenderingContext2D && CanvasRenderingContext2D.prototype;
    if (C && C.getImageData) {
      var gid = C.getImageData;
      C.getImageData = function(){ return noise(gid.apply(this, arguments)); };
    }
    var H = window.HTMLCanvasElement && HTMLCanvasElement.prototype;
    function touch(cv){
      try {
        var ctx = cv.getContext && cv.getContext('2d');
        if (!ctx || !cv.width || !cv.height) return;
        var w = Math.min(cv.width, 16), hh = Math.min(cv.height, 16);
        var img = gid.call(ctx, 0, 0, w, hh);
        ctx.putImageData(noise(img), 0, 0);
      } catch(e){}
    }
    if (H && gid) {
      var tdu = H.toDataURL, tb = H.toBlob;
      H.toDataURL = function(){ touch(this); return tdu.apply(this, arguments); };
      if (tb) H.toBlob = function(){ touch(this); return tb.apply(this, arguments); };
    }
    var AB = window.AudioBuffer && AudioBuffer.prototype;
    if (AB && AB.getChannelData) {
      var gcd = AB.getChannelData, done = new WeakSet();
      AB.getChannelData = function(){
        var a = gcd.apply(this, arguments);
        if (!done.has(a)) { done.add(a); for (var i = 0; i < a.length; i += 100) a[i] = a[i] + (rnd(i) - 0.5) * 1e-7; }
        return a;
      };
    }
    var AN = window.AnalyserNode && AnalyserNode.prototype;
    if (AN && AN.getFloatFrequencyData) {
      var gff = AN.getFloatFrequencyData;
      AN.getFloatFrequencyData = function(arr){ gff.apply(this, arguments); for (var i = 0; i < arr.length; i += 50) arr[i] = arr[i] + (rnd(i) - 0.5) * 1e-4; };
    }
    [window.WebGLRenderingContext, window.WebGL2RenderingContext].forEach(function(G){
      if (!G || !G.prototype.getParameter) return;
      var gp = G.prototype.getParameter;
      G.prototype.getParameter = function(p){
        if (p === 37445) return 'Google Inc.';
        if (p === 37446) return 'ANGLE (Generic GPU)';
        return gp.apply(this, arguments);
      };
    });
    var N = window.Navigator && Navigator.prototype;
    if (N) {
      def(N, 'hardwareConcurrency', 8);
      if ('deviceMemory' in navigator) def(N, 'deviceMemory', 8);
      def(N, 'webdriver', false);
    }
  } catch(e){}
})();
''';
}
