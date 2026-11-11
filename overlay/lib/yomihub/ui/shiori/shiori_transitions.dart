// Shiori Page Transitions for YomiHub (Mangayomi v0.9.95)
// Inspired by packages/shiori/lib/src/page_transitions.dart
import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/ui/shiori/shiori_tokens.dart';

const Curve _linearOutSlowIn = Cubic(0, 0, 0.2, 1);
const Curve _fastOutLinearIn = Cubic(0.4, 0, 1, 1);

/// Smooth shared-axis horizontal transition (Shared Axis on X).
/// The outgoing page slides left by 30 logical pixels and fades out,
/// while the incoming page slides in from 30 logical pixels on the right and fades in.
class ShioriPageTransition extends StatelessWidget {
  const ShioriPageTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    this.slideOffset = 30.0,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;
  final double slideOffset;

  static const Duration duration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return child;
    }

    final fadeIn = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.25, 1.0, curve: _linearOutSlowIn),
    );

    final slideIn = CurvedAnimation(
      parent: animation,
      curve: ShioriMotion.standardCurve,
    );

    final fadeOut = CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Interval(0.0, 0.35, curve: _fastOutLinearIn),
    );

    final slideOut = CurvedAnimation(
      parent: secondaryAnimation,
      curve: ShioriMotion.standardCurve,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: child,
      builder: (context, child) {
        final inOffset = (1.0 - slideIn.value) * slideOffset;
        final outOffset = -slideOut.value * slideOffset;
        final totalOffset = inOffset + outOffset;

        final opacity = (fadeIn.value * (1.0 - fadeOut.value)).clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(totalOffset, 0),
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
    );
  }
}

/// A PageTransitionsBuilder conforming to the Shiori design language.
class ShioriPageTransitionsBuilder extends PageTransitionsBuilder {
  const ShioriPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ShioriPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

