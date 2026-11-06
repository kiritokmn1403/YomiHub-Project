import sys; sys.path.insert(0,'.')
from edit import edit
F='lib/modules/more/data_and_storage/providers/backup.dart'
edit(F,"import 'dart:io';\n","import 'dart:io';\nimport 'dart:isolate';\n")
edit(F,"""import 'package:mangayomi/utils/log/logger.dart';
""","""import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
""")
edit(F,"""    // YomiHub: push the new backup to every connected cloud target.
    unawaited(CloudBackupService.instance.uploadInBackground(zipPath));""","""    // 0.5.2: every backup is written to the app log (Feature Check 34).
    AppLogger.log(
      '[Sao lưu] Đã tạo bản sao lưu ${p.basename(zipPath)} '
      '(${(File(zipPath).lengthSync() / 1048576).toStringAsFixed(1)} MB) trong ${p.dirname(zipPath)}',
      logLevel: LogLevel.info,
    );
    // YomiHub: push the new backup to every connected cloud target.
    unawaited(CloudBackupService.instance.uploadInBackground(zipPath));""")
edit(F,"""        title: (_) => const Text(
          "Backup created!",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),""","""        title: (_) => Text(
          tr("Đã tạo bản sao lưu!"),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),""")
edit(F,"""                  title: "Share YomiHub backup file",""","""                  title: tr("Chia sẻ tệp sao lưu YomiHub"),""")
edit(F,"""    AppLogger.log('Backup failed: $e\\n$stack', logLevel: LogLevel.error);""","""    AppLogger.log('[Sao lưu] Tạo bản sao lưu thất bại ($path): $e\\n$stack', logLevel: LogLevel.error);""")
edit(F,"""        title: (_) => Text(
          "Backup failed: $e",""","""        title: (_) => Text(
          tr("Tạo bản sao lưu thất bại: {e}", {'e': e}),""")
edit(F,"""  final file = File(backupFilePath);

  await file.writeAsString(jsonEncode(datas));
  final zipPath = p.join(directory, "$name.backup");
  final zipEncoder = ZipFileEncoder(password: encryptionPassword);
  zipEncoder.create(zipPath, level: compressionLevel);
  await zipEncoder.addFile(file);
  await zipEncoder.close();
  await file.delete();
  return zipPath;
}""","""  final zipPath = p.join(directory, "$name.backup");
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
}""")
