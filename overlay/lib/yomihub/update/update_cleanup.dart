import 'dart:io';

import 'package:mangayomi/services/fetch_sources_list.dart' show compareVersions;
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// YomiHub 0.1.9: the update file is deleted once it has been installed.
///
/// Android replaces the running app while installing, so nothing can run
/// "after" the install in the old process. The downloaded file is recorded
/// before the installer opens; at the next launch, when the app's version is
/// the one of that file (or newer), the file is removed – together with any
/// half-downloaded `.part` and older YomiHub update files left in Download.
class YomiUpdateCleanup {
  YomiUpdateCleanup._();
  static const _key = 'pendingUpdateFile';
  static final _ver = RegExp(r'(\d+\.\d+\.\d+)');

  static Future<void> remember(File f) async {
    await YomiPrefs.set(_key, f.path);
  }

  static Future<void> run() async {
    try {
      final current = (await PackageInfo.fromPlatform()).version;
      final pending = YomiPrefs.get<String>(_key, '');
      final dirs = <Directory>{
        if (pending.isNotEmpty) File(pending).parent,
        if (Platform.isAndroid) Directory('/storage/emulated/0/Download'),
        if (Platform.isWindows && Platform.environment['USERPROFILE'] != null)
          Directory('${Platform.environment['USERPROFILE']}\\Downloads'),
      };
      var n = 0;
      for (final d in dirs) {
        if (!await d.exists()) continue;
        await for (final e in d.list(followLinks: false)) {
          if (e is! File) continue;
          final name = e.uri.pathSegments.last;
          if (!name.startsWith('YomiHub-')) continue;
          final isApk = name.endsWith('.apk') || name.endsWith('.apk.part');
          final isWin = name.endsWith('.zip') || name.endsWith('.zip.part') || name.endsWith('.exe');
          if (!isApk && !isWin) continue;
          final v = _ver.firstMatch(name)?.group(1);
          // an update that is installed (same or older than this app)
          if (v != null && compareVersions(current, v) >= 0) {
            try {
              await e.delete();
              n++;
            } catch (_) {}
          }
        }
      }
      if (pending.isNotEmpty) {
        final v = _ver.firstMatch(pending)?.group(1);
        if (v == null || compareVersions(current, v) >= 0 || !await File(pending).exists()) {
          await YomiPrefs.set(_key, null);
        }
      }
      if (n > 0) AppLogger.log('Update: removed $n installed update file(s)', logLevel: LogLevel.info);
    } catch (_) {}
  }
}
