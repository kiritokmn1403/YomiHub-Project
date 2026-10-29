import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

/// YomiHub 0.1.7 – helper processes on Windows (tor.exe, xray.exe, the
/// M-Extension-Server JVM, OpenVPN GUI).
///
/// * Started with [ProcessStartMode.detachedWithStdio]: console programs get
///   no console window (a normal start from a GUI app pops one up) but their
///   output can still be read.
/// * Every child is put in a Job object with KILL_ON_JOB_CLOSE, so it dies
///   with YomiHub even when YomiHub is killed from Task Manager or crashes –
///   no orphaned tor.exe / java.exe keeping ports busy.
/// * [shortPath] turns paths with Vietnamese characters (e.g. OneDrive's
///   "Tài liệu") into their 8.3 form for programs that read ANSI argv
///   (java.exe), which otherwise fail to find the file.
class WinProc {
  WinProc._(this.name, this.process);

  final String name;
  final Process process;
  final List<String> _log = [];
  final _lines = StreamController<String>.broadcast();
  bool _exited = false;

  bool get running => !_exited;
  int get pid => process.pid;
  Stream<String> get lines => _lines.stream;
  List<String> get log => List.unmodifiable(_log);

  static final _all = <WinProc>[];

  static Future<WinProc> start(
    String name,
    String exe,
    List<String> args, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final proc = await Process.start(
      exe,
      args,
      workingDirectory: workingDirectory,
      environment: environment,
      mode: Platform.isWindows ? ProcessStartMode.detachedWithStdio : ProcessStartMode.normal,
    );
    final w = WinProc._(name, proc);
    if (Platform.isWindows) _WinJob.assign(proc.pid);
    void onLine(String l) {
      w._log.add(l);
      if (w._log.length > 400) w._log.removeRange(0, w._log.length - 400);
      if (!w._lines.isClosed) w._lines.add(l);
    }

    proc.stdout.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter()).listen(
          onLine,
          onDone: () => w._markExited(),
          onError: (_) {},
        );
    proc.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(onLine, onError: (_) {});
    _all.add(w);
    return w;
  }

  void _markExited() {
    _exited = true;
    _all.remove(this);
    if (!_lines.isClosed) _lines.close();
  }

  /// Ends the process (and its children, e.g. lyrebird under tor).
  Future<void> kill() async {
    if (_exited) return;
    try {
      if (Platform.isWindows) {
        // /T also ends helpers it started (lyrebird under tor.exe)
        await run('taskkill', ['/PID', '$pid', '/T', '/F']);
        Process.killPid(pid);
      } else {
        process.kill();
      }
    } catch (_) {}
    _markExited();
  }

  /// Runs a console tool without flashing a console window and returns its
  /// output (stdout + stderr).
  static Future<String> run(String exe, List<String> args, {Duration timeout = const Duration(seconds: 20)}) async {
    final proc = await Process.start(
      exe,
      args,
      mode: Platform.isWindows ? ProcessStartMode.detachedWithStdio : ProcessStartMode.normal,
    );
    final out = StringBuffer();
    final a = proc.stdout.transform(const Utf8Decoder(allowMalformed: true)).forEach(out.write);
    final b = proc.stderr.transform(const Utf8Decoder(allowMalformed: true)).forEach(out.write);
    try {
      await Future.wait([a, b]).timeout(timeout);
    } catch (_) {}
    return out.toString();
  }

  /// Is [pid] still alive (detached children have no exitCode future).
  bool get alive {
    if (_exited) return false;
    if (!Platform.isWindows) return true;
    final h = _k32OpenProcess(0x1000 /*QUERY_LIMITED_INFORMATION*/, 0, pid);
    if (h == nullptr) return false;
    final code = calloc<Uint32>();
    try {
      _k32GetExitCodeProcess(h, code);
      return code.value == 259; // STILL_ACTIVE
    } finally {
      calloc.free(code);
      _k32CloseHandle(h);
    }
  }

  static Future<void> killAll() async {
    for (final w in [..._all]) {
      await w.kill();
    }
  }

  /// Folder holding the helper programs shipped with YomiHub for Windows.
  static String get binDir => p.join(p.dirname(Platform.resolvedExecutable), 'yomihub_bin');

  /// 8.3 short form of [path] when it has non-ASCII characters.
  static String shortPath(String path) {
    if (!Platform.isWindows || !path.codeUnits.any((c) => c > 127)) return path;
    final src = path.toNativeUtf16();
    final buf = calloc<Uint16>(1024).cast<Utf16>();
    try {
      final n = _k32GetShortPathName(src, buf, 1024);
      if (n == 0 || n >= 1024) return path;
      return buf.toDartString();
    } catch (_) {
      return path;
    } finally {
      calloc.free(src);
      calloc.free(buf);
    }
  }

  /// A free TCP port on loopback, preferring [preferred].
  static Future<int> freePort([int preferred = 0]) async {
    if (preferred > 0) {
      try {
        final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, preferred);
        await s.close();
        return preferred;
      } catch (_) {}
    }
    final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = s.port;
    await s.close();
    return port;
  }

  /// Waits until something listens on 127.0.0.1:[port].
  static Future<bool> waitPort(int port, {Duration timeout = const Duration(seconds: 15)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      try {
        final s = await Socket.connect(InternetAddress.loopbackIPv4, port, timeout: const Duration(milliseconds: 500));
        s.destroy();
        return true;
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }
    return false;
  }
}

// ───────────── kernel32 ─────────────

final _k32 = Platform.isWindows ? DynamicLibrary.open('kernel32.dll') : null;

final _k32OpenProcess = _k32!.lookupFunction<Pointer Function(Uint32, Int32, Uint32), Pointer Function(int, int, int)>('OpenProcess');
final _k32CloseHandle = _k32!.lookupFunction<Int32 Function(Pointer), int Function(Pointer)>('CloseHandle');
final _k32GetExitCodeProcess =
    _k32!.lookupFunction<Int32 Function(Pointer, Pointer<Uint32>), int Function(Pointer, Pointer<Uint32>)>('GetExitCodeProcess');
final _k32GetShortPathName = _k32!.lookupFunction<Uint32 Function(Pointer<Utf16>, Pointer<Utf16>, Uint32),
    int Function(Pointer<Utf16>, Pointer<Utf16>, int)>('GetShortPathNameW');

class _WinJob {
  static Pointer? _job;

  static Pointer? _ensure() {
    if (_job != null) return _job;
    final create = _k32!.lookupFunction<Pointer Function(Pointer, Pointer<Utf16>), Pointer Function(Pointer, Pointer<Utf16>)>(
      'CreateJobObjectW',
    );
    final setInfo = _k32!.lookupFunction<Int32 Function(Pointer, Int32, Pointer, Uint32), int Function(Pointer, int, Pointer, int)>(
      'SetInformationJobObject',
    );
    final job = create(nullptr, nullptr);
    if (job == nullptr) return null;
    // JOBOBJECT_EXTENDED_LIMIT_INFORMATION is 144 bytes on x64; LimitFlags is
    // at offset 16 (after two LARGE_INTEGERs).
    const size = 144;
    final info = calloc<Uint8>(size);
    try {
      info.cast<Uint32>()[4] = 0x2000; // JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
      setInfo(job, 9 /*JobObjectExtendedLimitInformation*/, info.cast(), size);
    } finally {
      calloc.free(info);
    }
    _job = job;
    return job;
  }

  static void assign(int pid) {
    try {
      final job = _ensure();
      if (job == null) return;
      final assignFn = _k32!.lookupFunction<Int32 Function(Pointer, Pointer), int Function(Pointer, Pointer)>(
        'AssignProcessToJobObject',
      );
      final h = _k32OpenProcess(0x0100 | 0x0001 /*SET_QUOTA|TERMINATE*/, 0, pid);
      if (h == nullptr) return;
      assignFn(job, h);
      _k32CloseHandle(h);
    } catch (_) {}
  }
}
