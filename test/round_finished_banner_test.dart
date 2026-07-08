import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/features/games/data/models/session_winner_result_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/round_finished_banner.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  const winnerResult = SessionWinnerResultModel(
    gameCartelaId: 'gc-4',
    cartelaId: 'c-4',
    cartelaNumber: 4,
    amount: '120',
    owner: 'PLAYER',
    columns: [
      ['1', '2', '3', '4', '5'],
      ['6', '7', '8', '9', '10'],
      ['11', '12', 'FREE', '14', '15'],
      ['16', '17', '18', '19', '20'],
      ['21', '22', '23', '24', '25'],
    ],
    completedPatterns: [],
  );

  testWidgets('shows finished title, winner cartela, and countdown', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        RoundFinishedBanner(
          isLoading: false,
          isLoaded: true,
          results: const [winnerResult],
          winnerCartelaNumbers: const [4],
          secondsRemaining: 22,
          onNext: () {},
          onOpenWinners: () {},
        ),
      ),
    );

    expect(find.text('Game Finished'), findsOneWidget);
    expect(find.text('Cartela #4'), findsOneWidget);
    expect(find.text('Continue in 22s'), findsOneWidget);
    expect(find.text('Tap to view winning cartela'), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('does not open winners automatically on build', (tester) async {
    var winnersOpened = false;

    await tester.pumpWidget(
      wrap(
        RoundFinishedBanner(
          isLoading: false,
          isLoaded: true,
          results: const [winnerResult],
          winnerCartelaNumbers: const [4],
          secondsRemaining: 22,
          onNext: () {},
          onOpenWinners: () => winnersOpened = true,
        ),
      ),
    );

    expect(winnersOpened, isFalse);
  });

  testWidgets('opens winners only when banner is tapped', (tester) async {
    var winnersOpened = false;

    await tester.pumpWidget(
      wrap(
        RoundFinishedBanner(
          isLoading: false,
          isLoaded: true,
          results: const [winnerResult],
          winnerCartelaNumbers: const [4],
          secondsRemaining: 22,
          onNext: () {},
          onOpenWinners: () => winnersOpened = true,
        ),
      ),
    );

    await tester.tap(find.byType(RoundFinishedBanner));
    await tester.pump();

    expect(winnersOpened, isTrue);
  });

  testWidgets('invokes onNext when Continue is tapped', (tester) async {
    var nextTapped = false;

    await tester.pumpWidget(
      wrap(
        RoundFinishedBanner(
          isLoading: false,
          isLoaded: true,
          results: const [winnerResult],
          winnerCartelaNumbers: const [4],
          secondsRemaining: 22,
          onNext: () => nextTapped = true,
        ),
      ),
    );

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(nextTapped, isTrue);
  });

  testWidgets('shows loading state while winner results fetch', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const RoundFinishedBanner(
          isLoading: true,
          isLoaded: false,
          results: [],
          winnerCartelaNumbers: [4],
          secondsRemaining: 30,
        ),
      ),
    );

    expect(find.text('Game Finished'), findsOneWidget);
    expect(find.text('Loading round results…'), findsOneWidget);
    expect(find.text('Continue in 30s'), findsOneWidget);
  });

  testWidgets('shows advancing state while opening next round', (tester) async {
    await tester.pumpWidget(
      wrap(
        const RoundFinishedBanner(
          isLoading: false,
          isLoaded: true,
          results: [winnerResult],
          winnerCartelaNumbers: [4],
          secondsRemaining: 0,
          isAdvancing: true,
          onNext: _noop,
        ),
      ),
    );

    expect(find.text('Opening next round…'), findsOneWidget);
    expect(find.text('Cartela #4'), findsNothing);
    expect(find.text('Continue in 0s'), findsNothing);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('shows one no-winner review state', (tester) async {
    await tester.pumpWidget(
      wrap(
        const RoundFinishedBanner(
          isLoading: false,
          isLoaded: true,
          results: [],
          winnerCartelaNumbers: [],
          secondsRemaining: 12,
          isNoWinner: true,
        ),
      ),
    );

    expect(find.text('No winners this round.'), findsOneWidget);
    expect(find.text('All numbers were called.'), findsOneWidget);
    expect(find.text('Next game will open shortly.'), findsOneWidget);
    expect(find.text('Tap to view winning cartela'), findsNothing);
  });
}

void _noop() {}
