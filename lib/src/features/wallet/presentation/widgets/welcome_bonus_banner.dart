import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/wallet_model.dart';

class WelcomeBonusBanner extends StatelessWidget {
  const WelcomeBonusBanner({
    required this.wallet,
    super.key,
  });

  final WalletModel wallet;

  @override
  Widget build(BuildContext context) {
    if (!wallet.shouldShowWelcomeBonus) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: AppSpacing.cardPaddingDense,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.redeem_rounded,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            HGap.md,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.welcomeBonusTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  VGap.xs,
                  Text(
                    l10n.welcomeBonusBody(wallet.bonusCartelaBalance),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
