import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:mangayomi/services/http/cf_proxy_store.dart';

/// YomiHub 0.1.4: CloudScraper (VeNoMouS/cloudscraper) in the app settings.
///
/// cloudscraper gets past Cloudflare by (1) looking like a real browser –
/// a consistent User-Agent plus the headers that browser sends, in its
/// order – and (2) solving the challenge page. YomiHub does the same:
///  * browser emulation profiles applied to extension requests that don't
///    set their own User-Agent / Accept headers;
///  * challenges are solved by a real browser engine (the built-in WebView,
///    like cloudscraper's JS interpreters) or by a FlareSolverr / Byparr
///    server (also handed to the M-Extension-Server for APK extensions);
///  * retries with a delay, as cloudscraper's `delay` option.
class CloudScraper {
  CloudScraper._();
  static const _boxName = 'yomihub_cloudscraper';
  static Box? _box;

  static bool enabled = true;

  /// 'webview' | 'flaresolverr' | 'off'
  static String solver = 'webview';
  static String browser = 'chrome';
  static String platform = Platform.isAndroid ? 'android' : 'windows';
  static int retries = 2;
  static int delayMs = 1500;

  static Future<void> open() async {
    if (_box != null) return;
    try {
      _box = await Hive.openBox(_boxName);
      enabled = _box!.get('enabled', defaultValue: true) as bool;
      solver = _box!.get('solver', defaultValue: CfProxyStore.url.isNotEmpty ? 'flaresolverr' : 'webview') as String;
      browser = _box!.get('browser', defaultValue: 'chrome') as String;
      platform = _box!.get('platform', defaultValue: platform) as String;
      retries = _box!.get('retries', defaultValue: 2) as int;
      delayMs = _box!.get('delayMs', defaultValue: 1500) as int;
    } catch (_) {}
  }

  static Future<void> save() async {
    await _box?.putAll({
      'enabled': enabled,
      'solver': solver,
      'browser': browser,
      'platform': platform,
      'retries': retries,
      'delayMs': delayMs,
    });
  }

  static const browsers = {'chrome': 'Chrome', 'firefox': 'Firefox'};
  static const platforms = {
    'android': 'Android',
    'windows': 'Windows',
    'linux': 'Linux',
    'darwin': 'macOS',
    'ios': 'iOS',
  };

  /// User-Agent of the emulated browser.
  static String get userAgent {
    const chrome = '140.0.0.0';
    const firefox = '143.0';
    if (browser == 'firefox') {
      return switch (platform) {
        'android' => 'Mozilla/5.0 (Android 14; Mobile; rv:$firefox) Gecko/$firefox Firefox/$firefox',
        'darwin' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:$firefox) Gecko/20100101 Firefox/$firefox',
        'linux' => 'Mozilla/5.0 (X11; Linux x86_64; rv:$firefox) Gecko/20100101 Firefox/$firefox',
        'ios' => 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/$firefox Mobile/15E148 Safari/605.1.15',
        _ => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:$firefox) Gecko/20100101 Firefox/$firefox',
      };
    }
    return switch (platform) {
      'android' => 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$chrome Mobile Safari/537.36',
      'darwin' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$chrome Safari/537.36',
      'linux' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$chrome Safari/537.36',
      'ios' => 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/$chrome Mobile/15E148 Safari/604.1',
      _ => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$chrome Safari/537.36',
    };
  }

  /// Headers the emulated browser sends with a page request (cloudscraper's
  /// browsers.json idea).
  static Map<String, String> get headers {
    final isMobile = platform == 'android' || platform == 'ios';
    if (browser == 'firefox') {
      return {
        'User-Agent': userAgent,
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7',
        'Upgrade-Insecure-Requests': '1',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none',
        'Sec-Fetch-User': '?1',
      };
    }
    return {
      'User-Agent': userAgent,
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
      'Accept-Language': 'vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7',
      'sec-ch-ua': '"Chromium";v="140", "Google Chrome";v="140", "Not;A=Brand";v="24"',
      'sec-ch-ua-mobile': isMobile ? '?1' : '?0',
      'sec-ch-ua-platform': '"${platforms[platform] ?? 'Windows'}"',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      'Sec-Fetch-User': '?1',
    };
  }

  /// Fills in the browser identity an extension didn't set itself
  /// (User-Agent, language, client hints). Accept / Sec-Fetch stay as the
  /// extension sends them, so JSON APIs keep answering JSON.
  static void applyTo(Map<String, String> requestHeaders) {
    if (!enabled) return;
    final lower = requestHeaders.keys.map((k) => k.toLowerCase()).toSet();
    headers.forEach((k, v) {
      final key = k.toLowerCase();
      if (key != 'user-agent' && key != 'accept-language' && !key.startsWith('sec-ch-ua')) return;
      if (!lower.contains(key)) requestHeaders[k] = v;
    });
  }

  /// FlareSolverr/Byparr URL to use, or '' (webview / off).
  static String get proxyUrl =>
      enabled && solver == 'flaresolverr' ? CfProxyStore.url.trim() : '';

  /// Checks a FlareSolverr/Byparr server; returns a status line.
  static Future<String> testProxy(String url) async {
    try {
      final r = await http
          .post(
            Uri.parse(url),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'cmd': 'sessions.list'}),
          )
          .timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body);
        return 'Kết nối được • ${d['version'] ?? d['message'] ?? 'OK'}';
      }
      return 'HTTP ${r.statusCode}';
    } catch (e) {
      return 'Không kết nối được: $e';
    }
  }
}
