import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
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
                    'Welcome bonus',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  VGap.xs,
                  Text(
                    'You have ${wallet.bonusCartelaBalance} bonus cartelas for normal games. '
                    'Each one registers 1 normal-game cartela without using your ETB balance. '
                    'Big GOTD and Big Game use wallet money. Bonus cartelas are not withdrawable.',
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
