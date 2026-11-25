import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mangayomi/utils/share.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_logic.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_models.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_store.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_feed.dart';
import 'package:mangayomi/yomihub/bookshelf/ui/bookshelf_dialogs.dart';
import 'package:mangayomi/yomihub/bookshelf/ui/bookshelf_feed_ui.dart';
import 'package:mangayomi/yomihub/bookshelf/ui/bookshelf_scan_screen.dart';
import 'package:mangayomi/yomihub/bookshelf/ui/bookshelf_series_screen.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/ui/mangayomi_v2/mv2_nav_shell.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum _BsTab { home, shelf, latest, limited, shopping, stats }

enum _ShelfFilter { all, ongoing, completed, missing, loaned }

enum _ShelfSort { recent, title, publisher, volumes }

/// Main screen of "Tủ Sách Cá Nhân" (route `/bookshelf`, FN-01..FN-07, FN-24,
/// FN-25, FN-30).
class BookshelfHomeScreen extends StatefulWidget {
  const BookshelfHomeScreen({super.key});

  @override
  State<BookshelfHomeScreen> createState() => _BookshelfHomeScreenState();
}

class _BookshelfHomeScreenState extends State<BookshelfHomeScreen> {
  final BookshelfStore _store = BookshelfStore.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  _BsTab _tab = _BsTab.home;
  _ShelfFilter _shelfFilter = _ShelfFilter.all;
  _ShelfSort _shelfSort = _ShelfSort.recent;
  bool _gridMode = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    // 0.6.4 FN-16: publisher news are read at most once a day
    _store.init().then((_) => BookshelfFeed.instance.refresh());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openSeries(String seriesId) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => BookshelfSeriesScreen(seriesId: seriesId),
      ),
    );
  }

  void _openScanner() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const BookshelfScanScreen()),
    );
  }

  Future<bool> _addVolumeWithGuard(
    BsSeries series,
    double number, {
    BsEdition edition = BsEdition.regular,
  }) async {
    final res = await _store.addVolume(series.id, number, edition: edition);
    if (!mounted) return false;
    if (res.duplicate) {
      final force = await showBsDuplicateVolumeDialog(
        context,
        series: series,
        existing: res.volume,
      );
      if (!force) return false;
      await _store.addVolume(
        series.id,
        number,
        edition: edition,
        allowExtraCopy: true,
      );
    }
    if (!mounted) return true;
    _snack(tr('Đã thêm Tập {p0} vào {p1}', {
      'p0': BookshelfStore.fmt(number),
      'p1': series.title,
    }));
    return true;
  }

  /// FN-30: Import CSV using file_picker 12 (List<PlatformFile>, readAsBytes).
  Future<void> _importCsv() async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      final file = picked.isEmpty ? null : picked.first;
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final text = utf8.decode(bytes, allowMalformed: true);
      final res = await _store.importCsv(text);
      if (!mounted) return;
      _snack(tr('Nhập CSV xong: +{p0} tập, +{p1} bộ (bỏ qua {p2})', {
        'p0': res.volumes,
        'p1': res.series,
        'p2': res.skipped,
      }));
    } catch (e) {
      _snack(tr('Lỗi nhập CSV: {p0}', {'p0': '$e'}));
    }
  }

  /// FN-30: Export CSV via file_picker 12 on Desktop, or Documents + share on mobile.
  Future<void> _exportCsv() async {
    try {
      final csv = _store.exportCsv();
      final bytes = utf8.encode(csv);
      final stamp = DateTime.now().toIso8601String().substring(0, 10);
      final fileName = 'YomiHub_TuSach_$stamp.csv';

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final savedPath = await FilePicker.saveFile(
          dialogTitle: tr('Xuất tủ sách CSV'),
          fileName: fileName,
          bytes: bytes,
          mimeType: 'text/csv',
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );
        if (savedPath != null && mounted) {
          _snack(tr('Đã xuất CSV: {p0}', {'p0': fileName}));
        }
      } else {
        Directory? dir;
        try {
          dir = await getExternalStorageDirectory();
        } catch (_) {}
        dir ??= await getApplicationDocumentsDirectory();
        final outPath = p.join(dir.path, fileName);
        await File(outPath).writeAsBytes(bytes);
        if (!mounted) return;
        await shareOrCopy(
          ShareParams(
            files: [XFile(outPath, mimeType: 'text/csv')],
            text: fileName,
          ),
          fallbackName: fileName,
        );
      }
    } catch (e) {
      _snack(tr('Lỗi xuất CSV: {p0}', {'p0': '$e'}));
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _tabLabel(_BsTab t) => switch (t) {
        _BsTab.home => tr('Tìm nhanh'),
        _BsTab.shelf => tr('Tủ truyện'),
        _BsTab.latest => tr('Tập mới nhất hiện có'),
        _BsTab.limited => tr('Bản Limited'),
        _BsTab.shopping => tr('Cần mua'),
        _BsTab.stats => tr('Thống kê'),
      };

  IconData _tabIcon(_BsTab t) => switch (t) {
        _BsTab.home => Icons.search_rounded,
        _BsTab.shelf => Icons.shelves,
        _BsTab.latest => Icons.fiber_new_outlined,
        _BsTab.limited => Icons.auto_awesome_outlined,
        _BsTab.shopping => Icons.shopping_cart_outlined,
        _BsTab.stats => Icons.bar_chart_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final floatingNav = Mv2FloatingNavScope.enabledOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom + (floatingNav ? 148 : 88);

    return ListenableBuilder(
      listenable: Listenable.merge([_store, YomiTr.version]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(tr('Tủ Sách Cá Nhân')),
            actions: [
              IconButton(
                tooltip: tr('Thêm bộ mới'),
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () async {
                  final created = await showBsSeriesFormDialog(context);
                  if (created != null && mounted) {
                    _openSeries(created.id);
                  }
                },
              ),
              PopupMenuButton<String>(
                tooltip: tr('Tuỳ chọn'),
                onSelected: (v) async {
                  switch (v) {
                    case 'add':
                      final created = await showBsSeriesFormDialog(context);
                      if (created != null && mounted) _openSeries(created.id);
                    case 'wish':
                      await showBsAddWishDialog(context);
                    case 'import':
                      await _importCsv();
                    case 'export':
                      await _exportCsv();
                    case 'cover':
                      await showBsCoverMatch(context, onOpenSeries: _openSeries);
                    case 'feed':
                      await showBsFeedSettings(context);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'add',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.library_add_outlined),
                      title: Text(tr('Thêm bộ mới')),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'wish',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.add_shopping_cart_outlined),
                      title: Text(tr('Thêm vào Cần mua')),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'cover',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.image_search_outlined),
                      title: Text(tr('Nhận diện bìa bằng ảnh')),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'feed',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.campaign_outlined),
                      title: Text(tr('Cài đặt thanh gợi ý & nguồn tin')),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'import',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.file_upload_outlined),
                      title: Text(tr('Nhập CSV')),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.file_download_outlined),
                      title: Text(tr('Xuất CSV')),
                    ),
                  ),
                ],
              ),
            ],
          ),
          drawer: _buildDrawer(context),
          floatingActionButton: Padding(
            padding: EdgeInsets.only(bottom: floatingNav ? 72 : 0),
            child: FloatingActionButton.extended(
              onPressed: _openScanner,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(tr('Quét mã vạch')),
            ),
          ),
          body: Column(
            children: [
              // Quick segmented/pill tab strip (FN-04)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: SegmentedButton<_BsTab>(
                  showSelectedIcon: false,
                  segments: [
                    for (final t in _BsTab.values)
                      ButtonSegment(
                        value: t,
                        icon: Icon(_tabIcon(t), size: 17),
                        label: Text(_tabLabel(t),
                            style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
              ),
              Expanded(
                child: switch (_tab) {
                  _BsTab.home => _buildHomeTab(bottomInset),
                  _BsTab.shelf => _buildShelfTab(bottomInset),
                  _BsTab.latest => _buildLatestTab(bottomInset),
                  _BsTab.limited => _buildLimitedTab(bottomInset),
                  _BsTab.shopping => _buildShoppingTab(bottomInset),
                  _BsTab.stats => _buildStatsTab(bottomInset),
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final st = _store.stats();
    return NavigationDrawer(
      selectedIndex: _tab.index,
      onDestinationSelected: (idx) {
        Navigator.pop(context);
        setState(() => _tab = _BsTab.values[idx]);
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shelves, size: 28, color: Colors.brown),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr('Tủ Sách Cá Nhân'),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tr('{p0} bộ • {p1} cuốn • {p2} Limited', {
                  'p0': st['series'],
                  'p1': st['books'],
                  'p2': st['limited'],
                }),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Divider(),
        for (final t in _BsTab.values)
          NavigationDrawerDestination(
            icon: Icon(_tabIcon(t)),
            label: Text(_tabLabel(t)),
          ),
      ],
    );
  }

  /// FN-01, FN-02, FN-03: Centered large search bar, horizontal hit cards with
  /// ownership color badges, and 6 recent series below.
  Widget _buildHomeTab(double bottomInset) {
    final cs = Theme.of(context).colorScheme;
    final trimmed = _query.trim();
    final hits = trimmed.isEmpty ? const <BsHit>[] : _store.search(trimmed);
    final recent = _store.recent.isNotEmpty
        ? _store.recent
        : _store.series.take(BookshelfStore.maxRecent).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset),
      children: [
        // FN-01: Prominent instant search bar
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: tr('Tìm truyện, tên viết tắt hoặc tập (vd: "One Piece 105", "jjk")'),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_query.isNotEmpty)
                          IconButton(
                            tooltip: tr('Xoá'),
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                        IconButton(
                          tooltip: tr('Quét mã vạch'),
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: _openScanner,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 0.6.4 FN-16: publisher news related to the shelf
        if (trimmed.isEmpty) BsFeedBanner(onOpenSeries: _openSeries),

        // Instant search results (FN-02)
        if (trimmed.isNotEmpty) ...[
          if (hits.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 40, color: cs.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(
                      tr('Không có bộ nào khớp "{p0}" trong tủ sách',
                          {'p0': trimmed}),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(tr('Thêm bộ mới "{p0}"', {'p0': trimmed})),
                      onPressed: () async {
                        final created = await showBsSeriesFormDialog(
                          context,
                          initialTitle: trimmed,
                        );
                        if (created != null && mounted) {
                          _openSeries(created.id);
                        }
                      },
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Text(
              tr('Kết quả tìm kiếm ({p0})', {'p0': hits.length}),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final hit in hits) _buildSearchHitCard(hit),
          ],
        ] else ...[
          // Quick suggestion chips
          Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.bolt, size: 16),
                  label: const Text('One Piece 105'),
                  onPressed: () {
                    _searchCtrl.text = 'One Piece 105';
                    setState(() => _query = 'One Piece 105');
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.bolt, size: 16),
                  label: const Text('jjk'),
                  onPressed: () {
                    _searchCtrl.text = 'jjk';
                    setState(() => _query = 'jjk');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // FN-03: 6 recent series
          if (recent.isEmpty)
            _buildEmptyOnboarding(context)
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    _store.recent.isNotEmpty
                        ? tr('6 bộ gần đây')
                        : tr('Cập nhật gần đây'),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _tab = _BsTab.shelf),
                  child: Text(tr('Xem tất cả')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recent.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final s = recent[i];
                  final latest = _store.latestOf(s.id);
                  final gaps = _store.gapsOf(s.id);
                  return SizedBox(
                    width: 112,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _openSeries(s.id),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              BsCoverImage(
                                source: s.cover,
                                width: 112,
                                height: 142,
                                borderRadius: 10,
                                fallbackTitle: s.title,
                              ),
                              if (latest != null)
                                Positioned(
                                  left: 5,
                                  bottom: 5,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.72),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      tr('Tập số {p0}',
                                          {'p0': BookshelfStore.fmt(latest)}),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              if (gaps.isNotEmpty)
                                Positioned(
                                  right: 5,
                                  top: 5,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade800,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '-${gaps.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            s.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickShortcutsGrid(),
          ],
        ],
      ],
    );
  }

  /// FN-02: Horizontal search result card with color-coded ownership badge.
  Widget _buildSearchHitCard(BsHit hit) {
    final s = hit.series;
    final gaps = _store.gapsOf(s.id);
    final subtitleParts = <String>[
      if (s.publisher.isNotEmpty) s.publisher,
      if (hit.latest != null)
        tr('Mới nhất: Tập {p0}', {'p0': BookshelfStore.fmt(hit.latest)}),
      if (gaps.isNotEmpty)
        tr('Thiếu {p0} tập', {'p0': gaps.length}),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openSeries(s.id),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              BsCoverImage(
                source: s.cover,
                width: 52,
                height: 76,
                borderRadius: 6,
                fallbackTitle: s.title,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        if (hit.volume != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tr('Tập số {p0}',
                                  {'p0': BookshelfStore.fmt(hit.volume)}),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitleParts.join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 6),
                    BsOwnershipBadge(ownership: hit.ownership),
                  ],
                ),
              ),
              if (hit.volume != null && hit.ownership != BsOwnership.owned)
                IconButton(
                  tooltip: tr('Thêm tập này vào tủ'),
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _addVolumeWithGuard(
                    s,
                    hit.volume!,
                    edition: hit.ownership == BsOwnership.regularOnly
                        ? BsEdition.limited
                        : BsEdition.regular,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyOnboarding(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.shelves, size: 52, color: cs.primary),
            const SizedBox(height: 10),
            Text(
              tr('Tủ sách của bạn đang trống'),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              tr('Quét mã vạch sau bìa sách, thêm thủ công từng bộ hoặc nhập nhanh từ tệp CSV.'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(tr('Quét mã vạch')),
                  onPressed: _openScanner,
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add),
                  label: Text(tr('Thêm bộ mới')),
                  onPressed: () async {
                    final created = await showBsSeriesFormDialog(context);
                    if (created != null && mounted) _openSeries(created.id);
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.file_upload_outlined),
                  label: Text(tr('Nhập CSV')),
                  onPressed: _importCsv,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickShortcutsGrid() {
    final st = _store.stats();
    final shoppingCount = _store.shoppingList().length;
    final latestCount = _store.latestList().length;

    Widget card(_BsTab tab, String subtitle, Color color) => Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _tab = tab),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.14),
                    foregroundColor: color,
                    child: Icon(_tabIcon(tab)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_tabLabel(tab),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

    return LayoutBuilder(
      builder: (_, box) {
        final cols = box.maxWidth >= 600 ? 2 : 1;
        final items = [
          card(_BsTab.shelf,
              tr('{p0} bộ • {p1} cuốn', {'p0': st['series'], 'p1': st['books']}),
              Colors.indigo),
          card(_BsTab.latest,
              tr('{p0} bộ đang theo dõi', {'p0': latestCount}),
              Colors.teal),
          card(_BsTab.limited,
              tr('{p0} ấn phẩm đặc biệt', {'p0': st['limited']}),
              Colors.amber.shade800),
          card(_BsTab.shopping,
              tr('{p0} mục cần mua', {'p0': shoppingCount}),
              Colors.deepOrange),
        ];
        if (cols == 1) {
          return Column(children: items);
        }
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 3.1,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: items,
        );
      },
    );
  }

  /// FN-06: Full bookshelf with grid/list toggle + status/gap filters.
  Widget _buildShelfTab(double bottomInset) {
    final all = _store.series;
    final filtered = all.where((s) {
      return switch (_shelfFilter) {
        _ShelfFilter.all => true,
        _ShelfFilter.ongoing => s.status == BsStatus.ongoing,
        _ShelfFilter.completed => s.status == BsStatus.completed,
        _ShelfFilter.missing => _store.gapsOf(s.id).isNotEmpty,
        _ShelfFilter.loaned => _store
            .volumesOf(s.id)
            .any((v) => (v.borrower ?? '').trim().isNotEmpty),
      };
    }).toList();
    // FN-06 "sắp xếp đa chiều" (0.6.6); the store list is newest-first already
    switch (_shelfSort) {
      case _ShelfSort.recent:
        break;
      case _ShelfSort.title:
        filtered.sort((a, b) => bsNormalize(a.title).compareTo(bsNormalize(b.title)));
      case _ShelfSort.publisher:
        filtered.sort((a, b) {
          final pa = bsNormalize(a.publisher), pb = bsNormalize(b.publisher);
          if (pa.isEmpty != pb.isEmpty) return pa.isEmpty ? 1 : -1;
          final c = pa.compareTo(pb);
          return c != 0 ? c : bsNormalize(a.title).compareTo(bsNormalize(b.title));
        });
      case _ShelfSort.volumes:
        final counts = {for (final s in filtered) s.id: _store.volumesOf(s.id).length};
        filtered.sort((a, b) => counts[b.id]!.compareTo(counts[a.id]!));
    }

    String sortLabel(_ShelfSort o) => switch (o) {
          _ShelfSort.recent => tr('Mới cập nhật'),
          _ShelfSort.title => tr('Tên A → Z'),
          _ShelfSort.publisher => tr('Nhà xuất bản'),
          _ShelfSort.volumes => tr('Nhiều tập nhất'),
        };

    String filterLabel(_ShelfFilter f) => switch (f) {
          _ShelfFilter.all => tr('Tất cả'),
          _ShelfFilter.ongoing => tr('Đang ra'),
          _ShelfFilter.completed => tr('Đã trọn bộ'),
          _ShelfFilter.missing => tr('Thiếu tập'),
          _ShelfFilter.loaned => tr('Đang cho mượn'),
        };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in _ShelfFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            selected: _shelfFilter == f,
                            label: Text(filterLabel(f)),
                            onSelected: (_) => setState(() => _shelfFilter = f),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<_ShelfSort>(
                tooltip: tr('Sắp xếp'),
                icon: const Icon(Icons.sort),
                initialValue: _shelfSort,
                onSelected: (v) => setState(() => _shelfSort = v),
                itemBuilder: (_) => [
                  for (final o in _ShelfSort.values)
                    PopupMenuItem(value: o, child: Text(sortLabel(o))),
                ],
              ),
              IconButton(
                tooltip: _gridMode ? tr('Chế độ danh sách') : tr('Chế độ lưới'),
                icon: Icon(_gridMode ? Icons.view_list : Icons.grid_view),
                onPressed: () => setState(() => _gridMode = !_gridMode),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(tr('Không có bộ truyện nào khớp bộ lọc')))
              : _gridMode
                  ? GridView.builder(
                      padding: EdgeInsets.fromLTRB(12, 4, 12, bottomInset),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 170,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.60,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final s = filtered[i];
                        final vols = _store.volumesOf(s.id);
                        final gaps = _store.gapsOf(s.id);
                        final ownedCount =
                            vols.map((v) => v.number).toSet().length;
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _openSeries(s.id),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    BsCoverImage(
                                      source: s.cover,
                                      borderRadius: 10,
                                      fallbackTitle: s.title,
                                    ),
                                    Positioned(
                                      left: 6,
                                      bottom: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.72),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          s.totalVolumes != null
                                              ? '$ownedCount/${s.totalVolumes}'
                                              : tr('{p0} tập sách',
                                                  {'p0': ownedCount}),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (gaps.isNotEmpty)
                                      Positioned(
                                        right: 6,
                                        top: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade800,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            tr('Thiếu {p0}',
                                                {'p0': gaps.length}),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                s.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(12, 4, 12, bottomInset),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final s = filtered[i];
                        final vols = _store.volumesOf(s.id);
                        final gaps = _store.gapsOf(s.id);
                        final ownedCount =
                            vols.map((v) => v.number).toSet().length;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () => _openSeries(s.id),
                            leading: BsCoverImage(
                              source: s.cover,
                              width: 44,
                              height: 62,
                              borderRadius: 6,
                              fallbackTitle: s.title,
                            ),
                            title: Text(s.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              [
                                bsStatusLabel(s.status),
                                s.totalVolumes != null
                                    ? '$ownedCount/${s.totalVolumes}'
                                    : tr('{p0} tập sách', {'p0': ownedCount}),
                                if (gaps.isNotEmpty)
                                  tr('Thiếu: {p0}',
                                      {'p0': bsRangeText(gaps)}),
                              ].join(' • '),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  /// FN-05: Latest owned volume per series.
  Widget _buildLatestTab(double bottomInset) {
    final list = _store.latestList();
    if (list.isEmpty) {
      return Center(
        child: Text(tr('Chưa có tập nào được đánh dấu đã mua')),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12, 4, 12, bottomInset),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final (s, latest) = list[i];
        final next = latest.floorToDouble() + 1;
        final canBuyNext = s.status == BsStatus.ongoing &&
            (s.totalVolumes == null || next <= s.totalVolumes!);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () => _openSeries(s.id),
            leading: BsCoverImage(
              source: s.cover,
              width: 44,
              height: 62,
              borderRadius: 6,
              fallbackTitle: s.title,
            ),
            title: Text(s.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              [
                if (s.publisher.isNotEmpty) s.publisher,
                bsStatusLabel(s.status),
              ].join(' • '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tr('Tập số {p0}', {'p0': BookshelfStore.fmt(latest)}),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                if (canBuyNext)
                  IconButton(
                    tooltip: tr('Thêm Tập {p0}',
                        {'p0': BookshelfStore.fmt(next)}),
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _addVolumeWithGuard(s, next),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Limited/Special volumes and custom folder items (FN-13..15).
  Widget _buildLimitedTab(double bottomInset) {
    final entries = <Widget>[];
    for (final s in _store.series) {
      for (final f in _store.foldersOf(s.id)) {
        for (final item in f.items) {
          entries.add(
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => _openSeries(s.id),
                leading: BsCoverImage(
                  source: item.photos.isNotEmpty ? item.photos.first : s.cover,
                  width: 46,
                  height: 64,
                  borderRadius: 6,
                  fallbackTitle: item.name,
                ),
                title: Text('${s.title} — ${item.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        f.name,
                        if (item.storage.isNotEmpty) item.storage,
                        if (item.price != null) bsFormatMoney(item.price),
                      ].join(' • '),
                    ),
                    Wrap(
                      spacing: 4,
                      children: [
                        if (item.postcard) Chip(label: Text(tr('Postcard'))),
                        if (item.poster) Chip(label: Text(tr('Poster'))),
                        if (item.standee) Chip(label: Text(tr('Standee'))),
                        if (item.sealed)
                          Chip(label: Text(tr('Nguyên Seal'))),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          );
        }
      }
      for (final v
          in _store.volumesOf(s.id).where((v) => v.edition != BsEdition.regular)) {
        entries.add(
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () => _openSeries(s.id),
              leading: BsCoverImage(
                source: s.cover,
                width: 46,
                height: 64,
                borderRadius: 6,
                fallbackTitle: s.title,
              ),
              title: Text(
                '${s.title} • ${tr('Tập số {p0}', {'p0': v.numberText})}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                [
                  bsEditionLabel(v.edition),
                  if (v.price != null) bsFormatMoney(v.price),
                  if (v.place.isNotEmpty) v.place,
                ].join(' • '),
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        );
      }
    }

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            tr('Chưa có bản Limited, Đặc biệt hoặc ấn phẩm nào. Mở một bộ truyện để thêm bản Limited hoặc tạo thư mục riêng.'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(12, 4, 12, bottomInset),
      children: entries,
    );
  }

  /// FN-25: Automatic shopping list (gaps + next ongoing + wishlist).
  Widget _buildShoppingTab(double bottomInset) {
    final items = _store.shoppingList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  tr('{p0} mục cần mua (dùng ngoại tuyến tại nhà sách)',
                      {'p0': items.length}),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(tr('Thêm vào Cần mua')),
                onPressed: () => showBsAddWishDialog(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(tr('Danh sách Cần mua đang trống')),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(12, 4, 12, bottomInset),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final (String reasonText, Color reasonColor) =
                        switch (item.reason) {
                      'gap' => (tr('Thiếu tập ở giữa'), Colors.red),
                      'next' => (tr('Tập tiếp theo'), Colors.blue),
                      _ => (tr('Wishlist'), Colors.purple),
                    };
                    final volText = item.volume == null
                        ? tr('Ấn phẩm / Chưa rõ tập')
                        : tr('Tập số {p0}',
                            {'p0': BookshelfStore.fmt(item.volume)});

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => _openSeries(item.series.id),
                        leading: BsCoverImage(
                          source: item.series.cover,
                          width: 44,
                          height: 62,
                          borderRadius: 6,
                          fallbackTitle: item.series.title,
                        ),
                        title: Text(
                          '${item.series.title} • $volText',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: reasonColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                reasonText,
                                style: TextStyle(
                                  color: reasonColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.wishId != null)
                              IconButton(
                                tooltip: tr('Xoá khỏi danh sách'),
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () =>
                                    _store.removeWish(item.wishId!),
                              ),
                            IconButton.filledTonal(
                              tooltip: tr('Đã mua – chuyển vào tủ'),
                              icon: const Icon(Icons.check),
                              onPressed: () async {
                                if (item.volume != null) {
                                  BsWish? wish;
                                  if (item.wishId != null) {
                                    for (final w in _store.wishes) {
                                      if (w.id == item.wishId) {
                                        wish = w;
                                        break;
                                      }
                                    }
                                  }
                                  final added = await _addVolumeWithGuard(
                                    item.series,
                                    item.volume!,
                                    edition:
                                        wish?.edition ?? BsEdition.regular,
                                  );
                                  if (added && item.wishId != null) {
                                    await _store.removeWish(item.wishId!);
                                  }
                                } else {
                                  final ok = await showBsVolumeEditDialog(
                                    context,
                                    series: item.series,
                                  );
                                  if (ok && item.wishId != null) {
                                    await _store.removeWish(item.wishId!);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// FN-24: Bookshelf statistics (totals, spending by month, publishers, gaps).
  Widget _buildStatsTab(double bottomInset) {
    final st = _store.stats();
    final totalSeries = st['series'] as int? ?? 0;
    final totalBooks = st['books'] as int? ?? 0;
    final totalLimited = st['limited'] as int? ?? 0;
    final spent = st['spent'] as double? ?? 0.0;
    final missingSeries = st['missingSeries'] as int? ?? 0;
    final byPub = Map<String, int>.from(st['byPublisher'] as Map? ?? const {});
    final byMonth =
        Map<String, double>.from(st['byMonth'] as Map? ?? const {});

    final pubEntries = byPub.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final monthEntries = byMonth.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final maxPub = pubEntries.isEmpty ? 1 : pubEntries.first.value;
    final maxMonth = monthEntries.isEmpty
        ? 1.0
        : monthEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final gapSeries =
        _store.series.where((s) => _store.gapsOf(s.id).isNotEmpty).toList();
    final loans = _store.loans();

    Widget kpi(String label, String val, IconData icon, Color color) => Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 8),
                Text(
                  val,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        );

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset),
      children: [
        LayoutBuilder(
          builder: (_, box) {
            final cols = box.maxWidth >= 600 ? 3 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.45,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                kpi(tr('Tổng số bộ'), '$totalSeries',
                    Icons.library_books_outlined, Colors.indigo),
                kpi(tr('Tổng số cuốn'), '$totalBooks',
                    Icons.menu_book_outlined, Colors.teal),
                kpi(tr('Bản Limited / Đặc biệt'), '$totalLimited',
                    Icons.auto_awesome_outlined, Colors.amber.shade800),
                kpi(tr('Tổng tiền đã chi'), bsFormatMoney(spent),
                    Icons.payments_outlined, Colors.green.shade700),
                kpi(tr('Bộ đang thiếu tập'), '$missingSeries',
                    Icons.warning_amber_rounded, Colors.deepOrange),
              ],
            );
          },
        ),
        if (pubEntries.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            tr('Tỉ lệ theo nhà xuất bản'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (final e in pubEntries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.key == '?' ? tr('Chưa rõ NXB') : e.key,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(tr('{p0} cuốn', {'p0': e.value})),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: maxPub == 0 ? 0 : e.value / maxPub,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (monthEntries.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            tr('Chi tiêu theo tháng'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (final e in monthEntries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(e.key,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ),
                              Text(bsFormatMoney(e.value)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: maxMonth <= 0 ? 0 : e.value / maxMonth,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (loans.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            tr('Đang cho mượn ({p0})', {'p0': loans.length}),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final l in loans)
            Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                onTap: () => _openSeries(l.series.id),
                title: Text(
                    '${l.series.title} · ${tr('Tập số {p0}', {'p0': l.volume.numberText})}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  l.volume.loanDue == null
                      ? tr('Người mượn: {p0}', {'p0': l.volume.borrower})
                      : tr('Người mượn: {p0} · Hạn trả: {p1}', {
                          'p0': l.volume.borrower,
                          'p1': bsFormatDate(l.volume.loanDue),
                        }),
                  style: l.volume.loanDue != null &&
                          l.volume.loanDue! < DateTime.now().millisecondsSinceEpoch
                      ? const TextStyle(color: Colors.red)
                      : null,
                ),
                trailing: TextButton(
                  onPressed: () async {
                    await _store.returnLoan(l.volume.id);
                    if (mounted) setState(() {});
                  },
                  child: Text(tr('Đã trả')),
                ),
              ),
            ),
        ],
        if (gapSeries.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            tr('Danh sách bộ đang thiếu tập'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final s in gapSeries)
            Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                onTap: () => _openSeries(s.id),
                title: Text(s.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  tr('Thiếu: {p0}', {'p0': bsRangeText(_store.gapsOf(s.id))}),
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
        ],
      ],
    );
  }
}
