// YomiHub 0.5.7 - QA2: page decoding on Android 6-10 (no AImageDecoder).
// Native unavailable / native returns nothing -> Flutter codec fallback.
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/modules/manga/reader/subsampling_scale_image_view/src/ffi_image_decoder.dart';

Future<Uint8List> _png(int w, int h) async {
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec);
  // Left half red, right half blue.
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

  group('QA2 - decision logic', () {
    test('API 30+: native decoder is used while it works', () {
      expect(
        FfiImageDecoder.nextDecodePath(
          nativeAvailable: true,
          nativeFailed: false,
          bmpTried: false,
          android: true,
        ),
        DecodePath.native,
      );
    });
    test('native library not loadable -> Flutter codec at once', () {
      for (final android in [true, false]) {
        expect(
          FfiImageDecoder.nextDecodePath(
            nativeAvailable: false,
            nativeFailed: false,
            bmpTried: false,
            android: android,
          ),
          DecodePath.dart,
        );
      }
    });
    test('native returns null on Android (API<30) -> legacy BMP, then Dart', () {
      expect(
        FfiImageDecoder.nextDecodePath(
          nativeAvailable: true,
          nativeFailed: true,
          bmpTried: false,
          android: true,
        ),
        DecodePath.legacyBmp,
      );
      expect(
        FfiImageDecoder.nextDecodePath(
          nativeAvailable: true,
          nativeFailed: true,
          bmpTried: true,
          android: true,
        ),
        DecodePath.dart,
      );
    });
    test('native returns null on desktop -> Dart (no BMP detour)', () {
      expect(
        FfiImageDecoder.nextDecodePath(
          nativeAvailable: true,
          nativeFailed: true,
          bmpTried: false,
          android: false,
        ),
        DecodePath.dart,
      );
    });
  });

  group('QA2 - Dart fallback end to end', () {
    late Directory dir;
    final logs = <String>[];
    setUp(() {
      dir = Directory.systemTemp.createTempSync('yh_qa2_');
      logs.clear();
      FfiImageDecoder.debugNativeAvailable = false;
      FfiImageDecoder.debugFallbackLog = logs.add;
      FfiImageDecoder.debugResetFallbackLog();
    });
    tearDown(() {
      FfiImageDecoder.debugNativeAvailable = null;
      FfiImageDecoder.debugFallbackLog = null;
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });

    testWidgets('PNG: dimensions + full region + sampled region', (t) async {
      await t.runAsync(() async {
        final file = File('${dir.path}/a.png')..writeAsBytesSync(await _png(40, 30));
        final d = FfiImageDecoder();
        final dims = await d.getImageDimensionsAsync(file.path);
        expect(dims, [40, 30]);

        final full = await d.decodeRegionAsync(DecodeParams(
          filePath: file.path, left: 0, top: 0, right: 40, bottom: 30, sampleSize: 1,
        ));
        expect(full!.error, isNull);
        final p = Pointer<Uint8>.fromAddress(full.pointerAddress!);
        final px = p.asTypedList(40 * 30 * 4);
        expect(px.sublist(0, 4), [255, 0, 0, 255]); // (0,0) red
        expect(px.sublist(39 * 4, 39 * 4 + 4), [0, 0, 255, 255]); // (39,0) blue
        calloc.free(p);

        final half = await d.decodeRegionAsync(DecodeParams(
          filePath: file.path, left: 20, top: 0, right: 40, bottom: 30, sampleSize: 2,
        ));
        final p2 = Pointer<Uint8>.fromAddress(half!.pointerAddress!);
        final px2 = p2.asTypedList(10 * 15 * 4);
        expect(px2.sublist(0, 4), [0, 0, 255, 255]);
        expect(px2.length, 10 * 15 * 4);
        calloc.free(p2);
      });
    });

    testWidgets('warning is logged once per session', (t) async {
      await t.runAsync(() async {
        final file = File('${dir.path}/b.png')..writeAsBytesSync(await _png(8, 8));
        final d = FfiImageDecoder();
        await d.getImageDimensionsAsync(file.path);
        final f2 = File('${dir.path}/c.png')..writeAsBytesSync(await _png(8, 8));
        await d.getImageDimensionsAsync(f2.path);
        expect(logs.length, 1);
        expect(logs.first, contains('fallback'));
      });
    });

    testWidgets('corrupt file: null, no crash', (t) async {
      await t.runAsync(() async {
        final file = File('${dir.path}/bad.jpg')..writeAsBytesSync(List.filled(64, 7));
        final d = FfiImageDecoder();
        expect(await d.getImageDimensionsAsync(file.path), isNull);
        final r = await d.decodeRegionAsync(DecodeParams(
          filePath: file.path, left: 0, top: 0, right: 8, bottom: 8, sampleSize: 1,
        ));
        expect(r!.pointerAddress, isNull);
        expect(r.error, isNotNull);
      });
    });
  });
}
