import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/eval/model/m_bridge.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/modules/mass_migration/mass_migration_preview_screen.dart';
import 'package:mangayomi/modules/mass_migration/models/mass_migration_models.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/delete_source.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/pre_import_backup.dart';
import 'package:mangayomi/modules/more/widgets/dialog_actions.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/repositories/chapter_repository.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/router/router.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

String _itemTypeLabel(BuildContext context, ItemType itemType) {
  final l10n = context.l10n;
  return switch (itemType) {
    ItemType.manga => l10n.manga,
    ItemType.anime => l10n.anime,
    ItemType.novel => l10n.novel,
  };
}

class DeleteSourceTile extends ConsumerWidget {
  const DeleteSourceTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ListTile(
      leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
      title: Text(
        l10n.delete_source_title,
        style: const TextStyle(color: Colors.red),
      ),
      subtitle: Text(
        l10n.delete_source_subtitle,
        style: TextStyle(fontSize: 11, color: context.secondaryColor),
      ),
      onTap: () => _deleteSource(context, ref),
    );
  }
}

class MissingSourceCheckTile extends ConsumerWidget {
  const MissingSourceCheckTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ListTile(
      leading: const Icon(
        Icons.extension_off_outlined,
        color: Colors.orange,
      ),
      title: Text(l10n.missing_source_check_title),
      subtitle: Text(
        l10n.missing_source_check_subtitle,
        style: TextStyle(fontSize: 11, color: context.secondaryColor),
      ),
      onTap: () => _checkMissingSources(context),
    );
  }
}

class MergeDuplicateMangaTile extends ConsumerWidget {
  const MergeDuplicateMangaTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ListTile(
      leading: const Icon(Icons.join_full_rounded),
      title: Text(l10n.merge_manga_title),
      subtitle: Text(
        l10n.merge_manga_subtitle,
        style: TextStyle(fontSize: 11, color: context.secondaryColor),
      ),
      onTap: () => _mergeDuplicateManga(context, ref),
    );
  }
}

class ManualMergeMangaTile extends ConsumerWidget {
  const ManualMergeMangaTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.merge_type_rounded, color: Colors.blueAccent),
      title: Text(tr('Tự chọn bộ để hợp nhất')),
      subtitle: Text(
        tr('Chọn 2 hoặc nhiều bộ truyện/phim trong thư viện để hợp nhất, bảo lưu nguồn gốc'),
        style: TextStyle(fontSize: 11, color: context.secondaryColor),
      ),
      onTap: () => _manualMergeManga(context, ref),
    );
  }
}

class CustomMergeSourcesTile extends ConsumerWidget {
  const CustomMergeSourcesTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.call_merge_rounded, color: Colors.teal),
      title: Text(tr('Hợp nhất tiện ích theo lựa chọn')),
      subtitle: Text(
        tr('Chọn các tiện ích nguồn để hợp nhất sang tiện ích đích mong muốn'),
        style: TextStyle(fontSize: 11, color: context.secondaryColor),
      ),
      onTap: () => _customMergeSources(context, ref),
    );
  }
}

Future<void> _checkMissingSources(BuildContext context) async {
  final l10n = context.l10n;
  final groups = librarySourceGroupsMissingSource();
  if (groups.isEmpty) {
    botToast(l10n.missing_source_check_none_found);
    return;
  }

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.missing_source_check_result_title(groups.length)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.missing_source_check_result_message,
                style: TextStyle(
                  fontSize: 12,
                  color: dialogContext.secondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: groups.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (itemContext, index) {
                    final g = groups[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                      title: Text(
                        g.lang != null
                            ? "${g.sourceName} (${g.lang})"
                            : g.sourceName,
                      ),
                      subtitle: Text(
                        "${_itemTypeLabel(itemContext, g.itemType)} • ${g.mangaCount}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.call_merge_rounded, color: Colors.blue),
                            tooltip: tr('Gộp tất cả các bộ sang nguồn mới'),
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              _showMergeAllSourcesDialog(context, g);
                            },
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () {
                        // Straight to picking a destination for this exact
                        // group - unlike the normal mass-migration entry
                        // points, we already know which source is broken,
                        // so there's no reason to ask again.
                        final migrationGroups = buildMassMigrationSourceGroups(
                          itemType: g.itemType,
                        );
                        MassMigrationSourceGroup? migrationGroup;
                        for (final mg in migrationGroups) {
                          if (mg.sourceName.trim() == g.sourceName.trim() &&
                              mg.lang == g.lang) {
                            migrationGroup = mg;
                            break;
                          }
                        }
                        Navigator.pop(dialogContext);
                        if (migrationGroup == null || !context.mounted) {
                          return;
                        }
                        Navigator.push(
                          context,
                          createRoute(
                            page: MassMigrationPreviewScreen(
                              sourceGroup: migrationGroup,
                            ),
                          ),
                        );
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
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.ok),
          ),
        ],
      );
    },
  );
}

Future<void> _showMergeAllSourcesDialog(
  BuildContext context,
  LibrarySourceGroup group,
) async {
  final l10n = context.l10n;
  final installedSources = sourceRepository
      .getByItemType(group.itemType)
      .where((s) => s.isAdded == true)
      .toList();

  if (installedSources.isEmpty) {
    botToast(tr('Không có nguồn nào khác cùng thể loại để gộp sang. Vui lòng cài đặt nguồn mới trước.'));
    return;
  }

  await showDialog(
    context: context,
    builder: (pickerContext) {
      return AlertDialog(
        title: Text(tr('Gộp sang nguồn mới')),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('Chọn nguồn thay thế cho tất cả {p0} bộ trong "{p1}":', {
                  'p0': '${group.mangaCount}',
                  'p1': group.sourceName,
                }),
                style: TextStyle(fontSize: 13, color: pickerContext.secondaryColor),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: installedSources.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, idx) {
                    final target = installedSources[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(target.name ?? ''),
                      subtitle: Text('${target.lang ?? ""} • ${target.version ?? ""}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () async {
                        Navigator.pop(pickerContext);
                        final mangas = mangaForGroup(group, favoritesOnly: false);
                        for (final m in mangas) {
                          m.source = target.name;
                          m.lang = target.lang;
                          m.sourceId = target.id;
                          m.itemType = target.itemType;
                        }
                        await mangaRepository.putAll(mangas);
                        botToast(tr('Đã gộp thành công {p0} bộ từ "{p1}" sang "{p2}"', {
                          'p0': '${mangas.length}',
                          'p1': group.sourceName,
                          'p2': target.name ?? '',
                        }));
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
            onPressed: () => Navigator.pop(pickerContext),
            child: Text(l10n.cancel),
          ),
        ],
      );
    },
  );
}

Future<void> _deleteSource(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final groups = librarySourceGroups();
  if (groups.isEmpty) {
    botToast(l10n.delete_source_empty);
    return;
  }

  final group = await showDialog<LibrarySourceGroup>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.delete_source_pick_title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: groups.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final g = groups[index];
              return ListTile(
                title: Text(
                  g.lang != null ? "${g.sourceName} (${g.lang})" : g.sourceName,
                ),
                subtitle: Text(
                  "${_itemTypeLabel(context, g.itemType)} • ${g.mangaCount}",
                ),
                onTap: () => Navigator.pop(dialogContext, g),
              );
            },
          ),
        ),
        actions: dialogCancelOnlyAction(dialogContext),
      );
    },
  );
  if (group == null || !context.mounted) return;

  final mangaList = mangaForGroup(group);
  final counts = previewDeleteSource(mangaList);
  var removeExtension = group.sourceId != null;
  var keepHistory = false;
  var keepDownloads = false;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text(
              l10n.delete_source_confirm_title(
                "${group.sourceName} (${_itemTypeLabel(context, group.itemType)})",
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.delete_source_confirm_message(
                    counts.mangaCount,
                    counts.chapterCount,
                    counts.historyCount,
                    counts.updateCount,
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.delete_source_keep_history,
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: keepHistory,
                  onChanged: (value) =>
                      setState(() => keepHistory = value ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.delete_source_keep_downloads,
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: keepDownloads,
                  onChanged: (value) =>
                      setState(() => keepDownloads = value ?? false),
                ),
                if (group.sourceId != null)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.delete_source_also_remove_extension,
                      style: const TextStyle(fontSize: 13),
                    ),
                    value: removeExtension,
                    onChanged: (value) =>
                        setState(() => removeExtension = value ?? true),
                  ),
              ],
            ),
            actions: dialogCancelConfirmActions(
              dialogContext: dialogContext,
              confirmLabel: l10n.delete_source_button,
              confirmColor: Colors.red,
            ),
          );
        },
      );
    },
  );
  if (confirmed != true || !context.mounted) return;

  try {
    final safetyBackupPath = await createLibrarySafetyBackup();
    await writeLastLibrarySnapshot(
      LibrarySafetySnapshot(
        backupPath: safetyBackupPath,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        description: l10n.delete_source_result_message(
          counts.mangaCount,
          group.sourceName,
        ),
      ),
    );
    await deleteSourceLibrary(
      mangaList,
      group,
      keepHistory: keepHistory,
      keepDownloads: keepDownloads,
      alsoRemoveExtension: removeExtension,
    );
    if (!context.mounted) return;
    ref.invalidate(lastLibrarySnapshotProvider);
    botToast(
      l10n.delete_source_result_message(counts.mangaCount, group.sourceName),
    );
  } catch (e) {
    botToast("Error deleting source: $e");
  }
}

class _TaggedMangaCluster {
  _TaggedMangaCluster(this.group, this.cluster);

  final LibrarySourceGroup group;
  final DuplicateMangaCluster cluster;
}

Future<void> _mergeDuplicateManga(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final taggedClusters = <_TaggedMangaCluster>[];
  
  // 1. Quét theo từng nguồn riêng biệt
  for (final group in librarySourceGroups(favoritesOnly: true)) {
    final mangaList = mangaForGroup(group, favoritesOnly: true);
    for (final cluster in findDuplicateMangaClusters(mangaList)) {
      taggedClusters.add(_TaggedMangaCluster(group, cluster));
    }
  }

  // 2. Quét đa nguồn xuyên suốt thư viện (truyện tranh, anime, tiểu thuyết)
  final allFavorites = mangaRepository.getFavoritesNonLocalArchive();
  for (final itemType in ItemType.values) {
    final list = allFavorites.where((m) => m.itemType == itemType).toList();
    for (final cluster in findDuplicateMangaClusters(list)) {
      if (cluster.mangaList.length > 1) {
        final sources = cluster.mangaList.map((m) => m.source ?? '').toSet();
        if (sources.length > 1) {
          final groupName = 'Đa nguồn (${sources.join(", ")})';
          // Tránh trùng lặp cluster đã thêm ở bước 1
          final existingIds = taggedClusters.map((tc) => tc.cluster.mangaList.first.id).toSet();
          if (!existingIds.contains(cluster.mangaList.first.id)) {
            taggedClusters.add(_TaggedMangaCluster(
              LibrarySourceGroup(
                sourceId: null,
                sourceName: groupName,
                lang: null,
                itemType: itemType,
                mangaCount: cluster.mangaList.length,
              ),
              cluster,
            ));
          }
        }
      }
    }
  }

  if (taggedClusters.isEmpty) {
    botToast(l10n.merge_manga_none_found);
    return;
  }

  final picked = await showDialog<_TaggedMangaCluster>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.merge_manga_pick_title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: taggedClusters.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final t = taggedClusters[index];
              return ListTile(
                title: Text(t.cluster.mangaList.first.name ?? ''),
                subtitle: Text(
                  "${_itemTypeLabel(context, t.group.itemType)} • ${t.group.sourceName} • "
                  "${t.cluster.mangaList.length}",
                ),
                onTap: () => Navigator.pop(dialogContext, t),
              );
            },
          ),
        ),
        actions: dialogCancelOnlyAction(dialogContext),
      );
    },
  );
  if (picked == null || !context.mounted) return;

  final mangaList = [...picked.cluster.mangaList];
  final chapterCounts = <int, int>{
    for (final m in mangaList)
      m.id!: chapterRepository.countByMangaId(m.id),
  };
  mangaList.sort(
    (a, b) => (chapterCounts[b.id!] ?? 0).compareTo(chapterCounts[a.id!] ?? 0),
  );

  final primary = await showDialog<Manga>(
    context: context,
    builder: (dialogContext) {
      var selected = mangaList.first;
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text(l10n.merge_manga_choose_primary_title),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.merge_manga_choose_primary_message,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.secondaryColor,
                    ),
                  ),
                  ...mangaList.map(
                    (m) => RadioListTile<Manga>(
                      value: m,
                      // ignore: deprecated_member_use
                      groupValue: selected,
                      // ignore: deprecated_member_use
                      onChanged: (v) => setState(() => selected = v!),
                      title: Text(m.name ?? ''),
                      subtitle: Text(
                        l10n.merge_manga_chapters_subtitle(
                          chapterCounts[m.id!] ?? 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: dialogCancelConfirmActions(
              dialogContext: dialogContext,
              confirmLabel: l10n.merge_manga_button,
              onCancel: () => Navigator.pop(dialogContext, null),
              onConfirm: () => Navigator.pop(dialogContext, selected),
            ),
          );
        },
      );
    },
  );
  if (primary == null || !context.mounted) return;

  final others = mangaList.where((m) => m.id != primary.id).toList();
  final preview = previewMergeManga(primary, others);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.merge_preview_title),
        content: Text(
          l10n.merge_manga_preview_message(
            preview.totalChapters,
            preview.duplicateChapters,
            preview.keptChapters,
            preview.duplicateTracks,
          ),
        ),
        actions: dialogCancelConfirmActions(
          dialogContext: dialogContext,
          confirmLabel: l10n.merge_manga_button,
        ),
      );
    },
  );
  if (confirmed != true || !context.mounted) return;

  try {
    final safetyBackupPath = await createLibrarySafetyBackup();
    await writeLastLibrarySnapshot(
      LibrarySafetySnapshot(
        backupPath: safetyBackupPath,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        description: l10n.merge_manga_result_message(
          others.length,
          primary.name ?? '',
        ),
      ),
    );
    await mergeMangaGroup(primary, others);
    if (!context.mounted) return;
    ref.invalidate(lastLibrarySnapshotProvider);
    botToast(
      l10n.merge_manga_result_message(others.length, primary.name ?? ''),
    );
  } catch (e) {
    botToast("Error merging manga: $e");
  }
}

Future<void> _manualMergeManga(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final allFavorites = mangaRepository.getFavoritesNonLocalArchive();
  if (allFavorites.length < 2) {
    botToast(tr('Cần ít nhất 2 bộ trong thư viện để tiến hành hợp nhất.'));
    return;
  }

  final selectedMangas = await showDialog<List<Manga>>(
    context: context,
    builder: (dialogContext) {
      final selected = <Manga>{};
      var filterText = '';
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          final filtered = allFavorites
              .where((m) => filterText.isEmpty || (m.name?.toLowerCase().contains(filterText.toLowerCase()) ?? false))
              .toList();
          return AlertDialog(
            title: Text(tr('Chọn các bộ cần hợp nhất')),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: tr('Tìm kiếm theo tên...'),
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => filterText = v.trim()),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, idx) {
                        final m = filtered[idx];
                        final isChecked = selected.contains(m);
                        return CheckboxListTile(
                          value: isChecked,
                          title: Text(m.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${m.source ?? ""} • ${_itemTypeLabel(dialogContext, m.itemType)}'),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selected.add(m);
                              } else {
                                selected.remove(m);
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
                onPressed: () => Navigator.pop(dialogContext, null),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: selected.length >= 2 ? () => Navigator.pop(dialogContext, selected.toList()) : null,
                child: Text(tr('Tiếp tục ({p0})', {'p0': '${selected.length}'})),
              ),
            ],
          );
        },
      );
    },
  );

  if (selectedMangas == null || selectedMangas.length < 2 || !context.mounted) return;

  final mangaList = [...selectedMangas];
  final chapterCounts = <int, int>{
    for (final m in mangaList)
      m.id!: chapterRepository.countByMangaId(m.id),
  };
  mangaList.sort(
    (a, b) => (chapterCounts[b.id!] ?? 0).compareTo(chapterCounts[a.id!] ?? 0),
  );

  final primary = await showDialog<Manga>(
    context: context,
    builder: (dialogContext) {
      var chosen = mangaList.first;
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text(tr('Chọn bộ làm thông tin chính (Primary)')),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr('Các chương từ các bộ khác sẽ được hợp nhất vào bộ này và giữ nguyên nguồn gốc đọc:'),
                    style: TextStyle(fontSize: 12, color: dialogContext.secondaryColor),
                  ),
                  const SizedBox(height: 8),
                  ...mangaList.map(
                    (m) => RadioListTile<Manga>(
                      value: m,
                      groupValue: chosen,
                      onChanged: (v) => setState(() => chosen = v!),
                      title: Text(m.name ?? ''),
                      subtitle: Text(
                        '${m.source ?? ""} • ${chapterCounts[m.id!] ?? 0} chương/tập',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, null),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, chosen),
                child: Text(l10n.merge_manga_button),
              ),
            ],
          );
        },
      );
    },
  );

  if (primary == null || !context.mounted) return;

  final others = mangaList.where((m) => m.id != primary.id).toList();
  final preview = previewMergeManga(primary, others);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.merge_preview_title),
        content: Text(
          l10n.merge_manga_preview_message(
            preview.totalChapters,
            preview.duplicateChapters,
            preview.keptChapters,
            preview.duplicateTracks,
          ),
        ),
        actions: dialogCancelConfirmActions(
          dialogContext: dialogContext,
          confirmLabel: l10n.merge_manga_button,
        ),
      );
    },
  );
  if (confirmed != true || !context.mounted) return;

  try {
    final safetyBackupPath = await createLibrarySafetyBackup();
    await writeLastLibrarySnapshot(
      LibrarySafetySnapshot(
        backupPath: safetyBackupPath,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        description: l10n.merge_manga_result_message(
          others.length,
          primary.name ?? '',
        ),
      ),
    );
    await mergeMangaGroup(primary, others);
    if (!context.mounted) return;
    ref.invalidate(lastLibrarySnapshotProvider);
    botToast(
      l10n.merge_manga_result_message(others.length, primary.name ?? ''),
    );
  } catch (e) {
    botToast("Error merging manga: $e");
  }
}

Future<void> _customMergeSources(BuildContext context, WidgetRef ref) async {
  final groups = librarySourceGroups(favoritesOnly: false);
  if (groups.isEmpty) {
    botToast(tr('Không có tiện ích nào đang chứa dữ liệu trong thư viện.'));
    return;
  }

  final sourceGroup = await showDialog<LibrarySourceGroup>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(tr('Chọn tiện ích nguồn cần hợp nhất')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: groups.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, idx) {
              final g = groups[idx];
              return ListTile(
                title: Text(g.lang != null ? '${g.sourceName} (${g.lang})' : g.sourceName),
                subtitle: Text('${_itemTypeLabel(dialogContext, g.itemType)} • ${g.mangaCount} bộ'),
                onTap: () => Navigator.pop(dialogContext, g),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: Text(context.l10n.cancel),
          ),
        ],
      );
    },
  );

  if (sourceGroup == null || !context.mounted) return;
  await _showMergeAllSourcesDialog(context, sourceGroup);
}
