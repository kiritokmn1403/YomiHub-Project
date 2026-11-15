import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/modules/more/settings/reader/providers/reader_state_provider.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

class YomiPlayBooks {
  static const route = '/playBooks';
  static bool get enabled => YomiPrefs.get<bool>('playBooksEnabled', true);

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

class PlayBooksSettingTile extends ConsumerWidget {
  const PlayBooksSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(hideItemsStateProvider);
    final on = YomiPlayBooks.enabled && !hidden.contains(YomiPlayBooks.route);
    return ListTile(
      leading: const Icon(Icons.auto_stories_outlined, color: Colors.blue),
      title: const Text('Google Play Books'),
      subtitle: Text(on
          ? tr('Đang bật – tích hợp 18 dự án mở và giao diện đọc sách Google Play Books')
          : tr('Đang tắt – ẩn toàn bộ chức năng Google Play Books')),
      // 0.5.7: the switch itself (before: only an arrow to another screen)
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
    );
  }
}
