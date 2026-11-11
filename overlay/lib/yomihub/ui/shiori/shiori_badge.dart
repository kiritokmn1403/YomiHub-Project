// Shiori Badge for YomiHub (Mangayomi v0.9.95)
// Inspired by packages/shiori/lib/src/components/badge.dart
import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/ui/shiori/shiori_tokens.dart';

/// A filled pill badge for status, unread chapters, or episode counts.
class ShioriBadge extends StatelessWidget {
  const ShioriBadge({
    super.key,
    required this.count,
    this.kind = ShioriStatusKind.unread,
    this.max = 999,
    this.label,
  });

  final int count;
  final ShioriStatusKind kind;
  final int max;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (count <= 0 && label == null) return const SizedBox.shrink();

    final colors = ShioriColors.fromTheme(Theme.of(context));
    final status = colors.statusFor(kind);
    final text = label ?? (count > max ? '$max+' : '$count');

    return Semantics(
      container: true,
      label: text,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
        decoration: BoxDecoration(
          color: status.background,
          borderRadius: BorderRadius.circular(ShioriShape.badge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          text,
          maxLines: 1,
          style: TextStyle(
            color: status.foreground,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

