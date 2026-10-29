import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/services/fetch_item_sources.dart';
import 'package:mangayomi/utils/cached_network.dart';
import 'package:mangayomi/yomihub/kotatsu/kotatsu_screen.dart';
import 'package:mangayomi/yomihub/repos/repo_importer.dart';
import 'package:mangayomi/yomihub/repos/repo_discovery.dart';
import 'package:url_launcher/url_launcher.dart';

/// Repositories YomiHub suggests (from the YomiHub extension repo list).
class YomiSuggestedRepo {
  final String url;
  final String name;
  final String note;
  final bool compatible;
  const YomiSuggestedRepo(
    this.url,
    this.name, {
    this.note = '',
    this.compatible = true,
  });
}

const yomiSuggestedRepos = <YomiSuggestedRepo>[
  YomiSuggestedRepo(
    'https://aidoku-community.github.io/sources/index.min.json',
    'Aidoku Community',
    note: 'Comic • nguồn Aidoku (.aix)',
  ),
  YomiSuggestedRepo(
    'https://raw.githubusercontent.com/Kareadita/tach-extension/repo/index.min.json',
    'Kavita',
    note: 'Comic • máy chủ Kavita riêng',
  ),
  YomiSuggestedRepo(
    'https://raw.githubusercontent.com/m2k3a/mangayomi-extensions/refs/heads/main/index.json',
    'Mangayomi (m2k3a) – Comic',
  ),
  YomiSuggestedRepo(
    'https://raw.githubusercontent.com/m2k3a/mangayomi-extensions/refs/heads/main/anime_index.json',
    'Mangayomi (m2k3a) – Film & Movie',
  ),
  YomiSuggestedRepo(
    'https://raw.githubusercontent.com/m2k3a/mangayomi-extensions/refs/heads/main/novel_index.json',
    'Mangayomi (m2k3a) – Novel',
  ),
  YomiSuggestedRepo(
    'https://raw.githubusercontent.com/LNReader/lnreader-plugins/plugins/v3.0.0/.dist/plugins.min.json',
    'LNReader plugins',
    note: 'Novel',
  ),
  YomiSuggestedRepo(
    'https://raw.githubusercontent.com/yuzono/anime-repo/repo/index.min.json',
    'Yūzōnō',
    note: 'Film & Movie • APK Aniyomi',
  ),
  YomiSuggestedRepo(
    'https://raw.githubusercontent.com/gato404/kegareta-sauces/main/index.json',
    'Kegareta Sauces',
    note: 'Comic • định dạng Mangayomi',
  ),
  YomiSuggestedRepo(
    'https://raw.githubusercontent.com/FelipeGFA/extensoes/repo/index.min.json',
    'FelipeGFA',
    note: 'Comic • APK Mihon',
  ),
  YomiSuggestedRepo(
    'https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.pb',
    'Keiyoushi',
    note: 'Comic • APK Mihon (kho .pb)',
  ),
  YomiSuggestedRepo(
    'https://raw.githubusercontent.com/IReaderorg/IReader-extensions/repov2/index.min.json',
    'IReader',
    note: 'Tiện ích APK của IReader dùng API riêng, không chạy được trong '
        'Mihon/Aniyomi/Mangayomi nên YomiHub không cài được.',
    compatible: false,
  ),
];

String _norm(String? u) {
  var s = (u ?? '').trim().toLowerCase().replaceFirst('/refs/heads/', '/');
  while (s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

String _typeName(ItemType t) => switch (t) {
  ItemType.manga => 'Comic',
  ItemType.anime => 'Film & Movie',
  ItemType.novel => 'Novel',
};

IconData _typeIcon(ItemType t) => switch (t) {
  ItemType.manga => Icons.collections_bookmark_outlined,
  ItemType.anime => Icons.movie_outlined,
  ItemType.novel => Icons.menu_book_outlined,
};

class _RepoEntry {
  final String key;
  Repo repo;
  final Set<ItemType> types = {};
  _RepoEntry(this.key, this.repo);
}

/// YomiHub 0.1.4: one "Extensions Repo" screen instead of three
/// (Comic / Film & Movie / Novel). Every repository is still stored per item
/// type, so extensions keep being classified exactly as before; this screen
/// just shows and edits all of them together.
class ExtensionsRepoScreen extends ConsumerStatefulWidget {
  const ExtensionsRepoScreen({super.key});

  @override
  ConsumerState<ExtensionsRepoScreen> createState() =>
      _ExtensionsRepoScreenState();
}

class _ExtensionsRepoScreenState extends ConsumerState<ExtensionsRepoScreen> {
  ItemType? _filter;
  bool _refreshing = false;
  bool _bannerClosed = false;

  @override
  void initState() {
    super.initState();
    // YomiHub 0.1.6: refresh the wotaku.wiki / miyomi.app list if it is
    // older than a day, then offer what is new.
    YomiRepoDiscovery.dailyScan().then((_) {
      if (mounted) setState(() {});
    });
  }

  /// Discovered repos that are not added yet.
  List<YomiSuggestedRepo> _newDiscovered() {
    final existing = _entries().map((e) => e.key).toSet();
    final builtIn = yomiSuggestedRepos.map((r) => _norm(r.url)).toSet();
    return [
      for (final r in YomiRepoDiscovery.items)
        if (!existing.contains(_norm(r.url)) && !builtIn.contains(_norm(r.url))) r,
    ];
  }

  List<_RepoEntry> _entries() {
    final map = <String, _RepoEntry>{};
    for (final t in ItemType.values) {
      for (final r in ref.watch(extensionsRepoStateProvider(t))) {
        final k = _norm(r.jsonUrl);
        if (k.isEmpty) continue;
        final e = map.putIfAbsent(k, () => _RepoEntry(k, r));
        e.types.add(t);
      }
    }
    final list = map.values.toList();
    list.sort(
      (a, b) => _displayName(a.repo).toLowerCase().compareTo(
        _displayName(b.repo).toLowerCase(),
      ),
    );
    return list;
  }

  static String _displayName(Repo repo) {
    final n = repo.name;
    if (n != null && n.isNotEmpty && !n.endsWith('.json')) return n;
    final u = repo.jsonUrl ?? '';
    return u
            .replaceAll(RegExp(r'/[^/]+\.(json|pb)$'), '')
            .split('/')
            .where((s) => s.isNotEmpty)
            .lastOrNull ??
        u;
  }

  ({int total, int installed}) _count(String key, ItemType t) {
    var total = 0, installed = 0;
    for (final s in sourceRepository.getByItemType(t)) {
      if (_norm(s.repo?.jsonUrl) != key) continue;
      total++;
      if ((s.sourceCode ?? '').isNotEmpty || (s.isAdded ?? false)) installed++;
    }
    return (total: total, installed: installed);
  }

  Future<void> _refreshAll() async {
    setState(() => _refreshing = true);
    for (final t in ItemType.values) {
      try {
        final provider = fetchItemSourcesListProvider(
          id: null,
          reFresh: true,
          itemType: t,
        );
        ref.invalidate(provider);
        await ref.read(provider.future);
      } catch (_) {}
    }
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _setTypes(_RepoEntry e, Set<ItemType> types) async {
    for (final t in ItemType.values) {
      final notifier = ref.read(extensionsRepoStateProvider(t).notifier);
      final current = List<Repo>.from(ref.read(extensionsRepoStateProvider(t)));
      final has = current.any((r) => _norm(r.jsonUrl) == e.key);
      if (types.contains(t) && !has) {
        current.add(
          Repo(
            name: e.repo.name,
            website: e.repo.website,
            jsonUrl: e.repo.jsonUrl,
            hidden: e.repo.hidden,
          ),
        );
        await notifier.set(current);
      } else if (!types.contains(t) && has) {
        current.removeWhere((r) => _norm(r.jsonUrl) == e.key);
        await notifier.set(current);
        await _removeOrphans(e.key, t);
      }
    }
  }

  Future<void> _removeOrphans(String key, ItemType t) async {
    final ids = sourceRepository
        .getByItemType(t)
        .where(
          (s) => _norm(s.repo?.jsonUrl) == key && (s.sourceCode?.isEmpty ?? true),
        )
        .map((s) => s.id!)
        .toList();
    if (ids.isNotEmpty) await sourceRepository.deleteAll(ids);
  }

  Future<void> _setHidden(_RepoEntry e, bool hidden) async {
    for (final t in e.types) {
      final list = ref.read(extensionsRepoStateProvider(t));
      for (final r in list) {
        if (_norm(r.jsonUrl) == e.key) {
          ref.read(extensionsRepoStateProvider(t).notifier).setVisibility(r, hidden);
        }
      }
    }
  }

  Future<int> _add(String text, {Set<ItemType>? forceTypes}) async {
    if (forceTypes != null && forceTypes.isNotEmpty) {
      var n = 0;
      final resolved = await YomiRepoImporter.resolve(ImportedRepo(text));
      final base = resolved.values.firstOrNull ??
          Repo(name: Uri.tryParse(text)?.host, website: text, jsonUrl: text);
      for (final t in forceTypes) {
        final current = List<Repo>.from(ref.read(extensionsRepoStateProvider(t)));
        if (current.any((r) => _norm(r.jsonUrl) == _norm(base.jsonUrl))) continue;
        current.add(
          Repo(name: base.name, website: base.website, jsonUrl: base.jsonUrl),
        );
        await ref.read(extensionsRepoStateProvider(t).notifier).set(current);
        n++;
      }
      return n;
    }
    return YomiRepoImporter.addAll(ref, [ImportedRepo(text)]);
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries();
    final shown = _filter == null
        ? entries
        : entries.where((e) => e.types.contains(_filter)).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extensions Repo'),
        actions: [
          IconButton(
            tooltip: 'Kotatsu Multi Parsers',
            icon: const Icon(Icons.extension_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const KotatsuScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Kho đề xuất',
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: () => _showSuggested(context),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'export') {
                await Clipboard.setData(
                  ClipboardData(text: jsonEncode(exportRepos(ref))),
                );
                _toast('Đã chép danh sách kho vào bộ nhớ tạm');
              } else if (v == 'import') {
                final data = await Clipboard.getData('text/plain');
                final n = await importRepos(ref, data?.text ?? '');
                _toast(n > 0 ? 'Đã thêm $n kho' : 'Không có kho mới');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('Chép danh sách kho')),
              PopupMenuItem(
                value: 'import',
                child: Text('Dán danh sách kho / link'),
              ),
            ],
          ),
          _refreshing
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  tooltip: 'Làm mới tất cả kho',
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshAll,
                ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('Tất cả (${entries.length})'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                for (final t in ItemType.values)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      avatar: Icon(_typeIcon(t), size: 16),
                      label: Text(
                        '${_typeName(t)} (${entries.where((e) => e.types.contains(t)).length})',
                      ),
                      selected: _filter == t,
                      onSelected: (_) => setState(() => _filter = t),
                    ),
                  ),
              ],
            ),
          ),
          if (!_bannerClosed && _newDiscovered().isNotEmpty)
            Card(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: ListTile(
                leading: const Icon(Icons.travel_explore),
                title: Text(
                  'Có ${_newDiscovered().length} kho tiện ích gợi ý từ wotaku, miyomi và 6 trang cộng đồng',
                ),
                subtitle: const Text('Cập nhật mỗi ngày khi mở ứng dụng'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _bannerClosed = true),
                ),
                onTap: () => _showSuggested(context),
              ),
            ),
          Expanded(
            child: shown.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Chưa có kho tiện ích nào.\nBấm "Thêm" hoặc biểu tượng ✨ để thêm kho đề xuất.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: shown.length,
                    itemBuilder: (context, i) => _tile(context, shown[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm'),
      ),
    );
  }

  Widget _tile(BuildContext context, _RepoEntry e) {
    final hidden = e.repo.hidden ?? false;
    final gh = RegExp(
      r'(?:raw\.githubusercontent\.com|github\.com)/([^/]+)/',
    ).firstMatch(e.repo.jsonUrl ?? '')?.group(1);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: hidden ? 0.4 : 1,
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: gh != null
                        ? cachedNetworkImage(
                            imageUrl: 'https://github.com/$gh.png?size=64',
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            errorWidget: const Icon(Icons.extension_outlined),
                            useCustomNetworkImage: false,
                          )
                        : const Icon(Icons.extension_outlined),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName(e.repo),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: hidden ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        Text(
                          e.repo.jsonUrl ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final t in e.types)
                  Builder(
                    builder: (_) {
                      final c = _count(e.key, t);
                      return Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(_typeIcon(t), size: 14),
                        label: Text(
                          '${_typeName(t)} • ${c.total} tiện ích${c.installed > 0 ? ' (${c.installed} đã cài)' : ''}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    },
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Phân loại',
                  icon: const Icon(Icons.category_outlined),
                  onPressed: () => _editTypes(context, e),
                ),
                if ((e.repo.website ?? '').isNotEmpty)
                  IconButton(
                    tooltip: 'Mở trang kho',
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => launchUrl(
                      Uri.parse(e.repo.website!),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                IconButton(
                  tooltip: 'Chép link',
                  icon: const Icon(Icons.content_copy),
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: e.repo.jsonUrl ?? '')),
                ),
                IconButton(
                  tooltip: hidden ? 'Hiện' : 'Ẩn',
                  icon: Icon(
                    hidden
                        ? Icons.visibility_off_outlined
                        : Icons.remove_red_eye_outlined,
                  ),
                  onPressed: () => _setHidden(e, !hidden),
                ),
                IconButton(
                  tooltip: 'Xoá',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, e),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmDelete(BuildContext context, _RepoEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá kho tiện ích?'),
        content: Text(
          '${_displayName(e.repo)}\n\nTiện ích đã cài vẫn được giữ lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok == true) await _setTypes(e, {});
  }

  Future<void> _editTypes(BuildContext context, _RepoEntry e) async {
    final sel = {...e.types};
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Phân loại kho'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final t in ItemType.values)
                CheckboxListTile(
                  value: sel.contains(t),
                  secondary: Icon(_typeIcon(t)),
                  title: Text(_typeName(t)),
                  onChanged: (v) => setD(() {
                    v == true ? sel.add(t) : sel.remove(t);
                  }),
                ),
              const Text(
                'Tiện ích trong kho vẫn tự xếp đúng mục theo loại của nó.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) await _setTypes(e, sel);
  }

  Future<void> _showAdd(BuildContext context) async {
    final controller = TextEditingController();
    final sel = <ItemType>{};
    var busy = false;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Thêm kho tiện ích'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    hintText: 'Link index.json / index.min.json / index.pb / GitHub',
                  ),
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Mục (để trống = tự nhận diện):',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final t in ItemType.values)
                      FilterChip(
                        label: Text(_typeName(t)),
                        selected: sel.contains(t),
                        onSelected: (v) =>
                            setD(() => v ? sel.add(t) : sel.remove(t)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final text = controller.text.trim();
                      if (text.isEmpty) return;
                      setD(() => busy = true);
                      final n = await _add(text, forceTypes: sel);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _toast(
                        n > 0
                            ? 'Đã thêm kho, đang tải danh sách tiện ích…'
                            : 'Kho đã có hoặc không đọc được',
                      );
                      if (n > 0) _refreshAll();
                    },
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSuggested(BuildContext context) async {
    final existing = _entries().map((e) => e.key).toSet();
    final builtIn = yomiSuggestedRepos.map((r) => _norm(r.url)).toSet();
    var all = <YomiSuggestedRepo>[
      ...yomiSuggestedRepos,
      for (final r in YomiRepoDiscovery.items)
        if (!builtIn.contains(_norm(r.url))) r,
    ];
    final sel = <String>{
      for (final r in yomiSuggestedRepos)
        if (r.compatible && !existing.contains(_norm(r.url))) r.url,
    };
    var busy = false;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Kho tiện ích đề xuất'),
          content: SizedBox(
            width: 420,
            child: ListView(
              shrinkWrap: true,
              children: [
                // 0.1.7: sites from "Website Scan - Extension Repo"
                if (YomiRepoDiscovery.siteStatus.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Nguồn quét: wotaku.wiki, miyomi.app, '
                      '${YomiRepoDiscovery.siteStatus.entries.map((e) => '${e.key} (${e.value})').join(', ')}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                for (final r in all)
                  CheckboxListTile(
                    dense: true,
                    value: existing.contains(_norm(r.url)) || sel.contains(r.url),
                    onChanged: !r.compatible || existing.contains(_norm(r.url))
                        ? null
                        : (v) => setD(
                            () => v == true ? sel.add(r.url) : sel.remove(r.url),
                          ),
                    title: Text(r.name),
                    subtitle: Text(
                      existing.contains(_norm(r.url))
                          ? 'Đã thêm'
                          : (r.note.isEmpty ? r.url : r.note),
                      style: TextStyle(
                        fontSize: 11,
                        color: r.compatible ? null : Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      setD(() => busy = true);
                      await YomiRepoDiscovery.scan();
                      all = [
                        ...yomiSuggestedRepos,
                        for (final r in YomiRepoDiscovery.items)
                          if (!builtIn.contains(_norm(r.url))) r,
                      ];
                      setD(() => busy = false);
                    },
              child: Text(busy ? 'Đang quét…' : 'Quét lại 8 trang gợi ý'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: busy || sel.isEmpty
                  ? null
                  : () async {
                      setD(() => busy = true);
                      final n = await YomiRepoImporter.addAll(ref, [
                        for (final u in sel) ImportedRepo(u),
                      ]);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _toast('Đã thêm $n kho, đang tải tiện ích…');
                      _refreshAll();
                    },
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Thêm ${sel.length} kho'),
            ),
          ],
        ),
      ),
    );
  }
}

/// `{manga: [...], anime: [...], novel: [...]}` — also written into every
/// YomiHub backup.
Map<String, dynamic> exportRepos(dynamic ref) => {
  for (final t in ItemType.values)
    t.name: (ref.read(extensionsRepoStateProvider(t)) as List<Repo>)
        .map((r) => r.toJson())
        .toList(),
};

/// Accepts what [exportRepos] produced, or plain links (one per line).
Future<int> importRepos(dynamic ref, String text) async {
  text = text.trim();
  if (text.isEmpty) return 0;
  try {
    final data = jsonDecode(text);
    if (data is Map) {
      var n = 0;
      for (final t in ItemType.values) {
        final list = data[t.name];
        if (list is! List) continue;
        final current = List<Repo>.from(
          ref.read(extensionsRepoStateProvider(t)) as List<Repo>,
        );
        final known = current.map((r) => _norm(r.jsonUrl)).toSet();
        for (final j in list.whereType<Map>()) {
          final r = Repo.fromJson(Map<String, dynamic>.from(j));
          if (_norm(r.jsonUrl).isEmpty || !known.add(_norm(r.jsonUrl))) continue;
          current.add(r);
          n++;
        }
        await ref.read(extensionsRepoStateProvider(t).notifier).set(current);
      }
      return n;
    }
  } catch (_) {}
  final urls = RegExp(r'https?://\S+')
      .allMatches(text)
      .map((m) => m.group(0)!)
      .toList();
  if (urls.isEmpty) return 0;
  return YomiRepoImporter.addAll(ref, [for (final u in urls) ImportedRepo(u)]);
}
