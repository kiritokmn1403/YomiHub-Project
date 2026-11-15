import 'dart:io';
import 'dart:math';

import 'package:draggable_menu/draggable_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/router/router.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';

class MeasureWidgetSize extends StatefulWidget {
  final Function(Size? size) onCalculateSize;
  final Widget child;

  const MeasureWidgetSize({
    super.key,
    required this.onCalculateSize,
    required this.child,
  });

  @override
  State<MeasureWidgetSize> createState() => _MeasureWidgetSizeState();
}

class _MeasureWidgetSizeState extends State<MeasureWidgetSize> {
  final _key = GlobalKey();

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.onCalculateSize(_key.currentContext?.size),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(key: _key, child: widget.child);
  }
}

Future<void> customDraggableTabBar({
  required List<Widget> tabs,
  required List<Widget> children,
  required BuildContext context,
  required TickerProvider vsync,
  bool fullWidth = false,
  Widget? moreWidget,
}) async {
  final controller = DraggableMenuController();
  // 0.5.7 (logs 7: 40x "Null check operator used on a null value" in
  // flutter tabs.dart:633 `controller.animation!` @ /MangaLibrary and
  // /mangaReaderView): the TabController used to be created here and disposed
  // right after `DraggableMenu.open` returned - while the menu's closing
  // animation was still painting the TabBar. It now lives in
  // [DraggableTabsHost], whose State disposes it only once the subtree has
  // left the tree, i.e. after the last frame that could paint from it.
  // [vsync] is kept in the signature for the existing callers.
  final maxHeight = context.height(0.8);

  int index = 0;
  List<Map<String, dynamic>> widgetsHeight = [];

  void refresh() {
    controller.animateTo(
      widgetsHeight.indexWhere((element) => element["index"] == index),
    );
  }

  await showDialog(
    context: context,
    builder: (context) {
      return Material(
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              MeasureWidgetSize(
                onCalculateSize: (size) {
                  final additionnalHeight = Random().nextDouble() * 0.01;
                  double newHeight = size!.height + 52.0 + additionnalHeight;
                  if (!(newHeight <= maxHeight)) {
                    newHeight = maxHeight + additionnalHeight;
                  }
                  widgetsHeight.add({"index": i, "height": newHeight});
                  if (widgetsHeight.length == children.length) {
                    Navigator.pop(context);
                  }
                },
                child: children[i],
              ),
            ],
          ],
        ),
      );
    },
  );
  widgetsHeight.sort(
    (a, b) => (a["height"] as double).compareTo(b["height"] as double),
  );
  if (context.mounted) {
    await DraggableMenu.open(
      context,
      DraggableMenu(
        curve: Curves.linearToEaseOut,
        controller: controller,
        levels: widgetsHeight
            .map((e) => DraggableMenuLevel(height: e["height"]))
            .toList(),
        customUi: Consumer(
          builder: (context, ref, child) {
            final location = ref.watch(routerCurrentLocationStateProvider);
            final width = context.isTablet && !fullWidth
                ? switch (location) {
                    null => 100,
                    != '/MangaLibrary' &&
                        != '/AnimeLibrary' &&
                        != '/history' &&
                        != '/browse' &&
                        != '/more' =>
                      0,
                    _ => 100,
                  }
                : 0;
            return Scaffold(
              backgroundColor: Platform.isLinux ? null : Colors.transparent,
              body: SizedBox(
                width: context.width(1) - width,
                child: Material(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: DraggableTabsHost(
                    length: tabs.length,
                    onIndexChanged: (i) {
                      index = i;
                      refresh();
                    },
                    builder: (context, tabBarController) => Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              flex: 9,
                              child: TabBar(
                                unselectedLabelStyle: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                labelStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                dividerColor: Theme.of(context).dividerColor,
                                dividerHeight: 0.4,
                                controller: tabBarController,
                                tabs: tabs,
                              ),
                            ),
                            if (moreWidget != null)
                              Flexible(
                                flex: 1,
                                child: Column(
                                  children: [
                                    moreWidget,
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Container(
                                            color: Theme.of(context).dividerColor,
                                            height: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        Flexible(
                          child: TabBarView(
                            controller: tabBarController,
                            children: children
                                .map(
                                  (e) => SingleChildScrollView(
                                    child: MeasureWidgetSize(
                                      onCalculateSize: (_) => refresh(),
                                      child: e,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

/// Owns the [TabController] of a [customDraggableTabBar] sheet.
///
/// The controller is created in [State.initState] and disposed in
/// [State.dispose], so it outlives every frame in which the sheet (including
/// its closing animation) can still paint the [TabBar].
class DraggableTabsHost extends StatefulWidget {
  final int length;
  final ValueChanged<int>? onIndexChanged;
  final Widget Function(BuildContext context, TabController controller)
      builder;

  const DraggableTabsHost({
    super.key,
    required this.length,
    required this.builder,
    this.onIndexChanged,
  });

  @override
  State<DraggableTabsHost> createState() => _DraggableTabsHostState();
}

class _DraggableTabsHostState extends State<DraggableTabsHost>
    with SingleTickerProviderStateMixin {
  late final TabController _controller =
      TabController(length: widget.length, vsync: this);
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.animation?.addListener(_onAnimation);
  }

  void _onAnimation() {
    final animation = _controller.animation;
    if (animation == null) return;
    final i = animation.value.round().clamp(0, widget.length - 1);
    if (i == _lastIndex) return;
    _lastIndex = i;
    widget.onIndexChanged?.call(i);
  }

  @override
  void dispose() {
    _controller.animation?.removeListener(_onAnimation);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}
