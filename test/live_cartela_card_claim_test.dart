import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/live_cartela_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GameCartelaModel buildCartela() {
    final now = DateTime.utc(2026, 6, 12);
    return GameCartelaModel(
      id: 'gc-1',
      gameId: 'session-1',
      userId: 'user-1',
      cartelaId: 'c-1',
      status: GameCartelaStatus.registered,
      isWinner: false,
      blockedAt: null,
      createdAt: now,
      updatedAt: now,
      cartela: CartelaModel(
        id: 'c-1',
        number: 7,
        createdAt: now,
        b: const ['7', '13', '10', '9', '4'],
        i: const ['22', '20', '26', '18', '21'],
        n: const ['37', '43', 'FREE', '41', '42'],
        g: const ['56', '51', '57', '60', '53'],
        o: const ['74', '64', '65', '72', '62'],
      ),
    );
  }

  Widget buildHarness({
    required bool isClaiming,
    required bool isWinner,
    required bool isBlocked,
    bool freezeCartelaMarks = false,
    bool showFinishedOutcome = false,
    bool canClaimBingo = true,
    String? blockedReasonCode,
  }) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            height: 420,
            width: 220,
            child: LiveCartelaCard(
              gameCartela: buildCartela().copyWith(
                isWinner: isWinner,
                status: isBlocked
                    ? GameCartelaStatus.blocked
                    : isWinner
                    ? GameCartelaStatus.winner
                    : GameCartelaStatus.registered,
              ),
              canClaimBingo: canClaimBingo && !isClaiming && !isWinner && !isBlocked,
              isClaiming: isClaiming,
              pendingReview: false,
              showFinishedOutcome: showFinishedOutcome,
              freezeCartelaMarks: freezeCartelaMarks,
              manualMarkedNumbers: const {},
              onMarkedNumberToggled: (_, __, ___) {},
              onClaimBingo: () {},
              showMarkColorPicker: false,
              blockedReasonCode: blockedReasonCode,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows checking header while claim is in flight', (tester) async {
    await tester.pumpWidget(
      buildHarness(isClaiming: true, isWinner: false, isBlocked: false),
    );
    await tester.pump();

    expect(find.text('Checking bingo claim'), findsOneWidget);
    expect(find.text('BINGO'), findsNothing);
    expect(find.text('Valid'), findsNothing);
  });

  testWidgets('freeze marks keeps BINGO button during winner window', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        isClaiming: false,
        isWinner: false,
        isBlocked: false,
        freezeCartelaMarks: true,
        showFinishedOutcome: false,
        canClaimBingo: true,
      ),
    );
    await tester.pump();

    expect(find.text('BINGO'), findsOneWidget);
    expect(find.text('Registered'), findsNothing);
  });

  testWidgets('finished outcome hides BINGO button', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        isClaiming: false,
        isWinner: false,
        isBlocked: false,
        showFinishedOutcome: true,
      ),
    );
    await tester.pump();

    expect(find.text('BINGO'), findsNothing);
    expect(find.text('Registered'), findsOneWidget);
  });

  testWidgets('shows blocked header after invalid outcome', (tester) async {
    await tester.pumpWidget(
      buildHarness(isClaiming: false, isWinner: false, isBlocked: true),
    );
    await tester.pump();

    expect(find.text('BLOCKED'), findsOneWidget);
    expect(find.text('Checking bingo claim'), findsNothing);
  });

  testWidgets('blocked cartela shows info icon that opens reason dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        isClaiming: false,
        isWinner: false,
        isBlocked: true,
        blockedReasonCode: 'INVALID_LATE_CLAIM',
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    expect(find.text('Invalid'), findsNothing);

    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.textContaining('missed the winning call'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });
}
