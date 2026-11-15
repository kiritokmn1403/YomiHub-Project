import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangayomi/yomihub/integrations/yomikiru_reader_enhancer.dart';

/// Handler for keyboard shortcuts in the reader.
class ReaderKeyboardHandler {
  final VoidCallback? onEscape;
  final VoidCallback? onFullScreen;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final VoidCallback? onNextChapter;
  final VoidCallback? onPreviousChapter;

  /// YomiHub 0.5.7 (Yomikiru): phím bổ sung A/D/Space/Home/End.
  final bool extraKeys;
  final VoidCallback? onFirstPage;
  final VoidCallback? onLastPage;

  const ReaderKeyboardHandler({
    this.onEscape,
    this.onFullScreen,
    this.onPreviousPage,
    this.onNextPage,
    this.onNextChapter,
    this.onPreviousChapter,
    this.extraKeys = false,
    this.onFirstPage,
    this.onLastPage,
  });

  /// Handles a key event and returns true if it was handled.
  bool handleKeyEvent(KeyEvent event, {bool isReverseHorizontal = false}) {
    if (event is! KeyDownEvent) return false;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.f11:
        onFullScreen?.call();
        return true;

      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.backspace:
        onEscape?.call();
        return true;

      case LogicalKeyboardKey.arrowUp:
        onPreviousPage?.call();
        return true;

      case LogicalKeyboardKey.arrowDown:
        onNextPage?.call();
        return true;

      case LogicalKeyboardKey.arrowLeft:
        if (isReverseHorizontal) {
          onNextPage?.call();
        } else {
          onPreviousPage?.call();
        }
        return true;

      case LogicalKeyboardKey.arrowRight:
        if (isReverseHorizontal) {
          onPreviousPage?.call();
        } else {
          onNextPage?.call();
        }
        return true;

      case LogicalKeyboardKey.keyN:
      case LogicalKeyboardKey.pageDown:
      case LogicalKeyboardKey.shiftRight:
        onNextChapter?.call();
        return true;

      case LogicalKeyboardKey.keyP:
      case LogicalKeyboardKey.pageUp:
      case LogicalKeyboardKey.shiftLeft:
        onPreviousChapter?.call();
        return true;

      default:
        if (!extraKeys) return false;
        final act = YomikiruReaderEnhancer.extraKeyAction(event.logicalKey);
        if (act == null) return false;
        final isAD = event.logicalKey == LogicalKeyboardKey.keyA ||
            event.logicalKey == LogicalKeyboardKey.keyD;
        var forward = act == 'next';
        if (isAD && isReverseHorizontal) forward = !forward;
        switch (act) {
          case 'first':
            onFirstPage?.call();
          case 'last':
            onLastPage?.call();
          default:
            (forward ? onNextPage : onPreviousPage)?.call();
        }
        return true;
    }
  }

  /// Creates a KeyboardListener widget with this handler.
  Widget wrapWithKeyboardListener({
    required Widget child,
    bool isReverseHorizontal = false,
    FocusNode? focusNode,
  }) {
    return KeyboardListener(
      autofocus: true,
      focusNode: focusNode ?? FocusNode(),
      onKeyEvent: (event) =>
          handleKeyEvent(event, isReverseHorizontal: isReverseHorizontal),
      child: child,
    );
  }
}
