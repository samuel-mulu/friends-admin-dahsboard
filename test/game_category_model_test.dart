import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';

void main() {
  test('missing category defaults to normal', () {
    final game = GameModel.fromOperationJson({
      'slotId': 'slot-1',
      'sessionId': 'session-1',
      'staticCode': 'CODE-1',
      'playerStatus': 'registrationOpen',
      'rawStatus': 'READY',
      'entryFee': '10',
      'prizePerCartela': '8',
      'prizeAmount': '100',
      'registeredCartelasCount': 1,
      'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
    });

    expect(game.category, GameCategory.normal);
    expect(game.isBonus, isFalse);
  });

  test('unknown category safely falls back to normal', () {
    final game = GameModel.fromOperationJson({
      'slotId': 'slot-1',
      'sessionId': 'session-1',
      'staticCode': 'CODE-1',
      'playerStatus': 'registrationOpen',
      'rawStatus': 'READY',
      'category': 'MYSTERY',
      'entryFee': '10',
      'prizePerCartela': '8',
      'prizeAmount': '100',
      'registeredCartelasCount': 1,
      'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
    });

    expect(game.category, GameCategory.normal);
    expect(game.isBonus, isFalse);
    expect(game.isBigGame, isFalse);
  });

  test('big game category parses from api payload', () {
    final game = GameModel.fromOperationJson({
      'slotId': 'slot-big',
      'sessionId': 'session-big',
      'staticCode': 'BIG-1',
      'playerStatus': 'registrationOpen',
      'rawStatus': 'READY',
      'category': 'BIG_GAME',
      'isBigGame': true,
      'entryFee': '50',
      'prizePerCartela': '0',
      'prizeAmount': '5000',
      'fixedPrizeAmount': '5000',
      'maxCartelasPerPlayer': 20,
      'registrationOpensAt': '2026-07-01T09:00:00.000Z',
      'scheduledStartAt': '2026-07-01T12:00:00.000Z',
      'registeredCartelasCount': 0,
      'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
    });

    expect(game.category, GameCategory.bigGame);
    expect(game.isBigGame, isTrue);
    expect(game.registrationOpensAt, isNotNull);
    expect(game.fixedPrizeAmount, '5000');
    expect(game.maxCartelasPerPlayer, 20);
  });

  test('bonus category parses fixed prize and max cartelas', () {
    final game = GameModel.fromOperationJson({
      'slotId': 'slot-bonus',
      'sessionId': 'session-bonus',
      'staticCode': 'BONUS-1',
      'playerStatus': 'registrationOpen',
      'rawStatus': 'READY',
      'category': 'BONUS',
      'entryFee': '0',
      'prizePerCartela': '0',
      'prizeAmount': '5000.00',
      'fixedPrizeAmount': '5000.00',
      'maxCartelasPerPlayer': 5,
      'registeredCartelasCount': 0,
      'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
    });

    expect(game.category, GameCategory.bonus);
    expect(game.isBonus, isTrue);
    expect(game.fixedPrizeAmount, '5000.00');
    expect(game.maxCartelasPerPlayer, 5);
  });

  test('big gotd category parses as bonus-like paid entry', () {
    final game = GameModel.fromOperationJson({
      'slotId': 'slot-gotd',
      'sessionId': 'session-gotd',
      'staticCode': 'GOTD-1',
      'playerStatus': 'registrationOpen',
      'rawStatus': 'READY',
      'category': 'BIG_GOTD',
      'entryFee': '25',
      'prizePerCartela': '0',
      'prizeAmount': '5000.00',
      'fixedPrizeAmount': '5000.00',
      'maxCartelasPerPlayer': 5,
      'registeredCartelasCount': 0,
      'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
    });

    expect(game.category, GameCategory.bigGotd);
    expect(game.isBonus, isFalse);
    expect(game.isBigGotd, isTrue);
    expect(game.isBonusLike, isTrue);
    expect(game.hasFreeEntry, isFalse);
    expect(game.fixedPrizeAmount, '5000.00');
    expect(game.maxCartelasPerPlayer, 5);
  });
}
