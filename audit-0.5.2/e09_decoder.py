import sys; sys.path.insert(0,'.')
from edit import edit
F='lib/modules/more/data_and_storage/providers/backup_decoder.dart'
edit(F,"""import 'dart:convert';
""","""import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
""")
edit(F,"""import 'package:mangayomi/services/backup_password_storage.dart';
""","""import 'package:mangayomi/services/backup_password_storage.dart';
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
""")
edit(F,"""  final l10n = l10nLocalizations(context)!;

  while (true) {
    final stream = InputFileStream(path);
    try {
      final archive = ZipDecoder().decodeStream(
        stream,
        password: passwordToTry,
      );
      // decodeStream() only parses headers and buffers raw compressed
      // bytes - it doesn't verify/decrypt content (and so won't throw on a
      // wrong password) until the content is actually read, hence forcing
      // that access here rather than after returning.
      final bytes = archive.files.first.content as List<int>;
      final backup = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
""","""  final l10n = l10nLocalizations(context)!;
  final encrypted = _firstZipEntryEncrypted(path);

  while (true) {
    try {
      // decodeStream() only parses headers; the content is read (and a wrong
      // password detected) inside _decodeBackupFile.
      final pw = passwordToTry;
      final backup = await Isolate.run(() => _decodeBackupFile(path, pw));
""")
edit(F,"""    } catch (_) {
      if (!triedStoredPassword) {""","""    } catch (e, s) {
      // 0.5.2: only an encrypted backup can need a password. Before, any
      // failure (damaged file, not a backup, out of memory) ended in the
      // "enter password" dialog and the real error was never shown/logged.
      if (!encrypted) {
        AppLogger.log('[Sao lưu] Không đọc được bản sao lưu $path: $e\\n$s',
            logLevel: LogLevel.error);
        throw Exception(tr('Không đọc được bản sao lưu (tệp hỏng hoặc không phải bản sao lưu YomiHub/Mangayomi): {p0}', ['$e']));
      }
      if (!triedStoredPassword) {""")
edit(F,"""      passwordToTry = entered;
      wasIncorrect = true;
    } finally {
      stream.close();
    }
  }""","""      passwordToTry = entered;
      wasIncorrect = true;
    }
  }""")
