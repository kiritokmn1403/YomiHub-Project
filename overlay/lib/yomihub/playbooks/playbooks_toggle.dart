import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/modules/more/settings/reader/providers/reader_state_provider.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

class YomiPlayBooks {
  static const route = '/playBooks';
  static bool get enabled => YomiPrefs.get<bool>('playBooksEnabled', true);
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
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: () => context.push('/playBooksSettings'),
    );
  }
}
