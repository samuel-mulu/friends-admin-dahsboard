import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/theme/live_play_theme_tokens.dart';

void main() {
  testWidgets('Live top cluster inherits warm ivory surface and border', (tester) async {
    const tokens = LivePlayThemeTokens.light;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: const [tokens],
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final currentTokens = LivePlayThemeTokens.of(context);
              expect(currentTokens.topClusterBackground, const Color(0xFFFAF7F0));
              expect(currentTokens.topClusterBorder, const Color(0xFFE4DBC7));
              return Container(
                decoration: BoxDecoration(
                  color: currentTokens.topClusterBackground,
                  border: Border.all(color: currentTokens.topClusterBorder),
                ),
              );
            },
          ),
        ),
      ),
    );
  });
}

