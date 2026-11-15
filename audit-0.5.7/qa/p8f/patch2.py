import io,sys
def load(p):
    s=io.open(p,encoding='utf-8',newline='').read(); return s.replace('\r\n','\n'), ('\r\n' in s)
def save(p,s,crlf):
    if crlf: s=s.replace('\n','\r\n')
    io.open(p,'w',encoding='utf-8',newline='').write(s)
def rep(s,a,b,cnt=1):
    if s.count(a)!=cnt: sys.exit('MISMATCH %d x: %r'%(s.count(a),a[:80]))
    return s.replace(a,b)
D='overlay/lib/modules/manga/reader/subsampling_scale_image_view/src/'
# ---------- ffi: guard _activeJobs
p=D+'ffi_image_decoder.dart'; s,c=load(p)
s=rep(s,'''        answered = true;
        responsePort.close();
        _activeJobs--;
        _logStageTimeout''','''        answered = true;
        responsePort.close();
        if (_activeJobs > 0) _activeJobs--;
        _logStageTimeout''')
s=rep(s,'''        watchdog.cancel();
        responsePort.close();
        _activeJobs--;
''','''        watchdog.cancel();
        responsePort.close();
        if (_activeJobs > 0) _activeJobs--;
''')
save(p,s,c)
# ---------- SSIV
p=D+'subsampling_scale_image_view.dart'; s,c=load(p)
s=rep(s,'''import 'package:mangayomi/utils/image_load_timeout.dart';
''','''import 'package:mangayomi/utils/image_load_timeout.dart';
import 'package:mangayomi/utils/log/logger.dart';
''')
s=rep(s,'''    this.errorMessage,
    required this._reLoadCallback,
  });
''','''    this.errorMessage,
    this.autoRetry = true,
    required this._reLoadCallback,
  });

  /// 0.5.7 (P8F): false when retrying on its own is pointless (the page
  /// could not be decoded in time) - the error stays until "Thử lại".
  final bool autoRetry;
''')
s=rep(s,'''  String? _loadError;
  String? _resolvedFilePath;
''','''  String? _loadError;
  // 0.5.7 (P8F): decoding watchdog - the spinner can never outlive it.
  Timer? _decodeWatchdog;
  bool _decodeTimedOut = false;
  String? _resolvedFilePath;
''')
s=rep(s,'''    _resizeTimer?.cancel();
    _cancelImageStream();
    widget.controller?._detach();''','''    _resizeTimer?.cancel();
    _decodeWatchdog?.cancel();
    _cancelImageStream();
    widget.controller?._detach();''')
s=rep(s,'''  Future<void> _loadFromProvider({bool evictCache = false}) async {
    _cancelImageStream();

    if (mounted) {
      setState(() {
        _loadState = LoadState.loading;
        _loadingProgress = null;
        _loadError = null;
        _isInitialized = false;
      });
    }

    if (evictCache) {
      final provider = widget.image;''','''  /// 0.5.7 (P8F): the page file is on disk but was not on screen after
  /// [kImageDecodeBackstop] - show the error + "Thử lại" instead of spinning.
  void _armDecodeWatchdog() {
    _decodeWatchdog?.cancel();
    _decodeWatchdog = Timer(kImageDecodeBackstop, _onDecodeTimeout);
  }

  void _onDecodeTimeout() {
    if (!mounted || _loadState != LoadState.loading) return;
    final path = _resolvedFilePath ?? '';
    _failDecode(
      'quá ${kImageDecodeBackstop.inSeconds} giây',
      tr('Không giải mã được ảnh sau {sec} giây', {
        'sec': kImageDecodeBackstop.inSeconds,
      }),
      path,
      timedOut: true,
    );
  }

  void _failDecode(
    String why,
    String shown,
    String path, {
    bool timedOut = false,
  }) {
    _decodeWatchdog?.cancel();
    try {
      AppLogger.logOnce(
        'ssiv-decode-fail:$why',
        '[Reader] Không hiển thị được ảnh trang: $why (tệp '
            '${path.split(RegExp(r'[\\\\/]')).last})',
        logLevel: LogLevel.warning,
      );
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _loadState = LoadState.failed;
      _decodeTimedOut = timedOut;
      _loadError = shown;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onError?.call('Image decode failed: $why');
    });
  }

  Future<void> _loadFromProvider({bool evictCache = false}) async {
    _cancelImageStream();
    _decodeWatchdog?.cancel();
    _decodeTimedOut = false;

    if (mounted) {
      setState(() {
        _loadState = LoadState.loading;
        _loadingProgress = null;
        _loadError = null;
        _isInitialized = false;
      });
    }

    if (evictCache) {
      final stale = _resolvedFilePath;
      if (stale != null) ffiImageDecoder.forget(stale);
      final provider = widget.image;''')
s=rep(s,'''    errorMessage: _loadError,
    reLoadCallback:''','''    errorMessage: _loadError,
    autoRetry: !_decodeTimedOut,
    reLoadCallback:''')
s=rep(s,'''    var path = _resolvedFilePath;
    if (path == null) return;

    var outSize''','''    var path = _resolvedFilePath;
    if (path == null) return;
    if (_loadState == LoadState.loading) _armDecodeWatchdog();

    var outSize''')
s=rep(s,'''      if (mounted) {
        setState(() => _loadState = LoadState.failed);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onError?.call(msg);
        });
      }
      return;''','''      if (mounted) {
        _failDecode(
          'không đọc được kích thước ảnh',
          tr('Tệp ảnh hỏng hoặc định dạng không hỗ trợ'),
          path,
        );
      }
      return;''')
s=rep(s,'''    ffiImageDecoder.decodeRegionAsync(params, cancelToken: tile).then((result) {
      if (result == null) return;
      if (result.pointerAddress != null) {''','''    ffiImageDecoder.decodeRegionAsync(params, cancelToken: tile).then((result) {
      if (result == null) {
        tile.loading = false;
        _onTileFailed(tile, 'bộ giải mã không chạy');
        return;
      }
      // 0.5.7 (P8F): Android < 11 - the page arrives as a ready ui.Image.
      final direct = result.image;
      if (direct != null) {
        if (!mounted) {
          direct.dispose();
          return;
        }
        tile.image?.dispose();
        tile.image = direct;
        tile.loading = false;
        if (_loadState != LoadState.completed) {
          _decodeWatchdog?.cancel();
          _loadState = LoadState.completed;
          _notifyStateChanged();
          widget.onReady?.call();
          widget.onImageLoaded?.call(_sWidth, _sHeight);
        }
        _scheduleBatchRebuild();
        return;
      }
      if (result.pointerAddress != null) {''')
s=rep(s,'''              if (_loadState != LoadState.completed) {
                _loadState = LoadState.completed;
                _notifyStateChanged();''','''              if (_loadState != LoadState.completed) {
                _decodeWatchdog?.cancel();
                _loadState = LoadState.completed;
                _notifyStateChanged();''')
s=rep(s,'''          widget.onTileError?.call(msg);
        }
      }
    });
  }''','''          widget.onTileError?.call(msg);
          _onTileFailed(tile, msg);
        }
      }
    });
  }

  /// 0.5.7 (P8F): the first (base) tile failed - before this the page kept
  /// its spinner forever because nothing left the loading state.
  void _onTileFailed(Tile tile, String msg) {
    if (!mounted || _loadState != LoadState.loading) return;
    if (tile.sampleSize != _tilingEngine.fullImageSampleSize) return;
    _failDecode(
      'giải mã thất bại ($msg)',
      tr('Tệp ảnh hỏng hoặc định dạng không hỗ trợ'),
      _resolvedFilePath ?? '',
    );
  }''')
save(p,s,c)
# ---------- timeout const
p='overlay/lib/utils/image_load_timeout.dart'; s,c=load(p)
s=rep(s,'''/// Thrown when an image request exceeded [timeout].''','''/// 0.5.7 (P8F): once the page file is on disk, how long the reader waits for
/// it to be decoded and drawn before it shows "Không tải được ảnh này".
const Duration kImageDecodeBackstop = Duration(seconds: 30);

/// Thrown when an image request exceeded [timeout].''')
save(p,s,c)
# ---------- reader page content
p='overlay/lib/modules/manga/reader/widgets/reader_page_content.dart'; s,c=load(p)
s=rep(s,'''          if (tries < 2) {
            _autoRetries[key] = tries + 1;''','''          if (tries < 2 && state.autoRetry) {
            _autoRetries[key] = tries + 1;''')
save(p,s,c)
# ---------- min view
p=D+'min_subsampling_image_view.dart'; s,c=load(p)
s=rep(s,'''  Future<void> _loadFromPath(String path) async {
    if (!mounted) return;

    try {''','''  Future<void> _loadFromPath(String path) async {
    if (!mounted) return;

    // 0.5.7 (P8F): decoding backstop - never spin forever on a page that is
    // already on disk.
    _loadTimer?.cancel();
    _loadTimer = Timer(kImageDecodeBackstop, () {
      if (!mounted || !_isLoading) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
        _loadingProgress = null;
        _loadError = tr('Không giải mã được ảnh sau {sec} giây', {
          'sec': kImageDecodeBackstop.inSeconds,
        });
      });
      widget.failedToLoadImage(true);
    });

    try {''')
s=rep(s,'''      if (result.pointerAddress == null || result.error != null) {
        throw Exception(result.error ?? "Failed to decode region");
      }
''','''      // 0.5.7 (P8F): Android < 11 - the page arrives as a ready ui.Image.
      final direct = result.image;
      if (direct != null) {
        _loadTimer?.cancel();
        if (mounted) {
          widget.data.resolvedFilePath = path;
          widget.data.decodedImage?.dispose();
          widget.data.decodedImage = direct.clone();
          final old = _uiImage;
          setState(() {
            _uiImage = direct;
            _isLoading = false;
            _hasError = false;
          });
          old?.dispose();
          widget.failedToLoadImage(false);
          widget.onImageLoaded?.call(
            croppedWidth.toDouble(),
            croppedHeight.toDouble(),
          );
        } else {
          direct.dispose();
        }
        return;
      }

      if (result.pointerAddress == null || result.error != null) {
        throw Exception(result.error ?? "Failed to decode region");
      }
''')
save(p,s,c)
print('ok all')
