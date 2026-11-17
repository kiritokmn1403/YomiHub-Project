from ed import *

rel = 'lib/yomihub/health/health_connect_service.dart'
sub(rel, """  void _onActivityTime(int addedMinutes) {
    _continuousMinutes += addedMinutes;
    if (eyeCareReminder && _continuousMinutes >= reminderIntervalMinutes) {
      _continuousMinutes = 0;
      AppLogger.log(
        '[Health Connect] Nhắc nhở bảo vệ mắt: Bạn đã đọc/xem liên tục ${reminderIntervalMinutes} phút. Hãy nghỉ ngơi nhìn xa 20 giây!',
        logLevel: LogLevel.info,
      );
    }
    if (isEnabled && autoSync && Platform.isAndroid) {
      syncToAndroidHealthConnect(addedMinutes);
    }
  }
""", """  void _onActivityTime(int addedMinutes) {
    // 0.5.7: continuous screen time (20-20-20) is counted live by
    // [eyeCareTick]; the minutes reported when a reader / player closes are
    // only added to today's totals and synced.
    if (isEnabled && autoSync && Platform.isAndroid) {
      syncToAndroidHealthConnect(addedMinutes);
    }
  }

  // ---- 0.5.7 (Feature Check 35) -----------------------------------------
  // Until 0.5.6 nothing in the app called recordReadingMinutes /
  // recordWatchingMinutes / startContinuousSession: the statistics stayed at
  // 0, nothing reached Health Connect and the 20-20-20 reminder never fired.

  int _readCarry = 0;
  int _watchCarry = 0;

  /// Reading / watching time reported by the comic reader, the novel reader
  /// and the player when they save history (`setHistoryUpdate`). Seconds are
  /// carried over until they make a whole minute.
  void recordSeconds(int seconds, {required bool watching}) {
    // more than 12 h in one report is a clock jump or a forgotten screen
    if (seconds <= 0 || seconds > 12 * 3600 || !YomiPrefs.isOpen) return;
    if (watching) {
      _watchCarry += seconds;
      final m = _watchCarry ~/ 60;
      _watchCarry -= m * 60;
      recordWatchingMinutes(m);
    } else {
      _readCarry += seconds;
      final m = _readCarry ~/ 60;
      _readCarry -= m * 60;
      recordReadingMinutes(m);
    }
  }

  /// Screens that count as reading / watching (first segment of the route,
  /// as kept by `CrashReports.screen`).
  static const readerScreens = {'/mangaReaderView', '/novelReaderView', '/animePlayerView'};

  Timer? _eyeCareTimer;
  int _awayMinutes = 0;

  /// Minutes spent in a reader / player without a break (for tests / UI).
  int get continuousMinutes => _continuousMinutes;

  /// App-wide minute tick for the 20-20-20 reminder: no reader or player has
  /// to start / stop anything. [screen] is the current route, [foreground]
  /// tells whether the app is visible, [onEyeCareAlert] shows the reminder.
  void startEyeCareWatch({
    required String? Function() screen,
    required bool Function() foreground,
    required void Function(int minutes) onEyeCareAlert,
  }) {
    _eyeCareTimer?.cancel();
    _eyeCareTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      try {
        eyeCareTick(
          inReader: foreground() && readerScreens.contains(screen()),
          onEyeCareAlert: onEyeCareAlert,
        );
      } catch (_) {}
    });
  }

  void stopEyeCareWatch() {
    _eyeCareTimer?.cancel();
    _eyeCareTimer = null;
    _continuousMinutes = 0;
    _awayMinutes = 0;
  }

  /// One minute has passed. Two minutes in a row away from the readers /
  /// player (or with the app in the background) count as the break.
  @visibleForTesting
  void eyeCareTick({required bool inReader, required void Function(int minutes) onEyeCareAlert}) {
    if (!inReader) {
      if (++_awayMinutes >= 2) _continuousMinutes = 0;
      return;
    }
    _awayMinutes = 0;
    _continuousMinutes++;
    final every = reminderIntervalMinutes;
    if (isEnabled && eyeCareReminder && every > 0 && _continuousMinutes >= every) {
      _continuousMinutes = 0;
      AppLogger.log(
        '[Health Connect] Nhắc bảo vệ mắt: đã đọc/xem liên tục $every phút.',
        logLevel: LogLevel.info,
      );
      onEyeCareAlert(every);
    }
  }
""")

rel = 'lib/modules/manga/reader/mixins/chapter_controller_mixin.dart'
sub(rel, """import 'package:mangayomi/utils/extensions/manga_extensions.dart';
""", """import 'package:mangayomi/utils/extensions/manga_extensions.dart';
import 'package:mangayomi/yomihub/health/health_connect_service.dart';
""")
sub(rel, """    if (incognitoMode) return;
    final manga = getManga();

    final m = chapter.manga.value!;
""", """    if (incognitoMode) return;
    final manga = getManga();
    // 0.5.7 (Feature Check 35): reading / watching time feeds the Health
    // Connect statistics (not in incognito mode)
    if (elapsedSeconds > 0) {
      try {
        HealthConnectService.instance.recordSeconds(
          elapsedSeconds,
          watching: manga.itemType == ItemType.anime,
        );
      } catch (_) {}
    }

    final m = chapter.manga.value!;
""")

rel = 'lib/main.dart'
s = read(rel)
if 'health_connect_service.dart' not in s:
    sub(rel, """import 'package:mangayomi/services/crash_report.dart';
""", """import 'package:mangayomi/services/crash_report.dart';
import 'package:mangayomi/yomihub/health/health_connect_service.dart';
""")
sub(rel, """  // 0.2.2: freeze / jank / memory-pressure watchdog
  YomiPerf.instance.start();
""", """  // 0.2.2: freeze / jank / memory-pressure watchdog
  YomiPerf.instance.start();
  // 0.5.7 (Feature Check 35): 20-20-20 eye-care reminder while reading / watching
  HealthConnectService.instance.startEyeCareWatch(
    screen: () => CrashReports.screen,
    foreground: () {
      final s = WidgetsBinding.instance.lifecycleState;
      return s == null || s == AppLifecycleState.resumed;
    },
    onEyeCareAlert: (minutes) => botToast(
      tr('Bạn đã đọc/xem liên tục {p0} phút – hãy nhìn xa 20 giây để mắt nghỉ ngơi (quy tắc 20-20-20).', {'p0': '$minutes'}),
      second: 8,
    ),
  );
""")
print('P5 ok')
