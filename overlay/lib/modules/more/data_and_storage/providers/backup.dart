import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/backup_compression.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/repositories/category_repository.dart';
import 'package:mangayomi/yomihub/backup/yomi_backup_extras.dart';
import 'package:mangayomi/repositories/chapter_repository.dart';
import 'package:mangayomi/repositories/custom_button_repository.dart';
import 'package:mangayomi/repositories/download_repository.dart';
import 'package:mangayomi/repositories/history_repository.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/repositories/settings_repository.dart';
import 'package:mangayomi/repositories/source_preference_repository.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/repositories/track_repository.dart';
import 'package:mangayomi/repositories/update_repository.dart';
import 'package:mangayomi/services/backup_password_storage.dart';
import 'package:mangayomi/utils/constant.dart';
import 'package:mangayomi/utils/platform_utils.dart';
import 'package:mangayomi/utils/share.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/cloud/cloud_backup_service.dart';
import 'package:mangayomi/yomihub/browser/browser_screen.dart' show BrowserHistory;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
part 'backup.g.dart';

@riverpod
Future<void> doBackUp(
  Ref ref, {
  required List<int> list,
  required String path,
  required BuildContext? context,
}) async {
  final compression = ref.read(backupCompressionLevelProvider);
  final compressionLevel = compression.clamp(0, 9).toInt();
  // 0.5.2: a 23 MB backup takes ~8 s on the Note 9 with the "Tạo" screen
  // unchanged - show that it is working (manual backups only).
  final closeLoading = context != null ? BotToast.showLoading() : null;
  try {
    final String zipPath;
    try {
      zipPath = await writeMangayomiBackupZip(
        list: list,
        directory: path,
        compressionLevel: compressionLevel,
      );
    } finally {
      closeLoading?.call();
    }
    // 0.5.2: every backup is written to the app log (Feature Check 34).
    AppLogger.log(
      '[Sao lưu] Đã tạo bản sao lưu ${p.basename(zipPath)} '
      '(${(File(zipPath).lengthSync() / 1048576).toStringAsFixed(1)} MB) trong ${p.dirname(zipPath)}',
      logLevel: LogLevel.info, always: true,
    );
    // YomiHub: push the new backup to every connected cloud target.
    unawaited(CloudBackupService.instance.uploadInBackground(zipPath));
    if (context != null && context.mounted) {
      Navigator.pop(context);
      BotToast.showNotification(
        animationDuration: const Duration(milliseconds: 200),
        animationReverseDuration: const Duration(milliseconds: 200),
        duration: const Duration(seconds: 5),
        backButtonBehavior: BackButtonBehavior.none,
        leading: (_) =>
            Image.asset(appIconAssets[Random().nextInt(2)], height: 25),
        title: (_) => Text(
          tr("Đã tạo bản sao lưu!"),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // The button used to be hidden on Linux, where share_plus throws on a
        // file. shareOrCopy answers there with the backup's path on the
        // clipboard, which is the thing a Linux user wanted from it anyway.
        trailing: (_) => UnconstrainedBox(
          alignment: Alignment.topLeft,
          child: ElevatedButton(
            onPressed: () {
              final RenderBox? box = context.findRenderObject() as RenderBox?;
              shareOrCopy(
                ShareParams(
                  files: [XFile(zipPath)],
                  subject: p.basename(zipPath),
                  title: tr("Chia sẻ tệp sao lưu YomiHub"),
                  sharePositionOrigin: box == null
                      ? null
                      : box.localToGlobal(Offset.zero) & box.size,
                ),
              );
            },
            child: Text(context.l10n.share),
          ),
        ),
        enableSlideOff: true,
        onlyOne: true,
        crossPage: true,
      );
    }
  } catch (e, stack) {
    AppLogger.log('[Sao lưu] Tạo bản sao lưu thất bại ($path): $e\n$stack', logLevel: LogLevel.error);
    if (context?.mounted ?? false) {
      BotToast.showNotification(
        animationDuration: const Duration(milliseconds: 200),
        animationReverseDuration: const Duration(milliseconds: 200),
        duration: const Duration(seconds: 7),
        backButtonBehavior: BackButtonBehavior.none,
        leading: (_) => const Icon(Icons.error, color: Colors.red),
        title: (_) => Text(
          tr("Tạo bản sao lưu thất bại: {e}", {'e': e}),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        enableSlideOff: true,
        onlyOne: true,
        crossPage: true,
      );
    }
  }
}

Future<String> writeMangayomiBackupZip({
  required List<int> list,
  required String directory,
  int compressionLevel = 6,
  bool encrypt = true,
}) async {
  Map<String, dynamic> datas = {};
  datas.addAll({"version": "2"});
  if (list.contains(0)) {
    final res = mangaRepository
        .getFavoritesNonLocalArchive()
        .map((e) => e.toJson())
        .toList();
    datas.addAll({"manga": res});
  }
  if (list.contains(1)) {
    final res = categoryRepository.getAll().map((e) => e.toJson()).toList();
    datas.addAll({"categories": res});
  }
  // 0.5.3 (logs 3, 06/11 13:40:53): "Giao diện bị treo 3.3 giây" began in
  // the same second as an auto-backup. The ZIP step was already off the UI
  // isolate (0.5.2) but ~88 000 chapters were still read with findAllSync()
  // and converted with toJson() in one go on the UI isolate. Chapters are now
  // read asynchronously and every large table is converted in batches that
  // yield to the event loop between them.
  if (list.contains(2)) {
    final chapters = await chapterRepository.getAllAsync();
    datas.addAll({"chapters": await _toJsonInBatches(chapters, (e) => e.toJson())});
    final res_ = await _toJsonInBatches(
      downloadRepository.getAll(),
      (e) => e.toJson(),
    );
    datas.addAll({"downloads": res_});
  }
  if (list.contains(3)) {
    final res = trackRepository.getAll().map((e) => e.toJson()).toList();
    datas.addAll({"tracks": res});
  }
  if (list.contains(4)) {
    final res = await _toJsonInBatches(
      historyRepository.getAll(),
      (e) => e.toJson(),
    );
    datas.addAll({"history": res});
    // YomiHub: in-app browser history travels with the reading history.
    datas.addAll({"yomihub_browser_history": await BrowserHistory.all()});
  }
  if (list.contains(5)) {
    final res = await _toJsonInBatches(
      updateRepository.getAll(),
      (e) => e.toJson(),
    );
    datas.addAll({"updates": res});
  }
  if (list.contains(6)) {
    final res = settingsRepository.getAll().map((e) => e.toJson()).toList();
    datas.addAll({"settings": res});
  } else {
    final setting = Settings()..themeIsDark = isTv;
    datas.addAll({
      "settings": [setting.toJson()],
    });
  }
  if (list.contains(7)) {
    final res = sourcePreferenceRepository
        .getAll()
        .map((e) => e.toJson())
        .toList();
    datas.addAll({"extensions_preferences": res});
  }
  if (list.contains(8)) {
    final res_ = trackRepository
        .getAllPreferences()
        .map((e) => e.toJson())
        .toList();
    datas.addAll({"trackPreferences": res_});
  }
  if (list.contains(9)) {
    final res = sourceRepository.getAll().map((e) => e.toJson()).toList();
    datas.addAll({"extensions": res});
  }
  if (list.contains(10)) {
    final res = customButtonRepository.getAll().map((e) => e.toJson()).toList();
    datas.addAll({"customButtons": res});
  }
  // YomiHub: Extensions Repo lists, installed extensions with their settings
  // and YomiHub's own settings always travel with the backup.
  datas.addAll({
    "yomihub": await YomiBackupExtras.collect(
      hasExtensions: list.contains(9),
      hasExtensionPrefs: list.contains(7),
      includeSensitive: list.contains(8),
    ),
  });
  String? encryptionPassword;
  if (encrypt &&
      (settingsRepository.currentOrNull?.backupEncryptionEnabled ?? false)) {
    encryptionPassword = await BackupPasswordStorage.get();
    if (encryptionPassword == null) {
      throw Exception(
        'Backup encryption is enabled but no password is set. '
        'Re-enter it in Data and Storage settings.',
      );
    }
    datas.addAll({"backupEncryptionPassword": encryptionPassword});
  }
  final regExp = RegExp(r'[^a-zA-Z0-9 .()\-\s]');
  final name =
      'yomihub_${DateTime.now().toString().replaceAll(regExp, '_').replaceAll(' ', '_')}';
  final backupFilePath = p.join(directory, "$name.backup.db");
  final zipPath = p.join(directory, "$name.backup");
  // 0.5.2: JSON encoding and deflating (tens of MB for a large library) run
  // in a background isolate instead of freezing the UI.
  final pw = encryptionPassword;
  final level = compressionLevel;
  await Isolate.run(() async {
    final file = File(backupFilePath);
    await file.writeAsString(jsonEncode(datas));
    final zipEncoder = ZipFileEncoder(password: pw);
    zipEncoder.create(zipPath, level: level);
    await zipEncoder.addFile(file);
    await zipEncoder.close();
    await file.delete();
  });
  return zipPath;
}

/// 0.5.3: converts [items] to JSON maps [batchSize] at a time, yielding to
/// the event loop between batches so that a large library does not block the
/// UI isolate while a backup is being prepared (frames keep being drawn).
Future<List<Map<String, dynamic>>> _toJsonInBatches<T>(
  List<T> items,
  Map<String, dynamic> Function(T) toJson, {
  int batchSize = 1000,
}) async {
  final out = <Map<String, dynamic>>[];
  for (var i = 0; i < items.length; i++) {
    out.add(toJson(items[i]));
    if ((i + 1) % batchSize == 0) {
      await Future<void>.delayed(Duration.zero);
    }
  }
  return out;
}
