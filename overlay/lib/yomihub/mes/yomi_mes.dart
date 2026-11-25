import 'package:mangayomi/yomihub/prefs/yomi_hive.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:async';
import 'dart:io';

import 'dart:convert';

import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:mangayomi/yomihub/cloudscraper/cloudscraper.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/yomihub/win/win_process.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:m_extension_server/m_extension_server.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 0.6.6 (logs 16, 25/11 15:35–16:33): every Mihon/Aniyomi source on Windows
/// failed with "M-Extension-Server chưa chạy" (AVSub, Anime47, Xvideos,
/// MissAV, CBHentai …) and the error was logged once per source and call.
/// Thrown by [YomiMes.dalvik] when no extension bridge can be reached, so
/// callers (isolate service, Đề Xuất) log it once per session instead.
class MesUnavailableException implements Exception {
  MesUnavailableException(this.message, {this.installing = false});
  final String message;

  /// YomiHub is downloading the Windows bundle in the background.
  final bool installing;

  static bool _logged = false;

  /// true the first time in this run (callers log only then).
  static bool firstInSession() {
    if (_logged) return false;
    _logged = true;
    return true;
  }

  @override
  String toString() => message;
}

/// YomiHub: M-Extension-Server built into the app.
///
/// On Android the Mihon / Aniyomi APK extensions are loaded in-process by the
/// embedded Dalvik bridge (NanoHTTPD on loopback, classes loaded with a
/// child-first PathClassLoader), so no separate "MExtension Server" app is
/// needed. This class owns its lifecycle: a stable port, health checks,
/// automatic restart when the bridge dies, and routing every APK-extension
/// request to it.
class YomiMes {
  YomiMes._();

  static const preferredPort = 47321;
  static const _boxName = 'yomihub_mes';
  static const _vpn = MethodChannel('yomihub/vpn');

  static Box? _box;
  static String? _base;
  static Future<String?>? _starting;
  static int restarts = 0;
  static DateTime? startedAt;
  static String? lastError;

  /// Called with the new base URL every time the embedded bridge (re)starts,
  /// so the settings provider can follow it.
  static void Function(String url)? onUrl;

  /// 0.1.7: Windows too – YomiHub runs the desktop M-Extension-Server
  /// (Java) itself: bundled in `yomihub_bin\mes`, or installed with one tap.
  static bool get supported => Platform.isAndroid || Platform.isWindows;

  /// Windows JVM process.
  static WinProc? _winProc;

  /// Windows: where java.exe / the server JAR were found ('' = not installed).
  static String winJava = '';
  static String winJar = '';

  /// Proxy the Windows JVM was started with ('' = direct).
  static String _winJvmProxy = '';

  /// Remote ApkBridge / M-Extension-Server typed by the user (Windows
  /// "ApkBridge" mode, or Android external server).
  static String get remoteUrl => _box?.get('remote', defaultValue: '') ?? '';
  static Future<void> setRemoteUrl(String v) async {
    await open();
    await _box?.put('remote', v.trim());
  }


  /// Whether the built-in bridge is in use (default) rather than an external
  /// server address typed by the user.
  static bool get embedded => _box?.get('embedded', defaultValue: true) ?? true;

  static bool get active => supported && embedded;

  static String? get baseUrl => _base;

  static final http.Client _local = http.Client();

  /// Plain loopback client: never routed through Tor / custom proxy, which
  /// would make 127.0.0.1 unreachable.
  static http.Client get localClient => _local;

  static Future<void> open() async {
    // 0.1.8: start-up callers came before Hive.initFlutter (HiveError), which
    // left the built-in bridge switched off on Windows
    if (_box == null && !YomiPrefs.isOpen) {
      await YomiPrefs.ready.timeout(const Duration(seconds: 30), onTimeout: () {});
    }
    try {
      _box ??= Hive.isBoxOpen(_boxName)
          ? Hive.box(_boxName)
          : await YomiHive.open(_boxName);
    } catch (_) {}
  }

  static Future<void> setEmbedded(bool value) async {
    await open();
    await _box?.put('embedded', value);
    if (value) {
      await ensure();
    } else {
      await stop();
    }
  }

  static Future<bool> alive(String base) async {
    try {
      final res = await _local
          .get(Uri.parse('$base/capabilities'))
          .timeout(const Duration(milliseconds: 1500));
      return res.statusCode == 200 && res.body.contains('mangayomiMihonBridge');
    } catch (_) {
      return false;
    }
  }

  /// Any bridge answering: M-Extension-Server (/capabilities) or the
  /// ApkBridge app (plain "/" answers 200).
  static Future<bool> aliveAny(String base) async {
    if (await alive(base)) return true;
    try {
      final res = await _local.get(Uri.parse('$base/')).timeout(const Duration(milliseconds: 1500));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Looks for ApkBridge / YomiHub (Android) bridges on the local network:
  /// ports 47321 (YomiHub, M-Extension-Server) and 8080 (ApkBridge app).
  static Future<List<String>> scanLan({void Function(double)? progress}) async {
    final found = <String>[];
    final ifs = await NetworkInterface.list(type: InternetAddressType.IPv4);
    final prefixes = <String>{
      for (final i in ifs)
        for (final a in i.addresses)
          if (!a.isLoopback && (a.address.startsWith('192.168.') || a.address.startsWith('10.') || a.address.startsWith('172.')))
            a.address.substring(0, a.address.lastIndexOf('.')),
    };
    final own = {for (final i in ifs) for (final a in i.addresses) a.address};
    final targets = <(String, int)>[
      for (final pre in prefixes)
        for (var h = 1; h < 255; h++)
          if (!own.contains('$pre.$h'))
            for (final port in const [preferredPort, 8080]) ('$pre.$h', port),
    ];
    var done = 0;
    Future<void> probe((String, int) t) async {
      try {
        final s = await Socket.connect(t.$1, t.$2, timeout: const Duration(milliseconds: 350));
        s.destroy();
        final url = 'http://${t.$1}:${t.$2}';
        if (await aliveAny(url)) found.add(url);
      } catch (_) {}
      done++;
      progress?.call(targets.isEmpty ? 1 : done / targets.length);
    }

    for (var i = 0; i < targets.length; i += 64) {
      await Future.wait(targets.skip(i).take(64).map(probe));
    }
    return found;
  }

  static bool isLoopback(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    return host == '127.0.0.1' || host == 'localhost' || host == '::1';
  }

  /// Makes sure the embedded bridge is up and returns its base URL, or null
  /// when the built-in bridge is disabled / unsupported / failed to start.
  static Future<String?> ensure({bool restart = false}) async {
    if (!supported) return null;
    await open();
    if (!embedded) return null;
    if (!restart && _base != null && await alive(_base!)) return _base;
    return _starting ??= _start().whenComplete(() => _starting = null);
  }

  static Future<String?> _start() async {
    if (Platform.isWindows) return _startWindows();
    final hadServer = _base != null;
    try {
      await MExtensionServer().stopServer();
    } catch (_) {}
    _base = null;
    for (var attempt = 0; attempt < 4; attempt++) {
      final port = attempt == 0 ? preferredPort : await _freePort();
      if (port == null) continue;
      if (attempt == 0 && !await _portFree(port)) continue;
      try {
        await MExtensionServer().startServer(port);
      } catch (e) {
        lastError = '$e';
        continue;
      }
      final url = 'http://127.0.0.1:$port';
      for (var i = 0; i < 20; i++) {
        if (await alive(url)) {
          _base = url;
          startedAt = DateTime.now();
          if (hadServer) restarts++;
          lastError = null;
          onUrl?.call(url);
          return url;
        }
        await Future.delayed(const Duration(milliseconds: 250));
      }
      lastError = tr('Không phản hồi trên cổng {p0}', {'p0': port});
      try {
        await MExtensionServer().stopServer();
      } catch (_) {}
    }
    return null;
  }

  static Future<void> stop() async {
    if (Platform.isWindows) {
      await _winProc?.kill();
      _winProc = null;
      _base = null;
      return;
    }
    try {
      await MExtensionServer().stopServer();
    } catch (_) {}
    _base = null;
  }

  // ───────────── Windows ─────────────

  static Future<Directory> _winInstallDir() async {
    final base = await getApplicationSupportDirectory();
    return Directory(p.join(base.path, 'mes'));
  }

  /// Finds java(w).exe and MExtensionServer-*.jar: bundled next to
  /// YomiHub.exe first, then the copy installed by [installWindows], then a
  /// location chosen in Mangayomi's own extension-server screen.
  static Future<bool> locateWindows({String? jre, String? jar}) async {
    Future<(String, String)?> scan(Directory root) async {
      if (!await root.exists()) return null;
      String java = '', server = '';
      await for (final e in root.list(recursive: true, followLinks: false)) {
        if (e is! File) continue;
        final n = p.basename(e.path).toLowerCase();
        if (n == 'javaw.exe' || (n == 'java.exe' && java.isEmpty)) java = e.path;
        if (n.startsWith('mextensionserver') && n.endsWith('.jar')) server = e.path;
      }
      return java.isNotEmpty && server.isNotEmpty ? (java, server) : null;
    }

    final found = await scan(Directory(p.join(WinProc.binDir, 'mes'))) ?? await scan(await _winInstallDir());
    if (found != null) {
      winJava = found.$1;
      winJar = found.$2;
      return true;
    }
    if ((jre ?? '').isNotEmpty && (jar ?? '').isNotEmpty && File(jre!).existsSync() && File(jar!).existsSync()) {
      final javaw = p.join(p.dirname(jre), 'javaw.exe');
      winJava = File(javaw).existsSync() ? javaw : jre;
      winJar = jar;
      return true;
    }
    winJava = winJar = '';
    return false;
  }

  /// Settings from Mangayomi's extension-server screen (jrePath / jar).
  static String? configuredJre, configuredJar;

  static Future<String?> _startWindows() async {
    final hadServer = _base != null;
    await stop();
    if (!await locateWindows(jre: configuredJre, jar: configuredJar)) {
      lastError = tr('Chưa cài M-Extension-Server cho Windows – bấm “Cài tự động”.');
      return null;
    }
    final port = await WinProc.freePort(preferredPort);
    final dataDir = Directory(p.join((await _winInstallDir()).path, 'data'));
    await dataDir.create(recursive: true);
    final args = <String>[
      '-Xmx768m',
      '-Dfile.encoding=UTF-8',
      // 0.6.5 (log 14, CBHentai on Windows): classes converted from an APK's
      // dex fail the JVM verifier ("VerifyError: Bad type on operand stack in
      // putfield") although ART runs them fine. Extension classes are loaded
      // by the server's own class loader, so skipping verification of
      // non-bootstrap classes is enough; the JDK itself is still verified.
      '-XX:-BytecodeVerificationRemote',
      ..._jvmProxyArgs(_winJvmProxy),
      '-jar',
      WinProc.shortPath(winJar),
      '$port',
      WinProc.shortPath(dataDir.path),
    ];
    try {
      _winProc = await WinProc.start('mes', WinProc.shortPath(winJava), args, workingDirectory: p.dirname(winJar));
    } catch (e) {
      lastError = tr('Không chạy được Java: {p0}', {'p0': e});
      return null;
    }
    final url = 'http://127.0.0.1:$port';
    // The JVM needs a few seconds (more on the first run).
    for (var i = 0; i < 120; i++) {
      if (await alive(url)) {
        _base = url;
        startedAt = DateTime.now();
        if (hadServer) restarts++;
        lastError = null;
        onUrl?.call(url);
        return url;
      }
      if (!(_winProc?.alive ?? false)) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    final log = _winProc?.log.reversed.take(5).toList().reversed.join('\n') ?? '';
    lastError = tr('M-Extension-Server không phản hồi{p0}', {'p0': log.isEmpty ? '' : ':\n$log'});
    await stop();
    return null;
  }

  static List<String> _jvmProxyArgs(String url) {
    if (url.isEmpty) return const [];
    final u = Uri.tryParse(url);
    if (u == null || u.host.isEmpty) return const [];
    if (u.scheme.startsWith('socks')) {
      return ['-DsocksProxyHost=${u.host}', '-DsocksProxyPort=${u.port}'];
    }
    return [
      '-Dhttp.proxyHost=${u.host}',
      '-Dhttp.proxyPort=${u.port}',
      '-Dhttps.proxyHost=${u.host}',
      '-Dhttps.proxyPort=${u.port}',
      '-Dhttp.nonProxyHosts=localhost|127.*',
    ];
  }

  /// Downloads the latest Windows bundle (JRE + server JAR, ~130 MB) from
  /// kodjodevf/M-Extension-Server and unpacks it for YomiHub.
  static Future<String?>? _installing;

  /// Manual (settings) and automatic installs share one download
  /// (Codex B2: two writers of bundle.zip.part at once).
  static Future<String?> installWindows({void Function(int received, int total)? progress}) {
    return _installing ??= _installWindows(progress: progress).whenComplete(() => _installing = null);
  }

  static Future<String?> _installWindows({void Function(int received, int total)? progress}) async {
    final client = http.Client();
    try {
      final rel = await client.get(
        Uri.parse('https://api.github.com/repos/kodjodevf/M-Extension-Server/releases?per_page=10'),
        headers: const {'Accept': 'application/vnd.github+json'},
      ).timeout(const Duration(seconds: 30));
      if (rel.statusCode != 200) return tr('GitHub trả lỗi HTTP {p0}', {'p0': rel.statusCode});
      String? url;
      for (final r in jsonDecode(rel.body) as List) {
        if (r['draft'] == true || '${r['tag_name']}'.startsWith('ios-')) continue;
        for (final a in (r['assets'] as List)) {
          if (a['name'] == 'windows-x64-bundle.zip') {
            url = a['browser_download_url'];
            break;
          }
        }
        if (url != null) break;
      }
      if (url == null) return tr('Không tìm thấy gói windows-x64-bundle.zip');
      final dir = await _winInstallDir();
      await dir.create(recursive: true);
      final zip = File(p.join(dir.path, 'bundle.zip.part'));
      final res = await client.send(http.Request('GET', Uri.parse(url))).timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) return tr('Tải gói lỗi HTTP {p0}', {'p0': res.statusCode});
      final total = res.contentLength ?? 0;
      var got = 0;
      final sink = zip.openWrite();
      try {
        // a stalled download ends after 45 s without data instead of hanging
        await for (final chunk in res.stream.timeout(const Duration(seconds: 45))) {
          sink.add(chunk);
          got += chunk.length;
          progress?.call(got, total);
        }
      } finally {
        await sink.close();
      }
      if (total > 0 && got != total) {
        return tr('Tải gói chưa đủ ({p0}/{p1} byte) – thử lại', {'p0': got, 'p1': total});
      }
      await stop();
      for (final old in ['jre', 'app']) {
        final d = Directory(p.join(dir.path, old));
        if (await d.exists()) await d.delete(recursive: true);
      }
      await for (final e in dir.list()) {
        if (e is File && p.basename(e.path).toLowerCase().endsWith('.jar')) await e.delete();
      }
      await extractFileToDisk(zip.path, dir.path);
      await zip.delete();
      return await locateWindows() ? null : tr('Gói tải về không có java.exe / MExtensionServer.jar');
    } catch (e) {
      return '$e';
    } finally {
      client.close();
    }
  }

  static Future<bool> _portFree(int port) async {
    try {
      final s = await ServerSocket.bind(InternetAddress.anyIPv6, port);
      await s.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<int?> _freePort() async {
    try {
      final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final p = s.port;
      await s.close();
      return p;
    } catch (_) {
      return null;
    }
  }

  /// The base URL APK-extension requests should use.
  static String resolve(String configured) {
    if (active && _base != null) return _base!;
    if (supported && !embedded && remoteUrl.isNotEmpty) return remoteUrl;
    return configured;
  }

  /// POSTs one bridge call, restarting the embedded bridge and retrying once
  /// when it is not reachable.
  static Future<http.Response> dalvik(
    String configured,
    String body, {
    Map<String, String>? headers,
    Duration timeout = const Duration(minutes: 3),
  }) async {
    if (active && _base == null) await ensure();
    String? alt;
    if (Platform.isWindows && active && _base == null) {
      // 0.6.6: an ApkBridge / external server the user set up (or the
      // ApkBridge app on this PC, port 8080) keeps APK sources working
      // while the built-in server is missing or down.
      alt = await fallbackBridge();
      if (alt == null) {
        if (winJar.isEmpty && !_autoInstallFailed) {
          unawaited(autoInstallWindows());
          throw MesUnavailableException(
            tr('M-Extension-Server chưa cài trên Windows – YomiHub đang tự tải và cài ({p0}). Thử lại sau khi cài xong, hoặc dùng ApkBridge (Cài đặt › Duyệt › M-Extension-Server).',
                {'p0': autoInstallText}),
            installing: true,
          );
        }
        throw MesUnavailableException(
          tr('M-Extension-Server chưa chạy: {p0} (Cài đặt › Duyệt › M-Extension-Server để cài hoặc chuyển sang ApkBridge).', {'p0': lastError ?? ''}),
        );
      }
    }
    final h = {
      'content-type': 'application/json',
      // CloudScraper › FlareSolverr/Byparr for APK extensions (MES 0.1.0+)
      if (CloudScraper.proxyUrl.isNotEmpty) 'cf-proxy-url': CloudScraper.proxyUrl,
      ...?headers,
    };
    final base = alt ?? resolve(configured);
    try {
      final res = await _local
          .post(Uri.parse('$base/dalvik'), body: body, headers: h)
          .timeout(timeout);
      if (Platform.isWindows && alt == null && active && needsAndroidRuntime(res.body)) {
        // 0.6.6: retry once on the user's ApkBridge (Android phone) if set.
        final remote = await fallbackBridge();
        if (remote != null) {
          try {
            final r2 = await _local.post(Uri.parse('$remote/dalvik'), body: body, headers: h).timeout(timeout);
            AppLogger.logOnce('mes-android-fallback',
                '[M-Extension-Server] Tiện ích APK cần Android – đã chuyển sang ApkBridge đã lưu ($remote)',
                logLevel: LogLevel.info);
            return r2;
          } catch (_) {}
        }
      }
      return res;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      if (!active) rethrow;
      final nb = await ensure(restart: true);
      if (nb == null) rethrow;
      return _local
          .post(Uri.parse('$nb/dalvik'), body: body, headers: h)
          .timeout(timeout);
    }
  }

  // ───────────── 0.6.6: auto-install + ApkBridge fallback (Windows) ─────────────

  static Future<String?>? _autoInstall;
  static bool _autoInstallFailed = false;
  static double? autoInstallProgress;
  static int _autoInstallGot = 0;

  /// Short progress text for messages ("12.3 / 131.0 MB", "đang bắt đầu").
  static String get autoInstallText {
    if (_autoInstall == null) return tr('đang bắt đầu');
    final mb = (_autoInstallGot / 1048576).toStringAsFixed(1);
    final pc = autoInstallProgress == null ? '' : ' – ${(autoInstallProgress! * 100).round()}%';
    return '$mb MB$pc';
  }

  static bool get autoInstalling => _autoInstall != null;

  /// Downloads and starts the Windows M-Extension-Server once, in the
  /// background, the first time an APK source needs it. A failure is
  /// remembered for this run (no download loop); the settings screen can
  /// still install it by hand.
  static Future<String?> autoInstallWindows() {
    if (!Platform.isWindows || _autoInstallFailed) return Future.value(null);
    return _autoInstall ??= () async {
      AppLogger.log('[M-Extension-Server] Chưa cài trên Windows – tự tải gói windows-x64-bundle.zip và cài nền (một lần)',
          logLevel: LogLevel.info);
      final sw = Stopwatch()..start();
      final err = await installWindows(progress: (got, total) {
        _autoInstallGot = got;
        autoInstallProgress = total > 0 ? got / total : null;
      });
      if (err != null) {
        _autoInstallFailed = true;
        AppLogger.log('[M-Extension-Server] Tự cài thất bại: $err – vào Cài đặt › Duyệt › M-Extension-Server để cài lại hoặc dùng ApkBridge',
            logLevel: LogLevel.warning);
        return err;
      }
      final url = await ensure(restart: true);
      AppLogger.log(
          url == null
              ? '[M-Extension-Server] Đã cài (${sw.elapsed.inSeconds} s) nhưng chưa khởi động được: ${lastError ?? ''}'
              : '[M-Extension-Server] Đã tự cài và khởi động trong ${sw.elapsed.inSeconds} s: $url',
          logLevel: url == null ? LogLevel.warning : LogLevel.info);
      return url == null ? lastError : null;
    }()
        .whenComplete(() {
      _autoInstall = null;
      autoInstallProgress = null;
    });
  }

  static String? _altBridge;
  static DateTime? _altCheckedAt;

  /// The ApkBridge / external M-Extension-Server address the user saved in
  /// settings, when it answers. Only that saved address is used
  /// automatically (Codex B2 review: never an arbitrary local port that
  /// happens to return HTTP 200). Cached for 60 s so a burst of source calls
  /// probes once.
  static Future<String?> fallbackBridge() async {
    final now = DateTime.now();
    if (_altCheckedAt != null && now.difference(_altCheckedAt!) < const Duration(seconds: 60)) return _altBridge;
    _altCheckedAt = now;
    _altBridge = null;
    final u = remoteUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(u);
    if (u.isEmpty || uri == null || !const ['http', 'https'].contains(uri.scheme) || uri.host.isEmpty || u == _base) {
      return null;
    }
    if (await aliveAny(u)) _altBridge = u;
    return _altBridge;
  }

  /// The Windows (Java) server answered with an error only an Android
  /// runtime avoids (dex converted for the JVM fails verification, or the
  /// extension needs android.* classes) – logs 16: CBHentai, Manga Ball,
  /// DamCoNuong, AVSub.
  static bool needsAndroidRuntime(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map || decoded['error'] == null) return false;
      final error = decoded['error'].toString().toLowerCase();
      return error.contains('verifyerror') ||
          error.contains('bad type on operand stack') ||
          error.contains('cannot be cast to class') ||
          RegExp(r'^\s*android\.(app|content|webkit|os)\.').hasMatch(error);
    } catch (_) {
      return false;
    }
  }

  /// Routes the extension bridge's own OkHttp traffic (inside the JVM)
  /// through Tor / the custom proxy when that applies to every source.
  static Future<void> setJvmProxy(String? proxyUrl) async {
    if (!supported) return;
    if (Platform.isWindows) {
      final v = proxyUrl ?? '';
      if (v == _winJvmProxy) return;
      _winJvmProxy = v;
      // the JVM reads its proxy at start-up: restart it when it is running
      if (_winProc?.alive ?? false) await ensure(restart: true);
      return;
    }
    try {
      await _vpn.invokeMethod('jvmProxy', {'url': proxyUrl ?? ''});
    } catch (_) {}
  }

  /// 0.6.3: hosts of APK extensions that the ISP blocks go through Tor
  /// ([torProxy] '' = Tor not connected → direct). Android only (the
  /// Windows M-Extension-Server JVM reads its proxy at start-up).
  static Future<void> setJvmAutoTor(String torProxy, List<String> hosts) async {
    if (!Platform.isAndroid) return;
    try {
      await _vpn.invokeMethod('jvmAutoTor', {'url': torProxy, 'hosts': hosts});
    } catch (_) {}
  }
}
