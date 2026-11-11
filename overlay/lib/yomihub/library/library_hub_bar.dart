import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/library/side_swipe.dart';
import 'package:mangayomi/yomihub/ui/shiori/shiori_tokens.dart';

/// One sub-tab of "Thư Viện".
class LibraryHubTab {
  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const LibraryHubTab({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

/// YomiHub 0.5.6: the strip of library sub-tabs shown above the library
/// screens. Every tab is an [InkWell], so it takes D-pad focus on Android
/// TV / keyboard focus on Windows and shows the usual focus highlight.
///
/// [pill] draws the selected tab as a filled pill (Mangayomi layout)
/// instead of an underlined tab (classic layout).
class LibraryHubTabBar extends StatelessWidget {
  final List<LibraryHubTab> tabs;
  final String? current;
  final ValueChanged<String> onSelect;
  final bool pill;
  const LibraryHubTabBar({
    super.key,
    required this.tabs,
    required this.current,
    required this.onSelect,
    this.pill = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 46,
          margin: pill ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4) : null,
          decoration: pill
              ? BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(ShioriShape.pill),
                )
              : null,
          child: Row(
            children: [
              for (final t in tabs)
                Expanded(child: _tab(context, scheme, t, t.route == current)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    ColorScheme scheme,
    LibraryHubTab t,
    bool selected,
  ) {
    final fg = selected
        ? (pill ? scheme.primary : scheme.primary)
        : scheme.onSurfaceVariant;
    final radius = BorderRadius.circular(pill ? ShioriShape.pill : 8);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pill ? 3 : 0, vertical: pill ? 3 : 0),
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          key: ValueKey('libraryHubTab${t.route}'),
          borderRadius: radius,
          focusColor: scheme.primary.withValues(alpha: 0.30),
          onTap: () => onSelect(t.route),
          child: AnimatedContainer(
            duration: ShioriMotion.standard,
            curve: ShioriMotion.standardCurve,
            decoration: BoxDecoration(
              color: (pill && selected)
                  ? scheme.primary.withValues(alpha: ShioriAlphas.accentTint)
                  : Colors.transparent,
              borderRadius: pill ? radius : null,
              border: pill
                  ? (selected
                      ? Border.all(color: scheme.primary.withValues(alpha: 0.30), width: 1.0)
                      : null)
                  : Border(
                      bottom: BorderSide(
                        width: 3,
                        color: selected ? scheme.primary : Colors.transparent,
                      ),
                    ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(selected ? t.selectedIcon : t.icon, size: 19, color: fg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    t.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The content area of the main shell: the strip of library sub-tabs above
/// [child] and the sideways swipe between them. Same on phones, tablets and
/// desktop, in the classic and the modern layout ([pill]); only [stripTabs]
/// (empty = no strip) and [swipe] (off on TV: the D-pad uses the strip)
/// differ. The Column keeps the same shape with or without the strip so the
/// routed pages keep their state.
class YomiHubShell extends StatelessWidget {
  final List<String> stripTabs;
  final String? location;
  final bool pill;
  final bool swipe;
  final LibraryHubTab Function(String route) tabFor;
  final void Function(String route) onGo;
  final Widget child;
  const YomiHubShell({
    super.key,
    required this.stripTabs,
    required this.location,
    required this.pill,
    required this.swipe,
    required this.tabFor,
    required this.onGo,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final showStrip = stripTabs.isNotEmpty;
    final (prev, next) = swipe
        ? sideSwipeNeighbours(stripTabs, location)
        : (null, null);
    return Column(
      children: [
        if (showStrip)
          LibraryHubTabBar(
            tabs: [for (final t in stripTabs) tabFor(t)],
            current: location,
            pill: pill,
            onSelect: (r) {
              if (r != location) onGo(r);
            },
          )
        else
          const SizedBox.shrink(),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: showStrip,
            child: YomiSideSwipe(
              onNext: next == null ? null : () => onGo(next),
              onPrevious: prev == null ? null : () => onGo(prev),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
