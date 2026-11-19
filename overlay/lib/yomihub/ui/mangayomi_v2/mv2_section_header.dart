// YomiHub New Version (Mangayomi v0.9.96) Section Headers & Collapsing Titles.
// Adapted for Flutter 3.47.6 without package:material_ui or package:shiori.
import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

import 'mv2_theme.dart';

/// Section heading inside a screen (e.g. "Chapters · 127", "CONTINUE READING").
class Mv2SectionHeader extends StatelessWidget {
  const Mv2SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.count,
    this.overline = false,
    this.actionLabel,
    this.onAction,
    this.actionBusy = false,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(
      Mv2Space.s16,
      Mv2Space.s16,
      Mv2Space.s8,
      Mv2Space.s8,
    ),
  });

  final String title;
  final String? subtitle;
  final int? count;
  final bool overline;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool actionBusy;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.mv2;
    final c = tokens.color;
    final style = overline
        ? tokens.groupLabel
        : tokens.text.section.copyWith(color: c.fg);
    final displayTitle = overline ? title.toUpperCase() : title;
    final hasAction = actionBusy || (actionLabel != null && onAction != null);

    var resolved = padding.resolve(Directionality.of(context));
    if (hasAction) {
      final line = (style.fontSize ?? 14) * (style.height ?? 1.2);
      final excess = ((tokens.density.minTarget - line) / 2).clamp(
        0.0,
        double.infinity,
      );
      resolved = resolved.copyWith(
        top: (resolved.top - excess).clamp(0.0, double.infinity),
        bottom: (resolved.bottom - excess).clamp(0.0, double.infinity),
      );
    }

    Widget content = Padding(
      padding: resolved,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text.rich(
                    TextSpan(
                      text: displayTitle,
                      children: [
                        if (count != null)
                          TextSpan(
                            text: ' · $count',
                            style: TextStyle(
                              color: c.fgMuted,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                      ],
                    ),
                    style: style,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tokens.caption,
                  ),
                ],
              ],
            ),
          ),
          if (hasAction)
            TextButton(
              onPressed: actionBusy ? null : onAction,
              style: TextButton.styleFrom(
                alignment: AlignmentDirectional.centerEnd,
                foregroundColor: c.accentInk,
                textStyle: tokens.text.meta.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: actionBusy
                  ? Semantics(
                      label: tr('Đang tải'),
                      child: SizedBox.square(
                        dimension: tokens.scaled(16),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.accentInk,
                        ),
                      ),
                    )
                  : Text(actionLabel!),
            )
          else if (trailing != null)
            trailing!,
        ],
      ),
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Mv2Shape.card),
        child: content,
      );
    }

    return content;
  }
}

/// Uppercase overline label used above settings groups and shelves.
class Mv2GroupLabel extends StatelessWidget {
  const Mv2GroupLabel(this.title, {super.key, this.maxLines = 1});

  final String title;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        title.toUpperCase(),
        style: context.mv2.groupLabel,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Group of settings rows under an optional [Mv2GroupLabel] and footer note.
class Mv2SettingsGroup extends StatelessWidget {
  const Mv2SettingsGroup({
    super.key,
    this.title,
    required this.children,
    this.footer,
  });

  final String? title;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final tokens = context.mv2;
    return Padding(
      padding: const EdgeInsets.only(bottom: Mv2Space.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null && title!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Mv2Space.s16,
                Mv2Space.s16,
                Mv2Space.s16,
                Mv2Space.s4,
              ),
              child: Mv2GroupLabel(title!, maxLines: 2),
            ),
          ...children,
          if (footer != null && footer!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Mv2Space.s16,
                Mv2Space.s4,
                Mv2Space.s16,
                0,
              ),
              child: Text(footer!, style: tokens.caption),
            ),
        ],
      ),
    );
  }
}

/// Collapses or expands a sub-header smoothly on scroll (0.9.96 CollapsibleHeaderPart).
class Mv2CollapsibleHeaderPart extends StatelessWidget {
  const Mv2CollapsibleHeaderPart({
    super.key,
    required this.collapsed,
    required this.child,
  });

  final bool collapsed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: collapsed ? 0.0 : 1.0),
      duration: Mv2Motion.of(context, Mv2Motion.standard),
      curve: Mv2Motion.standardCurve,
      child: child,
      builder: (context, open, inner) => ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: open,
          child: Opacity(
            opacity: open,
            child: IgnorePointer(ignoring: open < 1.0, child: inner),
          ),
        ),
      ),
    );
  }
}

/// Animated screen title that swaps smoothly when the header folds (0.9.96 CollapsingTitle).
class Mv2CollapsingTitle extends StatelessWidget {
  const Mv2CollapsingTitle(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final duration = Mv2Motion.of(context, Mv2Motion.standard);
    return AnimatedSize(
      duration: duration,
      curve: Mv2Motion.standardCurve,
      alignment: AlignmentDirectional.centerStart,
      clipBehavior: Clip.none,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Mv2Motion.enterCurve,
        switchOutCurve: Mv2Motion.exitCurve,
        layoutBuilder: (current, previous) => Stack(
          clipBehavior: Clip.none,
          alignment: AlignmentDirectional.centerStart,
          children: [
            for (final child in previous)
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                child: Center(widthFactor: 1, child: child),
              ),
            if (current != null) current,
          ],
        ),
        transitionBuilder: (child, animation) {
          final incoming = child.key == ValueKey<String>(text);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, incoming ? 0.4 : -0.4),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Text(
          text,
          key: ValueKey<String>(text),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }
}
