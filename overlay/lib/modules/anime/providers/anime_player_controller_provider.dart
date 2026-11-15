import 'dart:async';

import 'package:flutter_riverpod/misc.dart';
import 'package:mangayomi/repositories/chapter_repository.dart';
import 'package:mangayomi/repositories/db_write_queue.dart';
import 'package:mangayomi/repositories/settings_repository.dart';
import 'package:mangayomi/repositories/track_repository.dart';
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/modules/manga/reader/mixins/chapter_controller_mixin.dart';
import 'package:mangayomi/utils/extensions/chapter_extensions.dart';
import 'package:mangayomi/modules/more/settings/player/providers/player_state_provider.dart';
import 'package:mangayomi/services/aniskip.dart';
import 'package:mangayomi/utils/chapter_recognition.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/utils/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mangayomi/yomihub/integrations/zenshin_anime_tracker.dart';
import 'package:mangayomi/yomihub/player/resume_policy.dart';
import 'package:mangayomi/yomihub/player/resume_store.dart';
part 'anime_player_controller_provider.g.dart';

final fullscreenProvider = StateProvider<bool>(() => false);

@riverpod
class AnimeStreamController extends _$AnimeStreamController
    with ChapterControllerMixin {
  @override
  KeepAliveLink build({required Chapter episode}) {
    _keepAliveLink = ref.keepAlive();
    return _keepAliveLink!;
  }

  KeepAliveLink? _keepAliveLink;
  KeepAliveLink? get keepAliveLink => _keepAliveLink;

  // Bridge the mixin's `chapter` contract to the `episode` build parameter.
  @override
  Chapter get chapter => episode;

  // Keep incognitoMode as a final field (read once, not on every access).
  @override
  final bool incognitoMode = settingsRepository.current.incognitoMode!;

  // ---------------------------------------------------------------------------
  // Anime-flavoured aliases (preserve the existing public API)
  // ---------------------------------------------------------------------------

  (int, bool) getEpisodeIndex() => getChapterIndex();

  Chapter getPrevEpisode() => getPrevChapter();
  Chapter getNextEpisode() => getNextChapter();

  bool get hasPreviousEpisode => hasPreviousChapter;
  bool get hasNextEpisode => hasNextChapter;

  int getEpisodesLength(bool isInFilterList) =>
      getChaptersLength(isInFilterList);

  // ---------------------------------------------------------------------------
  // Playback position
  // ---------------------------------------------------------------------------

  Duration getCurrentPosition() {
    if (incognitoMode) return Duration.zero;
    // YomiHub 0.3.3: Always query the latest persisted chapter from database
    final freshEp =
        (episode.id != null
            ? chapterRepository.findByIdSync(episode.id!)
            : null) ??
        episode;
    final pos = int.tryParse(freshEp.lastPageRead ?? '') ?? 0;
    final total = int.tryParse(freshEp.duration ?? '') ?? 0;
    // 0.5.7 (U7): the database write of the exit position may still be
    // waiting in the write queue – the side store knows the real position.
    return YomiResumePolicy.storedPosition(
      dbPositionMs: pos,
      dbTotalMs: total,
      dbUpdatedAtMs: freshEp.updatedAt ?? 0,
      mark: YomiResumeStore.peek(episode.id),
    );
  }

  int _lastSavedPositionMs = 0;
  // 0.5.7 (U5, Zenshin): the tracker is updated once per playback.
  bool _trackerSynced = false;

  void setCurrentPosition(
    Duration duration,
    Duration? totalDuration, {
    bool save = false,
  }) {
    if (incognitoMode) return;
    final wasRead = episode.isRead ?? false;
    final markEpisodeAsSeenType = ref.read(markEpisodeAsSeenTypeStateProvider);
    final isWatch =
        totalDuration != null &&
            totalDuration != Duration.zero &&
            duration != Duration.zero
        ? duration.inSeconds >=
              ((totalDuration.inSeconds * markEpisodeAsSeenType) / 100).ceil()
        : false;
    final syncTracker = YomiResumePolicy.shouldSyncTracker(
      zenshinEnabled: ZenshinAnimeTracker.autoSyncEnabled,
      reachedThreshold:
          totalDuration != null &&
          ZenshinAnimeTracker.hasReachedWatchThreshold(duration, totalDuration),
      markedSeenNow: isWatch && !wasRead,
      alreadySynced: _trackerSynced,
    );
    if ((isWatch && !wasRead) ||
        save ||
        syncTracker ||
        (duration.inMilliseconds - _lastSavedPositionMs).abs() >= 1000) {
      _lastSavedPositionMs = duration.inMilliseconds;
      final ep = episode.id != null
          ? chapterRepository.findByIdSync(episode.id!)
          : null;
      // A chapter removed while playing must not be resurrected by a timer.
      if (ep == null) return;
      YomiResumeStore.remember(episode.id, duration, totalDuration);
      ep.isRead = isWatch || wasRead;
      ep.lastPageRead = (duration.inMilliseconds).toString();
      if (totalDuration != null && totalDuration > Duration.zero) {
        ep.duration = totalDuration.inMilliseconds.toString();
      }
      ep.updatedAt = DateTime.now().millisecondsSinceEpoch;
      try {
        // 0.5.7 (FC32): a write that fails, or that is still waiting in the
        // database write queue after 20 s, is reported in the app log.
        chapterRepository
            .save(ep)
            .timeout(const Duration(seconds: 20))
            .catchError((Object e, StackTrace stack) {
              AppLogger.logOnce(
                'save_ep_pos_err_${ep.id}',
                e is TimeoutException
                    ? '[Trình phát] Trình phát video không lưu đúng vị trí đã xem: tập "${ep.name}" chờ ghi cơ sở dữ liệu quá 20 giây (hàng đợi ghi đang bận) – vị trí vẫn được giữ ở bộ nhớ phụ'
                    : '[Trình phát] Trình phát video không lưu đúng vị trí đã xem: tập "${ep.name}": $e',
                logLevel: LogLevel.warning,
              );
            });
        episode.lastPageRead = ep.lastPageRead;
        episode.duration = ep.duration;
        episode.isRead = ep.isRead;
      } catch (e, st) {
        AppLogger.log(
          '[Trình phát] Lỗi khi gửi vị trí tập "${ep.name}" vào hàng đợi: $e',
          logLevel: LogLevel.warning,
        );
      }
      if (syncTracker) {
        _trackerSynced = true;
        episode.updateTrackChapterRead(ref);
      }
    }
  }

  /// Persists the terminal playback state before the player route is replaced.
  /// Some backends emit `completed` before their final position event, so the
  /// known total duration is the deterministic terminal position.
  Future<void> completeEpisode(
    Duration totalDuration, {
    int elapsedSeconds = 0,
  }) async {
    if (incognitoMode) return;
    final completedPosition = totalDuration > Duration.zero
        ? totalDuration
        : Duration(milliseconds: int.tryParse(episode.lastPageRead ?? '') ?? 0);
    setCurrentPosition(completedPosition, totalDuration, save: true);
    await setHistoryUpdate(elapsedSeconds: elapsedSeconds);
    await dbWriteQueue.flush();
  }

  // ---------------------------------------------------------------------------
  // AniSkip
  // ---------------------------------------------------------------------------

  (int, int)? _getTrackId() {
    final malId = trackRepository.getMediaIdBySyncAndManga(
      1,
      episode.manga.value!.id!,
    );
    final aniId = trackRepository.getMediaIdBySyncAndManga(
      2,
      episode.manga.value!.id!,
    );
    return switch (malId) {
      != null => (malId, 1),
      == null => switch (aniId) {
        != null => (aniId, 2),
        _ => null,
      },
      _ => null,
    };
  }

  Future<List<Results>?> getAniSkipResults(
    Function(List<Results>) result,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final id = _getTrackId();
    if (id != null) {
      final res = await ref
          .read(aniSkipProvider.notifier)
          .getResult(
            id,
            ChapterRecognition().parseEpisodeNumber(
              episode.manga.value!.name!,
              episode.name!,
            ),
            0,
          );
      result.call(res ?? []);
      return res;
    }
    return null;
  }
}
