import sys; sys.path.insert(0,'.')
from edit import edit
F='lib/yomihub/vpn/vpn_service.dart'
edit(F,"import 'package:flutter/services.dart';\n","import 'package:flutter/services.dart';\nimport 'package:flutter/widgets.dart' show AppLifecycleListener;\n")
edit(F,"""  Timer? _torGuardTimer;
  Future<void> _armTorGuard() async {""","""  Timer? _torGuardTimer;
  AppLifecycleListener? _torGuardLife;

  /// 0.5.2: the crash-loop guard fired falsely (logs 2, 04/11 09:01:46 →
  /// 09:04:55): tor had loaded its consensus and reached 75 %
  /// ("enough_dirinfo"), then YomiHub went to the background (onTrimMemory
  /// 3 s later) and Android/the user closed it inside the 25 s window – the
  /// next launch blamed Tor and switched it off. The guard is now dropped as
  /// soon as tor has survived loading its consensus (circuit diagnostics
  /// readable) or the app leaves the foreground, where a process death is
  /// the system's doing, not tor's exit().
  void _clearTorGuard() {
    if (!(_torGuardTimer?.isActive ?? false)) return;
    _torGuardTimer!.cancel();
    unawaited(_put('torStartPending', false));
  }

  Future<void> _armTorGuard() async {""")
edit(F,"""    _torGuardTimer?.cancel();
    _torGuardTimer = Timer(const Duration(seconds: 25), () {
      unawaited(_put('torStartPending', false));
    });""","""    _torGuardTimer?.cancel();
    _torGuardTimer = Timer(const Duration(seconds: 25), () {
      unawaited(_put('torStartPending', false));
    });
    _torGuardLife ??= AppLifecycleListener(
      onHide: _clearTorGuard,
      onPause: _clearTorGuard,
      onDetach: _clearTorGuard,
    );""")
edit(F,"""        final hop = '${m['firstHop'] ?? ''}';
        if (hop.isEmpty && i < wait.inSeconds ~/ 5) continue;""","""        final hop = '${m['firstHop'] ?? ''}';
        // tor answered on its control port with a consensus loaded: it is
        // past the point where it used to exit() (0.4.3 guard).
        if (RegExp(r'PROGRESS=([5-9]\\d|100)').hasMatch('${m['bootstrap']}')) {
          _clearTorGuard();
        }
        if (hop.isEmpty && i < wait.inSeconds ~/ 5) continue;""")
edit(F,"""      AppLogger.log('[VPN] Tor dừng đột ngột khi khởi động (tiến trình bị đóng) – đã tắt Tor để ứng dụng mở được', logLevel: LogLevel.error);""","""      AppLogger.log('[VPN] Ứng dụng bị đóng trong lúc Tor đang khởi động (chưa tải xong dữ liệu mạng Tor) – đã tắt Tor để ứng dụng mở được; bật lại trong VPN & DNS', logLevel: LogLevel.error);""")
