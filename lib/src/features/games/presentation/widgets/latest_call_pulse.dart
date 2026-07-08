import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';

/// Pulsing red border + gold glow + scale beat for the latest called number.
class LatestCallPulse extends StatefulWidget {
  const LatestCallPulse({
    required this.child,
    this.borderRadius = 4,
    this.shape = BoxShape.rectangle,
    this.highlightColor,
    this.flashOverlay = true,
    this.pulseScale = 0.16,
    super.key,
  });

  final Widget child;
  final double borderRadius;
  final BoxShape shape;
  final Color? highlightColor;
  final bool flashOverlay;
  final double pulseScale;

  @override
  State<LatestCallPulse> createState() => _LatestCallPulseState();
}

class _LatestCallPulseState extends State<LatestCallPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.highlightColor ??
        AppBranding.latestCallGlowForTheme(context);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        final borderWidth = 3.0 + (t * 1.0);
        final borderOpacity = 0.9 + (t * 0.1);
        final glowBlur = 10.0 + (t * 10.0);
        final glowSpread = 0.5 + (t * 1.5);
        final scale = 1.0 + (t * widget.pulseScale);
        final flashAlpha = 0.18 + (t * 0.42);

        return Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: widget.shape,
              borderRadius: widget.shape == BoxShape.circle
                  ? null
                  : BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: AppBranding.latestCallBorder.withValues(
                  alpha: borderOpacity,
                ),
                width: borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.45 + (t * 0.4)),
                  blurRadius: glowBlur,
                  spreadRadius: glowSpread,
                ),
                BoxShadow(
                  color: AppBranding.latestCallBorder.withValues(
                    alpha: 0.35 + (t * 0.25),
                  ),
                  blurRadius: glowBlur * 0.55,
                  spreadRadius: glowSpread * 0.5,
                ),
              ],
            ),
            child: widget.flashOverlay
                ? Stack(
                    fit: StackFit.passthrough,
                    children: [
                      child!,
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: widget.shape,
                              borderRadius: widget.shape == BoxShape.circle
                                  ? null
                                  : BorderRadius.circular(
                                      widget.borderRadius,
                                    ),
                              color: Colors.white.withValues(alpha: flashAlpha),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : child!,
          ),
        );
      },
      child: widget.child,
    );
  }
}
