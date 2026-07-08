import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_branding.dart';
import 'app_spacing.dart';

class AppTheme {
  static ThemeData light() => _buildTheme(Brightness.light);

  static ThemeData dark() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark
        ? ColorScheme.fromSeed(
            seedColor: AppBranding.casinoPurple,
            brightness: Brightness.dark,
          ).copyWith(
            surface: AppBranding.liveCardDark,
            onSurface: const Color(0xFFF2EFFA),
            onSurfaceVariant: const Color(0xFFB9B0CE),
            surfaceContainerHighest: const Color(0xFF322A48),
            surfaceContainerHigh: const Color(0xFF2A2340),
            surfaceContainerLow: AppBranding.statPillDark,
          )
        : const ColorScheme(
            brightness: Brightness.light,
            primary: AppBranding.brandPurple,
            onPrimary: Colors.white,
            primaryContainer: Color(0xFFEDE4F8),
            onPrimaryContainer: AppBranding.brandPurple,
            secondary: AppBranding.goldAccent,
            onSecondary: AppBranding.brandPurple,
            secondaryContainer: Color(0xFFF8EDD4),
            onSecondaryContainer: AppBranding.brandPurple,
            tertiary: AppBranding.feltGreen,
            onTertiary: Colors.white,
            error: Color(0xFFDC2626),
            onError: Colors.white,
            surface: AppBranding.lightSurface,
            onSurface: AppBranding.lightOnSurface,
            onSurfaceVariant: AppBranding.lightOnSurfaceMuted,
            outline: AppBranding.lightOutline,
            outlineVariant: Color(0xFFEDE0C8),
            surfaceContainerHighest: AppBranding.lightSurfaceSubtle,
            surfaceContainerHigh: AppBranding.lightSurfaceMuted,
            surfaceContainerLow: AppBranding.lightSurfaceRaised,
            surfaceContainer: AppBranding.lightSurface,
            shadow: AppBranding.brandPurple,
            scrim: Colors.black,
            inverseSurface: AppBranding.brandPurple,
            onInverseSurface: Colors.white,
            inversePrimary: AppBranding.goldAccent,
          );

    final scaffoldColor =
        isDark ? AppBranding.liveSurfaceDark : AppBranding.lightScaffold;
    final cardColor = isDark ? AppBranding.liveCardDark : AppBranding.lightSurface;
    final inputFill = isDark ? AppBranding.liveCardDark : Colors.white;
    final cardBorderColor = isDark
        ? colorScheme.outlineVariant.withValues(alpha: 0.35)
        : AppBranding.lightOutline.withValues(alpha: 0.85);

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldColor,
      drawerTheme: DrawerThemeData(
        backgroundColor:
            isDark ? AppBranding.liveSurfaceDark : AppBranding.lightScaffold,
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
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIconColor: colorScheme.primary,
        suffixIconColor: colorScheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark
                ? colorScheme.outlineVariant.withValues(alpha: 0.35)
                : AppBranding.lightOutline.withValues(alpha: 0.75),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark
                ? colorScheme.outlineVariant.withValues(alpha: 0.35)
                : AppBranding.lightOutline.withValues(alpha: 0.75),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark ? colorScheme.primary : AppBranding.goldAccent,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorderColor),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: isDark
              ? colorScheme.surfaceContainerHighest
              : AppBranding.lightOnDisabled.withValues(alpha: 0.25),
          disabledForegroundColor: isDark
              ? colorScheme.onSurfaceVariant
              : AppBranding.lightOnDisabled,
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          backgroundColor: isDark ? null : AppBranding.lightSurface,
          side: BorderSide(
            color: isDark
                ? colorScheme.outlineVariant
                : AppBranding.lightOutline,
          ),
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        modalBackgroundColor: cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: isDark
            ? colorScheme.onSurfaceVariant
            : AppBranding.lightOutline,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cardBorderColor),
        ),
        titleTextStyle: _textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? colorScheme.outlineVariant.withValues(alpha: 0.35)
            : AppBranding.lightOutline.withValues(alpha: 0.55),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        textColor: colorScheme.onSurface,
        selectedColor: colorScheme.primary,
        selectedTileColor: isDark
            ? AppBranding.casinoPurple.withValues(alpha: 0.22)
            : AppBranding.brandPurple.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onPrimary;
            }
            return colorScheme.onSurface;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary;
            }
            return isDark ? colorScheme.surfaceContainerHigh : Colors.white;
          }),
          side: WidgetStateProperty.all(
            BorderSide(
              color: isDark
                  ? colorScheme.outlineVariant
                  : AppBranding.lightOutline,
            ),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? colorScheme.surfaceContainerHigh
            : AppBranding.lightSurfaceMuted,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        side: BorderSide(
          color: isDark
              ? colorScheme.outlineVariant.withValues(alpha: 0.35)
              : AppBranding.lightOutline.withValues(alpha: 0.75),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppBranding.liveCardDark : AppBranding.brandPurple,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
