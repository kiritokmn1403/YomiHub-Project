import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/models/video.dart' as vid;
import 'package:mangayomi/repositories/chapter_repository.dart';
import 'package:mangayomi/models/history.dart';
import 'package:mangayomi/repositories/history_repository.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/browser/adblock.dart';
import 'package:mangayomi/yomihub/player/yomi_pip.dart';

/// YomiHub 0.1.4: plays a server through the site's own web player.
///
/// Some servers only exist as an embedded player page (encrypted MSE
/// players such as AnimeVietsub "DU", Abyss/Hydrax…), so their stream can't
/// be handed to mpv. Extensions return those as videos whose url starts with
/// `yhweb:`; YomiHub opens them here, full screen, with pop-ups and ad
/// redirects blocked.
///
/// 0.1.8: plays by itself as soon as the episode is chosen (also inside the
/// player iframe), Picture-in-Picture (system PiP on Android 8.0+, the
/// browser's own PiP window on Windows) and the full AdBlock (network lists,
/// element hiding, pop-up / redirect blocking) like the in-app browser.
class YomiWebPlayer extends StatefulWidget {
  static const prefix = 'yhweb:';
  final Chapter episode;
  final List<vid.Video> servers;
  const YomiWebPlayer({super.key, required this.episode, required this.servers});

  static bool isWeb(vid.Video v) => v.url.startsWith(prefix);

  /// Web-only servers of the episode being played, for the automatic
  /// server switch to fall back on.
  static List<vid.Video> pending = [];

  @override
  State<YomiWebPlayer> createState() => _YomiWebPlayerState();
}

class YomiWebPip {
  static const _ch = MethodChannel('yomihub/web_pip');
  static final inPip = ValueNotifier<bool>(false);
  static bool _handler = false;

  static void _listen() {
    if (_handler) return;
    _handler = true;
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'pipChanged') inPip.value = call.arguments == true;
      return null;
    });
  }

  static Future<bool> supported() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _ch.invokeMethod<bool>('supported') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setup({required bool auto, int w = 16, int h = 9}) async {
    if (!Platform.isAndroid) return;
    _listen();
    try {
      await _ch.invokeMethod('setup', {'auto': auto, 'w': w, 'h': h});
    } catch (_) {}
  }

  static Future<bool> enter() async {
    if (!Platform.isAndroid) return false;
    _listen();
    try {
      return await _ch.invokeMethod<bool>('enter') ?? false;
    } catch (_) {
      return false;
    }
  }
}

class _YomiWebPlayerState extends State<YomiWebPlayer> {
  int _i = 0;
  bool _ui = true;
  bool _pipSupported = false;
  InAppWebViewController? _c;
  Timer? _hide;
  final _watch = Stopwatch()..start();

  vid.Video get _cur => widget.servers[_i];
  String get _url => _cur.url.substring(YomiWebPlayer.prefix.length);
  bool get _block => YomiAdBlock.activeFor(_url);

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _autoHide();
    YomiWebPip.inPip.addListener(_onPip);
    YomiPip.open().then((_) async {
      _pipSupported = await YomiWebPip.supported();
      await YomiWebPip.setup(auto: YomiPip.autoEnter && _pipSupported);
      if (mounted) setState(() {});
    });
  }

  void _autoHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _ui = false);
    });
  }

  void _onPip() {
    if (!mounted) return;
    final p = YomiWebPip.inPip.value;
    setState(() => _ui = !p);
    _post(p ? 'fill' : 'unfill');
    if (p) _post('play');
  }

  @override
  void dispose() {
    _hide?.cancel();
    YomiWebPip.inPip.removeListener(_onPip);
    // leaving the web player: the app must not go into PiP on Home any more
    YomiWebPip.setup(auto: false);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // 0.4.3: the last known position is written when leaving (it was only
    // saved every few seconds, so the end of the session was lost), the
    // episode is marked as watched only when really watched (≥ 85 %, it used
    // to be after 3 minutes of any playback) and History is updated like the
    // native player does (History tab / Comic-Anime-Novel history in sync).
    _saveNow(force: true);
    _touchHistory(_watch.elapsed.inSeconds);
    super.dispose();
  }

  /// Runs in every frame (the site page and the player iframes). It starts
  /// the video as soon as it can (clicking the usual "play" overlays of
  /// JW Player, ArtPlayer, Video.js, Plyr, Clappr… when needed), reports the
  /// video size up to the page, and obeys commands sent down by YomiHub
  /// through postMessage ("play", "fill", "unfill", "pip").
  static const _frameScript = r"""
(() => {
  if (window.__yhWebPlayer) return;
  window.__yhWebPlayer = true;
  const isTop = window === window.top;
  const tried = new WeakMap();
  let userPaused = false, started = false, t0 = Date.now();
  const PLAY_SEL = '.jw-icon-display,.jw-display-icon-container,.art-control-play,.art-state,'
    + '.vjs-big-play-button,.plyr__control--overlaid,.play-wrapper,.player-poster,'
    + '[class*="play-button"],[class*="btn-play"],[class*="playButton"],#play,.play';
  function videos() { return Array.from(document.querySelectorAll('video')); }
  function tryPlay(force) {
    if (userPaused && !force) return;
    let any = false;
    for (const v of videos()) {
      any = true;
      v.playsInline = true;
      v.setAttribute('playsinline', '');
      if (!v.paused && !v.ended) { started = true; continue; }
      const n = (tried.get(v) || 0);
      if (!force && n > 30) continue;
      tried.set(v, n + 1);
      try { const r = v.play(); if (r && r.catch) r.catch(() => { v.muted = true; v.play().then(() => setTimeout(() => { v.muted = false; }, 400)).catch(() => {}); }); } catch (e) {}
    }
    try { if (window.jwplayer) { const j = window.jwplayer(); if (j && j.getState && j.getState() !== 'playing' && j.play) j.play(true); } } catch (e) {}
    try { if (window.art && window.art.play && !window.art.playing) window.art.play(); } catch (e) {}
    if (!started && Date.now() - t0 < 20000) {
      const b = document.querySelector(PLAY_SEL);
      if (b && b.offsetParent !== null && (!any || videos().every(v => v.paused))) { try { b.click(); } catch (e) {} }
    }
  }
  function report() {
    const v = videos().find(v => v.videoWidth > 0);
    if (!v) return;
    const msg = { yh: 'size', w: v.videoWidth, h: v.videoHeight };
    if (isTop) { try { window.flutter_inappwebview.callHandler('yhSize', v.videoWidth, v.videoHeight); } catch (e) {} }
    else { try { window.top.postMessage(msg, '*'); } catch (e) {} }
  }
  let fillStyle = null;
  function fill(on) {
    const v = videos().find(v => v.videoWidth > 0) || videos()[0];
    if (on) {
      if (!fillStyle) { fillStyle = document.createElement('style'); (document.head || document.documentElement).appendChild(fillStyle); }
      fillStyle.textContent = v
        ? 'video{position:fixed!important;inset:0!important;width:100vw!important;height:100vh!important;z-index:2147483647!important;background:#000!important;object-fit:contain!important}'
        : 'iframe{position:fixed!important;inset:0!important;width:100vw!important;height:100vh!important;z-index:2147483647!important;border:0!important}';
    } else if (fillStyle) { fillStyle.textContent = ''; }
  }
  function forward(msg) {
    for (const f of document.querySelectorAll('iframe')) { try { f.contentWindow.postMessage(msg, '*'); } catch (e) {} }
  }
  // YomiHub 0.1.9: report the position (resume where the user stopped)
  let pendingSeek = 0;
  function pos() {
    const v = videos().find(v => v.duration > 0 && isFinite(v.duration));
    if (!v) return;
    if (pendingSeek > 0 && v.readyState >= 1) { try { v.currentTime = pendingSeek; } catch (e) {} pendingSeek = 0; }
    if (isTop) { try { window.flutter_inappwebview.callHandler('yhPos', v.currentTime, v.duration); } catch (e) {} }
    else { try { window.top.postMessage({ yh: 'pos', t: v.currentTime, d: v.duration }, '*'); } catch (e) {} }
  }
  setInterval(pos, 5000);
  document.addEventListener('pause', pos, true);
  document.addEventListener('ended', pos, true);
  document.addEventListener('loadedmetadata', () => { if (pendingSeek > 0) pos(); }, true);
  function command(c) {
    if (typeof c === 'string' && c.indexOf('seek:') === 0) {
      pendingSeek = parseFloat(c.slice(5)) || 0;
      pos();
      forward({ yh: 'cmd', c });
      return;
    }
    if (c === 'play') { userPaused = false; tryPlay(true); }
    else if (c === 'fill' || c === 'unfill') fill(c === 'fill');
    else if (c === 'pip') {
      const v = videos().find(v => v.videoWidth > 0);
      if (v && document.pictureInPictureEnabled) { v.requestPictureInPicture().catch(() => {}); }
    }
    forward({ yh: 'cmd', c });
  }
  window.__yhCommand = command;
  window.addEventListener('message', (e) => {
    const d = e.data;
    if (!d || typeof d !== 'object') return;
    if (d.yh === 'cmd') command(d.c);
    else if (d.yh === 'size' && isTop) { try { window.flutter_inappwebview.callHandler('yhSize', d.w, d.h); } catch (x) {} }
    else if (d.yh === 'pos' && isTop) { try { window.flutter_inappwebview.callHandler('yhPos', d.t, d.d); } catch (x) {} }
  });
  document.addEventListener('pause', (e) => { if (e.isTrusted && e.target && e.target.tagName === 'VIDEO' && started && document.visibilityState === 'visible') userPaused = true; }, true);
  document.addEventListener('playing', () => { started = true; userPaused = false; report(); }, true);
  document.addEventListener('loadedmetadata', report, true);
  document.addEventListener('loadeddata', () => tryPlay(false), true);
  document.addEventListener('canplay', () => tryPlay(false), true);
  const iv = setInterval(() => { if (Date.now() - t0 > 30000) { clearInterval(iv); return; } if (!started) tryPlay(false); }, 700);
  tryPlay(false);
})();
""";

  // ───── YomiHub 0.1.9: resume position (every Film & Movie extension) ─────
  bool _resumed = false;
  int _lastSaveMs = 0;

  /// 0.4.3: the episode as stored now. The [Chapter] handed to the player
  /// can be a stale copy from the episode list, so a position saved by the
  /// previous session was not seen and playback restarted from 0.
  Chapter get _fresh =>
      (widget.episode.id != null
          ? chapterRepository.findByIdSync(widget.episode.id!)
          : null) ??
      widget.episode;

  double _lastT = 0, _lastD = 0;

  void _saveNow({bool force = false}) {
    if (_lastD <= 0 || _lastT <= 0) return;
    if (!_resumed && _savedSec > 0 && _lastT < 5) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && now - _lastSaveMs < 4000) return;
    _lastSaveMs = now;
    final ep = _fresh
      ..lastPageRead = (_lastT * 1000).round().toString()
      ..duration = (_lastD * 1000).round().toString()
      ..updatedAt = now;
    if (_lastT >= _lastD * 0.85) ep.isRead = true;
    widget.episode
      ..lastPageRead = ep.lastPageRead
      ..duration = ep.duration
      ..isRead = ep.isRead;
    try {
      chapterRepository.saveSync(ep);
    } catch (e) {
      AppLogger.logOnce(
        'webpos:${ep.id}',
        '[Trình phát web] Không lưu được vị trí đã xem của tập "${ep.name}": $e',
        logLevel: LogLevel.error,
      );
    }
  }

  void _touchHistory(int elapsedSeconds) {
    try {
      final ep = _fresh;
      final manga = ep.manga.value;
      if (manga == null || manga.id == null) return;
      manga.lastRead = DateTime.now().millisecondsSinceEpoch;
      mangaRepository.save(manga);
      final old = historyRepository.findFirstByMangaId(manga.id);
      final h = (old ??
              History(
                mangaId: manga.id,
                date: '',
                itemType: manga.itemType,
                chapterId: ep.id,
              ))
        ..chapterId = ep.id
        ..chapter.value = ep
        ..date = DateTime.now().millisecondsSinceEpoch.toString();
      if (elapsedSeconds > 0) {
        h.readingTimeSeconds = (h.readingTimeSeconds ?? 0) + elapsedSeconds;
      }
      historyRepository.save(h);
    } catch (e) {
      AppLogger.logOnce(
        'webhist:${widget.episode.id}',
        '[Trình phát web] Không cập nhật được Lịch sử: $e',
        logLevel: LogLevel.warning,
      );
    }
  }

  /// Saved position of this episode in seconds (0 = from the start).
  late final double _savedSec = () {
    final e = _fresh;
    final ms = int.tryParse(e.lastPageRead ?? '') ?? 0;
    final total = int.tryParse(e.duration ?? '') ?? 0;
    if (ms < 10000) return 0.0;
    if (total > 0 && ms > total * 0.95) return 0.0; // finished: start over
    return ms / 1000;
  }();

  void _resumeOnce() {
    if (_resumed) return;
    _resumed = true;
    final s = _savedSec;
    if (s > 0) {
      _post('seek:${s.toStringAsFixed(1)}');
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(tr('Xem tiếp từ {p0}', {'p0': _fmt(s)})),
        ),
      );
    }
  }

  static String _fmt(double s) {
    final d = Duration(seconds: s.round());
    final h = d.inHours, m = d.inMinutes % 60, sec = d.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
  }

  void _onPos(num t, num d) {
    if (d <= 0 || t <= 0 || !d.isFinite) return;
    if (!_resumed && _savedSec > 0 && t < 5) return; // not resumed yet
    _lastT = t.toDouble();
    _lastD = d.toDouble();
    _saveNow();
  }

  void _post(String cmd) {
    final c = _c;
    if (c == null) return;
    c
        .evaluateJavascript(
          source: "window.__yhCommand && window.__yhCommand('$cmd');",
        )
        .catchError((_) => null);
  }

  Future<void> _pip() async {
    if (Platform.isAndroid) {
      if (!_pipSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('Máy này chưa có Hình trong hình của hệ thống (cần Android 8.0+). Hãy dùng máy chủ phát bằng trình phát YomiHub để có cửa sổ nổi.'),
            ),
          ),
        );
        return;
      }
      _post('fill');
      setState(() => _ui = false);
      final ok = await YomiWebPip.enter();
      if (!ok) _post('unfill');
    } else {
      // Windows (WebView2): the browser's own floating PiP window
      _post('pip');
    }
  }

  bool _sameSite(String a, String b) {
    String root(String u) {
      final h = Uri.tryParse(u)?.host ?? '';
      final p = h.split('.');
      return p.length >= 2 ? p.sublist(p.length - 2).join('.') : h;
    }

    return root(a) == root(b);
  }

  @override
  Widget build(BuildContext context) {
    // YomiHub 0.1.9: the system Back key puts the video in PiP (Android)
    final backPip = Platform.isAndroid && YomiPip.backToPip && _pipSupported && !YomiWebPip.inPip.value;
    return PopScope(
      canPop: !backPip,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && backPip) _pip();
      },
      child: _page(context),
    );
  }

  Widget _page(BuildContext context) {
    final block = _block;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          InAppWebView(
            key: ValueKey(_i),
            initialUrlRequest: URLRequest(
              url: WebUri(_url),
              headers: _cur.headers,
            ),
            initialSettings: InAppWebViewSettings(
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              allowsPictureInPictureMediaPlayback: true,
              javaScriptCanOpenWindowsAutomatically: false,
              supportMultipleWindows: true,
              useWideViewPort: true,
              transparentBackground: true,
              useShouldOverrideUrlLoading: true,
              // AdBlock lists (AdGuard, EasyList, ABPVN…) on sub-resources;
              // the built-in ad hosts are also blocked natively
              useShouldInterceptRequest: block && Platform.isAndroid,
              contentBlockers: block ? YomiAdBlock.contentBlockers() : [],
            ),
            initialUserScripts: UnmodifiableListView([
              // YomiHub 0.2.0: AVSub's player showed "Developer Tools đang
              // mở" in the WebView (outer/inner size heuristics, debugger
              // traps): make the page see a normal browser window.
              UserScript(
                source: _antiDevtoolsScript,
                injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                forMainFrameOnly: false,
              ),
              UserScript(
                source: _frameScript,
                injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
                forMainFrameOnly: false,
              ),
              if (block)
                UserScript(
                  source: YomiAdBlock.pageScript(YomiAdBlock.hostOf(_url)),
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
                  forMainFrameOnly: false,
                ),
            ]),
            onWebViewCreated: (c) {
              _c = c;
              c.addJavaScriptHandler(
                handlerName: 'yhPos',
                callback: (a) {
                  _onPos(
                    (a.isNotEmpty ? a[0] : 0) as num,
                    (a.length > 1 ? a[1] : 0) as num,
                  );
                  return null;
                },
              );
              c.addJavaScriptHandler(
                handlerName: 'yhSize',
                callback: (a) {
                  _resumeOnce();
                  final w = (a.isNotEmpty ? a[0] : 16) as num;
                  final h = (a.length > 1 ? a[1] : 9) as num;
                  YomiWebPip.setup(
                    auto: YomiPip.autoEnter && _pipSupported,
                    w: w.round(),
                    h: h.round(),
                  );
                  return null;
                },
              );
            },
            shouldInterceptRequest: (c, r) async => YomiAdBlock.intercept(_url, r.url.toString()),
            onCreateWindow: (c, a) async => false, // no pop-ups
            shouldOverrideUrlLoading: (c, a) async {
              final u = a.request.url?.toString() ?? '';
              if (!a.isForMainFrame) {
                return block && YomiAdBlock.isAd(u)
                    ? NavigationActionPolicy.CANCEL
                    : NavigationActionPolicy.ALLOW;
              }
              if ((block && YomiAdBlock.isAd(u)) || !_sameSite(u, _url)) {
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
            onLoadStop: (c, u) async {
              try {
                await c.evaluateJavascript(source: _frameScript);
                if (block) {
                  await c.evaluateJavascript(
                    source: YomiAdBlock.pageScript(YomiAdBlock.hostOf(_url)),
                  );
                }
                _post('play');
              } catch (error) {
                AppLogger.log(
                  'Web player script failed: $error',
                  logLevel: LogLevel.warning,
                );
              }
            },
            onReceivedError: (c, r, e) {
              if (r.isForMainFrame ?? false) {
                AppLogger.log(
                  'Web player ${widget.servers[_i].quality} ${r.url}: ${e.description}',
                  logLevel: LogLevel.error,
                );
              }
            },
          ),
          // tap strip at the top toggles the overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 36,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() => _ui = !_ui);
                if (_ui) _autoHide();
              },
            ),
          ),
          if (_ui)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.episode.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      if (YomiPip.showButton)
                        IconButton(
                          tooltip: tr('Hình trong hình'),
                          icon: const Icon(
                            Icons.picture_in_picture_alt_outlined,
                            color: Colors.white,
                          ),
                          onPressed: _pip,
                        ),
                      IconButton(
                        tooltip: tr('Phát'),
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        onPressed: () => _post('play'),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (var k = 0; k < widget.servers.length; k++)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: ChoiceChip(
                                    label: Text(widget.servers[k].quality),
                                    selected: k == _i,
                                    onSelected: (_) => setState(() {
                                      _i = k;
                                      _c = null;
                                    }),
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
            ),
        ],
      ),
    );
  }
}

/// YomiHub 0.2.0: hides the signals sites use to detect "DevTools open"
/// (window outer size vs inner size, `debugger` loops, devtools-detector /
/// disable-devtool libraries) inside the web player.
const String _antiDevtoolsScript = r'''
(function () {
  try {
    var dp = Object.defineProperty;
    try { dp(window, 'outerWidth', { get: function () { return window.innerWidth; }, configurable: true }); } catch (e) {}
    try { dp(window, 'outerHeight', { get: function () { return window.innerHeight + 80; }, configurable: true }); } catch (e) {}
    var noop = function () {};
    window.DisableDevtool = function () { return { success: false }; };
    window.DisableDevtool.isRunning = false;
    window.devtoolsDetector = { addListener: noop, removeListener: noop, launch: noop, stop: noop, isLaunch: function () { return false; } };
    try { dp(window, 'devtools', { get: function () { return { isOpen: false, orientation: undefined }; }, set: noop, configurable: true }); } catch (e) {}
    ['clear', 'table', 'profile', 'profileEnd'].forEach(function (k) { try { console[k] = noop; } catch (e) {} });
    var F = window.Function;
    var NF = function () {
      var a = Array.prototype.slice.call(arguments);
      if (a.length && typeof a[a.length - 1] === 'string') a[a.length - 1] = a[a.length - 1].replace(/\bdebugger\b/g, '');
      return F.apply(this, a);
    };
    NF.prototype = F.prototype;
    try { F.prototype.constructor = NF; } catch (e) {}
    window.Function = NF;
    var wrap = function (orig) {
      return function (f, t) {
        try {
          if (typeof f === 'string' && /\bdebugger\b/.test(f)) return 0;
          if (typeof f === 'function' && /\bdebugger\b/.test(Function.prototype.toString.call(f))) return 0;
        } catch (e) {}
        return orig.apply(this, arguments);
      };
    };
    window.setInterval = wrap(window.setInterval);
    window.setTimeout = wrap(window.setTimeout);
  } catch (e) {}
})();
''';
