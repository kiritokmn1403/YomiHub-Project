import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/modules/manga/detail/widgets/chapter_filter_list_tile_widget.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/auto_backup.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/backup.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/providers/storage_provider.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:mangayomi/utils/platform_utils.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

class CreateBackup extends ConsumerStatefulWidget {
  const CreateBackup({super.key});

  @override
  ConsumerState<CreateBackup> createState() => _CreateBackupState();
}

class _CreateBackupState extends ConsumerState<CreateBackup> {
  late final List<(String, int)> _libraryList = _getLibraryList(context);
  late final List<(String, int)> _settingsList = _getSettingsList(context);
  late final List<(String, int)> _extensionList = _getExtensionsList(context);

  void _set(int index, List<int> indexList) {
    if (indexList.contains(index)) {
      ref
          .read(backupFrequencyOptionsStateProvider.notifier)
          .set(indexList.where((e) => e != index).toList());
    } else {
      ref.read(backupFrequencyOptionsStateProvider.notifier).set([
        ...indexList,
        index,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final indexList = ref.watch(backupFrequencyOptionsStateProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.create_backup)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.library,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: SuperListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 15),
                  shrinkWrap: true,
                  primary: false,
                  itemCount: _libraryList.length,
                  itemBuilder: (context, index) {
                    final (label, idx) = _libraryList[index];
                    return ListTileChapterFilter(
                      label: label,
                      type: indexList.contains(idx) ? 1 : 0,
                      onTap: () {
                        _set(idx, indexList);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.settings,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: SuperListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 15),
                  shrinkWrap: true,
                  primary: false,
                  itemCount: _settingsList.length,
                  itemBuilder: (context, index) {
                    final (label, idx) = _settingsList[index];
                    return ListTileChapterFilter(
                      label: label,
                      type: indexList.contains(idx) ? 1 : 0,
                      onTap: () {
                        _set(idx, indexList);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.extensions,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: SuperListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 15),
                  shrinkWrap: true,
                  primary: false,
                  itemCount: _extensionList.length,
                  itemBuilder: (context, index) {
                    final (label, idx) = _extensionList[index];
                    return ListTileChapterFilter(
                      label: label,
                      type: indexList.contains(idx) ? 1 : 0,
                      onTap: () {
                        _set(idx, indexList);
                      },
                    );
                  },
                ),
              ),
              // 0.5.9 (sheet YomiHub Update): choose the YomiHub-only items too –
              // Booru App = search history + favourites + settings
              // (Hive box `yomihub_booru`). Not on the TV build (no Booru).
              if (!kIsTvBuild) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Text('YomiHub', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: StatefulBuilder(
                      builder: (context, setLocal) {
                        final on = YomiPrefs.get<bool>('backupBooru', true);
                        return ListTileChapterFilter(
                          label: tr('Booru App (lịch sử tìm kiếm, yêu thích, cài đặt)'),
                          type: on ? 1 : 0,
                          onTap: () async {
                            await YomiPrefs.set('backupBooru', !on);
                            setLocal(() {});
                          },
                        );
                      },
                    ),
                  ),
                ),
                // 0.6.3: Tủ Sách Cá Nhân (Hive box `yomihub_bookshelf`)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: StatefulBuilder(
                      builder: (context, setLocal) {
                        final on = YomiPrefs.get<bool>('backupBookshelf', true);
                        return ListTileChapterFilter(
                          label: tr('Tủ Sách Cá Nhân (bộ truyện, tập đã mua, cần mua, lịch sử quét)'),
                          type: on ? 1 : 0,
                          onTap: () async {
                            await YomiPrefs.set('backupBookshelf', !on);
                            setLocal(() {});
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: context.primaryColor, height: 0.3),
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                        ),
                        onPressed: () async {
                          String? result;
                          if (Platform.isIOS) {
                            result =
                                (await StorageProvider()
                                        .getIosBackupDirectory())!
                                    .path;
                          } else {
                            result = await FilePicker.getDirectoryPath(
                              linuxOptions: const LinuxOptions(
                                lockParentWindow: true,
                              ),
                            );
                          }
                          if (result != null && context.mounted) {
                            ref.read(
                              doBackUpProvider(
                                list: indexList,
                                path: result,
                                context: context,
                              ),
                            );
                          }
                        },
                        child: Text(
                          l10n.create,
                          style: TextStyle(
                            color: context.dynamicBlackWhiteColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<(String, int)> _getLibraryList(BuildContext context) {
  final l10n = context.l10n;
  return [
    (l10n.library_entries, 0),
    (l10n.categories, 1),
    (l10n.chapters_and_episode, 2),
    (l10n.tracking, 3),
    (l10n.history, 4),
    (l10n.updates, 5),
  ];
}

List<(String, int)> _getSettingsList(BuildContext context) {
  final l10n = context.l10n;
  return [
    (l10n.app_settings, 6),
    (l10n.custom_buttons, 10),
    (l10n.sources_settings, 7),
    (l10n.include_sensitive_settings, 8),
  ];
}

List<(String, int)> _getExtensionsList(BuildContext context) {
  final l10n = context.l10n;
  return [(l10n.extensions, 9)];
}
