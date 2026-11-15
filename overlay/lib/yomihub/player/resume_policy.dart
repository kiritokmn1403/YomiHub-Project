/// YomiHub 0.5.7 (U7 / FC39): pure decisions of the "Resume A Video" flow.
///
/// No Flutter / media_kit / database imports: everything here is unit-tested
/// in `test/yh_057_p3_test.dart`. The player (`anime_player_view.dart`) and
/// the stream controller only feed it plain values.
library;

/// What the resume loop has to do on one tick.
enum ResumeStep {
  /// Nothing yet: the stream is not ready, or playback is settling at the target.
  wait,

  /// Send (another) seek to the target.
  seek,

  /// Playback stayed at the target long enough: resume done.
  confirmed,

  /// Playback reached the target and the viewer then moved somewhere else:
  /// stop fighting the viewer, the resume is over.
  userSeek,

  /// Out of time / attempts.
  giveUp,
}

/// Last position of an episode remembered outside the database.
class ResumeMark {
  final int positionMs;
  final int totalMs;

  /// Wall clock (ms since epoch) when the mark was taken.
  final int atMs;
  const ResumeMark(this.positionMs, this.totalMs, this.atMs);

  List<int> toList() => [positionMs, totalMs, atMs];

  static ResumeMark? fromList(Object? raw) {
    if (raw is! List || raw.length < 3) return null;
    final v = raw.map((e) => e is int ? e : int.tryParse('$e')).toList();
    if (v.any((e) => e == null)) return null;
    return ResumeMark(v[0]!, v[1]!, v[2]!);
  }
}

class YomiResumePolicy {
  YomiResumePolicy._();

  /// A stored position below this is "the beginning" (same rule as before 0.5.7).
  static const minResume = Duration(seconds: 1);
  static const tolerance = Duration(seconds: 2);
  static const stableFor = Duration(seconds: 3);

  /// 0.5.7 (P8F-2): how far past the target a seek may land and still count
  /// as "resumed". HLS sources seek to a segment boundary: on the Note 9 a
  /// seek to 55:59 always landed at 56:20 (+21 s, mpv log), the position was
  /// never "near" and the loop seeked 8 times in 20 s.
  static const landSlack = Duration(seconds: 60);

  /// Seeks one resume may send (the first one + one retry).
  static const maxSeeks = 2;

  /// The database write of a position can still be waiting in the write queue
  /// when the episode is opened again; a mark is only overruled by a database
  /// row that was written clearly after it.
  static const markGraceMs = 2000;

  /// Position to resume at from what is stored for the episode.
  ///
  /// [dbPositionMs]/[dbTotalMs]/[dbUpdatedAtMs] come from the chapter row,
  /// [mark] from the in-memory / Hive side store (may be null).
  static Duration storedPosition({
    required int dbPositionMs,
    required int dbTotalMs,
    int dbUpdatedAtMs = 0,
    ResumeMark? mark,
  }) {
    var pos = dbPositionMs;
    var total = dbTotalMs;
    if (mark != null && dbUpdatedAtMs <= mark.atMs + markGraceMs) {
      pos = mark.positionMs;
      if (mark.totalMs > 0) total = mark.totalMs;
    }
    if (total > 0 && pos >= total) return Duration.zero;
    if (pos >= minResume.inMilliseconds) return Duration(milliseconds: pos);
    return Duration.zero;
  }

  /// Target of a freshly opened media.
  /// Order: position handed over by the floating mini player, then the
  /// position asked for by the caller (server / quality switch), then storage.
  static Duration openTarget({
    required bool resumeEnabled,
    Duration? miniPlayer,
    Duration? explicit,
    required Duration stored,
  }) {
    if (!resumeEnabled) return Duration.zero;
    return miniPlayer ?? explicit ?? stored;
  }

  /// Position to carry to the next server / quality.
  ///
  /// While a resume is still pending the engine reports 0 (or a few seconds):
  /// carrying that value was the 0.5.6 bug "đổi server là xem lại từ đầu".
  /// Returns null when nothing trustworthy is known → the caller falls back
  /// to the stored position.
  static Duration? carryOver({
    required Duration pendingTarget,
    required bool targetCompleted,
    required Duration enginePosition,
    required Duration uiPosition,
    bool live = false,
  }) {
    if (live) return Duration.zero;
    if (!targetCompleted && pendingTarget > Duration.zero) return pendingTarget;
    final pos = enginePosition > Duration.zero ? enginePosition : uiPosition;
    return pos >= minResume ? pos : null;
  }

  /// May the current position be written to storage?
  /// Returns null when it may, otherwise the reason it must not.
  static String? persistBlocker({
    required bool mediaOpenStarted,
    required bool live,
    required bool natureResolved,
    required bool targetCompleted,
    required Duration pendingTarget,
  }) {
    if (!mediaOpenStarted) return 'not-opened';
    if (live) return 'live';
    if (!natureResolved) return 'unresolved';
    if (!targetCompleted && pendingTarget > Duration.zero) return 'resume-pending';
    return null;
  }

  static bool isNear({
    required Duration target,
    required Duration position,
    Duration stable = Duration.zero,
    double rate = 1.0,
    Duration sinceSeek = Duration.zero,
    bool afterSeek = false,
  }) {
    final diff = position - target;
    // 0.5.7 (P8F): playback keeps running after a seek. On the Note 9 a seek
    // finished at once, the next check came 2.5 s later, the position was
    // target + 2.5 s (> tolerance) and the resume seeked again - 8 times in
    // 20 s, each one flushing the decoder (black screen + spinner). The time
    // since the last seek is therefore allowed on top of the tolerance.
    final run = stable > sinceSeek ? stable : sinceSeek;
    // P8F-2: once a seek was sent, landing a little further (segment
    // boundary) is the resume position - never seek again for that.
    final ahead = tolerance +
        (afterSeek ? landSlack : Duration.zero) +
        Duration(milliseconds: (run.inMilliseconds * (rate <= 0 ? 1.0 : rate)).round());
    return diff >= -tolerance && diff <= ahead;
  }

  /// One tick of the resume loop.
  ///
  /// * [stable]: how long playback has stayed near the target (zero if not).
  /// * [reached]: the target was observed at least once since the last seek
  ///   (or since the open, for media opened with a start position).
  /// * [baseline] / [sinceBaseline]: position just before the last seek (zero
  ///   at open) and the time since then – where playback would be had the
  ///   seek been dropped by the backend (HLS variant re-open).
  static ResumeStep step({
    required Duration target,
    required Duration position,
    required Duration duration,
    required bool playing,
    required bool buffering,
    double rate = 1.0,
    Duration stable = Duration.zero,
    bool reached = false,
    Duration baseline = Duration.zero,
    Duration sinceBaseline = Duration.zero,
    int tries = 0,
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
    )) {
      if (playing && !buffering && stable >= stableFor) return ResumeStep.confirmed;
      // Sitting at the target when time runs out is a success, not a failure.
      return expired ? ResumeStep.confirmed : ResumeStep.wait;
    }
    if (reached) {
      final r = rate <= 0 ? 1.0 : rate;
      final ifDropped = baseline +
          Duration(milliseconds: (sinceBaseline.inMilliseconds * r).round()) +
          const Duration(seconds: 5);
      // Anywhere else than "restarted from where it was": the viewer moved.
      if (position > ifDropped) return ResumeStep.userSeek;
    }
    if (expired) return ResumeStep.giveUp;
    // P8F-2: a position that stands still (stalled / no data) is not a
    // reason to seek again - wait until playback really runs.
    final ready = duration > Duration.zero &&
        playing &&
        !buffering &&
        advancing &&
        position > Duration.zero;
    if (!ready) return ResumeStep.wait;
    if (tries >= maxTries) return ResumeStep.giveUp;
    return ResumeStep.seek;
  }

  /// 0.5.7 (P8F-2): next decoder to try on Android when a video plays (sound,
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

  /// U5 (Zenshin): when does the tracker (AniList / MAL / Kitsu…) get the
  /// episode? With Zenshin's auto-sync on: once, when the watch threshold
  /// (85 % by default) is reached. Off: the previous behaviour – the moment
  /// the episode is marked as seen.
  static bool shouldSyncTracker({
    required bool zenshinEnabled,
    required bool reachedThreshold,
    required bool markedSeenNow,
    required bool alreadySynced,
  }) {
    if (alreadySynced) return false;
    return zenshinEnabled ? reachedThreshold : markedSeenNow;
  }

  static String clock(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(d.inMinutes)}:${two(s)}';
  }
}
