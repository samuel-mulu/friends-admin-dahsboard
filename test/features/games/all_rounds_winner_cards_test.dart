import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/round_winner_history_adapters.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/all_rounds_winner_cards.dart';

void main() {
  testWidgets('round label follows the horizontal page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AllRoundsWinnerCards(
            cards: [
              _card(roundIndex: 1, cartelaNumber: 111),
              _card(roundIndex: 1, cartelaNumber: 222),
              _card(roundIndex: 2, cartelaNumber: 333),
              _card(roundIndex: 3, cartelaNumber: 444),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Round 1 of 3'), findsOneWidget);
    expect(find.textContaining('111'), findsOneWidget);
    expect(find.textContaining('222'), findsOneWidget);
    expect(find.textContaining('333'), findsNothing);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Round 2 of 3'), findsOneWidget);
    expect(find.textContaining('333'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Round 3 of 3'), findsOneWidget);
    expect(find.textContaining('444'), findsOneWidget);
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
