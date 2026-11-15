import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/integrations/yomihon_novel_enhancer.dart';
import 'package:mangayomi/yomihub/integrations/yomikiru_reader_enhancer.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

/// YomiHub 0.5.7 (U5): công tắc cho phần tích hợp Yomikiru trong cài đặt trình đọc truyện.
class YomikiruSettingsSection extends StatelessWidget {
  const YomikiruSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: YomiPrefs.changes,
      builder: (context, _, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, 'Yomikiru'),
          SwitchListTile(
            secondary: const Icon(Icons.keyboard_alt_outlined),
            title: Text(tr('Phím tắt mở rộng (Yomikiru)')),
            subtitle: Text(
              tr('A / D chuyển trang, Space trang kế, Home / End về trang đầu / cuối'),
            ),
            value: YomikiruReaderEnhancer.extraKeysEnabled,
            onChanged: (v) =>
                YomiPrefs.set(YomikiruReaderEnhancer.prefExtraKeys, v),
          ),
        ],
      ),
    );
  }
}

/// YomiHub 0.5.7 (U5): công tắc cho phần tích hợp Yomihon trong cài đặt trình đọc tiểu thuyết.
class YomihonSettingsSection extends StatelessWidget {
  const YomihonSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: YomiPrefs.changes,
      builder: (context, _, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, 'Yomihon'),
          SwitchListTile(
            secondary: const Icon(Icons.format_line_spacing),
            title: Text(tr('Preset giãn dòng (Yomihon)')),
            subtitle: Text(
              tr('Dùng giãn dòng theo preset thay cho giá trị tự chỉnh'),
            ),
            value: YomihonNovelEnhancer.typographyEnabled,
            onChanged: (v) =>
                YomiPrefs.set(YomihonNovelEnhancer.prefTypographyEnabled, v),
          ),
          if (YomihonNovelEnhancer.typographyEnabled)
            ListTile(
              title: Text(tr('Kiểu preset')),
              trailing: DropdownButton<String>(
                value: YomihonNovelEnhancer.typographyPreset,
                items: [
                  DropdownMenuItem(
                    value: 'compact',
                    child: Text(tr('Gọn')),
                  ),
                  DropdownMenuItem(
                    value: 'standard',
                    child: Text(tr('Chuẩn')),
                  ),
                  DropdownMenuItem(
                    value: 'relaxed',
                    child: Text(tr('Thoáng')),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    YomiPrefs.set(YomihonNovelEnhancer.prefTypographyPreset, v);
                  }
                },
              ),
            ),
          SwitchListTile(
            secondary: const Icon(Icons.timer_outlined),
            title: Text(tr('Hiện thời gian đọc ước tính')),
            subtitle: Text(
              tr('Hiện ước tính thời gian đọc chương khi mở thanh công cụ'),
            ),
            value: YomihonNovelEnhancer.showReadingTime,
            onChanged: (v) =>
                YomiPrefs.set(YomihonNovelEnhancer.prefShowReadingTime, v),
          ),
          if (YomihonNovelEnhancer.showReadingTime)
            ListTile(
              title: Text(tr('Tốc độ đọc (từ/phút)')),
              trailing: DropdownButton<int>(
                value:
                    YomihonNovelEnhancer.wpmChoices.contains(
                      YomihonNovelEnhancer.readingWpm,
                    )
                    ? YomihonNovelEnhancer.readingWpm
                    : 250,
                items: [
                  for (final w in YomihonNovelEnhancer.wpmChoices)
                    DropdownMenuItem(value: w, child: Text('$w')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    YomiPrefs.set(YomihonNovelEnhancer.prefWpm, v);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

Widget _header(BuildContext context, String title) => Padding(
  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
  child: Text(
    title,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
    ),
  ),
);
