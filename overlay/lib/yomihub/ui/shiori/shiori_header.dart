// Shiori Section Header & App Bar Header for YomiHub (Mangayomi v0.9.95)
// Inspired by packages/shiori/lib/src/components/section_header.dart
import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/ui/shiori/shiori_tokens.dart';

/// Clean, modern section header adhering to Shiori typography and spacing.
class ShioriSectionHeader extends StatelessWidget {
  const ShioriSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.trailing,
    this.onTap,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final String? badgeText;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = ShioriColors.fromTheme(theme);

    Widget header = Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: ShioriSpace.s16, vertical: ShioriSpace.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.fg,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: ShioriAlphas.accentTint),
                          borderRadius: BorderRadius.circular(ShioriShape.badge),
                        ),
                        child: Text(
                          badgeText!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: colors.fgMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );

    if (onTap != null) {
      header = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ShioriShape.card),
        child: header,
      );
    }

    return header;
  }
}

