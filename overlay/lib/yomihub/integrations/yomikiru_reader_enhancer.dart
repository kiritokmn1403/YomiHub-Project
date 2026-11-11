import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

/// Yomikiru Reader Integration (Desktop Manga & Comic Enhancer)
/// Inspired by mienaiyami/yomikiru (Electron/JS Manga Reader).
///
/// Features integrated:
/// - Dual-page spread detection for wide/desktop screens
/// - Flexible page fitting modes (Fit Width, Fit Height, 1:1 Original, Smart Fit)
/// - Desktop keyboard shortcut mapping
/// - Smooth scroll and reading filter presets
class YomikiruReaderEnhancer {
  YomikiruReaderEnhancer._();

  static const String prefDualPage = 'yomikiru_dual_page';
  static const String prefFitMode = 'yomikiru_fit_mode';
  static const String prefSmoothScroll = 'yomikiru_smooth_scroll';
  static const String prefImageEnhance = 'yomikiru_image_enhance';

  /// Whether automatic dual-page spread is enabled on wide monitors.
  static bool get dualPageEnabled => YomiPrefs.get<bool>(prefDualPage, false);

  /// Current page fit mode: 'smart', 'width', 'height', 'original'.
  static String get fitMode => YomiPrefs.get<String>(prefFitMode, 'smart');

  /// Whether smooth scrolling is enabled for webtoon reading.
  static bool get smoothScrollEnabled => YomiPrefs.get<bool>(prefSmoothScroll, true);

  /// Whether image enhancement filters (sharpen/smoothing) are active.
  static bool get imageEnhanceEnabled => YomiPrefs.get<bool>(prefImageEnhance, false);

  /// Computes whether the current viewport should display two pages side-by-side.
  static bool shouldDisplayDualPage(BuildContext context, {required bool isLandscape}) {
    if (!dualPageEnabled) return false;
    final size = MediaQuery.sizeOf(context);
    // On wide monitors (aspect ratio > 1.3 and width > 900)
    return size.width > 900 && size.width / (size.height > 0 ? size.height : 1) > 1.3;
  }

  /// Handles desktop keyboard shortcuts for manga reader navigation.
  static KeyEventResult handleKeyNavigation({
    required KeyEvent event,
    required VoidCallback onNextPage,
    required VoidCallback onPreviousPage,
    required VoidCallback onFirstPage,
    required VoidCallback onLastPage,
  }) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD ||
        key == LogicalKeyboardKey.pageDown ||
        key == LogicalKeyboardKey.space) {
      onNextPage();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.pageUp) {
      onPreviousPage();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.home) {
      onFirstPage();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.end) {
      onLastPage();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Returns the BoxFit corresponding to the fit mode.
  static BoxFit getBoxFit(String mode) {
    return switch (mode) {
      'width' => BoxFit.fitWidth,
      'height' => BoxFit.fitHeight,
      'original' => BoxFit.none,
      _ => BoxFit.contain,
    };
  }
}

