import sys,os; sys.path.insert(0,os.path.expanduser('~/mnt/A.I Project - YomiHub Project/YomiHub-Project/audit-0.5.3')); from edit import edit
D='lib/modules/more/data_and_storage/data_and_storage.dart'
edit(D,"""class DataAndStorage extends ConsumerWidget {
  const DataAndStorage({super.key});
""","""class DataAndStorage extends ConsumerWidget {
  /// 0.5.3 (sheet "YomiHub Update" mục 4): true = the "Sao Lưu & Đồng Bộ"
  /// screen (create / restore, frequency, compression, location, encryption,
  /// cloud backup, sync, Booru App backup) – opened from Settings and More.
  /// false = "Dữ liệu và bộ nhớ" without the backup settings.
  final bool backupSync;
  const DataAndStorage({super.key, this.backupSync = false});
""")
edit(D,"      appBar: AppBar(title: Text(l10n.data_and_storage)),","      appBar: AppBar(\n        title: Text(backupSync ? tr('Sao Lưu & Đồng Bộ') : l10n.data_and_storage),\n      ),")
edit(D,"""        child: Column(
          children: [
            // YomiHub 0.1.8: download index""","""        child: Column(
          children: [
            if (!backupSync) ...[
            // YomiHub 0.1.8: download index""")
edit(D,"""            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Row(
                children: [
                  Text(
                    l10n.backup_and_restore,""","""            // 0.5.3: library tools stay here; backup settings moved
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
                    l10n.backup_and_restore,""")
edit(D,"""            const RollbackLastChangeTile(),
            const MissingSourceCheckTile(),
            const DeleteSourceTile(),
            const MergeDuplicateMangaTile(),
            const ManualMergeMangaTile(),
            const CustomMergeSourcesTile(),
""","""            const RollbackLastChangeTile(),
""")
edit(D,"""              onTap: () => context.push('/cloudBackup'),
            ),
            Padding(""","""              onTap: () => context.push('/cloudBackup'),
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
            Padding(""")
edit(D,"""                    .read(clearChapterCacheOnAppLaunchStateProvider.notifier)
                    .set(value);
              },
            ),
          ],""","""                    .read(clearChapterCacheOnAppLaunchStateProvider.notifier)
                    .set(value);
              },
            ),
            ],
          ],""")
R='lib/router/router.dart'
edit(R,"""    _genericRoute(name: "dataAndStorage", child: const DataAndStorage()),""","""    _genericRoute(name: "dataAndStorage", child: const DataAndStorage()),
    // 0.5.3: "Sao Lưu & Đồng Bộ" (Settings + More)
    _genericRoute(
      name: "backupSync",
      child: const DataAndStorage(backupSync: true),
    ),""")
S='lib/modules/more/settings/settings_screen.dart'
edit(S,"""            ListTileWidget(
              title: l10n.syncing,
              icon: Icons.cloud_sync_outlined,
              onTap: () => context.push('/sync'),
            ),""","""            // 0.5.3: backup, cloud backup and sync are one section
            ListTileWidget(
              title: tr('Sao Lưu & Đồng Bộ'),
              subtitle: tr('Tạo / khôi phục sao lưu, tần suất, mức nén, vị trí, sao lưu đám mây, đồng bộ, Booru App'),
              icon: Icons.settings_backup_restore,
              onTap: () => context.push('/backupSync'),
            ),""")
edit(S,"""            // YomiHub 0.2.0: Google Play Books on/off
            // 0.5.0: no Play Books / Booru on Android TV
            if (!(isTv || kIsTvBuild)) const PlayBooksSettingTile(),
            if (!(isTv || kIsTvBuild)) const BooruSettingTile(),
            ListTileWidget(
              title: tr('Sao lưu đám mây'),
              subtitle: 'Google Drive, OneDrive, Dropbox, WebDAV, Rclone, MediaFire, Telegram',
              icon: Icons.cloud_upload_outlined,
              onTap: () => context.push('/cloudBackup'),
            ),
""","""            // 0.5.3: Google Play Books / Booru App moved to "Bật/Tắt tính
            // năng & Nguồn mở rộng"; cloud backup to "Sao Lưu & Đồng Bộ"
""")
edit(S,"import 'package:mangayomi/yomihub/playbooks/playbooks_toggle.dart';\nimport 'package:mangayomi/yomihub/booru/booru_settings_screen.dart';\n","")
M='lib/modules/more/more_screen.dart'
edit(M,"""            ListTileWidget(
              onTap: () {
                context.push('/dataAndStorage');
              },
              icon: Icons.storage,
              title: l10n.data_and_storage,
            ),""","""            // 0.5.3 (YomiHub Update mục 4)
            ListTileWidget(
              onTap: () => context.push('/backupSync'),
              icon: Icons.settings_backup_restore,
              title: tr('Sao Lưu & Đồng Bộ'),
            ),
            ListTileWidget(
              onTap: () {
                context.push('/dataAndStorage');
              },
              icon: Icons.storage,
              title: l10n.data_and_storage,
            ),""")
F='lib/yomihub/features/feature_toggle_screen.dart'
edit(F,"""            // --- QUICK SHORTCUTS ---""","""            // 0.5.3 (YomiHub Update mục 5): Google Play Books and Booru App
            // on/off live here with the other features (not on Android TV)
            if (!(isTv || kIsTvBuild)) ...[
              _buildSectionHeader(
                context,
                icon: Icons.extension_outlined,
                title: tr('Tính năng khác'),
                color: Colors.deepPurple,
              ),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                ),
                child: const Column(
                  children: [
                    PlayBooksSettingTile(),
                    Divider(height: 1),
                    BooruSettingTile(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // --- QUICK SHORTCUTS ---""")
edit(F,"import 'package:mangayomi/yomihub/ui/liquid_glass.dart';\n","import 'package:mangayomi/yomihub/ui/liquid_glass.dart';\nimport 'package:mangayomi/yomihub/playbooks/playbooks_toggle.dart';\nimport 'package:mangayomi/yomihub/booru/booru_settings_screen.dart';\nimport 'package:mangayomi/utils/platform_utils.dart';\nimport 'package:mangayomi/modules/main_view/providers/tv_mode_provider.dart';\n")
B='lib/yomihub/backup/yomi_backup_extras.dart'
edit(B,"""    for (final name in boxes) {
      try {
        final box = Hive.isBoxOpen(name)""","""    for (final name in boxes) {
      // 0.5.3: "Sao lưu dữ liệu Booru App" switch in Sao Lưu & Đồng Bộ
      if (name == 'yomihub_booru' && !YomiPrefs.get<bool>('backupBooru', true)) continue;
      try {
        final box = Hive.isBoxOpen(name)""")
edit(B,"import 'package:hive/hive.dart';\n","import 'package:hive/hive.dart';\nimport 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';\n")
