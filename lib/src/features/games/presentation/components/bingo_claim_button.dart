import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';

/// Reusable glowing B-I-N-G-O claim button with pulse animation on winning opportunity.
class BingoClaimButton extends StatefulWidget {
  const BingoClaimButton({
    required this.canClaim,
    required this.showReadyPulse,
    required this.isClaiming,
    required this.onPressed,
    super.key,
  });

  final bool canClaim;
  final bool showReadyPulse;
  final bool isClaiming;
  final VoidCallback onPressed;

  @override
  State<BingoClaimButton> createState() => _BingoClaimButtonState();
}

class _BingoClaimButtonState extends State<BingoClaimButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant BingoClaimButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.canClaim != widget.canClaim ||
        oldWidget.showReadyPulse != widget.showReadyPulse ||
        oldWidget.isClaiming != widget.isClaiming) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.showReadyPulse && !widget.isClaiming) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = widget.canClaim && !widget.isClaiming;

    final Widget buttonContent;
    if (widget.isClaiming) {
      buttonContent = SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isEnabled ? AppBranding.casinoPurpleDeep : AppBranding.gold,
          ),
        ),
      );
    } else {
      buttonContent = Text(
        'BINGO',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 11.5,
          letterSpacing: 0.8,
          height: 1,
          color: isEnabled
              ? AppBranding.casinoPurpleDeep
              : (isDark ? Colors.white38 : AppBranding.lightOnDisabled),
        ),
      );
    }

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? widget.onPressed : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: isEnabled
                ? const LinearGradient(
                    colors: [AppBranding.goldAccent, AppBranding.gold],
                  )
                : null,
            color: isEnabled
                ? null
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05)),
            border: Border.all(
              color: isEnabled
                  ? Colors.white.withValues(alpha: 0.5)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08)),
              width: 1.0,
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: AppBranding.gold.withValues(alpha: 0.35),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ]
                : null,
          ),
          child: buttonContent,
        ),
      ),
    );

    if (!widget.showReadyPulse || widget.isClaiming) {
      return button;
    }

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        return Transform.scale(
          scale: 1 + (t * 0.05),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppBranding.feltGreen.withValues(alpha: 0.2 + (t * 0.5)),
                  blurRadius: 4 + (t * 8),
                  spreadRadius: t * 0.8,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: button,
    );
  }
}
