import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:mangayomi/yomihub/savior/savior_screen.dart';
import 'package:mangayomi/yomihub/library/foreign_downloads.dart';
import 'package:mangayomi/yomihub/library/local_folders.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/l10n/generated/app_localizations.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/modules/library/providers/file_scanner.dart';
import 'package:mangayomi/modules/more/settings/downloads/providers/downloads_state_provider.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:mangayomi/utils/local_directory_access.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:mangayomi/utils/platform_utils.dart';
import 'package:path/path.dart' as p;

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  @override
  Widget build(BuildContext context) {
    final saveAsCBZArchiveState = ref.watch(saveAsCBZArchiveStateProvider);
    final deleteDownloadAfterReading = ref.watch(
      deleteDownloadAfterReadingStateProvider,
    );
    final onlyOnWifiState = ref.watch(onlyOnWifiStateProvider);
    final concurrentDownloads = ref.watch(concurrentDownloadsStateProvider);
    final allowConcurrentDownloads = ref.watch(
      allowConcurrentDownloadsStateProvider,
    );
    final downloadDelaySeconds = ref.watch(downloadDelaySecondsStateProvider);
    final localFolders = ref.watch(localFoldersStateProvider);
    final downloadLocation = ref.watch(downloadLocationStateProvider);
    final l10n = l10nLocalizations(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n!.downloads)),
      body: SingleChildScrollView(
        padding: tvPageInsets,
        child: Column(
          children: [
            SwitchListTile(
              value: onlyOnWifiState,
              title: Text(l10n.only_on_wifi),
              onChanged: (value) {
                ref.read(onlyOnWifiStateProvider.notifier).set(value);
              },
            ),
            SwitchListTile(
              value: saveAsCBZArchiveState,
              title: Text(l10n.save_as_cbz_archive),
              onChanged: (value) {
                ref.read(saveAsCBZArchiveStateProvider.notifier).set(value);
              },
            ),
            SwitchListTile(
              value: deleteDownloadAfterReading,
              title: Text(l10n.delete_download_after_reading),
              onChanged: (value) {
                ref
                    .read(deleteDownloadAfterReadingStateProvider.notifier)
                    .set(value);
              },
            ),
            SwitchListTile(
              value: allowConcurrentDownloads,
              title: Text(l10n.allow_concurrent_downloads),
              subtitle: Text(l10n.allow_concurrent_downloads_subtitle),
              onChanged: (value) {
                ref
                    .read(allowConcurrentDownloadsStateProvider.notifier)
                    .set(value);
              },
            ),
            if (allowConcurrentDownloads)
              ListTile(
                onTap: () {
                  int currentIntValue = concurrentDownloads;
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(context.l10n.concurrent_downloads),
                        content: StatefulBuilder(
                          builder: (context, setState) => SizedBox(
                            height: 200,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                NumberPicker(
                                  value: currentIntValue,
                                  minValue: 1,
                                  maxValue: 255,
                                  step: 1,
                                  haptics: true,
                                  textMapper: (numberText) => numberText,
                                  onChanged: (value) =>
                                      setState(() => currentIntValue = value),
                                ),
                              ],
                            ),
                          ),
                        ),
                        actions: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  context.l10n.cancel,
                                  style: TextStyle(color: context.primaryColor),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  ref
                                      .read(
                                        concurrentDownloadsStateProvider
                                            .notifier,
                                      )
                                      .set(currentIntValue);
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  context.l10n.ok,
                                  style: TextStyle(color: context.primaryColor),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
                title: Text(context.l10n.concurrent_downloads),
                subtitle: Text(
                  "$concurrentDownloads",
                  style: TextStyle(fontSize: 11, color: context.secondaryColor),
                ),
              ),
            ListTile(
              onTap: () {
                int currentDelay = downloadDelaySeconds;
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(context.l10n.download_delay),
                      content: StatefulBuilder(
                        builder: (context, setState) => SizedBox(
                          height: 200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              NumberPicker(
                                value: currentDelay,
                                minValue: 0,
                                maxValue: 120,
                                step: 1,
                                haptics: true,
                                textMapper: (numberText) => numberText,
                                onChanged: (value) =>
                                    setState(() => currentDelay = value),
                              ),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                context.l10n.cancel,
                                style: TextStyle(color: context.primaryColor),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(
                                      downloadDelaySecondsStateProvider
                                          .notifier,
                                    )
                                    .set(currentDelay);
                                Navigator.pop(context);
                              },
                              child: Text(
                                context.l10n.ok,
                                style: TextStyle(color: context.primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
              title: Text(context.l10n.download_delay),
              subtitle: Text(
                downloadDelaySeconds == 0
                    ? l10n.download_delay_subtitle
                    : "$downloadDelaySeconds s (+ jitter)",
                style: TextStyle(fontSize: 11, color: context.secondaryColor),
              ),
            ),
            ListTile(
              onTap: () async {
                final result =
                    await LocalDirectoryAccess.pickDirectory() ??
                    await FilePicker.getDirectoryPath(
                      linuxOptions: const LinuxOptions(lockParentWindow: true),
                    );
                if (result != null) {
                  ref.read(downloadLocationStateProvider.notifier).set(result);
                }
              },
              title: Text(l10n.download_location),
              subtitle: Text(
                downloadLocation.$2.isEmpty
                    ? downloadLocation.$1
                    : downloadLocation.$2,
                style: TextStyle(fontSize: 11, color: context.secondaryColor),
              ),
            ),
            ListTile(
              onTap: () async {
                final result =
                    await LocalDirectoryAccess.pickDirectory() ??
                    await FilePicker.getDirectoryPath(
                      linuxOptions: const LinuxOptions(lockParentWindow: true),
                    );
                if (result != null) {
                  if (!context.mounted) return;
                  await _addLocalFolder(context, localFolders, result);
                }
              },
              leading: const Icon(Icons.create_new_folder_outlined),
              title: Text(context.l10n.add_local_folder),
              subtitle: Text(
                'Thêm được nhiều thư mục; nhận cả thư mục local / localanime của Aniyomi, Nekoyomi, Mihon và tệp .cbz của Kotatsu',
                style: TextStyle(fontSize: 11, color: context.secondaryColor),
              ),
            ),
            ListTile(
              onTap: () => _rescan(),
              leading: const Icon(Icons.refresh),
              title: Text(context.l10n.rescan_local_folder),
              subtitle: _scanning
                  ? const LinearProgressIndicator()
                  : Text(
                      'Quét mọi thư mục cục bộ (${localFolders.length + 1})',
                      style: TextStyle(fontSize: 11, color: context.secondaryColor),
                    ),
            ),
            // YomiHub 0.1.5
            ListTile(
              leading: const Icon(Icons.drive_folder_upload_outlined),
              title: const Text('Chương / tập đã tải từ app khác'),
              subtitle: const Text('Mangayomi, Mihon/Tachiyomi, Aniyomi, Nekoyomi, Komikku, Kotatsu, LNReader'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ForeignDownloadsScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.download_for_offline_outlined),
              title: const Text('Savior'),
              subtitle: const Text('Tải video / nhạc / tệp từ trang web trong Trình duyệt (HLS m3u8, MP4…)'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SaviorScreen()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Text(
                          context.l10n.local_folder,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        IconButton.outlined(
                          tooltip: context.l10n.local_folder_structure,
                          onPressed: () => _showHelpDialog(context),
                          icon: const Icon(Icons.question_mark),
                        ),
                      ],
                    ),
                  ),
                  FutureBuilder<LocalFolder?>(
                    future: getDefaultLocalFolder(),
                    builder: (context, snapshot) => Column(
                      children: [
                        if (snapshot.data?.path != null)
                          _buildLocalFolder(
                            l10n,
                            localFolders,
                            snapshot.data!,
                            isDefault: true,
                          ),
                        ...localFolders.map(
                          (e) => _buildLocalFolder(l10n, localFolders, e),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _scanning = false;

  Future<void> _rescan([LocalFolder? only]) async {
    if (_scanning) return;
    setState(() => _scanning = true);
    try {
      if (only == null) {
        await ref.read(scanLocalLibraryProvider.future);
      } else {
        await ref.read(_scanFolderProvider(only).future);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(only == null ? 'Đã quét xong các thư mục cục bộ' : 'Đã quét xong “${only.name}”')),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  /// YomiHub 0.1.7: validates, offers Aniyomi/Mihon local sub-folders, names
  /// the new folder and scans it right away.
  Future<void> _addLocalFolder(
    BuildContext context,
    List<LocalFolder> localFolders,
    String picked,
  ) async {
    var paths = [picked];
    final subs = await YomiLocalFolders.localSubfolders(picked);
    if (subs.isNotEmpty && context.mounted) {
      final useSubs = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Thư mục của Aniyomi / Mihon / Nekoyomi?'),
          content: Text(
            'Thư mục này có ${subs.map(p.basename).join(', ')}. '
            'Thêm các thư mục con này (mỗi thư mục là một nguồn cục bộ) thay cho thư mục gốc?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Giữ thư mục gốc')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Thêm thư mục con')),
          ],
        ),
      );
      if (useSubs == true) paths = subs;
    }
    final def = await getDefaultLocalFolder();
    final temp = localFolders.toList();
    final added = <LocalFolder>[];
    for (final path in paths) {
      final err = YomiLocalFolders.validateNew(path, temp, defaultFolder: def);
      if (err != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.basename(path)}: $err')));
        }
        continue;
      }
      var name = LocalFolder.fromPath(path: path).name ?? p.basename(path);
      if (path != picked) name = '${p.basename(picked)} ${p.basename(path)}';
      if (paths.length > 1) {
        name = '${p.basename(picked)} ${p.basename(path)}';
      } else {
        if (!context.mounted) return;
        final n = await _showLocalFolderNameDialog(context, name);
        if (n == null || n.trim().isEmpty) return;
        name = n.trim();
      }
      final f = LocalFolder(name: name, path: path);
      temp.add(f);
      added.add(f);
    }
    if (added.isEmpty) return;
    ref.read(localFoldersStateProvider.notifier).set(temp);
    // names may have been made unique by the provider
    final saved = ref.read(localFoldersStateProvider);
    for (final a in added) {
      final f = saved.where((e) => e.path == a.path).firstOrNull;
      if (f != null) await _rescan(f);
    }
  }

  Future<void> _folderAction(String action, LocalFolder folder, bool isDefault) async {
    final l10n = context.l10n;
    switch (action) {
      case 'scan':
        await _rescan(folder);
      case 'open':
        await YomiLocalFolders.reveal(folder.path ?? '');
      case 'rename':
        final n = await _showLocalFolderNameDialog(context, folder.name ?? '');
        if (n == null) return;
        final err = await YomiLocalFolders.rename(ref, folder, n);
        if (mounted && err != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        }
      case 'download':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Lưu tải xuống mới vào thư mục này?'),
            content: Text(
              'Chương / tập tải về sau này sẽ nằm trong:\n${folder.path}\n\n'
              'Các chương đã tải trước đó vẫn ở vị trí cũ (đổi lại được trong “${l10n.download_location}”).',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.ok)),
            ],
          ),
        );
        if (ok == true && folder.path != null) {
          ref.read(downloadLocationStateProvider.notifier).set(folder.path!);
          ref.read(downloadLocalFolderNameStateProvider.notifier).set(folder.name);
        }
      case 'remove':
        final counts = await YomiLocalFolders.countTitles(folder.name ?? '');
        final total = counts.values.fold<int>(0, (a, b) => a + b);
        if (!mounted) return;
        var purge = false;
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, set) => AlertDialog(
              title: Text('Gỡ “${folder.name}”?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${folder.path}\n\nTệp trên máy không bị xoá.'),
                  if (total > 0)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: purge,
                      onChanged: (v) => set(() => purge = v ?? false),
                      title: Text('Bỏ luôn $total mục của thư mục này khỏi thư viện'),
                    ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.delete)),
              ],
            ),
          ),
        );
        if (ok == true) {
          final n = await YomiLocalFolders.remove(ref, folder, purge: purge);
          if (mounted && n > 0) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã bỏ $n mục khỏi thư viện')));
          }
        }
    }
  }

  Future<String?> _showLocalFolderNameDialog(
    BuildContext context,
    String initialName,
  ) async {
    final controller = TextEditingController(text: initialName);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.name),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: context.l10n.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final data = (
      "LocalFolder",
      [
        (
          "MangaName",
          [
            ("cover.jpg", Icons.image_outlined),
            (
              "Chapter1",
              [
                ("Page1.jpg", Icons.image_outlined),
                ("Page2.jpeg", Icons.image_outlined),
                ("Page3.png", Icons.image_outlined),
                ("Page4.webp", Icons.image_outlined),
              ],
            ),
            ("Chapter2.cbz", Icons.folder_zip_outlined),
            ("Chapter3.zip", Icons.folder_zip_outlined),
            ("Chapter4.cbt", Icons.folder_zip_outlined),
            ("Chapter5.tar", Icons.folder_zip_outlined),
          ],
        ),
        (
          "AnimeName",
          [
            ("cover.jpg", Icons.image_outlined),
            ("Episode1.mp4", Icons.video_file_outlined),
            (
              "Episode1_subtitles",
              [
                ("en.srt", Icons.subtitles_outlined),
                ("de.srt", Icons.subtitles_outlined),
              ],
            ),
            ("Episode2.mov", Icons.video_file_outlined),
            ("Episode3.avi", Icons.video_file_outlined),
            ("Episode4.flv", Icons.video_file_outlined),
            ("Episode5.wmv", Icons.video_file_outlined),
            ("Episode6.mpeg", Icons.video_file_outlined),
            ("Episode7.mkv", Icons.video_file_outlined),
          ],
        ),
        (
          "NovelName",
          [
            ("cover.jpg", Icons.image_outlined),
            ("NovelName.epub", Icons.book_outlined),
          ],
        ),
      ],
    );

    Widget buildSubFolder((String, dynamic) data, int level) {
      if (data.$2 is List) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  for (int i = 1; i < level; i++)
                    const WidgetSpan(child: SizedBox(width: 20)),
                  if (level > 0)
                    WidgetSpan(child: Icon(Icons.subdirectory_arrow_right)),
                  WidgetSpan(child: Icon(Icons.folder)),
                  const WidgetSpan(child: SizedBox(width: 5)),
                  TextSpan(text: data.$1),
                ],
              ),
            ),
            ...(data.$2 as List<(String, dynamic)>).map(
              (e) => buildSubFolder(e, level + 1),
            ),
          ],
        );
      }
      return Text.rich(
        TextSpan(
          children: [
            for (int i = 1; i < level; i++)
              const WidgetSpan(child: SizedBox(width: 20)),
            if (level > 0)
              WidgetSpan(child: Icon(Icons.subdirectory_arrow_right)),
            WidgetSpan(child: Icon(data.$2 as IconData)),
            const WidgetSpan(child: SizedBox(width: 5)),
            TextSpan(text: data.$1),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(context.l10n.local_folder_structure),
              content: SizedBox(
                width: context.width(0.6),
                height: context.height(0.8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(child: buildSubFolder(data, 0)),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(context.l10n.cancel),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLocalFolder(
    AppLocalizations l10n,
    List<LocalFolder> localFolders,
    LocalFolder folder, {
    bool isDefault = false,
  }) {
    final folderName = folder.name ?? "";
    final folderPath = folder.path ?? "";
    return Card(
      key: Key('folder_${folderName}_${folderPath.hashCode}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.12),
              child: Icon(
                isDefault ? Icons.home_outlined : Icons.folder_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          folderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isDefault)
                        _buildFolderLabel(l10n.default0)
                      else
                        _buildFolderLabel(l10n.custom),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    folderPath,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.secondaryColor,
                    ),
                  ),
                  _FolderInfo(folder: folder),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'Tuỳ chọn',
              onSelected: (v) => _folderAction(v, folder, isDefault),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'scan', child: ListTile(leading: Icon(Icons.refresh), title: Text('Quét lại thư mục này'))),
                if (!Platform.isAndroid && !Platform.isIOS)
                  const PopupMenuItem(value: 'open', child: ListTile(leading: Icon(Icons.folder_open), title: Text('Mở thư mục'))),
                if (!isDefault) ...[
                  const PopupMenuItem(value: 'rename', child: ListTile(leading: Icon(Icons.drive_file_rename_outline), title: Text('Đổi tên'))),
                  const PopupMenuItem(value: 'download', child: ListTile(leading: Icon(Icons.download_outlined), title: Text('Lưu tải xuống mới vào đây'))),
                  PopupMenuItem(value: 'remove', child: ListTile(leading: const Icon(Icons.delete_outline), title: Text(l10n.delete))),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderLabel(String label) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 58, maxWidth: 82),
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}


final _scanFolderProvider = FutureProvider.autoDispose.family<void, LocalFolder>(
  (ref, folder) => scanLocalFolder(ref, folder),
);

/// Free space + number of titles for one local folder (YomiHub 0.1.7).
class _FolderInfo extends StatelessWidget {
  final LocalFolder folder;
  const _FolderInfo({required this.folder});

  Future<(Object?, Map<ItemType, int>)> _load() async {
    final space = await YomiLocalFolders.diskSpace(folder.path ?? '');
    final counts = await YomiLocalFolders.countTitles(folder.name ?? '');
    return (space, counts);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(Object?, Map<ItemType, int>)>(
      key: ValueKey('${folder.name}|${folder.path}'),
      future: _load(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox(height: 4);
        final (spaceObj, counts) = snap.data!;
        final space = spaceObj as (int, int)?;
        final parts = <String>[
          if ((counts[ItemType.manga] ?? 0) > 0) '${counts[ItemType.manga]} Comic',
          if ((counts[ItemType.anime] ?? 0) > 0) '${counts[ItemType.anime]} Film & Movie',
          if ((counts[ItemType.novel] ?? 0) > 0) '${counts[ItemType.novel]} Novel',
        ];
        final style = TextStyle(fontSize: 11, color: context.secondaryColor);
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(parts.isEmpty ? 'Chưa có mục nào trong thư viện' : parts.join(' • '), style: style),
              if (space != null && space.$2 > 0) ...[
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 1 - space.$1 / space.$2,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Còn trống ${YomiLocalFolders.formatBytes(space.$1)} / ${YomiLocalFolders.formatBytes(space.$2)}',
                  style: style,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
