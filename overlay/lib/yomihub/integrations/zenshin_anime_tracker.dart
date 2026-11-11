import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

/// Zenshin Anime Integration (Smart Episode Parsing & Tracking Sync)
/// Inspired by hitarth-gg/zenshin (Anime streaming & AniList tracking client).
///
/// Features integrated:
/// - Smart episode number extraction from complex filenames & streaming titles
/// - Automatic watch progress threshold (sync when >= 85% watched)
/// - Stream pre-buffering profile configuration
/// - Media title fuzzy matching confidence score
class ZenshinAnimeTracker {
  ZenshinAnimeTracker._();

  static const String prefAutoSync = 'zenshin_auto_sync_progress';
  static const String prefSyncThreshold = 'zenshin_sync_threshold_percent';
  static const String prefPreloadBufferSec = 'zenshin_preload_buffer_sec';

  /// Whether auto-syncing watch progress to AniList/MAL is enabled.
  static bool get autoSyncEnabled => YomiPrefs.get<bool>(prefAutoSync, true);

  /// Progress percentage threshold to trigger auto-sync (default 85%).
  static int get syncThresholdPercent => YomiPrefs.get<int>(prefSyncThreshold, 85);

  /// Preload buffer duration in seconds for video playback.
  static int get preloadBufferSec => YomiPrefs.get<int>(prefPreloadBufferSec, 30);

  /// Extracts episode number from a filename or title string.
  /// Handles patterns like " - 05 ", "E05", "Episode 5", "[05]", "Tập 5", etc.
  static int? parseEpisodeNumber(String title) {
    if (title.isEmpty) return null;

    final patterns = [
      RegExp(r'\b(?:s\d+e|tập|tap|episode|ep|e)\s*(\d+)\b', caseSensitive: false),
      RegExp(r'\[(\d{1,4})\]'),
      RegExp(r'#(\d{1,4})'),
      RegExp(r'\s[-–—]\s*(\d{1,4})(?:v\d+)?\b', caseSensitive: false),
      RegExp(r'[-\s_](\d{1,4})(?:v\d+)?(?:[\s_\.\[\(\]]|$)', caseSensitive: false),
    ];

    for (final reg in patterns) {
      final match = reg.firstMatch(title);
      if (match != null) {
        final numStr = match.group(1);
        if (numStr != null) {
          final parsed = int.tryParse(numStr);
          if (parsed != null && parsed > 0 && parsed < 5000) {
            return parsed;
          }
        }
      }
    }

    return null;
  }

  /// Determines if an episode has reached the watch threshold for auto-sync.
  static bool hasReachedWatchThreshold(Duration position, Duration total) {
    if (total <= Duration.zero || position <= Duration.zero) return false;
    final percent = (position.inMilliseconds / total.inMilliseconds) * 100;
    return percent >= syncThresholdPercent;
  }

  /// Calculates a match confidence score between local title and remote tracker title (0.0 to 1.0).
  static double calculateTitleMatchConfidence(String sourceTitle, String trackerTitle) {
    final s1 = _normalize(sourceTitle);
    final s2 = _normalize(trackerTitle);
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    if (s1 == s2) return 1.0;
    if (s1.contains(s2) || s2.contains(s1)) {
      return 0.85;
    }

    // Bigram similarity (Dice coefficient)
    final b1 = _getBigrams(s1);
    final b2 = _getBigrams(s2);
    if (b1.isEmpty || b2.isEmpty) return 0.0;

    int intersection = 0;
    final b2Copy = List<String>.from(b2);
    for (final bigram in b1) {
      if (b2Copy.remove(bigram)) {
        intersection++;
      }
    }

    return (2.0 * intersection) / (b1.length + b2.length);
  }

  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'\[.*?\]|\(.*?\)|season\s*\d+|part\s*\d+', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> _getBigrams(String s) {
    final list = <String>[];
    for (int i = 0; i < s.length - 1; i++) {
      list.add(s.substring(i, i + 2));
    }
    return list;
  }
}
