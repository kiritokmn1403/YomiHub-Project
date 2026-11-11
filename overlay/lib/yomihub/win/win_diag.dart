// YomiHub 0.5.2 – Windows start-up diagnostics.
//
// Sheet "YomiHub Update": "Ứng dụng trên phiên bản Windows, đặc biệt là AMD
// Ryzen 9 bị lỗi không có đầy đủ tính năng". The build PC (Intel i5-11300H)
// has Visual Studio, a JDK and WebView2, so everything worked there; on a new
// PC the light Setup/portable package had no Java (Mihon/Aniyomi ApkBridge,
// Kotatsu, IReader unavailable) and relied on a system VC++ runtime.
// Packaging now ships both; this writes, once per app version, what this PC
// has and which features a missing component would switch off, so a report
// from any machine (Ryzen or not) can be read from the app log alone.
import 'dart:async';
import 'dart:io';

import 'package:mangayomi/repositories/settings_repository.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/app_identity.dart';
import 'package:mangayomi/yomihub/mes/yomi_mes.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:path/path.dart' as p;

class WinDiag {
  WinDiag._();

  /// Result of the last run (shown in tests / logs).
  static final List<String> problems = [];

  /// 0.5.3: the last "[Windows] Chẩn đoán" line, shown in Settings.
  static String summary = '';

  /// Detected CPU string
  static String detectedCpu = '';

  static bool get isAmdCpu =>
      detectedCpu.toLowerCase().contains('amd') ||
      detectedCpu.toLowerCase().contains('ryzen');

  static bool get isHighThreadCount => Platform.numberOfProcessors >= 12;

  static Future<String> _reg(String key, String value) async {
    try {
      final r = await Process.run('reg', ['query', key, '/v', value])
          .timeout(const Duration(seconds: 8));
      final m = RegExp('$value\\s+REG_\\w+\\s+(.+)').firstMatch('${r.stdout}');
      return m?.group(1)?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<String> _gpu() async {
    try {
      final r = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        '(Get-CimInstance Win32_VideoController | ForEach-Object { \$_.Name + " " + \$_.DriverVersion }) -join "; "',
      ]).timeout(const Duration(seconds: 15));
      return '${r.stdout}'.trim();
    } catch (_) {
      return '';
    }
  }

  /// Missing files next to YomiHub.exe → the features they switch off.
  static List<String> checkFiles(String exeDir) {
    final out = <String>[];
    bool has(String rel) => File(p.join(exeDir, rel)).existsSync();
    final sys32 = p.join(Platform.environment['SystemRoot'] ?? r'C:\Windows', 'System32');
    for (final dll in ['vcruntime140.dll', 'vcruntime140_1.dll', 'msvcp140.dll']) {
      if (!has(dll) && !File(p.join(sys32, dll)).existsSync()) {
        out.add('thiếu $dll (VC++ 2015-2022) – lõi Rust, cơ sở dữ liệu, torrent, trình phát có thể không chạy');
      }
    }
    if (!has(p.join('yomihub_bin', 'xray.exe'))) out.add('thiếu yomihub_bin\\xray.exe – WARP/VPN & DNS không chạy');
    if (!has(p.join('yomihub_bin', 'tor', 'tor.exe'))) out.add('thiếu yomihub_bin\\tor\\tor.exe – Tor không chạy');
    if (!Directory(p.join(exeDir, 'yomihub_bin', 'bridge', 'lib')).existsSync()) {
      out.add('thiếu yomihub_bin\\bridge – nguồn Kotatsu / IReader không chạy');
    }
    if (!has('libmpv-2.dll')) out.add('thiếu libmpv-2.dll – không phát được video');
    return out;
  }

  /// Runs in the background once per app version (or when [force]).
  static Future<void> runOnce({bool force = false}) async {
    if (!Platform.isWindows) return;
    final key = 'winDiag:${AppIdentity.userAgent}';
    if (!force && YomiPrefs.get(key, false) == true) return;
    try {
      final env = Platform.environment;
      final exeDir = p.dirname(Platform.resolvedExecutable);
      final cpu = (await _reg(r'HKLM\HARDWARE\DESCRIPTION\System\CentralProcessor\0', 'ProcessorNameString'))
          .ifEmpty(env['PROCESSOR_IDENTIFIER'] ?? '?');
      detectedCpu = cpu;
      final arch = env['PROCESSOR_ARCHITEW6432'] ?? env['PROCESSOR_ARCHITECTURE'] ?? '?';
      final gpu = await _gpu();
      final wv2 = (await _reg(r'HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}', 'pv'))
          .ifEmpty(await _reg(r'HKCU\Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}', 'pv'));
      final java = await YomiMes.locateWindows(jre: YomiMes.configuredJre, jar: YomiMes.configuredJar);
      problems
        ..clear()
        ..addAll(checkFiles(exeDir));
      if (wv2.isEmpty || wv2 == '0.0.0.0') {
        problems.add('chưa có Microsoft Edge WebView2 Runtime – trình duyệt trong app, vượt Cloudflare, đăng nhập tiện ích không chạy (cài từ go.microsoft.com/fwlink/p/?LinkId=2124703)');
      }
      if (!java) {
        problems.add('chưa có Java của M-Extension-Server – tiện ích Mihon/Aniyomi (ApkBridge), Kotatsu, IReader không chạy (Cài đặt › Duyệt › M-Extension-Server › Cài tự động, hoặc dùng gói Setup/-full)');
      }
      summary = '${Platform.operatingSystemVersion} • CPU $cpu ($arch, ${Platform.numberOfProcessors} luồng)'
          '${gpu.isEmpty ? '' : ' • GPU $gpu'} • WebView2 ${wv2.isEmpty ? 'không có' : wv2}'
          ' • Java ${java ? 'có' : 'không'} • thư mục $exeDir';
      AppLogger.log(
        '[Windows] Chẩn đoán: $summary',
        logLevel: LogLevel.info, always: true,
      );
      if (cpu.toLowerCase().contains('ryzen') || cpu.toLowerCase().contains('amd')) {
        final s = await settingsRepository.currentAsync;
        final hwdec = s?.hwdecMode ?? 'auto';
        final hwAccel = s?.enableHardwareAcceleration ?? true;
        AppLogger.log(
          '[Windows] Phát hiện vi xử lý AMD ($cpu - ${Platform.numberOfProcessors} luồng): Thiết lập video hiện tại hwdec=$hwdec, tăng tốc phần cứng=${hwAccel ? "bật" : "tắt (fallback phần mềm)"}. Nếu GPU/driver gặp sự cố giải mã Direct3D 11, chuyển Tăng tốc phần cứng sang Tắt để kích hoạt fallback giải mã CPU đa luồng.',
          logLevel: LogLevel.info, always: true,
        );
      }
      for (final m in problems) {
        AppLogger.log('[Windows] Thiếu thành phần: $m', logLevel: LogLevel.warning);
      }
      await YomiPrefs.set(key, true);
    } catch (e) {
      AppLogger.log('[Windows] Không chạy được chẩn đoán: $e', logLevel: LogLevel.info);
    }
  }
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}
