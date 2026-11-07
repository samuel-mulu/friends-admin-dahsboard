import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/theme/app_theme.dart';
import 'package:friends_bingo_app/src/features/games/presentation/theme/live_play_theme_tokens.dart';

double _luminance(Color color) {
  double channel(double value) {
    return value <= 0.03928
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double _contrastRatio(Color c1, Color c2) {
  final l1 = _luminance(c1);
  final l2 = _luminance(c2);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Live Play Reality Check - WCAG AA Contrast Verification', () {
    test('Unmarked cell text on warm cream background exceeds WCAG AA 4.5:1', () {
      const tokens = LivePlayThemeTokens.light;
      final ratio = _contrastRatio(tokens.cellUnmarkedText, tokens.cellUnmarkedBackground);
      // Brand purple #2B0A57 on cream #F5EFE6 achieves high contrast
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'Ratio was $ratio');
    });

    test('Marked cell white text on emerald green exceeds WCAG AA 3.0:1 for bold game numbers', () {
      const tokens = LivePlayThemeTokens.light;
      final ratio = _contrastRatio(tokens.cellMarkedGreenText, tokens.cellMarkedGreenFill);
      expect(ratio, greaterThanOrEqualTo(3.0), reason: 'Bold text threshold: $ratio');
    });

    test('Blocked pill red text on light red pill exceeds WCAG AA 4.5:1', () {
      const tokens = LivePlayThemeTokens.light;
      final ratio = _contrastRatio(tokens.blockedPillText, tokens.blockedPillBackground);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'Ratio was $ratio');
    });
  });

  group('Screen Isolation Reality Check', () {
    test('Global AppTheme is completely unmodified by LivePlayThemeTokens', () {
      final defaultLightTheme = AppTheme.light();
      final defaultDarkTheme = AppTheme.dark();

      expect(defaultLightTheme.extensions[LivePlayThemeTokens], isNull);
      expect(defaultDarkTheme.extensions[LivePlayThemeTokens], isNull);

      // Verify global scaffold colors remain default
      expect(defaultLightTheme.scaffoldBackgroundColor, isNot(equals(const Color(0xFFF3EFE6))));
    });
  });
}

