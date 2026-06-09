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
        if (visible)
          const Positioned.fill(child: BrandingSplashView()),
      ],
    );
  }
}
