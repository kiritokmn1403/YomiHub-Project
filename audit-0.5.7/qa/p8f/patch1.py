import io,sys
p='overlay/lib/modules/manga/reader/subsampling_scale_image_view/src/ffi_image_decoder.dart'
s=io.open(p,encoding='utf-8',newline='').read()
crlf='\r\n' in s
s=s.replace('\r\n','\n')
def rep(a,b,cnt=1):
    global s
    if s.count(a)!=cnt: sys.exit('MISMATCH %d x: %r'%(s.count(a),a[:70]))
    s=s.replace(a,b)

# 1. DecodeResult.image
rep('''  final String? error;

  DecodeResult({
    this.pointerAddress,
    this.width = 0,
    this.height = 0,
    this.error,
  });''','''  final String? error;

  /// 0.5.7 (P8F): a ready-to-draw image instead of an RGBA buffer (the
  /// "direct" path on Android < 11). The receiver owns and disposes it.
  final ui.Image? image;

  DecodeResult({
    this.pointerAddress,
    this.width = 0,
    this.height = 0,
    this.error,
    this.image,
  });''')

# 2. isolate start timeout
rep('''    _sendPort = await completer.future;
    _isRunning = true;''','''    // 0.5.7 (P8F): an isolate that never reports back must not hang every
    // page forever (the caller falls back to the Flutter codec).
    _sendPort = await completer.future.timeout(kDecodeStepTimeout);
    _isRunning = true;''')
rep('''      if (message is SendPort) {
        completer.complete(message);
      }''','''      if (message is SendPort && !completer.isCompleted) {
        completer.complete(message);
      }''')

# 3. routing in decodeRegionAsync
rep('''    if (_dartRouted.contains(params.filePath) || !nativeAvailable) {
      _dartRouted.add(params.filePath);
      return _dartRegion(params);
    }''','''    // 0.5.7 (P8F): page handled by the direct (ui.Image) path.
    if (_directRouted.contains(params.filePath)) {
      return _directRegion(params);
    }
    if (_dartRouted.contains(params.filePath) || !nativeAvailable) {
      _dartRouted.add(params.filePath);
      return _dartRegion(params);
    }''')

# 4. routing in getImageDimensionsAsync
rep('''    if (_dartRouted.contains(filePath) || !nativeAvailable) {
      if (!nativeAvailable) _logFallbackOnce('native library not loadable');
      return _dartDims(filePath);
    }
    final known = _legacyBmp[filePath];''','''    if (_directRouted.contains(filePath)) {
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
    final known = _legacyBmp[filePath];''')
rep('''      _logFallbackOnce('decoder isolate not running');
      return _dartDims(filePath);
    }
    var dims = await job.completer.future as List<int>?;
    var failed = dims == null || dims[0] == 0 || dims[1] == 0;
    if (failed &&''','''      _logFallbackOnce('decoder isolate not running');
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
    if (failed &&''')
rep('''      final bmp = await _legacyBmpFor(filePath);
      if (bmp != null) {''','''      final bmp = await _legacyBmpFor(filePath).timeout(
        kDecodeStepTimeout,
        onTimeout: () {
          _logStageTimeout('legacy-bmp', filePath);
          return null;
        },
      );
      if (bmp != null) {''')
rep('''      _logFallbackOnce('native decoder and BMP path failed');
      final d = await _dartDims(filePath);
      if (d != null) return d;''','''      _logFallbackOnce('native decoder and BMP path failed');
      final d = await _dartDims(filePath).timeout(
        kDecodeStepTimeout,
        onTimeout: () {
          _logStageTimeout('dart-rgba', filePath);
          return null;
        },
      );
      if (d != null) return d;''')

# 5. direct path implementation (before the QA2 section)
rep('''  // ── YomiHub 0.5.7 (QA2): pure-Dart fallback ──''','''  // ── YomiHub 0.5.7 (P8F): direct ui.Image path (Android < 11) ────────────
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

  // ── YomiHub 0.5.7 (QA2): pure-Dart fallback ──''')

# 6. per-job timeout in _processNext
rep('''      final responsePort = ReceivePort();
      responsePort.listen((response) {
        responsePort.close();
        _activeJobs--;
''','''      final responsePort = ReceivePort();
      // 0.5.7 (P8F): a job the isolate never answers must not block the
      // queue (3 of them froze every later page until the app restarted).
      var answered = false;
      final watchdog = Timer(kDecodeStepTimeout, () {
        if (answered) return;
        answered = true;
        responsePort.close();
        _activeJobs--;
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
        _activeJobs--;
''')

# 7. constant
rep('''/// Required parameters to decode an image region
class DecodeParams {''','''/// 0.5.7 (P8F): upper bound for one decoding step (native job, Flutter codec,
/// BMP conversion ...). A step that takes longer is abandoned and the next
/// decoder is tried, so a page can no longer wait forever.
const Duration kDecodeStepTimeout = Duration(seconds: 12);

/// Required parameters to decode an image region
class DecodeParams {''')
if crlf: s=s.replace('\n','\r\n')
io.open(p,'w',encoding='utf-8',newline='').write(s)
print('ok ffi')
