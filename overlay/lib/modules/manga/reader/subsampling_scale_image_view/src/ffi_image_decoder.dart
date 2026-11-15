import 'dart:math' as math;
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/a6/a6_native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 0.5.7 (P8F): upper bound for one decoding step (native job, Flutter codec,
/// BMP conversion ...). A step that takes longer is abandoned and the next
/// decoder is tried, so a page can no longer wait forever.
const Duration kDecodeStepTimeout = Duration(seconds: 12);

/// Required parameters to decode an image region
class DecodeParams {
  final String filePath;
  final int left;
  final int top;
  final int right;
  final int bottom;
  final int sampleSize;
  final bool cropBorders;

  DecodeParams({
    required this.filePath,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.sampleSize,
    this.cropBorders = false,
  });

  Map<String, dynamic> toJson() => {
    "filePath": filePath,
    "left": left,
    "top": top,
    "right": right,
    "bottom": bottom,
    "sampleSize": sampleSize,
    "cropBorders": cropBorders,
  };
  factory DecodeParams.fromJson(Map<String, dynamic> json) {
    return DecodeParams(
      bottom: json['bottom'],
      filePath: json['filePath'],
      left: json['left'],
      top: json['top'],
      right: json['right'],
      sampleSize: json['sampleSize'],
      cropBorders: json['cropBorders'] ?? false,
    );
  }
}

/// Result returned after decoding a region
class DecodeResult {
  final int? pointerAddress;
  final int width;
  final int height;
  final String? error;

  /// 0.5.7 (P8F): a ready-to-draw image instead of an RGBA buffer (the
  /// "direct" path on Android < 11). The receiver owns and disposes it.
  final ui.Image? image;

  DecodeResult({
    this.pointerAddress,
    this.width = 0,
    this.height = 0,
    this.error,
    this.image,
  });
}

/// FFI interop interface with the native C++ library.
/// Manages loading the dynamic library and asynchronous execution
/// of decoding tasks in background Isolates.
class FfiImageDecoder {
  static DynamicLibrary? _dylib;

  bool _isRunning = false;
  Future<void>? _startFuture;
  Isolate? _cIsolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;

  final List<_DecodeJob> _queue = [];
  // Max concurrent decode jobs sent to the isolate.
  // 3 parallel jobs keeps tile throughput high without overloading memory.
  static const int _maxConcurrent = 3;
  int _activeJobs = 0;

  void cancel(Object token) {
    _queue.removeWhere((job) {
      if (job.cancelToken == token) {
        job.cancelled = true;
        if (!job.completer.isCompleted) {
          if (job.action == 'getDimensions') {
            job.completer.complete(null);
          } else {
            job.completer.complete(DecodeResult(error: 'Cancelled'));
          }
        }
        return true;
      }
      return false;
    });
  }

  Future<void> start() {
    if (_isRunning) {
      return Future.value();
    }
    _startFuture ??= _doStart();
    return _startFuture!;
  }

  Future<void> _doStart() async {
    try {
      await _initCIsolate();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error starting FFI isolate: $e');
        print(stackTrace);
      }
      await stop();
    } finally {
      _startFuture = null;
    }
  }

  Future<void> _initCIsolate() async {
    _receivePort = ReceivePort();

    _cIsolate = await Isolate.spawn(
      _cIsolateEntryPoint,
      _receivePort!.sendPort,
    );

    final completer = Completer<SendPort>();
    _receivePort!.listen((message) {
      if (message is SendPort && !completer.isCompleted) {
        completer.complete(message);
      }
    });

    // 0.5.7 (P8F): an isolate that never reports back must not hang every
    // page forever (the caller falls back to the Flutter codec).
    _sendPort = await completer.future.timeout(kDecodeStepTimeout);
    _isRunning = true;
  }

  static DynamicLibrary get dylib {
    if (_dylib == null) {
      if (Platform.isAndroid) {
        // 0.5.7 (U10): Android 6 – tên trần "not found" sau khi LD_LIBRARY_PATH
        // bị ghi đè; bản android6 mở bằng đường dẫn tuyệt đối (a6_native.dart).
        _dylib = yhOpenAndroidLib("libsubsampling_scale_image_view.so");
      } else if (Platform.isIOS || Platform.isMacOS) {
        try {
          _dylib = DynamicLibrary.open(
            "subsampling_scale_image_view.framework/subsampling_scale_image_view",
          );
        } catch (_) {
          _dylib = DynamicLibrary.process();
        }
      } else if (Platform.isWindows) {
        final exeDir = File(Platform.resolvedExecutable).parent.path;
        final candidates = [
          "$exeDir\\subsampling_scale_image_view.dll",
          "subsampling_scale_image_view.dll",
          "libsubsampling_scale_image_view.dll",
          "$exeDir\\libsubsampling_scale_image_view.dll",
          "${Directory.current.path}\\build\\native_assets\\windows\\subsampling_scale_image_view.dll",
          "$exeDir\\..\\..\\..\\native_assets\\windows\\subsampling_scale_image_view.dll",
        ];
        for (final path in candidates) {
          try {
            _dylib = DynamicLibrary.open(path);
            if (_dylib != null) break;
          } catch (_) {}
        }
        _dylib ??= DynamicLibrary.process();
      } else if (Platform.isLinux) {
        final exeDir = File(Platform.resolvedExecutable).parent.path;
        final candidates = [
          "$exeDir/lib/libsubsampling_scale_image_view.so",
          "$exeDir/libsubsampling_scale_image_view.so",
          "libsubsampling_scale_image_view.so",
          "${Directory.current.path}/build/native_assets/linux/libsubsampling_scale_image_view.so",
        ];
        for (final path in candidates) {
          try {
            _dylib = DynamicLibrary.open(path);
            if (_dylib != null) break;
          } catch (_) {}
        }
        _dylib ??= DynamicLibrary.process();
      } else {
        _dylib = DynamicLibrary.process();
      }
    }
    return _dylib!;
  }

  static final Pointer<Opaque> Function(
    Pointer<Utf8>,
    bool,
    Pointer<Int32>,
    Pointer<Int32>,
  )
  _initDecoder = dylib
      .lookupFunction<
        Pointer<Opaque> Function(
          Pointer<Utf8>,
          Bool,
          Pointer<Int32>,
          Pointer<Int32>,
        ),
        Pointer<Opaque> Function(
          Pointer<Utf8>,
          bool,
          Pointer<Int32>,
          Pointer<Int32>,
        )
      >('init_decoder');

  static final bool Function(
    Pointer<Opaque>,
    int,
    int,
    int,
    int,
    int,
    Pointer<Uint8>,
  )
  _decodeRegion = dylib
      .lookupFunction<
        Bool Function(
          Pointer<Opaque>,
          Int32,
          Int32,
          Int32,
          Int32,
          Int32,
          Pointer<Uint8>,
        ),
        bool Function(Pointer<Opaque>, int, int, int, int, int, Pointer<Uint8>)
      >('decode_region');

  static final void Function(Pointer<Opaque>) _freeDecoder = dylib
      .lookupFunction<
        Void Function(Pointer<Opaque>),
        void Function(Pointer<Opaque>)
      >('free_decoder');

  /// Decodes a specific region of the image asynchronously in a background Isolate.
  /// This prevents blocking the main UI thread during disk reads and decoding.
  static Future<void> _cIsolateEntryPoint(SendPort mainSendPort) async {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    // LRU Cache using LinkedHashMap for O(1) access, insertion, and ordering.
    // Keys are inserted in access order; to evict, remove first entry.
    final Map<String, Pointer<Opaque>> cachedContexts = {};
    final Map<String, List<int>> cachedDimensions = {};
    // lruOrder tracks insertion order; LinkedHashMap isn't directly available in isolate
    // so we use a plain Map (Dart Maps maintain insertion order since Dart 2) as O(1) ordered set.
    final Map<String, bool> lruOrder = {};
    const int maxCacheSize = 5;

    receivePort.listen((message) async {
      if (message is Map<String, dynamic>) {
        final responsePort = message['responsePort'] as SendPort;
        final action = message['action'] as String?;
        final params = DecodeParams.fromJson(message['params']);

        final key = "${params.filePath}_${params.cropBorders}";
        Pointer<Opaque> ctx = cachedContexts[key] ?? Pointer.fromAddress(0);
        int imgWidth = 0;
        int imgHeight = 0;

        if (ctx.address == 0) {
          // LRU Eviction: O(1) — remove first (oldest) entry from ordered map
          if (cachedContexts.length >= maxCacheSize) {
            final oldestKey = lruOrder.keys.first;
            lruOrder.remove(oldestKey);
            final oldestCtx = cachedContexts.remove(oldestKey);
            cachedDimensions.remove(oldestKey);
            if (oldestCtx != null && oldestCtx.address != 0) {
              _freeDecoder(oldestCtx);
            }
          }

          final Pointer<Utf8> pathPtr = params.filePath.toNativeUtf8();
          final Pointer<Int32> wPtr = calloc<Int32>();
          final Pointer<Int32> hPtr = calloc<Int32>();
          try {
            final Pointer<Opaque> newCtx = _initDecoder(
              pathPtr,
              params.cropBorders,
              wPtr,
              hPtr,
            );
            if (newCtx.address == 0) {
              responsePort.send({
                'success': false,
                'error':
                    "Failed to initialize decoder for file: ${params.filePath}",
              });
              return;
            }
            ctx = newCtx;
            cachedContexts[key] = ctx;
            lruOrder[key] = true; // O(1) insertion at end
            imgWidth = wPtr.value;
            imgHeight = hPtr.value;
            cachedDimensions[key] = [imgWidth, imgHeight];
          } catch (e) {
            responsePort.send({
              'success': false,
              'error': "Error initializing FFI decoder: $e",
            });
            return;
          } finally {
            calloc.free(pathPtr);
            calloc.free(wPtr);
            calloc.free(hPtr);
          }
        } else {
          // Update LRU order: O(1) — remove and re-insert at end
          lruOrder.remove(key);
          lruOrder[key] = true;
          final dims = cachedDimensions[key]!;
          imgWidth = dims[0];
          imgHeight = dims[1];
        }

        if (action == 'getDimensions') {
          responsePort.send({
            'success': true,
            'width': imgWidth,
            'height': imgHeight,
          });
          return;
        }

        // Calculates required size for destination pixel buffer (RGBA)
        final int rectWidth = params.right - params.left;
        final int rectHeight = params.bottom - params.top;
        final int destWidth = rectWidth ~/ params.sampleSize;
        final int destHeight = rectHeight ~/ params.sampleSize;
        final int bufferSize = destWidth * destHeight * 4;

        final Pointer<Uint8> rgbaBuffer = calloc<Uint8>(bufferSize);

        try {
          final bool success = _decodeRegion(
            ctx,
            params.left,
            params.top,
            params.right,
            params.bottom,
            params.sampleSize,
            rgbaBuffer,
          );

          if (!success) {
            calloc.free(rgbaBuffer);
            responsePort.send({'error': "Region decoding failed."});
            return;
          }

          responsePort.send({
            'success': true,
            'pointerAddress': rgbaBuffer.address,
            'width': imgWidth,
            'height': imgHeight,
          });
        } catch (e) {
          calloc.free(rgbaBuffer);
          responsePort.send({'success': false, 'error': "FFI error: $e"});
        }
      } else if (message == 'dispose') {
        for (final ctx in cachedContexts.values) {
          if (ctx.address != 0) {
            _freeDecoder(ctx);
          }
        }
        cachedContexts.clear();
        lruOrder.clear();
        cachedDimensions.clear();
        receivePort.close();
      }
    });
  }

  Future<DecodeResult?> decodeRegionAsync(
    DecodeParams params, {
    Object? cancelToken,
  }) async {
    // 0.5.7 (QA2): native library unusable, or the page already went to the
    // Flutter-codec fallback -> decode the region in Dart.
    // 0.5.7 (P8F): page handled by the direct (ui.Image) path.
    if (_directRouted.contains(params.filePath)) {
      return _directRegion(params);
    }
    if (_dartRouted.contains(params.filePath) || !nativeAvailable) {
      _dartRouted.add(params.filePath);
      return _dartRegion(params);
    }
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
    await start();
    if (_sendPort == null) {
      if (kDebugMode) {
        print('FfiImageDecoder isolate is not running');
      }
      return null;
    }

    final completer = Completer<DecodeResult?>();
    final job = _DecodeJob(
      params: params,
      completer: completer,
      cancelToken: cancelToken,
    );

    _queue.add(job);
    _processNext();

    return completer.future;
  }

  // ── YomiHub 0.5.7 (P7F): Android 6–10 ────────────────────────────────────
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
    if (_directRouted.contains(filePath)) {
      final d = await _directDims(filePath);
      if (d != null) return d;
    }
    if (_dartRouted.contains(filePath) || !nativeAvailable) {
      if (!nativeAvailable) _logFallbackOnce('native library not loadable');
      if (_useDirect && !_dartRouted.contains(filePath)) {
        final d = await _directDims(filePath);
        if (d != null) return d;
      }
      return _dartDims(filePath);
    }
    final known = _legacyBmp[filePath];
    if (known != null && !await File(known).exists()) {
      _legacyBmp.remove(filePath);
    }
    final job = await _dimensionsJob(
      _legacyBmp[filePath] ?? filePath,
      cropBorders: cropBorders,
      cancelToken: cancelToken,
    );
    if (job == null) {
      // The isolate could not start: nothing native will ever work.
      _logFallbackOnce('decoder isolate not running');
      if (_useDirect) {
        final d = await _directDims(filePath);
        if (d != null) return d;
      }
      return _dartDims(filePath);
    }
    var dims = await job.completer.future as List<int>?;
    var failed = dims == null || dims[0] == 0 || dims[1] == 0;
    // 0.5.7 (P8F): Android < 11 - AImageDecoder is missing, so the native
    // decoder returns nothing for JPEG/PNG/WebP. On the Note 9 (Android 10,
    // release build) the BMP / RGBA fallbacks below never answered
    // (Image.toByteData did not complete) and the page spun forever. The page
    // is now decoded by Flutter's codec and drawn as a ui.Image directly: no
    // pixel read-back, no temporary file.
    if (failed && !job.cancelled && _legacyBmp[filePath] == null && _useDirect) {
      _logFallbackOnce('native decoder returned no image (Android < 11?)');
      final d = await _directDims(filePath);
      if (d != null) return d;
    }
    if (failed &&
        !job.cancelled &&
        _legacyBmp[filePath] == null &&
        (Platform.isAndroid || debugForceLegacyBmp)) {
      _logFallbackOnce('native decoder returned no image (Android < 11?)');
      final bmp = await _legacyBmpFor(filePath).timeout(
        kDecodeStepTimeout,
        onTimeout: () {
          _logStageTimeout('legacy-bmp', filePath);
          return null;
        },
      );
      if (bmp != null) {
        _legacyBmp[filePath] = bmp;
        final retry = await _dimensionsJob(
          bmp,
          cropBorders: cropBorders,
          cancelToken: cancelToken,
        );
        if (retry != null) {
          dims = await retry.completer.future as List<int>?;
          if (dims == null && !retry.cancelled) _legacyBmp.remove(filePath);
          failed = dims == null || dims[0] == 0 || dims[1] == 0;
        }
      }
    }
    // 0.5.7 (QA2): last resort - Flutter's own codec, whole page in memory.
    if (failed && !job.cancelled) {
      _logFallbackOnce('native decoder and BMP path failed');
      final d = await _dartDims(filePath).timeout(
        kDecodeStepTimeout,
        onTimeout: () {
          _logStageTimeout('dart-rgba', filePath);
          return null;
        },
      );
      if (d != null) return d;
    }
    return dims;
  }

  // ── YomiHub 0.5.7 (P8F): direct ui.Image path (Android < 11) ────────────
  // The page is decoded once by Flutter's codec (the same code that draws
  // covers) and handed to the viewers as a ui.Image. Nothing is read back
  // from the GPU and no file is written, so there is nothing left to hang.
  // cropBorders is not applied in this mode.
  final Set<String> _directRouted = {};
  final Map<String, Future<ui.Image?>> _directImages = {};
  static const int _directKeep = 4;
  static const int _directMaxSide = 8192;

  /// Test hook: use the direct path on this (non-Android) platform too.
  @visibleForTesting
  static bool debugForceDirect = false;

  /// Test hook: collects the step-timeout warnings instead of the app log.
  @visibleForTesting
  static void Function(String message)? debugTimeoutLog;

  /// Test hook: replaces the Flutter codec of the direct path.
  @visibleForTesting
  static Future<ui.Image?> Function(String filePath)? debugDirectDecoder;

  static bool get _useDirect =>
      debugForceDirect || (Platform.isAndroid && !debugForceLegacyBmp);

  @visibleForTesting
  bool debugIsDirect(String filePath) => _directRouted.contains(filePath);

  /// Forget everything cached for [filePath] ("Thử lại" in the reader).
  void forget(String filePath) {
    _directRouted.remove(filePath);
    _dartRouted.remove(filePath);
    _dartPages.remove(filePath);
    final f = _directImages.remove(filePath);
    f?.then((i) => i?.dispose()).catchError((_) {});
  }

  /// Target size for a page of [w] x [h]: null when it fits as is.
  @visibleForTesting
  static List<int>? directTargetSize(int w, int h) {
    if (w <= 0 || h <= 0) return null;
    var k = 1.0;
    if (w > _directMaxSide) k = math.min(k, _directMaxSide / w);
    if (h > _directMaxSide) k = math.min(k, _directMaxSide / h);
    if (w * h > _dartMaxPixels) {
      k = math.min(k, math.sqrt(_dartMaxPixels / (w * h)));
    }
    if (k >= 1.0) return null;
    return [math.max(1, (w * k).floor()), math.max(1, (h * k).floor())];
  }

  static final Set<String> _timeoutLogged = {};

  static void _logStageTimeout(String stage, String filePath) {
    if (!_timeoutLogged.add(stage)) return;
    final msg =
        '[Reader] Giải mã ảnh quá hạn ${kDecodeStepTimeout.inSeconds}s ở bước '
        '$stage (${p.basename(filePath)}) - bỏ qua bước này';
    try {
      final h = debugTimeoutLog;
      if (h != null) {
        h(msg);
      } else {
        AppLogger.log(msg, logLevel: LogLevel.warning);
      }
    } catch (_) {}
  }

  @visibleForTesting
  static void debugResetTimeoutLog() => _timeoutLogged.clear();

  Future<List<int>?> _directDims(String filePath) async {
    final img = await _directImage(filePath);
    if (img == null) return null;
    try {
      final d = [img.width, img.height];
      _directRouted.add(filePath);
      return d;
    } catch (_) {
      return null; // disposed meanwhile
    }
  }

  Future<ui.Image?> _directImage(String filePath) {
    final cached = _directImages.remove(filePath);
    final fut =
        cached ??
        _decodeDirect(filePath).timeout(
          kDecodeStepTimeout,
          onTimeout: () {
            _logStageTimeout('flutter-codec', filePath);
            return null;
          },
        );
    _directImages[filePath] = fut; // most recently used last
    while (_directImages.length > _directKeep) {
      final old = _directImages.remove(_directImages.keys.first);
      old?.then((i) => i?.dispose()).catchError((_) {});
    }
    fut.then((v) {
      if (v == null && identical(_directImages[filePath], fut)) {
        _directImages.remove(filePath);
        _directRouted.remove(filePath);
      }
    }).catchError((_) {});
    return fut;
  }

  Future<ui.Image?> _decodeDirect(String filePath) async {
    final custom = debugDirectDecoder;
    if (custom != null) return custom(filePath);
    ui.Codec? codec;
    try {
      final bytes = await File(filePath).readAsBytes();
      if (bytes.length < 12) return null;
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      try {
        final desc = await ui.ImageDescriptor.encoded(buffer);
        try {
          final t = directTargetSize(desc.width, desc.height);
          if (desc.width <= 0 || desc.height <= 0) return null;
          codec = await desc.instantiateCodec(
            targetWidth: t?[0],
            targetHeight: t?[1],
          );
          return (await codec.getNextFrame()).image;
        } finally {
          desc.dispose();
        }
      } finally {
        buffer.dispose();
      }
    } catch (e) {
      if (kDebugMode) print('FfiImageDecoder direct path failed: $e');
      return null;
    } finally {
      codec?.dispose();
    }
  }

  Future<DecodeResult?> _directRegion(DecodeParams params) async {
    final img = await _directImage(params.filePath);
    if (img == null) {
      return DecodeResult(error: 'Flutter codec could not decode the image');
    }
    try {
      final w = img.width, h = img.height;
      final full =
          params.left <= 0 &&
          params.top <= 0 &&
          params.right >= w &&
          params.bottom >= h;
      if (full) {
        return DecodeResult(image: img.clone(), width: w, height: h);
      }
      // A part of the page (split wide pages): cut it out on the GPU.
      final rw = params.right - params.left, rh = params.bottom - params.top;
      if (rw <= 0 || rh <= 0) return DecodeResult(error: 'Empty region');
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImageRect(
        img,
        ui.Rect.fromLTRB(
          params.left.toDouble(),
          params.top.toDouble(),
          params.right.toDouble(),
          params.bottom.toDouble(),
        ),
        ui.Rect.fromLTWH(0, 0, rw.toDouble(), rh.toDouble()),
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
      final picture = recorder.endRecording();
      try {
        final part = await picture.toImage(rw, rh).timeout(kDecodeStepTimeout);
        return DecodeResult(image: part, width: w, height: h);
      } finally {
        picture.dispose();
      }
    } catch (e) {
      return DecodeResult(error: 'Direct region failed: $e');
    }
  }

  // ── YomiHub 0.5.7 (QA2): pure-Dart fallback ──────────────────────────────
  // Used when libsubsampling_scale_image_view.so cannot be loaded, its isolate
  // cannot start, or AImageDecoder/BMP both fail (Android 6-10). The page is
  // decoded by Flutter's codec (BitmapFactory underneath) and kept as RGBA;
  // regions are copied out with nearest-neighbour sampling. cropBorders is
  // not applied in this mode. API 30+ never reaches this code unless the
  // native decoder really fails on a file.
  final Set<String> _dartRouted = {};
  final Map<String, Future<_DartPage?>> _dartPages = {};
  static const int _dartKeep = 2;
  static const int _dartMaxPixels = 32 * 1000 * 1000;
  static bool _fallbackLogged = false;

  /// Test hook: pretend the native library is (not) loadable.
  @visibleForTesting
  static bool? debugNativeAvailable;

  /// Test hook: collects the fallback warning instead of the app log.
  @visibleForTesting
  static void Function(String message)? debugFallbackLog;

  @visibleForTesting
  static void debugResetFallbackLog() => _fallbackLogged = false;

  static bool? _nativeOk;

  /// True when the native library and its three entry points resolve.
  static bool get nativeAvailable {
    final forced = debugNativeAvailable;
    if (forced != null) return forced;
    return _nativeOk ??= () {
      try {
        return <Object>[_initDecoder, _decodeRegion, _freeDecoder].length == 3;
      } catch (_) {
        return false;
      }
    }();
  }

  /// Which decoder handles the page next (pure decision, unit-tested).
  @visibleForTesting
  static DecodePath nextDecodePath({
    required bool nativeAvailable,
    required bool nativeFailed,
    required bool bmpTried,
    required bool android,
  }) {
    if (!nativeAvailable) return DecodePath.dart;
    if (!nativeFailed) return DecodePath.native;
    if (android && !bmpTried) return DecodePath.legacyBmp;
    return DecodePath.dart;
  }

  static void _logFallbackOnce(String reason) {
    if (_fallbackLogged) return;
    _fallbackLogged = true;
    final msg =
        '[Reader] Image decoder fallback: $reason - using Flutter codec '
        '(slower, no border crop)';
    try {
      final h = debugFallbackLog;
      if (h != null) {
        h(msg);
      } else {
        AppLogger.log(msg, logLevel: LogLevel.warning);
      }
    } catch (_) {}
  }

  Future<List<int>?> _dartDims(String filePath) async {
    final page = await _dartPage(filePath);
    if (page == null) return null;
    _dartRouted.add(filePath);
    return [page.width, page.height];
  }

  Future<_DartPage?> _dartPage(String filePath) {
    final cached = _dartPages.remove(filePath);
    final fut = cached ?? _decodeDartPage(filePath);
    _dartPages[filePath] = fut; // most recently used last
    while (_dartPages.length > _dartKeep) {
      _dartPages.remove(_dartPages.keys.first);
    }
    fut.then((v) {
      if (v == null && identical(_dartPages[filePath], fut)) {
        _dartPages.remove(filePath);
      }
    });
    return fut;
  }

  Future<_DartPage?> _decodeDartPage(String filePath) async {
    ui.Codec? codec;
    ui.Image? image;
    try {
      final bytes = await File(filePath).readAsBytes();
      if (bytes.length < 12) return null;
      // Read the size first (no pixel decode); very tall webtoon pages are
      // decoded at a reduced size so they cannot exhaust memory.
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      try {
        final desc = await ui.ImageDescriptor.encoded(buffer);
        try {
          final ow = desc.width, oh = desc.height;
          if (ow <= 0 || oh <= 0) return null;
          int? tw, th;
          if (ow * oh > _dartMaxPixels) {
            final k = math.sqrt(_dartMaxPixels / (ow * oh));
            tw = math.max(1, (ow * k).floor());
            th = math.max(1, (oh * k).floor());
          }
          codec = await desc.instantiateCodec(
            targetWidth: tw,
            targetHeight: th,
          );
          // Decode the frame while the descriptor and buffer are still alive.
          image = (await codec.getNextFrame()).image;
        } finally {
          desc.dispose();
        }
      } finally {
        buffer.dispose();
      }
      if (image == null) return null;
      final w = image.width, h = image.height;
      if (w <= 0 || h <= 0) return null;
      final raw = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      if (raw == null) return null;
      Uint32List px;
      if (raw.offsetInBytes % 4 == 0) {
        px = raw.buffer.asUint32List(raw.offsetInBytes, w * h);
      } else {
        px = Uint8List.fromList(
          raw.buffer.asUint8List(raw.offsetInBytes, w * h * 4),
        ).buffer.asUint32List();
      }
      return _DartPage(w, h, px);
    } catch (e) {
      if (kDebugMode) print('FfiImageDecoder Dart fallback failed: $e');
      return null;
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  Future<DecodeResult?> _dartRegion(DecodeParams params) async {
    final page = await _dartPage(params.filePath);
    if (page == null) {
      return DecodeResult(error: 'Dart fallback could not decode the image');
    }
    final s = params.sampleSize < 1 ? 1 : params.sampleSize;
    final destW = (params.right - params.left) ~/ s;
    final destH = (params.bottom - params.top) ~/ s;
    if (destW <= 0 || destH <= 0) {
      return DecodeResult(error: 'Empty region');
    }
    final buf = calloc<Uint8>(destW * destH * 4);
    try {
      final dst = buf.cast<Uint32>().asTypedList(destW * destH);
      final src = page.pixels;
      for (var y = 0; y < destH; y++) {
        var sy = params.top + y * s;
        if (sy < 0) sy = 0;
        if (sy >= page.height) sy = page.height - 1;
        final rowStart = sy * page.width;
        final dstRow = y * destW;
        if (s == 1 && params.left >= 0 && params.left + destW <= page.width) {
          dst.setRange(
            dstRow,
            dstRow + destW,
            src,
            rowStart + params.left,
          );
        } else {
          for (var x = 0; x < destW; x++) {
            var sx = params.left + x * s;
            if (sx < 0) sx = 0;
            if (sx >= page.width) sx = page.width - 1;
            dst[dstRow + x] = src[rowStart + sx];
          }
        }
      }
    } catch (e) {
      calloc.free(buf);
      return DecodeResult(error: 'Dart fallback region failed: $e');
    }
    return DecodeResult(
      pointerAddress: buf.address,
      width: page.width,
      height: page.height,
    );
  }

  Future<_DecodeJob?> _dimensionsJob(
    String filePath, {
    bool cropBorders = false,
    Object? cancelToken,
  }) async {
    await start();
    if (_sendPort == null) {
      if (kDebugMode) {
        print('FfiImageDecoder isolate is not running');
      }
      return null;
    }

    final completer = Completer<List<int>?>();
    final job = _DecodeJob(
      params: DecodeParams(
        filePath: filePath,
        left: 0,
        top: 0,
        right: 0,
        bottom: 0,
        sampleSize: 1,
        cropBorders: cropBorders,
      ),
      completer: completer,
      cancelToken: cancelToken,
      action: 'getDimensions',
    );

    _queue.add(job);
    _processNext();

    return job;
  }

  void _processNext() {
    // Sort once before dispatching, not per iteration.
    // Priority: getDimensions first, then high sampleSize (base layer), LIFO within.
    if (_queue.length > 1) {
      _queue.sort((a, b) {
        final aPriority = a.action == 'getDimensions'
            ? 1000
            : a.params.sampleSize;
        final bPriority = b.action == 'getDimensions'
            ? 1000
            : b.params.sampleSize;
        return bPriority.compareTo(
          aPriority,
        ); // descending: highest priority last for removeLast
      });
    }

    while (_activeJobs < _maxConcurrent && _queue.isNotEmpty) {
      final job = _queue.removeLast();
      _activeJobs++;

      final responsePort = ReceivePort();
      // 0.5.7 (P8F): a job the isolate never answers must not block the
      // queue (3 of them froze every later page until the app restarted).
      var answered = false;
      final watchdog = Timer(kDecodeStepTimeout, () {
        if (answered) return;
        answered = true;
        responsePort.close();
        if (_activeJobs > 0) _activeJobs--;
        _logStageTimeout('native-${job.action ?? 'region'}', job.params.filePath);
        if (!job.completer.isCompleted) {
          if (job.action == 'getDimensions') {
            job.completer.complete(null);
          } else {
            job.completer.complete(DecodeResult(error: 'Timeout'));
          }
        }
        _processNext();
      });
      responsePort.listen((response) {
        if (answered) return;
        answered = true;
        watchdog.cancel();
        responsePort.close();
        if (_activeJobs > 0) _activeJobs--;

        if (!job.completer.isCompleted) {
          if (response is Map<String, dynamic>) {
            if (response['success'] == true) {
              if (job.action == 'getDimensions') {
                job.completer.complete([
                  response['width'] as int,
                  response['height'] as int,
                ]);
              } else {
                final pointerAddress = response['pointerAddress'] as int?;
                job.completer.complete(
                  DecodeResult(
                    pointerAddress: pointerAddress,
                    width: response['width'] as int,
                    height: response['height'] as int,
                  ),
                );
              }
            } else {
              if (kDebugMode) {
                print('Image job failed: ${response['error']}');
              }
              if (job.action == 'getDimensions') {
                job.completer.complete(null);
              } else {
                job.completer.complete(DecodeResult(error: response['error']));
              }
            }
          } else {
            job.completer.complete(null);
          }
        }

        _processNext();
      });

      _sendPort!.send({
        'action': job.action,
        'params': job.params.toJson(),
        'responsePort': responsePort.sendPort,
      });
    }
  }

  bool getImageDimensions(
    String filePath,
    List<int> outSize, {
    bool cropBorders = false,
  }) {
    final Pointer<Utf8> pathPtr = filePath.toNativeUtf8();
    final Pointer<Int32> wPtr = calloc<Int32>();
    final Pointer<Int32> hPtr = calloc<Int32>();

    try {
      final Pointer<Opaque> ctx = _initDecoder(
        pathPtr,
        cropBorders,
        wPtr,
        hPtr,
      );
      if (ctx.address == 0) return false;

      outSize[0] = wPtr.value;
      outSize[1] = hPtr.value;
      _freeDecoder(ctx);
      return true;
    } catch (_) {
      return false;
    } finally {
      calloc.free(pathPtr);
      calloc.free(wPtr);
      calloc.free(hPtr);
    }
  }

  Future<void> stop() async {
    _startFuture = null;
    if (!_isRunning && _cIsolate == null && _receivePort == null) {
      return;
    }

    try {
      _sendPort?.send('dispose');
    } catch (_) {}
    _cIsolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    _sendPort = null;
    _cIsolate = null;
    _receivePort = null;
    _isRunning = false;
    _activeJobs = 0;

    for (final job in _queue) {
      job.cancelled = true;
      if (!job.completer.isCompleted) {
        if (job.action == 'getDimensions') {
          job.completer.complete(null);
        } else {
          job.completer.complete(DecodeResult(error: 'Cancelled'));
        }
      }
    }
    _queue.clear();
  }
}

enum DecodePath { native, legacyBmp, dart }

class _DartPage {
  final int width;
  final int height;
  final Uint32List pixels;
  _DartPage(this.width, this.height, this.pixels);
}

class _DecodeJob {
  final DecodeParams params;
  final Completer<dynamic> completer;
  final Object? cancelToken;
  final String? action;
  bool cancelled = false;

  _DecodeJob({
    required this.params,
    required this.completer,
    this.cancelToken,
    this.action,
  });
}

final ffiImageDecoder = FfiImageDecoder();
