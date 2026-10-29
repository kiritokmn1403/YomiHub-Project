import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/yomihub/extensions/builtin_extensions.dart';
import 'package:mangayomi/utils/log/logger.dart';

/// YomiHub: "Hợp nhất tiện ích" – sources that point at the same website.
///
/// 0.1.5: merging no longer disables anything. All merged extensions stay
/// installed and enabled; the chosen primary represents the website in
/// Browse › Sources, and every merge can be edited or undone here.
class ExtensionMergeScreen extends StatefulWidget {
  const ExtensionMergeScreen({super.key});

  /// Shows a one-time hint when unmerged duplicate domains are found (called
  /// from the More screen).
  static Future<void> suggestIfNeeded(BuildContext context) async {
    final groups = ExtensionMergeHelper.duplicateGroups();
    if (groups.isEmpty || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        persist: false,
        showCloseIcon: true,
        content: Text(
          tr('Phát hiện {p0} nhóm tiện ích trùng tên miền. Nên hợp nhất?', {
            'p0': groups.length,
          }),
        ),
        action: SnackBarAction(
          label: tr('Xem'),
          onPressed: () => context.push('/mergeExtensions'),
        ),
      ),
    );
  }

  @override
  State<ExtensionMergeScreen> createState() => _ExtensionMergeScreenState();
}

class _ExtensionMergeScreenState extends State<ExtensionMergeScreen> {
  late List<List<Source>> _all;
  final Map<String, int> _primary = {};
  final Map<String, Set<int>> _members = {};
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// 0.4.3: library counts are computed once per reload (was: the whole
  /// library was scanned for every source row on every rebuild – each tap
  /// on a checkbox froze the screen with a big library).
  final Map<int, int> _counts = {};
  final Map<String, int> _countsByName = {};

  /// key of every group shown (host groups use "itemType|host", hand-made
  /// groups "custom|…")
  final Map<List<Source>, String> _keys = {};

  String _keyOf(List<Source> g) =>
      _keys[g] ?? ExtensionMergeHelper.keyOf(g.first);

  void _reload() {
    _counts.clear();
    _countsByName.clear();
    try {
      for (final m in mangaRepository.getFavoritesNonLocalArchive()) {
        if (m.sourceId != null) {
          _counts[m.sourceId!] = (_counts[m.sourceId!] ?? 0) + 1;
        }
        final n = '${m.source}|${m.lang}';
        _countsByName[n] = (_countsByName[n] ?? 0) + 1;
      }
    } catch (_) {}
    _keys.clear();
    _all = ExtensionMergeHelper.allGroups(includeInactive: true);
    final merged = YomiMerge.groups;
    // hand-made groups (sources of different websites picked by the user)
    for (final e in merged.entries) {
      if (!YomiMerge.isCustom(e.key)) continue;
      final g = <Source>[
        for (final id in (e.value['members'] as List? ?? const []).cast<int>())
          ?sourceRepository.getById(id),
      ];
      if (g.length < 2) continue;
      _keys[g] = e.key;
      _all.add(g);
    }
    for (final g in _all) {
      final k = _keyOf(g);
      final m = merged[k];
      _primary[k] =
          (m?['primary'] as int?) ??
          g.firstWhere((s) => s.isActive ?? true, orElse: () => g.first).id!;
      _members[k] = m == null
          ? g.map((s) => s.id!).toSet()
          : ((m['members'] as List).cast<int>()).toSet();
    }
  }

  String _type(ItemType t) => switch (t) {
    ItemType.manga => YomiTr.term(0),
    ItemType.anime => YomiTr.term(1),
    ItemType.novel => YomiTr.term(2),
  };

  int _libraryCount(Source s) {
    final byId = _counts[s.id] ?? 0;
    final byName = _countsByName['${s.name}|${s.lang}'] ?? 0;
    return byId > byName ? byId : byName;
  }

  /// 0.4.3 (sheet "YomiHub Update"): the user picks any extensions to merge,
  /// not only the ones that share a website.
  Future<void> _pickCustom() async {
    final sources = sourceRepository.getInstalled().toList()
      ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    if (sources.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Cần cài đặt ít nhất 2 tiện ích để thực hiện hợp nhất.'))),
      );
      return;
    }
    final chosen = <int>{};
    int? primary;
    var filter = '';
    ItemType? type;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dc) => StatefulBuilder(
        builder: (dc, setD) {
          final q = filter.toLowerCase();
          final list = sources
              .where(
                (s) =>
                    (type == null || s.itemType == type) &&
                    (q.isEmpty ||
                        (s.name ?? '').toLowerCase().contains(q) ||
                        (s.baseUrl ?? '').toLowerCase().contains(q)),
              )
              .toList();
          return AlertDialog(
            title: Text(tr('Tự chọn tiện ích để hợp nhất')),
            content: SizedBox(
              width: double.maxFinite,
              height: 420,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: tr('Tìm kiếm theo tên tiện ích, tên miền, URL...'),
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (v) => setD(() => filter = v),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr('Chọn từ 2 tiện ích cùng loại trở lên; bấm ● để đặt tiện ích chính.'),
                    style: Theme.of(dc).textTheme.bodySmall,
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final s = list[i];
                        final on = chosen.contains(s.id);
                        return CheckboxListTile(
                          dense: true,
                          value: on,
                          secondary: IconButton(
                            tooltip: tr('Đặt làm tiện ích chính'),
                            icon: Icon(
                              primary == s.id
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 18,
                            ),
                            onPressed: on
                                ? () => setD(() => primary = s.id)
                                : null,
                          ),
                          title: Text(s.name ?? ''),
                          subtitle: Text(
                            '${_type(s.itemType)} • ${s.lang ?? ''} • ${ExtensionMergeHelper.hostOf(s.baseUrl)}',
                          ),
                          onChanged: (v) => setD(() {
                            if (v == true) {
                              chosen.add(s.id!);
                              type ??= s.itemType;
                              primary ??= s.id;
                            } else {
                              chosen.remove(s.id);
                              if (primary == s.id) {
                                primary = chosen.isEmpty ? null : chosen.first;
                              }
                              if (chosen.isEmpty) type = null;
                            }
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dc, false),
                child: Text(tr('Huỷ')),
              ),
              FilledButton(
                onPressed: chosen.length < 2
                    ? null
                    : () => Navigator.pop(dc, true),
                child: Text(tr('Hợp nhất')),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || chosen.length < 2 || primary == null) return;
    final key =
        '${YomiMerge.customPrefix}${type?.index ?? 0}|${DateTime.now().millisecondsSinceEpoch}';
    try {
      await YomiMerge.merge(key, primary!, chosen.toList());
      AppLogger.log(
        '[Hợp nhất] Đã hợp nhất tự chọn ${chosen.length} tiện ích: ${chosen.join(', ')}',
        logLevel: LogLevel.info,
      );
    } catch (e) {
      AppLogger.log('[Hợp nhất] Lỗi khi hợp nhất tự chọn: $e', logLevel: LogLevel.error);
    }
    if (mounted) setState(_reload);
  }

  Future<void> _merge(List<Source> g) async {
    final k = _keyOf(g);
    final members = {..._members[k]!, _primary[k]!}.toList();
    for (final id in members) {
      final s = sourceRepository.getById(id);
      if (s == null) {
        AppLogger.log(
          '[Hợp nhất] Nguồn $id không tồn tại trong cơ sở dữ liệu',
          logLevel: LogLevel.error,
        );
      }
    }
    // keep every member installed *and enabled*
    for (final s in g.where(
      (s) => members.contains(s.id) && !(s.isActive ?? true),
    )) {
      s.isActive = true;
      await sourceRepository.save(s);
    }
    try {
      await YomiMerge.merge(k, _primary[k]!, members);
    } catch (e) {
      AppLogger.log(
        '[Hợp nhất] Lỗi khi lưu nhóm hợp nhất $k: $e',
        logLevel: LogLevel.error,
      );
    }
    if (!mounted) return;
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr('Đã hợp nhất {p0} tiện ích – tất cả vẫn được giữ và bật', {
            'p0': members.length,
          }),
        ),
      ),
    );
  }

  Future<void> _unmerge(List<Source> g) async {
    try {
      await YomiMerge.unmerge(_keyOf(g));
    } catch (e) {
      AppLogger.log(
        '[Hợp nhất] Lỗi khi tách nhóm: $e',
        logLevel: LogLevel.error,
      );
    }
    if (mounted) setState(_reload);
  }

  Future<void> _reEnable(List<Source> list) async {
    for (final s in list) {
      s.isActive = true;
      await sourceRepository.save(s);
    }
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchQuery.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _all
        : _all.where((g) {
            final host = ExtensionMergeHelper.hostOf(g.first.baseUrl)
                .toLowerCase();
            return host.contains(q) ||
                g.any(
                  (s) =>
                      (s.name ?? '').toLowerCase().contains(q) ||
                      (s.baseUrl ?? '').toLowerCase().contains(q) ||
                      (s.lang ?? '').toLowerCase().contains(q),
                );
          }).toList();
    final disabled = [
      for (final g in filtered) ...g.where((s) => !(s.isActive ?? true)),
    ];
    final merged = filtered
        .where((g) => YomiMerge.isMerged(_keyOf(g)))
        .toList();
    final open = filtered
        .where((g) => !YomiMerge.isMerged(_keyOf(g)))
        .toList();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Hợp nhất tiện ích')),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_check),
            tooltip: tr('Tự chọn tiện ích để hợp nhất'),
            onPressed: _pickCustom,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: tr('Làm mới'),
            onPressed: () {
              if (mounted) setState(_reload);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickCustom,
        icon: const Icon(Icons.playlist_add_check),
        label: Text(tr('Tự chọn tiện ích')),
      ),
      body: _all.isEmpty
          ? Center(child: Text(tr('Không có tiện ích nào trùng tên miền. Bấm "Tự chọn tiện ích" để hợp nhất các tiện ích bất kỳ.'), textAlign: TextAlign.center))
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    tr(
                      'Hợp nhất chỉ gộp các tiện ích cùng trang web dưới một tiện ích chính trong Duyệt › Nguồn. Mọi tiện ích đã cài đều được giữ nguyên và vẫn bật (thư viện, lịch sử, tải xuống, tìm kiếm toàn cục vẫn dùng được). Có thể đổi tiện ích chính, thêm/bớt thành viên hoặc tách nhóm bất cứ lúc nào.',
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: tr(
                        'Tìm kiếm theo tên tiện ích, tên miền, URL...',
                      ),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                if (filtered.isEmpty && _searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        tr('Không tìm thấy tiện ích nào khớp với "{p0}"', {
                          'p0': _searchQuery,
                        }),
                        style: TextStyle(color: theme.hintColor),
                      ),
                    ),
                  ),
                if (disabled.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: const Icon(Icons.restore, color: Colors.orange),
                      title: Text(
                        tr('{p0} tiện ích đang bị tắt', {
                          'p0': disabled.length,
                        }),
                      ),
                      subtitle: Text(
                        tr(
                          'Bản 0.1.4 tắt các tiện ích phụ khi hợp nhất. Bật lại để giữ nguyên như đã cài.',
                        ),
                      ),
                      trailing: FilledButton.tonal(
                        onPressed: () => _reEnable(disabled),
                        child: Text(tr('Bật lại')),
                      ),
                    ),
                  ),
                if (open.isNotEmpty)
                  _header(tr('Chưa hợp nhất ({p0})', {'p0': open.length})),
                for (final g in open) _group(g, merged: false),
                if (merged.isNotEmpty)
                  _header(tr('Đã hợp nhất ({p0})', {'p0': merged.length})),
                for (final g in merged) _group(g, merged: true),
              ],
            ),
    );
  }

  Widget _header(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      t,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _group(List<Source> g, {required bool merged}) {
    final k = _keyOf(g);
    final custom = YomiMerge.isCustom(k);
    final host = custom
        ? '${tr('Tự chọn')}: ${g.map((s) => s.name ?? '').join(' + ')}'
        : ExtensionMergeHelper.hostOf(g.first.baseUrl);
    final members = _members[k]!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: RadioGroup<int>(
          groupValue: _primary[k],
          onChanged: (v) => setState(() {
            _primary[k] = v!;
            members.add(v);
          }),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(
                  merged ? Icons.merge_type : Icons.call_split,
                  color: merged ? Colors.green : null,
                ),
                title: Text(
                  host,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  tr('{p0} • chọn tiện ích chính (●) và thành viên (☑)', {
                    'p0': _type(g.first.itemType),
                  }),
                ),
              ),
              for (final s in g)
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<int>(
                        value: s.id!,
                        title: Text(s.name ?? ''),
                        subtitle: Text(
                          tr('{p0} • v{p1} • {p2} mục trong thư viện{p3}', {
                            'p0': s.lang ?? '',
                            'p1': s.version ?? '?',
                            'p2': _libraryCount(s),
                            'p3': (s.isActive ?? true)
                                ? ''
                                : ' • ${tr('đang tắt')}',
                          }),
                        ),
                      ),
                    ),
                    Checkbox(
                      value: members.contains(s.id),
                      onChanged: s.id == _primary[k]
                          ? null
                          : (v) => setState(
                              () => v == true
                                  ? members.add(s.id!)
                                  : members.remove(s.id),
                            ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (merged)
                      TextButton.icon(
                        icon: const Icon(Icons.call_split),
                        label: Text(tr('Tách nhóm')),
                        onPressed: () => _unmerge(g),
                      ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.merge_type),
                      label: Text(merged ? tr('Lưu thay đổi') : tr('Hợp nhất')),
                      onPressed: members.length < 2 ? null : () => _merge(g),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
