import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/modules/more/settings/reader/providers/reader_state_provider.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_store.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

/// YomiHub 0.6.3 – "Tủ Sách Cá Nhân" on/off (same mechanism as Booru App:
/// the route is kept in the hidden navigation items).
void setBookshelfEnabled(WidgetRef ref, bool on) {
  final hidden = [...ref.read(hideItemsStateProvider)]..remove(BookshelfStore.route);
  if (!on) hidden.add(BookshelfStore.route);
  ref.read(hideItemsStateProvider.notifier).set(hidden);
}

/// Entry in Cài đặt › Bật/Tắt tính năng & Nguồn mở rộng (next to Booru App).
class BookshelfSettingTile extends ConsumerWidget {
  const BookshelfSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = !ref.watch(hideItemsStateProvider).contains(BookshelfStore.route);
    return ListTile(
      leading: const Icon(Icons.shelves, color: Colors.brown),
      title: Text(tr('Tủ Sách Cá Nhân')),
      subtitle: Text(on
          ? tr('Đang bật – quản lý tủ truyện & sách, quét mã vạch ISBN, chống mua trùng tập')
          : tr('Đang tắt – ẩn nút Tủ Sách khỏi thanh điều hướng')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            key: const ValueKey('bookshelfSwitch'),
            value: on,
            onChanged: (v) => setBookshelfEnabled(ref, v),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        ],
      ),
      onTap: on ? () => context.go(BookshelfStore.route) : null,
    );
  }
}
