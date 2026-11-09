import 'dart:async';
import 'dart:io';

import 'package:mangayomi/providers/storage_provider.dart';
import 'package:mangayomi/repositories/settings_repository.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AppLogger {
  static File? _logFile;
  static IOSink? _sink;
  static bool _initialized = false;
  static bool _busy = false;

  /// YomiHub 0.1.8: verbose (debug/info) lines are only written when
  /// "Enable logs" is on, but warnings and errors - every error report of
  /// the app - always go to the application log (logs.txt).
  static bool verbose = false;

  /// Lines logged before [init] finished (start-up errors), flushed by it.
  static final List<String> _pending = [];

  static const _maxSize = 512 * 1024;

  /// Path of the application log, once known.
  static String? get path_ => _logFile?.path;

  static Future<File?> logFile() async {
    if (_logFile != null) return _logFile;
    final directory = await StorageProvider().getDefaultDirectory();
    if (directory == null) return null;
    return File(path.join(directory.path, 'logs.txt'));
  }

  /// Initialize the logger
  static Future<void> init() async {
    verbose = (await settingsRepository.currentAsync)?.enableLogs ?? false;
    if (_initialized || _busy) return;
    _busy = true;
    try {
      final storage = StorageProvider();
      final directory = await storage.getDefaultDirectory();
      var candidate = File(path.join(directory!.path, 'logs.txt'));
      // 0.5.1: Note 9 / Android 10 had no storage permission (see
      // StorageProvider.requestPermission), /storage/emulated/0/YomiHub could
      // not be created, init() failed silently and NO error was ever written
      // – the log screen then spun forever. Fall back to the app's own folder.
      try {
        await candidate.parent.create(recursive: true);
        await candidate.writeAsString('', mode: FileMode.append, flush: true);
      } catch (_) {
        candidate = File(path.join((await getApplicationSupportDirectory()).path, 'logs.txt'));
        await candidate.parent.create(recursive: true);
      }
      _logFile = candidate;

      if (await _logFile!.exists() && await _logFile!.length() > _maxSize) {
        // keep the previous log one generation back instead of losing it
        final old = File('${_logFile!.path}.old');
        if (await old.exists()) await old.delete();
        await _logFile!.rename(old.path);
        _logFile = File(candidate.path);
      }

      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }

      _sink = _logFile!.openWrite(mode: FileMode.append);
      _initialized = true;

      // 0.5.3: the session marker was written as a WARNING wrapped in blank
      // lines - 73 of the warnings in "logs 3" were only this marker. It is
      // now one INFO line, still always written so sessions stay separable.
      log('===== Logger initialized (phiên mới) =====', logLevel: LogLevel.info, always: true);
      _queue.addAll(_pending);
      _pending.clear();
      _drain();
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  /// [always]: 0.5.2 - an INFO line that is written even with "Enable logs"
  /// off (backup / restore results, Windows diagnostics), so a log sent in
  /// by a user shows what happened, not only what failed.
  static void log(String message, {LogLevel logLevel = LogLevel.info, bool always = false}) {
    final important =
        logLevel == LogLevel.error || logLevel == LogLevel.warning;
    if (!important && !always && !verbose) return;

    // 0.5.4: Phân loại nguồn lỗi rõ ràng (nguồn 404/403/Cloudflare vs Tor timeout vs ứng dụng)
    message = classifyMessage(message, logLevel);

    // 0.5.2: one line may not exceed 16 000 characters. A failed restore
    // printed its whole provider argument (the decoded backup) - ~30 MB per
    // line, logs.txt + crash_reports.json grew to 133 MB on the Note 9.
    if (message.length > 16000) {
      message = '${message.substring(0, 16000)}… [đã cắt ${message.length - 16000} ký tự]';
    }

    final now = DateTime.now();
    final timestamp =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year.toString().padLeft(4, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final logMessage = '[$timestamp][${logLevel.toString()}] $message';
    if (!_initialized || _sink == null) {
      if (_pending.length < 300) _pending.add(logMessage);
      return;
    }
    // YomiHub 0.1.9: never write to the IOSink while a flush() is running.
    // `writeln` during `flush` throws "Bad state: StreamSink is bound to a
    // stream", so a log call itself crashed its caller (seen as "Suggestions
    // failed: Bad state: StreamSink is bound to a stream" in logs.txt).
    _queue.add(logMessage);
    if (important) _wantFlush = true;
    _drain();
  }

  static final RegExp _appErrorRegex = RegExp(
    r'\b(fluttererror|bad\s+state|null\s+check\s+operator|isarerror|rangeerror|nosuchmethoderror|unhandled\s+exception|lateinitializationerror)\b|type\s+.+\s+is\s+not\s+a\s+subtype\s+of\s+type',
    caseSensitive: false,
  );

  static final RegExp _http404Regex = RegExp(
    r'\b(http\s*(?:status|error)?\s*[:=]?\s*404|status(?:code)?\s*[:=]?\s*404|code\s*[:=]?\s*404|404\s+(?:not\s+found|error))\b',
    caseSensitive: false,
  );

  static final RegExp _http403Regex = RegExp(
    r'\b(http\s*(?:status|error)?\s*[:=]?\s*403|status(?:code)?\s*[:=]?\s*403|code\s*[:=]?\s*403|403\s+forbidden|cloudflare|turnstile|cf_clearance)\b',
    caseSensitive: false,
  );

  static final RegExp _networkTorRegex = RegExp(
    r'\b(tor|warp|timeout|timed\s*out|socketexception|connection\s+(?:closed|refused|reset|error|aborted)|tls\s+handshake)\b',
    caseSensitive: false,
  );

  /// 0.5.4: Tự động phân loại lỗi để dễ dàng kiểm thử và khoanh vùng sự cố.
  static String classifyMessage(String msg, LogLevel level) {
    if (level != LogLevel.error && level != LogLevel.warning) return msg;
    if (msg.startsWith('[Lỗi Nguồn') ||
        msg.startsWith('[Lỗi Mạng') ||
        msg.startsWith('[Lỗi Ứng Dụng]') ||
        msg.startsWith('[Hiệu năng]')) {
      return msg;
    }

    // 1. Kiểm tra Lỗi Ứng Dụng trước tiên để tránh bắt nhầm (ví dụ: operator trong Null check operator)
    if (_appErrorRegex.hasMatch(msg)) {
      return '[Lỗi Ứng Dụng] $msg';
    }

    // 2. Kiểm tra HTTP 404 dựa trên status code thực tế, không bắt số 404 ngẫu nhiên trong URL
    if (_http404Regex.hasMatch(msg)) {
      return '[Lỗi Nguồn 404] $msg';
    }

    // 3. Kiểm tra HTTP 403 / Cloudflare Turnstile
    if (_http403Regex.hasMatch(msg)) {
      return '[Lỗi Nguồn 403 / Cloudflare] $msg';
    }

    // 4. Kiểm tra Lỗi Mạng / Tor Timeout với ranh giới từ nguyên (\b)
    if (_networkTorRegex.hasMatch(msg)) {
      return '[Lỗi Mạng / Tor Timeout] $msg';
    }

    return msg;
  }



  static final List<String> _queue = [];
  static bool _draining = false;
  static bool _wantFlush = false;

  static void _drain() {
    if (_draining) return;
    _draining = true;
    scheduleMicrotask(() async {
      try {
        while (_queue.isNotEmpty && _sink != null) {
          final lines = List<String>.of(_queue);
          _queue.clear();
          _sink!.write('${lines.join('\n')}\n');
          if (_wantFlush) {
            _wantFlush = false;
            await _sink!.flush();
          }
        }
      } catch (_) {
        // logging must never break the app
      } finally {
        _draining = false;
        if (_queue.isNotEmpty && _sink != null) _drain();
      }
    });
  }

  /// YomiHub 0.1.9: keys already written by [logOnce] this run.
  static final Set<String> _once = {};

  /// Write [message] only the first time [key] is seen in this run (keeps
  /// recurring network failures from flooding logs.txt).
  static void logOnce(
    String key,
    String message, {
    LogLevel logLevel = LogLevel.warning,
  }) {
    if (_once.length > 2000) _once.clear();
    if (!_once.add(key)) return;
    log(message, logLevel: logLevel);
  }

  /// Turning "Enable logs" off now only stops the verbose lines.
  static Future<void> dispose() async {
    verbose = false;
  }

  static Future<void> flush() async {
    // 0.5.1: bounded – a sink in error state kept _draining busy and the
    // log screen waiting forever.
    try {
      final sw = Stopwatch()..start();
      while (_draining && sw.elapsedMilliseconds < 3000) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      await _sink?.flush().timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      await flush();
      await _sink?.close();
    } catch (_) {}
    _sink = null;
    _initialized = false;
    final f = await logFile();
    if (f != null && await f.exists()) await f.writeAsString('');
    await init();
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error;

  @override
  String toString() {
    switch (this) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
    }
  }
}
