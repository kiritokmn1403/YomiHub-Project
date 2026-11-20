import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_logic.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_models.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_store.dart';
import 'package:mangayomi/yomihub/bookshelf/ui/bookshelf_dialogs.dart';
import 'package:mangayomi/yomihub/bookshelf/ui/bookshelf_scan_screen.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

/// Detail screen for a single series (FN-06, FN-10, FN-12, FN-13, FN-14,
/// FN-15, FN-23, FN-26, FN-27, FN-28).
class BookshelfSeriesScreen extends StatefulWidget {
  const BookshelfSeriesScreen({super.key, required this.seriesId});

  final String seriesId;

  @override
  State<BookshelfSeriesScreen> createState() => _BookshelfSeriesScreenState();
}

class _BookshelfSeriesScreenState extends State<BookshelfSeriesScreen> {
  final BookshelfStore _store = BookshelfStore.instance;
  BsEdition _edition = BsEdition.regular;
  bool _synopsisExpanded = false;
  int _extraGridSlots = 0;

  @override
  void initState() {
    super.initState();
    _store.init().then((_) {
      if (mounted && _store.seriesById(widget.seriesId) != null) {
        _store.touchRecent(widget.seriesId);
      }
    });
  }

  Future<void> _confirmDeleteSeries(BsSeries s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Xoá bộ truyện?')),
        content: Text(tr(
          'Xoá "{p0}" cùng toàn bộ tập đã lưu, thư mục Limited và mục Cần mua liên quan?',
          {'p0': s.title},
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Huỷ')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Xoá')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _store.deleteSeries(s.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDeleteFolder(BsFolder f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Xoá thư mục?')),
        content: Text(tr(
          'Xoá thư mục "{p0}" và {p1} ấn phẩm bên trong?',
          {'p0': f.name, 'p1': f.items.length},
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Huỷ')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Xoá')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _store.removeFolder(f.id);
    }
  }

  Future<void> _addGapsToWishlist(BsSeries s, List<int> gaps) async {
    final existing = _store.wishes
        .where((w) => w.seriesId == s.id && w.edition == BsEdition.regular)
        .map((w) => w.volume)
        .toSet();
    var added = 0;
    for (final g in gaps) {
      if (existing.contains(g.toDouble())) continue;
      await _store.addWish(s.id, volume: g.toDouble());
      added++;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added > 0
              ? tr('Đã thêm {p0} tập thiếu vào Cần mua', {'p0': added})
              : tr('Các tập thiếu đã có sẵn trong Cần mua'),
        ),
      ),
    );
  }

  Future<void> _toggleGridVolume(
    BsSeries s,
    double number,
    BsVolume? existing,
  ) async {
    if (existing != null) {
      await _store.removeVolume(existing.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
                tr('Đã bỏ Tập {p0}', {'p0': BookshelfStore.fmt(number)})),
            action: SnackBarAction(
              label: tr('Hoàn tác'),
              onPressed: () => _store.saveVolume(existing),
            ),
          ),
        );
      return;
    }
    await _store.addVolume(s.id, number, edition: _edition);
  }

  List<double> _gridNumbers(BsSeries s, List<BsVolume> editionVolumes,
      List<BsVolume> allVolumes) {
    final numbers = <double>{};
    if (allVolumes.any((v) => v.number == 0)) {
      numbers.add(0);
    }
    var highest = 0;
    for (final v in allVolumes) {
      highest = math.max(highest, v.number.ceil());
    }
    final maxWhole = math.max(
      s.totalVolumes ?? 0,
      math.max(highest, 24),
    ) +
        _extraGridSlots;
    for (var i = 1; i <= maxWhole; i++) {
      numbers.add(i.toDouble());
    }
    for (final v in editionVolumes) {
      numbers.add(v.number);
    }
    final sorted = numbers.toList()..sort();
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_store, YomiTr.version]),
      builder: (context, _) {
        final s = _store.seriesById(widget.seriesId);
        if (s == null) {
          return Scaffold(
            appBar: AppBar(title: Text(tr('Tủ Sách Cá Nhân'))),
            body: Center(child: Text(tr('Không tìm thấy bộ truyện này'))),
          );
        }

        final allVolumes = _store.volumesOf(s.id);
        final folders = _store.foldersOf(s.id);
        final gaps = _store.gapsOf(s.id);
        final gapSet = gaps.toSet();
        final latest = _store.latestOf(s.id);

        final editionMap = <double, BsVolume>{};
        final otherEditionNumbers = <double>{};
        final editionCounts = {for (final e in BsEdition.values) e: 0};
        var totalCopies = 0;
        var readCount = 0;
        var loanCount = 0;
        var totalSpent = 0.0;

        for (final v in allVolumes) {
          editionCounts[v.edition] = (editionCounts[v.edition] ?? 0) + 1;
          totalCopies += v.copies;
          if (v.readStatus == BsReadStatus.read) readCount++;
          if ((v.borrower ?? '').trim().isNotEmpty) loanCount++;
          if (v.price != null) totalSpent += v.price! * v.copies;
          if (v.edition == _edition) {
            editionMap[v.number] = v;
          } else {
            otherEditionNumbers.add(v.number);
          }
        }
        for (final f in folders) {
          for (final item in f.items) {
            if (item.price != null) totalSpent += item.price!;
          }
        }

        final editionVolumes =
            allVolumes.where((v) => v.edition == _edition).toList();
        final gridNums = _gridNumbers(s, editionVolumes, allVolumes);
        final uniqueOwnedCount =
            allVolumes.map((v) => v.number).toSet().length;

        final cs = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // FN-10: MyAnimeList-style header with blurred cover backdrop
              SliverAppBar(
                expandedHeight: 272,
                pinned: true,
                actions: [
                  IconButton(
                    tooltip: tr('Quét mã vạch'),
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              BookshelfScanScreen(preselectedSeriesId: s.id),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: tr('Sửa'),
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        showBsSeriesFormDialog(context, existing: s),
                  ),
                  IconButton(
                    tooltip: tr('Xoá'),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDeleteSeries(s),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (s.cover.trim().isNotEmpty)
                        BsCoverImage(
                          source: s.cover,
                          borderRadius: 0,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(color: cs.primaryContainer),
                      ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.45),
                                  Colors.black.withValues(alpha: 0.82),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 48, 16, 52),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: s.cover.trim().isEmpty
                                    ? null
                                    : () => showBsPhotoViewer(context, s.cover,
                                        title: s.title),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black54,
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: BsCoverImage(
                                    source: s.cover,
                                    width: 98,
                                    height: 144,
                                    borderRadius: 8,
                                    fallbackTitle: s.title,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (s.original.isNotEmpty)
                                      Text(
                                        s.original,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    if (s.author.isNotEmpty)
                                      Text(
                                        tr('Tác giả: {p0}', {'p0': s.author}),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 13),
                                      ),
                                    if (s.publisher.isNotEmpty)
                                      Text(
                                        tr('NXB: {p0}', {'p0': s.publisher}),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12),
                                      ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _HeaderChip(
                                          label: bsStatusLabel(s.status),
                                          color: cs.primary,
                                        ),
                                        _HeaderChip(
                                          label: s.totalVolumes != null
                                              ? tr('Đã có {p0}/{p1} tập', {
                                                  'p0': uniqueOwnedCount,
                                                  'p1': s.totalVolumes,
                                                })
                                              : tr('Đã có {p0} tập',
                                                  {'p0': uniqueOwnedCount}),
                                          color: Colors.green.shade700,
                                        ),
                                        if (latest != null)
                                          _HeaderChip(
                                            label: tr('Mới nhất: Tập {p0}', {
                                              'p0': BookshelfStore.fmt(latest),
                                            }),
                                            color: Colors.teal.shade700,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick series metrics bar
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          Text(
                            tr('Tổng số cuốn: {p0}', {'p0': totalCopies}),
                            style: textTheme.bodySmall,
                          ),
                          Text(
                            tr('Đã đọc: {p0}', {'p0': readCount}),
                            style: textTheme.bodySmall,
                          ),
                          if (loanCount > 0)
                            Text(
                              tr('Đang cho mượn: {p0}', {'p0': loanCount}),
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (totalSpent > 0)
                            Text(
                              tr('Đã chi: {p0}',
                                  {'p0': bsFormatMoney(totalSpent)}),
                              style: textTheme.bodySmall,
                            ),
                        ],
                      ),

                      // FN-23 aliases
                      if (s.aliases.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final a in s.aliases)
                              Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(a,
                                    style: const TextStyle(fontSize: 11)),
                              ),
                          ],
                        ),
                      ],

                      // Synopsis
                      if (s.synopsis.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => setState(
                              () => _synopsisExpanded = !_synopsisExpanded),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.synopsis,
                                maxLines: _synopsisExpanded ? 20 : 3,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium,
                              ),
                              Text(
                                _synopsisExpanded
                                    ? tr('Thu gọn')
                                    : tr('Xem thêm'),
                                style: textTheme.labelMedium
                                    ?.copyWith(color: cs.primary),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // FN-06 gap alert banner
                      if (gaps.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Card(
                          color: Colors.amber.withValues(alpha: 0.16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: Colors.orange.withValues(alpha: 0.5)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.orange.shade800),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tr('Đang thiếu {p0} tập bản thường',
                                            {'p0': gaps.length}),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        bsRangeText(gaps),
                                        style: textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _addGapsToWishlist(s, gaps),
                                  child: Text(tr('Thêm vào Cần mua')),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Edition selector + bulk select + add volume (FN-12)
                      const SizedBox(height: 16),
                      SegmentedButton<BsEdition>(
                        showSelectedIcon: false,
                        segments: [
                          for (final e in BsEdition.values)
                            ButtonSegment(
                              value: e,
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${bsEditionLabel(e)} (${editionCounts[e] ?? 0})',
                                ),
                              ),
                            ),
                        ],
                        selected: {_edition},
                        onSelectionChanged: (sel) =>
                            setState(() => _edition = sel.first),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('Danh sách tập sách'),
                                  style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold),
                                ),
                                if (editionVolumes.isNotEmpty)
                                  Text(
                                    bsRangeText(
                                        editionVolumes.map((v) => v.number)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.checklist_rtl, size: 18),
                            label: Text(tr('Chọn hàng loạt')),
                            onPressed: () async {
                              final added = await showBsBulkSelectDialog(
                                context,
                                s,
                                initialEdition: _edition,
                              );
                              if (added > 0 && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(tr(
                                      'Đã thêm {p0} tập mới',
                                      {'p0': added},
                                    )),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(tr('Thêm tập')),
                            onPressed: () => showBsVolumeEditDialog(
                              context,
                              series: s,
                              initialNumber: (latest ?? 0).floorToDouble() + 1,
                              initialEdition: _edition,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr('Chạm ô để đánh dấu Đã mua / bỏ • Giữ ô để ghi chú, giá, đọc & cho mượn'),
                        style: textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // Volume checklist grid (FN-12)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 64,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.05,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final num = gridNums[index];
                      final vol = editionMap[num];
                      final isOwned = vol != null;
                      final isGap = _edition == BsEdition.regular &&
                          num == num.roundToDouble() &&
                          gapSet.contains(num.toInt());
                      final hasOtherEdition =
                          !isOwned && otherEditionNumbers.contains(num);

                      final bg = isOwned
                          ? cs.primaryContainer
                          : isGap
                              ? Colors.red.withValues(alpha: 0.10)
                              : cs.surfaceContainerHighest.withValues(alpha: 0.55);
                      final border = isOwned
                          ? cs.primary
                          : isGap
                              ? Colors.red.shade400
                              : cs.outlineVariant;
                      final fg = isOwned
                          ? cs.onPrimaryContainer
                          : isGap
                              ? Colors.red.shade700
                              : cs.onSurfaceVariant;

                      return Material(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _toggleGridVolume(s, num, vol),
                          onLongPress: () => showBsVolumeEditDialog(
                            context,
                            series: s,
                            existing: vol,
                            initialNumber: num,
                            initialEdition: _edition,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: border,
                                width: isOwned || isGap ? 1.4 : 0.8,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    BookshelfStore.fmt(num),
                                    style: TextStyle(
                                      fontWeight: isOwned
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: fg,
                                    ),
                                  ),
                                ),
                                if (vol != null && vol.copies > 1)
                                  Positioned(
                                    right: 3,
                                    top: 2,
                                    child: Text(
                                      '×${vol.copies}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: cs.primary,
                                      ),
                                    ),
                                  )
                                else if (hasOtherEdition)
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                if (vol != null &&
                                    vol.readStatus == BsReadStatus.read)
                                  Positioned(
                                    left: 3,
                                    bottom: 2,
                                    child: Icon(Icons.done_all,
                                        size: 11, color: Colors.green.shade700),
                                  ),
                                if (vol != null &&
                                    (vol.borrower ?? '').trim().isNotEmpty)
                                  Positioned(
                                    right: 3,
                                    bottom: 2,
                                    child: Icon(Icons.person_outline,
                                        size: 11, color: Colors.blue.shade700),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: gridNums.length,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.unfold_more),
                      label: Text(tr('Hiện thêm 24 ô tập')),
                      onPressed: () => setState(() => _extraGridSlots += 24),
                    ),
                  ),
                ),
              ),

              // FN-13 / FN-14 / FN-15: Custom Folders
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr('Thư mục phiên bản khác'),
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.create_new_folder_outlined,
                            size: 18),
                        label: Text(tr('Tạo thư mục')),
                        onPressed: () =>
                            showBsCreateFolderDialog(context, s.id),
                      ),
                    ],
                  ),
                ),
              ),

              if (folders.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          tr('Chưa có thư mục Limited / Artbook / Goods nào. Bấm "Tạo thư mục" để lưu ảnh thực tế và phụ kiện đi kèm.'),
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList.separated(
                    itemCount: folders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, idx) {
                      final folder = folders[idx];
                      return _FolderCard(
                        folder: folder,
                        onAddItem: () =>
                            showBsItemDialog(context, folder: folder),
                        onEditItem: (item) => showBsItemDialog(context,
                            folder: folder, existing: item),
                        onRenameFolder: () => showBsCreateFolderDialog(
                            context, s.id,
                            existing: folder),
                        onDeleteFolder: () => _confirmDeleteFolder(folder),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folder,
    required this.onAddItem,
    required this.onEditItem,
    required this.onRenameFolder,
    required this.onDeleteFolder,
  });

  final BsFolder folder;
  final VoidCallback onAddItem;
  final ValueChanged<BsItem> onEditItem;
  final VoidCallback onRenameFolder;
  final VoidCallback onDeleteFolder;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.folder_special_outlined),
        title: Text(
          '${folder.name} (${folder.items.length})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: tr('Thêm ấn phẩm'),
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onAddItem,
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'rename') onRenameFolder();
                if (v == 'delete') onDeleteFolder();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'rename', child: Text(tr('Đổi tên thư mục'))),
                PopupMenuItem(value: 'delete', child: Text(tr('Xoá thư mục'))),
              ],
            ),
          ],
        ),
        children: [
          if (folder.items.isEmpty)
            ListTile(
              dense: true,
              title: Text(tr('Chưa có ấn phẩm nào trong thư mục này')),
              trailing: TextButton(
                onPressed: onAddItem,
                child: Text(tr('Thêm')),
              ),
            )
          else
            for (final item in folder.items)
              ListTile(
                onTap: () => onEditItem(item),
                leading: item.photos.isNotEmpty
                    ? BsCoverImage(
                        source: item.photos.first,
                        width: 44,
                        height: 60,
                        borderRadius: 6,
                      )
                    : const CircleAvatar(
                        child: Icon(Icons.collections_bookmark_outlined,
                            size: 20),
                      ),
                title: Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.storage.isNotEmpty || item.price != null)
                      Text(
                        [
                          if (item.storage.isNotEmpty) item.storage,
                          if (item.price != null) bsFormatMoney(item.price),
                        ].join(' • '),
                        style: textTheme.bodySmall,
                      ),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        if (item.postcard) _TagChip(tr('Postcard')),
                        if (item.poster) _TagChip(tr('Poster')),
                        if (item.standee) _TagChip(tr('Standee')),
                        if (item.sealed) _TagChip(tr('Nguyên Seal')),
                        if (item.photos.isNotEmpty)
                          _TagChip(tr('{p0} ảnh', {'p0': item.photos.length})),
                      ],
                    ),
                    if (item.notes.isNotEmpty)
                      Text(
                        item.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall,
                      ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: cs.onSecondaryContainer),
      ),
    );
  }
}
