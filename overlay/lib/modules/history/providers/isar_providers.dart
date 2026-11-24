import 'package:mangayomi/models/update.dart';
import 'package:mangayomi/models/history.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/repositories/history_repository.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/repositories/update_repository.dart';
import 'package:mangayomi/yomihub/perf/updates_preload.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'isar_providers.g.dart';

@riverpod
Stream<List<History>> getAllHistoryStream(
  Ref ref, {
  required ItemType itemType,
  String search = "",
}) async* {
  yield* historyRepository.watchByItemTypeAndSearch(itemType, search);
}

@Riverpod(keepAlive: true)
class ActiveHistoryItemTypeState extends _$ActiveHistoryItemTypeState {
  @override
  ItemType build() => ItemType.manga;

  void set(ItemType type) => state = type;
}

@riverpod
Stream<List<Update>> getAllUpdateStream(
  Ref ref, {
  required ItemType itemType,
  String search = "",
}) {
  // Filtering via .chapter((q) => q.manga(...)) makes Isar walk and fully
  // deserialize the linked Chapter+Manga for every Update row on every watch
  // re-evaluation. Resolving matching manga ids up front (indexed) and
  // filtering Updates by mangaId (also indexed) avoids that link traversal.
  final mangaIdsStream = mangaRepository.watchIdsByItemTypeAndSearch(
    itemType,
    search,
  );
  // 0.6.5 (log 14, Windows: "PlatformDispatcher error: Stack Overflow",
  // 11 646 frames of async* continuations): `await for` + `yield*` into an
  // endless Isar watch never left the first inner stream, so every later
  // manga-id list (library restored: 4 877 series) piled up behind it and
  // was completed in one synchronous chain. Switch to the newest inner stream
  // instead (no async* generator involved).
  // 0.6.0: chapter links resolved off the UI thread before emitting.
  return yomiSwitchMap<List<int>, List<Update>>(
    mangaIdsStream,
    (mangaIds) => updateRepository
        .watchByMangaIds(mangaIds)
        .asyncMap(preloadUpdateChapters),
  );
}
