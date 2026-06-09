import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Friends Bingo brand palette — casino-inspired, player-first.
abstract final class AppBranding {
  static const brandName = 'FRIENDS BINGO';

  static const gold = Color(0xFFF5C542);
  static const goldDark = Color(0xFFC9A227);
  static const casinoPurple = Color(0xFF4C1D95);
  static const casinoPurpleDeep = Color(0xFF2E1065);
  static const feltGreen = Color(0xFF0F3D2E);

  static const liveSurfaceDark = Color(0xFF0D0A14);
  static const liveCardDark = Color(0xFF1A1528);
  static const statPillDark = Color(0xFF251D3A);

  static Color liveSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? liveSurfaceDark
        : const Color(0xFFF5F3FA);
  }

  static Color statPillBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? statPillDark
        : casinoPurple.withValues(alpha: 0.08);
  }

  static Color calledBallLatest(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? gold
        : casinoPurple;
  }

  static Color panelBackground(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? liveCardDark
        : theme.colorScheme.surfaceContainerLow;
  }

  static Color cellBackground(BuildContext context, {required bool marked}) {
    final theme = Theme.of(context);
    if (marked) {
      return theme.brightness == Brightness.dark
          ? casinoPurple.withValues(alpha: 0.55)
          : casinoPurple.withValues(alpha: 0.18);
    }
    return theme.brightness == Brightness.dark
        ? const Color(0xFF2A2340)
        : theme.colorScheme.surface;
  }

  static Color cellForeground(BuildContext context, {required bool marked}) {
    final theme = Theme.of(context);
    if (marked) {
      return gold;
    }
    return theme.colorScheme.onSurface;
  }

  static Color balanceAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? gold : goldDark;
  }

  static TextStyle wordmark(BuildContext context, {bool compact = false}) {
    return GoogleFonts.bebasNeue(
      fontSize: compact ? 22 : 32,
      letterSpacing: compact ? 2 : 3,
      height: 1,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle wordmarkGold({double size = 28}) {
    return GoogleFonts.bebasNeue(
      fontSize: size,
      letterSpacing: 2.5,
      height: 1,
      color: gold,
    );
  }
}
