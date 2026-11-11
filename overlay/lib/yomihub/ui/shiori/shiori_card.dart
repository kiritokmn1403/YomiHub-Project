// Shiori Card & Cover Card for YomiHub (Mangayomi v0.9.95)
// Inspired by packages/shiori/lib/src/components/cover.dart
import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/ui/shiori/shiori_badge.dart';
import 'package:mangayomi/yomihub/ui/shiori/shiori_tokens.dart';

/// General purpose Shiori-styled card container.
class ShioriCard extends StatelessWidget {
  const ShioriCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = ShioriColors.fromTheme(theme);
    final r = borderRadius ?? BorderRadius.circular(ShioriShape.card);

    Widget content = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(ShioriSpace.s16),
      decoration: BoxDecoration(
        color: color ?? colors.ink1,
        borderRadius: r,
        border: Border.all(
          color: colors.hairline.withValues(alpha: ShioriAlphas.hairline),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: r,
        child: content,
      );
    }

    return content;
  }
}

/// A media cover card (2:3 aspect ratio) with Shiori styling,
/// unread count badge, bottom reading/watching progress bar,
/// and smooth D-pad/keyboard focus highlight.
class ShioriCoverCard extends StatefulWidget {
  const ShioriCoverCard({
    super.key,
    required this.title,
    this.imageProvider,
    this.unreadCount = 0,
    this.progress = 0.0,
    this.statusKind = ShioriStatusKind.unread,
    this.onTap,
    this.onLongPress,
    this.width,
    this.height,
  });

  final String title;
  final ImageProvider? imageProvider;
  final int unreadCount;
  final double progress; // 0.0 to 1.0
  final ShioriStatusKind statusKind;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? width;
  final double? height;

  @override
  State<ShioriCoverCard> createState() => _ShioriCoverCardState();
}

class _ShioriCoverCardState extends State<ShioriCoverCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = ShioriColors.fromTheme(theme);
    final radius = BorderRadius.circular(ShioriShape.cover);

    return FocusableActionDetector(
      onFocusChange: (f) => setState(() => _isFocused = f),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: ShioriMotion.fast,
          curve: ShioriMotion.standardCurve,
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: _isFocused
                  ? colors.accent
                  : colors.hairline.withValues(alpha: ShioriAlphas.hairline),
              width: _isFocused ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isFocused ? 0.20 : 0.08),
                blurRadius: _isFocused ? 12 : 6,
                offset: Offset(0, _isFocused ? 4 : 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: AspectRatio(
              aspectRatio: kShioriCoverAspect,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover Image or Placeholder
                  if (widget.imageProvider != null)
                    Image(
                      image: widget.imageProvider!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(colors),
                    )
                  else
                    _buildPlaceholder(colors),

                  // Bottom Gradient Scrim for Title
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(6, 18, 6, 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.85),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),

                  // Reading/Watching Progress Bar
                  if (widget.progress > 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        value: widget.progress.clamp(0.0, 1.0),
                        minHeight: 3.0,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                      ),
                    ),

                  // Unread Badge Top Right
                  if (widget.unreadCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: ShioriBadge(
                        count: widget.unreadCount,
                        kind: widget.statusKind,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ShioriColors colors) {
    return Container(
      color: colors.ink2,
      padding: const EdgeInsets.all(ShioriSpace.s8),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: colors.fgMuted.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
