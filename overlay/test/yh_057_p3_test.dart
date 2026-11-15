// YomiHub 0.5.7 – gói P3 (trình phát & Short Video).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/eval/model/filter.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/yomihub/integrations/nuvio_media_hub.dart';
import 'package:mangayomi/yomihub/player/resume_policy.dart';
import 'package:mangayomi/yomihub/player/resume_store.dart';
import 'package:mangayomi/yomihub/player/shorts_detect.dart';
import 'package:mangayomi/yomihub/player/yomi_shorts.dart';

const _s = Duration(seconds: 1);
Duration sec(num v) => Duration(milliseconds: (v * 1000).round());

void main() {
  setUp(() {
    YomiResumeStore.persistent = false;
    YomiResumeStore.resetForTest();
  });

  group('U7 – stored position', () {
    test('database value is used when there is no mark', () {
      expect(
        YomiResumePolicy.storedPosition(dbPositionMs: 754000, dbTotalMs: 1440000),
        sec(754),
      );
      expect(YomiResumePolicy.storedPosition(dbPositionMs: 999, dbTotalMs: 0), Duration.zero);
      expect(YomiResumePolicy.storedPosition(dbPositionMs: 1, dbTotalMs: 0), Duration.zero);
      // finished episode restarts
      expect(
        YomiResumePolicy.storedPosition(dbPositionMs: 1440000, dbTotalMs: 1440000),
        Duration.zero,
      );
    });

    test('a mark newer than the database row wins (write still queued)', () {
      // exit at 20:00 – the Isar row still holds 05:00 written a minute earlier
      final mark = ResumeMark(1200000, 1440000, 1000000);
      expect(
        YomiResumePolicy.storedPosition(
          dbPositionMs: 300000,
          dbTotalMs: 1440000,
          dbUpdatedAtMs: 940000,
          mark: mark,
        ),
        sec(1200),
      );
      // the queued write landed a moment later with the same clock: still the mark
      expect(
        YomiResumePolicy.storedPosition(
          dbPositionMs: 1200000,
          dbTotalMs: 1440000,
          dbUpdatedAtMs: 1001500,
          mark: mark,
        ),
        sec(1200),
      );
    });

    test('a database row written clearly later overrules the mark', () {
      // "đánh dấu chưa xem" (lastPageRead = "1") ten seconds after the mark
      final mark = ResumeMark(1200000, 1440000, 1000000);
      expect(
        YomiResumePolicy.storedPosition(
          dbPositionMs: 1,
          dbTotalMs: 1440000,
          dbUpdatedAtMs: 1010000,
          mark: mark,
        ),
        Duration.zero,
      );
    });

    test('the side store keeps the last mark per episode in memory', () {
      expect(YomiResumeStore.peek(7), isNull);
      YomiResumeStore.remember(7, sec(61), sec(600), nowMs: 5000);
      YomiResumeStore.remember(7, sec(64), sec(600), nowMs: 8000);
      YomiResumeStore.remember(null, sec(1), null);
      final m = YomiResumeStore.peek(7)!;
      expect([m.positionMs, m.totalMs, m.atMs], [64000, 600000, 8000]);
      expect(ResumeMark.fromList(m.toList())!.positionMs, 64000);
      expect(ResumeMark.fromList('x'), isNull);
      expect(ResumeMark.fromList([1, 2]), isNull);
      YomiResumeStore.forget(7);
      expect(YomiResumeStore.peek(7), isNull);
    });
  });

  group('U7 – open target and carry-over', () {
    test('mini player hand-over, then explicit position, then storage', () {
      expect(
        YomiResumePolicy.openTarget(
          resumeEnabled: true, miniPlayer: sec(90), explicit: sec(30), stored: sec(10)),
        sec(90),
      );
      expect(
        YomiResumePolicy.openTarget(resumeEnabled: true, explicit: sec(30), stored: sec(10)),
        sec(30),
      );
      expect(YomiResumePolicy.openTarget(resumeEnabled: true, stored: sec(10)), sec(10));
      expect(
        YomiResumePolicy.openTarget(resumeEnabled: false, miniPlayer: sec(90), stored: sec(10)),
        Duration.zero,
      );
    });

    test('a server switch before the resume finished keeps the pending target', () {
      // first server dead: engine at 0, stored target 20:00 not reached yet
      expect(
        YomiResumePolicy.carryOver(
          pendingTarget: sec(1200),
          targetCompleted: false,
          enginePosition: Duration.zero,
          uiPosition: Duration.zero,
        ),
        sec(1200),
      );
      // engine a few seconds in, still before the seek
      expect(
        YomiResumePolicy.carryOver(
          pendingTarget: sec(1200),
          targetCompleted: false,
          enginePosition: sec(2.4),
          uiPosition: sec(2.4),
        ),
        sec(1200),
      );
    });

    test('after the resume the live position is carried; nothing known → storage', () {
      expect(
        YomiResumePolicy.carryOver(
          pendingTarget: sec(1200),
          targetCompleted: true,
          enginePosition: sec(1300),
          uiPosition: sec(1299),
        ),
        sec(1300),
      );
      expect(
        YomiResumePolicy.carryOver(
          pendingTarget: Duration.zero,
          targetCompleted: true,
          enginePosition: Duration.zero,
          uiPosition: sec(45),
        ),
        sec(45),
      );
      expect(
        YomiResumePolicy.carryOver(
          pendingTarget: Duration.zero,
          targetCompleted: true,
          enginePosition: Duration.zero,
          uiPosition: Duration.zero,
        ),
        isNull,
      );
      expect(
        YomiResumePolicy.carryOver(
          pendingTarget: sec(50),
          targetCompleted: false,
          enginePosition: sec(900),
          uiPosition: sec(900),
          live: true,
        ),
        Duration.zero,
      );
    });

    test('the position is not written while it cannot be trusted', () {
      String? b({
        bool opened = true,
        bool live = false,
        bool resolved = true,
        bool done = true,
        Duration target = Duration.zero,
      }) => YomiResumePolicy.persistBlocker(
        mediaOpenStarted: opened,
        live: live,
        natureResolved: resolved,
        targetCompleted: done,
        pendingTarget: target,
      );
      expect(b(), isNull);
      expect(b(opened: false), 'not-opened');
      expect(b(live: true), 'live');
      expect(b(resolved: false), 'unresolved');
      expect(b(done: false, target: sec(30)), 'resume-pending');
      expect(b(done: false), isNull);
    });
  });

  group('U7 – resume loop', () {
    ResumeStep step({
      num pos = 0,
      num dur = 1440,
      bool playing = true,
      bool buffering = false,
      num stable = 0,
      bool reached = false,
      num baseline = 0,
      num since = 0,
      int tries = 0,
      bool expired = false,
    }) => YomiResumePolicy.step(
      target: sec(1200),
      position: sec(pos),
      duration: sec(dur),
      playing: playing,
      buffering: buffering,
      stable: sec(stable),
      reached: reached,
      baseline: sec(baseline),
      sinceBaseline: sec(since),
      tries: tries,
      expired: expired,
    );

    test('no seek before the stream really plays with a known duration', () {
      expect(step(pos: 0), ResumeStep.wait);
      expect(step(pos: 1.2, dur: 0), ResumeStep.wait); // HLS: duration unknown
      expect(step(pos: 1.2, buffering: true), ResumeStep.wait);
      expect(step(pos: 1.2, playing: false), ResumeStep.wait);
      expect(step(pos: 1.2), ResumeStep.seek);
    });

    test('confirmed only after 3 s of stable playback at the target', () {
      expect(step(pos: 1200.4, stable: 0), ResumeStep.wait);
      expect(step(pos: 1202.5, stable: 2), ResumeStep.wait);
      expect(step(pos: 1203.2, stable: 3), ResumeStep.confirmed);
      expect(step(pos: 1200.4, stable: 3, buffering: true), ResumeStep.wait);
    });

    test('a seek dropped by the backend (HLS variant re-open) is sent again', () {
      // reported 20:00, then playback restarted near where it was
      expect(
        step(pos: 3.5, reached: true, baseline: 1.2, since: 2.5, tries: 1),
        ResumeStep.seek,
      );
      expect(
        step(pos: 3.5, reached: true, baseline: 1.2, since: 2.5, tries: 8),
        ResumeStep.giveUp,
      );
    });

    test('the viewer seeking elsewhere ends the resume instead of being pulled back', () {
      expect(
        step(pos: 1800, reached: true, baseline: 1.2, since: 4, tries: 1),
        ResumeStep.userSeek,
      );
      expect(
        step(pos: 600, reached: true, baseline: 1.2, since: 4, tries: 1),
        ResumeStep.userSeek,
      );
    });

    test('time running out: success when at the target, give up otherwise', () {
      expect(step(pos: 1201, stable: 1, expired: true), ResumeStep.confirmed);
      expect(step(pos: 4, expired: true, tries: 3), ResumeStep.giveUp);
      expect(step(pos: 0, expired: true), ResumeStep.giveUp);
    });

    test('no target means nothing to do; clock formatting', () {
      expect(
        YomiResumePolicy.step(
          target: Duration.zero,
          position: _s,
          duration: sec(10),
          playing: true,
          buffering: false,
        ),
        ResumeStep.confirmed,
      );
      expect(YomiResumePolicy.clock(sec(1200)), '20:00');
      expect(YomiResumePolicy.clock(sec(3725)), '01:02:05');
    });
  });

  group('U5 – Nuvio gestures / PiP and Zenshin threshold', () {
    test('PiP size is always inside what Android accepts', () {
      (double, double) s(int? w, int? h) => NuvioMediaHub.pipVideoSize(w, h);
      double r((double, double) v) => v.$1 / v.$2;
      expect(r(s(null, null)), closeTo(16 / 9, 0.01));
      expect(r(s(0, 0)), closeTo(16 / 9, 0.01));
      expect(r(s(1920, 1080)), closeTo(16 / 9, 0.01));
      expect(r(s(3840, 1080)), lessThanOrEqualTo(2.39 + 0.01)); // 32:9
      expect(r(s(400, 1600)), greaterThanOrEqualTo(0.418)); // 1:4
      expect(s(1080, 1920).$2, 1920);
    });

    test('swipe maths keeps the historical 500 px travel and clamps', () {
      // prefs box is not open in tests → both gestures enabled by default
      final up = NuvioMediaHub.applySwipe(
        leftSide: true, current: 0.5, dy: -50, screenHeight: 400, travel: 500);
      expect(up, closeTo(0.6, 1e-9));
      final down = NuvioMediaHub.applySwipe(
        leftSide: false, current: 0.05, dy: 100, screenHeight: 400, travel: 500);
      expect(down, 0.0);
      expect(NuvioMediaHub.resolveDoubleTapSeconds(10), 10);
    });

    test('tracker sync: Zenshin threshold when on, "marked seen" when off', () {
      bool f({required bool z, bool reached = false, bool seen = false, bool done = false}) =>
          YomiResumePolicy.shouldSyncTracker(
            zenshinEnabled: z,
            reachedThreshold: reached,
            markedSeenNow: seen,
            alreadySynced: done,
          );
      expect(f(z: true, seen: true), isFalse); // 75 % seen, not yet 85 %
      expect(f(z: true, reached: true), isTrue);
      expect(f(z: true, reached: true, done: true), isFalse);
      expect(f(z: false, seen: true), isTrue);
      expect(f(z: false, reached: true), isFalse);
    });
  });

  group('U9 / FC26 – Short Video for external extensions', () {
    Source anime({String? name, String? baseUrl, String? params, String? notes}) =>
        Source(itemType: ItemType.anime)
          ..name = name
          ..baseUrl = baseUrl
          ..additionalParams = params
          ..notes = notes;

    test('short-form words, not every "short"', () {
      for (final w in ['Shorts', 'short videos', 'Video ngắn', 'Reels', 'TikTok', '抖音', 'Feed: Shorts', 'yt_shorts']) {
        expect(ShortsDetect.isShortWord(w), isTrue, reason: w);
      }
      for (final w in ['Short (< 4 min)', 'TV Short', 'Shortest first', '', null, 'Movie']) {
        expect(ShortsDetect.isShortWord(w), isFalse, reason: '$w');
      }
    });

    test('check box / tri-state / sort / nested group filters are recognised and applied', () {
      final cb = CheckBoxFilter('', 'Shorts', 'shorts', null);
      final tri = TriStateFilter('', 'Reels', 'reels', null);
      final sort = SortFilter('', 'Feed', SortState(0, false, null), [
        SelectFilterOption('New', 'new', null),
        SelectFilterOption('Short videos', 'sv', null),
      ], null);
      final sel = SelectFilter('', 'Type', 0, [
        SelectFilterOption('All', '0', null),
        SelectFilterOption('TikTok', 'tt', null),
      ], null);
      final filters = [
        GroupFilter('', 'Genres', [cb, GroupFilter('', 'More', [tri], null)], null),
        sort,
        sel,
      ];
      for (final f in [[cb], [tri], [sort], [sel]]) {
        expect(YomiShorts.supports(anime(name: 'Some Tube'), filters: f), isTrue);
      }
      expect(YomiShorts.supportReason(anime(name: 'Some Tube'), filters: filters), 'filter');
      final found = ShortsDetect.scanFilters(filters, apply: true);
      expect(found, hasLength(4));
      expect(cb.state, isTrue);
      expect(tri.state, 1);
      expect(sort.state.index, 1);
      expect(sel.state, 1);
    });

    test('a duration filter with a "Short" option does not unlock the button', () {
      final dur = SelectFilter('', 'Duration', 0, [
        SelectFilterOption('Any', '0', null),
        SelectFilterOption('Short (< 4 min)', 's', null),
        SelectFilterOption('Long', 'l', null),
      ], null);
      expect(YomiShorts.supports(anime(name: 'Some Tube', baseUrl: 'https://tube.example'), filters: [dur]), isFalse);
    });

    test('a filter that switches shorts OFF is never applied', () {
      for (final w in ['No shorts', 'Hide Shorts', 'Exclude reels', 'Ẩn video ngắn', 'Without TikTok']) {
        expect(ShortsDetect.isShortWord(w), isFalse, reason: w);
      }
      final off = CheckBoxFilter('', 'Hide shorts', 'hide_shorts', null);
      final on = CheckBoxFilter('', 'Shorts', 'shorts', null);
      expect(ShortsDetect.scanFilters([off], apply: true), isEmpty);
      expect(off.state, isFalse);
      expect(ShortsDetect.scanFilters([off, on], apply: true), ['checkbox:Shorts']);
      expect(on.state, isTrue);
    });

    test('capability flags and known sites', () {
      expect(YomiShorts.supportReason(anime(name: 'X', params: '{"shorts": true}')), 'capability');
      expect(YomiShorts.supportReason(anime(name: 'X', params: '{"supportsShorts":"true"}')), 'capability');
      expect(YomiShorts.supportReason(anime(name: 'X', notes: 'HD tube #shorts')), 'capability');
      expect(YomiShorts.supports(anime(name: 'X', params: '{"shorts": false}')), isFalse);
      expect(YomiShorts.supportReason(anime(name: 'TikTok (unofficial)')), 'site');
      expect(YomiShorts.supportReason(anime(name: 'DY', baseUrl: 'https://www.douyin.com')), 'site');
      expect(YomiShorts.supportReason(anime(name: 'Insta', baseUrl: 'https://www.instagram.com/reels/')), 'site');
      expect(YomiShorts.supportReason(anime(name: 'YouTube')), 'site');
      expect(YomiShorts.supports(anime(name: 'AnimePahe', baseUrl: 'https://animepahe.example')), isFalse);
    });

    test('only video sources; the override forces any video source', () {
      expect(
        ShortsDetect.reason(isVideoSource: false, forced: true, name: 'TikTok'),
        isNull,
      );
      expect(ShortsDetect.reason(isVideoSource: true, forced: true, name: 'AnimePahe'), 'forced');
      expect(YomiShorts.supports(Source(itemType: ItemType.novel)..name = 'TikTok'), isFalse);
    });
  });

  group('wiring in the player sources', () {
    String read(String p) => File(p).readAsStringSync();
    test('player uses the policy, the side store and the Nuvio helpers', () {
      final view = read('lib/modules/anime/anime_player_view.dart');
      expect(view, contains('YomiResumePolicy.step('));
      expect(view, contains('YomiResumePolicy.openTarget('));
      expect(view, contains('YomiResumePolicy.persistBlocker('));
      expect(view, contains('YomiResumeStore.ensureOpen()'));
      expect(view, contains('NuvioMediaHub.pipVideoSize('));
      expect('_yhCarryPosition()'.allMatches(view).length, greaterThanOrEqualTo(5));
      // FC32 wording
      expect(view, contains('Trình phát video không lưu đúng vị trí đã xem'));
      expect(view, contains('Lỗi video không tải được'));
      expect(view, contains('Video không thoát được'));
      final ctrl = read('lib/modules/anime/providers/anime_player_controller_provider.dart');
      expect(ctrl, contains('YomiResumeStore.remember('));
      expect(ctrl, contains('YomiResumePolicy.storedPosition('));
      expect(ctrl, contains('ZenshinAnimeTracker.hasReachedWatchThreshold('));
      final mobile = read('lib/modules/anime/widgets/mobile.dart');
      expect(mobile, contains('NuvioMediaHub.applySwipe('));
      expect(mobile, contains('NuvioMediaHub.resolveDoubleTapSeconds('));
      final home = read('lib/modules/manga/home/manga_home_screen.dart');
      expect(home, contains("tr('Ép chế độ Short')"));
      expect(home, contains('ShortsStore.setForced('));
    });

    test('every new string of the package has all 18 translations', () {
      final f = File(r'D:\Claude A.I\audit-0.5.7\notes\i18n_P3.json');
      if (!f.existsSync()) return; // only on the build machine
      final text = f.readAsStringSync();
      for (final lang in Directory('assets/yomihub_i18n').listSync().whereType<File>()) {
        final code = lang.uri.pathSegments.last.replaceAll('.json', '');
        expect('"$code":'.allMatches(text).length, 9, reason: code);
      }
    });
  });
}
