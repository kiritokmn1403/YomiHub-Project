import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mangayomi/main.dart' show webViewEnvironment;

/// YomiHub: finds the real video stream behind an embedded player.
///
/// Opens [url] in a hidden WebView, keeps the page's player from being
/// "punished" for blocked pop-ups, presses play inside every frame and
/// records media requests (HLS / DASH / MP4 / chunked players) made by any
/// frame. Used by bundled extensions through
/// `evaluateJavascriptViaWebview(url, headers, ["__yh_sniff__", pattern])`.
class YomiMediaSniffer {
  YomiMediaSniffer._();

  static final _defaultPattern = RegExp(
    r'(\.m3u8|\.mpd|\.mp4|\.webm|\.mkv|/hls/|playlist|master\.|/sora/|videoplayback|\.ts\?|mime=video)',
    caseSensitive: false,
  );
  static final _ignore = RegExp(
    r'(googlesyndication|doubleclick|google-analytics|googletagmanager|pixel\.|/ads?/|\.jpg|\.png|\.gif|\.css|\.woff|vast|preroll|thumbnail|\.vtt|sprite)',
    caseSensitive: false,
  );

  static const _frameScript = r'''
(function(){
  if (window.__yhSniff) return; window.__yhSniff = 1;
  // Players that stream through a Service Worker hide the real media
  // requests; without one they fall back to a plain <video> request.
  try { Object.defineProperty(Navigator.prototype, 'serviceWorker', { get: function(){ return undefined; } }); } catch(e){}
  try { delete Navigator.prototype.serviceWorker; } catch(e){}
  var report = function(u){ try { if (u && typeof u === 'string' && u.indexOf('blob:') !== 0) window.flutter_inappwebview.callHandler('yhMedia', u, location.href); } catch(e){} };
  try { window.open = function(){ return { focus:function(){}, close:function(){}, closed:false, location:{} }; }; } catch(e){}
  try { var _f = window.fetch; window.fetch = function(i, o){ try { report(typeof i === 'string' ? i : (i && i.url)); } catch(e){} return _f.apply(this, arguments); }; } catch(e){}
  try { var _o = XMLHttpRequest.prototype.open; XMLHttpRequest.prototype.open = function(m, u){ try { report('' + u); } catch(e){} return _o.apply(this, arguments); }; } catch(e){}
  var n = 0;
  var t = setInterval(function(){
    n++;
    try { var ov = document.getElementById('overlay'); if (ov) { if (ov.onclick) ov.onclick(); if (ov.ontouchend) ov.ontouchend(); } } catch(e){}
    try { if (window.jwplayer) { var p = window.jwplayer(); if (p) { try { var it = p.getPlaylistItem && p.getPlaylistItem(); if (it) { report(it.file); (it.sources||[]).forEach(function(s){ report(s.file); }); } } catch(e){}
      if (p.setMute) p.setMute(true); if (p.getState && p.getState() !== 'playing' && p.play) p.play(); } } } catch(e){}
    try { document.querySelectorAll('video, video source').forEach(function(v){ report(v.currentSrc || v.src); if (v.play) { v.muted = true; var r = v.play(); if (r && r.catch) r.catch(function(){}); } }); } catch(e){}
    try { var b = document.querySelector('.jw-icon-display, .vjs-big-play-button, .plyr__control--overlaid, .play-button, #play, .btn-play'); if (b && n % 4 === 1) b.click(); } catch(e){}
    if (n > 120) clearInterval(t);
  }, 500);
})();
''';

  static Future<Map<String, dynamic>> sniff(
    String url,
    Map<String, String> headers, {
    int timeoutSec = 25,
    String? pattern,
    String? userAgentSuffix,
  }) async {
    final re = (pattern != null && pattern.isNotEmpty)
        ? RegExp(pattern, caseSensitive: false)
        : _defaultPattern;
    final found = <String, Map<String, String>>{};
    final order = <String>[];
    final done = Completer<void>();

    void add(String? u, Map<String, String>? reqHeaders, {String? frame}) {
      if (u == null || u.isEmpty || u.startsWith('data:') || u.startsWith('blob:')) return;
      if (!re.hasMatch(u) || _ignore.hasMatch(u)) return;
      if (found.containsKey(u)) return;
      final h = <String, String>{};
      reqHeaders?.forEach((k, v) {
        final lk = k.toLowerCase();
        if (lk == 'referer' || lk == 'origin' || lk == 'user-agent' || lk == 'cookie') h[k] = v;
      });
      if (!h.keys.any((k) => k.toLowerCase() == 'referer') && frame != null) {
        final f = Uri.tryParse(frame);
        if (f != null && f.hasScheme) h['Referer'] = '${f.scheme}://${f.host}/';
      }
      found[u] = h;
      order.add(u);
      // A playlist is the best answer; stop early. For raw files wait a bit
      // more in case a playlist shows up.
      if (RegExp(r'\.(m3u8|mpd)', caseSensitive: false).hasMatch(u) && !done.isCompleted) {
        done.complete();
      } else if (order.length == 1) {
        Future.delayed(const Duration(seconds: 4), () {
          if (!done.isCompleted) done.complete();
        });
      }
    }

    HeadlessInAppWebView? web;
    try {
      web = HeadlessInAppWebView(
        webViewEnvironment: webViewEnvironment,
        initialSettings: InAppWebViewSettings(
          mediaPlaybackRequiresUserGesture: false,
          useShouldInterceptRequest: true,
          javaScriptCanOpenWindowsAutomatically: false,
          supportMultipleWindows: false,
          userAgent: (headers['User-Agent'] ?? headers['user-agent'] ??
                  'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36') +
              (userAgentSuffix == null || userAgentSuffix.isEmpty ? '' : ' $userAgentSuffix'),
        ),
        initialUserScripts: UnmodifiableListView([
          UserScript(
            source: _frameScript,
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
            forMainFrameOnly: false,
          ),
        ]),
        onWebViewCreated: (c) {
          c.addJavaScriptHandler(
            handlerName: 'yhMedia',
            callback: (args) {
              add(args.isNotEmpty ? '${args[0]}' : null, null,
                  frame: args.length > 1 ? '${args[1]}' : null);
              return null;
            },
          );
        },
        initialUrlRequest: URLRequest(url: WebUri(url), headers: headers),
        shouldInterceptRequest: (c, req) async {
          add(req.url.toString(), req.headers);
          return null;
        },
        onLoadResource: (c, res) {
          add(res.url?.toString(), null);
        },
        onCreateWindow: (c, action) async => false,
        onLoadStop: (c, u) async {
          try {
            await c.evaluateJavascript(source: _frameScript);
          } catch (_) {}
        },
      );
      await web.run();
      await Future.any([
        done.future,
        Future.delayed(Duration(seconds: timeoutSec)),
      ]);
    } catch (_) {
    } finally {
      try {
        await web?.dispose();
      } catch (_) {}
    }
    // Playlists first, then everything else in the order seen.
    order.sort((a, b) {
      int rank(String u) => RegExp(r'\.(m3u8|mpd)', caseSensitive: false).hasMatch(u) ? 0 : 1;
      return rank(a) - rank(b);
    });
    return {
      'url': order.isEmpty ? '' : order.first,
      'headers': order.isEmpty ? <String, String>{} : found[order.first],
      'all': [for (final u in order) {'url': u, 'headers': found[u]}],
    };
  }

  static String encode(Map<String, dynamic> r) => jsonEncode(r);
}
