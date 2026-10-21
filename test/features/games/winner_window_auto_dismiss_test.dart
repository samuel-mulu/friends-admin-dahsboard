import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/session_winner_result_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/winner_cartela_dialog.dart';
import 'package:friends_bingo_app/src/core/utils/l10n.dart';

void main() {
  testWidgets('WinnerCartelaDialog auto-dismisses after autoDismissDuration', (tester) async {
    const winnerResult = SessionWinnerResultModel(
      gameCartelaId: 'gc-1',
      cartelaId: 'c-1',
      cartelaNumber: 42,
      amount: '150.00',
      columns: [
        ['1', '2', '3', '4', '5'],
        ['16', '17', '18', '19', '20'],
        ['31', '32', 'FREE', '34', '35'],
        ['46', '47', '48', '49', '50'],
        ['61', '62', '63', '64', '65'],
      ],
      completedPatterns: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showWinnerCartelaDialog(
                    context: context,
                    results: [winnerResult],
                    autoDismissDuration: const Duration(seconds: 2),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      ),
    );

    // Tap to show dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Dialog should be visible
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('2s'), findsOneWidget);

    // Advance 1 second
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1s'), findsOneWidget);

    // Advance past expiration
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Dialog should be dismissed
    expect(find.byType(Dialog), findsNothing);
  });
}
