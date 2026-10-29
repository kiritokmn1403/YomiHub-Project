import 'dart:async';
import 'dart:io';

import 'package:mangayomi/providers/storage_provider.dart';
import 'package:mangayomi/repositories/settings_repository.dart';
import 'package:path/path.dart' as path;

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
      _logFile = File(path.join(directory!.path, 'logs.txt'));

      if (await _logFile!.exists() && await _logFile!.length() > _maxSize) {
        // keep the previous log one generation back instead of losing it
        final old = File('${_logFile!.path}.old');
        if (await old.exists()) await old.delete();
        await _logFile!.rename(old.path);
        _logFile = File(path.join(directory.path, 'logs.txt'));
      }

      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }

      _sink = _logFile!.openWrite(mode: FileMode.append);
      _initialized = true;

      log('\n\nLogger initialized\n\n', logLevel: LogLevel.warning);
      _queue.addAll(_pending);
      _pending.clear();
      _drain();
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  static void log(String message, {LogLevel logLevel = LogLevel.info}) {
    final important =
        logLevel == LogLevel.error || logLevel == LogLevel.warning;
    if (!important && !verbose) return;

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
    try {
      while (_draining) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      await _sink?.flush();
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
