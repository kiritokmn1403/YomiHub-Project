from ed import *

# ---------- U4: cong tac that ngay trong "Bat/Tat tinh nang" ----------
rel = 'lib/yomihub/playbooks/playbooks_toggle.dart'
sub(rel, """  static bool get enabled => YomiPrefs.get<bool>('playBooksEnabled', true);
}
""", """  static bool get enabled => YomiPrefs.get<bool>('playBooksEnabled', true);

  /// 0.5.7 (YomiHub Update: công tắc Google Play Books nằm ngay trong
  /// "Bật/Tắt tính năng & Nguồn mở rộng"): the one place that turns the
  /// feature on/off – the preference and the hidden navigation item together.
  static Future<void> setEnabled(WidgetRef ref, bool on) async {
    await YomiPrefs.set('playBooksEnabled', on);
    final list = [...ref.read(hideItemsStateProvider)]..remove(route);
    if (!on) list.add(route);
    ref.read(hideItemsStateProvider.notifier).set(list);
  }
}
""")
sub(rel, """      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: () => context.push('/playBooksSettings'),
""", """      // 0.5.7: the switch itself (before: only an arrow to another screen)
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            key: const ValueKey('playBooksSwitch'),
            value: on,
            onChanged: (v) => YomiPlayBooks.setEnabled(ref, v),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        ],
      ),
      onTap: () => context.push('/playBooksSettings'),
""")

rel = 'lib/yomihub/booru/booru_settings_screen.dart'
sub(rel, """/// YomiHub 0.4.4 – entry in Settings (next to Google Play Books).
class BooruSettingTile extends ConsumerWidget {
""", """/// 0.5.7: turns Booru App on/off (shows / hides its navigation item). Used by
/// the switch in "Bật/Tắt tính năng & Nguồn mở rộng" and by the Booru settings.
void setBooruEnabled(WidgetRef ref, bool on) {
  final hidden = [...ref.read(hideItemsStateProvider)]..remove(BooruStore.route);
  if (!on) hidden.add(BooruStore.route);
  ref.read(hideItemsStateProvider.notifier).set(hidden);
}

/// YomiHub 0.4.4 – entry in Settings (next to Google Play Books).
class BooruSettingTile extends ConsumerWidget {
""")
sub(rel, """      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: () => context.push('/booruSettings'),
""", """      // 0.5.7: the switch itself (before: only an arrow to another screen)
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            key: const ValueKey('booruSwitch'),
            value: on,
            onChanged: (v) => setBooruEnabled(ref, v),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        ],
      ),
      onTap: () => context.push('/booruSettings'),
""")
sub(rel, """  void _setEnabled(bool on) {
    final hidden = [...ref.read(hideItemsStateProvider)];
    hidden.remove(BooruStore.route);
    if (!on) hidden.add(BooruStore.route);
    ref.read(hideItemsStateProvider.notifier).set(hidden);
  }
""", """  void _setEnabled(bool on) => setBooruEnabled(ref, on);
""")
# ---------- U3: cau chu vi tri sao luu ----------
sub(rel, "tr('Yêu thích ({p0}), lịch sử và cài đặt Booru App được sao lưu cùng ứng dụng (Cài đặt › Dữ liệu và bộ nhớ, đồng bộ đám mây).',",
         "tr('Yêu thích ({p0}), lịch sử và cài đặt Booru App được sao lưu cùng ứng dụng (Cài đặt › Sao Lưu & Đồng Bộ).',")

# ---------- FC38: gom loi vao hop nhat vao man "Hop Nhat Tien Ich" ----------
rel = 'lib/yomihub/merge/extension_merge_screen.dart'
sub(rel, """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/eval/model/m_bridge.dart';
""", """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/eval/model/m_bridge.dart';
import 'package:mangayomi/modules/more/data_and_storage/widgets/source_management_tiles.dart';
""")
sub(rel, """          const SizedBox(height: 16),

          // Header danh sách nhóm đã hợp nhất
""", """          const SizedBox(height: 16),

          // 0.5.7 (Feature Check 38): every merge setting lives on this
          // screen – the three tools that used to sit under "Dữ liệu và bộ
          // nhớ" and the way into "Hợp nhất nội dung".
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              tr('Công cụ hợp nhất'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ),
          Card(
            key: const ValueKey('mergeTools'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const CustomMergeSourcesTile(),
                const Divider(height: 1),
                const MergeDuplicateMangaTile(),
                const Divider(height: 1),
                const ManualMergeMangaTile(),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.auto_stories_rounded),
                  title: Text(tr('Hợp nhất nội dung')),
                  subtitle: Text(
                    tr('Hợp nhất truyện tranh, tiểu thuyết, phim ảnh (tự động đề xuất, chọn thủ công, hủy hợp nhất)'),
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => context.push('/contentMerge'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Header danh sách nhóm đã hợp nhất
""")

rel = 'lib/modules/more/data_and_storage/data_and_storage.dart'
sub(rel, """            const MergeDuplicateMangaTile(),
            const ManualMergeMangaTile(),
            const CustomMergeSourcesTile(),
""", """            // 0.5.7 (Feature Check 38): the three merge tools moved into
            // "Hợp Nhất Tiện Ích"; one shortcut stays here
            ListTile(
              leading: const Icon(Icons.hub_rounded),
              title: Text(tr('Hợp Nhất Tiện Ích')),
              subtitle: Text(tr('Hợp nhất bộ trùng, tự chọn bộ, hợp nhất tiện ích theo lựa chọn')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/mergeExtensions'),
            ),
""")
print('P1 patch part 1 OK')
