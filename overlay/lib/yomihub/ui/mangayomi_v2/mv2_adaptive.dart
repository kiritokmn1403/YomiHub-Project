// YomiHub New Version (Mangayomi v0.9.96) Adaptive Rail, TV D-pad Focus & Responsive Grid.
// Designed for tablets (>= 600 dp), Windows/desktop, and Android TV on Flutter 3.47.6 / Dart 3.13.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangayomi/utils/constant.dart';
import 'package:mangayomi/utils/platform_utils.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/ui/liquid_glass.dart';

import 'mv2_nav_shell.dart';
import 'mv2_theme.dart';

/// Adaptive breakpoints, rail geometry and TV focus helpers for YomiHub New Version.
abstract final class Mv2Adaptive {
  /// Minimum width (dp) treated as a wide screen / tablet layout.
  static const double wideBreakpoint = 600.0;

  /// Width (dp) above which grid spacing and card extent step up for tablets/laptops.
  static const double expandedBreakpoint = 840.0;

  /// Width (dp) above which grid columns step up for large desktop / 1080p TV screens.
  static const double largeBreakpoint = 1200.0;

  /// Width of the collapsed navigation rail panel (excluding outer margin).
  static const double collapsedRailWidth = 92.0;

  /// Width of the collapsed navigation rail panel on Android TV.
  static const double collapsedTvRailWidth = 108.0;

  /// Width of the expanded navigation rail panel on tablets / Windows.
  static const double expandedRailWidth = 224.0;

  /// Width of the expanded navigation rail panel on Android TV.
  static const double expandedTvRailWidth = 252.0;

  /// Top-level shell routes where the navigation rail remains visible.
  /// Mirrors `_TabletLayout._getNavigationRailWidth` in `main_screen.dart`.
  static const Set<String> validRailLocations = {
    '/MangaLibrary',
    '/AnimeLibrary',
    '/NovelLibrary',
    '/playBooks',
    '/booru',
    '/bookshelf',
    '/history',
    '/updates',
    '/browse',
    '/more',
    '/trackerLibrary',
  };

  /// Whether the viewport is at least [wideBreakpoint] logical pixels wide.
  static bool isWideScreen(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wideBreakpoint;

  /// Whether New Version should show the adaptive navigation rail rather than
  /// the mobile floating capsule bar.
  ///
  /// True on Android TV, desktop platforms (Windows/macOS/Linux), and wide
  /// screens (`width >= 600 dp`).
  static bool shouldUseRail(
    BuildContext context, {
    bool? isTvOverride,
    bool? isDesktopOverride,
  }) {
    final tv = isTvOverride ?? isTv;
    final desktop = isDesktopOverride ?? isDesktop;
    return tv || desktop || isWideScreen(context);
  }

  /// Whether the rail should remain visible at [location].
  static bool isRailLocation(String? location) =>
      location == null || validRailLocations.contains(location);

  /// High-contrast focus border colour that stays legible on [surface].
  static Color focusRingColor(BuildContext context, {Color? surface}) {
    final c = context.mv2.color;
    return Mv2Colors.legibleOn(c.accent, surface ?? c.ink1, target: 3.0);
  }
}

/// Pure responsive grid layout metrics compatible with `Mv2MangaCard` and library grids.
@immutable
class Mv2AdaptiveGridSpec {
  const Mv2AdaptiveGridSpec({
    required this.crossAxisCount,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.childAspectRatio,
    required this.padding,
    required this.cellWidth,
  });

  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;
  final double cellWidth;

  /// Computes responsive column count, spacing, padding and overflow-safe aspect ratio
  /// for a grid of width [availableWidth].
  static Mv2AdaptiveGridSpec resolve({
    required double availableWidth,
    int? gridSize,
    bool isComfortableGrid = false,
    bool isCoverOnly = false,
    bool hasSubtitle = false,
    bool isTvMode = false,
    bool isDesktopMode = false,
    double typeScale = 1.0,
    double textScaleFactor = 1.0,
    double coverAspectRatio = kMv2CoverAspect,
    double outerItemPadding = 0.0,
    double bottomInset = 0.0,
  }) {
    final safeWidth =
        (availableWidth.isFinite && availableWidth > 0) ? availableWidth : 360.0;
    final safeAspect = coverAspectRatio > 0 ? coverAspectRatio : kMv2CoverAspect;

    final double horizontalPad;
    final double topPad = Mv2Space.s12;
    final double bottomPad = Mv2Space.s12 + math.max(0.0, bottomInset);
    final double spacing;
    final double targetExtent;

    if (isTvMode) {
      horizontalPad = Mv2Space.s16;
      spacing = Mv2Space.s12;
      targetExtent = 164.0;
    } else if (safeWidth >= Mv2Adaptive.largeBreakpoint) {
      horizontalPad = Mv2Space.s16;
      spacing = Mv2Space.s12;
      targetExtent = isDesktopMode ? 186.0 : 180.0;
    } else if (safeWidth >= Mv2Adaptive.expandedBreakpoint) {
      horizontalPad = Mv2Space.s16;
      spacing = Mv2Space.s8;
      targetExtent = isDesktopMode ? 174.0 : 168.0;
    } else if (safeWidth >= Mv2Adaptive.wideBreakpoint) {
      horizontalPad = Mv2Space.s12;
      spacing = Mv2Space.s8;
      targetExtent = 158.0;
    } else {
      horizontalPad = Mv2Space.s8;
      spacing = Mv2Space.s4;
      targetExtent = 156.0;
    }

    final innerWidth = math.max(120.0, safeWidth - horizontalPad * 2);
    final int columns = (gridSize != null && gridSize > 0)
        ? gridSize.clamp(1, 12)
        : ((innerWidth + spacing) / (targetExtent + spacing))
            .floor()
            .clamp(2, 12);

    final cellWidth = math.max(
      64.0,
      (innerWidth - spacing * (columns - 1)) / columns,
    );

    // Match Mv2MangaCard geometry: outer Padding(Mv2Space.s4) = 8 dp,
    // focus Border.all(width: 3) = 6 dp, plus optional caller wrapper padding.
    final cardChrome = outerItemPadding + Mv2Space.s4 * 2 + 6.0;
    final coverWidth = math.max(36.0, cellWidth - cardChrome);
    final coverHeight = coverWidth / safeAspect;

    final showBottomTitle = isComfortableGrid && !isCoverOnly;
    var extraHeight = cardChrome;
    if (showBottomTitle) {
      final scale = math.max(0.85, typeScale) * textScaleFactor.clamp(0.85, 1.6);
      final titleLines = hasSubtitle ? 1 : 2;
      final titleHeight = 14.0 * scale * 1.35 * titleLines + 4.0;
      final subtitleHeight = hasSubtitle ? (12.0 * scale * 1.35 + 2.0) : 0.0;
      extraHeight += Mv2Space.s4 + titleHeight + subtitleHeight;
    }

    final cellHeight = coverHeight + extraHeight;
    final aspect = (cellWidth / cellHeight).clamp(0.45, 0.85);

    return Mv2AdaptiveGridSpec(
      crossAxisCount: columns,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: aspect,
      padding: EdgeInsets.fromLTRB(
        horizontalPad,
        topPad,
        horizontalPad,
        bottomPad,
      ),
      cellWidth: cellWidth,
    );
  }

  /// Resolves responsive grid metrics using tokens and text scale from [context].
  factory Mv2AdaptiveGridSpec.of(
    BuildContext context, {
    required double availableWidth,
    int? gridSize,
    bool isComfortableGrid = false,
    bool isCoverOnly = false,
    bool hasSubtitle = false,
    bool? isTvOverride,
    bool? isDesktopOverride,
    double coverAspectRatio = kMv2CoverAspect,
    double outerItemPadding = 0.0,
    bool addFloatingBottomInset = true,
  }) {
    final tokens = context.mv2;
    final tv = isTvOverride ?? isTv;
    final desktop = isDesktopOverride ?? isDesktop;
    final textScale = MediaQuery.textScalerOf(context).scale(14.0) / 14.0;
    final bottomInset = (addFloatingBottomInset && Mv2FloatingNavScope.enabledOf(context))
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;
    return resolve(
      availableWidth: availableWidth,
      gridSize: gridSize,
      isComfortableGrid: isComfortableGrid,
      isCoverOnly: isCoverOnly,
      hasSubtitle: hasSubtitle,
      isTvMode: tv,
      isDesktopMode: desktop,
      typeScale: tokens.density.typeScale,
      textScaleFactor: textScale,
      coverAspectRatio: coverAspectRatio,
      outerItemPadding: outerItemPadding,
      bottomInset: bottomInset,
    );
  }

  /// Converts this spec into a Flutter [SliverGridDelegate].
  SliverGridDelegateWithFixedCrossAxisCount toSliverDelegate() =>
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      );
}

/// Width-responsive grid view compatible with `Mv2MangaCard` and library screens.
class Mv2AdaptiveGrid extends StatelessWidget {
  const Mv2AdaptiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.reverse = false,
    this.physics,
    this.shrinkWrap = false,
    this.gridSize,
    this.isComfortableGrid = false,
    this.isCoverOnly = false,
    this.hasSubtitle = false,
    this.coverAspectRatio = kMv2CoverAspect,
    this.outerItemPadding = 0.0,
    this.paddingOverride,
    this.backgroundColor,
    this.isTvOverride,
    this.isDesktopOverride,
    this.addFloatingBottomInset = true,
  });

  final int itemCount;
  final Widget? Function(BuildContext context, int index) itemBuilder;
  final ScrollController? controller;
  final bool reverse;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final int? gridSize;
  final bool isComfortableGrid;
  final bool isCoverOnly;
  final bool hasSubtitle;
  final double coverAspectRatio;
  final double outerItemPadding;
  final EdgeInsetsGeometry? paddingOverride;
  final Color? backgroundColor;
  final bool? isTvOverride;
  final bool? isDesktopOverride;
  final bool addFloatingBottomInset;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? context.mv2.color.ink0;
    return ColoredBox(
      color: bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final spec = Mv2AdaptiveGridSpec.of(
            context,
            availableWidth: width,
            gridSize: gridSize,
            isComfortableGrid: isComfortableGrid,
            isCoverOnly: isCoverOnly,
            hasSubtitle: hasSubtitle,
            isTvOverride: isTvOverride,
            isDesktopOverride: isDesktopOverride,
            coverAspectRatio: coverAspectRatio,
            outerItemPadding: outerItemPadding,
            addFloatingBottomInset: addFloatingBottomInset,
          );
          return GridView.builder(
            controller: controller,
            reverse: reverse,
            physics: physics,
            shrinkWrap: shrinkWrap,
            padding: paddingOverride ?? spec.padding,
            gridDelegate: spec.toSliverDelegate(),
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          );
        },
      ),
    );
  }
}

/// Responsive cover grid skeleton aligned with [Mv2AdaptiveGridSpec].
class Mv2AdaptiveGridSkeleton extends StatefulWidget {
  const Mv2AdaptiveGridSkeleton({
    super.key,
    this.gridSize,
    this.isComfortableGrid = false,
    this.isCoverOnly = false,
    this.itemCount = 12,
    this.isTvOverride,
    this.isDesktopOverride,
  });

  final int? gridSize;
  final bool isComfortableGrid;
  final bool isCoverOnly;
  final int itemCount;
  final bool? isTvOverride;
  final bool? isDesktopOverride;

  @override
  State<Mv2AdaptiveGridSkeleton> createState() =>
      _Mv2AdaptiveGridSkeletonState();
}

class _Mv2AdaptiveGridSkeletonState extends State<Mv2AdaptiveGridSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: Mv2Motion.ambient,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = context.mv2.color.fg;
    return Mv2AdaptiveGrid(
      itemCount: widget.itemCount,
      gridSize: widget.gridSize,
      isComfortableGrid: widget.isComfortableGrid,
      isCoverOnly: widget.isCoverOnly,
      isTvOverride: widget.isTvOverride,
      isDesktopOverride: widget.isDesktopOverride,
      itemBuilder: (_, _) => AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final tint = fg.withValues(alpha: Mv2Alphas.tint * (1 + _pulse.value));
          return Padding(
            padding: const EdgeInsets.all(Mv2Space.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(Mv2Shape.cover),
                    ),
                  ),
                ),
                if (widget.isComfortableGrid && !widget.isCoverOnly) ...[
                  const SizedBox(height: Mv2Space.s8),
                  FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: 0.72,
                    child: SizedBox(
                      height: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: tint,
                          borderRadius: BorderRadius.circular(Mv2Shape.badge),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// New Version rounded, collapsible navigation rail with pill selection indicator
/// and high-contrast TV D-pad focus highlight + scale pop.
class Mv2AdaptiveRail extends StatefulWidget {
  const Mv2AdaptiveRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.onDestinationDoubleTap,
    this.expanded,
    this.initialExpanded = false,
    this.onExpandedChanged,
    this.showCollapseButton = true,
    this.hideNavigation = false,
    this.isTvOverride,
    this.tvRailBadgeText = 'BETA',
    this.leading,
    this.footer,
    this.itemFocusNodes,
    this.toggleFocusNode,
    this.collapsedWidth,
    this.expandedWidth,
    this.showFocusHighlight,
  });

  final List<Mv2NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final ValueChanged<int>? onDestinationDoubleTap;
  final bool? expanded;
  final bool initialExpanded;
  final ValueChanged<bool>? onExpandedChanged;
  final bool showCollapseButton;
  final bool hideNavigation;
  final bool? isTvOverride;
  final String tvRailBadgeText;
  final Widget? leading;
  final Widget? footer;
  final List<FocusNode>? itemFocusNodes;
  final FocusNode? toggleFocusNode;
  final double? collapsedWidth;
  final double? expandedWidth;
  final bool? showFocusHighlight;

  @override
  State<Mv2AdaptiveRail> createState() => _Mv2AdaptiveRailState();
}

class _Mv2AdaptiveRailState extends State<Mv2AdaptiveRail> {
  static const Duration _doubleTapWindow = Duration(milliseconds: 450);

  late bool _internalExpanded = widget.initialExpanded;
  int? _lastTapIndex;
  DateTime? _lastTapTime;

  bool get _isTv => widget.isTvOverride ?? isTv;
  bool get _isExpanded => widget.expanded ?? _internalExpanded;

  void _toggleExpanded() {
    final next = !_isExpanded;
    if (widget.expanded == null) {
      setState(() => _internalExpanded = next);
    }
    widget.onExpandedChanged?.call(next);
  }

  void _handleDestinationTap(int index) {
    final now = DateTime.now();
    final isDoubleTap = index == _lastTapIndex &&
        _lastTapTime != null &&
        now.difference(_lastTapTime!) < _doubleTapWindow;
    if (isDoubleTap && widget.onDestinationDoubleTap != null) {
      _lastTapIndex = null;
      _lastTapTime = null;
      widget.onDestinationDoubleTap!(index);
      return;
    }
    _lastTapIndex = index;
    _lastTapTime = now;
    widget.onDestinationSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.destinations.isEmpty) return const SizedBox.shrink();

    final tokens = context.mv2;
    final c = tokens.color;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final motion = Mv2Motion.of(context, Mv2Motion.standard);
    final clampedIndex =
        widget.selectedIndex.clamp(0, widget.destinations.length - 1);

    final compactW = widget.collapsedWidth ??
        (_isTv
            ? Mv2Adaptive.collapsedTvRailWidth
            : Mv2Adaptive.collapsedRailWidth);
    final wideW = widget.expandedWidth ??
        (_isTv
            ? Mv2Adaptive.expandedTvRailWidth
            : Mv2Adaptive.expandedRailWidth);

    final targetPanelWidth = _isExpanded ? wideW : compactW;
    const outerStart = Mv2Space.s8;
    const outerEnd = Mv2Space.s4;
    const outerV = Mv2Space.s8;
    final totalTargetWidth =
        widget.hideNavigation ? 0.0 : targetPanelWidth + outerStart + outerEnd;

    final railBg = theme.navigationRailTheme.backgroundColor ?? c.ink1;
    final customIndicator = theme.navigationRailTheme.indicatorColor;
    final pillColor = customIndicator ??
        (light ? scheme.primaryContainer : scheme.secondaryContainer);
    final selectedFg = customIndicator != null
        ? (theme.navigationRailTheme.selectedIconTheme?.color ?? c.fg)
        : (light ? scheme.onPrimaryContainer : scheme.onSecondaryContainer);
    final radius = BorderRadius.circular(Mv2Shape.sheet);

    final Widget railPanel = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        outerStart,
        outerV,
        outerEnd,
        outerV,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: c.hairline, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: light ? 0.08 : 0.24),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: LiquidGlassBar(
            area: 'rail',
            child: ColoredBox(
              color: railBg,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showRow = constraints.maxWidth >= 148.0;
                  return FocusTraversalGroup(
                    policy: OrderedTraversalPolicy(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.leading != null)
                          widget.leading!
                        else if (_isTv)
                          _Mv2AdaptiveTvHeader(
                            badgeText: widget.tvRailBadgeText,
                            expanded: showRow,
                          ),
                        if (widget.showCollapseButton)
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              Mv2Space.s8,
                              _isTv ? Mv2Space.s4 : Mv2Space.s12,
                              Mv2Space.s8,
                              Mv2Space.s4,
                            ),
                            child: FocusTraversalOrder(
                              order: const NumericFocusOrder(0),
                              child: _Mv2RailCollapseButton(
                                focusNode: widget.toggleFocusNode,
                                expanded: _isExpanded,
                                showLabel: showRow,
                                isTv: _isTv,
                                showFocusHighlight: widget.showFocusHighlight,
                                onTap: _toggleExpanded,
                              ),
                            ),
                          ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, listConstraints) =>
                                SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Mv2Space.s8,
                                vertical: Mv2Space.s8,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: math.max(
                                    0.0,
                                    listConstraints.maxHeight - Mv2Space.s16,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: _isTv
                                      ? MainAxisAlignment.center
                                      : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    for (var i = 0;
                                        i < widget.destinations.length;
                                        i++) ...[
                                      if (i > 0)
                                        SizedBox(
                                          height: _isTv
                                              ? Mv2Space.s8
                                              : Mv2Space.s4,
                                        ),
                                      FocusTraversalOrder(
                                        order: NumericFocusOrder((i + 1).toDouble()),
                                        child: _Mv2AdaptiveRailItem(
                                          destination: widget.destinations[i],
                                          selected: i == clampedIndex,
                                          expanded: showRow,
                                          isTv: _isTv,
                                          pillColor: pillColor,
                                          selectedFg: selectedFg,
                                          focusNode: (widget.itemFocusNodes != null &&
                                                  i < widget.itemFocusNodes!.length)
                                              ? widget.itemFocusNodes![i]
                                              : null,
                                          autofocus: _isTv &&
                                              !widget.hideNavigation &&
                                              i == clampedIndex,
                                          showFocusHighlight:
                                              widget.showFocusHighlight,
                                          onTap: () => _handleDestinationTap(i),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (widget.footer != null)
                          Padding(
                            padding: const EdgeInsets.all(Mv2Space.s8),
                            child: widget.footer!,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    final fullPanelW = targetPanelWidth + outerStart + outerEnd;
    final minStableW = compactW + outerStart + outerEnd;

    return Semantics(
      label: tr('Thanh điều hướng'),
      container: true,
      child: AnimatedContainer(
        duration: motion,
        curve: Mv2Motion.standardCurve,
        width: totalTargetWidth,
        child: ExcludeFocus(
          excluding: widget.hideNavigation,
          child: ClipRect(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= minStableW) {
                  return railPanel;
                }
                return OverflowBox(
                  alignment: AlignmentDirectional.centerStart,
                  minWidth: fullPanelW,
                  maxWidth: fullPanelW,
                  child: SizedBox(width: fullPanelW, child: railPanel),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Mv2AdaptiveTvHeader extends StatelessWidget {
  const _Mv2AdaptiveTvHeader({
    required this.badgeText,
    required this.expanded,
  });

  final String badgeText;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final tokens = context.mv2;
    final accent = tokens.color.accentInk;
    final glyph = Image.asset(
      appIconAssets[2],
      width: 28,
      height: 28,
      color: accent,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => Icon(
        Icons.tv_rounded,
        size: 28,
        color: accent,
      ),
    );
    final badge = badgeText.isEmpty
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Mv2Space.s8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(Mv2Shape.cover),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: accent,
                fontSize: tokens.text.badge.fontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Mv2Space.s12,
        Mv2Space.s12,
        Mv2Space.s12,
        Mv2Space.s4,
      ),
      child: expanded
          ? Row(
              children: [
                glyph,
                const SizedBox(width: Mv2Space.s8),
                Expanded(
                  child: Text(
                    'YomiHub',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tokens.text.section.copyWith(
                      color: tokens.color.fg,
                    ),
                  ),
                ),
                if (badge != null) badge,
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                glyph,
                if (badge != null) ...[
                  const SizedBox(height: Mv2Space.s4),
                  badge,
                ],
              ],
            ),
    );
  }
}

class _Mv2RailCollapseButton extends StatefulWidget {
  const _Mv2RailCollapseButton({
    required this.expanded,
    required this.showLabel,
    required this.isTv,
    required this.onTap,
    this.focusNode,
    this.showFocusHighlight,
  });

  final bool expanded;
  final bool showLabel;
  final bool isTv;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final bool? showFocusHighlight;

  @override
  State<_Mv2RailCollapseButton> createState() => _Mv2RailCollapseButtonState();
}

class _Mv2RailCollapseButtonState extends State<_Mv2RailCollapseButton> {
  bool _focused = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlightChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightChanged);
    super.dispose();
  }

  void _onHighlightChanged(FocusHighlightMode mode) {
    if (!widget.isTv &&
        widget.showFocusHighlight != true &&
        mode != FocusHighlightMode.traditional &&
        _focused) {
      setState(() => _focused = false);
    }
  }

  void _onFocusChange(bool hasFocus) {
    final show = hasFocus &&
        (widget.isTv ||
            widget.showFocusHighlight == true ||
            FocusManager.instance.highlightMode ==
                FocusHighlightMode.traditional);
    if (mounted && show != _focused) {
      setState(() => _focused = show);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.mv2;
    final c = tokens.color;
    final motion = Mv2Motion.of(context, Mv2Motion.fast);
    final label = widget.expanded
        ? tr('Thu gọn thanh bên')
        : tr('Mở rộng thanh bên');
    final pop = _focused ? (widget.isTv ? 1.05 : 1.02) : 1.0;
    final borderWidth = widget.isTv ? 3.0 : 2.0;
    final ringColor = Mv2Adaptive.focusRingColor(context);

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            focusNode: widget.focusNode,
            onTap: widget.onTap,
            onFocusChange: _onFocusChange,
            onHover: (h) {
              if (mounted && h != _hovered) setState(() => _hovered = h);
            },
            borderRadius: BorderRadius.circular(Mv2Shape.pill),
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            child: AnimatedContainer(
              duration: motion,
              curve: Mv2Motion.standardCurve,
              height: widget.isTv ? 44 : 38,
              padding: EdgeInsets.symmetric(
                horizontal: widget.showLabel ? Mv2Space.s12 : Mv2Space.s8,
              ),
              transform: Matrix4.identity()..scaleByDouble(pop, pop, pop, 1.0),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                color: _focused
                    ? c.accent.withValues(alpha: Mv2Alphas.focus)
                    : _hovered
                        ? c.fg.withValues(alpha: Mv2Alphas.tint)
                        : c.ink2,
                borderRadius: BorderRadius.circular(Mv2Shape.pill),
                border: Border.all(
                  color: _focused ? ringColor : Colors.transparent,
                  width: borderWidth,
                ),
              ),
              child: Row(
                mainAxisAlignment: widget.showLabel
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.expanded
                        ? Icons.menu_open_rounded
                        : Icons.menu_rounded,
                    size: widget.isTv ? 22 : 20,
                    color: _focused ? ringColor : c.fg,
                  ),
                  if (widget.showLabel) ...[
                    const SizedBox(width: Mv2Space.s8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tokens.text.meta.copyWith(
                          color: _focused ? c.fg : c.fgMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Mv2AdaptiveRailItem extends StatefulWidget {
  const _Mv2AdaptiveRailItem({
    required this.destination,
    required this.selected,
    required this.expanded,
    required this.isTv,
    required this.pillColor,
    required this.selectedFg,
    required this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.showFocusHighlight,
  });

  final Mv2NavDestination destination;
  final bool selected;
  final bool expanded;
  final bool isTv;
  final Color pillColor;
  final Color selectedFg;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool? showFocusHighlight;

  @override
  State<_Mv2AdaptiveRailItem> createState() => _Mv2AdaptiveRailItemState();
}

class _Mv2AdaptiveRailItemState extends State<_Mv2AdaptiveRailItem> {
  bool _focused = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlightChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightChanged);
    super.dispose();
  }

  void _onHighlightChanged(FocusHighlightMode mode) {
    if (!widget.isTv &&
        widget.showFocusHighlight != true &&
        mode != FocusHighlightMode.traditional &&
        _focused) {
      setState(() => _focused = false);
    }
  }

  void _onFocusChange(bool hasFocus) {
    final show = hasFocus &&
        (widget.isTv ||
            widget.showFocusHighlight == true ||
            FocusManager.instance.highlightMode ==
                FocusHighlightMode.traditional);
    if (mounted && show != _focused) {
      setState(() => _focused = show);
    }
    if (hasFocus && context.mounted && Scrollable.maybeOf(context) != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: Mv2Motion.of(context, Mv2Motion.fast),
        curve: Mv2Motion.standardCurve,
      );
    }
  }

  static String _singleLineLabel(String raw) =>
      raw.replaceAll('-\n', '').replaceAll('\n', ' ');

  @override
  Widget build(BuildContext context) {
    final tokens = context.mv2;
    final c = tokens.color;
    final motion = Mv2Motion.of(context, Mv2Motion.fast);
    final d = widget.destination;
    final ringColor = Mv2Adaptive.focusRingColor(context);
    final borderWidth = widget.isTv ? 3.0 : 2.0;
    final pop = _focused ? (widget.isTv ? 1.06 : 1.02) : 1.0;

    final rawIcon = widget.selected ? (d.selectedIcon ?? d.icon) : d.icon;
    final badgedIcon = d.badgeCount > 0
        ? Badge.count(count: d.badgeCount, child: rawIcon)
        : rawIcon;
    final iconColor = widget.selected ? widget.selectedFg : c.fgMuted;
    final iconSize = widget.isTv ? 26.0 : 22.0;

    final themedIcon = IconTheme(
      data: IconThemeData(color: iconColor, size: iconSize),
      child: badgedIcon,
    );

    final focusShadows = (_focused && widget.isTv)
        ? [
            BoxShadow(
              color: ringColor.withValues(alpha: 0.36),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ]
        : null;

    final tooltipMsg = (d.tooltip != null && d.tooltip!.isNotEmpty)
        ? d.tooltip!
        : (widget.expanded ? '' : d.label);

    Widget content;
    if (widget.expanded) {
      content = AnimatedContainer(
        duration: motion,
        curve: Mv2Motion.standardCurve,
        height: widget.isTv ? 54.0 : 46.0,
        padding: const EdgeInsets.symmetric(horizontal: Mv2Space.s12),
        transform: Matrix4.identity()..scaleByDouble(pop, pop, pop, 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.selected
              ? widget.pillColor
              : _focused
                  ? c.accent.withValues(alpha: Mv2Alphas.focus)
                  : _hovered
                      ? c.fg.withValues(alpha: Mv2Alphas.tint)
                      : Colors.transparent,
          borderRadius: BorderRadius.circular(Mv2Shape.pill),
          border: Border.all(
            color: _focused ? ringColor : Colors.transparent,
            width: borderWidth,
          ),
          boxShadow: focusShadows,
        ),
        child: Row(
          children: [
            themedIcon,
            const SizedBox(width: Mv2Space.s12),
            Expanded(
              child: Text(
                _singleLineLabel(d.label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tokens.text.row.copyWith(
                  color: widget.selected ? widget.selectedFg : c.fg,
                  fontWeight:
                      widget.selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      content = AnimatedContainer(
        duration: motion,
        curve: Mv2Motion.standardCurve,
        padding: const EdgeInsets.symmetric(
          horizontal: Mv2Space.s4,
          vertical: Mv2Space.s8,
        ),
        transform: Matrix4.identity()..scaleByDouble(pop, pop, pop, 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: _focused
              ? c.accent.withValues(alpha: Mv2Alphas.focus)
              : _hovered && !widget.selected
                  ? c.fg.withValues(alpha: Mv2Alphas.tint)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(Mv2Shape.sheet),
          border: Border.all(
            color: _focused ? ringColor : Colors.transparent,
            width: borderWidth,
          ),
          boxShadow: focusShadows,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: motion,
              curve: Mv2Motion.standardCurve,
              width: widget.isTv ? 62.0 : 54.0,
              height: widget.isTv ? 36.0 : 32.0,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.selected ? widget.pillColor : Colors.transparent,
                borderRadius: BorderRadius.circular(Mv2Shape.pill),
              ),
              child: themedIcon,
            ),
            const SizedBox(height: Mv2Space.s4),
            Text(
              d.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: tokens.text.meta.copyWith(
                color: widget.selected ? c.fg : c.fgMuted,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final itemRadius =
        BorderRadius.circular(widget.expanded ? Mv2Shape.pill : Mv2Shape.sheet);

    return Tooltip(
      message: tooltipMsg,
      child: Semantics(
        label: _singleLineLabel(d.label),
        selected: widget.selected,
        button: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            onTap: widget.onTap,
            onFocusChange: _onFocusChange,
            onHover: (h) {
              if (mounted && h != _hovered) setState(() => _hovered = h);
            },
            borderRadius: itemRadius,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Complete adaptive navigation shell for YomiHub New Version.
///
/// Uses [Mv2AdaptiveRail] with separate rail/content [FocusScopeNode]s and
/// smooth D-pad traversal on wide screens (`>= 600 dp`), Windows, and Android TV;
/// falls back to [Mv2NavShell] (floating capsule bar) on compact mobile screens.
class Mv2AdaptiveNavShell extends StatefulWidget {
  const Mv2AdaptiveNavShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
    this.onDestinationDoubleTap,
    this.topBanner,
    this.groupTabs = const [],
    this.selectedGroupTabId,
    this.onGroupTabSelected,
    this.useFloatingBar = true,
    this.hideNavigation = false,
    this.initialExpanded = false,
    this.expanded,
    this.onExpandedChanged,
    this.showCollapseButton = true,
    this.isTvOverride,
    this.isDesktopOverride,
    this.enableDpadNavigation,
    this.tvRailBadgeText = 'BETA',
    this.railLeading,
    this.railFooter,
    this.showFocusHighlight,
  });

  final List<Mv2NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final ValueChanged<int>? onDestinationDoubleTap;
  final Widget child;
  final Widget? topBanner;
  final List<Mv2NavGroupTab> groupTabs;
  final String? selectedGroupTabId;
  final ValueChanged<String>? onGroupTabSelected;
  final bool useFloatingBar;
  final bool hideNavigation;
  final bool initialExpanded;
  final bool? expanded;
  final ValueChanged<bool>? onExpandedChanged;
  final bool showCollapseButton;
  final bool? isTvOverride;
  final bool? isDesktopOverride;
  final bool? enableDpadNavigation;
  final String tvRailBadgeText;
  final Widget? railLeading;
  final Widget? railFooter;
  final bool? showFocusHighlight;

  @override
  State<Mv2AdaptiveNavShell> createState() => _Mv2AdaptiveNavShellState();
}

class _Mv2AdaptiveNavShellState extends State<Mv2AdaptiveNavShell> {
  final FocusScopeNode _railScope = FocusScopeNode(
    debugLabel: 'mv2AdaptiveRailScope',
  );
  final FocusScopeNode _contentScope = FocusScopeNode(
    debugLabel: 'mv2AdaptiveContentScope',
  );
  final List<FocusNode> _itemFocusNodes = [];
  final List<FocusNode> _retiredFocusNodes = [];
  bool _didAutofocusRail = false;

  bool get _isTv => widget.isTvOverride ?? isTv;

  void _syncItemNodes(int count) {
    while (_itemFocusNodes.length < count) {
      _itemFocusNodes.add(
        FocusNode(debugLabel: 'mv2AdaptiveRailItem${_itemFocusNodes.length}'),
      );
    }
    while (_itemFocusNodes.length > count) {
      _retiredFocusNodes.add(_itemFocusNodes.removeLast());
    }
    if (_retiredFocusNodes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final node in _retiredFocusNodes) {
          node.dispose();
        }
        _retiredFocusNodes.clear();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _syncItemNodes(widget.destinations.length);
  }

  @override
  void didUpdateWidget(Mv2AdaptiveNavShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.destinations.length != _itemFocusNodes.length) {
      _syncItemNodes(widget.destinations.length);
    }
  }

  @override
  void dispose() {
    for (final node in _itemFocusNodes) {
      node.dispose();
    }
    _itemFocusNodes.clear();
    for (final node in _retiredFocusNodes) {
      node.dispose();
    }
    _retiredFocusNodes.clear();
    _railScope.dispose();
    _contentScope.dispose();
    super.dispose();
  }

  void _focusActiveRailItem(int clampedIndex) {
    if (clampedIndex >= 0 && clampedIndex < _itemFocusNodes.length) {
      _itemFocusNodes[clampedIndex].requestFocus();
    } else {
      _railScope.requestFocus();
    }
  }

  void _focusContent() {
    if (_contentScope.focusedChild != null) {
      _contentScope.requestFocus();
      return;
    }
    _contentScope.requestFocus();
    final descendants = _contentScope.traversalDescendants;
    if (descendants.isNotEmpty) {
      descendants.first.requestFocus();
    }
  }

  KeyEventResult _handleDpadKey(
    BuildContext context,
    KeyEvent event, {
    required bool railVisible,
    required int clampedIndex,
  }) {
    if (!railVisible) return KeyEventResult.ignored;
    final bridgeActive = widget.enableDpadNavigation ?? _isTv;
    if (!bridgeActive) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final primary = FocusManager.instance.primaryFocus;
    if (!_isTv && primary?.context?.widget is EditableText) {
      return KeyEventResult.ignored;
    }

    final rtl = Directionality.of(context) == TextDirection.rtl;
    final toRailKey =
        rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft;
    final toContentKey =
        rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight;
    final toRailDirection =
        rtl ? TraversalDirection.right : TraversalDirection.left;

    final key = event.logicalKey;
    if (key == toRailKey) {
      if (_railScope.hasFocus) return KeyEventResult.ignored;
      final moved = primary?.focusInDirection(toRailDirection) ?? false;
      if (!moved) {
        _focusActiveRailItem(clampedIndex);
      }
      return KeyEventResult.handled;
    }
    if (key == toContentKey && _railScope.hasFocus) {
      _focusContent();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final useRail = Mv2Adaptive.shouldUseRail(
      context,
      isTvOverride: widget.isTvOverride,
      isDesktopOverride: widget.isDesktopOverride,
    );

    if (!useRail) {
      return Mv2NavShell(
        destinations: widget.destinations,
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: widget.onDestinationSelected,
        onDestinationDoubleTap: widget.onDestinationDoubleTap,
        topBanner: widget.topBanner,
        groupTabs: widget.groupTabs,
        selectedGroupTabId: widget.selectedGroupTabId,
        onGroupTabSelected: widget.onGroupTabSelected,
        useFloatingBar: widget.useFloatingBar,
        showRailOverride: false,
        isTvOverride: widget.isTvOverride,
        hideNavigation: widget.hideNavigation,
        tvRailBadgeText: widget.tvRailBadgeText,
        child: widget.child,
      );
    }

    final clampedIndex = widget.destinations.isEmpty
        ? 0
        : widget.selectedIndex.clamp(0, widget.destinations.length - 1);
    final railVisible = !widget.hideNavigation && widget.destinations.isNotEmpty;

    if (_isTv && railVisible && !_didAutofocusRail) {
      _didAutofocusRail = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusActiveRailItem(clampedIndex);
      });
    }

    Widget bodyContent = widget.child;
    if (widget.groupTabs.length >= 2 &&
        widget.selectedGroupTabId != null &&
        widget.onGroupTabSelected != null &&
        !widget.hideNavigation) {
      bodyContent = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Mv2Space.s16,
              Mv2Space.s4,
              Mv2Space.s16,
              Mv2Space.s8,
            ),
            child: Mv2SegmentedControl<String>(
              segments: [
                for (final t in widget.groupTabs)
                  Mv2Segment<String>(
                    value: t.id,
                    label: t.label,
                    icon: t.icon,
                    selectedIcon: t.selectedIcon,
                    badge: t.badgeCount,
                  ),
              ],
              selected: widget.selectedGroupTabId!,
              onSelected: widget.onGroupTabSelected!,
            ),
          ),
          Expanded(child: bodyContent),
        ],
      );
    }

    final Widget rail = FocusScope(
      node: _railScope,
      child: Mv2AdaptiveRail(
        destinations: widget.destinations,
        selectedIndex: clampedIndex,
        onDestinationSelected: widget.onDestinationSelected,
        onDestinationDoubleTap: widget.onDestinationDoubleTap,
        expanded: widget.expanded,
        initialExpanded: widget.initialExpanded,
        onExpandedChanged: widget.onExpandedChanged,
        showCollapseButton: widget.showCollapseButton,
        hideNavigation: widget.hideNavigation,
        isTvOverride: widget.isTvOverride,
        tvRailBadgeText: widget.tvRailBadgeText,
        leading: widget.railLeading,
        footer: widget.railFooter,
        itemFocusNodes: _itemFocusNodes,
        showFocusHighlight: widget.showFocusHighlight,
      ),
    );

    final Widget content = FocusScope(
      node: _contentScope,
      child: bodyContent,
    );

    final Widget row = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) => _handleDpadKey(
        context,
        event,
        railVisible: railVisible,
        clampedIndex: clampedIndex,
      ),
      child: Row(
        children: [
          rail,
          Expanded(child: content),
        ],
      ),
    );

    return Mv2FloatingNavScope(
      enabled: false,
      child: Column(
        children: [
          if (widget.topBanner != null) widget.topBanner!,
          Expanded(
            child: Scaffold(
              body: row,
            ),
          ),
        ],
      ),
    );
  }
}
