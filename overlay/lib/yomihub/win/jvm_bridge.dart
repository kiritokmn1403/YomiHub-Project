import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:mangayomi/main.dart' show webViewEnvironment;
import 'package:mangayomi/services/http/m_client.dart' show yomiSolveCloudflare;
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/mes/yomi_mes.dart';
import 'package:mangayomi/yomihub/win/win_process.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// YomiHub 0.2.1: Kotatsu + IReader on Windows.
///
/// `yomihub_bin\bridge\lib` holds the YomiHub JVM bridge (tools/yomihub_bridge:
/// Kotatsu-Redo parsers + IReader desktop source-api). It runs on the Java
/// runtime of M-Extension-Server and serves the same loopback API as the
/// Android bridges (Kotatsu 47350, IReader 47360), so the generated
/// JavaScript extensions work unchanged.
///
/// Cloudflare: the bridge asks the app (loopback port 47351) to solve a
/// challenge in YomiHub's own WebView and gets the cookies + User-Agent back.
class YomiJvmBridge {
  YomiJvmBridge._();

  static const kotatsuPort = 47350;
  static const ireaderPort = 47360;
  static const cfPort = 47351;

  static WinProc? _proc;
  static Future<bool>? _starting;
  static HttpServer? _cf;
  static String lastError = '';

  static bool get supported => Platform.isWindows;

  static String get libDir => p.join(WinProc.binDir, 'bridge', 'lib');

  static Future<bool> _ping(int port, String path) async {
    try {
      final r = await http
          .get(Uri.parse('http://127.0.0.1:$port/$path/ping'))
          .timeout(const Duration(seconds: 2));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> get kotatsuReady => _ping(kotatsuPort, 'kotatsu');
  static Future<bool> get ireaderReady => _ping(ireaderPort, 'ireader');

  /// Starts the bridge once (concurrent callers share the start).
  static Future<bool> ensure() async {
    if (!supported) return false;
    if (_proc?.running == true && await kotatsuReady) return true;
    return _starting ??= _start().whenComplete(() => _starting = null);
  }

  static Future<bool> _start() async {
    if (await kotatsuReady) return true; // left over from a previous run
    if (!Directory(libDir).existsSync()) {
      lastError = tr('Thiếu thư mục yomihub_bin\\bridge – hãy cài lại YomiHub cho Windows.');
      return false;
    }
    if (!await YomiMes.locateWindows(jre: YomiMes.configuredJre, jar: YomiMes.configuredJar)) {
      lastError = tr('Kotatsu / IReader trên Windows cần Java của M-Extension-Server: vào Cài đặt › Duyệt › M-Extension-Server và bấm “Cài tự động”.');
      return false;
    }
    await _startCfServer();
    final data = Directory(p.join((await getApplicationSupportDirectory()).path, 'bridge'));
    await data.create(recursive: true);
    final java = WinProc.shortPath(YomiMes.winJava);
    final args = <String>[
      '-Xmx512m',
      '-XX:+UseSerialGC',
      '-Dfile.encoding=UTF-8',
      '-cp',
      '${WinProc.shortPath(libDir)}\\*',
      'yomihub.bridge.MainKt',
      '--data',
      WinProc.shortPath(data.path),
      '--parent',
      '$pid',
      '--cf',
      '$cfPort',
    ];
    try {
      _proc = await WinProc.start('bridge', java, args, workingDirectory: libDir);
    } catch (e) {
      lastError = tr('Không chạy được Java: {p0}', {'p0': e});
      return false;
    }
    for (var i = 0; i < 90; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (await kotatsuReady) {
        lastError = '';
        return true;
      }
      if (_proc?.running != true) break;
    }
    final log = _proc?.log.join('\n') ?? '';
    lastError = tr('Cầu nối Kotatsu/IReader không khởi động được') +
        (log.isEmpty ? '' : '\n${log.length > 600 ? log.substring(log.length - 600) : log}');
    AppLogger.log('JVM bridge: $lastError', logLevel: LogLevel.error);
    return false;
  }

  static Future<void> _startCfServer() async {
    if (_cf != null) return;
    try {
      _cf = await HttpServer.bind(InternetAddress.loopbackIPv4, cfPort);
    } catch (_) {
      return;
    }
    _cf!.listen((req) async {
      final res = req.response;
      try {
        final url = req.uri.queryParameters['url'] ?? '';
        Map<String, Object?> out = {'ok': false};
        if (req.uri.path == '/solveCf' && url.startsWith('http')) {
          final ua = await yomiSolveCloudflare(url);
          if (ua != null) {
            var cookies = '';
            try {
              final list = await CookieManager.instance(webViewEnvironment: webViewEnvironment)
                  .getCookies(url: WebUri(url));
              cookies = list.map((c) => '${c.name}=${c.value}').join('; ');
            } catch (_) {}
            out = {'ok': true, 'ua': ua, 'cookies': cookies};
          }
        }
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode(out));
      } catch (e) {
        res.statusCode = 500;
        res.write(jsonEncode({'ok': false, 'error': '$e'}));
      } finally {
        await res.close();
      }
    });
  }

  /// IReader: loads a desktop extension jar into the bridge.
  static Future<List<Map<String, dynamic>>> loadIReaderJar(String path) async {
    if (!await ensure()) throw Exception(lastError);
    final r = await http
        .get(Uri.parse('http://127.0.0.1:$ireaderPort/ireader/load?path=${Uri.encodeQueryComponent(path)}'))
        .timeout(const Duration(seconds: 90));
    final body = utf8.decode(r.bodyBytes);
    if (r.statusCode != 200) {
      String msg = body;
      try {
        msg = '${(jsonDecode(body) as Map)['error']}';
      } catch (_) {}
      throw Exception(msg);
    }
    return [for (final e in jsonDecode(body) as List) Map<String, dynamic>.from(e as Map)];
  }

  static Future<void> stop() async {
    await _proc?.kill();
    _proc = null;
    await _cf?.close(force: true);
    _cf = null;
  }
}
