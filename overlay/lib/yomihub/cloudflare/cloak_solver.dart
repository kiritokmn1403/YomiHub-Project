import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:mangayomi/services/http/m_client.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';
import 'package:path_provider/path_provider.dart';

/// YomiHub 0.1.8: CloakBrowser as a Cloudflare solver (Windows).
///
/// CloakBrowser (CloakHQ) is a Chromium with fingerprint patches at the C++
/// level; its wrappers launch it with a random `--fingerprint` seed and a
/// Windows fingerprint profile, headed, and drive it over CDP. YomiHub does
/// the same with the CloakBrowser binary the user installed
/// (`pip install cloakbrowser` / `npm i cloakbrowser`, which keeps it in
/// `%USERPROFILE%\.cloakbrowser`, or any path chosen in the settings):
/// it opens the protected page in a small CloakBrowser window, waits for
/// `cf_clearance` through the DevTools protocol and hands the cookies and the
/// browser's User-Agent to the extensions, like the FlareSolverr mode.
/// The binary is never downloaded or redistributed by YomiHub (its licence
/// is CloakHQ's).
class YomiCloak {
  YomiCloak._();
  static final _rnd = Random();

  static String get customPath => YomiPrefs.get<String>('cloakPath', '');
  static bool get humanize => YomiPrefs.get<bool>('cfHumanize', true);

  /// The CloakBrowser chrome.exe, or null.
  static Future<String?> findBinary() async {
    if (!Platform.isWindows) return null;
    if (customPath.isNotEmpty && await File(customPath).exists()) return customPath;
    final home = Platform.environment['USERPROFILE'] ?? '';
    final dirs = <String>[
      if (Platform.environment['CLOAKBROWSER_CACHE_DIR'] != null) Platform.environment['CLOAKBROWSER_CACHE_DIR']!,
      '$home\\.cloakbrowser',
    ];
    for (final d in dirs) {
      final dir = Directory(d);
      if (!await dir.exists()) continue;
      final found = <File>[];
      await for (final e in dir.list(recursive: true, followLinks: false)) {
        if (e is File && e.path.toLowerCase().endsWith('\\chrome.exe')) found.add(e);
      }
      if (found.isNotEmpty) {
        found.sort((a, b) => b.path.compareTo(a.path)); // newest version first
        return found.first.path;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _json(int port, String path) async {
    try {
      final c = HttpClient()..connectionTimeout = const Duration(seconds: 2);
      final r = await (await c.getUrl(Uri.parse('http://127.0.0.1:$port$path'))).close();
      final body = await r.transform(utf8.decoder).join();
      c.close(force: true);
      final j = jsonDecode(body);
      if (j is List && j.isNotEmpty) return Map<String, dynamic>.from(j.first as Map);
      if (j is Map) return Map<String, dynamic>.from(j);
    } catch (_) {}
    return null;
  }

  /// Opens [url] in CloakBrowser until Cloudflare hands out `cf_clearance`.
  static Future<bool> solve(String url, {Duration timeout = const Duration(seconds: 75)}) async {
    final exe = await findBinary();
    if (exe == null) return false;
    final port = 39200 + _rnd.nextInt(700);
    final profile = '${(await getApplicationSupportDirectory()).path}\\cloakbrowser_profile';
    final args = <String>[
      '--remote-debugging-port=$port',
      '--user-data-dir=$profile',
      '--fingerprint=${10000 + _rnd.nextInt(89999)}',
      '--fingerprint-platform=windows',
      '--no-first-run',
      '--no-default-browser-check',
      '--window-size=520,640',
      if (YomiVpnState.proxyEnabled && YomiVpnState.proxyUrl.isNotEmpty)
        '--proxy-server=${YomiVpnState.proxyUrl.replaceFirst(RegExp(r'//[^@/]*@'), '//')}',
      url,
    ];
    Process? proc;
    WebSocket? ws;
    try {
      proc = await Process.start(exe, args);
      final deadline = DateTime.now().add(timeout);
      Map<String, dynamic>? page;
      while (page == null && DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 500));
        page = await _json(port, '/json/list');
        if (page != null && page['type'] != 'page') page = null;
      }
      if (page == null) return false;
      ws = await WebSocket.connect('${page['webSocketDebuggerUrl']}');
      var id = 0;
      final pending = <int, Completer<Map>>{};
      ws.listen((m) {
        final j = jsonDecode('$m') as Map;
        final c = pending.remove(j['id']);
        if (c != null) c.complete(j);
      });
      Future<Map> send(String method, [Map<String, dynamic>? params]) {
        final c = Completer<Map>();
        pending[++id] = c;
        ws!.add(jsonEncode({'id': id, 'method': method, 'params': ?params}));
        return c.future.timeout(const Duration(seconds: 10));
      }

      while (DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 900));
        final r = await send('Network.getCookies', {'urls': [url]});
        final cookies = ((r['result'] ?? const {})['cookies'] as List? ?? const []).cast<Map>();
        if (!cookies.any((c) => c['name'] == 'cf_clearance')) continue;
        final t = await send('Runtime.evaluate', {'expression': 'document.title', 'returnByValue': true});
        final title = '${(((t['result'] ?? {})['result'] ?? {})['value']) ?? ''}';
        if (title.contains('Just a moment') || title.contains('Một chút')) continue;
        final u = await send('Runtime.evaluate', {'expression': 'navigator.userAgent', 'returnByValue': true});
        final ua = '${(((u['result'] ?? {})['result'] ?? {})['value']) ?? ''}';
        final cookie = cookies.map((c) => '${c['name']}=${c['value']}').join('; ');
        await MClient.setCookie(url, ua, null, cookie: cookie);
        AppLogger.log('CloakBrowser solved ${Uri.parse(url).host}', logLevel: LogLevel.warning);
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.log('CloakBrowser solver: $e', logLevel: LogLevel.error);
      return false;
    } finally {
      try {
        await ws?.close();
      } catch (_) {}
      proc?.kill();
    }
  }
}
