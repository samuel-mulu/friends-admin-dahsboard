import 'package:flutter/material.dart';

import '../../../../core/utils/l10n.dart';
import '../../data/models/game_model.dart';
import '../../domain/game_category_theme.dart';

/// Unified category badge — Normal (blue), Bonus (green), Big Game (purple/gold).
class GameCategoryBadge extends StatelessWidget {
  const GameCategoryBadge({
    required this.category,
    this.compact = false,
    super.key,
  });

  factory GameCategoryBadge.forGame(GameModel game, {bool compact = false}) {
    return GameCategoryBadge(
      category: GameCategoryTheme.categoryFor(game),
      compact: compact,
    );
  }

  final GameCategory category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = GameCategoryTheme.accentColor(category, isDark: isDark);
    // Big GOTD uses the same player-facing label as Normal (category stays BIG_GOTD).
    final label = switch (category) {
      GameCategory.normal => l10n.gameCategoryNormal,
      GameCategory.bonus => l10n.gameCategoryBonus,
      GameCategory.bigGotd => l10n.gameCategoryNormal,
      GameCategory.bigGame => l10n.gameCategoryBigGame,
    };

    return Semantics(
      label: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.22 : 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              GameCategoryTheme.iconFor(category),
              size: compact ? 13 : 15,
              color: accent,
            ),
            SizedBox(width: compact ? 4 : 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
