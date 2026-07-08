import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/registration_reg_display_count.dart';

GameModel _game({GameCategory category = GameCategory.normal}) {
  final now = DateTime.utc(2026, 7, 3);
  return GameModel(
    id: 'game-1',
    sessionId: 'session-1',
    staticCode: 'ABC',
    playCode: '123',
    name: 'Test',
    gameRule: null,
    gameType: 'FOUR_CORNERS',
    entryFee: '5.00',
    prizePerCartela: '10.00',
    companyFeePerCartela: '1.00',
    prizeAmount: '100.00',
    companyRevenue: '20.00',
    status: GameStatus.ready,
    playOrder: 1,
    startedAt: null,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 42,
    calledNumbersCount: 0,
    registrationOpen: true,
    canRegister: true,
    category: category,
  );
}

void main() {
  test('normal game shows session registration total', () {
    expect(
      registrationRegDisplayCount(
        game: _game(),
        myRegisteredCount: 2,
        registrationStateCount: 55,
      ),
      55,
    );

    expect(
      registrationRegDisplayCount(
        game: _game(),
        myRegisteredCount: 2,
      ),
      42,
    );
  });

  test('bonus and big gotd show only my registration count', () {
    for (final category in [GameCategory.bonus, GameCategory.bigGotd]) {
      expect(
        registrationRegDisplayCount(
          game: _game(category: category),
          myRegisteredCount: 3,
          registrationStateCount: 99,
        ),
        3,
      );
    }
  });
}
