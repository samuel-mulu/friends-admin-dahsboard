import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/cartela_board_widget.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/live_cartela_card.dart';

final _now = DateTime.utc(2026, 8, 26);

GameCartelaModel _sampleGameCartela() {
  List<String> column(int col) => [
    for (var row = 0; row < 5; row++)
      row == 2 && col == 2 ? 'FREE' : '${col * 15 + row + 1}',
  ];

  return GameCartelaModel(
    id: 'game-cartela-pulse',
    gameId: 'game-1',
    userId: 'user-1',
    cartelaId: 'cartela-1',
    status: GameCartelaStatus.registered,
    isWinner: false,
    blockedAt: null,
    createdAt: _now,
    updatedAt: _now,
    cartela: CartelaModel(
      id: 'cartela-1',
      number: 42,
      createdAt: _now,
      b: column(0),
      i: column(1),
      n: column(2),
      g: column(3),
      o: column(4),
    ),
  );
}

CartelaModel _boardCartela() => _sampleGameCartela().cartela;

void main() {
  testWidgets('one-away board pulses cells when enabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 280,
            child: CartelaBoardWidget(
              cartela: _boardCartela(),
              markedCells: const {},
              oneAwayCellIndexes: const {4},
              showHeader: false,
              expandToFill: true,
              pulseOneAwayCells: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AnimatedBuilder), findsWidgets);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });

  testWidgets('one-away live card pulses when claim is session-eligible', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 220,
              height: 400,
              child: LiveCartelaCard(
                gameCartela: _sampleGameCartela(),
                canClaimBingo: true,
                isClaiming: false,
                pendingReview: false,
                showMarkColorPicker: false,
                manualMarkedNumbers: const {},
                onMarkedNumberToggled: (_, __, ___) {},
                onClaimBingo: () {},
                isOneAwayFromWin: true,
                hasLocalPatternComplete: false,
                oneAwayCellIndexes: const {4},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AnimatedBuilder), findsWidgets);

    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  });
}
