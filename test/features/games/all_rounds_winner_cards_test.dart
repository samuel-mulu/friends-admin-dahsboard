import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/round_winner_history_adapters.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/all_rounds_winner_cards.dart';

Widget _app(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

final _threeRounds = [
  _card(roundIndex: 1, cartelaNumber: 111),
  _card(roundIndex: 1, cartelaNumber: 222),
  _card(roundIndex: 2, cartelaNumber: 333),
  _card(roundIndex: 3, cartelaNumber: 444),
];

void main() {
  testWidgets('opens on the last round and swipes back to earlier rounds', (
    tester,
  ) async {
    await tester.pumpWidget(_app(AllRoundsWinnerCards(cards: _threeRounds)));

    expect(find.text('Round 3 of 3'), findsOneWidget);
    expect(find.textContaining('444'), findsOneWidget);
    expect(find.textContaining('111'), findsNothing);

    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Round 2 of 3'), findsOneWidget);
    expect(find.textContaining('333'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Round 1 of 3'), findsOneWidget);
    expect(find.textContaining('111'), findsOneWidget);
    expect(find.textContaining('222'), findsOneWidget);
  });

  testWidgets('rounds are ordered by round index even if delivered unsorted', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        AllRoundsWinnerCards(
          cards: [
            _card(roundIndex: 3, cartelaNumber: 444),
            _card(roundIndex: 1, cartelaNumber: 111),
            _card(roundIndex: 2, cartelaNumber: 333),
          ],
        ),
      ),
    );

    expect(find.text('Round 3 of 3'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Round 2 of 3'), findsOneWidget);
  });

  testWidgets('failure shows a friendly message with Retry, not raw error', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      _app(
        AllRoundsWinnerCards(
          cards: const [],
          hasError: true,
          onRetry: () => retries++,
        ),
      ),
    );

    expect(find.text('Could not load round winners.'), findsOneWidget);
    expect(find.textContaining('ApiException'), findsNothing);

    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });

  testWidgets('loading state shows progress while waiting for the server', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const AllRoundsWinnerCards(cards: [], isLoading: true)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('refresh with a new round moves to it until the player swipes', (
    tester,
  ) async {
    final twoRounds = _threeRounds.where((c) => c.roundIndex < 3).toList();

    await tester.pumpWidget(_app(AllRoundsWinnerCards(cards: twoRounds)));
    expect(find.text('Round 2 of 3'), findsOneWidget);

    // Not navigated yet: the newly delivered last round is shown.
    await tester.pumpWidget(_app(AllRoundsWinnerCards(cards: _threeRounds)));
    await tester.pumpAndSettle();
    expect(find.text('Round 3 of 3'), findsOneWidget);

    // Player swipes back to round 2; a refresh must keep them there.
    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Round 2 of 3'), findsOneWidget);

    await tester.pumpWidget(
      _app(AllRoundsWinnerCards(cards: List.of(_threeRounds))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Round 2 of 3'), findsOneWidget);
  });
}

AllRoundsWinnerCardData _card({
  required int roundIndex,
  required int cartelaNumber,
}) {
  return AllRoundsWinnerCardData(
    roundIndex: roundIndex,
    roundCount: 3,
    cartelaNumber: cartelaNumber,
    amount: '1000.00',
    prizeAmount: '1000.00',
    isNoWinner: false,
    phoneNumber: '0962',
    winnerResults: const [],
  );
}
