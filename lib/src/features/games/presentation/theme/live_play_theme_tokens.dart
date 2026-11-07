import 'package:flutter/material.dart';

@immutable
class LivePlayThemeTokens extends ThemeExtension<LivePlayThemeTokens> {
  const LivePlayThemeTokens({
    required this.scaffoldBackground,
    required this.cardBackground,
    required this.cardBorder,
    required this.topClusterBackground,
    required this.topClusterBorder,
    required this.cellUnmarkedBackground,
    required this.cellUnmarkedBorder,
    required this.cellUnmarkedText,
    required this.cellMarkedGreenFill,
    required this.cellMarkedGreenBorder,
    required this.cellMarkedGreenText,
    required this.latestBallHaloColor,
    required this.bingoClaimGold,
    required this.bingoClaimGoldDark,
    required this.blockedPillBackground,
    required this.blockedPillBorder,
    required this.blockedPillText,
    required this.badgeGoldBackground,
    required this.badgeGoldBorder,
    required this.badgeGoldText,
  });

  final Color scaffoldBackground;
  final Color cardBackground;
  final Color cardBorder;
  final Color topClusterBackground;
  final Color topClusterBorder;
  final Color cellUnmarkedBackground;
  final Color cellUnmarkedBorder;
  final Color cellUnmarkedText;
  final Color cellMarkedGreenFill;
  final Color cellMarkedGreenBorder;
  final Color cellMarkedGreenText;
  final Color latestBallHaloColor;
  final Color bingoClaimGold;
  final Color bingoClaimGoldDark;
  final Color blockedPillBackground;
  final Color blockedPillBorder;
  final Color blockedPillText;
  final Color badgeGoldBackground;
  final Color badgeGoldBorder;
  final Color badgeGoldText;

  static const light = LivePlayThemeTokens(
    scaffoldBackground: Color(0xFFF3EFE6),
    cardBackground: Color(0xFFFAF7F2),
    cardBorder: Color(0xFFE5DEC9),
    topClusterBackground: Color(0xFFFAF7F0),
    topClusterBorder: Color(0xFFE4DBC7),
    cellUnmarkedBackground: Color(0xFFF5EFE6),
    cellUnmarkedBorder: Color(0xFFE4DAC7),
    cellUnmarkedText: Color(0xFF2B0A57),
    cellMarkedGreenFill: Color(0xFF27AE60),
    cellMarkedGreenBorder: Color(0xFF1E8E4D),
    cellMarkedGreenText: Colors.white,
    latestBallHaloColor: Color(0xFFF5C542),
    bingoClaimGold: Color(0xFFE5B834),
    bingoClaimGoldDark: Color(0xFFC99718),
    blockedPillBackground: Color(0xFFFEE2E2),
    blockedPillBorder: Color(0xFFFCA5A5),
    blockedPillText: Color(0xFFDC2626),
    badgeGoldBackground: Color(0xFFFEF3C7),
    badgeGoldBorder: Color(0xFFFDE68A),
    badgeGoldText: Color(0xFF78350F),
  );

  static const dark = LivePlayThemeTokens(
    scaffoldBackground: Color(0xFF0D0A14),
    cardBackground: Color(0xFF1A1528),
    cardBorder: Color(0x33F5C542),
    topClusterBackground: Color(0xFF1E1730),
    topClusterBorder: Color(0x33F5C542),
    cellUnmarkedBackground: Color(0xFF2A2340),
    cellUnmarkedBorder: Color(0x33B9B0CE),
    cellUnmarkedText: Color(0xFFF2EFFA),
    cellMarkedGreenFill: Color(0xFF16A34A),
    cellMarkedGreenBorder: Color(0xFF0F3D2E),
    cellMarkedGreenText: Colors.white,
    latestBallHaloColor: Color(0xFFF5C542),
    bingoClaimGold: Color(0xFFF5C542),
    bingoClaimGoldDark: Color(0xFFC9A227),
    blockedPillBackground: Color(0x2EE53935),
    blockedPillBorder: Color(0x66E53935),
    blockedPillText: Color(0xFFEF4444),
    badgeGoldBackground: Color(0x33F5C542),
    badgeGoldBorder: Color(0x66F5C542),
    badgeGoldText: Color(0xFFF5C542),
  );

  static LivePlayThemeTokens of(BuildContext context) {
    final tokens = Theme.of(context).extension<LivePlayThemeTokens>();
    if (tokens != null) return tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? dark : light;
  }

  @override
  LivePlayThemeTokens copyWith({
    Color? scaffoldBackground,
    Color? cardBackground,
    Color? cardBorder,
    Color? topClusterBackground,
    Color? topClusterBorder,
    Color? cellUnmarkedBackground,
    Color? cellUnmarkedBorder,
    Color? cellUnmarkedText,
    Color? cellMarkedGreenFill,
    Color? cellMarkedGreenBorder,
    Color? cellMarkedGreenText,
    Color? latestBallHaloColor,
    Color? bingoClaimGold,
    Color? bingoClaimGoldDark,
    Color? blockedPillBackground,
    Color? blockedPillBorder,
    Color? blockedPillText,
    Color? badgeGoldBackground,
    Color? badgeGoldBorder,
    Color? badgeGoldText,
  }) {
    return LivePlayThemeTokens(
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      topClusterBackground: topClusterBackground ?? this.topClusterBackground,
      topClusterBorder: topClusterBorder ?? this.topClusterBorder,
      cellUnmarkedBackground: cellUnmarkedBackground ?? this.cellUnmarkedBackground,
      cellUnmarkedBorder: cellUnmarkedBorder ?? this.cellUnmarkedBorder,
      cellUnmarkedText: cellUnmarkedText ?? this.cellUnmarkedText,
      cellMarkedGreenFill: cellMarkedGreenFill ?? this.cellMarkedGreenFill,
      cellMarkedGreenBorder: cellMarkedGreenBorder ?? this.cellMarkedGreenBorder,
      cellMarkedGreenText: cellMarkedGreenText ?? this.cellMarkedGreenText,
      latestBallHaloColor: latestBallHaloColor ?? this.latestBallHaloColor,
      bingoClaimGold: bingoClaimGold ?? this.bingoClaimGold,
      bingoClaimGoldDark: bingoClaimGoldDark ?? this.bingoClaimGoldDark,
      blockedPillBackground: blockedPillBackground ?? this.blockedPillBackground,
      blockedPillBorder: blockedPillBorder ?? this.blockedPillBorder,
      blockedPillText: blockedPillText ?? this.blockedPillText,
      badgeGoldBackground: badgeGoldBackground ?? this.badgeGoldBackground,
      badgeGoldBorder: badgeGoldBorder ?? this.badgeGoldBorder,
      badgeGoldText: badgeGoldText ?? this.badgeGoldText,
    );
  }

  @override
  LivePlayThemeTokens lerp(ThemeExtension<LivePlayThemeTokens>? other, double t) {
    if (other is! LivePlayThemeTokens) return this;
    return LivePlayThemeTokens(
      scaffoldBackground: Color.lerp(scaffoldBackground, other.scaffoldBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      topClusterBackground: Color.lerp(topClusterBackground, other.topClusterBackground, t)!,
      topClusterBorder: Color.lerp(topClusterBorder, other.topClusterBorder, t)!,
      cellUnmarkedBackground: Color.lerp(cellUnmarkedBackground, other.cellUnmarkedBackground, t)!,
      cellUnmarkedBorder: Color.lerp(cellUnmarkedBorder, other.cellUnmarkedBorder, t)!,
      cellUnmarkedText: Color.lerp(cellUnmarkedText, other.cellUnmarkedText, t)!,
      cellMarkedGreenFill: Color.lerp(cellMarkedGreenFill, other.cellMarkedGreenFill, t)!,
      cellMarkedGreenBorder: Color.lerp(cellMarkedGreenBorder, other.cellMarkedGreenBorder, t)!,
      cellMarkedGreenText: Color.lerp(cellMarkedGreenText, other.cellMarkedGreenText, t)!,
      latestBallHaloColor: Color.lerp(latestBallHaloColor, other.latestBallHaloColor, t)!,
      bingoClaimGold: Color.lerp(bingoClaimGold, other.bingoClaimGold, t)!,
      bingoClaimGoldDark: Color.lerp(bingoClaimGoldDark, other.bingoClaimGoldDark, t)!,
      blockedPillBackground: Color.lerp(blockedPillBackground, other.blockedPillBackground, t)!,
      blockedPillBorder: Color.lerp(blockedPillBorder, other.blockedPillBorder, t)!,
      blockedPillText: Color.lerp(blockedPillText, other.blockedPillText, t)!,
      badgeGoldBackground: Color.lerp(badgeGoldBackground, other.badgeGoldBackground, t)!,
      badgeGoldBorder: Color.lerp(badgeGoldBorder, other.badgeGoldBorder, t)!,
      badgeGoldText: Color.lerp(badgeGoldText, other.badgeGoldText, t)!,
    );
  }
}
