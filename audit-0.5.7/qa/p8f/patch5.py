import io,sys
R='overlay/'
def sub(path, old, new, count=1):
    s=io.open(R+path,encoding='utf-8',newline='').read()
    nl='\r\n' if '\r\n' in s else '\n'
    o=old.replace('\n',nl); n=new.replace('\n',nl)
    assert s.count(o)==count, (path, s.count(o), old[:60])
    io.open(R+path,'w',encoding='utf-8',newline='').write(s.replace(o,n))

# ---------- resume_policy.dart
P='lib/yomihub/player/resume_policy.dart'
sub(P,"""  static const stableFor = Duration(seconds: 3);
""","""  static const stableFor = Duration(seconds: 3);

  /// 0.5.7 (P8F-2): how far past the target a seek may land and still count
  /// as "resumed". HLS sources seek to a segment boundary: on the Note 9 a
  /// seek to 55:59 always landed at 56:20 (+21 s, mpv log), the position was
  /// never "near" and the loop seeked 8 times in 20 s.
  static const landSlack = Duration(seconds: 60);

  /// Seeks one resume may send (the first one + one retry).
  static const maxSeeks = 2;
""")
sub(P,"""    Duration sinceSeek = Duration.zero,
  }) {
    final diff = position - target;""","""    Duration sinceSeek = Duration.zero,
    bool afterSeek = false,
  }) {
    final diff = position - target;""")
sub(P,"""    final ahead = tolerance +
        Duration(milliseconds: (run.inMilliseconds * (rate <= 0 ? 1.0 : rate)).round());""","""    // P8F-2: once a seek was sent, landing a little further (segment
    // boundary) is the resume position - never seek again for that.
    final ahead = tolerance +
        (afterSeek ? landSlack : Duration.zero) +
        Duration(milliseconds: (run.inMilliseconds * (rate <= 0 ? 1.0 : rate)).round());""")
sub(P,"""    int tries = 0,
    int maxTries = 8,
    bool expired = false,
    Duration sinceSeek = Duration.zero,
  }) {
    if (target <= Duration.zero) return ResumeStep.confirmed;
    if (isNear(
      target: target,
      position: position,
      stable: stable,
      rate: rate,
      sinceSeek: sinceSeek,
    )) {""","""    int tries = 0,
    int maxTries = maxSeeks,
    bool expired = false,
    Duration sinceSeek = Duration.zero,
    bool advancing = true,
  }) {
    if (target <= Duration.zero) return ResumeStep.confirmed;
    if (isNear(
      target: target,
      position: position,
      stable: stable,
      rate: rate,
      sinceSeek: sinceSeek,
      afterSeek: tries > 0,
    )) {""")
sub(P,"""    final ready = duration > Duration.zero &&
        playing &&
        !buffering &&
        position > Duration.zero;""","""    // P8F-2: a position that stands still (stalled / no data) is not a
    // reason to seek again - wait until playback really runs.
    final ready = duration > Duration.zero &&
        playing &&
        !buffering &&
        advancing &&
        position > Duration.zero;""")
sub(P,"""  /// U5 (Zenshin): when does the tracker""","""  /// 0.5.7 (P8F-2): next decoder to try on Android when a video plays (sound,
  /// position advancing) but the decoder never reports a picture size.
  /// Order: direct MediaCodec -> MediaCodec with copy-back -> software.
  /// Returns null when there is nothing left to try.
  static String? nextHwdecFallback(String current) {
    switch (current.trim().toLowerCase()) {
      case 'no':
        return null;
      case 'mediacodec-copy':
      case 'auto-copy':
      case 'auto-copy-safe':
        return 'no';
      default: // auto, auto-safe, mediacodec, yes, ...
        return 'mediacodec-copy';
    }
  }

  /// Should the decoder fallback above run now?
  static bool videoStuckWithoutPicture({
    required bool playing,
    required bool hasVideoTrack,
    required int? width,
    required int? height,
    required Duration advancingFor,
    Duration limit = const Duration(seconds: 8),
  }) =>
      playing &&
      hasVideoTrack &&
      ((width ?? 0) <= 0 || (height ?? 0) <= 0) &&
      advancingFor >= limit;

  /// U5 (Zenshin): when does the tracker""")

# ---------- yomi_pip.dart
P='lib/yomihub/player/yomi_pip.dart'
sub(P,"""    required int? width,
    required int? height,
  }) =>
      playing && !buffering && (width ?? 0) > 0 && (height ?? 0) > 0;""","""    required int? width,
    required int? height,
    bool advancing = true,
    bool resumePending = false,
  }) =>
      // P8F-2: also not while the position stands still or the "resume where
      // I stopped" seek is still running (decoder flushed -> black window).
      playing &&
      !buffering &&
      advancing &&
      !resumePending &&
      (width ?? 0) > 0 &&
      (height ?? 0) > 0;""")

# ---------- anime_player_view.dart
P='lib/modules/anime/anime_player_view.dart'
sub(P,"""  void _unifiedPositionHandler(Duration position) {
    final currentSecs = position.inSeconds;""","""  // 0.5.7 (P8F-2): when the position last moved / since when it has been
  // moving without a pause (Back -> PiP, decoder fallback).
  Duration _yhLastPos = Duration.zero;
  DateTime? _yhPosMovedAt;
  DateTime? _yhPosRunSince;
  bool get _yhPositionAdvancing {
    final at = _yhPosMovedAt;
    return at != null &&
        DateTime.now().difference(at) < const Duration(milliseconds: 1500);
  }

  void _unifiedPositionHandler(Duration position) {
    if (position != _yhLastPos) {
      final now = DateTime.now();
      final last = _yhPosMovedAt;
      if (last == null ||
          now.difference(last) > const Duration(milliseconds: 1500)) {
        _yhPosRunSince = now;
      }
      _yhPosMovedAt = now;
      _yhLastPos = position;
    }
    final currentSecs = position.inSeconds;""")
sub(P,"""    unawaited(_audioWatchdog());
    _yhSaveTimer ??=""","""    unawaited(_audioWatchdog());
    unawaited(_yhVideoWatchdog(sessionId));
    _yhSaveTimer ??=""")
sub(P,"""  /// 0.4.9 (kiểm thử lại Note 9, 03/11/2026): the verified seek above still""","""  /// 0.5.7 (P8F-2): sound + advancing position but the decoder never reports
  /// a picture size -> try MediaCodec with copy-back, then software decoding.
  /// (On the Note 9 the black picture was NOT this - mpv rendered fine and the
  /// frame was lost in Flutter's texture, see MainActivity - but a decoder
  /// that yields nothing must not leave the viewer with sound only.)
  Future<void> _yhVideoWatchdog(int sessionId) async {
    if (!Platform.isAndroid) return;
    var current = hwdecMode;
    for (var round = 0; round < 2; round++) {
      for (var i = 0; i < 40; i++) {
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!mounted || _mediaSessionId != sessionId) return;
        final st = _player.state;
        if ((st.width ?? 0) > 0 && (st.height ?? 0) > 0) return;
        final since = _yhPosRunSince;
        final stuck = YomiResumePolicy.videoStuckWithoutPicture(
          playing: st.playing,
          hasVideoTrack: st.tracks.video.any(
            (t) => t.id != 'auto' && t.id != 'no',
          ),
          width: st.width,
          height: st.height,
          advancingFor: (_yhPositionAdvancing && since != null)
              ? DateTime.now().difference(since)
              : Duration.zero,
        );
        if (!stuck) continue;
        final next = YomiResumePolicy.nextHwdecFallback(current);
        if (next == null) return;
        AppLogger.log(
          '[Trình phát] Video có tiếng nhưng bộ giải mã "$current" không ra hình sau 8 giây (tập "${widget.episode.name}") – thử lại với bộ giải mã "$next"',
          logLevel: LogLevel.warning,
        );
        try {
          final p = _player.platform;
          if (p is NativePlayer) {
            await p.setProperty('hwdec', next, waitForInitialization: false);
          }
        } catch (e) {
          AppLogger.log(
            '[Trình phát] Không đổi được bộ giải mã sang "$next": $e',
            logLevel: LogLevel.warning,
          );
          return;
        }
        current = next;
        _yhPosRunSince = DateTime.now();
        break;
      }
    }
  }

  /// 0.4.9 (kiểm thử lại Note 9, 03/11/2026): the verified seek above still""")
sub(P,"""    var baselineAt = began;
    DateTime? okSince;""","""    var baselineAt = began;
    var lastPos = _player.state.position;
    DateTime? okSince;""")
sub(P,"""      final stable = okSince == null ? Duration.zero : now.difference(okSince);
      final step = YomiResumePolicy.step(""","""      final stable = okSince == null ? Duration.zero : now.difference(okSince);
      // P8F-2: never seek again while the position stands still.
      final advancing = st.position != lastPos;
      lastPos = st.position;
      final step = YomiResumePolicy.step(""")
sub(P,"""        sinceSeek: tries > 0 ? now.difference(baselineAt) : Duration.zero,
      );
      if (step == ResumeStep.wait) {""","""        sinceSeek: tries > 0 ? now.difference(baselineAt) : Duration.zero,
        advancing: advancing,
      );
      if (step == ResumeStep.wait) {""")
sub(P,"""          sinceSeek: tries > 0 ? now.difference(baselineAt) : Duration.zero,
        )) {
          reached = true;""","""          sinceSeek: tries > 0 ? now.difference(baselineAt) : Duration.zero,
          afterSeek: tries > 0,
        )) {
          reached = true;""")
sub(P,"""        _hasResumeTargetCompleted = true;
        AppLogger.log(
          "[Trình phát] Đã tiếp tục xem video tại ${start.inSeconds}s thành công",
          logLevel: LogLevel.info,
        );""","""        _hasResumeTargetCompleted = true;
        final landed = st.position - start;
        AppLogger.log(
          landed > const Duration(seconds: 8)
              ? "[Trình phát] Đã tiếp tục xem video tại ${YomiResumePolicy.clock(st.position)} (nguồn chỉ tua được tới mốc gần nhất sau ${YomiResumePolicy.clock(start)})"
              : "[Trình phát] Đã tiếp tục xem video tại ${start.inSeconds}s thành công",
          logLevel: LogLevel.info,
        );""")
sub(P,"""                buffering: st.buffering,
                width: st.width,
                height: st.height,
              )) {""","""                buffering: st.buffering,
                width: st.width,
                height: st.height,
                advancing: _yhPositionAdvancing,
                resumePending: !_hasResumeTargetCompleted &&
                    _initialResumeTarget > Duration.zero,
              )) {""")

# ---------- MainActivity.kt
P='android/app/src/main/kotlin/com/kodjodevf/mangayomi/MainActivity.kt'
sub(P,"""class MainActivity: FlutterFragmentActivity() {
""","""class MainActivity: FlutterFragmentActivity() {

    // YomiHub 0.5.7 (P8F-2): "video has sound but a black picture" on the
    // Galaxy Note 9 (Android 10, Exynos 9810 / Mali-G72). mpv decoded and
    // rendered every frame (its own window screenshot showed the film), the
    // picture was lost afterwards: from Android 10 on Flutter backs video
    // textures with ImageReader / HardwareBuffer, which is defective on some
    // Android <= 10 devices (Flutter itself already avoids it for Huawei
    // <= API 29, flutter/flutter#166481, #156459, #154068). On Android <= 10
    // YomiHub therefore uses the classic SurfaceTexture path for every
    // device. SurfaceTexture is only defined for the OpenGL renderers, so
    // Impeller (which may pick Vulkan) is switched off there as well - the
    // same renderer Android 9 and older already get.
    private fun yhUseLegacyVideoTextures() {
        if (Build.VERSION.SDK_INT > 29) return
        try {
            val f = Class.forName("io.flutter.embedding.engine.renderer.FlutterRenderer")
                .getField("debugForceSurfaceProducerGlTextures")
            f.setBoolean(null, true)
            if (intent != null && !intent.hasExtra("enable-impeller")) {
                intent.putExtra("enable-impeller", false)
            }
            android.util.Log.i("YomiHub", "Android <= 10: SurfaceTexture video textures, Impeller off")
        } catch (e: Throwable) {
            android.util.Log.w("YomiHub", "legacy video textures not available: $e")
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        // must run before super.onCreate(): the Flutter fragment reads the
        // shell arguments from the intent when it is created.
        yhUseLegacyVideoTextures()
        super.onCreate(savedInstanceState)
    }
""")
print('patched OK')
