// Decoding a mangayomi-format backup's JSON contents, transparently
// handling AES-encrypted backups. Kept apart from restore.dart: this only
// reads and decrypts a file, it never touches Isar.
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:mangayomi/modules/more/data_and_storage/widgets/backup_encryption_password_dialog.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/services/backup_password_storage.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

/// 0.5.2: unzip + JSON-decode in a background isolate (a 22 MB Mangayomi
/// backup is ~150 MB of JSON; on the UI isolate the screen froze).
Map<String, dynamic> _decodeBackupFile(String path, String? password) {
  final stream = InputFileStream(path);
  try {
    final archive = ZipDecoder().decodeStream(stream, password: password);
    final bytes = archive.files.first.content as List<int>;
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  } finally {
    stream.close();
  }
}

/// Whether the backup's (first) zip entry is password-protected: bit 0 of
/// the general purpose flag in the local file header.
bool _firstZipEntryEncrypted(String path) {
  try {
    final raf = File(path).openSync();
    try {
      final h = raf.readSync(8);
      if (h.length < 8) return false;
      final sig = h[0] | (h[1] << 8) | (h[2] << 16) | (h[3] << 24);
      if (sig != 0x04034b50) return false;
      return (h[6] & 1) == 1;
    } finally {
      raf.closeSync();
    }
  } catch (_) {
    return false;
  }
}

/// Tries with no password, then the locally-stored password (if any), then
/// prompts the user - retrying on a wrong password until it succeeds or the
/// user cancels.
///
/// On success, if the backup embeds an encryption password (see
/// `backup.dart`), persists it locally so future backups/restores on this
/// device don't need it retyped - mirroring how every other part of a
/// restored backup overwrites the local settings, just kept out of the
/// generic Settings JSON round-trip (see backup_password_fallback.dart).
///
/// Public so the restore UI can decode+preview a mangayomi-format backup
/// (merge/replace choice, category/source conflicts) before committing to
/// the actual restore - doRestore accepts the result back as
/// decodedMangayomiBackup so it isn't decrypted (and the password
/// re-prompted) a second time.
Future<Map<String, dynamic>> decodeMangayomiBackup(
  String path,
  BuildContext context,
) async {
  String? passwordToTry;
  var triedStoredPassword = false;
  var wasIncorrect = false;
  final l10n = l10nLocalizations(context)!;
  final encrypted = _firstZipEntryEncrypted(path);

  while (true) {
    try {
      // decodeStream() only parses headers; the content is read (and a wrong
      // password detected) inside _decodeBackupFile.
      final pw = passwordToTry;
      final sw = Stopwatch()..start();
      final backup = await Isolate.run(() => _decodeBackupFile(path, pw));
      AppLogger.log(
        '[Sao lưu] Đã giải nén + đọc JSON ${path.split(RegExp(r'[\\/]')).last} ở luồng nền trong ${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)} s',
        logLevel: LogLevel.info, always: true,
      );

      final embeddedPassword = backup['backupEncryptionPassword'] as String?;
      if (embeddedPassword != null && context.mounted) {
        await persistResolvedPassword(embeddedPassword, context);
      }
      return backup;
    } catch (e, s) {
      // 0.5.2: only an encrypted backup can need a password. Before, any
      // failure (damaged file, not a backup, out of memory) ended in the
      // "enter password" dialog and the real error was never shown/logged.
      if (!encrypted) {
        AppLogger.log('[Sao lưu] Không đọc được bản sao lưu $path: $e\n$s',
            logLevel: LogLevel.error);
        throw Exception(tr('Không đọc được bản sao lưu (tệp hỏng hoặc không phải bản sao lưu YomiHub/Mangayomi): {e}', {'e': e}));
      }
      if (!triedStoredPassword) {
        triedStoredPassword = true;
        final stored = await BackupPasswordStorage.get();
        if (stored != null) {
          passwordToTry = stored;
          continue;
        }
      }
      if (!context.mounted) rethrow;
      final entered = await showBackupDecryptPasswordDialog(
        context,
        wasIncorrect: wasIncorrect,
      );
      if (entered == null) {
        throw Exception(l10n.password_required_to_restore);
      }
      passwordToTry = entered;
      wasIncorrect = true;
    }
  }
}
