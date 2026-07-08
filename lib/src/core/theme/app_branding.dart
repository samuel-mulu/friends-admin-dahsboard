import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Friends Bingo brand palette — casino-inspired, player-first.
abstract final class AppBranding {
  static const brandName = 'FRIENDS BINGO';

  static const gold = Color(0xFFF5C542);
  static const goldDark = Color(0xFFC9A227);
  static const goldAccent = Color(0xFFD4A937);
  static const brandPurple = Color(0xFF2B0A57);
  static const casinoPurple = Color(0xFF4C1D95);
  static const casinoPurpleDeep = Color(0xFF2E1065);
  static const feltGreen = Color(0xFF0F3D2E);

  static const liveSurfaceDark = Color(0xFF0D0A14);
  static const liveCardDark = Color(0xFF1A1528);
  static const statPillDark = Color(0xFF251D3A);

  /// Premium light theme — warm cream surfaces (not near-white), readable contrast.
  static const lightScaffold = Color(0xFFE8E2D8);
  static const lightSurface = Color(0xFFF3EEE6);
  static const lightSurfaceRaised = Color(0xFFF7F3EC);
  static const lightSurfaceMuted = Color(0xFFDDD6CA);
  static const lightSurfaceSubtle = Color(0xFFD4CCC0);
  static const lightOutline = Color(0xFFC4B08A);
  static const lightOnSurface = Color(0xFF2B0A57);
  static const lightOnSurfaceMuted = Color(0xFF4A4560);
  static const lightOnDisabled = Color(0xFF8A8398);

  /// B-I-N-G-O column palette (board + cartela marks).
  static const bingoB = Color(0xFF2196F3);
  static const bingoI = Color(0xFFE53935);
  static const bingoN = Color(0xFF43A047);
  static const bingoG = Color(0xFF8E24AA);
  static const bingoO = Color(0xFFFB8C00);
  static const bingoFreeGreen = Color(0xFF16A34A);

  /// Latest-draw emphasis — visible on dark and light backgrounds.
  static const latestCallBorder = Color(0xFFEF4444);
  static const latestCallGlow = Color(0xFFF5C542);

  static bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color bingoColumnColor(String letter) {
    switch (letter.trim().toUpperCase()) {
      case 'B':
        return bingoB;
      case 'I':
        return bingoI;
      case 'N':
        return bingoN;
      case 'G':
        return bingoG;
      case 'O':
        return bingoO;
      default:
        return lightOnSurfaceMuted;
    }
  }

  static Color latestCallGlowForTheme(BuildContext context) {
    return _isDark(context) ? latestCallGlow : goldAccent;
  }

  static Color liveSurface(BuildContext context) {
    return _isDark(context) ? liveSurfaceDark : lightScaffold;
  }

  static Color statPillBackground(BuildContext context) {
    return _isDark(context) ? statPillDark : lightSurfaceMuted;
  }

  static Color calledBallLatest(BuildContext context) {
    return _isDark(context) ? gold : goldAccent;
  }

  static Color panelBackground(BuildContext context) {
    return _isDark(context) ? liveCardDark : lightSurface;
  }

  static Color panelBorder(BuildContext context) {
    return _isDark(context)
        ? gold.withValues(alpha: 0.25)
        : lightOutline;
  }

  static Color interactiveSurface(BuildContext context) {
    return _isDark(context) ? liveCardDark : const Color(0xFFFAF6F0);
  }

  static Color cartelaBoardBackground(BuildContext context) {
    return _isDark(context) ? const Color(0xFF101010) : lightSurfaceMuted;
  }

  static Color brandChipBackground(BuildContext context) {
    return _isDark(context) ? liveCardDark : lightSurface;
  }

  static Color brandChipBorder(BuildContext context) {
    return _isDark(context)
        ? gold.withValues(alpha: 0.6)
        : lightOutline;
  }

  static Color brandChipLabel(BuildContext context) {
    return _isDark(context)
        ? Colors.white.withValues(alpha: 0.78)
        : lightOnSurfaceMuted;
  }

  static Color brandHighlightText(BuildContext context) {
    return _isDark(context) ? gold : brandPurple;
  }

  static Color brandAccentValue(BuildContext context) {
    return _isDark(context) ? gold : goldAccent;
  }

  static Color headerActionIcon(BuildContext context) {
    return _isDark(context) ? Colors.white : brandPurple;
  }

  static Color appShellHeaderForeground(BuildContext context) {
    return _isDark(context) ? Colors.white : brandPurple;
  }

  static Color appShellHeaderForegroundMuted(BuildContext context) {
    return _isDark(context)
        ? Colors.white.withValues(alpha: 0.72)
        : lightOnSurfaceMuted;
  }

  static BoxDecoration appShellHeaderDecoration(BuildContext context) {
    if (_isDark(context)) {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            casinoPurpleDeep,
            casinoPurple,
            Color(0xFF5B21B6),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0x33F5C542)),
        ),
      );
    }

    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF3EEE6),
          Color(0xFFE8DFD2),
          Color(0xFFDDD4C6),
        ],
      ),
      border: Border(
        bottom: BorderSide(color: lightOutline.withValues(alpha: 0.9)),
      ),
    );
  }

  static Color elevationShadow(BuildContext context) {
    return _isDark(context) ? casinoPurple : brandPurple;
  }

  static BoxDecoration lightPanelDecoration(BuildContext context) {
    return BoxDecoration(
      color: panelBackground(context),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: panelBorder(context)),
    );
  }

  static BoxDecoration? cartelaHeaderDecoration(
    BuildContext context, {
    required bool isBlocked,
    required bool isWinner,
  }) {
    if (isBlocked || isWinner) {
      return null;
    }

    if (_isDark(context)) {
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [casinoPurpleDeep, casinoPurple],
        ),
      );
    }

    return BoxDecoration(
      color: lightSurfaceRaised,
      border: Border(
        bottom: BorderSide(color: lightOutline.withValues(alpha: 0.95)),
      ),
    );
  }

  static BoxDecoration drawerHeaderDecoration(BuildContext context) {
    if (_isDark(context)) {
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [casinoPurpleDeep, liveCardDark],
        ),
      );
    }

    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [lightSurfaceRaised, lightSurface],
      ),
      border: Border(
        bottom: BorderSide(color: lightOutline.withValues(alpha: 0.9)),
      ),
    );
  }

  static Color cellBackground(BuildContext context, {required bool marked}) {
    if (marked) {
      return _isDark(context)
          ? gold.withValues(alpha: 0.34)
          : goldAccent.withValues(alpha: 0.22);
    }
    return _isDark(context)
        ? const Color(0xFF2A2340)
        : const Color(0xFFFAF6F0);
  }

  static Color cellBorder(BuildContext context, {required bool marked}) {
    if (marked) {
      return gold;
    }
    return _isDark(context)
        ? Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35)
        : lightOutline.withValues(alpha: 0.95);
  }

  static double cellBorderWidth({required bool marked}) => marked ? 2 : 1;

  static Color cellForeground(BuildContext context, {required bool marked}) {
    if (marked) {
      return _isDark(context) ? gold : goldAccent;
    }
    return _isDark(context)
        ? Theme.of(context).colorScheme.onSurface
        : lightOnSurface;
  }

  static Color balanceAccent(BuildContext context) {
    return _isDark(context) ? gold : goldAccent;
  }

  static Color cartelaChipAvailableBackground(BuildContext context) {
    return casinoPurple.withValues(alpha: 0.92);
  }

  static Color cartelaChipAvailableForeground(BuildContext context) {
    return Colors.white;
  }

  static Color cartelaChipAvailableBorder(BuildContext context) {
    return gold.withValues(alpha: _isDark(context) ? 0.55 : 0.65);
  }

  static Color cartelaChipSelectedBackground(BuildContext context) {
    return _isDark(context)
        ? casinoPurple
        : brandPurple.withValues(alpha: 0.18);
  }

  static Color cartelaChipMineBackground(BuildContext context) {
    return _isDark(context)
        ? bingoFreeGreen.withValues(alpha: 0.22)
        : bingoFreeGreen.withValues(alpha: 0.22);
  }

  static Color cartelaChipMineForeground(BuildContext context) {
    return _isDark(context) ? bingoFreeGreen : const Color(0xFF15803D);
  }

  static Color cartelaChipMineBorder(BuildContext context) {
    return _isDark(context)
        ? bingoFreeGreen.withValues(alpha: 0.7)
        : bingoFreeGreen.withValues(alpha: 0.55);
  }

  static Color cartelaChipTakenBackground(BuildContext context) {
    return _isDark(context)
        ? const Color(0xFF2A2438)
        : const Color(0xFF2A2438).withValues(alpha: 0.10);
  }

  static Color cartelaChipTakenForeground(BuildContext context) {
    return _isDark(context)
        ? const Color(0xFF8A8298)
        : const Color(0xFF6B6476);
  }

  static Color cartelaChipTakenBorder(BuildContext context) {
    return _isDark(context)
        ? const Color(0xFF5C5468)
        : const Color(0xFF5C5468).withValues(alpha: 0.45);
  }

  static Color cartelaChipReservedByOtherBackground(BuildContext context) {
    return _isDark(context)
        ? const Color(0xFF2E2840)
        : lightSurfaceMuted;
  }

  static Color cartelaChipReservedByOtherForeground(BuildContext context) {
    return _isDark(context)
        ? const Color(0xFF9890A8)
        : lightOnDisabled;
  }

  static TextStyle wordmark(BuildContext context, {bool compact = false}) {
    return GoogleFonts.bebasNeue(
      fontSize: compact ? 22 : 32,
      letterSpacing: compact ? 2 : 3,
      height: 1,
      color: _isDark(context) ? gold : brandPurple,
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

  static TextStyle wordmarkBrandAccent({double size = 28}) {
    return GoogleFonts.bebasNeue(
      fontSize: size,
      letterSpacing: 2.5,
      height: 1,
      color: goldAccent,
    );
  }
}
