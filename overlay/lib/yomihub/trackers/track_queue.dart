import 'dart:async';

import 'package:mangayomi/main.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/track.dart';
import 'package:mangayomi/modules/manga/detail/providers/track_state_providers.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

/// YomiHub 0.1.8: delayed tracker updates (Mihon's DelayedTrackingUpdateJob,
/// Kotatsu's scrobbling queue).
///
/// Reading a chapter / watching an episode offline, or while AniList, MAL,
/// Kitsu, Simkl, Trakt, MangaUpdates, Shikimori or Bangumi is down, used to
/// lose the progress update. Failed updates are queued (track id) and sent
/// again after start-up, when the app comes back to the foreground and
/// every 15 minutes, newest progress wins.
class YomiTrackQueue {
  YomiTrackQueue._();
  static const _key = 'trackQueue';
  static bool _busy = false;
  static Timer? _timer;

  static List<int> get pending => YomiPrefs.get<List>(_key, const []).cast<int>();

  static Future<void> add(Track t) async {
    if (t.id == null) return;
    final q = {...pending, t.id!}.toList();
    await YomiPrefs.set(_key, q);
  }

  static Future<void> _remove(int id) async {
    await YomiPrefs.set(_key, pending.where((e) => e != id).toList());
  }

  static void start(dynamic ref) {
    _timer ??= Timer.periodic(const Duration(minutes: 15), (_) => flush(ref));
    Future.delayed(const Duration(seconds: 20), () => flush(ref));
  }

  static Future<int> flush(dynamic ref) async {
    if (_busy || pending.isEmpty) return 0;
    _busy = true;
    var sent = 0;
    try {
      for (final id in pending) {
        final t = isar.tracks.getSync(id);
        if (t == null || t.mangaId == null) {
          await _remove(id);
          continue;
        }
        final m = isar.mangas.getSync(t.mangaId!);
        final type = m?.itemType ?? ItemType.manga;
        try {
          await ref
              .read(trackStateProvider(track: t, itemType: type, widgetRef: ref).notifier)
              .updateRemote();
          await _remove(id);
          sent++;
        } catch (e) {
          AppLogger.log('Tracker update still pending (${t.syncId} ${t.title}): $e', logLevel: LogLevel.warning);
        }
      }
    } finally {
      _busy = false;
    }
    return sent;
  }
}
