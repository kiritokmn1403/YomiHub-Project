import 'package:flutter/material.dart';
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
    final words = RegExp(r'[\w\u4e00-\u9fa5\u3040-\u30ff]+').allMatches(text).length;
    final minutes = (words / speed).ceil();
    return Duration(minutes: minutes.clamp(1, 9999));
  }

  /// Formats estimated duration into human-readable text.
  static String formatReadingTime(Duration duration) {
    if (duration.inMinutes < 1) return '< 1 phút';
    if (duration.inHours < 1) return '${duration.inMinutes} phút';
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;
    return mins > 0 ? '$hours giờ $mins phút' : '$hours giờ';
  }
}

