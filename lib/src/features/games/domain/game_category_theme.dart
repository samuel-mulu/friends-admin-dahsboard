import 'package:flutter/material.dart';

import '../../../core/theme/app_branding.dart';
import '../data/models/game_model.dart';

/// Visual identity for game categories — shared across hub, live, and history.
abstract final class GameCategoryTheme {
  static IconData iconFor(GameCategory category) {
    return switch (category) {
      GameCategory.normal => Icons.sports_esports_rounded,
      GameCategory.bonus => Icons.redeem_rounded,
      GameCategory.bigGotd => Icons.star_rounded,
      GameCategory.bigGame => Icons.emoji_events_rounded,
    };
  }

  static Color accentColor(GameCategory category, {required bool isDark}) {
    return switch (category) {
      GameCategory.normal => AppBranding.bingoB,
      GameCategory.bonus => AppBranding.bingoFreeGreen,
      GameCategory.bigGotd => AppBranding.gold,
      GameCategory.bigGame => AppBranding.gold,
    };
  }

  static Color surfaceColor(GameCategory category, {required bool isDark}) {
    return switch (category) {
      GameCategory.normal =>
        isDark ? const Color(0xFF152238) : const Color(0xFFE8F1FF),
      GameCategory.bonus =>
        isDark ? const Color(0xFF0F2A1C) : const Color(0xFFE8F8EE),
      GameCategory.bigGotd =>
        isDark ? const Color(0xFF2B2111) : const Color(0xFFFFF6DB),
      GameCategory.bigGame =>
        isDark ? AppBranding.casinoPurpleDeep : const Color(0xFFF3E8FF),
    };
  }

  static Color borderColor(GameCategory category, {required bool isDark}) {
    return accentColor(
      category,
      isDark: isDark,
    ).withValues(alpha: isDark ? 0.45 : 0.55);
  }

  static GameCategory categoryFor(GameModel game) {
    if (game.isBigGame) {
      return GameCategory.bigGame;
    }
    if (game.isBigGotd) {
      return GameCategory.bigGotd;
    }
    if (game.isBonus) {
      return GameCategory.bonus;
    }
    return GameCategory.normal;
  }

  static ThemeData bigGameTheme(BuildContext context) {
    final base = Theme.of(context);
    final isDark = base.brightness == Brightness.dark;
    final surface = surfaceColor(GameCategory.bigGame, isDark: isDark);

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppBranding.gold,
        secondary: isDark ? AppBranding.casinoPurpleDeep : AppBranding.brandPurple,
        surface: surface,
      ),
      scaffoldBackgroundColor: surface,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor:
            isDark ? AppBranding.casinoPurpleDeep : const Color(0xFFF3E8FF),
        foregroundColor: isDark ? AppBranding.gold : AppBranding.brandPurple,
      ),
    );
  }
}
