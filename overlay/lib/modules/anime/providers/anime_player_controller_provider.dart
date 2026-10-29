import 'package:flutter_riverpod/misc.dart';
import 'package:mangayomi/repositories/chapter_repository.dart';
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
    if (total > 0 && pos >= total) return Duration.zero;
    if (pos >= 1000) return Duration(milliseconds: pos);
    return Duration.zero;
  }

  int _lastSavedPositionMs = 0;

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
    if ((isWatch && !wasRead) ||
        save ||
        (duration.inMilliseconds - _lastSavedPositionMs).abs() >= 1000) {
      _lastSavedPositionMs = duration.inMilliseconds;
      final ep = episode.id != null
          ? chapterRepository.findByIdSync(episode.id!)
          : null;
      // A chapter removed while playing must not be resurrected by a timer.
      if (ep == null) return;
      ep.isRead = isWatch || wasRead;
      ep.lastPageRead = (duration.inMilliseconds).toString();
      if (totalDuration != null && totalDuration > Duration.zero) {
        ep.duration = totalDuration.inMilliseconds.toString();
      }
      ep.updatedAt = DateTime.now().millisecondsSinceEpoch;
      try {
        if (save) {
          chapterRepository.saveSync(ep);
        } else {
          chapterRepository.save(ep).catchError((Object e, StackTrace stack) {
            AppLogger.logOnce(
              'save_ep_pos_err_${ep.id}',
              '[Trình phát] Lỗi không lưu được vị trí đã xem của tập "${ep.name}": $e',
              logLevel: LogLevel.error,
            );
          });
        }
        episode.lastPageRead = ep.lastPageRead;
        episode.duration = ep.duration;
        episode.isRead = ep.isRead;
      } catch (e) {
        AppLogger.logOnce(
          'save_ep_pos_err_${ep.id}',
          '[Trình phát] Lỗi không lưu được vị trí đã xem của tập "${ep.name}": $e',
          logLevel: LogLevel.error,
        );
      }
      if (isWatch && !wasRead) {
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
