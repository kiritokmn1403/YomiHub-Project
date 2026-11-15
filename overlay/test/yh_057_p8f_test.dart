// YomiHub 0.5.7 - P8F: two hangs seen on the Note 9 (Android 10).
// 1. Reader: the page was downloaded but never decoded (native decoder has no
//    AImageDecoder below Android 11; the BMP / RGBA fallbacks never answered).
//    -> direct ui.Image path, a time limit on every decoding step, watchdog.
// 2. Video player: see the second half of this file.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/modules/manga/reader/subsampling_scale_image_view/src/ffi_image_decoder.dart';
import 'package:mangayomi/modules/manga/reader/subsampling_scale_image_view/src/subsampling_scale_image_view.dart'
    as ssiv;
import 'package:mangayomi/utils/image_load_timeout.dart';
import 'package:mangayomi/yomihub/player/resume_policy.dart';
import 'package:mangayomi/yomihub/player/yomi_pip.dart';

Future<Uint8List> _png(int w, int h) async {
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec);
  c.drawRect(
    ui.Rect.fromLTWH(0, 0, w / 2, h.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFFF0000),
  );
  c.drawRect(
    ui.Rect.fromLTWH(w / 2, 0, w / 2, h.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF0000FF),
  );
  final img = await rec.endRecording().toImage(w, h);
  final bd = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return bd!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P8F reader - limits', () {
    test('every wait is bounded and fits in 45 s', () {
      expect(kDecodeStepTimeout.inSeconds, lessThanOrEqualTo(15));
      expect(kImageDecodeBackstop.inSeconds, lessThanOrEqualTo(45));
      expect(kImageDecodeBackstop, greaterThan(kDecodeStepTimeout));
    });
    test('directTargetSize: normal page untouched, huge page reduced', () {
      expect(FfiImageDecoder.directTargetSize(1115, 1600), isNull);
      expect(FfiImageDecoder.directTargetSize(0, 10), isNull);
      final tall = FfiImageDecoder.directTargetSize(800, 20000)!;
      expect(tall[1], lessThanOrEqualTo(8192));
      expect((tall[0] / tall[1] - 800 / 20000).abs(), lessThan(0.01));
      final big = FfiImageDecoder.directTargetSize(8000, 8000)!;
      expect(big[0] * big[1], lessThanOrEqualTo(32 * 1000 * 1000));
    });
    test('image state: auto retry on by default, off for a decode timeout', () {
      final a = ssiv.SubsamplingImageState(
        loadState: ssiv.LoadState.failed,
        reLoadCallback: () {},
      );
      expect(a.autoRetry, isTrue);
      final b = ssiv.SubsamplingImageState(
        loadState: ssiv.LoadState.failed,
        autoRetry: false,
        errorMessage: 'x',
        reLoadCallback: () {},
      );
      expect(b.autoRetry, isFalse);
    });
  });

  group('P8F reader - direct ui.Image path (Android < 11)', () {
    late Directory dir;
    final logs = <String>[];
    final timeouts = <String>[];
    setUp(() {
      dir = Directory.systemTemp.createTempSync('yh_p8f_');
      logs.clear();
      timeouts.clear();
      FfiImageDecoder.debugNativeAvailable = false;
      FfiImageDecoder.debugForceDirect = true;
      FfiImageDecoder.debugFallbackLog = logs.add;
      FfiImageDecoder.debugTimeoutLog = timeouts.add;
      FfiImageDecoder.debugResetFallbackLog();
      FfiImageDecoder.debugResetTimeoutLog();
    });
    tearDown(() {
      FfiImageDecoder.debugNativeAvailable = null;
      FfiImageDecoder.debugForceDirect = false;
      FfiImageDecoder.debugFallbackLog = null;
      FfiImageDecoder.debugTimeoutLog = null;
      FfiImageDecoder.debugDirectDecoder = null;
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });

    testWidgets('page is handed over as an image, no RGBA buffer', (t) async {
      await t.runAsync(() async {
        final file = File('${dir.path}/a.png')
          ..writeAsBytesSync(await _png(40, 30));
        final d = FfiImageDecoder();
        expect(await d.getImageDimensionsAsync(file.path), [40, 30]);
        expect(d.debugIsDirect(file.path), isTrue);
        expect(logs.length, 1);

        final full = await d.decodeRegionAsync(
          DecodeParams(
            filePath: file.path,
            left: 0,
            top: 0,
            right: 40,
            bottom: 30,
            sampleSize: 1,
          ),
        );
        expect(full!.error, isNull);
        expect(full.pointerAddress, isNull);
        expect(full.image, isNotNull);
        expect([full.image!.width, full.image!.height], [40, 30]);
        full.image!.dispose();

        // Right half only (split wide page).
        final half = await d.decodeRegionAsync(
          DecodeParams(
            filePath: file.path,
            left: 20,
            top: 0,
            right: 40,
            bottom: 30,
            sampleSize: 1,
          ),
        );
        expect(half!.error, isNull);
        expect([half.image!.width, half.image!.height], [20, 30]);
        final px = await half.image!.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        expect(px!.buffer.asUint8List().sublist(0, 4), [0, 0, 255, 255]);
        half.image!.dispose();

        // "Thử lại" forgets the page; it decodes again afterwards.
        d.forget(file.path);
        expect(d.debugIsDirect(file.path), isFalse);
        expect(await d.getImageDimensionsAsync(file.path), [40, 30]);
      });
    });

    testWidgets('broken file: no image, no hang', (t) async {
      await t.runAsync(() async {
        final file = File('${dir.path}/bad.jpg')
          ..writeAsBytesSync(List<int>.filled(64, 7));
        final d = FfiImageDecoder();
        final dims = await d
            .getImageDimensionsAsync(file.path)
            .timeout(const Duration(seconds: 10));
        expect(dims, isNull);
        expect(d.debugIsDirect(file.path), isFalse);
      });
    });

    testWidgets('a decoder that never answers is given up after the limit', (
      t,
    ) async {
      await t.runAsync(() async {
        FfiImageDecoder.debugDirectDecoder = (_) => Completer<ui.Image?>().future;
        final d = FfiImageDecoder();
        final sw = Stopwatch()..start();
        // The file does not exist, so the later fallbacks fail at once.
        final dims = await d
            .getImageDimensionsAsync('${dir.path}/missing.jpg')
            .timeout(kDecodeStepTimeout + const Duration(seconds: 8));
        expect(dims, isNull);
        expect(sw.elapsed, greaterThanOrEqualTo(kDecodeStepTimeout));
        expect(timeouts.length, 1);
        expect(timeouts.single, contains('flutter-codec'));
        expect(timeouts.single, contains('missing.jpg'));
      });
    }, timeout: const Timeout(Duration(seconds: 60)));
  });

  group('P8F player - resume does not re-seek a stream that is playing', () {
    Duration sec(num v) => Duration(milliseconds: (v * 1000).round());
    ResumeStep step(num pos, {num sinceSeek = 0, int tries = 1}) =>
        YomiResumePolicy.step(
          target: sec(1714), // 28:34 (Note 9 log, 15/11 11:54)
          position: sec(pos),
          duration: sec(6000),
          playing: true,
          buffering: false,
          tries: tries,
          sinceSeek: sec(sinceSeek),
        );

    test('2.5 s after a seek the position is target + 2.5 s: wait, no seek', () {
      // Before the fix this returned ResumeStep.seek (8 seeks in 20 s).
      expect(step(1716.5, sinceSeek: 2.5), ResumeStep.wait);
      expect(step(1719.4, sinceSeek: 5.5), ResumeStep.wait);
    });
    test('old behaviour without the elapsed time (documents the bug)', () {
      // (P8F-2: after a seek the landing slack applies as well, so the old
      // rule is only visible through isNear without any allowance.)
      expect(
        YomiResumePolicy.isNear(target: sec(1714), position: sec(1716.5)),
        isFalse,
      );
    });
    test('a seek the backend dropped is still repeated', () {
      expect(step(3.0, sinceSeek: 2.5), ResumeStep.seek);
      // P8F-2: but only once more - never 8 times
      expect(step(3.0, sinceSeek: 2.5, tries: 2), ResumeStep.giveUp);
      expect(YomiResumePolicy.maxSeeks, 2);
    });
    test('P8F-2: an HLS seek that lands on a later segment is the resume position', () {
      // mpv log, Note 9 15/11 14:07: seek 3359.44 -> "playback restart
      // complete @ 3380.88" every time; 8 seeks, "sau 8 lần tua".
      ResumeStep s(num pos, {num since = 0, num stable = 0, int tries = 1}) =>
          YomiResumePolicy.step(
            target: sec(3359.44),
            position: sec(pos),
            duration: sec(5863.96),
            playing: true,
            buffering: false,
            stable: sec(stable),
            tries: tries,
            sinceSeek: sec(since),
          );
      expect(s(3383.4, since: 2.5), ResumeStep.wait);
      expect(s(3386.4, since: 5.5, stable: 3), ResumeStep.confirmed);
      // before any seek was sent the slack does not apply
      expect(
        YomiResumePolicy.isNear(target: sec(3359.44), position: sec(3383.4)),
        isFalse,
      );
      // far outside the slack: still not "resumed"
      expect(s(3359.44 + 200, since: 2.5), ResumeStep.seek);
      // the whole loop with a +21.44 s landing: exactly one seek
      var pos = 1.0, t = 0.0, tries = 0, seeks = 0;
      double? seekAt, okSince;
      var result = ResumeStep.wait;
      while (t < 60) {
        t += 0.5;
        pos += 0.5;
        result = YomiResumePolicy.step(
          target: sec(3359.44),
          position: sec(pos),
          duration: sec(5863.96),
          playing: true,
          buffering: false,
          stable: sec(okSince == null ? 0.0 : t - okSince),
          tries: tries,
          sinceSeek: sec(seekAt == null ? 0.0 : t - seekAt),
        );
        if (result == ResumeStep.wait) {
          if (tries > 0) okSince ??= t;
          continue;
        }
        if (result != ResumeStep.seek) break;
        tries++;
        seeks++;
        seekAt = t;
        okSince = null;
        pos = 3380.88;
        t += 2;
        pos += 2;
      }
      expect(seeks, 1);
      expect(result, ResumeStep.confirmed);
    });
    test('P8F-2: no seek while the position stands still', () {
      ResumeStep s({required bool advancing, int tries = 0}) =>
          YomiResumePolicy.step(
            target: sec(1714),
            position: sec(4),
            duration: sec(6000),
            playing: true,
            buffering: false,
            tries: tries,
            advancing: advancing,
          );
      expect(s(advancing: false), ResumeStep.wait);
      expect(s(advancing: false, tries: 1), ResumeStep.wait);
      expect(s(advancing: true), ResumeStep.seek);
    });
    test('P8F-2: decoder fallback order and trigger', () {
      expect(YomiResumePolicy.nextHwdecFallback('auto'), 'mediacodec-copy');
      expect(YomiResumePolicy.nextHwdecFallback('auto-safe'), 'mediacodec-copy');
      expect(YomiResumePolicy.nextHwdecFallback('mediacodec'), 'mediacodec-copy');
      expect(YomiResumePolicy.nextHwdecFallback('mediacodec-copy'), 'no');
      expect(YomiResumePolicy.nextHwdecFallback('no'), isNull);
      bool stuck({int? w, int? h, num run = 9, bool playing = true, bool track = true}) =>
          YomiResumePolicy.videoStuckWithoutPicture(
            playing: playing,
            hasVideoTrack: track,
            width: w,
            height: h,
            advancingFor: sec(run),
          );
      expect(stuck(), isTrue);
      expect(stuck(w: 0, h: 0), isTrue);
      expect(stuck(w: 1920, h: 1080), isFalse); // picture size known
      expect(stuck(run: 5), isFalse); // not long enough
      expect(stuck(playing: false), isFalse);
      expect(stuck(track: false), isFalse); // audio-only stream
    });
    test('isNear: elapsed time widens only the "ahead" side', () {
      expect(
        YomiResumePolicy.isNear(
          target: sec(100),
          position: sec(96),
          sinceSeek: sec(10),
        ),
        isFalse,
      );
      expect(
        YomiResumePolicy.isNear(
          target: sec(100),
          position: sec(109),
          sinceSeek: sec(10),
        ),
        isTrue,
      );
    });
    test('the whole loop: one seek, then confirmed after 3 s of playback', () {
      // Simulates _yhResumeTo polling every 0.5 s (2 s pause after a seek).
      var pos = 1.0, t = 0.0, tries = 0, seeks = 0;
      double? seekAt, okSince;
      var result = ResumeStep.wait;
      while (t < 60) {
        t += 0.5;
        pos += 0.5;
        final stable = okSince == null ? 0.0 : t - okSince;
        final since = seekAt == null ? 0.0 : t - seekAt;
        result = YomiResumePolicy.step(
          target: sec(1714),
          position: sec(pos),
          duration: sec(6000),
          playing: true,
          buffering: false,
          stable: sec(stable),
          tries: tries,
          sinceSeek: sec(since),
        );
        if (result == ResumeStep.wait) {
          okSince ??= t;
          continue;
        }
        if (result != ResumeStep.seek) break;
        tries++;
        seeks++;
        seekAt = t;
        okSince = null;
        pos = 1714; // the seek lands at once
        t += 2;
        pos += 2;
      }
      expect(seeks, 1);
      expect(result, ResumeStep.confirmed);
    });
  });

  group('P8F-2 player - Back key', () {
    test('no PiP while the position stands still or the resume seek runs', () {
      bool b({bool advancing = true, bool resumePending = false}) =>
          YomiPip.pipOnBack(
            playing: true,
            buffering: false,
            width: 1920,
            height: 1080,
            advancing: advancing,
            resumePending: resumePending,
          );
      expect(b(), isTrue);
      expect(b(advancing: false), isFalse);
      expect(b(resumePending: true), isFalse);
    });
    test('MainActivity: Android <= 10 uses SurfaceTexture video textures', () {
      final kt = File(
        'android/app/src/main/kotlin/com/kodjodevf/mangayomi/MainActivity.kt',
      ).readAsStringSync();
      expect(kt, contains('debugForceSurfaceProducerGlTextures'));
      expect(kt, contains('Build.VERSION.SDK_INT > 29'));
      expect(kt, contains('"enable-impeller", false'));
      // must run before the Flutter fragment is created
      expect(
        kt.indexOf('yhUseLegacyVideoTextures()\n        super.onCreate') > 0 ||
            kt.indexOf('yhUseLegacyVideoTextures()\r\n        super.onCreate') > 0,
        isTrue,
      );
    });
  });

  group('P8F player - Back key', () {
    test('PiP only while a picture is really playing', () {
      expect(
        YomiPip.pipOnBack(playing: true, buffering: false, width: 1920, height: 1080),
        isTrue,
      );
      // loading / re-buffering / no frame yet / paused -> plain Back
      expect(
        YomiPip.pipOnBack(playing: true, buffering: true, width: 1920, height: 1080),
        isFalse,
      );
      expect(
        YomiPip.pipOnBack(playing: true, buffering: false, width: null, height: null),
        isFalse,
      );
      expect(
        YomiPip.pipOnBack(playing: true, buffering: false, width: 0, height: 0),
        isFalse,
      );
      expect(
        YomiPip.pipOnBack(playing: false, buffering: false, width: 1920, height: 1080),
        isFalse,
      );
    });
  });
}
