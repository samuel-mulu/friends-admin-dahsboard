import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_branding.dart';

class AppTheme {
  static ThemeData light() => _buildTheme(Brightness.light);

  static ThemeData dark() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    const seed = AppBranding.casinoPurple;

    final baseScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    final isDark = brightness == Brightness.dark;
    final colorScheme = baseScheme.copyWith(
      surface: isDark ? AppBranding.liveCardDark : Colors.white,
      onSurface: isDark ? const Color(0xFFF2EFFA) : baseScheme.onSurface,
      onSurfaceVariant:
          isDark ? const Color(0xFFB9B0CE) : baseScheme.onSurfaceVariant,
      surfaceContainerHighest:
          isDark ? const Color(0xFF322A48) : baseScheme.surfaceContainerHighest,
      surfaceContainerHigh:
          isDark ? const Color(0xFF2A2340) : baseScheme.surfaceContainerHigh,
      surfaceContainerLow:
          isDark ? AppBranding.statPillDark : baseScheme.surfaceContainerLow,
    );
    final scaffoldColor =
        isDark ? AppBranding.liveSurfaceDark : const Color(0xFFF5F3FA);
    final cardColor = isDark ? AppBranding.liveCardDark : Colors.white;
    final inputFill = isDark ? AppBranding.liveCardDark : Colors.white;

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldColor,
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? AppBranding.liveSurfaceDark : scaffoldColor,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: isDark ? AppBranding.liveSurfaceDark : scaffoldColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? colorScheme.outlineVariant.withValues(alpha: 0.35)
                : colorScheme.outlineVariant,
          ),
        ),
      ),
      textTheme: _textTheme,
    );
  }

  static final TextTheme _textTheme = TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 50,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.5,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 40,
      fontWeight: FontWeight.w700,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w700,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 25,
      fontWeight: FontWeight.w700,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 21,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w500,
    ),
  );
}
