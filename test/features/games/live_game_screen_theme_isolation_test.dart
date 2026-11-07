import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/theme/app_theme.dart';
import 'package:friends_bingo_app/src/features/games/presentation/theme/live_play_theme_tokens.dart';

void main() {
  testWidgets('LivePlay theme wrapper provides warm scaffold without mutating base AppTheme', (tester) async {
    final baseTheme = AppTheme.light();
    expect(baseTheme.extensions[LivePlayThemeTokens], isNull);

    // Build scoped live wrapper
    final liveTheme = baseTheme.copyWith(
      scaffoldBackgroundColor: LivePlayThemeTokens.light.scaffoldBackground,
      extensions: [LivePlayThemeTokens.light],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: baseTheme,
        home: Builder(
          builder: (outerContext) {
            // Verify outer context retains base theme
            expect(Theme.of(outerContext).extension<LivePlayThemeTokens>(), isNull);

            return Theme(
              data: liveTheme,
              child: Builder(
                builder: (innerContext) {
                  final tokens = LivePlayThemeTokens.of(innerContext);
                  expect(tokens.scaffoldBackground, const Color(0xFFF3EFE6));
                  expect(Theme.of(innerContext).scaffoldBackgroundColor, const Color(0xFFF3EFE6));
                  return const Scaffold(body: Text('Live Screen'));
                },
              ),
            );
          },
        ),
      ),
    );
  });
}
