import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:mangayomi/utils/platform_utils.dart';

/// YomiHub 0.1.5: one place for the app's own identity.
///
/// Up to 0.1.4 the desktop build still kept its data in
/// `Documents\Mangayomi` (shared with a real Mangayomi install), registered the
/// `mangayomi://` protocol, and reported itself as "MangaYomi" in the window
/// title / Android recents. Everything now goes through these constants.
class AppIdentity {
  AppIdentity._();

  static const String _envName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'YomiHub',
  );
  static String get name =>
      (isTv || kIsTvBuild) ? 'YumiHub Android TV' : _envName;

  /// Folder under Documents (desktop) that holds databases, downloads, mpv…
  static const dirName = 'YomiHub';

  /// Folder name the app used before 0.1.5 on desktop.
  static const legacyDirName = 'Mangayomi';

  static const userAgent = 'YomiHub/0.4.4';

  /// URL scheme registered on Windows (Android declares its schemes in the
  /// manifest). `mangayomi://` is no longer claimed on desktop.
  static const scheme = 'yomihub';

  /// Desktop only: copy YomiHub's own data out of the shared
  /// `Documents\Mangayomi` folder into `Documents\YomiHub` once.
  ///
  /// Only copies when the old folder was really used by YomiHub (it holds the
  /// `yomihub_prefs` Hive box); a genuine Mangayomi install is left untouched
  /// and is never moved or deleted.
  static Future<void> migrateDesktopData() async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      return;
    }
    try {
      final docs = await getApplicationDocumentsDirectory();
      final oldDb = Directory(p.join(docs.path, legacyDirName, 'databases'));
      final newRoot = Directory(p.join(docs.path, dirName));
      final newDb = Directory(p.join(newRoot.path, 'databases'));
      if (await newDb.exists()) return;
      final marker = File(p.join(oldDb.path, 'yomihub_prefs.hive'));
      if (!await oldDb.exists() || !await marker.exists()) return;
      await _copyDir(oldDb, newDb);
      // Downloads / local library live next to the databases; copy the
      // small, YomiHub-specific folders only – downloads are re-linked by
      // the local-folder scanner (the old path is added as a local folder).
      for (final sub in const ['mpv', 'extension_server', 'backup']) {
        final d = Directory(p.join(docs.path, legacyDirName, sub));
        if (await d.exists()) {
          await _copyDir(d, Directory(p.join(newRoot.path, sub)));
        }
      }
      await File(p.join(newRoot.path, 'migrated_from_mangayomi.txt'))
          .writeAsString(
            tr(
              'Dữ liệu YomiHub đã được chép từ {p0} ({p1}). Thư mục cũ được giữ nguyên.',
              {'p0': oldDb.parent.path, 'p1': DateTime.now().toIso8601String()},
            ),
          );
    } catch (e) {
      debugPrint('[YomiHub] desktop data migration failed: $e');
    }
  }

  static Future<void> _copyDir(Directory from, Directory to) async {
    await to.create(recursive: true);
    await for (final e in from.list(followLinks: false)) {
      final target = p.join(to.path, p.basename(e.path));
      if (e is Directory) {
        await _copyDir(e, Directory(target));
      } else if (e is File) {
        // Lock files belong to a running instance; never copy them.
        if (e.path.endsWith('.lock') || e.path.endsWith('-lck')) continue;
        await e.copy(target);
      }
    }
  }
}
