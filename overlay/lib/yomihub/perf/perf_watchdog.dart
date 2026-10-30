import 'dart:async';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mangayomi/eval/lib.dart';
import 'package:mangayomi/services/download_manager/download_isolate_pool.dart';
import 'package:mangayomi/services/isolate_service.dart';
import 'package:mangayomi/utils/log/logger.dart';

/// YomiHub 0.2.2 – "Ứng dụng rất hay bị treo, lag, bị văng".
///
///  * Freeze detector: a 500 ms heartbeat on the UI isolate; when it fires
///    seconds late the UI thread was blocked – logged with its length, so a
///    freeze can be told apart from a slow network.
///  * Jank detector: frames slower than 700 ms are logged (build / raster
///    split). When raster time stays high (GPU-bound: blur of Liquid Glass on
///    weak GPUs), [reduceEffects] turns on and the glass blur is lowered for
///    the rest of the session.
///  * Memory pressure (Android onTrimMemory / low memory): the decoded image
///    cache is emptied instead of letting the system kill the app.
class YomiPerf with WidgetsBindingObserver {
  YomiPerf._();
  static final YomiPerf instance = YomiPerf._();

  /// Read by the Liquid Glass widgets.
  static bool reduceEffects = false;
  static final ValueNotifier<bool> reduceEffectsNotifier = ValueNotifier(false);

  bool _started = false;
  Timer? _beat;
  DateTime _last = DateTime.now();
  DateTime _lastFreezeLog = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastJankLog = DateTime.fromMillisecondsSinceEpoch(0);
  final List<int> _slowRaster = [];
  bool _foreground = true;
  final Stopwatch _mono = Stopwatch();
  int _lastMonoMs = 0;

  /// 0.4.3: short label of the work running in the background (library
  /// update, repository refresh…) so a freeze in the log says what caused it.
  static String _lastActivity = '';

  /// 0.4.5: current screen (set by MainScreen) – written with every slow
  /// frame so a slow screen can be found from the log alone (Xiaomi 15T:
  /// "dựng 855–1195ms" right after leaving a pushed page).
  static String route = '';
  static void activity(String label) => _lastActivity = label;
  static void activityDone(String label) {
    if (_lastActivity == label) _lastActivity = '';
  }

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _last = DateTime.now();
    _mono
      ..reset()
      ..start();
    // 0.4.3: the gap is measured with a monotonic Stopwatch. Wall-clock time
    // keeps running while the phone sleeps (screen off, Doze, PC suspend), so
    // the old DateTime-based check reported fake "freezes" of minutes (log:
    // "Giao diện bị treo 111.2 giây"). A Stopwatch pauses with the CPU, so a
    // large gap now really means the UI isolate was blocked.
    _beat = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final now = DateTime.now();
      final monoMs = _mono.elapsedMilliseconds;
      final gap = monoMs - _lastMonoMs - 500;
      final wallGap = now.difference(_last).inMilliseconds - 500;
      _lastMonoMs = monoMs;
      _last = now;
      if (!_foreground) return; // timers are paused in background
      // A wall-clock jump much larger than the monotonic one = device slept.
      if (wallGap - gap > 5000) return;
      if (gap >= 2500 && gap < 600000 &&
          now.difference(_lastFreezeLog).inSeconds > 30) {
        _lastFreezeLog = now;
        AppLogger.log(
          '[Hiệu năng] Giao diện bị treo ${(gap / 1000).toStringAsFixed(1)} giây (luồng UI bị chặn)${_lastActivity.isEmpty ? '' : ' • đang chạy: $_lastActivity'}',
          logLevel: LogLevel.warning,
        );
      }
    });
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    probeMemory();
  }

  void _onTimings(List<FrameTiming> timings) {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final t in timings) {
      final build = t.buildDuration.inMilliseconds;
      final raster = t.rasterDuration.inMilliseconds;
      if (raster > 40) {
        _slowRaster.add(now);
      }
      if (build + raster > 700 && DateTime.now().difference(_lastJankLog).inSeconds > 60) {
        _lastJankLog = DateTime.now();
        AppLogger.log(
          '[Hiệu năng] Khung hình chậm: dựng ${build}ms, vẽ ${raster}ms'
          '${route.isEmpty ? '' : ' • màn hình: $route'}${_lastActivity.isEmpty ? '' : ' • đang chạy: $_lastActivity'}',
          logLevel: LogLevel.info,
        );
      }
    }
    _slowRaster.removeWhere((t) => now - t > 10000);
    if (!reduceEffects && _slowRaster.length >= 60) {
      reduceEffects = true;
      reduceEffectsNotifier.value = true;
      AppLogger.log(
        '[Hiệu năng] GPU quá tải (≥60 khung hình vẽ chậm trong 10 giây) – tự giảm hiệu ứng làm mờ Liquid Glass',
        logLevel: LogLevel.info,
      );
    }
  }

  static const _tools = MethodChannel('com.yomihub/tools');

  /// Phone RAM in MB (0 = unknown); ≤ 4 GB counts as low-RAM.
  static int totalRamMb = 0;
  static bool lowRam = false;
  DateTime _lastTrimLog = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastTrim = DateTime.fromMillisecondsSinceEpoch(0);

  /// YomiHub 0.2.3: read the device RAM once and size the caches to it.
  Future<void> probeMemory() async {
    if (!Platform.isAndroid) return;
    try {
      final m = await _tools.invokeMapMethod<String, dynamic>('memInfo');
      final total = (m?['total'] as num?)?.toInt() ?? 0;
      totalRamMb = total ~/ 1048576;
      lowRam = (m?['lowRamDevice'] == true) || (totalRamMb > 0 && totalRamMb <= 4200);
      if (lowRam) {
        PaintingBinding.instance.imageCache
          ..maximumSizeBytes = 40 << 20
          ..maximumSize = 300;
      }
    } catch (_) {}
  }

  /// Frees what can be rebuilt later: decoded images, cached JS / extension
  /// runtimes, idle extension and download isolates, native (Kotatsu) caches.
  Future<String> trim({required bool critical, String reason = ''}) async {
    final now = DateTime.now();
    if (!critical && now.difference(_lastTrim).inSeconds < 20) return '';
    _lastTrim = now;
    final parts = <String>[];
    try {
      final c = PaintingBinding.instance.imageCache;
      final mb = c.currentSizeBytes ~/ 1048576;
      c.clear();
      if (critical) c.clearLiveImages();
      if (mb > 0) parts.add('ảnh $mb MB');
    } catch (_) {}
    try {
      final n = clearExtensionServiceCache();
      if (n > 0) parts.add('$n bộ chạy tiện ích');
    } catch (_) {}
    try {
      if (await getIsolateService.stopIfIdle()) parts.add('luồng tiện ích');
    } catch (_) {}
    try {
      if (DownloadIsolatePool.instance.releaseIfIdle()) parts.add('luồng tải xuống');
    } catch (_) {}
    if (Platform.isAndroid) {
      try {
        final r = await _tools.invokeMapMethod<String, dynamic>('trimMemory');
        final k = (r?['kotatsu'] as num?)?.toInt() ?? 0;
        final f = ((r?['freed'] as num?)?.toInt() ?? 0) ~/ 1048576;
        if (k > 0 || f > 0) parts.add('Java $f MB (Kotatsu $k mục)');
      } catch (_) {}
    }
    return parts.join(', ');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _last = DateTime.now();
    _lastMonoMs = _mono.elapsedMilliseconds;
    // 0.2.3: in the background Android kills the biggest apps first – give
    // back what is idle as soon as the app is hidden
    if (state == AppLifecycleState.paused) {
      trim(critical: false, reason: 'background');
    }
  }

  @override
  void didHaveMemoryPressure() {
    trim(critical: true).then((freed) {
      final now = DateTime.now();
      if (now.difference(_lastTrimLog).inMinutes < 10) return;
      _lastTrimLog = now;
      AppLogger.log(
        '[Hiệu năng] Hệ thống báo thiếu bộ nhớ'
        '${totalRamMb > 0 ? ' (RAM máy ${(totalRamMb / 1024).toStringAsFixed(1)} GB)' : ''}'
        ' – đã giải phóng: ${freed.isEmpty ? 'đã dọn bộ nhớ Java (GC), không còn bộ đệm nào khác' : freed}',
        logLevel: LogLevel.info,
      );
    });
  }

  void stop() {
    _beat?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _started = false;
  }
}
