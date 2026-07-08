import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/called_numbers_strip.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  group('CalledNumbersStrip lockExpanded', () {
    testWidgets('lockExpanded shows board without collapse control', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CalledNumbersStrip(
            lockExpanded: true,
            calledNumbers: [
              CalledNumberModel(
                id: 'cn-1',
                sessionId: 'session-1',
                letter: 'B',
                number: 7,
                order: 1,
                createdAt: DateTime.utc(2026, 6, 18),
              ),
            ],
          ),
        ),
      );

      expect(find.byTooltip('Hide called numbers board'), findsNothing);
      expect(find.text('B'), findsWidgets);
    });
  });
}
