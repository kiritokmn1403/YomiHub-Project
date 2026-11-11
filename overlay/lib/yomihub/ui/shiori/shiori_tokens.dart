// Shiori Design Tokens for YomiHub (Mangayomi v0.9.95 Shiori Design Language)
// Based on packages/shiori/lib/src/tokens.dart & alphas.dart (Apache-2.0 / MIT)
import 'package:flutter/material.dart';

/// Spacing on a 4 point grid.
abstract final class ShioriSpace {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
}

/// Corner radii tokens.
abstract final class ShioriShape {
  /// Pills and badges.
  static const double badge = 4;

  /// Covers: rounded without losing the rectangular look of a book.
  static const double cover = 6;

  /// Cards, dialogues, and text fields.
  static const double card = 12;

  /// Sheets and floating panels.
  static const double sheet = 20;

  /// Capsule buttons and floating navigation pill.
  static const double pill = 999;
}

/// Animation durations and easing curves.
abstract final class ShioriMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 220);
  static const Duration enter = Duration(milliseconds: 350);
  static const Duration exitSlow = Duration(milliseconds: 500);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve enterCurve = Curves.easeOutQuart;
  static const Curve exitCurve = Curves.easeInCubic;

  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false
          ? Duration.zero
          : duration;
}

/// Opacity values for layered UI washes and borders.
abstract final class ShioriAlphas {
  static const double tint = 0.08;
  static const double hairline = 0.16;
  static const double focus = 0.14;
  static const double accentTint = 0.16;
  static const double secondary = 0.70;
  static const double tvFocus = 0.45;
  static const double disabled = 0.38;
  static const double chrome = 0.92;
}

/// Standard 2:3 aspect ratio for comic, novel, and anime covers.
const double kShioriCoverAspect = 2 / 3;

/// Status indicators in the Shiori system.
enum ShioriStatusKind {
  unread,
  downloaded,
  read,
  offline,
  completed,
  newChapter,
  error,
}

@immutable
class ShioriStatus {
  const ShioriStatus(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

/// Color system of Shiori for both Dark and Light themes.
@immutable
class ShioriColors {
  const ShioriColors({
    required this.ink0,
    required this.ink1,
    required this.ink2,
    required this.ink3,
    required this.fg,
    required this.fgMuted,
    required this.hairline,
    required this.accent,
    required this.onAccent,
    required this.unread,
    required this.downloaded,
    required this.offline,
    required this.completed,
    required this.read,
    required this.newChapter,
    required this.error,
  });

  final Color ink0;
  final Color ink1;
  final Color ink2;
  final Color ink3;
  final Color fg;
  final Color fgMuted;
  final Color hairline;
  final Color accent;
  final Color onAccent;

  final ShioriStatus unread;
  final ShioriStatus downloaded;
  final ShioriStatus offline;
  final ShioriStatus completed;
  final ShioriStatus read;
  final ShioriStatus newChapter;
  final ShioriStatus error;

  static Color onFill(Color fill) {
    return fill.computeLuminance() > 0.45
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
  }

  factory ShioriColors.fromTheme(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final onAccent = onFill(accent);

    if (isDark) {
      return ShioriColors(
        ink0: const Color(0xFF0F1016),
        ink1: const Color(0xFF171823),
        ink2: const Color(0xFF20212F),
        ink3: const Color(0xFF292A3A),
        fg: const Color(0xFFECEDF5),
        fgMuted: const Color(0xFFA3A5B8),
        hairline: const Color(0xFF2F3142),
        accent: accent,
        onAccent: onAccent,
        unread: ShioriStatus(accent, onAccent),
        downloaded: const ShioriStatus(Color(0xFF00897B), Color(0xFFFFFFFF)),
        offline: const ShioriStatus(Color(0xFFE65100), Color(0xFFFFFFFF)),
        completed: const ShioriStatus(Color(0xFF2E7D32), Color(0xFFFFFFFF)),
        read: const ShioriStatus(Color(0xFF37474F), Color(0xFFCFD8DC)),
        newChapter: const ShioriStatus(Color(0xFF1E88E5), Color(0xFFFFFFFF)),
        error: const ShioriStatus(Color(0xFFC62828), Color(0xFFFFFFFF)),
      );
    } else {
      return ShioriColors(
        ink0: const Color(0xFFF6F6F9),
        ink1: const Color(0xFFECECF2),
        ink2: const Color(0xFFE5E6EE),
        ink3: const Color(0xFFDEDFE8),
        fg: const Color(0xFF15161D),
        fgMuted: const Color(0xFF4B4D5C),
        hairline: const Color(0xFFC6C8D4),
        accent: accent,
        onAccent: onAccent,
        unread: ShioriStatus(accent, onAccent),
        downloaded: const ShioriStatus(Color(0xFF4DB6AC), Color(0xFF004D40)),
        offline: const ShioriStatus(Color(0xFFFFB74D), Color(0xFFE65100)),
        completed: const ShioriStatus(Color(0xFF81C784), Color(0xFF1B5E20)),
        read: const ShioriStatus(Color(0xFFCFD8DC), Color(0xFF455A64)),
        newChapter: const ShioriStatus(Color(0xFF64B5F6), Color(0xFF0D47A1)),
        error: const ShioriStatus(Color(0xFFE57373), Color(0xFFB71C1C)),
      );
    }
  }

  ShioriStatus statusFor(ShioriStatusKind kind) => switch (kind) {
    ShioriStatusKind.unread => unread,
    ShioriStatusKind.downloaded => downloaded,
    ShioriStatusKind.offline => offline,
    ShioriStatusKind.completed => completed,
    ShioriStatusKind.read => read,
    ShioriStatusKind.newChapter => newChapter,
    ShioriStatusKind.error => error,
  };
}

