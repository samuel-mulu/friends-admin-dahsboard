import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';

void main() {
  group('AUTO operation mode parsing', () {
    test('parses scheduledStartAt and canRegister from operations payload', () {
      final game = GameModel.fromOperationJson({
        'slotId': 'slot-auto-1',
        'sessionId': 'session-auto-1',
        'staticCode': 'FULL_HOUSE-S1',
        'playCode': 'BINGO-AUTO1',
        'playerStatus': 'registrationOpen',
        'rawStatus': 'READY',
        'operationMode': 'AUTO',
        'registrationDurationSeconds': 60,
        'autoCallIntervalSeconds': 7,
        'scheduledStartAt': '2026-06-10T12:01:00.000Z',
        'canRegister': true,
        'registrationOpen': true,
        'entryFee': '10',
        'prizePerCartela': '8',
        'prizeAmount': '0',
        'registeredCartelasCount': 0,
        'calledNumbersCount': 0,
        'gameRule': {
          'id': 'rule-1',
          'key': 'FULL_HOUSE',
          'name': 'Full House',
        },
      });

      expect(game.operationMode, 'AUTO');
      expect(game.scheduledStartAt, isNotNull);
      expect(game.canRegister, isTrue);
    });

    test('canRegister false hides registration after AUTO starts', () {
      final game = GameModel.fromOperationJson({
        'slotId': 'slot-auto-1',
        'sessionId': 'session-auto-1',
        'staticCode': 'FULL_HOUSE-S1',
        'playCode': 'BINGO-AUTO1',
        'playerStatus': 'playing',
        'rawStatus': 'PLAYING',
        'operationMode': 'AUTO',
        'canRegister': false,
        'registrationOpen': false,
        'entryFee': '10',
        'prizePerCartela': '8',
        'prizeAmount': '16',
        'registeredCartelasCount': 2,
        'calledNumbersCount': 1,
        'gameRule': {
          'id': 'rule-1',
          'key': 'FULL_HOUSE',
          'name': 'Full House',
        },
      });

      expect(game.canRegister, isFalse);
      expect(game.playerStatus, PlayerGameStatus.playing);
    });

    test('winner window countdown uses winnerWindowEndsAt from operations', () {
      final endsAt = DateTime.now().add(const Duration(seconds: 15));
      final game = GameModel.fromOperationJson({
        'slotId': 'slot-auto-1',
        'sessionId': 'session-auto-1',
        'staticCode': 'FULL_HOUSE-S1',
        'playCode': 'BINGO-AUTO1',
        'playerStatus': 'winnerWindow',
        'rawStatus': 'WINNER_WINDOW',
        'operationMode': 'AUTO',
        'winnerWindowEndsAt': endsAt.toIso8601String(),
        'canRegister': false,
        'registrationOpen': false,
        'entryFee': '10',
        'prizePerCartela': '8',
        'prizeAmount': '16',
        'registeredCartelasCount': 2,
        'calledNumbersCount': 12,
        'gameRule': {
          'id': 'rule-1',
          'key': 'FULL_HOUSE',
          'name': 'Full House',
        },
      });

      expect(game.winnerWindowEndsAt, isNotNull);
      expect(
        game.winnerWindowEndsAt!.difference(DateTime.now()).inSeconds,
        greaterThan(10),
      );
      expect(game.canRegister, isFalse);
    });

    test('parses nextAutoCallAt from operations payload', () {
      final nextCall = DateTime.now().add(const Duration(seconds: 6));
      final game = GameModel.fromOperationJson({
        'slotId': 'slot-auto-1',
        'sessionId': 'session-auto-1',
        'staticCode': 'FULL_HOUSE-S1',
        'playCode': 'BINGO-AUTO1',
        'playerStatus': 'playing',
        'rawStatus': 'PLAYING',
        'operationMode': 'AUTO',
        'nextAutoCallAt': nextCall.toIso8601String(),
        'canRegister': false,
        'registrationOpen': false,
        'entryFee': '10',
        'prizePerCartela': '8',
        'prizeAmount': '16',
        'registeredCartelasCount': 2,
        'calledNumbersCount': 0,
        'gameRule': {
          'id': 'rule-1',
          'key': 'FULL_HOUSE',
          'name': 'Full House',
        },
      });

      expect(game.nextAutoCallAt, isNotNull);
      expect(
        game.nextAutoCallAt!.difference(DateTime.now()).inSeconds,
        greaterThan(3),
      );
    });

    test('rawStatus PLAYING wins over stale registrationOpen playerStatus', () {
      final game = GameModel.fromOperationJson({
        'slotId': 'slot-auto-1',
        'sessionId': 'session-auto-1',
        'staticCode': 'FULL_HOUSE-S1',
        'playCode': 'BINGO-AUTO1',
        'playerStatus': 'registrationOpen',
        'rawStatus': 'PLAYING',
        'operationMode': 'AUTO',
        'canRegister': false,
        'registrationOpen': false,
        'entryFee': '10',
        'prizePerCartela': '8',
        'prizeAmount': '16',
        'registeredCartelasCount': 1,
        'calledNumbersCount': 2,
        'gameRule': {
          'id': 'rule-1',
          'key': 'FULL_HOUSE',
          'name': 'Full House',
        },
      });

      expect(game.status, GameStatus.playing);
      expect(game.playerStatus, PlayerGameStatus.playing);
    });

    test('registration countdown uses scheduledStartAt from operations', () {
      final target = DateTime.now().add(const Duration(seconds: 45));
      final game = GameModel.fromOperationJson({
        'slotId': 'slot-auto-1',
        'sessionId': 'session-auto-1',
        'staticCode': 'FULL_HOUSE-S1',
        'playCode': 'BINGO-AUTO1',
        'playerStatus': 'registrationOpen',
        'rawStatus': 'READY',
        'operationMode': 'AUTO',
        'scheduledStartAt': target.toIso8601String(),
        'canRegister': true,
        'registrationOpen': true,
        'entryFee': '10',
        'prizePerCartela': '8',
        'prizeAmount': '0',
        'registeredCartelasCount': 0,
        'calledNumbersCount': 0,
        'gameRule': {
          'id': 'rule-1',
          'key': 'FULL_HOUSE',
          'name': 'Full House',
        },
      });

      expect(game.scheduledStartAt, isNotNull);
      expect(
        game.scheduledStartAt!.difference(DateTime.now()).inSeconds,
        greaterThan(40),
      );
    });
  });
}
