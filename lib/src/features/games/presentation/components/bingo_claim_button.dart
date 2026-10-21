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
    final button = SizedBox(
      height: 22,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppBranding.goldAccent,
          foregroundColor: AppBranding.brandPurple,
          disabledBackgroundColor: isDark
              ? Colors.white24
              : AppBranding.lightOnDisabled.withValues(alpha: 0.25),
          disabledForegroundColor: isDark
              ? Colors.white54
              : AppBranding.lightOnDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: widget.canClaim && !widget.isClaiming ? widget.onPressed : null,
        child: widget.isClaiming
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'BINGO',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
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
