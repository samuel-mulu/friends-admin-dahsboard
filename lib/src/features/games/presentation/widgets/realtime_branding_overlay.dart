import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/branding_splash_view.dart';

/// Full-screen branded splash layered over the live games screen.
class RealtimeBrandingOverlay extends StatelessWidget {
  const RealtimeBrandingOverlay({
    required this.visible,
    required this.child,
    super.key,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Cross-fade the branded splash in/out so entering a live room resolves
        // smoothly into content instead of hard-cutting.
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !visible,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: visible
                  ? const BrandingSplashView()
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}
