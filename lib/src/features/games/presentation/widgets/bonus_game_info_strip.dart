import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/game_model.dart';
import 'game_category_badge.dart';

/// Shared fixed-prize side-game metadata strip.
class BonusGameInfoStrip extends StatelessWidget {
  const BonusGameInfoStrip({required this.game, super.key});

  final GameModel game;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final limit = game.maxCartelasPerPlayer ?? 5;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        GameCategoryBadge.forGame(game, compact: true),
        Text(
          game.hasFreeEntry
              ? l10n.gameBonusFreeEntry
              : '${l10n.bigGameEntryFee}: ${formatMoney(game.entryFee)}',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (game.fixedPrizeAmount != null)
          Text(
            l10n.gameBonusFixedPrize(formatMoney(game.fixedPrizeAmount!)),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        Text(
          l10n.gameBonusMaxCartelas(limit),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
