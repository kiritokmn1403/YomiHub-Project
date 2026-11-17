import sys; sys.path.insert(0,'.')
from edit import edit
F='lib/modules/library/library_screen.dart'
edit(F,"""  void _retireTabController(TabController? controller) {
    if (controller == null) return;
    _retiredTabControllers.add(controller);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_retiredTabControllers.remove(controller)) return;
      controller.dispose();
    });
  }""","""  ///
  /// 0.5.2: disposing one frame later was still too early. logs 2
  /// (04/11 09:49:27, /AnimeLibrary): "Null check operator used on a null
  /// value" in `_IndicatorPainter.paint` (flutter tabs.dart:633,
  /// `controller.animation!`) – the TabBar repainted with a controller that
  /// had already been disposed while a library update changed the category
  /// list. Retired controllers are now kept (they hold no running ticker)
  /// until this screen is disposed; only the oldest are released once more
  /// than 16 have piled up, long after anything could paint from them.
  void _retireTabController(TabController? controller) {
    if (controller == null) return;
    _retiredTabControllers.add(controller);
    while (_retiredTabControllers.length > 16) {
      _retiredTabControllers.removeAt(0).dispose();
    }
  }""")
