import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/eval/model/m_bridge.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/utils/constant.dart';
import 'package:mangayomi/yomihub/extensions/builtin_extensions.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

class ExtensionMergeScreen extends ConsumerStatefulWidget {
  const ExtensionMergeScreen({super.key});

  @override
  ConsumerState<ExtensionMergeScreen> createState() =>
      _ExtensionMergeScreenState();
}

class _ExtensionMergeScreenState extends ConsumerState<ExtensionMergeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final allSources = sourceRepository
        .getAll()
        .where((s) => s.isAdded ?? false)
        .toList();
    final groups = YomiMerge.groups;

    return Scaffold(
      appBar: AppBar(title: Text(tr('Hợp Nhất Tiện Ích'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary.withValues(alpha: 0.15),
                  cs.tertiary.withValues(alpha: 0.08),
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
                Icon(Icons.hub_rounded, color: cs.primary, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Cài đặt Hợp Nhất Tiện Ích'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(
                          'Người dùng tự chọn các tiện ích nguồn để hợp nhất với nhau hoặc chuyển đổi nội dung sang tiện ích đích mong muốn.',
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

          // Action 1: Tự chọn các tiện ích để hợp nhất
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.playlist_add_check_rounded,
                color: Colors.teal,
              ),
              title: Text(tr('Tự chọn các tiện ích để hợp nhất')),
              subtitle: Text(
                tr(
                  'Chọn danh sách tiện ích nguồn và chỉ định tiện ích đích để gộp chung',
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () => _pickAndMergeExtensions(context, allSources),
            ),
          ),
          const SizedBox(height: 16),

          // Header danh sách nhóm đã hợp nhất
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              tr('Các nhóm tiện ích đã hợp nhất ({p0})', {
                'p0': '${groups.length}',
              }),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ),

          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  tr('Chưa có tiện ích nào được thiết lập hợp nhất.'),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
              ),
            )
          else
            ...groups.entries.map((e) {
              final key = e.key;
              final data = e.value;
              final primaryId = data['primary'] as int?;
              final memberIds = (data['members'] as List? ?? const [])
                  .cast<int>();
              final primarySource = primaryId != null
                  ? sourceRepository.getById(primaryId)
                  : null;
              final memberSources = memberIds
                  .map((id) => sourceRepository.getById(id))
                  .whereType<Source>()
                  .toList();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.call_merge_rounded,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              primarySource?.name ?? key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                            ),
                            tooltip: tr('Hủy hợp nhất nhóm này'),
                            onPressed: () async {
                              await YomiMerge.unmerge(key);
                              if (!mounted) return;
                              setState(() {});
                              botToast(tr('Đã hủy hợp nhất nhóm tiện ích.'));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr('Bao gồm {p0} tiện ích: {p1}', {
                          'p0': '${memberSources.length}',
                          'p1': memberSources
                              .map((s) => s.name ?? '')
                              .join(', '),
                        }),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _pickAndMergeExtensions(
    BuildContext context,
    List<Source> allSources,
  ) async {
    if (allSources.length < 2) {
      botToast(tr('Cần cài đặt ít nhất 2 tiện ích để thực hiện hợp nhất.'));
      return;
    }

    final selected = await showDialog<List<Source>>(
      context: context,
      builder: (dContext) {
        final chosen = <Source>{};
        var filter = '';
        return StatefulBuilder(
          builder: (dContext, setModalState) {
            final list = allSources
                .where(
                  (s) =>
                      filter.isEmpty ||
                      (s.name?.toLowerCase().contains(filter.toLowerCase()) ??
                          false),
                )
                .toList();
            return AlertDialog(
              title: Text(tr('Chọn các tiện ích nguồn')),
              content: SizedBox(
                width: double.maxFinite,
                height: 380,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: tr('Tìm tiện ích...'),
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
                          final s = list[idx];
                          final isChecked = chosen.contains(s);
                          return CheckboxListTile(
                            dense: true,
                            value: isChecked,
                            title: Text(s.name ?? ''),
                            subtitle: Text(
                              '${s.lang ?? ""} • ${s.itemType.name}',
                            ),
                            onChanged:
                                chosen.isNotEmpty &&
                                    chosen.first.itemType != s.itemType
                                ? null
                                : (val) {
                                    setModalState(() {
                                      if (val == true &&
                                          (chosen.isEmpty ||
                                              chosen.first.itemType ==
                                                  s.itemType)) {
                                        chosen.add(s);
                                      } else {
                                        chosen.remove(s);
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
                    tr('Chọn tiện ích đích ({p0})', {'p0': '${chosen.length}'}),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null && selected.length >= 2 && mounted) {
      final target = await showDialog<Source>(
        context: context,
        builder: (dContext) => AlertDialog(
          title: Text(tr('Chọn tiện ích đích')),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: selected.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, idx) {
                final s = selected[idx];
                return ListTile(
                  title: Text(s.name ?? ''),
                  subtitle: Text('${s.lang ?? ""} • ${s.itemType.name}'),
                  onTap: () => Navigator.pop(dContext, s),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dContext, null),
              child: Text(tr('Hủy')),
            ),
          ],
        ),
      );

      if (target != null && mounted) {
        final memberIds = selected.map((s) => s.id!).toList();
        final groupKey = '${target.itemType.name}|${target.name}';
        await YomiMerge.merge(groupKey, target.id!, memberIds);

        // Grouping the browser entries must not rewrite library source IDs:
        // each stored URL still needs the parser from its original extension.
        for (final source in selected) {
          if (!(source.isActive ?? true)) {
            source.isActive = true;
            await sourceRepository.save(source);
          }
        }
        if (!mounted) return;
        setState(() {});
        botToast(
          tr('Đã hợp nhất {p0} tiện ích vào "{p1}".', {
            'p0': '${selected.length}',
            'p1': target.name ?? '',
          }),
        );
      }
    }
  }
}
