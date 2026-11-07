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
    final enabledGradient = LinearGradient(
      colors: [tokens.bingoClaimGold, tokens.bingoClaimGoldDark],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isEnabled ? onPressed : null,
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: isEnabled ? enabledGradient : null,
                    color: isEnabled
                        ? null
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : tokens.bingoClaimGold.withValues(alpha: 0.16)),
                    border: Border.all(
                      color: isEnabled
                          ? Colors.white.withValues(alpha: 0.5)
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : tokens.bingoClaimGold.withValues(alpha: 0.35)),
                      width: 1.0,
                    ),
                    boxShadow: isEnabled
                        ? [
                            BoxShadow(
                              color: tokens.bingoClaimGold.withValues(alpha: 0.38),
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            ),
                          ]
                        : null,
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
        ),
      ],
    );
  }
}
