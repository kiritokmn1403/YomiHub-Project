import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/l10n/generated/app_localizations.dart';
import 'package:mangayomi/modules/widgets/base_library_tab_screen.dart';
import 'package:mangayomi/modules/widgets/custom_sliver_grouped_list_view.dart';

import 'package:mangayomi/repositories/chapter_repository.dart';
import 'package:mangayomi/repositories/history_repository.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/models/history.dart';
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/modules/history/providers/isar_providers.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/utils/cached_network.dart';
import 'package:mangayomi/utils/constant.dart';
import 'package:mangayomi/utils/date.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:mangayomi/utils/extensions/chapter_extensions.dart';
import 'package:mangayomi/utils/headers.dart';
import 'package:mangayomi/utils/platform_utils.dart';
import 'package:mangayomi/modules/widgets/error_text.dart';
import 'package:mangayomi/modules/widgets/progress_center.dart';
import 'package:mangayomi/modules/widgets/tv_row_button.dart';
import 'package:mangayomi/modules/library/providers/library_state_provider.dart';
import 'package:mangayomi/modules/library/widgets/library_entry_utils.dart';
import 'package:mangayomi/modules/widgets/bottom_text_widget.dart';
import 'package:mangayomi/modules/widgets/cover_view_widget.dart';
import 'package:mangayomi/modules/widgets/gridview_widget.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends BaseLibraryTabScreenState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    _syncActiveItemType();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncActiveItemType();
  }

  void _syncActiveItemType() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(activeHistoryItemTypeStateProvider.notifier)
            .set(getCurrentItemType());
      }
    });
  }

  @override
  void onTabChanged(ItemType type) {
    ref.read(activeHistoryItemTypeStateProvider.notifier).set(type);
  }

  @override
  String get title => l10nLocalizations(context)!.history;

  @override
  Widget buildTab(ItemType type) {
    return HistoryTab(itemType: type, query: textEditingController.text);
  }

  @override
  List<Widget> buildExtraActions(BuildContext context) {
    final l10n = l10nLocalizations(context)!;

    return [
      IconButton(
        splashRadius: 20,
        focusColor: tvIconFocusColor(context),
        icon: Icon(
          Icons.delete_sweep_outlined,
          color: Theme.of(context).hintColor,
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(l10n.remove_everything),
              content: Text(l10n.remove_everything_msg),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await _clearHistory();
                  },
                  child: Text(l10n.ok),
                ),
              ],
            ),
          );
        },
      ),
    ];
  }

  Future<void> _clearHistory() async {
    final idsToDelete = await historyRepository.getIdsByItemType(
      getCurrentItemType(),
    );
    await historyRepository.deleteAll(idsToDelete);
  }
}

class HistoryTab extends ConsumerStatefulWidget {
  final String query;
  final ItemType itemType;
  final bool isGridView;
  final bool isComfortableGrid;
  const HistoryTab({
    required this.itemType,
    required this.query,
    this.isGridView = true,
    this.isComfortableGrid = true,
    super.key,
  });

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Accent overlay when a history row / cover button holds d-pad focus on
  // Android TV so it is clearly visible on a remote; `null` (default) off-TV.
  WidgetStateProperty<Color?>? _tvFocusOverlay(BuildContext context) => isTv
      ? WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : null,
        )
      : null;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = l10nLocalizations(context)!;
    final history = ref.watch(
      getAllHistoryStreamProvider(
        itemType: widget.itemType,
        search: widget.query,
      ),
    );
    return history.when(
      data: (allEntries) {
        // Batch-resolve chapter/manga for every entry in one multi-get each,
        // instead of each row's IsarLink.value doing its own blocking sync
        // DB read — that was firing per row as it scrolled into view (every
        // unloaded IsarLink.value synchronously calls loadSync()).
        final chapterIds = allEntries
            .map((e) => e.chapterId)
            .whereType<int>()
            .toSet()
            .toList();
        final chapterById = {
          for (final c in chapterRepository.getAllByIds(chapterIds))
            if (c != null && c.id != null) c.id!: c,
        };
        final mangaIds = chapterById.values
            .map((c) => c.mangaId)
            .whereType<int>()
            .toSet()
            .toList();
        final mangaById = {
          for (final m in mangaRepository.getAllByIds(mangaIds))
            if (m != null && m.id != null) m.id!: m,
        };
        final entries = allEntries.where((e) {
          final cId = e.chapterId;
          if (cId == null) return false;
          final c = chapterById[cId];
          if (c == null) return false;
          final mId = c.mangaId;
          if (mId == null) return false;
          return mangaById[mId] != null && e.date != null;
        }).toList();
        if (entries.isNotEmpty) {
          if (widget.isGridView) {
            final seenMangaIds = <int>{};
            final historyByManga = <int, History>{};
            final historyChapters = <int, Chapter>{};
            final recentMangas = <Manga>[];
            for (final e in entries) {
              final c = chapterById[e.chapterId];
              if (c == null || c.mangaId == null) continue;
              final m = mangaById[c.mangaId];
              if (m == null || m.id == null) continue;
              if (seenMangaIds.add(m.id!)) {
                recentMangas.add(m);
                historyByManga[m.id!] = e;
                historyChapters[m.id!] = c;
              }
            }
            final gridSize = ref.watch(
              libraryGridSizeStateProvider(itemType: widget.itemType),
            );
            return GridViewWidget(
              gridSize: gridSize,
              childAspectRatio: 0.69,
              itemCount: recentMangas.length,
              itemBuilder: (context, index) {
                final manga = recentMangas[index];
                final chapter = historyChapters[manga.id!];
                final hist = historyByManga[manga.id!];
                final timeStr = hist?.date != null
                    ? dateFormatHour(hist!.date!, context)
                    : '';
                final epLabel = chapter?.name ?? '';
                return Padding(
                  padding: const EdgeInsets.all(2),
                  child: CoverViewWidget(
                    autofocus: isTv && index == 0,
                    isComfortableGrid: widget.isComfortableGrid,
                    bottomTextWidget: BottomTextWidget(
                      maxLines: 1,
                      text: manga.name ?? '',
                      isComfortableGrid: widget.isComfortableGrid,
                    ),
                    image: resolveCoverImage(manga, ref),
                    onTap: () {
                      if (chapter != null) {
                        chapter.pushToReaderView(context);
                      } else {
                        context.push('/manga-reader/detail', extra: manga.id);
                      }
                    },
                    onLongPress: () {
                      context.push('/manga-reader/detail', extra: manga.id);
                    },
                    children: [
                      // 0.4.3: CoverViewWidget only draws bottomTextWidget in
                      // the comfortable grid, so the compact grid of the
                      // "Lịch Sử Đọc/Xem" tab showed no title at all. Draw it
                      // inside the card there, and move the episode badge to
                      // the top so the two do not overlap.
                      if (!widget.isComfortableGrid)
                        BottomTextWidget(text: manga.name ?? ''),
                      if (epLabel.isNotEmpty)
                        Positioned(
                          top: widget.isComfortableGrid ? null : 4,
                          bottom: widget.isComfortableGrid ? 4 : null,
                          left: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              timeStr.isNotEmpty
                                  ? '$epLabel • $timeStr'
                                  : epLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          }
          return CustomScrollView(
            slivers: [
              CustomSliverGroupedListView<History, String>(
                elements: entries,
                groupBy: (element) => element.date != null
                    ? dateFormat(
                        element.date!,
                        context: context,
                        ref: ref,
                        forHistoryValue: true,
                        useRelativeTimesTamps: false,
                      )
                    : '',
                groupSeparatorBuilder: (String groupByValue) => Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 12),
                  child: Row(
                    children: [
                      Text(
                        dateFormat(
                          null,
                          context: context,
                          stringDate: groupByValue,
                          ref: ref,
                        ),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context, History element) {
                  final chapter = chapterById[element.chapterId];
                  if (chapter == null) return const SizedBox.shrink();
                  final manga = mangaById[chapter.mangaId];
                  if (manga == null) return const SizedBox.shrink();
                  final isLight =
                      Theme.of(context).brightness == Brightness.light;
                  final textColor =
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      (isLight ? Colors.black87 : Colors.white70);
                  final mangaName = manga.name ?? '';
                  final chapterName = chapter.name ?? '';
                  final timeStr = element.date != null
                      ? dateFormatHour(element.date!, context)
                      : '';
                  // Two focusable targets on TV, matching the Browse source
                  // rows: the entry itself, and remove. The cover's own
                  // tap-to-detail folds into the entry rather than becoming a
                  // third stop for the remote to pass through.
                  if (isTv) {
                    return TvListRow(
                      children: [
                        Expanded(
                          child: TvRowButton(
                            onTap: () => chapter.pushToReaderView(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: SizedBox(
                                height: 92,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 60,
                                      height: 90,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(7),
                                        child: _getCoverImage(manga),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mangaName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            timeStr.isNotEmpty
                                                ? "$chapterName - $timeStr"
                                                : chapterName,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        TvRowButton(
                          onTap: () =>
                              _openDeleteDialog(l10n, manga, element.id),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Icon(
                              Icons.delete_outline,
                              size: 25,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(0),
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ).copyWith(overlayColor: _tvFocusOverlay(context)),
                    onPressed: () async {
                      await chapter.pushToReaderView(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        height: 105,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 90,
                              child: ElevatedButton(
                                style:
                                    ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.all(0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                    ).copyWith(
                                      overlayColor: _tvFocusOverlay(context),
                                    ),
                                onPressed: () {
                                  context.push(
                                    '/manga-reader/detail',
                                    extra: manga.id,
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: _getCoverImage(manga),
                                ),
                              ),
                            ),
                            Flexible(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      color: Colors.transparent,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              mangaName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: textColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.start,
                                            ),
                                            Wrap(
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.end,
                                              children: [
                                                Text(
                                                  chapterName,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: textColor,
                                                  ),
                                                ),
                                                if (timeStr.isNotEmpty)
                                                  Text(
                                                    " - $timeStr",
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    focusColor: isTv
                                        ? Theme.of(context).colorScheme.primary
                                              .withValues(alpha: 0.4)
                                        : null,
                                    onPressed: () => _openDeleteDialog(
                                      l10n,
                                      manga,
                                      element.id,
                                    ),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 25,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                itemComparator: (item1, item2) =>
                    (item1.date ?? '').compareTo(item2.date ?? ''),
                order: GroupedListOrder.DESC,
              ),
            ],
          );
        }
        return Center(child: Text(l10n.nothing_read_recently));
      },
      error: (Object error, StackTrace stackTrace) {
        return ErrorText(error);
      },
      loading: () {
        return const ProgressCenter();
      },
    );
  }

  Widget _getCoverImage(Manga manga) {
    return _DeferredCoverImage(
      width: 60,
      height: 90,
      builder: (context) => manga.customCoverImage != null
          ? Image.memory(manga.customCoverImage as Uint8List)
          : cachedCompressedNetworkImage(
              headers: ref.watch(
                headersProvider(
                  source: manga.source!,
                  lang: manga.lang!,
                  sourceId: manga.sourceId,
                ),
              ),
              imageUrl: toImgUrl(
                manga.customCoverFromTracker ?? manga.imageUrl ?? "",
              ),
              width: 60,
              height: 90,
              fit: BoxFit.cover,
            ),
    );
  }

  void _openDeleteDialog(AppLocalizations l10n, Manga manga, int? deleteId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.remove),
          content: Text(l10n.remove_history_msg),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 15),
                TextButton(
                  onPressed: () async => deleteManga(context, manga, deleteId),
                  child: Text(l10n.remove),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteManga(
    BuildContext context,
    Manga manga,
    int? deleteId,
  ) async {
    historyRepository.delete(ref, deleteId!);
    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}

/// Skips building the real cover — a network fetch + decode — while the
/// nearest Scrollable is flinging fast, showing an empty box of the same
/// size instead. Swaps in the real image once scrolling settles, using
/// ScrollerNotif to know when to re-check.
class _DeferredCoverImage extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final double width;
  final double height;

  const _DeferredCoverImage({
    required this.builder,
    required this.width,
    required this.height,
  });

  @override
  State<_DeferredCoverImage> createState() => _DeferredCoverImageState();
}

class _DeferredCoverImageState extends State<_DeferredCoverImage> {
  ScrollPosition? _scrollPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (!identical(position, _scrollPosition)) {
      _scrollPosition?.isScrollingNotifier.removeListener(_onScrollingChanged);
      _scrollPosition = position;
      _scrollPosition?.isScrollingNotifier.addListener(_onScrollingChanged);
    }
  }

  void _onScrollingChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scrollPosition?.isScrollingNotifier.removeListener(_onScrollingChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Scrollable.recommendDeferredLoadingForContext(context)) {
      return SizedBox(width: widget.width, height: widget.height);
    }
    return widget.builder(context);
  }
}
