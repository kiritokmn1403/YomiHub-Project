# P7F 0.5.7: Android < 11 (API < 30) khong co AImageDecoder -> bo giai ma goc tra NULL -> "Khong tai duoc anh nay".
# Them duong du phong: giai ma bang codec cua Flutter, ghi BMP 32-bit (bo giai ma goc doc duoc BMP tren moi nen tang).
import io,sys
p='overlay/lib/modules/manga/reader/subsampling_scale_image_view/src/ffi_image_decoder.dart'
s=io.open(p,encoding='utf-8',newline='').read()
nl='\r\n' if '\r\n' in s else '\n'
s=s.replace('\r\n','\n')
assert 'legacyBmp' not in s
def rep(a,b,n=1):
    global s
    assert s.count(a)==n,(a,s.count(a))
    s=s.replace(a,b)
rep("""import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
""","""import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
""")
# cancel(): mark cancelled
rep("""    _queue.removeWhere((job) {
      if (job.cancelToken == token) {
        if (!job.completer.isCompleted) {""","""    _queue.removeWhere((job) {
      if (job.cancelToken == token) {
        job.cancelled = true;
        if (!job.completer.isCompleted) {""")
rep("""  Future<DecodeResult?> decodeRegionAsync(
    DecodeParams params, {
    Object? cancelToken,
  }) async {
    await start();""","""  Future<DecodeResult?> decodeRegionAsync(
    DecodeParams params, {
    Object? cancelToken,
  }) async {
    // 0.5.7: the page was converted for the legacy path (see below).
    final legacy = _legacyBmp[params.filePath];
    if (legacy != null) {
      params = DecodeParams(
        filePath: legacy,
        left: params.left,
        top: params.top,
        right: params.right,
        bottom: params.bottom,
        sampleSize: params.sampleSize,
        cropBorders: params.cropBorders,
      );
    }
    await start();""")
rep("""  Future<List<int>?> getImageDimensionsAsync(
    String filePath, {
    bool cropBorders = false,
    Object? cancelToken,
  }) async {
    await start();""","""  // ── YomiHub 0.5.7 (P7F): Android 6–10 ────────────────────────────────────
  // The native decoder on Android is AImageDecoder (libjnigraphics, API 30+).
  // Below Android 11 `init_decoder` returns NULL for every JPEG/PNG/WebP and
  // the reader showed "Không tải được ảnh này" for each page (seen on the
  // API 23 emulator with local CBZ files). The native library does read
  // 32-bit BMP on every platform, so such a page is decoded once with
  // Flutter's own codec and handed over as a BMP in the cache directory.
  final Map<String, String> _legacyBmp = {};
  final Map<String, Future<String?>> _legacyBmpJobs = {};
  static const int _legacyBmpKeep = 24;

  /// Test hook: the directory for converted pages (default: temp directory).
  @visibleForTesting
  static Directory? debugLegacyBmpDir;

  /// Test hook: treat this platform as Android for the legacy path.
  @visibleForTesting
  static bool debugForceLegacyBmp = false;

  /// 32-bit top-down BMP (BGRA) from straight RGBA pixels – the layout
  /// `init_bmp_decoder` / `decode_bmp_region` in image_decoder.cpp expect.
  @visibleForTesting
  static Uint8List encodeBmp32(Uint8List rgba, int width, int height) {
    if (width <= 0 || height <= 0 || rgba.length < width * height * 4) {
      throw ArgumentError('encodeBmp32: bad size $width x $height');
    }
    const headerSize = 54;
    final pixels = width * height * 4;
    final out = Uint8List(headerSize + pixels);
    final h = ByteData.view(out.buffer);
    out[0] = 0x42; // 'B'
    out[1] = 0x4D; // 'M'
    h.setUint32(2, headerSize + pixels, Endian.little);
    h.setUint32(10, headerSize, Endian.little);
    h.setUint32(14, 40, Endian.little); // BITMAPINFOHEADER
    h.setInt32(18, width, Endian.little);
    h.setInt32(22, -height, Endian.little); // top-down
    h.setUint16(26, 1, Endian.little);
    h.setUint16(28, 32, Endian.little);
    h.setUint32(34, pixels, Endian.little);
    for (var i = 0, o = headerSize; i < pixels; i += 4, o += 4) {
      out[o] = rgba[i + 2]; // B
      out[o + 1] = rgba[i + 1]; // G
      out[o + 2] = rgba[i]; // R
      out[o + 3] = rgba[i + 3]; // A
    }
    return out;
  }

  Future<String?> _legacyBmpFor(String filePath) {
    return _legacyBmpJobs[filePath] ??= _convertToLegacyBmp(filePath)
        .whenComplete(() => _legacyBmpJobs.remove(filePath));
  }

  Future<String?> _convertToLegacyBmp(String filePath) async {
    ui.Codec? codec;
    ui.Image? image;
    try {
      final source = File(filePath);
      if (!await source.exists()) return null;
      final stat = await source.stat();
      final key = md5
          .convert(
            '$filePath:${stat.size}:${stat.modified.millisecondsSinceEpoch}'
                .codeUnits,
          )
          .toString();
      final dir = debugLegacyBmpDir ?? await getTemporaryDirectory();
      final target = File(p.join(dir.path, 'ssiv_bmp_$key.bmp'));
      if (await target.exists() && await target.length() > 54) {
        return target.path;
      }
      final bytes = await source.readAsBytes();
      // Already a BMP the native side refused, or not an image at all.
      if (bytes.length < 12 || (bytes[0] == 0x42 && bytes[1] == 0x4D)) {
        return null;
      }
      codec = await ui.instantiateImageCodec(bytes);
      image = (await codec.getNextFrame()).image;
      final raw = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      if (raw == null) return null;
      final bmp = encodeBmp32(
        raw.buffer.asUint8List(raw.offsetInBytes, raw.lengthInBytes),
        image.width,
        image.height,
      );
      final part = File('${target.path}.part');
      await part.writeAsBytes(bmp, flush: true);
      await part.rename(target.path);
      unawaited(_trimLegacyBmp(dir, target.path));
      return target.path;
    } catch (e) {
      if (kDebugMode) {
        print('FfiImageDecoder legacy BMP fallback failed for $filePath: $e');
      }
      return null;
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  /// Converted pages are large (4 bytes per pixel): keep the newest few.
  Future<void> _trimLegacyBmp(Directory dir, String keep) async {
    try {
      final files = <File, DateTime>{};
      await for (final e in dir.list()) {
        if (e is File && p.basename(e.path).startsWith('ssiv_bmp_')) {
          files[e] = (await e.stat()).modified;
        }
      }
      if (files.length <= _legacyBmpKeep) return;
      final inUse = _legacyBmp.values.toSet();
      final sorted = files.keys.toList()
        ..sort((a, b) => files[a]!.compareTo(files[b]!));
      var extra = files.length - _legacyBmpKeep;
      for (final f in sorted) {
        if (extra <= 0) break;
        if (f.path == keep) continue;
        try {
          await f.delete();
          extra--;
          if (inUse.contains(f.path)) {
            _legacyBmp.removeWhere((_, v) => v == f.path);
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<List<int>?> getImageDimensionsAsync(
    String filePath, {
    bool cropBorders = false,
    Object? cancelToken,
  }) async {
    final known = _legacyBmp[filePath];
    if (known != null && !await File(known).exists()) {
      _legacyBmp.remove(filePath);
    }
    final job = await _dimensionsJob(
      _legacyBmp[filePath] ?? filePath,
      cropBorders: cropBorders,
      cancelToken: cancelToken,
    );
    if (job == null) return null;
    var dims = await job.completer.future as List<int>?;
    final failed = dims == null || dims[0] == 0 || dims[1] == 0;
    if (failed &&
        !job.cancelled &&
        _legacyBmp[filePath] == null &&
        (Platform.isAndroid || debugForceLegacyBmp)) {
      final bmp = await _legacyBmpFor(filePath);
      if (bmp != null) {
        _legacyBmp[filePath] = bmp;
        final retry = await _dimensionsJob(
          bmp,
          cropBorders: cropBorders,
          cancelToken: cancelToken,
        );
        if (retry == null) return null;
        dims = await retry.completer.future as List<int>?;
        if (dims == null && !retry.cancelled) _legacyBmp.remove(filePath);
      }
    }
    return dims;
  }

  Future<_DecodeJob?> _dimensionsJob(
    String filePath, {
    bool cropBorders = false,
    Object? cancelToken,
  }) async {
    await start();""")
rep("""    _queue.add(job);
    _processNext();

    return completer.future;
  }

  void _processNext() {""","""    _queue.add(job);
    _processNext();

    return job;
  }

  void _processNext() {""")
rep("""    for (final job in _queue) {
      if (!job.completer.isCompleted) {""","""    for (final job in _queue) {
      job.cancelled = true;
      if (!job.completer.isCompleted) {""")
rep("""  final Object? cancelToken;
  final String? action;
""","""  final Object? cancelToken;
  final String? action;
  bool cancelled = false;
""")
io.open(p,'w',encoding='utf-8',newline='').write(s.replace('\n',nl))
print('ok')
