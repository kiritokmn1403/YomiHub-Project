import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/eval/model/m_bridge.dart';
import 'package:mangayomi/models/chapter.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/yomihub/merge/chapter_origins.dart';
import 'package:mangayomi/repositories/chapter_repository.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/utils/constant.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/yomihub/ui/liquid_glass.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/delete_source.dart';
import 'package:mangayomi/modules/more/data_and_storage/widgets/source_management_tiles.dart';

class ContentMergeScreen extends ConsumerStatefulWidget {
  const ContentMergeScreen({super.key});

  @override
  ConsumerState<ContentMergeScreen> createState() => _ContentMergeScreenState();
}

class _MergedMangaItem {
  final Manga manga;
  final List<String> sources;
  final int chapterCount;
  _MergedMangaItem({
    required this.manga,
    required this.sources,
    required this.chapterCount,
  });
}

class _ContentMergeScreenState extends ConsumerState<ContentMergeScreen> {
  static const _prefAutoSuggest = 'content_merge_auto_suggest';
  bool _autoSuggest = YomiPrefs.get<bool>(_prefAutoSuggest, true);
  bool _loadingMerged = false;
  List<_MergedMangaItem> _mergedMangas = [];

  @override
  void initState() {
    super.initState();
    _loadMergedMangas();
  }

  Future<void> _loadMergedMangas() async {
    if (!mounted) return;
    setState(() => _loadingMerged = true);
    await Future<void>.delayed(Duration.zero);
    final rawOrigins = YomiPrefs.get<Map>('mergedChapterOrigins', const {});
    final mergedMangaIds = <int>{};
    for (final v in rawOrigins.values) {
      if (v is Map) {
        final mId = v['mangaId'];
        if (mId is int) mergedMangaIds.add(mId);
      }
    }
    final items = <_MergedMangaItem>[];
    for (final mId in mergedMangaIds) {
      if (!mounted) return;
      final m = mangaRepository.getById(mId);
      if (m == null) continue;
      final chapters = chapterRepository.getAllByMangaId(m.id);
      final sources = <String, String>{};
      sources['${m.sourceId}|${m.source}|${m.lang}'] = m.source ?? '';
      for (final c in chapters) {
        final origin = ChapterOrigins.of(c);
        if (origin != null) {
          sources[ChapterOrigins.sourceKey(c)] = ChapterOrigins.sourceLabel(c);
        }
      }
      if (sources.length > 1) {
        items.add(
          _MergedMangaItem(
            manga: m,
            sources: sources.values.toList(),
            chapterCount: chapters.length,
          ),
        );
      }
      await Future<void>.delayed(Duration.zero);
    }
    if (mounted) {
      setState(() {
        _mergedMangas = items;
        _loadingMerged = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mergedMangas = _mergedMangas;

    return Scaffold(
      appBar: AppBar(title: Text(tr('Hợp Nhất Nội Dung'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Banner giới thiệu tính năng
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary.withValues(alpha: 0.15),
                  cs.secondary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_stories_rounded, color: cs.primary, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Hợp nhất truyện tranh, tiểu thuyết, phim ảnh'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(
                          'Gộp các bản dịch/nguồn phát khác nhau của cùng một tác phẩm vào làm một, tự do chọn nguồn đọc/xem và cho phép hủy hợp nhất bất kỳ lúc nào.',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cài đặt 1: Tự động phát hiện trùng tên & đề xuất
          SwitchListTile(
            secondary: const Icon(
              Icons.manage_search_rounded,
              color: Colors.indigoAccent,
            ),
            title: Text(tr('Tự động phát hiện tên trùng nhau')),
            subtitle: Text(
              tr(
                'Hệ thống đối chiếu tên tác phẩm trong thư viện để đề xuất hợp nhất',
              ),
            ),
            value: _autoSuggest,
            onChanged: (val) async {
              setState(() => _autoSuggest = val);
              await YomiPrefs.set(_prefAutoSuggest, val);
            },
          ),
          ListTile(
            leading: const Icon(Icons.join_full_rounded, color: Colors.blue),
            title: Text(tr('Quét trùng tên và đề xuất hợp nhất')),
            subtitle: Text(
              tr(
                'Tìm tất cả các bộ có cùng tên trong thư viện và gộp theo nhóm',
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () => _scanAndMergeDuplicates(context),
          ),
          const Divider(),

          // Cài đặt 2: Tự chọn các bộ để hợp nhất thủ công
          ListTile(
            leading: const Icon(Icons.merge_type_rounded, color: Colors.teal),
            title: Text(tr('Người dùng tự chọn bộ để hợp nhất')),
            subtitle: Text(
              tr(
                'Chọn 2 hoặc nhiều bộ truyện/phim trong thư viện để tiến hành ghép',
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () => _manualSelectAndMerge(context),
          ),
          const Divider(),

          // Cài đặt 3: Danh sách các bộ đã hợp nhất & Hủy hợp nhất
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tr('Danh sách các bộ đã hợp nhất ({p0})', {
                      'p0': '${mergedMangas.length}',
                    }),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ),
                if (_loadingMerged)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          if (mergedMangas.isEmpty && !_loadingMerged)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  tr('Chưa có bộ nào được hợp nhất trong thư viện.'),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
              ),
            )
          else
            ...mergedMangas.map((item) {
              final m = item.manga;
              final sources = item.sources;
              final chapterCount = item.chapterCount;
              return Card(
                elevation: 0,
                color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.library_books_rounded,
                    color: Colors.amber,
                  ),
                  title: Text(
                    m.name ?? tr('Không tên'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    tr('{p0} nguồn ({p1}) • {p2} chương/tập', {
                      'p0': '${sources.length}',
                      'p1': sources.join(', '),
                      'p2': '$chapterCount',
                    }),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: OutlinedButton.icon(
                    icon: const Icon(
                      Icons.call_split_rounded,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    label: Text(
                      tr('Hủy hợp nhất'),
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () =>
                        _unmergeManga(context, m, sources.toList()),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _scanAndMergeDuplicates(BuildContext context) async {
    final allFavorites = mangaRepository.getFavoritesNonLocalArchive();
    final clusters = findDuplicateMangaClusters(allFavorites);
    final duplicates = clusters
        .map((c) => c.mangaList)
        .where((list) => list.length >= 2)
        .toList();
    if (duplicates.isEmpty) {
      botToast(tr('Không phát hiện bộ nào có tên trùng nhau trong thư viện.'));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dContext) => AlertDialog(
        title: Text(tr('Đề xuất hợp nhất trùng tên')),
        content: Text(
          tr(
            'Phát hiện {p0} nhóm bộ có tên trùng nhau trong thư viện. Bạn có muốn xem và xác nhận hợp nhất không?',
            {'p0': '${duplicates.length}'},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dContext, false),
            child: Text(tr('Đóng')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dContext, true),
            child: Text(tr('Tiến hành hợp nhất')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      for (final group in duplicates) {
        if (group.length >= 2) {
          final primary = group.first;
          final others = group.sublist(1);
          await mergeMangaGroup(primary, others);
          await Future<void>.delayed(Duration.zero);
        }
      }
      await _loadMergedMangas();
      botToast(tr('Đã hoàn tất hợp nhất các bộ trùng tên.'));
    }
  }

  Future<void> _manualSelectAndMerge(BuildContext context) async {
    final allFavorites = mangaRepository.getFavoritesNonLocalArchive();
    if (allFavorites.length < 2) {
      botToast(tr('Cần ít nhất 2 bộ trong thư viện để tiến hành hợp nhất.'));
      return;
    }

    final selected = await showDialog<List<Manga>>(
      context: context,
      builder: (dContext) {
        final chosen = <Manga>{};
        var filter = '';
        return StatefulBuilder(
          builder: (dContext, setModalState) {
            final list = allFavorites
                .where(
                  (m) =>
                      filter.isEmpty ||
                      (m.name?.toLowerCase().contains(filter.toLowerCase()) ??
                          false),
                )
                .toList();
            return AlertDialog(
              title: Text(tr('Chọn các bộ để hợp nhất')),
              content: SizedBox(
                width: double.maxFinite,
                height: 380,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: tr('Tìm kiếm...'),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (v) => setModalState(() => filter = v.trim()),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, idx) {
                          final m = list[idx];
                          final isChecked = chosen.contains(m);
                          return CheckboxListTile(
                            dense: true,
                            value: isChecked,
                            title: Text(m.name ?? ''),
                            subtitle: Text(
                              '${m.source ?? ""} • ${m.itemType.name}',
                            ),
                            onChanged:
                                chosen.isNotEmpty &&
                                    chosen.first.itemType != m.itemType
                                ? null
                                : (val) {
                                    setModalState(() {
                                      if (val == true) {
                                        chosen.add(m);
                                      } else {
                                        chosen.remove(m);
                                      }
                                    });
                                  },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dContext, null),
                  child: Text(tr('Hủy')),
                ),
                FilledButton(
                  onPressed: chosen.length >= 2
                      ? () => Navigator.pop(dContext, chosen.toList())
                      : null,
                  child: Text(
                    tr('Hợp nhất ({p0})', {'p0': '${chosen.length}'}),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null && selected.length >= 2 && mounted) {
      final primary = selected.first;
      final others = selected.sublist(1);
      await mergeMangaGroup(primary, others);
      await _loadMergedMangas();
      botToast(
        tr('Đã hợp nhất thành công vào bộ "{p0}".', {'p0': primary.name ?? ''}),
      );
    }
  }

  Future<void> _unmergeManga(
    BuildContext context,
    Manga primary,
    List<String> sourceNames,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dContext) => AlertDialog(
        title: Text(tr('Xác nhận hủy hợp nhất')),
        content: Text(
          tr(
            'Bạn có chắc muốn hủy hợp nhất "{p0}" và tách lại thành các bộ riêng lẻ theo từng nguồn không?',
            {'p0': primary.name ?? ''},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dContext, false),
            child: Text(tr('Hủy')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dContext, true),
            child: Text(tr('Tách lại nguồn')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final chapters = chapterRepository.getAllByMangaId(primary.id);
      final bySource = <String, List<Chapter>>{};
      for (final c in chapters) {
        final sName = ChapterOrigins.sourceKey(c);
        bySource.putIfAbsent(sName, () => []).add(c);
      }

      // Recreate individual mangas for secondaries
      for (final entry in bySource.entries) {
        if (entry.key !=
                '${primary.sourceId}|${primary.source}|${primary.lang}' &&
            entry.value.isNotEmpty) {
          final origin = ChapterOrigins.of(entry.value.first);
          final newManga = Manga(
            name: primary.name,
            source: ChapterOrigins.sourceLabel(entry.value.first),
            sourceId: origin?['sourceId'] as int?,
            itemType: primary.itemType,
            imageUrl: primary.imageUrl,
            description: primary.description,
            author: primary.author,
            artist: primary.artist,
            genre: primary.genre,
            status: primary.status,
            favorite: true,
            link: origin?['link'] as String? ?? primary.link,
            lang: origin?['lang'] as String? ?? primary.lang,
          );
          final newId = await mangaRepository.put(newManga);
          for (final c in entry.value) {
            c.mangaId = newId;
            c.manga.value = newManga;
            await chapterRepository.saveWithMangaLink(c);
          }
        }
      }

      await _loadMergedMangas();
      botToast(
        tr('Đã hủy hợp nhất thành công. Các bộ đã được tách lại độc lập.'),
      );
    }
  }
}
