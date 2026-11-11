// Shiori Theme Adapter for YomiHub (Mangayomi v0.9.95)
import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/ui/shiori/shiori_tokens.dart';
import 'package:mangayomi/yomihub/ui/ui_style.dart';

extension ShioriContextExtension on BuildContext {
  /// Whether the modern Shiori design system is currently active.
  bool get isShiori => YomiUi.isModern;

  /// Shiori colors resolved against the current theme.
  ShioriColors get shioriColors => ShioriColors.fromTheme(Theme.of(this));
}

/// Shiori UI Theme helper
class ShioriTheme {
  ShioriTheme._();

  /// Returns card decoration conforming to Shiori design language.
  static BoxDecoration cardDecoration({
    required BuildContext context,
    Color? color,
    BorderRadius? borderRadius,
    bool elevated = true,
  }) {
    final colors = context.shioriColors;
    final r = borderRadius ?? BorderRadius.circular(ShioriShape.card);
    return BoxDecoration(
      color: color ?? colors.ink1,
      borderRadius: r,
      border: Border.all(
        color: colors.hairline.withValues(alpha: ShioriAlphas.hairline),
        width: 1,
      ),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  /// Returns floating pill decoration for Shiori navigation bars and tags.
  static BoxDecoration pillDecoration({
    required BuildContext context,
    Color? color,
    Color? borderColor,
  }) {
    final colors = context.shioriColors;
    return BoxDecoration(
      color: color ?? colors.ink1,
      borderRadius: BorderRadius.circular(ShioriShape.pill),
      border: Border.all(
        color: borderColor ?? colors.hairline.withValues(alpha: ShioriAlphas.hairline),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

