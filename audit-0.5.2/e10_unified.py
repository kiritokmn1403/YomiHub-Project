import sys; sys.path.insert(0,'.')
from edit import edit
F='lib/modules/more/data_and_storage/widgets/unified_restore.dart'
edit(F,"""import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
""","""import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
""")
edit(F,"""    final (hasServer, syncOn) = _syncState(ref);

    final backupType = peekBackupType(path);
    final isMihonFamily =
        backupType == BackupType.mihon ||
        backupType == BackupType.aniyomi ||
        backupType == BackupType.neko;
""","""    final (hasServer, syncOn) = _syncState(ref);

    // 0.5.2: reading a large backup took up to 45 s with nothing on screen
    // (12 MB .tachibk, Note 9) - users took it for a broken restore and
    // tapped again. Show progress, inflate in the background, then preview.
    final BackupType backupType;
    TachiBkImportPreview? tachiPreview;
    showBusyDialog(context, tr('Đang đọc bản sao lưu…'));
    try {
      final lower = path.toLowerCase();
      if (lower.endsWith('.tachibk') || lower.endsWith('.proto.gz')) {
        await warmTachiBk(path);
      }
      // let the spinner paint before the synchronous parsing below
      await Future<void>.delayed(const Duration(milliseconds: 32));
      backupType = peekBackupType(path);
      if (backupType == BackupType.mihon ||
          backupType == BackupType.aniyomi ||
          backupType == BackupType.neko) {
        tachiPreview = previewTachiBkImport(path);
      }
    } finally {
      if (context.mounted) hideBusyDialog(context);
    }
    final isMihonFamily =
        backupType == BackupType.mihon ||
        backupType == BackupType.aniyomi ||
        backupType == BackupType.neko;
""")
edit(F,"""    final preview = previewTachiBkImport(path);
    if (preview == null) {
      botToast("Unsupported or unrecognized backup file.");
      return false;
    }""","""    final preview = tachiPreview;
    if (preview == null) {
      botToast(tr("Định dạng bản sao lưu không được hỗ trợ!"));
      return false;
    }""")
edit(F,"""    _showImportResultToast(context, ref, resultDescription, safetyBackupPath);
    return true;
  } catch (e) {
    botToast("Error restoring backup: $e");
    if (safetyBackupPath != null && context.mounted) {
      offerLibraryRollback(context, ref, safetyBackupPath);
    }
    return false;
  }
}""","""    _showImportResultToast(context, ref, resultDescription, safetyBackupPath);
    return true;
  } catch (e, s) {
    AppLogger.log('[Sao lưu] Lỗi khôi phục bản sao lưu: $e\\n$s', logLevel: LogLevel.error);
    botToast(tr('Lỗi khôi phục bản sao lưu: {e}', {'e': e}));
    if (safetyBackupPath != null && context.mounted) {
      offerLibraryRollback(context, ref, safetyBackupPath);
    }
    return false;
  } finally {
    clearTachiBkCache();
  }
}""")
edit(F,"""    final Map<String, dynamic> backup;
    try {
      backup = await decodeMangayomiBackup(path, context);
    } catch (e) {
      if (context.mounted) botToast("$e");
      return;
    }""","""    final Map<String, dynamic> backup;
    try {
      botToast(tr('Đang đọc bản sao lưu…'), second: 3);
      backup = await decodeMangayomiBackup(path, context);
    } catch (e) {
      if (context.mounted) botToast("$e");
      return;
    }""")
edit(F,"""    botToast("Error restoring backup: $e");""","""    AppLogger.log('[Sao lưu] Lỗi khôi phục bản sao lưu: $e', logLevel: LogLevel.error);
    botToast(tr('Lỗi khôi phục bản sao lưu: {e}', {'e': e}));""")
edit(F,"""                              label: Text(
                                name,
                                maxLines: 1,""","""                              label: Text(
                                name.trim().isEmpty ? tr('(Không rõ nguồn)') : name,
                                maxLines: 1,""")
