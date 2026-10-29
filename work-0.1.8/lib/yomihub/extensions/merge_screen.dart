import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/yomihub/extensions/builtin_extensions.dart';

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
        content: Text('Phát hiện ${groups.length} nhóm tiện ích trùng tên miền. Nên hợp nhất?'),
        action: SnackBarAction(label: 'Xem', onPressed: () => context.push('/mergeExtensions')),
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

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _all = ExtensionMergeHelper.allGroups(includeInactive: true);
    final merged = YomiMerge.groups;
    for (final g in _all) {
      final k = ExtensionMergeHelper.keyOf(g.first);
      final m = merged[k];
      _primary[k] = (m?['primary'] as int?) ?? g.firstWhere((s) => s.isActive ?? true, orElse: () => g.first).id!;
      _members[k] = m == null
          ? g.map((s) => s.id!).toSet()
          : ((m['members'] as List).cast<int>()).toSet();
    }
  }

  String _type(ItemType t) => switch (t) {
        ItemType.manga => 'Comic',
        ItemType.anime => 'Film & Movie',
        ItemType.novel => 'Novel',
      };

  int _libraryCount(Source s) {
    try {
      return mangaRepository
          .getFavoritesNonLocalArchive()
          .where((m) => m.sourceId == s.id || (m.source == s.name && m.lang == s.lang))
          .length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _merge(List<Source> g) async {
    final k = ExtensionMergeHelper.keyOf(g.first);
    final members = {..._members[k]!, _primary[k]!}.toList();
    // keep every member installed *and enabled*
    for (final s in g.where((s) => members.contains(s.id) && !(s.isActive ?? true))) {
      s.isActive = true;
      await sourceRepository.save(s);
    }
    await YomiMerge.merge(k, _primary[k]!, members);
    if (!mounted) return;
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã hợp nhất ${members.length} tiện ích – tất cả vẫn được giữ và bật'),
      ),
    );
  }

  Future<void> _unmerge(List<Source> g) async {
    await YomiMerge.unmerge(ExtensionMergeHelper.keyOf(g.first));
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
    final disabled = [
      for (final g in _all) ...g.where((s) => !(s.isActive ?? true)),
    ];
    final merged = _all.where((g) => YomiMerge.isMerged(ExtensionMergeHelper.keyOf(g.first))).toList();
    final open = _all.where((g) => !YomiMerge.isMerged(ExtensionMergeHelper.keyOf(g.first))).toList();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Hợp nhất tiện ích')),
      body: _all.isEmpty
          ? const Center(child: Text('Không có tiện ích nào trùng tên miền.'))
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'Hợp nhất chỉ gộp các tiện ích cùng trang web dưới một tiện ích chính trong Duyệt › Nguồn. '
                    'Mọi tiện ích đã cài đều được giữ nguyên và vẫn bật (thư viện, lịch sử, tải xuống, tìm kiếm toàn cục '
                    'vẫn dùng được). Có thể đổi tiện ích chính, thêm/bớt thành viên hoặc tách nhóm bất cứ lúc nào.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                if (disabled.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: const Icon(Icons.restore, color: Colors.orange),
                      title: Text('${disabled.length} tiện ích đang bị tắt'),
                      subtitle: const Text('Bản 0.1.4 tắt các tiện ích phụ khi hợp nhất. Bật lại để giữ nguyên như đã cài.'),
                      trailing: FilledButton.tonal(
                        onPressed: () => _reEnable(disabled),
                        child: const Text('Bật lại'),
                      ),
                    ),
                  ),
                if (open.isNotEmpty) _header('Chưa hợp nhất (${open.length})'),
                for (final g in open) _group(g, merged: false),
                if (merged.isNotEmpty) _header('Đã hợp nhất (${merged.length})'),
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
    final k = ExtensionMergeHelper.keyOf(g.first);
    final host = ExtensionMergeHelper.hostOf(g.first.baseUrl);
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
                leading: Icon(merged ? Icons.merge_type : Icons.call_split,
                    color: merged ? Colors.green : null),
                title: Text(host, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${_type(g.first.itemType)} • chọn tiện ích chính (●) và thành viên (☑)'),
              ),
              for (final s in g)
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<int>(
                        value: s.id!,
                        title: Text(s.name ?? ''),
                        subtitle: Text(
                          '${s.lang ?? ''} • v${s.version ?? '?'} • ${_libraryCount(s)} mục trong thư viện'
                          '${(s.isActive ?? true) ? '' : ' • đang tắt'}',
                        ),
                      ),
                    ),
                    Checkbox(
                      value: members.contains(s.id),
                      onChanged: s.id == _primary[k]
                          ? null
                          : (v) => setState(() => v == true ? members.add(s.id!) : members.remove(s.id)),
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
                        label: const Text('Tách nhóm'),
                        onPressed: () => _unmerge(g),
                      ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.merge_type),
                      label: Text(merged ? 'Lưu thay đổi' : 'Hợp nhất'),
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
