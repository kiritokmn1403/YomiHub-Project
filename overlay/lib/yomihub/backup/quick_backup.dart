import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/auto_backup.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/backup.dart';
import 'package:mangayomi/providers/storage_provider.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/cloud/cloud_backup_service.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:path/path.dart' as p;

/// YomiHub 0.6.5 (sheet "YomiHub Update" mục 14): a "Sao Lưu" button in the
/// Library. One tap writes a backup with the items chosen in
/// Sao Lưu & Khôi Phục (the same list as the automatic backup), into the
/// automatic backup folder (so "Số bản sao lưu giữ lại" prunes it), and the
/// existing hook in doBackUp pushes it to every cloud target with
/// automatic upload on.
class YomiQuickBackup {
  YomiQuickBackup._();

  /// Pref: show the button in the Library app bar.
  static const showKey = 'libraryBackupButton';

  /// Pref: ask before starting.
  static const confirmKey = 'libraryBackupConfirm';

  static bool get showButton => YomiPrefs.get<bool>(showKey, true);
  static bool get confirm => YomiPrefs.get<bool>(confirmKey, false);

  static bool _running = false;
  static bool get running => _running;

  /// One-shot: toasts the outcome of the next background cloud upload.
  static void Function() _reportCloudResult(CloudBackupService cloud) {
    void listener() {
      cloud.lastResults.removeListener(listener);
      final res = cloud.lastResults.value;
      final failed = [for (final r in res) if (r.error != null) r.provider];
      BotToast.showText(
        text: failed.isEmpty
            ? tr('Đã tải lên đám mây xong')
            : tr('Tải lên đám mây lỗi: {p0} – xem Sao lưu đám mây', {'p0': failed.join(', ')}),
        duration: const Duration(seconds: 5),
      );
    }

    cloud.lastResults.addListener(listener);
    return () => cloud.lastResults.removeListener(listener);
  }

  /// The folder a quick backup goes to: `<backup location>/autobackup`,
  /// falling back to the app's default backup folder.
  static Future<Directory?> targetDirectory(ProviderContainer container) async {
    final storage = StorageProvider();
    if (Platform.isIOS) {
      final d = await storage.getIosBackupDirectory();
      return d == null ? null : automaticBackupDirectory(d.path);
    }
    final location = container.read(autoBackupLocationStateProvider).$2;
    final fromSetting = location.isNotEmpty ? automaticBackupDirectory(location) : null;
    if (fromSetting != null) return fromSetting;
    final def = await storage.getDefaultDirectory();
    if (def == null) return null;
    return automaticBackupDirectory(p.join(def.path, 'backup'));
  }

  /// Runs a backup now. Returns the folder, or null when it failed.
  static Future<String?> run(WidgetRef ref, BuildContext context) async {
    // The widget may be disposed while the backup runs (user leaves the
    // Library): take the container now and never use `ref` after an await.
    final container = ProviderScope.containerOf(context, listen: false);
    if (_running) {
      BotToast.showText(text: tr('Đang sao lưu, vui lòng chờ…'));
      return null;
    }
    if (confirm) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(tr('Sao lưu ngay?')),
          content: Text(tr('Tạo bản sao lưu theo các mục đã chọn trong Sao Lưu & Khôi Phục và tải lên các dịch vụ đám mây đang bật tự động.')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Hủy'))),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('Sao lưu'))),
          ],
        ),
      );
      if (ok != true) return null;
    }
    _running = true;
    final close = BotToast.showLoading();
    void Function()? cancelCloudReport;
    try {
      final dir = await targetDirectory(container);
      if (dir == null) {
        throw Exception(tr('Chưa có thư mục sao lưu dùng được – hãy chọn vị trí trong Sao Lưu & Khôi Phục.'));
      }
      await StorageProvider().createDirectorySafely(dir.path);
      final cloud = CloudBackupService.instance;
      await cloud.load();
      final pending = cloud.providers.any((e) => e.isConnected && cloud.autoUpload(e));
      if (pending) cancelCloudReport = _reportCloudResult(cloud);
      await container.read(
        doBackUpProvider(
          list: container.read(backupFrequencyOptionsStateProvider),
          path: dir.path,
          context: null,
        ).future,
      );
      await pruneOldBackups(dir.path);
      close();
      BotToast.showText(
        text: pending
            ? '${tr('Đã sao lưu vào {p0}', {'p0': dir.path})}\n${tr('Đang tải lên đám mây…')}'
            : tr('Đã sao lưu vào {p0}', {'p0': dir.path}),
        duration: const Duration(seconds: 4),
      );
      return dir.path;
    } catch (e, st) {
      cancelCloudReport?.call();
      close();
      AppLogger.log('[Sao lưu] Nút Sao Lưu trong Thư Viện thất bại: $e\n$st', logLevel: LogLevel.error);
      BotToast.showText(
        text: tr('Tạo bản sao lưu thất bại: {e}', {'e': e}),
        duration: const Duration(seconds: 6),
      );
      return null;
    } finally {
      _running = false;
    }
  }
}

/// The button itself (Library app bar).
class YomiQuickBackupButton extends ConsumerWidget {
  const YomiQuickBackupButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<int>(
      valueListenable: YomiPrefs.changes,
      builder: (context, _, _) {
        if (!YomiQuickBackup.showButton) return const SizedBox.shrink();
        return IconButton(
          splashRadius: 20,
          tooltip: tr('Sao lưu'),
          icon: const Icon(Icons.backup_outlined),
          onPressed: () => YomiQuickBackup.run(ref, context),
        );
      },
    );
  }
}
