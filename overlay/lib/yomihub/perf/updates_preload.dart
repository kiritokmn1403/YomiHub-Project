// YomiHub 0.6.0 – Updates screen without UI freezes.
//
// Log 18/11/2026 20:16 (0.5.9, Xiaomi Android 16): "Giao diện bị treo 2.7 giây
// (luồng UI bị chặn) • màn hình: /updates" and a 2826 ms frame. The screen's
// build() called `e.chapter.loadSync()` for every Update row – one synchronous
// Isar read per row on the UI thread (thousands of rows after a library
// update), repeated on every rebuild/watch event.
//
// Fix: the provider resolves the chapter links before it emits, in chunks,
// with Isar's async API (runs on Isar's own thread). build() then finds the
// links already loaded and never touches the database row by row.
import 'dart:async';

import 'package:mangayomi/main.dart' show isar;
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/update.dart';
import 'package:mangayomi/utils/log/logger.dart';

const int kUpdatePreloadChunk = 150;

/// 0.6.3: mangas of the Updates rows, loaded off the UI thread by
/// [preloadUpdateChapters]; refreshed on every emit (lastUpdate may change).
final Map<int, Manga> kUpdateMangaCache = {};

/// Loads `chapter` of every [Update] that is not loaded yet, [chunk] at a time.
/// Returns the same list (for `Stream.asyncMap`).
Future<List<Update>> preloadUpdateChapters(
  List<Update> list, {
  int chunk = kUpdatePreloadChunk,
}) async {
  final sw = Stopwatch()..start();
  final pending = [for (final u in list) if (!u.chapter.isLoaded) u];
  for (var i = 0; i < pending.length; i += chunk) {
    final end = (i + chunk) > pending.length ? pending.length : i + chunk;
    await Future.wait([for (final u in pending.sublist(i, end)) _load(u)]);
  }
  // 0.6.3 (log 20/11 08:16: 891 ms frame on /updates although the chapters
  // were preloaded): the screen also read every manga with getAllSync on the
  // UI thread. Load them here with Isar's async API and keep them for build().
  try {
    final ids = <int>{};
    for (final u in list) {
      final c = u.chapter.value;
      final id = c?.mangaId;
      if (id != null) ids.add(id);
    }
    // 0.6.3 review (Codex): rebuild the cache from THIS emit only – a deleted
    // manga (null from Isar) or one that left the list must not linger.
    final fresh = <int, Manga>{};
    if (ids.isNotEmpty) {
      final ms = await isar.mangas.getAll(ids.toList());
      for (final m in ms) {
        if (m?.id != null) fresh[m!.id!] = m;
      }
    }
    kUpdateMangaCache
      ..clear()
      ..addAll(fresh);
  } catch (_) {
    // the screen falls back to a synchronous read
  }
  if (sw.elapsedMilliseconds > 1500) {
    AppLogger.log(
      '[Hiệu năng] Trang Cập nhật: nạp ${pending.length}/${list.length} chương ở nền mất ${sw.elapsedMilliseconds} ms (không chặn giao diện)',
    );
  }
  return list;
}

Future<void> _load(Update u) async {
  try {
    await u.chapter.load();
  } catch (_) {
    // A deleted chapter just stays unresolved; the screen drops that row.
  }
}


/// 0.6.5: "switchMap" without async*: for every [source] event, cancels the
/// previous inner stream and forwards the one built by [map]. Used by the
/// Updates provider (log 14 Stack Overflow, see isar_providers.dart).
Stream<R> yomiSwitchMap<T, R>(Stream<T> source, Stream<R> Function(T) map) {
  StreamSubscription<T>? outer;
  StreamSubscription<R>? inner;
  late final StreamController<R> c;
  c = StreamController<R>(
    onListen: () {
      outer = source.listen(
        (v) {
          final old = inner;
          inner = map(v).listen(c.add, onError: c.addError);
          old?.cancel();
        },
        onError: c.addError,
      );
    },
    onPause: () {
      outer?.pause();
      inner?.pause();
    },
    onResume: () {
      outer?.resume();
      inner?.resume();
    },
    onCancel: () async {
      await inner?.cancel();
      await outer?.cancel();
    },
  );
  return c.stream;
}
