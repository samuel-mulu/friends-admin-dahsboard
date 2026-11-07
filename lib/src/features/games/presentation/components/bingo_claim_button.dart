import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../theme/live_play_theme_tokens.dart';

/// B-I-N-G-O claim button. Stays still when a cartela's rule is fully marked.
class BingoClaimButton extends StatelessWidget {
  const BingoClaimButton({
    required this.canClaim,
    required this.isClaiming,
    required this.onPressed,
    super.key,
  });

  final bool canClaim;
  final bool isClaiming;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = canClaim && !isClaiming;

    final Widget buttonContent;
    if (isClaiming) {
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

    final tokens = LivePlayThemeTokens.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              height: 22,
              child: FilledButton(
                onPressed: isEnabled ? onPressed : null,
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.bingoClaimGold,
                  foregroundColor: AppBranding.casinoPurpleDeep,
                  disabledBackgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : tokens.bingoClaimGold.withValues(alpha: 0.16),
                  disabledForegroundColor: isDark
                      ? Colors.white38
                      : AppBranding.lightOnDisabled,
                  elevation: isEnabled ? 2 : 0,
                  shadowColor: tokens.bingoClaimGold.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isEnabled
                          ? Colors.white.withValues(alpha: 0.5)
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : tokens.bingoClaimGold.withValues(alpha: 0.35)),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Center(
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: buttonContent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
