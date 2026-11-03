import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mangayomi/yomihub/extensions/ext_errors.dart';
import 'package:mangayomi/eval/model/filter.dart';
import 'package:mangayomi/eval/model/m_manga.dart';
import 'package:mangayomi/eval/model/m_pages.dart';
import 'package:mangayomi/main.dart';
import 'package:mangayomi/models/history.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:flutter/services.dart';
import 'package:mangayomi/modules/widgets/manga_image_card_widget.dart'
    show pushToMangaReaderDetail;
import 'package:mangayomi/modules/widgets/tv_pill.dart' show tvIsSelectKey;
import 'package:mangayomi/utils/cached_network.dart';
import 'package:mangayomi/utils/constant.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:mangayomi/utils/headers.dart';
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/services/get_filter_list.dart';
import 'package:mangayomi/services/isolate_service.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

/// One suggested title and why it was suggested.
class YomiSuggestion {
  final MManga manga;
  final Source source;
  final double score;
  final List<String> matched;
  YomiSuggestion(this.manga, this.source, this.score, this.matched);
}

/// YomiHub 0.1.8: "Đề xuất" for Comic / Film & Movie / Novel.
///
/// Works like Kotatsu's SuggestionsWorker, on Mangayomi's extension engine:
///  1. the tags (genres) of the titles in the library and in the history of
///     that category are counted, recent ones weighing more;
///  2. for each installed source of the category, a genre filter option
///     matching one of the top tags is switched on and the source is searched
///     with it (sources without such a filter give their popular list);
///  3. results already in the library are dropped, the rest are ranked by
///     how many of the user's tags they share, the source's weight in the
///     user's reading, and their rank in the source's list.
class YomiSuggestionEngine {
  static final Map<ItemType, (DateTime, List<YomiSuggestion>, List<String>)>
  _cache = {};

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[\s_\-]+'), ' ')
      .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), '')
      .trim();

  /// Tag → weight, from the library and history of [type].
  static Future<Map<String, double>> userTags(
    ItemType type, {
    Map<String, double>? sourceWeight,
  }) async {
    final tags = <String, double>{};
    final seen = <int>{};
    final now = DateTime.now().millisecondsSinceEpoch;
    void add(Manga m, double w) {
      if (m.id == null || !seen.add(m.id!)) return;
      final key = '${m.source}|${m.lang}';
      sourceWeight?.update(key, (v) => v + w, ifAbsent: () => w);
      for (final g in m.genre ?? const <String>[]) {
        final n = _norm(g);
        if (n.isEmpty || n.length > 40) continue;
        tags.update(n, (v) => v + w, ifAbsent: () => w);
      }
    }

    final favs = await isar.mangas
        .filter()
        .itemTypeEqualTo(type)
        .favoriteEqualTo(true)
        .findAll();
    for (final m in favs) {
      // recently read titles weigh up to 3x
      final days = m.lastRead == null
          ? 365
          : ((now - m.lastRead!) / 86400000).clamp(0, 365);
      add(m, 1 + 2 * (1 - days / 365));
    }
    final hist = await isar.historys
        .filter()
        .itemTypeEqualTo(type)
        .sortByDateDesc()
        .limit(200)
        .findAll();
    final ids = hist.map((h) => h.mangaId).whereType<int>().toSet().toList();
    final hm = await isar.mangas.getAll(ids);
    for (final m in hm) {
      if (m != null) add(m, 1.5);
    }
    return tags;
  }

  static Iterable<dynamic> _leaves(List<dynamic> filters) sync* {
    for (final f in filters) {
      if (f is GroupFilter) {
        yield* _leaves(f.state);
      } else {
        yield f;
      }
    }
  }

  /// Switches on the filter options named like [tag]; true if one matched.
  static bool _applyTag(List<dynamic> filters, String tag) {
    var hit = false;
    for (final f in _leaves(filters)) {
      if (f is CheckBoxFilter && _norm(f.name) == tag) {
        f.state = true;
        hit = true;
      } else if (f is TriStateFilter && _norm(f.name) == tag) {
        f.state = 1;
        hit = true;
      } else if (f is SelectFilter && !hit) {
        for (var i = 0; i < f.values.length; i++) {
          final o = f.values[i];
          final name = o is SelectFilterOption ? o.name : '$o';
          if (_norm(name) == tag) {
            f.state = i;
            hit = true;
            break;
          }
        }
      }
    }
    return hit;
  }

  static Future<List<YomiSuggestion>> load(
    ItemType type, {
    required String proxyServer,
    bool force = false,
    bool showNsfw = true,
    void Function(List<YomiSuggestion>, List<String>)? progress,
  }) async {
    final cached = _cache[type];
    if (!force && showNsfw &&
        cached != null &&
        DateTime.now().difference(cached.$1) < const Duration(hours: 6)) {
      progress?.call(cached.$2, cached.$3);
      return cached.$2;
    }
    final sourceWeight = <String, double>{};
    final tags = await userTags(type, sourceWeight: sourceWeight);
    final top = (tags.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(8)
        .map((e) => e.key)
        .toList();
    final sources = sourceRepository
        .getInstalledByItemType(type)
        .where((s) => s.name != 'local' && (s.isActive ?? true) && (showNsfw || !(s.isNsfw ?? false)))
        // YomiHub 0.2.0: skip sources that need setup (Jellyfin, Google
        // Drive…) or timed out recently – they only produced errors here.
        .where((s) => !YomiExtErrors.needsSetup(s.name, s.lang) && !YomiExtErrors.isSlow(s.name, s.lang))
        .toList()
      ..sort((a, b) =>
          (sourceWeight['${b.name}|${b.lang}'] ?? 0).compareTo(sourceWeight['${a.name}|${a.lang}'] ?? 0));
    final picked = sources.take(8).toList();
    final inLibrary = (await isar.mangas
            .filter()
            .itemTypeEqualTo(type)
            .favoriteEqualTo(true)
            .findAll())
        .map((m) => _norm(m.name ?? ''))
        .toSet();
    final out = <String, YomiSuggestion>{};
    final rnd = Random();

    Future<void> fromSource(Source src) async {
      MPages? pages;
      final usedTags = <String>[];
      try {
        if (top.isNotEmpty) {
          List<dynamic> base = const [];
          try {
            base = getFilterList(source: src);
          } catch (_) {}
          if (base.isNotEmpty) {
            // deep copy, the source keeps its own filter state
            final copy = FilterList.fromJson(FilterList(base).toJson()).filters;
            // one or two of the user's tags, varied between sources
            final order = [...top]..shuffle(rnd);
            for (final t in order) {
              if (_applyTag(copy, t)) usedTags.add(t);
              if (usedTags.length >= 2) break;
            }
            if (usedTags.isNotEmpty) {
              pages = await getIsolateService
                  .get<MPages?>(
                    query: '',
                    filterList: copy,
                    source: src,
                    page: 1,
                    serviceType: 'search',
                    proxyServer: proxyServer,
                  )
                  .timeout(_kSuggestTimeout);
            }
          }
        }
        if (pages == null || pages.list.isEmpty) {
          pages = await getIsolateService
              .get<MPages?>(
                source: src,
                page: 1,
                serviceType: 'getPopular',
                proxyServer: proxyServer,
              )
              .timeout(_kSuggestTimeout);
        }
      } catch (e) {
        if (e is TimeoutException || YomiExtErrors.isNetworkError(e)) {
          YomiExtErrors.markSlow(src.name, src.lang);
        }
        if (YomiExtErrors.isSetupError(e)) {
          YomiExtErrors.markSetup(src.name, src.lang);
        }
        // YomiHub 0.2.7: Ghi chi tiết lỗi Đề Xuất vào Nhật Ký Ứng Dụng
        AppLogger.log(
          'Đề Xuất [${src.name} (${src.lang})]: không tải được danh sách: ${YomiExtErrors.short(e)} ($e)',
          logLevel: LogLevel.warning,
        );
        return;
      }
      final list = pages?.list ?? const <MManga>[];
      final sw = sourceWeight['${src.name}|${src.lang}'] ?? 0;
      for (var i = 0; i < list.length && i < 30; i++) {
        final m = list[i];
        final n = _norm(m.name ?? '');
        if (n.isEmpty || inLibrary.contains(n)) continue;
        final g = (m.genre ?? const []).map(_norm).toSet();
        final matched = <String>{...usedTags, ...top.where(g.contains)}.toList();
        var score = 0.0;
        for (final t in matched) {
          score += (tags[t] ?? 0.5);
        }
        score += sw * 0.3 + (30 - i) / 30;
        final prev = out[n];
        if (prev == null || prev.score < score) {
          out[n] = YomiSuggestion(m, src, score, matched);
        }
      }
      final sorted = out.values.toList()..sort((a, b) => b.score.compareTo(a.score));
      progress?.call(sorted, top);
    }

    // YomiHub 0.4.9: one gate shared by the Comic/Anime/Novel tabs. Before,
    // each tab ran 2 sources at once and all of them queued on the single
    // isolate service; the queue wait counted against the 12 s timeout, so
    // ~20 sources "timed out" within one second (logs_6, 01/11 13:26).
    await Future.wait(
      picked.map((s) => _SuggestGate.run(() async {
            try {
              await fromSource(s);
            } catch (e) {
              AppLogger.log('Đề Xuất [${s.name}]: $e', logLevel: LogLevel.warning);
            }
          })),
    );
    final result = out.values.toList()..sort((a, b) => b.score.compareTo(a.score));
    _cache[type] = (DateTime.now(), result, top);
    return result;
  }
}

class YomiSuggestionsView extends ConsumerStatefulWidget {
  final ItemType itemType;
  final VoidCallback? onOpenExtensions;
  const YomiSuggestionsView({super.key, required this.itemType, this.onOpenExtensions});

  @override
  ConsumerState<YomiSuggestionsView> createState() => _YomiSuggestionsViewState();
}

class _YomiSuggestionsViewState extends ConsumerState<YomiSuggestionsView>
    with AutomaticKeepAliveClientMixin {
  List<YomiSuggestion> _items = [];
  List<String> _tags = [];
  bool _loading = true;
  String? _tag;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load(false);
  }

  Future<void> _load(bool force) async {
    setState(() => _loading = true);
    try {
      await YomiSuggestionEngine.load(
        widget.itemType,
        proxyServer: ref.read(androidProxyServerStateProvider),
        force: force,
        showNsfw: ref.read(showNSFWStateProvider),
        progress: (items, tags) {
          if (!mounted) return;
          setState(() {
            _items = items;
            _tags = tags;
          });
        },
      );
    } catch (e) {
      AppLogger.log('Suggestions failed: $e', logLevel: LogLevel.error);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final installed = sourceRepository.getInstalledByItemType(widget.itemType);
    if (installed.where((s) => s.name != 'local').isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.extension_outlined, size: 48),
              const SizedBox(height: 12),
              Text(
                tr('Chưa cài tiện ích nào cho mục này. Hãy cài tiện ích để nhận đề xuất.'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (widget.onOpenExtensions != null)
                FilledButton.icon(
                  onPressed: widget.onOpenExtensions,
                  icon: const Icon(Icons.download_outlined),
                  label: Text(tr('Mở Tiện ích')),
                ),
            ],
          ),
        ),
      );
    }
    final items = _tag == null
        ? _items
        : _items.where((s) => s.matched.contains(_tag)).toList();
    return RefreshIndicator(
      onRefresh: () => _load(true),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _tags.isEmpty
                          ? tr('Đề xuất từ các nguồn đã cài (đọc/xem thêm để đề xuất sát hơn)')
                          : tr('Đề xuất theo các nhãn bạn hay đọc/xem'),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (_loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      tooltip: tr('Làm mới'),
                      icon: const Icon(Icons.refresh),
                      onPressed: () => _load(true),
                    ),
                ],
              ),
            ),
          ),
          if (_tags.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(tr('Tất cả')),
                        selected: _tag == null,
                        onSelected: (_) => setState(() => _tag = null),
                      ),
                    ),
                    for (final t in _tags)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(t),
                          selected: _tag == t,
                          onSelected: (_) => setState(() => _tag = _tag == t ? null : t),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (items.isEmpty && !_loading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(tr('Chưa có đề xuất'))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 170,
                  mainAxisExtent: 260,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (c, i) => _SuggestionCard(
                    manga: items[i].manga,
                    source: items[i].source,
                  ),
                  childCount: items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends ConsumerStatefulWidget {
  final MManga manga;
  final Source source;

  const _SuggestionCard({
    required this.manga,
    required this.source,
  });

  @override
  ConsumerState<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends ConsumerState<_SuggestionCard> {
  bool _focused = false;

  void _open() {
    pushToMangaReaderDetail(
      ref: ref,
      context: context,
      getManga: widget.manga,
      lang: widget.source.lang!,
      itemType: widget.source.itemType,
      useMaterialRoute: true,
      source: widget.source.name!,
      sourceId: widget.source.id,
    );
  }

  void _quickAddToLibrary() {
    pushToMangaReaderDetail(
      ref: ref,
      context: context,
      getManga: widget.manga,
      lang: widget.source.lang!,
      itemType: widget.source.itemType,
      source: widget.source.name!,
      sourceId: widget.source.id,
      addToFavourite: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Focus(
      onFocusChange: (f) {
        setState(() => _focused = f);
        if (f && context.mounted && Scrollable.maybeOf(context) != null) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && tvIsSelectKey(event.logicalKey)) {
          _open();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _focused ? context.primaryColor : Colors.transparent,
            width: 2,
          ),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _open,
            onLongPress: _quickAddToLibrary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        child: cachedNetworkImage(
                          headers: ref.watch(
                            headersProvider(
                              source: widget.source.name!,
                              lang: widget.source.lang!,
                              sourceId: widget.source.id,
                            ),
                          ),
                          imageUrl: toImgUrl(widget.manga.imageUrl ?? ""),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.source.name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Text(
                    widget.manga.name ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const Duration _kSuggestTimeout = Duration(seconds: 20);

/// Global concurrency gate for suggestion fetches (all item types together).
class _SuggestGate {
  static const int _max = 2;
  static int _running = 0;
  static final List<Completer<void>> _waiters = [];

  static Future<T> run<T>(Future<T> Function() body) async {
    if (_running >= _max) {
      final c = Completer<void>();
      _waiters.add(c);
      await c.future;
    }
    _running++;
    try {
      return await body();
    } finally {
      _running--;
      if (_waiters.isNotEmpty) _waiters.removeAt(0).complete();
    }
  }
}
