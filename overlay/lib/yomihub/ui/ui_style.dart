import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

/// YomiHub 0.5.6 (sheet "YomiHub Update" row 12): the application shell can
/// be shown in two ways.
///
/// * [classic] – the YomiHub layout up to 0.5.5: History lives only in
///   "More"; the Library sub-tabs are an underlined tab strip.
/// * [modern] – the navigation of Mangayomi 0.9.95 (nav groups): History is
///   a destination again and is folded with Updates into "Hoạt động"
///   (Activity, double tap resumes the last entry); the group switchers
///   are pill-shaped segments.
///
/// The choice is kept in [YomiPrefs] (key [prefKey]) so it is part of every
/// backup; upgraders and restored backups without the key get [classic].
/// * [mangayomiV2] – 0.6.2 "YomiHub New Version": giao diện Mangayomi 0.9.96
///   (thanh điều hướng nổi kéo-thả, chủ đề Mv2, thẻ bìa mới) – xem
///   `yomihub/ui/mangayomi_v2/`. Kế thừa mọi hành vi của [modern].
enum YomiUiStyle { classic, modern, mangayomiV2 }

class YomiUi {
  YomiUi._();
  static const prefKey = 'uiStyle';

  /// Parses a stored value; anything unknown is the classic layout.
  static YomiUiStyle parse(Object? raw) => switch (raw) {
        'mangayomiV2' => YomiUiStyle.mangayomiV2,
        'modern' => YomiUiStyle.modern,
        _ => YomiUiStyle.classic,
      };

  /// Test hook: forces a style without an open prefs box.
  @visibleForTesting
  static YomiUiStyle? debugOverride;

  static YomiUiStyle get style =>
      debugOverride ?? parse(YomiPrefs.get<Object?>(prefKey, null));

  /// true cho cả "Mới" (0.9.95) và "YomiHub New Version" (0.9.96): V2 dùng
  /// chung nhóm điều hướng, chuyển cảnh và thẻ Shiori của bản Mới.
  static bool get isModern => style != YomiUiStyle.classic;

  /// 0.6.2: "YomiHub New Version" (Mangayomi 0.9.96).
  static bool get isV2 => style == YomiUiStyle.mangayomiV2;

  /// Saves the choice; listeners of [YomiPrefs.changes] rebuild at once.
  static Future<void> setStyle(YomiUiStyle s) => YomiPrefs.set(prefKey, s.name);
}

/// 0.6.2: kiểu giao diện dạng provider (đổi trong Cài đặt → chủ đề dựng lại ngay).
class YomiUiStyleNotifier extends Notifier<YomiUiStyle> {
  @override
  YomiUiStyle build() {
    void listener() {
      final s = YomiUi.style;
      if (s != state) state = s;
    }

    YomiPrefs.changes.addListener(listener);
    ref.onDispose(() => YomiPrefs.changes.removeListener(listener));
    return YomiUi.style;
  }
}

final yomiUiStyleProvider =
    NotifierProvider<YomiUiStyleNotifier, YomiUiStyle>(YomiUiStyleNotifier.new);

/// Settings › Appearance: "Giao diện ứng dụng: Cũ / Mới".
class YomiUiStyleTile extends StatelessWidget {
  const YomiUiStyleTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: YomiPrefs.changes,
      builder: (context, _, _) {
        final style = YomiUi.style;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: Text(tr('Giao diện ứng dụng')),
              subtitle: Text(
                switch (style) {
                  YomiUiStyle.mangayomiV2 => tr('YomiHub New Version – giao diện Mangayomi 0.9.96: thanh điều hướng nổi kéo-thả, chủ đề và thẻ truyện mới'),
                  YomiUiStyle.modern => tr('Mới – điều hướng kiểu Mangayomi 0.9.95: Cập nhật và Lịch sử gộp thành mục Hoạt động, bộ chọn tab dạng viên'),
                  YomiUiStyle.classic => tr('Cũ – bố cục YomiHub: Lịch sử nằm trong Thêm, tab con của Thư Viện ở phía trên'),
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SegmentedButton<YomiUiStyle>(
                key: const ValueKey('yomiUiStyleSwitch'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: YomiUiStyle.classic,
                    icon: const Icon(Icons.view_agenda_outlined),
                    label: FittedBox(fit: BoxFit.scaleDown, child: Text(tr('YomiHub Old Version'))),
                  ),
                  ButtonSegment(
                    value: YomiUiStyle.modern,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: FittedBox(fit: BoxFit.scaleDown, child: Text(tr('Mới (0.9.95)'))),
                  ),
                  ButtonSegment(
                    value: YomiUiStyle.mangayomiV2,
                    icon: const Icon(Icons.rocket_launch_outlined),
                    label: FittedBox(fit: BoxFit.scaleDown, child: Text(tr('YomiHub New Version'))),
                  ),
                ],
                selected: {style},
                onSelectionChanged: (s) => YomiUi.setStyle(s.first),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// YomiHub 0.6.2 – Settings › Appearance: "Giao diện bộ lọc: Bộ lọc cũ / Bộ lọc mới"
/// (sheet "YomiHub Update": chọn giữa bộ lọc mới và bộ lọc cũ trong Giao Diện).
class YomiFilterStyleTile extends StatelessWidget {
  const YomiFilterStyleTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: YomiPrefs.changes,
      builder: (context, _, _) {
        final isNew = YomiPrefs.useNewFilter;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.filter_list_rounded),
              title: Text(tr('Giao diện bộ lọc')),
              subtitle: Text(
                isNew
                    ? tr('Bộ lọc mới – gom thành 9 nhóm thẻ gập/mở (Sắp Xếp, Tình Trạng, Thể Loại…), toàn bộ dạng ô chọn')
                    : tr('Bộ lọc cũ – danh sách bộ lọc mặc định theo từng kiểu tiện ích'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SegmentedButton<bool>(
                key: const ValueKey('yomiFilterStyleSwitch'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.view_list_outlined),
                    label: Text(tr('Bộ lọc cũ')),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.dashboard_outlined),
                    label: Text(tr('Bộ lọc mới')),
                  ),
                ],
                selected: {isNew},
                onSelectionChanged: (s) => YomiPrefs.useNewFilter = s.first,
              ),
            ),
          ],
        );
      },
    );
  }
}
