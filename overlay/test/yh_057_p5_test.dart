// YomiHub 0.5.7 – gói P5, Feature Check 35 (Health Connect): thời lượng đọc/xem
// thật sự được ghi (trước 0.5.7 không nơi nào gọi record*), nhắc 20-20-20 chạy
// theo phút khi đang ở trình đọc / trình phát.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/health/health_connect_service.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  final hc = HealthConnectService.instance;
  late Directory temp;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    temp = await Directory.systemTemp.createTemp('yomihub-057-p5-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => temp.path,
        );
    await YomiPrefs.open();
    expect(YomiPrefs.isOpen, isTrue);
  });

  setUp(() async {
    hc.stopEyeCareWatch();
    await YomiPrefs.set('healthConnect_todayReadingMinutes', 0);
    await YomiPrefs.set('healthConnect_todayWatchingMinutes', 0);
    await YomiPrefs.set('healthConnect_enabled', true);
    await YomiPrefs.set('healthConnect_eyeCareReminder', true);
    await YomiPrefs.set('healthConnect_reminderInterval', 3);
    // touch the getters once so today's key is stored before the test starts
    hc.totalTodayMinutes;
    await YomiPrefs.set('healthConnect_todayReadingMinutes', 0);
    await YomiPrefs.set('healthConnect_todayWatchingMinutes', 0);
  });

  group('Feature Check 35 – thời lượng đọc/xem', () {
    test('seconds are carried over until they make a minute, reading and watching apart', () {
      hc.recordSeconds(50, watching: false);
      expect(hc.todayReadingMinutes, 0);
      hc.recordSeconds(50, watching: true);
      expect(hc.todayWatchingMinutes, 0);
      hc.recordSeconds(15, watching: false); // 65 s of reading
      expect(hc.todayReadingMinutes, 1);
      expect(hc.todayWatchingMinutes, 0);
      hc.recordSeconds(175, watching: false); // 5 s carried + 175 s = 3 min
      expect(hc.todayReadingMinutes, 4);
      hc.recordSeconds(20 * 60 + 10, watching: true); // 50 s carried + 1210 s = 21 min
      expect(hc.todayWatchingMinutes, 21);
      expect(hc.totalTodayMinutes, 25);
    });

    test('nonsense reports are ignored', () {
      hc.recordSeconds(0, watching: false);
      hc.recordSeconds(-30, watching: false);
      hc.recordSeconds(13 * 3600, watching: true);
      expect(hc.totalTodayMinutes, 0);
    });

    test('the history mixin reports the elapsed time (after the incognito check)', () {
      final m = _read('lib/modules/manga/reader/mixins/chapter_controller_mixin.dart');
      final incognito = m.indexOf('if (incognitoMode) return;', m.indexOf('Future<void> setHistoryUpdate'));
      final record = m.indexOf('HealthConnectService.instance.recordSeconds(');
      expect(incognito, greaterThan(0));
      expect(record, greaterThan(incognito));
      expect(m, contains('watching: manga.itemType == ItemType.anime'));
    });
  });

  group('Feature Check 35 – nhắc 20-20-20', () {
    test('fires after the chosen minutes in a reader / player, then starts over', () {
      final alerts = <int>[];
      void tick(bool inReader) => hc.eyeCareTick(inReader: inReader, onEyeCareAlert: alerts.add);
      tick(true);
      tick(true);
      expect(alerts, isEmpty);
      tick(true);
      expect(alerts, [3]);
      expect(hc.continuousMinutes, 0);
      tick(true);
      tick(true);
      tick(true);
      expect(alerts, [3, 3]);
    });

    test('one minute away keeps the count, two minutes away are the break', () {
      final alerts = <int>[];
      void tick(bool inReader) => hc.eyeCareTick(inReader: inReader, onEyeCareAlert: alerts.add);
      tick(true);
      tick(true);
      tick(false); // e.g. switching chapters through the detail screen
      expect(hc.continuousMinutes, 2);
      tick(true);
      expect(alerts, [3]);
      tick(true);
      tick(true);
      tick(false);
      tick(false); // a real break
      expect(hc.continuousMinutes, 0);
      tick(true);
      expect(alerts, [3]);
    });

    test('no reminder when Health Connect or the reminder is switched off', () async {
      final alerts = <int>[];
      void tick() => hc.eyeCareTick(inReader: true, onEyeCareAlert: alerts.add);
      await YomiPrefs.set('healthConnect_enabled', false);
      for (var i = 0; i < 7; i++) {
        tick();
      }
      expect(alerts, isEmpty);
      await YomiPrefs.set('healthConnect_enabled', true);
      await YomiPrefs.set('healthConnect_eyeCareReminder', false);
      hc.stopEyeCareWatch();
      for (var i = 0; i < 7; i++) {
        tick();
      }
      expect(alerts, isEmpty);
    });

    test('readers and the player are the watched screens; main.dart starts the watch', () {
      expect(HealthConnectService.readerScreens, {'/mangaReaderView', '/novelReaderView', '/animePlayerView'});
      final router = _read('lib/router/router.dart');
      for (final s in HealthConnectService.readerScreens) {
        expect(router, contains('name: "${s.substring(1)}"'), reason: s);
      }
      final main = _read('lib/main.dart');
      expect(main, contains('HealthConnectService.instance.startEyeCareWatch('));
      expect(main, contains('screen: () => CrashReports.screen'));
    });
  });
}
