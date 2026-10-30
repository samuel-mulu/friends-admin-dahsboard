import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/live_cartela_card.dart';
import 'package:friends_bingo_app/src/features/games/presentation/components/bingo_claim_button.dart';

final _now = DateTime.utc(2026, 8, 26);

GameCartelaModel _sampleGameCartela() {
  List<String> column(int col) => [
    for (var row = 0; row < 5; row++)
      row == 2 && col == 2 ? 'FREE' : '${col * 15 + row + 1}',
  ];

  return GameCartelaModel(
    id: 'game-cartela-lock-resolver',
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
      number: 7,
      createdAt: _now,
      b: column(0),
      i: column(1),
      n: column(2),
      g: column(3),
      o: column(4),
    ),
  );
}

InkWell _bingoInkWell(WidgetTester tester) {
  return tester.widget<InkWell>(
    find.descendant(
      of: find.byType(BingoClaimButton),
      matching: find.byType(InkWell),
    ),
  );
}

void main() {
  testWidgets('lock unlock re-reads resolveCanClaimBingo without card rebuild', (
    tester,
  ) async {
    final lock = ValueNotifier<bool>(true);
    var resolverEligible = false;
    var tileBuilds = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 220,
              height: 400,
              child: Builder(
                builder: (context) {
                  tileBuilds++;
                  return LiveCartelaCard(
                    gameCartela: _sampleGameCartela(),
                    canClaimBingo: false,
                    isClaiming: false,
                    pendingReview: false,
                    showMarkColorPicker: false,
                    manualMarkedNumbers: const {},
                    onMarkedNumberToggled: (_, __, ___) {},
                    onClaimBingo: () {},
                    bingoLockListenable: lock,
                    resolveCanClaimBingo: () => resolverEligible,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(tileBuilds, 1);
    expect(_bingoInkWell(tester).onTap, isNull);

    resolverEligible = true;
    lock.value = false;
    await tester.pump();

    expect(tileBuilds, 1);
    expect(_bingoInkWell(tester).onTap, isNotNull);

    lock.dispose();
  });

  testWidgets('stale canClaimBingo bool ignored when resolver returns true', (
    tester,
  ) async {
    final lock = ValueNotifier<bool>(false);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 220,
              height: 400,
              child: LiveCartelaCard(
                gameCartela: _sampleGameCartela(),
                canClaimBingo: false,
                isClaiming: false,
                pendingReview: false,
                showMarkColorPicker: false,
                manualMarkedNumbers: const {},
                onMarkedNumberToggled: (_, __, ___) {},
                onClaimBingo: () {},
                bingoLockListenable: lock,
                resolveCanClaimBingo: () => true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(_bingoInkWell(tester).onTap, isNotNull);

    lock.value = true;
    await tester.pump();
    expect(_bingoInkWell(tester).onTap, isNull);

    lock.dispose();
  });
}
