import 'package:flutter/material.dart';

/// Animated transition wrapper between live game presentation phases.
class LiveGameContentSwitcher extends StatelessWidget {
  const LiveGameContentSwitcher({
    required this.transitionKey,
    required this.hasCompletedInitialPaint,
    required this.child,
    super.key,
  });

  final String transitionKey;
  final bool hasCompletedInitialPaint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: hasCompletedInitialPaint
          ? const Duration(milliseconds: 240)
          : Duration.zero,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        if (!hasCompletedInitialPaint) {
          return child;
        }
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey<String>(transitionKey),
        child: child,
      ),
    );
  }
}
