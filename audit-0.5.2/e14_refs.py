import sys; sys.path.insert(0,'.')
from edit import edit
L='lib/utils/log/logger.dart'
edit(L,"""  static void log(String message, {LogLevel logLevel = LogLevel.info}) {
    final important =
        logLevel == LogLevel.error || logLevel == LogLevel.warning;
    if (!important && !verbose) return;
""","""  static void log(String message, {LogLevel logLevel = LogLevel.info}) {
    final important =
        logLevel == LogLevel.error || logLevel == LogLevel.warning;
    if (!important && !verbose) return;
    // 0.5.2: one line may not exceed 16 000 characters. A failed restore
    // printed its whole provider argument (the decoded backup) - ~30 MB per
    // line, logs.txt + crash_reports.json grew to 133 MB on the Note 9.
    if (message.length > 16000) {
      message = '${message.substring(0, 16000)}… [đã cắt ${message.length - 16000} ký tự]';
    }
""")
C='lib/services/crash_report.dart'
edit(C,"""        error: redact(error.toString()),""","""        // 0.5.2: capped (see AppLogger.log) - a provider error can embed
        // its whole argument, e.g. a decoded backup of tens of MB.
        error: _cap(redact(error.toString()), 8000),""")
edit(C,"""  static void record({
    required String source,""","""  static String _cap(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}… [${s.length - max} ký tự bị cắt]';

  static void record({
    required String source,""")
F='lib/modules/more/data_and_storage/providers/restore.dart'
edit(F,"""      if (full) {
        if (yomiExtras is Map) {
          await YomiBackupExtras.restore(Map<String, dynamic>.from(yomiExtras));
        }
        _invalidateCommonState(ref);
      } else if (merge) {
        // 0.5.2: the library, the extensions installed above and their
        // settings changed - refresh the screens that show them.
        _invalidateCommonState(ref);
      }""","""      if (full) {
        if (yomiExtras is Map) {
          await YomiBackupExtras.restore(Map<String, dynamic>.from(yomiExtras));
        }
      }
      // 0.5.2: no `ref` after an await here. This autoDispose provider can be
      // disposed while a long restore runs ("Cannot use the Ref of
      // restoreBackupProvider(...) after it has been disposed", Note 9
      // 06/11 00:22:39 - the restore was reported as failed at its very end).
      // doRestore, whose ref is kept alive, refreshes the screens instead.""")
edit(F,"""      trackRepository.clearPreferencesSync();
    });
    _invalidateCommonState(ref);
  } catch (e) {
    rethrow;
  }
}""","""      trackRepository.clearPreferencesSync();
    });
    // 0.5.2: refreshed by doRestore (see restoreBackup).
  } catch (e) {
    rethrow;
  }
}""")
edit(F,"""  // 0.5.2: inflated once (platform zlib, background isolate) by the restore
  // screen and reused here instead of a 4th pure-Dart GZipDecoder pass.
  final content = tachiBkBytes(path);""","""  // 0.5.2: kept alive for the repository import below (it awaits the
  // network and then uses ref); the screens are refreshed by doRestore.
  final keepAlive = ref.keepAlive();
  // 0.5.2: inflated once (platform zlib, background isolate) by the restore
  // screen and reused here instead of a 4th pure-Dart GZipDecoder pass.
  final content = tachiBkBytes(path);""")
s=open('../overlay/'+F,encoding='utf-8').read()
i=s.index('Future<void> restoreTachiBkBackup(')
j=s.index('_invalidateCommonState(ref);', i)
s=s[:j]+'keepAlive.close(); // 0.5.2: screens refreshed by doRestore'+s[j+len('_invalidateCommonState(ref);'):]
open('../overlay/'+F,'w',encoding='utf-8',newline='').write(s)
print('tachibk invalidate replaced')
edit(F,"""      default:
    }
    if (backupType != BackupType.unknown) {""","""      default:
    }
    // 0.5.2: refresh the screens here - this provider is kept alive, the
    // restore providers above may already be disposed.
    if (backupType != BackupType.unknown && backupType != BackupType.lnreader) {
      _invalidateCommonState(ref);
    }
    if (backupType != BackupType.unknown) {""")
edit(F,"""    AppLogger.log('[Sao lưu] Khôi phục thất bại (${p.basename(path)}): $e\\n$s',
        logLevel: LogLevel.error);""","""    final msg = '$e';
    AppLogger.log('[Sao lưu] Khôi phục thất bại (${p.basename(path)}): '
        '${msg.length > 600 ? '${msg.substring(0, 600)}…' : msg}\\n$s',
        logLevel: LogLevel.error);""")
