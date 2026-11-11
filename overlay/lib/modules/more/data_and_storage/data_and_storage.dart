import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/yomihub/library/download_index.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:bot_toast/bot_toast.dart';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/auto_backup.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/backup_compression.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/backup_encryption.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/storage_usage.dart';
import 'package:mangayomi/modules/more/data_and_storage/widgets/backup_encryption_password_dialog.dart';
import 'package:mangayomi/modules/more/data_and_storage/widgets/rollback_last_change_tile.dart';
import 'package:mangayomi/modules/more/data_and_storage/widgets/source_management_tiles.dart';
import 'package:mangayomi/modules/more/data_and_storage/widgets/unified_restore.dart';
import 'package:mangayomi/modules/more/settings/downloads/providers/downloads_state_provider.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/services/backup_password_storage.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:mangayomi/modules/widgets/tv_escapable_slider.dart';
import 'package:mangayomi/utils/platform_utils.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class DataAndStorage extends ConsumerWidget {
  /// 0.5.3 (sheet "YomiHub Update" mục 4): true = the "Sao Lưu & Đồng Bộ"
  /// screen (create / restore, frequency, compression, location, encryption,
  /// cloud backup, sync, Booru App backup) – opened from Settings and More.
  /// false = "Dữ liệu và bộ nhớ" without the backup settings.
  final bool backupSync;
  const DataAndStorage({super.key, this.backupSync = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupFrequency = ref.watch(backupFrequencyStateProvider);
    final autoBackupLocation = ref.watch(autoBackupLocationStateProvider);
    final downloadLocationState = ref.watch(downloadLocationStateProvider);
    final totalChapterCacheSize = ref.watch(totalChapterCacheSizeStateProvider);
    final clearChapterCacheOnAppLaunch = ref.watch(
      clearChapterCacheOnAppLaunchStateProvider,
    );
    final l10n = l10nLocalizations(context)!;
    final compression = ref.watch(backupCompressionLevelProvider);
    final backupEncryptionEnabled = ref.watch(backupEncryptionEnabledProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(backupSync ? tr('Sao Lưu & Đồng Bộ') : l10n.data_and_storage),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (!backupSync) ...[
            // YomiHub 0.1.8: download index (on by default, only the user
            // can turn it off)
            ValueListenableBuilder<int>(
              valueListenable: YomiPrefs.changes,
              builder: (context, _, child) => Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.manage_search),
                    title: Text(tr('Lập chỉ mục tải xuống')),
                    subtitle: Text(tr('Đối chiếu thư mục tải xuống với thư viện khi mở ứng dụng (6 giờ/lần) và quét các thư mục cục bộ: chương/tập có sẵn trên máy hiện là đã tải, tệp bị xoá ngoài ứng dụng được gỡ khỏi danh sách tải xuống.')),
                    value: YomiPrefs.downloadIndexing,
                    onChanged: (value) => YomiPrefs.set('downloadIndexing', value),
                  ),
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: Text(tr('Lập chỉ mục ngay')),
                    subtitle: Text(
                      YomiDownloadIndex.lastRun == 0
                          ? tr('Chưa lập chỉ mục')
                          : tr('Lần cuối: {t} • {n} mục trên máy', {
                              't': DateTime.fromMillisecondsSinceEpoch(YomiDownloadIndex.lastRun).toString().substring(0, 16),
                              'n': YomiDownloadIndex.lastFiles,
                            }),
                    ),
                    onTap: () async {
                      BotToast.showText(text: tr('Đang lập chỉ mục tải xuống…'));
                      final r = await YomiDownloadIndex.run();
                      BotToast.showText(
                        text: r == null
                            ? tr('Không lập chỉ mục được (xem Nhật ký ứng dụng)')
                            : tr('Xong: {n} mục trên máy, thêm {a}, gỡ {r} ({s} giây)', {
                                'n': r.files,
                                'a': r.added,
                                'r': r.removed,
                                's': (r.took.inMilliseconds / 1000).toStringAsFixed(1),
                              }),
                      );
                    },
                  ),
                ],
              ),
            ),
            ListTile(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(l10n.download_location),
                      content: SizedBox(
                        width: context.width(0.8),
                        child: RadioGroup(
                          groupValue: downloadLocationState.$2.isEmpty
                              ? downloadLocationState.$1
                              : downloadLocationState.$2,
                          onChanged: (value) async {
                            if (value == downloadLocationState.$1) {
                              ref
                                  .read(downloadLocationStateProvider.notifier)
                                  .set("");
                              Navigator.pop(context);
                            } else {
                              String? result =
                                  await FilePicker.getDirectoryPath(
                                    linuxOptions: const LinuxOptions(
                                      lockParentWindow: true,
                                    ),
                                  );

                              if (result != null) {
                                ref
                                    .read(
                                      downloadLocationStateProvider.notifier,
                                    )
                                    .set(result);
                              } else {}
                              if (!context.mounted) return;
                              Navigator.pop(context);
                            }
                          },
                          child: SuperListView(
                            shrinkWrap: true,
                            children: [
                              RadioListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.all(0),
                                value: downloadLocationState.$1,
                                title: Text(downloadLocationState.$1),
                              ),
                              RadioListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.all(0),
                                value: downloadLocationState.$2,
                                title: Text(l10n.custom_location),
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
                                l10n.cancel,
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
              title: Text(l10n.download_location),
              subtitle: Builder(
                builder: (context) {
                  final loc = downloadLocationState.$2.isEmpty
                      ? downloadLocationState.$1
                      : downloadLocationState.$2;
                  // 0.5.2: a custom folder on a removed/replaced SD card
                  // (Note 9: /storage/7563-670C gone, card now 0000-0000)
                  // silently broke downloads - say so under the path.
                  final missing = downloadLocationState.$2.isNotEmpty &&
                      !Directory(downloadLocationState.$2).existsSync();
                  return Text(
                    missing
                        ? '$loc\n${tr('Thư mục này không còn tồn tại (thẻ nhớ đã tháo hoặc đổi?) – chọn lại vị trí tải xuống.')}'
                        : loc,
                    style: TextStyle(
                      fontSize: 11,
                      color: missing ? Colors.red : context.secondaryColor,
                    ),
                  );
                },
              ),
            ),
            // 0.5.2: icon and note on one line (the icon alone looked like a
            // row whose title was missing, e.g. on a DeX/tablet screen).
            ListTile(
              dense: true,
              leading: Icon(
                Icons.info_outline_rounded,
                color: context.secondaryColor,
              ),
              title: Text(
                l10n.download_location_info,
                style: TextStyle(fontSize: 11, color: context.secondaryColor),
              ),
            ),
            // 0.5.3: library tools stay here; backup settings moved
            const MissingSourceCheckTile(),
            const DeleteSourceTile(),
            const MergeDuplicateMangaTile(),
            const ManualMergeMangaTile(),
            const CustomMergeSourcesTile(),
            ListTile(
              leading: const Icon(Icons.settings_backup_restore),
              title: Text(tr('Sao Lưu & Đồng Bộ')),
              subtitle: Text(tr('Tạo / khôi phục sao lưu, tần suất, mức nén, vị trí, sao lưu đám mây, đồng bộ, Booru App')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/backupSync'),
            ),
            ],
            if (backupSync) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Row(
                children: [
                  Text(
                    l10n.backup_and_restore,
                    style: TextStyle(fontSize: 13, color: context.primaryColor),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton(
                      emptySelectionAllowed: true,
                      showSelectedIcon: false,
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      segments: [
                        ButtonSegment(
                          value: 'create',
                          label: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(l10n.create_backup),
                          ),
                        ),
                        ButtonSegment(
                          value: 'restore',
                          label: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(l10n.restore_backup),
                          ),
                        ),
                      ],
                      selected: {},
                      onSelectionChanged: (newSelection) {
                        if (newSelection.contains('create')) {
                          context.push('/createBackup');
                        } else if (newSelection.contains('restore')) {
                          performRestore(context, ref);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const RollbackLastChangeTile(),
            ListTile(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    final list = _getBackupFrequencyList(context);
                    return AlertDialog(
                      title: Text(l10n.backup_frequency),
                      content: SizedBox(
                        width: context.width(0.8),
                        child: RadioGroup(
                          groupValue: backupFrequency,
                          onChanged: (value) {
                            ref
                                .read(backupFrequencyStateProvider.notifier)
                                .set(value!);
                            Navigator.pop(context);
                          },
                          child: SuperListView.builder(
                            shrinkWrap: true,
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              return RadioListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.all(0),
                                value: index,
                                title: Row(children: [Text(list[index])]),
                              );
                            },
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
                                l10n.cancel,
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
              title: Text(l10n.backup_frequency),
              subtitle: Text(
                _getBackupFrequencyList(context)[backupFrequency],
                style: TextStyle(fontSize: 11, color: context.secondaryColor),
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: YomiPrefs.changes,
              builder: (context, _, _) {
                final maxCount = YomiPrefs.get<int>('backupMaxCount', 0);
                return ListTile(
                  title: Text(tr('Số lượng bản sao lưu')),
                  subtitle: Text(
                    maxCount <= 0
                        ? tr('Không giới hạn')
                        : tr('{p0} bản gần nhất (tự động dọn dẹp các bản cũ hơn)', {'p0': '$maxCount'}),
                    style: TextStyle(fontSize: 11, color: context.secondaryColor),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        const options = [1, 2, 3, 5, 10, 20, 0];
                        return AlertDialog(
                          title: Text(tr('Số lượng bản sao lưu')),
                          content: SizedBox(
                            width: context.width(0.8),
                            child: RadioGroup<int>(
                              groupValue: maxCount,
                              onChanged: (value) async {
                                if (value != null) {
                                  final locations = ref.read(autoBackupLocationStateProvider);
                                  final dir = automaticBackupDirectory(
                                    locations.$2.isEmpty ? locations.$1 : locations.$2,
                                  );
                                  await YomiPrefs.set('backupMaxCount', value);
                                  if (dir != null) await pruneOldBackups(dir.path, maxRetentionCount: value);
                                }
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: SuperListView.builder(
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final val = options[index];
                                  final label = val <= 0
                                      ? tr('Không giới hạn')
                                      : tr('{p0} bản gần nhất', {'p0': '$val'});
                                  return RadioListTile<int>(
                                    dense: true,
                                    contentPadding: const EdgeInsets.all(0),
                                    value: val,
                                    title: Text(label),
                                  );
                                },
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(l10n.cancel, style: TextStyle(color: context.primaryColor)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
            SwitchListTile(
              title: Text(l10n.encrypt_backups),
              subtitle: Text(
                l10n.encrypt_backups_info,
                style: TextStyle(fontSize: 11),
              ),
              value: backupEncryptionEnabled,
              onChanged: (value) async {
                if (!value) {
                  await ref
                      .read(backupEncryptionEnabledProvider.notifier)
                      .set(false);
                  await BackupPasswordStorage.clear();
                  return;
                }
                final saved = await showBackupEncryptionPasswordDialog(context);
                if (saved == true) {
                  await ref
                      .read(backupEncryptionEnabledProvider.notifier)
                      .set(true);
                }
              },
            ),
            ListTile(
              title: Text(l10n.compression_level),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.compression_info(DeflateLevel.defaultCompression),
                    style: TextStyle(
                      fontSize: 11,
                      color: context.secondaryColor,
                    ),
                  ),
                  TvEscapableSlider(
                    enabled: isTv,
                    onDecrease: () => ref
                        .read(backupCompressionLevelProvider.notifier)
                        .set((compression - 1).clamp(0, 9)),
                    onIncrease: () => ref
                        .read(backupCompressionLevelProvider.notifier)
                        .set((compression + 1).clamp(0, 9)),
                    child: Slider(
                      min: 0,
                      max: 9,
                      divisions: 9,
                      value: compression.toDouble(),
                      label: compression.toString(),
                      onChanged: (value) {
                        ref
                            .read(backupCompressionLevelProvider.notifier)
                            .update(value.round());
                      },
                      onChangeEnd: (value) {
                        ref
                            .read(backupCompressionLevelProvider.notifier)
                            .set(value.round());
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (!Platform.isIOS)
              ListTile(
                onTap: () async {
                  String? result = await FilePicker.getDirectoryPath(
                    linuxOptions: const LinuxOptions(lockParentWindow: true),
                  );

                  if (result != null) {
                    ref
                        .read(autoBackupLocationStateProvider.notifier)
                        .set(result);
                  }
                },
                title: Text(l10n.backup_location),
                // 0.5.3 (Note 9 test): the backup folder on the removed SD
                // card was shown as if it still worked; auto-backup now falls
                // back to the default folder and the path is shown in red.
                subtitle: Builder(
                  builder: (context) {
                    final missing = autoBackupLocation.$2.isNotEmpty &&
                        !Directory(autoBackupLocation.$2).existsSync();
                    return Text(
                      '${autoBackupLocation.$2.isEmpty ? autoBackupLocation.$1 : autoBackupLocation.$2}'
                      '${missing ? '\n${tr('Thư mục này không còn tồn tại – bản tự sao lưu được lưu vào thư mục mặc định. Chọn lại vị trí sao lưu.')}' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: missing ? Colors.red : context.secondaryColor,
                      ),
                    );
                  },
                ),
              ),
            ListTile(
              title: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: context.secondaryColor,
                    ),
                  ],
                ),
              ),
              subtitle: Text(
                l10n.backup_and_restore_warning_info,
                style: TextStyle(fontSize: 11, color: context.secondaryColor),
              ),
            ),
            // YomiHub: cloud targets + "send to other apps"
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: Text(tr('Sao lưu đám mây')),
              subtitle: Text(
                tr('Google Drive, OneDrive, Dropbox, WebDAV, Rclone, MediaFire, Telegram, gửi sang ứng dụng khác'),
              ),
              onTap: () => context.push('/cloudBackup'),
            ),
            // 0.5.3: sync + Booru App backup in the same place
            ListTile(
              leading: const Icon(Icons.cloud_sync_outlined),
              title: Text(l10n.syncing),
              subtitle: Text(tr('Đồng bộ thư viện, tiến độ đọc/xem giữa các thiết bị qua máy chủ đồng bộ')),
              onTap: () => context.push('/sync'),
            ),
            if (!(isTv || kIsTvBuild))
              ValueListenableBuilder<int>(
                valueListenable: YomiPrefs.changes,
                builder: (context, _, _) => SwitchListTile(
                  secondary: const Icon(Icons.photo_library_outlined),
                  title: Text(tr('Sao lưu dữ liệu Booru App')),
                  subtitle: Text(tr('Yêu thích, lịch sử tìm kiếm, trang và cài đặt Booru App đi kèm bản sao lưu và sao lưu đám mây')),
                  value: YomiPrefs.get<bool>('backupBooru', true),
                  onChanged: (v) => YomiPrefs.set('backupBooru', v),
                ),
              ),
            ],
            if (!backupSync) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Row(
                children: [
                  Text(
                    l10n.storage,
                    style: TextStyle(fontSize: 13, color: context.primaryColor),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(l10n.clear_chapter_and_episode_cache),
              onTap: () => ref
                  .read(totalChapterCacheSizeStateProvider.notifier)
                  .clearCache(),
              subtitle: Text(
                totalChapterCacheSize,
                style: TextStyle(fontSize: 11, color: context.secondaryColor),
              ),
            ),
            SwitchListTile(
              value: clearChapterCacheOnAppLaunch,
              title: Text(
                context.l10n.clear_chapter_or_episode_cache_on_app_launch,
              ),
              onChanged: (value) {
                ref
                    .read(clearChapterCacheOnAppLaunchStateProvider.notifier)
                    .set(value);
              },
            ),
            ],
          ],
        ),
      ),
    );
  }
}

List<String> _getBackupFrequencyList(BuildContext context) {
  final l10n = l10nLocalizations(context)!;
  return [
    l10n.off,
    l10n.every_6_hours,
    l10n.every_12_hours,
    l10n.daily,
    l10n.every_2_days,
    l10n.weekly,
  ];
}
