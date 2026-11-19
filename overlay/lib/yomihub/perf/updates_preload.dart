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
import 'package:mangayomi/models/update.dart';
import 'package:mangayomi/utils/log/logger.dart';

const int kUpdatePreloadChunk = 150;

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
