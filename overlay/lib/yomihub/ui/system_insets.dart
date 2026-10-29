import 'dart:io';

import 'package:flutter/material.dart';

/// YomiHub 0.1.8: keeps every screen clear of the Android navigation bar /
/// 3-button navigation keys (bottom in portrait, left or right side in
/// landscape).
///
/// Android 15+ draws apps edge-to-edge, so lists, sheets, the reader's
/// bottom bar, floating buttons… ended up under the navigation keys. The
/// whole app is laid out inside the safe area instead; the strip behind the
/// keys takes the colour of the bottom navigation bar. Full-screen readers
/// and players hide the system bars, so their insets are zero and they still
/// use the whole screen. The status bar is left to the app bars.
class YomiSystemInsets extends StatelessWidget {
  final Widget child;
  const YomiSystemInsets({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) return child;
    final mq = MediaQuery.of(context);
    final pad = mq.padding;
    if (pad.bottom == 0 && pad.left == 0 && pad.right == 0) return child;
    final theme = Theme.of(context);
    final barColor =
        theme.navigationBarTheme.backgroundColor ?? theme.colorScheme.surfaceContainer;
    return ColoredBox(
      color: barColor,
      child: Padding(
        padding: EdgeInsets.only(
          left: pad.left,
          right: pad.right,
          bottom: pad.bottom,
        ),
        child: MediaQuery(
          data: mq.copyWith(
            padding: pad.copyWith(left: 0, right: 0, bottom: 0),
            viewPadding: mq.viewPadding.copyWith(left: 0, right: 0, bottom: 0),
            // the keyboard inset is measured from the screen edge; part of it
            // is now taken by the padding above
            viewInsets: mq.viewInsets.copyWith(
              bottom: (mq.viewInsets.bottom - pad.bottom).clamp(0, double.infinity),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
