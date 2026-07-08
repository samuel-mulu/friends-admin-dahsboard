import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';

void main() {
  group('automatic rule helpers', () {
    test('FULL_HOUSE is treated as automatic', () {
      final game = GameModel.fromOperationJson({
        'slotId': 'slot-1',
        'sessionId': 'session-1',
        'staticCode': 'FULL-S1',
        'playCode': 'BINGO-ABC123',
        'playerStatus': 'playing',
        'rawStatus': 'PLAYING',
        'entryFee': '10',
        'prizePerCartela': '8',
        'prizeAmount': '80',
        'registeredCartelasCount': 1,
        'calledNumbersCount': 5,
        'gameRule': {
          'id': 'rule-full',
          'key': 'FULL_HOUSE',
          'name': 'FULL-HOUSE',
        },
      });

      expect(game.isAutomaticRule, isTrue);
    });

    test('MANUAL is not automatic', () {
      final game = GameModel.fromOperationJson({
        'slotId': 'slot-1',
        'sessionId': 'session-1',
        'staticCode': 'MANUAL-S1',
        'playCode': 'BINGO-ABC123',
        'playerStatus': 'checking',
        'rawStatus': 'CHECKING',
        'entryFee': '10',
        'prizePerCartela': '8',
        'prizeAmount': '80',
        'registeredCartelasCount': 1,
        'calledNumbersCount': 5,
        'gameRule': {
          'id': 'rule-manual',
          'key': 'MANUAL',
          'name': 'Manual',
        },
      });

      expect(game.isAutomaticRule, isFalse);
    });
  });
}
