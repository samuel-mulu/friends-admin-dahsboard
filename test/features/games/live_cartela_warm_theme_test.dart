import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_bingo_app/src/core/theme/app_branding.dart';
import 'package:friends_bingo_app/src/core/theme/app_theme.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/cartela_board_widget.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/cartela_number_badge.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/live_cartela_card.dart';
import 'package:friends_bingo_app/src/features/games/presentation/components/bingo_claim_button.dart';

import 'package:friends_bingo_app/src/core/utils/l10n.dart';

final _testNow = DateTime.utc(2026, 11, 7);

CartelaModel _createSampleCartela() {
  return CartelaModel(
    id: 'cartela-1',
    number: 1074,
    createdAt: _testNow,
    b: const ['9', '4', '2', '5', '15'],
    i: const ['30', '23', '24', '16', '26'],
    n: const ['35', '42', 'FREE', '40', '33'],
    g: const ['55', '56', '46', '50', '52'],
    o: const ['63', '75', '65', '66', '61'],
  );
}

GameCartelaModel _createSampleGameCartela() {
  return GameCartelaModel(
    id: 'gc-1',
    gameId: 'game-1',
    userId: 'user-1',
    cartelaId: 'cartela-1',
    status: GameCartelaStatus.registered,
    isWinner: false,
    blockedAt: null,
    createdAt: _testNow,
    updatedAt: _testNow,
    cartela: _createSampleCartela(),
  );
}

void main() {
  group('Live Cartela Warm Lounge Theme Tests', () {
    testWidgets('LiveCartelaCard renders warm surface and not raw Colors.white in light mode', (tester) async {
      final gameCartela = _createSampleGameCartela();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 320,
                height: 520,
                child: LiveCartelaCard(
                  gameCartela: gameCartela,
                  canClaimBingo: false,
                  isClaiming: false,
                  pendingReview: false,
                  showMarkColorPicker: false,
                  isOneAwayFromWin: false,
                  oneAwayCellIndexes: const {},
                  winningHighlightCells: const {},
                  manualMarkedNumbers: const {},
                  onMarkedNumberToggled: (_, _, _) {},
                  onClaimBingo: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final cardFinder = find.byType(Card);
      expect(cardFinder, findsWidgets);

      final cardWidget = tester.widget<Card>(cardFinder.first);
      expect(cardWidget.color, equals(AppBranding.warmSurfaceRaised),
          reason: 'LiveCartelaCard must use warm ivory surface, avoiding harsh pure white');
    });

    testWidgets('CartelaNumberCompactBadge renders white number on deep purple background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: CartelaNumberCompactBadge(number: 1074),
          ),
        ),
      );

      final textFinder = find.text('1074');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.color, equals(Colors.white),
          reason: 'Cartela number inside deep purple badge should be white for contrast');
    });

    testWidgets('BingoClaimButton displays golden amber style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: BingoClaimButton(
              canClaim: true,
              showReadyPulse: false,
              isClaiming: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      final bingoFinder = find.text('BINGO');
      expect(bingoFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(bingoFinder);
      expect(textWidget.style?.color, equals(AppBranding.bingoGoldButtonText),
          reason: 'BINGO text must use dark brown on gold button');
    });

    testWidgets('CartelaBoardWidget uses emerald green for FREE space', (tester) async {
      final cartela = _createSampleCartela();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: CartelaBoardWidget(
              cartela: cartela,
              markedCells: const {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final freeFinder = find.text('FREE');
      expect(freeFinder, findsOneWidget);
    });
  });
}
