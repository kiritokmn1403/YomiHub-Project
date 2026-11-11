// Shiori Floating Navigation Bar for YomiHub (Mangayomi v0.9.95)
// Inspired by lib/modules/widgets/floating_nav_bar.dart (Apache-2.0 / MIT)
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/ui/liquid_glass.dart';
import 'package:mangayomi/yomihub/ui/shiori/shiori_tokens.dart';

/// One destination for [ShioriFloatingNavBar].
class ShioriNavDestination {
  final Widget icon;
  final Widget? selectedIcon;
  final String label;
  final Widget? badge;
  final String? tooltip;

  const ShioriNavDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.badge,
    this.tooltip,
  });
}

/// A floating capsule navigation bar conforming to the Shiori design language.
/// Floats above the content with smooth pill highlight animations,
/// glassmorphism blur backdrop, and full D-pad/keyboard accessibility.
class ShioriFloatingNavBar extends StatefulWidget {
  const ShioriFloatingNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.showLabels = true,
    this.elevation = 8.0,
    this.height = 58.0,
    this.maxWidth = 520.0,
  });

  final List<ShioriNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool showLabels;
  final double elevation;
  final double height;
  final double maxWidth;

  @override
  State<ShioriFloatingNavBar> createState() => _ShioriFloatingNavBarState();
}

class _ShioriFloatingNavBarState extends State<ShioriFloatingNavBar> {
  @override
  Widget build(BuildContext context) {
    if (widget.destinations.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? const Color(0xFF14151E).withValues(alpha: 0.88)
        : const Color(0xFFF0F1F6).withValues(alpha: 0.90);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final barWidth = availableWidth > widget.maxWidth ? widget.maxWidth : availableWidth - 32;

        // R25: heightFactor 1 — in Scaffold.bottomNavigationBar a plain Center
        // takes the whole height, centring the bar and zeroing the body.
        return Center(
          heightFactor: 1,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
            child: SizedBox(
              width: barWidth,
              height: widget.height,
              child: LiquidGlassBar(
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(ShioriShape.pill),
                    border: Border.all(color: borderColor, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(ShioriShape.pill),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Row(
                        children: [
                          for (int i = 0; i < widget.destinations.length; i++)
                            Expanded(
                              child: _buildNavItem(
                                index: i,
                                destination: widget.destinations[i],
                                isSelected: i == widget.selectedIndex,
                                scheme: scheme,
                                isDark: isDark,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required ShioriNavDestination destination,
    required bool isSelected,
    required ColorScheme scheme,
    required bool isDark,
  }) {
    final activeColor = scheme.primary;
    final inactiveColor = isDark
        ? const Color(0xFFA0A3B5)
        : const Color(0xFF5A5C6A);

    return Semantics(
      selected: isSelected,
      label: destination.label,
      button: true,
      child: Tooltip(
        message: destination.tooltip ?? destination.label,
        child: InkWell(
          key: ValueKey('shioriNav_${destination.label}'),
          onTap: () => widget.onDestinationSelected(index),
          borderRadius: BorderRadius.circular(ShioriShape.pill),
          focusColor: activeColor.withValues(alpha: 0.25),
          hoverColor: activeColor.withValues(alpha: 0.08),
          child: Center(
            child: AnimatedContainer(
              duration: ShioriMotion.standard,
              curve: ShioriMotion.standardCurve,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: ShioriAlphas.accentTint)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(ShioriShape.pill),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconTheme(
                        data: IconThemeData(
                          color: isSelected ? activeColor : inactiveColor,
                          size: 22,
                        ),
                        child: isSelected
                            ? (destination.selectedIcon ?? destination.icon)
                            : destination.icon,
                      ),
                      if (destination.badge != null)
                        Positioned(
                          right: -8,
                          top: -4,
                          child: destination.badge!,
                        ),
                    ],
                  ),
                  if (widget.showLabels) ...[
                    const SizedBox(height: 2),
                    Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? activeColor : inactiveColor,
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
