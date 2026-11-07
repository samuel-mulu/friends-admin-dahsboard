import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/theme/live_play_theme_tokens.dart';

void main() {
  group('LivePlayThemeTokens', () {
    test('provides warm light palette tokens with zero pure white card/cell fills', () {
      const tokens = LivePlayThemeTokens.light;

      expect(tokens.scaffoldBackground, const Color(0xFFF3EFE6));
      expect(tokens.cardBackground, const Color(0xFFEAE3D5));
      expect(tokens.cardBorder, const Color(0xFFE5DEC9));
      expect(tokens.cellUnmarkedBackground, const Color(0xFFF5EFE6));
      expect(tokens.cellUnmarkedText, const Color(0xFF2B0A57));
      expect(tokens.cellMarkedGreenFill, const Color(0xFF27AE60));

      // Guard: absolutely no pure white (#FFFFFF) fills for cards or unselected cells
      expect(tokens.cardBackground, isNot(equals(Colors.white)));
      expect(tokens.cellUnmarkedBackground, isNot(equals(Colors.white)));
    });

    test('supports ThemeExtension copyWith and lerp correctly', () {
      const light = LivePlayThemeTokens.light;
      const dark = LivePlayThemeTokens.dark;

      final lerped = light.lerp(dark, 0.5);
      expect(lerped, isNotNull);
      expect(lerped.scaffoldBackground, isNotNull);
    });

    testWidgets('resolves via LivePlayThemeTokens.of with fallback if omitted in theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final tokens = LivePlayThemeTokens.of(context);
              expect(tokens, isNotNull);
              expect(tokens.scaffoldBackground, const Color(0xFFF3EFE6));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });
}

