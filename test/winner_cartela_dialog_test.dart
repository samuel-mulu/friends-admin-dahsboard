import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/features/games/data/models/completed_pattern_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/session_winner_result_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/winning_ball_cell.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/winner_cartela_dialog.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/winner_cartela_number_strip.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  SessionWinnerResultModel winner({
    required int number,
    String id = 'gc',
  }) {
    return SessionWinnerResultModel(
      gameCartelaId: '$id-$number',
      cartelaId: 'c-$number',
      cartelaNumber: number,
      amount: '120',
      owner: 'ME',
      columns: const [
        ['1', '2', '3', '4', '5'],
        ['16', '17', '18', '19', '20'],
        ['31', '32', 'FREE', '34', '35'],
        ['46', '47', '48', '49', '50'],
        ['61', '62', '63', '64', '65'],
      ],
      completedPatterns: const [
        CompletedPatternModel(
          type: 'row',
          numbers: [1, 2, 3, 4, 5],
          highlightCellIndexes: {0, 1, 2, 3, 4},
        ),
      ],
      winningBallCellIndex: 0,
      lastCalledNumber: SessionWinnerLastCalledNumber(
        letter: 'B',
        number: 1,
      ),
    );
  }

  testWidgets('opens winner dialog with session title and winning ball', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showWinnerCartelaDialog(
                  context: context,
                  results: [winner(number: 4)],
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Winning cartelas'), findsOneWidget);
    expect(find.text('Winning cartela #4'), findsOneWidget);
    expect(find.text('Winning ball: B-1'), findsOneWidget);
  });

  testWidgets('multiple winners show chips and swipe hint', (tester) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showWinnerCartelaDialog(
                  context: context,
                  results: [
                    winner(number: 4, id: 'a'),
                    winner(number: 12, id: 'b'),
                  ],
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(WinnerCartelaNumberStrip), findsOneWidget);
    expect(find.text('#4'), findsWidgets);
    expect(find.text('#12'), findsWidgets);
    expect(
      find.text('Swipe or tap a number to see each winner'),
      findsOneWidget,
    );
  });

  testWidgets('tapping chip changes active winner page', (tester) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showWinnerCartelaDialog(
                  context: context,
                  results: [
                    winner(number: 4, id: 'a'),
                    winner(number: 12, id: 'b'),
                  ],
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('#12').last);
    await tester.pumpAndSettle();

    expect(find.text('Winning cartela #12'), findsOneWidget);
  });

  testWidgets('shows winning ball label from API even when not on cartela', (
    tester,
  ) async {
    final mismatched = SessionWinnerResultModel(
      gameCartelaId: 'gc-270',
      cartelaId: 'c-270',
      cartelaNumber: 270,
      amount: '120',
      owner: 'ME',
      columns: const [
        ['6', '3', '14', '4', '13'],
        ['20', '26', '22', '19', '25'],
        ['37', '44', 'FREE', '38', '40'],
        ['59', '50', '53', '55', '48'],
        ['64', '73', '74', '61', '70'],
      ],
      completedPatterns: const [
        CompletedPatternModel(
          type: 'square',
          numbers: [6, 20, 3, 26],
          highlightCellIndexes: {0, 1, 5, 6},
        ),
      ],
      lastCalledNumber: SessionWinnerLastCalledNumber(
        letter: 'I',
        number: 24,
      ),
    );

    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showWinnerCartelaDialog(
                  context: context,
                  results: [mismatched],
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Winning cartela #270'), findsOneWidget);
    expect(find.text('Winning ball: I-24'), findsOneWidget);
  });
}
