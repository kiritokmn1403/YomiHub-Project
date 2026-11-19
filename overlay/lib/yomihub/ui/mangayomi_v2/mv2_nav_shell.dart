// YomiHub New Version (Mangayomi v0.9.96) Adaptive Navigation Shell.
// Includes Windows/Desktop NavigationRail, Android TV D-pad FocusScopes,
// Mobile Floating Glass Capsule Bar (drag-to-switch + scroll-shrink),
// fallback Material 3 NavigationBar, and Group Segmented Switcher.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangayomi/utils/constant.dart';
import 'package:mangayomi/utils/platform_utils.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/ui/liquid_glass.dart';

import 'mv2_theme.dart';

/// Destination entry for [Mv2NavShell].
class Mv2NavDestination {
  const Mv2NavDestination({
    required this.id,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badgeCount = 0,
    this.tooltip,
  });

  final String id;
  final String label;
  final Widget icon;
  final Widget? selectedIcon;
  final int badgeCount;
  final String? tooltip;
}

/// Sub-tab entry shown inside [Mv2SegmentedControl] above a grouped screen.
class Mv2NavGroupTab {
  const Mv2NavGroupTab({
    required this.id,
    required this.label,
    this.icon,
    this.selectedIcon,
    this.badgeCount = 0,
  });

  final String id;
  final String label;
  final IconData? icon;
  final IconData? selectedIcon;
  final int badgeCount;
}

/// Pure state machine deciding when the floating bar shrinks on scroll.
class Mv2NavShrink {
  static const double downTrigger = 90.0;
  static const double upRelease = 40.0;

  double _run = 0;
  bool _shrunk = false;

  bool get shrunk => _shrunk;

  bool update(double delta) {
    if (delta == 0) return false;
    if (_run != 0 && (delta < 0) != (_run < 0)) _run = 0;
    _run += delta;

    if (!_shrunk && _run >= downTrigger) {
      _shrunk = true;
      _run = 0;
      return true;
    }
    if (_shrunk && _run <= -upRelease) {
      _shrunk = false;
      _run = 0;
      return true;
    }
    return false;
  }

  bool reset() {
    _run = 0;
    if (!_shrunk) return false;
    _shrunk = false;
    return true;
  }
}

/// Shares whether the shell currently floats its mobile bottom bar.
class Mv2FloatingNavScope extends InheritedWidget {
  const Mv2FloatingNavScope({
    super.key,
    required this.enabled,
    required super.child,
  });

  final bool enabled;

  static bool enabledOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<Mv2FloatingNavScope>()
          ?.enabled ??
      false;

  @override
  bool updateShouldNotify(Mv2FloatingNavScope oldWidget) =>
      enabled != oldWidget.enabled;
}

/// Gives [child] back the bottom inset consumed by a Scaffold's bottom bar.
class Mv2RestoreBottomPadding extends StatelessWidget {
  const Mv2RestoreBottomPadding({
    super.key,
    required this.bottom,
    required this.child,
  });

  final double bottom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    return MediaQuery(
      data: data.copyWith(padding: data.padding.copyWith(bottom: bottom)),
      child: child,
    );
  }
}

/// Adaptive navigation shell for YomiHub New Version (0.9.96).
///
/// - **Android TV**: centred [NavigationRail] with separate [FocusScopeNode]s
///   for rail vs content (`ArrowLeft`/`ArrowRight` traversal) and branded TV header.
/// - **Windows / Wide Screen (`shortestSide >= 600`)**: [NavigationRail] with
///   Liquid Glass support when floating bar is off.
/// - **Mobile / Compact**: [Mv2FloatingNavBar] frosted draggable capsule (or M3
///   [NavigationBar] when [useFloatingBar] is false).
class Mv2NavShell extends StatefulWidget {
  const Mv2NavShell({
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
    this.showRailOverride,
    this.isTvOverride,
    this.hideNavigation = false,
    this.enableShrinkOnScroll = true,
    this.tvRailBadgeText = 'BETA',
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
  final bool? showRailOverride;
  final bool? isTvOverride;
  final bool hideNavigation;
  final bool enableShrinkOnScroll;
  final String tvRailBadgeText;

  @override
  State<Mv2NavShell> createState() => _Mv2NavShellState();
}

class _Mv2NavShellState extends State<Mv2NavShell> {
  final FocusScopeNode _railScope = FocusScopeNode(debugLabel: 'mv2RailScope');
  final FocusScopeNode _contentScope = FocusScopeNode(
    debugLabel: 'mv2ContentScope',
  );
  final Mv2NavShrink _navShrink = Mv2NavShrink();

  bool _didAutofocusRail = false;
  int? _lastTapIndex;
  DateTime? _lastTapTime;

  static const Duration _doubleTapWindow = Duration(milliseconds: 450);

  bool get _isTv => widget.isTvOverride ?? isTv;

  @override
  void dispose() {
    _railScope.dispose();
    _contentScope.dispose();
    super.dispose();
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

  bool _onPageScroll(
    ScrollNotification notification, {
    required bool floatingActive,
  }) {
    if (!floatingActive ||
        !widget.enableShrinkOnScroll ||
        notification.metrics.axis != Axis.vertical) {
      return false;
    }
    var changed = false;
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      if (metrics.maxScrollExtent <= 0 ||
          metrics.pixels <= metrics.minScrollExtent) {
        changed = _navShrink.reset();
      } else {
        changed = _navShrink.update(notification.scrollDelta ?? 0);
      }
    }
    if (changed && mounted) setState(() {});
    return false;
  }

  void _wakeNav() {
    if (_navShrink.reset() && mounted) setState(() {});
  }

  KeyEventResult _handleTvKey(KeyEvent event, bool railVisible) {
    if (!railVisible) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (_railScope.hasFocus) return KeyEventResult.ignored;
      final current = FocusManager.instance.primaryFocus;
      final moved = current?.focusInDirection(TraversalDirection.left) ?? false;
      if (!moved) _railScope.requestFocus();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight && _railScope.hasFocus) {
      _contentScope.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.shortestSide >= 600;
    final canFloat = !_isTv && widget.useFloatingBar && !isDesktop;
    final useRail =
        widget.showRailOverride ?? (_isTv || (!canFloat && isWide));
    final floatingActive = !useRail && !_isTv && widget.useFloatingBar;
    final hasEnoughDest = widget.destinations.length >= 2;
    final clampedIndex = widget.destinations.isEmpty
        ? 0
        : widget.selectedIndex.clamp(0, widget.destinations.length - 1);

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

    if (useRail && hasEnoughDest) {
      bodyContent = _buildRailLayout(
        context,
        bodyContent: bodyContent,
        clampedIndex: clampedIndex,
      );
    }

    final Widget? bottomBar = (!useRail && hasEnoughDest && !widget.hideNavigation)
        ? (floatingActive
            ? Mv2FloatingNavBar(
                destinations: widget.destinations,
                currentIndex: clampedIndex,
                onSelected: _handleDestinationTap,
                showLabels: size.width > size.height,
                shrink: _navShrink.shrunk ? 1.0 : 0.0,
                onWake: _wakeNav,
              )
            : _buildDockedMobileBar(context, clampedIndex))
        : null;

    return Mv2FloatingNavScope(
      enabled: floatingActive && !widget.hideNavigation,
      child: Column(
        children: [
          if (widget.topBanner != null) widget.topBanner!,
          Expanded(
            child: Scaffold(
              extendBody: floatingActive && !widget.hideNavigation,
              body: NotificationListener<ScrollNotification>(
                onNotification: (n) =>
                    _onPageScroll(n, floatingActive: floatingActive),
                child: bodyContent,
              ),
              bottomNavigationBar: bottomBar,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRailLayout(
    BuildContext context, {
    required Widget bodyContent,
    required int clampedIndex,
  }) {
    final tokens = context.mv2;
    final c = tokens.color;
    final scheme = Theme.of(context).colorScheme;
    final railVisible = !widget.hideNavigation;
    final railWidth = railVisible ? 100.0 : 0.0;

    if (_isTv && railVisible && !_didAutofocusRail) {
      _didAutofocusRail = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _railScope.requestFocus();
      });
    }

    Widget rail = Semantics(
      label: tr('Thanh điều hướng'),
      child: NavigationRail(
        labelType: NavigationRailLabelType.all,
        useIndicator: true,
        groupAlignment: _isTv ? 0.0 : null,
        leading: _isTv ? _Mv2TvRailHeader(badgeText: widget.tvRailBadgeText) : null,
        selectedIconTheme: _isTv
            ? IconThemeData(size: 28, color: scheme.onSecondaryContainer)
            : null,
        unselectedIconTheme:
            _isTv ? IconThemeData(size: 28, color: c.fgMuted) : null,
        selectedLabelTextStyle: _isTv
            ? TextStyle(
                fontSize: tokens.text.meta.fontSize,
                fontWeight: FontWeight.w600,
                color: c.fg,
              )
            : null,
        unselectedLabelTextStyle: _isTv
            ? TextStyle(
                fontSize: tokens.text.meta.fontSize,
                color: c.fgMuted,
              )
            : null,
        selectedIndex: clampedIndex,
        onDestinationSelected: _handleDestinationTap,
        destinations: [
          for (final d in widget.destinations)
            NavigationRailDestination(
              padding: _isTv
                  ? const EdgeInsets.symmetric(vertical: Mv2Space.s8)
                  : null,
              icon: _withBadge(d.icon, d.badgeCount, tooltip: d.tooltip),
              selectedIcon: _withBadge(
                d.selectedIcon ?? d.icon,
                d.badgeCount,
                tooltip: d.tooltip,
              ),
              label: Padding(
                padding: const EdgeInsets.only(top: Mv2Space.s4),
                child: Text(d.label, textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );

    if (_isTv) {
      rail = FocusScope(node: _railScope, child: rail);
    }

    Widget content = bodyContent;
    if (_isTv) {
      content = FocusScope(node: _contentScope, child: content);
    }

    Widget row = Row(
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: _isTv ? 220 : 0),
          curve: Mv2Motion.standardCurve,
          width: railWidth,
          child: ClipRect(
            child: OverflowBox(
              alignment: AlignmentDirectional.centerStart,
              minWidth: 0,
              maxWidth: 100,
              child: SizedBox(
                width: 100,
                child: NavigationRailTheme(
                  data: NavigationRailThemeData(
                    indicatorShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Mv2Shape.sheet),
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      focusColor: _isTv
                          ? c.accent.withValues(alpha: Mv2Alphas.tvFocus)
                          : Theme.of(context).focusColor,
                    ),
                    child: LiquidGlassBar(area: 'rail', child: rail),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(child: content),
      ],
    );

    if (_isTv) {
      row = Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) => _handleTvKey(event, railVisible),
        child: row,
      );
    }
    return row;
  }

  Widget _buildDockedMobileBar(BuildContext context, int clampedIndex) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: Theme.of(context).navigationBarTheme.backgroundColor,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(overflow: TextOverflow.ellipsis),
        ),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Mv2Shape.sheet),
        ),
      ),
      child: LiquidGlassBar(
        child: NavigationBar(
          animationDuration: Mv2Motion.exitSlow,
          selectedIndex: clampedIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: _handleDestinationTap,
          destinations: [
            for (final d in widget.destinations)
              NavigationDestination(
                icon: _withBadge(d.icon, d.badgeCount),
                selectedIcon: _withBadge(d.selectedIcon ?? d.icon, d.badgeCount),
                label: d.label,
                tooltip: d.tooltip ?? '',
              ),
          ],
        ),
      ),
    );
  }

  Widget _withBadge(Widget icon, int count, {String? tooltip}) {
    final badged = count > 0
        ? Badge.count(count: count, child: icon)
        : icon;
    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(message: tooltip, child: badged);
    }
    return badged;
  }
}

class _Mv2TvRailHeader extends StatelessWidget {
  const _Mv2TvRailHeader({required this.badgeText});

  final String badgeText;

  @override
  Widget build(BuildContext context) {
    final tokens = context.mv2;
    final accent = tokens.color.accentInk;
    return Padding(
      padding: const EdgeInsets.only(top: Mv2Space.s12, bottom: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            appIconAssets[2],
            width: 30,
            height: 30,
            color: accent,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => Icon(
              Icons.tv_rounded,
              size: 28,
              color: accent,
            ),
          ),
          if (badgeText.isNotEmpty) ...[
            const SizedBox(height: Mv2Space.s8),
            Container(
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
            ),
          ],
        ],
      ),
    );
  }
}

/// Floating frosted-glass capsule navigation bar from Mangayomi 0.9.96.
///
/// Supports drag-to-select, pointer velocity stretch, specular glass edge,
/// landscape inline labels, and scroll-driven shrink.
class Mv2FloatingNavBar extends StatefulWidget {
  const Mv2FloatingNavBar({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
    this.showLabels = false,
    this.shrink = 0.0,
    this.onWake,
  });

  final List<Mv2NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final bool showLabels;
  final double shrink;
  final VoidCallback? onWake;

  static const Duration duration = Mv2Motion.standard;
  static const Curve curve = Mv2Motion.standardCurve;
  static const Duration _shrinkDuration = Mv2Motion.exitSlow;
  static const Duration _shrinkReleaseDuration = Mv2Motion.standard;
  static const Curve _shrinkCurve = Curves.easeOutQuart;

  static const int _comfortableCount = 5;
  static const double _shrinkScale = 0.14;
  static const double _fullHeight = 56.0;
  static const double _shrinkPerExtra = 3.0;
  static const double _minHeight = 44.0;
  static const double _iconRatio = 27 / _fullHeight;
  static const double _labelGap = 6.0;
  static const double _itemSpacing = 20.0;
  static const double _pillPad = 9.0;
  static const double _shortViewport = 480.0;
  static const double _shortViewportTrim = 6.0;
  static const double _pillInset = 5.0;
  static const double _pillSlotInset = 1.5;
  static const double _speedStretch = 0.9;
  static const double _maxSpeedStretch = 24.0;
  static const double _margin = 20.0;
  static const double _dragZoom = 1.035;
  static const double _barGive = 0.05;
  static const double _pillZoom = 1.04;

  static double heightFor(int destinationCount, {double viewportHeight = 0}) {
    final crowding =
        math.max(0, destinationCount - _comfortableCount) * _shrinkPerExtra;
    final landscape = viewportHeight > 0 && viewportHeight < _shortViewport
        ? _shortViewportTrim
        : 0.0;
    return math.max(_minHeight, _fullHeight - crowding - landscape);
  }

  @override
  State<Mv2FloatingNavBar> createState() => _Mv2FloatingNavBarState();
}

class _Mv2FloatingNavBarState extends State<Mv2FloatingNavBar> {
  double? _dragX;
  double _stretch = 0;
  bool _tapped = false;
  Timer? _tapTimer;
  bool _catchingUp = false;
  Timer? _catchUpTimer;

  double _slot = 0;
  double _barWidth = 0;
  double _edgePush = 0;
  int? _droppedIndex;

  List<double> _slotL = const [];
  List<double> _slotR = const [];
  List<GlobalKey> _itemKeys = const [];
  final GlobalKey _interiorKey = GlobalKey();

  double _slotStart(int i) => i < _slotL.length ? _slotL[i] : 0;
  double _slotEnd(int i) => i < _slotR.length ? _slotR[i] : _barWidth;
  double _slotWidth(int i) => _slotEnd(i) - _slotStart(i);

  void _syncKeys(int count) {
    if (_itemKeys.length != count) {
      _itemKeys = List.generate(count, (_) => GlobalKey());
    }
  }

  void _measure() {
    final box = _interiorKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      _remeasure();
      return;
    }
    final l = <double>[];
    final r = <double>[];
    for (final key in _itemKeys) {
      final item = key.currentContext?.findRenderObject();
      if (item is! RenderBox || !item.hasSize) {
        _remeasure();
        return;
      }
      final left = item.localToGlobal(Offset.zero, ancestor: box).dx;
      l.add(left - Mv2FloatingNavBar._pillPad);
      r.add(left + item.size.width + Mv2FloatingNavBar._pillPad);
    }
    if (l.isEmpty) return;

    var changed = l.length != _slotL.length || box.size.width != _barWidth;
    for (var i = 0; !changed && i < l.length; i++) {
      changed =
          (l[i] - _slotL[i]).abs() > 0.5 || (r[i] - _slotR[i]).abs() > 0.5;
    }
    if (!changed || !mounted) return;
    setState(() {
      _slotL = l;
      _slotR = r;
      _barWidth = box.size.width;
      _slot = _barWidth / math.max(1, widget.destinations.length);
    });
  }

  void _remeasure() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(Mv2FloatingNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_droppedIndex != null && widget.currentIndex == _droppedIndex) {
      _droppedIndex = null;
    }
    if (widget.currentIndex != oldWidget.currentIndex && widget.onWake != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onWake?.call());
    }
  }

  @override
  void dispose() {
    _catchUpTimer?.cancel();
    _tapTimer?.cancel();
    super.dispose();
  }

  int _slotAt(double x) {
    for (var i = 0; i < widget.destinations.length; i++) {
      if (x < _slotEnd(i)) return i;
    }
    return math.max(0, widget.destinations.length - 1);
  }

  void _flashTap() {
    _tapTimer?.cancel();
    setState(() => _tapped = true);
    _tapTimer = Timer(Mv2FloatingNavBar.duration, () {
      if (mounted) setState(() => _tapped = false);
    });
  }

  void _startDrag(double x) {
    _catchUpTimer?.cancel();
    _tapTimer?.cancel();
    final centre = _restingCentre(
      _barWidth,
      _droppedIndex ?? widget.currentIndex,
    );
    final halfPill = (_slot - Mv2FloatingNavBar._pillSlotInset * 2) / 2;
    final travels = _slot > 0 && (x - centre).abs() > halfPill;

    setState(() {
      _dragX = x;
      _stretch = 0;
      _edgePush = 0;
      _tapped = false;
      _catchingUp = travels;
    });
    if (!travels) return;
    _catchUpTimer = Timer(Mv2FloatingNavBar.duration, () {
      if (mounted) setState(() => _catchingUp = false);
    });
  }

  void _updateDrag(double x) {
    if (_dragX == null) return;
    setState(() {
      final travelled = (x - _dragX!).abs() * Mv2FloatingNavBar._speedStretch;
      _stretch = (_stretch * 0.6 + travelled * 0.4).clamp(
        0.0,
        Mv2FloatingNavBar._maxSpeedStretch,
      );
      _dragX = x;
    });
  }

  void _endDrag() {
    if (_dragX == null) return;
    final target = _slotAt(_dragX!);
    final changing = target != widget.currentIndex;
    _catchUpTimer?.cancel();
    setState(() {
      _dragX = null;
      _stretch = 0;
      _edgePush = 0;
      _catchingUp = false;
      _droppedIndex = changing ? target : null;
    });
    if (changing) widget.onSelected(target);
  }

  void _cancelDrag() {
    _catchUpTimer?.cancel();
    setState(() {
      _dragX = null;
      _stretch = 0;
      _edgePush = 0;
      _catchingUp = false;
    });
  }

  double _restingCentre(double width, int index) {
    const outer = Mv2FloatingNavBar._pillInset;
    final base = _slotWidth(index) - Mv2FloatingNavBar._pillSlotInset * 2;
    final lo = outer + base / 2;
    final hi = width - outer - base / 2;
    final centre = (_slotStart(index) + _slotEnd(index)) / 2;
    return centre.clamp(math.min(lo, hi), math.max(lo, hi));
  }

  (double, double) _pillEdges(double width, int index) {
    const outer = Mv2FloatingNavBar._pillInset;
    final over = _dragX == null ? index : _slotAt(_dragX!);
    final base = math.max(
      0.0,
      _slotWidth(over) - Mv2FloatingNavBar._pillSlotInset * 2,
    );

    double centreFor(double wanted, double pillWidth) {
      final lo = outer + pillWidth / 2;
      final hi = width - outer - pillWidth / 2;
      return wanted.clamp(math.min(lo, hi), math.max(lo, hi));
    }

    if (_dragX == null) {
      final centre = _restingCentre(width, index);
      return (centre - base / 2, centre + base / 2);
    }

    final pillWidth = math.min(base + _stretch, math.max(0.0, width - outer * 2));
    final centre = centreFor(_dragX!, pillWidth);
    _edgePush = ((_dragX! - centre) / 60).clamp(-1.0, 1.0);
    return (centre - pillWidth / 2, centre + pillWidth / 2);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.destinations.isEmpty) return const SizedBox.shrink();
    final height = Mv2FloatingNavBar.heightFor(
      widget.destinations.length,
      viewportHeight: MediaQuery.sizeOf(context).height,
    );
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottom = math.max(8.0, safeBottom - 12);

    return Semantics(
      label: tr('Thanh điều hướng'),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Mv2FloatingNavBar._margin,
          0,
          Mv2FloatingNavBar._margin,
          bottom,
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: widget.shrink.clamp(0.0, 1.0)),
          duration: widget.shrink > 0
              ? Mv2FloatingNavBar._shrinkDuration
              : Mv2FloatingNavBar._shrinkReleaseDuration,
          curve: Mv2FloatingNavBar._shrinkCurve,
          builder: (context, shrink, child) => Transform.scale(
            scale: 1 - shrink * Mv2FloatingNavBar._shrinkScale,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
          child: widget.showLabels
              ? Align(
                  alignment: Alignment.bottomCenter,
                  heightFactor: 1,
                  child: IntrinsicWidth(child: _bar(context, height, null)),
                )
              : LayoutBuilder(
                  builder: (context, outer) =>
                      _bar(context, height, outer.maxWidth),
                ),
        ),
      ),
    );
  }

  Widget _bar(BuildContext context, double height, double? fixedWidth) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final tokens = context.mv2;
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          fontSize: tokens.text.meta.fontSize,
          fontWeight: FontWeight.w600,
        );
    final dragging = _dragX != null;
    final lifted = dragging || _tapped;
    final barColor = light
        ? scheme.surfaceContainerHigh.withValues(alpha: 0.98)
        : scheme.surface.withValues(alpha: 0.62);
    final pillColor = light
        ? (dragging
            ? Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.08),
                scheme.primaryContainer,
              )
            : scheme.primaryContainer)
        : scheme.secondaryContainer.withValues(alpha: dragging ? 1.0 : 0.9);

    return AnimatedScale(
      duration: Mv2FloatingNavBar.duration,
      curve: Mv2FloatingNavBar.curve,
      scale: lifted ? Mv2FloatingNavBar._dragZoom : 1.0,
      alignment: Alignment.bottomCenter,
      child: Transform.scale(
        scaleX: 1 + (dragging ? _edgePush.abs() * Mv2FloatingNavBar._barGive : 0.0),
        scaleY: 1,
        alignment: _edgePush < 0 ? Alignment.centerRight : Alignment.centerLeft,
        child: SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              boxShadow: [
                BoxShadow(
                  color: (light ? scheme.shadow : Colors.black).withValues(
                    alpha: light ? 0.18 : 0.34,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(height / 2),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                    child: Builder(
                      builder: (context) {
                        final count = widget.destinations.length;
                        final resting = (_droppedIndex ?? widget.currentIndex)
                            .clamp(0, count - 1);
                        _syncKeys(count);

                        final width = fixedWidth ?? _barWidth;
                        if (!widget.showLabels && fixedWidth != null) {
                          const gap = Mv2FloatingNavBar._pillSlotInset;
                          _slotL = [
                            for (var i = 0; i < count; i++)
                              width / count * i + gap,
                          ];
                          _slotR = [
                            for (var i = 1; i <= count; i++)
                              width / count * i - gap,
                          ];
                          _barWidth = width;
                          _slot = width / count;
                        } else {
                          _remeasure();
                        }
                        final slot = _slot;
                        final (left, right) = _pillEdges(width, resting);
                        final pillW = math.max(0.0, right - left);

                        return Listener(
                          onPointerDown: (_) => widget.onWake?.call(),
                          behavior: HitTestBehavior.translucent,
                          child: GestureDetector(
                            onHorizontalDragStart: (d) =>
                                _startDrag(d.localPosition.dx),
                            onHorizontalDragUpdate: (d) =>
                                _updateDrag(d.localPosition.dx),
                            onHorizontalDragEnd: (_) => _endDrag(),
                            onHorizontalDragCancel: _cancelDrag,
                            child: Stack(
                              key: _interiorKey,
                              alignment: Alignment.centerLeft,
                              children: [
                                if (pillW > 0)
                                  AnimatedPositioned(
                                    duration: dragging && !_catchingUp
                                        ? Duration.zero
                                        : Mv2FloatingNavBar.duration,
                                    curve: Mv2FloatingNavBar.curve,
                                    left: left,
                                    width: pillW,
                                    top: Mv2FloatingNavBar._pillInset,
                                    bottom: Mv2FloatingNavBar._pillInset,
                                    child: AnimatedScale(
                                      duration: Mv2FloatingNavBar.duration,
                                      curve: Mv2FloatingNavBar.curve,
                                      scale: lifted
                                          ? Mv2FloatingNavBar._pillZoom
                                          : 1.0,
                                      child: AnimatedContainer(
                                        duration: Mv2FloatingNavBar.duration,
                                        curve: Mv2FloatingNavBar.curve,
                                        decoration: ShapeDecoration(
                                          color: pillColor,
                                          shape: const StadiumBorder(),
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: _Mv2FloatingNavGlassEdge(
                                      color: light
                                          ? scheme.outline
                                          : scheme.onSurface,
                                      light: light,
                                      radius: height / 2,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: widget.showLabels
                                        ? Mv2FloatingNavBar._itemSpacing
                                        : 0,
                                  ),
                                  child: Row(
                                    mainAxisSize: widget.showLabels
                                        ? MainAxisSize.min
                                        : MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: widget.showLabels
                                        ? Mv2FloatingNavBar._itemSpacing
                                        : 0,
                                    children: [
                                      for (var i = 0; i < count; i++)
                                        _Mv2FloatingNavSized(
                                          key: _itemKeys[i],
                                          expand: !widget.showLabels,
                                          child: _Mv2FloatingNavItem(
                                            destination: widget.destinations[i],
                                            selected: i == resting,
                                            iconSize: height *
                                                Mv2FloatingNavBar._iconRatio,
                                            label: widget.showLabels
                                                ? widget.destinations[i].label
                                                : null,
                                            labelStyle: labelStyle,
                                            light: light,
                                            nudge: widget.showLabels || slot <= 0
                                                ? 0
                                                : _restingCentre(width, i) -
                                                    slot * (i + 0.5),
                                            onTap: () {
                                              _flashTap();
                                              widget.onSelected(i);
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Mv2FloatingNavSized extends StatelessWidget {
  const _Mv2FloatingNavSized({
    super.key,
    required this.expand,
    required this.child,
  });

  final bool expand;
  final Widget child;

  @override
  Widget build(BuildContext context) => expand ? Expanded(child: child) : child;
}

class _Mv2FloatingNavItem extends StatelessWidget {
  const _Mv2FloatingNavItem({
    required this.destination,
    required this.selected,
    required this.iconSize,
    required this.nudge,
    required this.onTap,
    required this.light,
    this.label,
    this.labelStyle,
  });

  final Mv2NavDestination destination;
  final bool selected;
  final double iconSize;
  final double nudge;
  final VoidCallback onTap;
  final bool light;
  final String? label;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rawIcon = selected
        ? (destination.selectedIcon ?? destination.icon)
        : destination.icon;
    final icon = destination.badgeCount > 0
        ? Badge.count(count: destination.badgeCount, child: rawIcon)
        : rawIcon;
    final color = light
        ? (selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant)
        : (selected ? scheme.onSecondaryContainer : scheme.onSurface);

    Widget themedItem(double size, Color resolvedColor) => IconTheme(
          data: IconThemeData(
            size: size,
            color: resolvedColor,
            shadows: selected
                ? [Shadow(color: resolvedColor, blurRadius: 0.9)]
                : null,
          ),
          child: label == null
              ? icon
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(width: Mv2FloatingNavBar._labelGap),
                    Flexible(
                      child: Text(
                        label!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle?.copyWith(color: resolvedColor),
                      ),
                    ),
                  ],
                ),
        );

    return Semantics(
      label: destination.label,
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Transform.translate(
            offset: Offset(nudge, 0),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: iconSize),
              duration: Mv2FloatingNavBar.duration,
              curve: Mv2FloatingNavBar.curve,
              builder: (context, size, _) => TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: color),
                duration: Mv2FloatingNavBar.duration,
                curve: Mv2FloatingNavBar.curve,
                builder: (context, animatedColor, _) =>
                    themedItem(size, animatedColor ?? color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Mv2FloatingNavGlassEdge extends StatelessWidget {
  const _Mv2FloatingNavGlassEdge({
    required this.color,
    required this.light,
    required this.radius,
  });

  final Color color;
  final bool light;
  final double radius;

  static const double _strokeWidth = 1.0;
  static const List<double> _stops = [
    0.0,
    0.13,
    0.27,
    0.44,
    0.58,
    0.71,
    0.86,
    1.0,
  ];
  static const List<double> _alphas = [
    1.0,
    0.42,
    0.92,
    0.34,
    0.86,
    0.38,
    0.98,
    0.50,
  ];

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          for (final a in _alphas) Colors.white.withValues(alpha: a),
        ],
        stops: _stops,
      ).createShader(rect),
      child: CustomPaint(
        painter: _Mv2FloatingNavGlassEdgePainter(
          color: color,
          light: light,
          radius: radius,
        ),
      ),
    );
  }
}

class _Mv2FloatingNavGlassEdgePainter extends CustomPainter {
  const _Mv2FloatingNavGlassEdgePainter({
    required this.color,
    required this.light,
    required this.radius,
  });

  final Color color;
  final bool light;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _Mv2FloatingNavGlassEdge._strokeWidth
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: light ? 0.34 : 0.36),
          color.withValues(alpha: light ? 0.08 : 0.07),
          color.withValues(alpha: light ? 0.20 : 0.18),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(_Mv2FloatingNavGlassEdge._strokeWidth / 2),
        Radius.circular(radius),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_Mv2FloatingNavGlassEdgePainter old) =>
      old.color != color || old.light != light || old.radius != radius;
}

/// Sliding-pill segmented switcher matching 0.9.96 `ShioriSegmentedControl`.
class Mv2Segment<T> {
  const Mv2Segment({
    required this.value,
    required this.label,
    this.icon,
    this.selectedIcon,
    this.badge = 0,
  });

  final T value;
  final String label;
  final IconData? icon;
  final IconData? selectedIcon;
  final int badge;
}

class Mv2SegmentedControl<T> extends StatelessWidget {
  const Mv2SegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelected,
  });

  final List<Mv2Segment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();
    final tokens = context.mv2;
    final c = tokens.color;
    final motion = Mv2Motion.of(context, Mv2Motion.fast);
    final index = segments.indexWhere((s) => s.value == selected);
    final count = segments.length;

    return Container(
      padding: const EdgeInsets.all(Mv2Space.s4 - 1),
      decoration: BoxDecoration(
        color: c.ink2,
        borderRadius: BorderRadius.circular(Mv2Shape.pill),
      ),
      child: Stack(
        children: [
          if (index >= 0)
            Positioned.fill(
              child: AnimatedAlign(
                duration: motion,
                curve: Mv2Motion.standardCurve,
                alignment: AlignmentDirectional(
                  count == 1 ? 0.0 : -1.0 + 2.0 * index / (count - 1),
                  0.0,
                ),
                child: FractionallySizedBox(
                  widthFactor: 1.0 / count,
                  heightFactor: 1.0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.ink3,
                      borderRadius: BorderRadius.circular(Mv2Shape.pill),
                    ),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              for (final segment in segments)
                Expanded(
                  child: _Mv2SegmentItem<T>(
                    segment: segment,
                    selected: segment.value == selected,
                    motion: motion,
                    onTap: () {
                      if (segment.value != selected) onSelected(segment.value);
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Mv2SegmentItem<T> extends StatelessWidget {
  const _Mv2SegmentItem({
    required this.segment,
    required this.selected,
    required this.motion,
    required this.onTap,
  });

  final Mv2Segment<T> segment;
  final bool selected;
  final Duration motion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.mv2;
    final c = tokens.color;
    final fg = selected ? c.fg : c.fgMuted;
    final height = tokens.density.minTarget - (Mv2Space.s4 - 1) * 2;
    final icon = selected
        ? (segment.selectedIcon ?? segment.icon)
        : segment.icon;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Mv2Shape.pill),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: Mv2Space.s8),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: Mv2Space.s4,
              children: [
                if (icon != null)
                  Icon(icon, size: tokens.scaled(16), color: fg),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: motion,
                    curve: Mv2Motion.standardCurve,
                    style: tokens.text.row.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    child: Text(
                      segment.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (segment.badge > 0)
                  Text(
                    '${segment.badge}',
                    style: tokens.text.badge.copyWith(color: c.accentInk),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
