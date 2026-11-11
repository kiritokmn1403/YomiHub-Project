import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// How far a sideways swipe must go, in logical pixels, to count.
const double kSideSwipeDistance = 72;

/// How fast a sideways fling must be, in logical pixels a second.
const double kSideSwipeVelocity = 700;

/// YomiHub 0.5.6: sideways swipe between the members of a navigation group
/// (Comic ↔ Film & Movie ↔ Novel ↔ Play Books in "Thư Viện").
///
/// Ported from Mangayomi v0.9.95 `lib/modules/widgets/side_swipe_detector.dart`
/// (used there by `NavGroupSwipe`). What scrolls sideways inside keeps its
/// swipe: over horizontal pages (the category tabs) only the pull past the
/// first or the last page counts.
///
/// Unlike upstream the widget always builds the same tree – with both
/// callbacks null it only listens – so the routed pages below keep their
/// state when the swipe is switched on or off.
class YomiSideSwipe extends StatefulWidget {
  const YomiSideSwipe({
    super.key,
    required this.child,
    this.onNext,
    this.onPrevious,
  });

  final Widget child;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  @override
  State<YomiSideSwipe> createState() => _YomiSideSwipeState();
}

class _YomiSideSwipeState extends State<YomiSideSwipe> {
  double _drag = 0;

  /// How far the pages were pulled past their first or last one.
  double _overscroll = 0;

  bool get _active => widget.onNext != null || widget.onPrevious != null;

  /// [offset] is how far the swipe went toward the end side of the screen.
  void _maybeSwipe(double offset, double velocity) {
    final far = offset.abs() >= kSideSwipeDistance;
    final fast =
        velocity.abs() >= kSideSwipeVelocity && velocity.sign == offset.sign;
    if (!far && !fast) return;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final next = rtl ? offset > 0 : offset < 0;
    final action = next ? widget.onNext : widget.onPrevious;
    if (action == null) return;
    HapticFeedback.selectionClick();
    action();
  }

  bool _onScroll(ScrollNotification notification) {
    if (!_active ||
        notification.metrics is! PageMetrics ||
        notification.metrics.axis != Axis.horizontal) {
      return false;
    }
    if (notification is ScrollStartNotification) {
      _overscroll = 0;
    } else if (notification is OverscrollNotification) {
      // Clamped pages (Android, Windows): the pull past the edge is
      // reported. The finger's only: a fling carrying on past the last page
      // is not asking for more.
      if (notification.dragDetails != null) {
        _overscroll -= notification.overscroll;
      }
    } else if (notification is ScrollUpdateNotification) {
      // Bouncing pages (iOS, macOS): the pull shows as being out of range.
      if (notification.dragDetails == null) return false;
      final m = notification.metrics;
      if (m.pixels < m.minScrollExtent) {
        _overscroll = m.minScrollExtent - m.pixels;
      } else if (m.pixels > m.maxScrollExtent) {
        _overscroll = m.maxScrollExtent - m.pixels;
      }
    } else if (notification is ScrollEndNotification) {
      final pulled = _overscroll;
      _overscroll = 0;
      if (pulled.abs() >= kSideSwipeDistance) _maybeSwipe(pulled, 0);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      // Where nothing inside scrolls sideways, the swipe reaches this. No
      // recogniser is created while inactive, so readers and players that
      // handle sideways drags themselves are never disturbed.
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: active ? (_) => _drag = 0 : null,
        onHorizontalDragUpdate: active
            ? (details) => _drag += details.primaryDelta ?? 0
            : null,
        onHorizontalDragEnd: active
            ? (details) => _maybeSwipe(_drag, details.primaryVelocity ?? 0)
            : null,
        child: widget.child,
      ),
    );
  }
}

/// The neighbours of [current] among [tabs]: (previous, next), null at the
/// ends or when [current] is not one of them.
(String?, String?) sideSwipeNeighbours(List<String> tabs, String? current) {
  final i = current == null ? -1 : tabs.indexOf(current);
  if (i < 0) return (null, null);
  return (i > 0 ? tabs[i - 1] : null, i + 1 < tabs.length ? tabs[i + 1] : null);
}
