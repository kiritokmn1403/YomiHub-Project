import 'package:mangayomi/yomihub/prefs/yomi_hive.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hive/hive.dart';
import 'package:mangayomi/main.dart' show webViewEnvironment;
import 'package:mangayomi/router/router.dart' show navigatorKey;
import 'package:mangayomi/services/http/m_client.dart';
import 'package:mangayomi/yomihub/cloudscraper/cloudscraper.dart';
import 'package:mangayomi/yomihub/cloudflare/cf_humanize.dart';
import 'package:mangayomi/yomihub/cloudflare/cloak_solver.dart';

/// YomiHub 0.1.6: Cloudflare challenge handling shared by every extension.
///
/// Fixes over 0.1.5:
///  * `cf_clearance` is bound to the User-Agent that earned it. 0.1.5 kept
///    one global User-Agent, so solving site B (or an extension that sends
///    its own UA) silently invalidated site A. The solving UA is now kept
///    per host and forced on every request that carries that host's
///    clearance cookie.
///  * one challenge per host at a time: a library page firing 40 cover
///    requests at a protected site used to start 40 headless WebViews.
///  * when the invisible WebView can't pass (interactive Turnstile), the
///    challenge page is shown to the user once, the same way Mihon/Aniyomi
///    ask the user to open the WebView; declining is remembered for a while
///    so the prompt does not come back for every image.
class YomiCf {
  YomiCf._();
  static const _boxName = 'yomihub_cf_ua';
  static Box? _box;
  static final Map<String, String> _ua = {};
  static final Map<String, Future<bool>> _inflight = {};
  static final Map<String, DateTime> _declined = {};
  static final Map<String, DateTime> _failed = {};

  static Future<void> open() async {
    if (_box != null) return;
    try {
      _box = await YomiHive.open(_boxName);
      for (final k in _box!.keys) {
        final v = _box!.get(k);
        if (v is String) _ua['$k'] = v;
      }
    } catch (_) {}
  }

  static String _key(String host) =>
      host.startsWith('www.') ? host.substring(4) : host;

  /// User-Agent that solved the challenge for [host] (or a parent domain).
  static String? uaFor(String host) {
    var h = _key(host);
    while (true) {
      final v = _ua[h];
      if (v != null) return v;
      final i = h.indexOf('.');
      if (i < 0 || h.indexOf('.', i + 1) < 0) return null;
      h = h.substring(i + 1);
    }
  }

  static void rememberUa(String host, String ua) {
    if (ua.isEmpty) return;
    final h = _key(host);
    _ua[h] = ua;
    _box?.put(h, ua);
  }

  static Map<String, String> get all => Map.unmodifiable(_ua);

  static Future<void> forget(String host) async {
    final h = _key(host);
    _ua.remove(h);
    await _box?.delete(h);
    await MClient.deleteAllCookies('https://$h/');
    try {
      await CookieManager.instance(
        webViewEnvironment: webViewEnvironment,
      ).deleteCookies(url: WebUri('https://$h/'));
    } catch (_) {}
  }

  // ---- YomiHub 0.2.2 -----------------------------------------------------
  static final Map<String, DateTime> _solvedAt = {};
  static final Map<String, String> _redirect = {};

  /// Host whose challenge was solved within the last 30 minutes.
  static bool recentlySolved(String host) {
    final t = _solvedAt[_key(host)];
    return t != null && DateTime.now().difference(t).inMinutes < 30;
  }

  /// Site [from] answered from [to] after the challenge (domain moved).
  static String? redirectOf(String host) => _redirect[_key(host)];

  /// Has the WebView earned `cf_clearance` for [origUrl] – on its own host or
  /// on the host it was redirected to? (0.2.2: the redirect case was missed:
  /// e.g. hentaicube.xyz → hentaicb.help, the solver waited for a cookie on
  /// the old host, timed out and the extension stayed blocked.)
  static Future<bool> hasClearance(String origUrl, InAppWebViewController c) async {
    final cm = CookieManager.instance(webViewEnvironment: webViewEnvironment);
    try {
      final a = await cm.getCookies(url: WebUri(origUrl), webViewController: c);
      if (a.any((e) => e.name == 'cf_clearance')) return true;
    } catch (_) {}
    try {
      final cur = await c.getUrl();
      if (cur != null && cur.host != Uri.parse(origUrl).host) {
        final b = await cm.getCookies(url: cur, webViewController: c);
        if (b.any((e) => e.name == 'cf_clearance')) return true;
      }
    } catch (_) {}
    return false;
  }

  /// Stores the WebView's cookies + User-Agent for the requested host and,
  /// after a redirect, also for the host the WebView ended on.
  static Future<void> saveFromWebView(String origUrl, InAppWebViewController c) async {
    final ua = (await c.evaluateJavascript(source: 'navigator.userAgent'))?.toString() ?? '';
    final orig = Uri.parse(origUrl);
    WebUri? cur;
    try {
      cur = await c.getUrl();
    } catch (_) {}
    await MClient.setCookie(origUrl, ua, c);
    if (cur != null && cur.host.isNotEmpty && _key(cur.host) != _key(orig.host)) {
      try {
        final cs = await CookieManager.instance(webViewEnvironment: webViewEnvironment)
            .getCookies(url: cur, webViewController: c);
        final joined = cs.map((e) => '${e.name}=${e.value}').join(', ');
        await MClient.setCookie(cur.toString(), ua, c);
        if (joined.isNotEmpty) {
          // requests to the old host carry the new host's clearance too
          await MClient.setCookie(origUrl, ua, null, cookie: joined);
        }
      } catch (_) {}
      _redirect[_key(orig.host)] = _key(cur.host);
      rememberUa(cur.host, ua);
      AppLogger.logOnce(
        'cfredir:${orig.host}',
        '[Cloudflare] ${orig.host} chuyển hướng sang ${cur.host} sau khi xác minh – '
        'nên dùng "Đổi URL" của tiện ích sang https://${cur.host}',
        logLevel: LogLevel.warning,
      );
    }
    rememberUa(orig.host, ua);
    _solvedAt[_key(orig.host)] = DateTime.now();
    if (cur != null) _solvedAt[_key(cur.host)] = DateTime.now();
  }

  static Future<void> forgetAll() async {
    _ua.clear();
    await _box?.clear();
  }

  /// Runs [headless] once per host; if it fails, optionally asks the user.
  static Future<bool> solve(String url, Future<bool> Function() headless) {
    final host = _key(Uri.parse(url).host);
    final running = _inflight[host];
    if (running != null) return running;
    final failed = _failed[host];
    if (failed != null && DateTime.now().difference(failed).inSeconds < 60) {
      return Future.value(false);
    }
    final f = () async {
      try {
        final ok = await headless() || await _interactive(url, host);
        if (ok) {
          _failed.remove(host);
        } else {
          _failed[host] = DateTime.now();
        }
        return ok;
      } catch (_) {
        _failed[host] = DateTime.now();
        return false;
      } finally {
        // ignore: unawaited_futures
        Future<void>.delayed(Duration.zero, () => _inflight.remove(host));
      }
    }();
    _inflight[host] = f;
    return f;
  }

  static Future<bool> _interactive(String url, String host) async {
    if (!CloudScraper.interactive) return false;
    final d = _declined[host];
    if (d != null && DateTime.now().difference(d).inMinutes < 10) return false;
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return false;
    }
    final nav = navigatorKey.currentState;
    if (nav == null) return false;
    final ok = await nav.push<bool>(
      MaterialPageRoute(builder: (_) => CfChallengePage(url: url)),
    );
    if (ok != true) _declined[host] = DateTime.now();
    return ok == true;
  }
}

/// Visible challenge page: the site is opened in the WebView, the user ticks
/// the Cloudflare box if asked, and the page closes itself as soon as
/// Cloudflare hands out `cf_clearance`.
class CfChallengePage extends StatefulWidget {
  final String url;
  const CfChallengePage({super.key, required this.url});

  @override
  State<CfChallengePage> createState() => _CfChallengePageState();
}

class _CfChallengePageState extends State<CfChallengePage> {
  InAppWebViewController? _c;
  Timer? _poll;
  bool _done = false;
  double _progress = 0;
  final _webKey = GlobalKey();
  int _clicks = 0;
  DateTime _lastClick = DateTime.fromMillisecondsSinceEpoch(0);

  /// 0.1.8: tick the Turnstile box like a person (CloakBrowser humanize),
  /// at most three times, a few seconds apart.
  Future<void> _humanize() async {
    if (!YomiCloak.humanize || _done || _c == null || _clicks >= 3) return;
    if (DateTime.now().difference(_lastClick).inSeconds < 4) return;
    if (await CfHumanize.clickTurnstile(_c!, _webKey)) {
      _clicks++;
      _lastClick = DateTime.now();
    }
  }

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(milliseconds: 700), (_) => _check());
  }

  Future<void> _check() async {
    if (_done || _c == null) return;
    try {
      if (!await YomiCf.hasClearance(widget.url, _c!)) {
        unawaited(_humanize());
        return;
      }
      final title = await _c!.getTitle() ?? '';
      if (title.contains('Just a moment') || title.contains('Một chút')) {
        return;
      }
      _done = true;
      await YomiCf.saveFromWebView(widget.url, _c!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final host = Uri.parse(widget.url).host;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Xác minh Cloudflare · {p0}', {'p0': host})),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        bottom: _progress < 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress, minHeight: 2),
              )
            : null,
      ),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr('Trang này yêu cầu xác minh. Nếu có ô "Xác minh bạn là con người", hãy bấm vào; trang sẽ tự đóng khi xong.'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: InAppWebView(
              key: _webKey,
              webViewEnvironment: webViewEnvironment,
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                thirdPartyCookiesEnabled: true,
              ),
              onWebViewCreated: (c) => _c = c,
              onProgressChanged: (_, p) =>
                  mounted ? setState(() => _progress = p / 100) : null,
              onLoadStop: (_, _) => _check(),
            ),
          ),
        ],
      ),
    );
  }
}
