import 'package:flutter/material.dart';
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
enum YomiUiStyle { classic, modern }

class YomiUi {
  YomiUi._();
  static const prefKey = 'uiStyle';

  /// Parses a stored value; anything unknown is the classic layout.
  static YomiUiStyle parse(Object? raw) =>
      raw == 'modern' ? YomiUiStyle.modern : YomiUiStyle.classic;

  static YomiUiStyle get style => parse(YomiPrefs.get<Object?>(prefKey, null));

  static bool get isModern => style == YomiUiStyle.modern;

  /// Saves the choice; listeners of [YomiPrefs.changes] rebuild at once.
  static Future<void> setStyle(YomiUiStyle s) => YomiPrefs.set(prefKey, s.name);
}

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
                style == YomiUiStyle.modern
                    ? tr('Mới – điều hướng kiểu Mangayomi 0.9.95: Cập nhật và Lịch sử gộp thành mục Hoạt động, bộ chọn tab dạng viên')
                    : tr('Cũ – bố cục YomiHub: Lịch sử nằm trong Thêm, tab con của Thư Viện ở phía trên'),
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
                    label: Text(tr('Cũ')),
                  ),
                  ButtonSegment(
                    value: YomiUiStyle.modern,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: Text(tr('Mới')),
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
