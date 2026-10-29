import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hive/hive.dart';
import 'package:mangayomi/main.dart' show webViewEnvironment;
import 'package:mangayomi/router/router.dart' show navigatorKey;
import 'package:mangayomi/services/http/m_client.dart';
import 'package:mangayomi/yomihub/cloudscraper/cloudscraper.dart';

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
      _box = await Hive.openBox(_boxName);
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

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(milliseconds: 700), (_) => _check());
  }

  Future<void> _check() async {
    if (_done || _c == null) return;
    try {
      final cookies = await CookieManager.instance(
        webViewEnvironment: webViewEnvironment,
      ).getCookies(url: WebUri(widget.url), webViewController: _c);
      if (!cookies.any((c) => c.name == 'cf_clearance')) return;
      final title = await _c!.getTitle() ?? '';
      if (title.contains('Just a moment') || title.contains('Một chút')) {
        return;
      }
      _done = true;
      final ua =
          (await _c!.evaluateJavascript(source: 'navigator.userAgent'))
              ?.toString() ??
          '';
      await MClient.setCookie(widget.url, ua, _c);
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
        title: Text('Xác minh Cloudflare · $host'),
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
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(Icons.verified_user_outlined, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trang này yêu cầu xác minh. Nếu có ô "Xác minh bạn là con người", '
                      'hãy bấm vào; trang sẽ tự đóng khi xong.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: InAppWebView(
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
