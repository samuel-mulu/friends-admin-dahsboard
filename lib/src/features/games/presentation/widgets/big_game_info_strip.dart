import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/game_model.dart';
import 'game_category_badge.dart';

/// Shared big-game metadata strip (entry fee, round/fixed prize, max cartelas).
class BigGameInfoStrip extends StatelessWidget {
  const BigGameInfoStrip({
    required this.game,
    super.key,
  });

  final GameModel game;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final limit = game.maxCartelasPerPlayer;
    final roundPrize = game.effectiveRoundPrizeAmount;
    final prizeText = roundPrize != null
        ? (game.hasMultipleRounds
            ? '${l10n.bigGameThisRoundPrize}: ${formatMoney(roundPrize)}'
            : l10n.gameBonusFixedPrize(formatMoney(roundPrize)))
        : game.fixedPrizeAmount != null
            ? l10n.gameBonusFixedPrize(formatMoney(game.fixedPrizeAmount!))
            : null;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        GameCategoryBadge.forGame(game, compact: true),
        Text(
          '${l10n.gameInfoEntry}: ${formatMoney(game.entryFee)}',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (prizeText != null)
          Text(
            prizeText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (limit != null)
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
