import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

/// Yomihon Novel & EPUB Integration
/// Inspired by Yomihon (Light novel reader & typography toolkit).
///
/// Features integrated:
/// - Ergonomic typography presets (line height, letter spacing, paragraph spacing)
/// - Vertical text layout mode support (Tate-gaki)
/// - Estimated reading time calculation (Words Per Minute)
/// - Reading progress bookmarking
class YomihonNovelEnhancer {
  YomihonNovelEnhancer._();

  static const String prefTypographyPreset = 'yomihon_typography_preset';
  static const String prefVerticalMode = 'yomihon_vertical_mode';
  static const String prefWpm = 'yomihon_reading_wpm';

  /// YomiHub 0.5.7: bật áp preset typography (line-height) cho trình đọc tiểu thuyết.
  static const String prefTypographyEnabled = 'yomihon_typography_enabled';

  /// YomiHub 0.5.7: hiện thời gian đọc ước tính của chương.
  static const String prefShowReadingTime = 'yomihon_show_reading_time';

  /// Mặc định tắt (giữ hành vi cũ: line-height theo cài đặt riêng của trình đọc).
  static bool get typographyEnabled =>
      YomiPrefs.get<bool>(prefTypographyEnabled, false);

  static bool get showReadingTime =>
      YomiPrefs.get<bool>(prefShowReadingTime, false);

  static const List<int> wpmChoices = [150, 200, 250, 300, 400];

  /// Line-height của preset ('compact' 1.4, 'relaxed' 2.0, còn lại 1.65).
  static double presetLineHeight(String preset) => switch (preset) {
        'compact' => 1.4,
        'relaxed' => 2.0,
        _ => 1.65,
      };

  /// Line-height thực dùng trong trình đọc: preset nếu bật, nếu không giữ [userValue].
  static double effectiveLineHeight(double userValue) =>
      typographyEnabled ? presetLineHeight(typographyPreset) : userValue;

  /// Bóc thẻ HTML thành văn bản thuần để đếm từ.
  static String plainTextFromHtml(String html) {
    return html
        .replaceAll(RegExp(r'<(script|style)[^>]*>.*?</\1>', caseSensitive: false, dotAll: true), ' ')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'&[a-zA-Z#0-9]+;'), ' ');
  }

  /// Typography preset: 'compact', 'standard', 'relaxed'.
  static String get typographyPreset => YomiPrefs.get<String>(prefTypographyPreset, 'standard');

  /// Whether vertical text layout (Tate-gaki) is enabled.
  static bool get verticalMode => YomiPrefs.get<bool>(prefVerticalMode, false);

  /// Average reading speed in Words Per Minute (default 250 wpm).
  static int get readingWpm => YomiPrefs.get<int>(prefWpm, 250);

  /// Computes typography style based on selected preset.
  static TextStyle applyPreset(TextStyle base, String preset) {
    return switch (preset) {
      'compact' => base.copyWith(
          height: 1.4,
          letterSpacing: 0.1,
        ),
      'relaxed' => base.copyWith(
          height: 2.0,
          letterSpacing: 0.5,
        ),
      _ => base.copyWith(
          height: 1.65,
          letterSpacing: 0.25,
        ),
    };
  }

  /// Calculates estimated reading time for a text.
  static Duration estimateReadingTime(String text, {int? wpm}) {
    if (text.isEmpty) return Duration.zero;
    final speed = (wpm != null && wpm > 0) ? wpm : readingWpm;
    // Word count calculation: splits on whitespace or CJK characters
    final words = RegExp(r'[\u3040-\u30ff\u4e00-\u9fff]|[\p{L}\p{N}_]+', unicode: true)
        .allMatches(text)
        .length;
    final minutes = (words / speed).ceil();
    return Duration(minutes: minutes.clamp(1, 9999));
  }

  /// Formats estimated duration into human-readable text.
  static String formatReadingTime(Duration duration) {
    if (duration.inMinutes < 1) return tr('< 1 phút');
    if (duration.inHours < 1) return tr('{p0} phút', {'p0': duration.inMinutes});
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;
    return mins > 0
        ? tr('{p0} giờ {p1} phút', {'p0': hours, 'p1': mins})
        : tr('{p0} giờ', {'p0': hours});
  }
}

