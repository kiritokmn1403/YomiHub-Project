// YomiHub New Version (Mangayomi v0.9.96) Cover Card, Badges & Skeleton Grid.
// Adapted for Flutter 3.47.6 without package:material_ui or package:shiori.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangayomi/utils/platform_utils.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

import 'mv2_theme.dart';

/// Two lines of 12.5 px overlay title plus its bottom padding (UI-16).
const double _kOverlayTitleClearance = 48;

/// Compact status pill used for unread counts, downloads, local/merged and language chips.
class Mv2Badge extends StatelessWidget {
  const Mv2Badge({
    super.key,
    this.count = 0,
    this.label,
    this.kind = Mv2StatusKind.unread,
    this.customTone,
    this.max = 999,
    this.strong = true,
  });

  final int count;
  final String? label;
  final Mv2StatusKind kind;
  final Mv2Status? customTone;
  final int max;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    if (count <= 0 && (label == null || label!.isEmpty)) {
      return const SizedBox.shrink();
    }
    final tokens = context.mv2;
    final tone = customTone ?? tokens.color.statusFor(kind);
    final text = (label != null && label!.isNotEmpty)
        ? label!
        : (count > max ? '$max+' : '$count');

    return Semantics(
      container: true,
      label: text,
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(minWidth: tokens.scaled(18)),
        padding: const EdgeInsets.symmetric(
          horizontal: Mv2Space.s4 + 1,
          vertical: 1.5,
        ),
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(Mv2Shape.badge),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: tokens.text.badge.copyWith(
            color: tone.foreground,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Media cover card (2:3 aspect ratio by default) styled after Mangayomi 0.9.96.
///
/// Supports comfortable vs overlay title modes, split status badges, continue-reading
/// action button, Hero transition, multi-selection veil, and TV D-pad focus + held-OK.
class Mv2MangaCard extends StatefulWidget {
  const Mv2MangaCard({
    super.key,
    required this.title,
    this.subtitle,
    this.image,
    this.unreadCount = 0,
    this.downloadedCount = 0,
    this.isLocal = false,
    this.isMerged = false,
    this.inLibrary = false,
    this.languageLabel,
    this.sourceLabel,
    this.progress = 0.0,
    this.isComfortableGrid = false,
    this.isCoverOnly = false,
    this.isSelected = false,
    this.showContinueButton = false,
    this.onContinueTap,
    this.heroTag,
    this.autofocus = false,
    this.onFocusChange,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.aspectRatio = kMv2CoverAspect,
    this.tvModeOverride,
  });

  final String title;
  final String? subtitle;
  final ImageProvider? image;
  final int unreadCount;
  final int downloadedCount;
  final bool isLocal;
  final bool isMerged;
  final bool inLibrary;
  final String? languageLabel;
  final String? sourceLabel;
  final double progress;
  final bool isComfortableGrid;
  final bool isCoverOnly;
  final bool isSelected;
  final bool showContinueButton;
  final VoidCallback? onContinueTap;
  final Object? heroTag;
  final bool autofocus;
  final ValueChanged<bool>? onFocusChange;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final double aspectRatio;
  final bool? tvModeOverride;

  @override
  State<Mv2MangaCard> createState() => _Mv2MangaCardState();
}

class _Mv2MangaCardState extends State<Mv2MangaCard> {
  bool _focused = false;
  bool _held = false;
  bool _pressed = false;

  bool get _isTv => widget.tvModeOverride ?? isTv;

  static bool _isTvSelectKey(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.gameButtonA ||
      key == LogicalKeyboardKey.space;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlightModeChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightModeChanged);
    super.dispose();
  }

  void _onHighlightModeChanged(FocusHighlightMode mode) {
    if (!_isTv && mode != FocusHighlightMode.traditional && _focused) {
      setState(() => _focused = false);
    }
  }

  void _onFocusChange(bool hasFocus) {
    widget.onFocusChange?.call(hasFocus);
    final show = hasFocus &&
        (_isTv ||
            FocusManager.instance.highlightMode ==
                FocusHighlightMode.traditional);
    if (mounted && show != _focused) {
      setState(() => _focused = show);
    }
  }

  Widget _wrapHero(Widget child) {
    final tag = widget.heroTag;
    return tag == null ? child : Hero(tag: tag, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.mv2;
    final c = tokens.color;
    final motion = Mv2Motion.of(context, Mv2Motion.fast);
    final radius = BorderRadius.circular(Mv2Shape.cover);
    final pop = _focused ? 1.06 : 1.0;

    final showTopLeftBadges = widget.inLibrary ||
        widget.isMerged ||
        widget.isLocal ||
        widget.downloadedCount > 0 ||
        widget.unreadCount > 0;

    final showOverlayTitle =
        !widget.isComfortableGrid && !widget.isCoverOnly && widget.title.isNotEmpty;
    final showBottomTitle =
        widget.isComfortableGrid && !widget.isCoverOnly && widget.title.isNotEmpty;

    final coverContent = AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: c.ink2,
              child: widget.image == null
                  ? _Mv2CoverPlaceholder(title: widget.title)
                  : Image(
                      image: widget.image!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      frameBuilder: (context, child, frame, sync) {
                        if (sync || frame != null) return child;
                        return const _Mv2PulseBox(radius: Mv2Shape.cover);
                      },
                      errorBuilder: (_, _, _) =>
                          _Mv2CoverPlaceholder(title: widget.title),
                    ),
            ),
            if (widget.inLibrary) const ColoredBox(color: Mv2Scrim.onImage),
            if (showOverlayTitle)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 70,
                  alignment: AlignmentDirectional.bottomStart,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Mv2Scrim.underText],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    Mv2Space.s8,
                    Mv2Space.s16,
                    Mv2Space.s8,
                    Mv2Space.s8,
                  ),
                  child: Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tokens.text.card.copyWith(
                      color: Colors.white,
                      fontSize: tokens.scaled(12.5),
                      shadows: const [
                        Shadow(color: Mv2Scrim.shadow, blurRadius: 3),
                      ],
                    ),
                  ),
                ),
              ),
            if (widget.isSelected)
              Positioned.fill(
                child: ColoredBox(
                  color: c.accent.withValues(alpha: Mv2Alphas.secondary),
                  child: Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: c.onAccent,
                      size: tokens.scaled(32),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  autofocus: widget.autofocus,
                  onTap: widget.onTap,
                  onLongPress: widget.onLongPress,
                  onSecondaryTap: widget.onSecondaryTap,
                  onFocusChange: _onFocusChange,
                  focusColor: Colors.transparent,
                ),
              ),
            ),
            if (showTopLeftBadges)
              PositionedDirectional(
                top: Mv2Space.s4,
                start: Mv2Space.s4,
                end: widget.languageLabel != null ? Mv2Space.s48 : Mv2Space.s4,
                child: IgnorePointer(
                  child: Wrap(
                    spacing: 3,
                    runSpacing: 3,
                    children: [
                      if (widget.inLibrary)
                        Mv2Badge(
                          label: tr('Trong thư viện'),
                          kind: Mv2StatusKind.unread,
                        ),
                      if (widget.isMerged)
                        Mv2Badge(
                          label: tr('Hợp nhất'),
                          kind: Mv2StatusKind.newChapter,
                        ),
                      if (widget.isLocal)
                        Mv2Badge(
                          label: tr('Cục bộ'),
                          kind: Mv2StatusKind.offline,
                        ),
                      if (widget.downloadedCount > 0)
                        Mv2Badge(
                          count: widget.downloadedCount,
                          kind: Mv2StatusKind.downloaded,
                        ),
                      if (widget.unreadCount > 0)
                        Mv2Badge(
                          count: widget.unreadCount,
                          kind: Mv2StatusKind.unread,
                        ),
                    ],
                  ),
                ),
              ),
            if (widget.languageLabel != null && widget.languageLabel!.isNotEmpty)
              PositionedDirectional(
                top: Mv2Space.s4,
                end: Mv2Space.s4,
                child: IgnorePointer(
                  child: Mv2Badge(
                    label: widget.languageLabel!.toUpperCase(),
                    customTone: Mv2Status(c.ink3, c.fg),
                    strong: false,
                  ),
                ),
              ),
            if (widget.sourceLabel != null && widget.sourceLabel!.isNotEmpty)
              PositionedDirectional(
                // 0.6.6 (UI-16): sit above the overlay title instead of on it.
                bottom: showOverlayTitle
                    ? _kOverlayTitleClearance
                    : (widget.progress > 0 ? Mv2Space.s8 : Mv2Space.s4),
                start: Mv2Space.s4,
                child: IgnorePointer(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 96),
                    child: Mv2Badge(
                      label: widget.sourceLabel!,
                      customTone: Mv2Status(c.ink3, c.fg),
                      strong: false,
                    ),
                  ),
                ),
              ),
            if (widget.showContinueButton && widget.onContinueTap != null)
              PositionedDirectional(
                bottom: showOverlayTitle
                    ? _kOverlayTitleClearance
                    : Mv2Space.s8,
                end: Mv2Space.s8,
                child: _Mv2ContinueButton(onTap: widget.onContinueTap!),
              ),
            if (widget.progress > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SizedBox(
                  height: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: Mv2Scrim.onImage),
                      FractionallySizedBox(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: widget.progress.clamp(0.0, 1.0),
                        child: ColoredBox(color: c.accent),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    Widget card = Padding(
      padding: const EdgeInsets.all(Mv2Space.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: motion,
            curve: Mv2Motion.standardCurve,
            transform: Matrix4.identity()..scaleByDouble(pop, pop, pop, 1.0),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Mv2Shape.cover + 3),
              border: Border.all(
                color: _focused ? c.accent : Colors.transparent,
                width: 3,
              ),
            ),
            child: _wrapHero(coverContent),
          ),
          if (showBottomTitle) ...[
            const SizedBox(height: Mv2Space.s4),
            Text(
              widget.title,
              maxLines: widget.subtitle != null ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: tokens.text.card.copyWith(color: c.fg),
            ),
            if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
              Text(
                widget.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tokens.caption,
              ),
          ],
        ],
      ),
    );

    final longPress = widget.onLongPress;
    if (_isTv && longPress != null) {
      card = Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          if (!_isTvSelectKey(event.logicalKey)) return KeyEventResult.ignored;
          if (event is KeyDownEvent) {
            _held = false;
            _pressed = true;
            return KeyEventResult.handled;
          }
          if (event is KeyRepeatEvent) {
            if (_pressed) _held = true;
            return KeyEventResult.handled;
          }
          if (event is KeyUpEvent) {
            if (!_pressed) return KeyEventResult.ignored;
            if (_held) {
              longPress();
            } else {
              widget.onTap?.call();
            }
            _held = false;
            _pressed = false;
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: card,
      );
    }

    return Semantics(
      label: widget.title,
      button: widget.onTap != null,
      selected: widget.isSelected,
      child: card,
    );
  }
}

class _Mv2ContinueButton extends StatelessWidget {
  const _Mv2ContinueButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.mv2;
    final c = tokens.color;
    final size = tokens.scaled(32);
    final label = tr('Tiếp tục');
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: c.accent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox.square(
              dimension: size,
              child: Icon(
                Icons.play_arrow_rounded,
                size: size * 0.6,
                color: c.onAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Mv2CoverPlaceholder extends StatelessWidget {
  const _Mv2CoverPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = context.mv2;
    final c = tokens.color;
    return Padding(
      padding: const EdgeInsets.all(Mv2Space.s8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            color: c.fgMuted,
            size: tokens.scaled(24),
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: Mv2Space.s8),
            Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: tokens.caption,
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact list-tile representation of a media entry matching 0.9.96 `MangaImageCardListTileWidget`.
class Mv2MangaListTile extends StatelessWidget {
  const Mv2MangaListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.image,
    this.inLibrary = false,
    this.unreadCount = 0,
    this.downloadedCount = 0,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final ImageProvider? image;
  final bool inLibrary;
  final int unreadCount;
  final int downloadedCount;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.mv2;
    final c = tokens.color;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Mv2Space.s8,
        vertical: Mv2Space.s4,
      ),
      child: Material(
        color: isSelected
            ? c.accent.withValues(alpha: Mv2Alphas.accentTint)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(Mv2Shape.cover),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          onSecondaryTap: onSecondaryTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Mv2Space.s12,
              vertical: Mv2Space.s8,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Mv2Shape.cover),
                  child: SizedBox(
                    width: 40,
                    height: 55,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: c.ink2,
                          child: image != null
                              ? Image(
                                  image: image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Icon(
                                    Icons.image_outlined,
                                    size: 18,
                                    color: c.fgMuted,
                                  ),
                                )
                              : Icon(
                                  Icons.image_outlined,
                                  size: 18,
                                  color: c.fgMuted,
                                ),
                        ),
                        if (inLibrary) const ColoredBox(color: Mv2Scrim.onImage),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: Mv2Space.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tokens.text.row.copyWith(color: c.fg),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tokens.caption,
                        ),
                      ],
                    ],
                  ),
                ),
                if (inLibrary) ...[
                  const SizedBox(width: Mv2Space.s8),
                  Mv2Badge(
                    label: tr('Trong thư viện'),
                    kind: Mv2StatusKind.unread,
                  ),
                ],
                if (downloadedCount > 0) ...[
                  const SizedBox(width: Mv2Space.s4),
                  Mv2Badge(
                    count: downloadedCount,
                    kind: Mv2StatusKind.downloaded,
                  ),
                ],
                if (unreadCount > 0) ...[
                  const SizedBox(width: Mv2Space.s4),
                  Mv2Badge(count: unreadCount, kind: Mv2StatusKind.unread),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: Mv2Space.s4),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Breathing cover grid skeleton matching `0.9.96/lib/modules/widgets/cover_grid_skeleton.dart`.
class Mv2MangaGridSkeleton extends StatelessWidget {
  const Mv2MangaGridSkeleton({
    super.key,
    this.gridSize,
    this.childAspectRatio = 0.69,
    this.itemCount = 12,
  });

  final int? gridSize;
  final double childAspectRatio;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final tokens = context.mv2;
    return Container(
      color: tokens.color.ink0,
      child: GridView.builder(
        padding: isTv
            ? const EdgeInsets.all(Mv2Space.s12)
            : const EdgeInsets.only(top: Mv2Space.s12),
        gridDelegate: (gridSize == null || gridSize == 0)
            ? SliverGridDelegateWithMaxCrossAxisExtent(
                childAspectRatio: childAspectRatio,
                maxCrossAxisExtent: isTv ? 150 : 220,
                crossAxisSpacing: isTv ? 10 : 0,
                mainAxisSpacing: isTv ? 10 : 0,
              )
            : SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSize!,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: isTv ? 10 : 0,
                mainAxisSpacing: isTv ? 10 : 0,
              ),
        itemCount: itemCount,
        itemBuilder: (_, _) => const Padding(
          padding: EdgeInsets.all(Mv2Space.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _Mv2PulseBox(radius: Mv2Shape.cover)),
              SizedBox(height: Mv2Space.s8),
              FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: 0.72,
                child: SizedBox(
                  height: 12,
                  child: _Mv2PulseBox(radius: Mv2Shape.badge),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Mv2PulseBox extends StatefulWidget {
  const _Mv2PulseBox({required this.radius});

  final double radius;

  @override
  State<_Mv2PulseBox> createState() => _Mv2PulseBoxState();
}

class _Mv2PulseBoxState extends State<_Mv2PulseBox>
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
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: fg.withValues(alpha: Mv2Alphas.tint * (1 + _pulse.value)),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
