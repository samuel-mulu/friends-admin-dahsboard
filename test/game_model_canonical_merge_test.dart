import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';

GameModel _operationGame({
  required String sessionId,
  required String playerStatus,
  required String rawStatus,
  String? winnerWindowEndsAt,
}) {
  return GameModel.fromOperationJson({
    'slotId': 'slot-auto-1',
    'sessionId': sessionId,
    'staticCode': 'FULL_HOUSE-S1',
    'playCode': 'BINGO-AUTO1',
    'playerStatus': playerStatus,
    'rawStatus': rawStatus,
    'operationMode': 'AUTO',
    'winnerWindowEndsAt': winnerWindowEndsAt,
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
}

void main() {
  test('slot payload prefers latestSession winner window status', () {
    final endsAt = DateTime.now().add(const Duration(seconds: 12));
    final game = GameModel.fromSlotJson({
      'id': 'slot-auto-1',
      'staticCode': 'FULL_HOUSE-S1',
      'status': 'PLAYING',
      'sessionId': 'session-auto-1',
      'playCode': 'BINGO-AUTO1',
      'entryFee': '10',
      'prizePerCartela': '8',
      'prizeAmount': '16',
      'registeredCartelasCount': 2,
      'calledNumbersCount': 12,
      'latestSession': {
        'id': 'session-auto-1',
        'sessionId': 'session-auto-1',
        'playCode': 'BINGO-AUTO1',
        'status': 'WINNER_WINDOW',
        'winnerWindowEndsAt': endsAt.toIso8601String(),
        'entryFee': '10',
        'prizePerCartela': '8',
        'prizeAmount': '16',
        'registeredCartelasCount': 2,
        'calledNumbersCount': 12,
      },
      'gameRule': {
        'id': 'rule-1',
        'key': 'FULL_HOUSE',
        'name': 'Full House',
      },
    });

    expect(game.status, GameStatus.winnerWindow);
    expect(game.winnerWindowEndsAt, isNotNull);
  });

  test('mergeCanonicalSessionState keeps winner window over stale playing', () {
    final endsAt = DateTime.now().add(const Duration(seconds: 10));
    final current = _operationGame(
      sessionId: 'session-auto-1',
      playerStatus: 'winnerWindow',
      rawStatus: 'WINNER_WINDOW',
      winnerWindowEndsAt: endsAt.toIso8601String(),
    );
    final incoming = _operationGame(
      sessionId: 'session-auto-1',
      playerStatus: 'playing',
      rawStatus: 'PLAYING',
    );

    final merged = GameModel.mergeCanonicalSessionState(
      current: current,
      incoming: incoming,
    );

    expect(merged.status, GameStatus.winnerWindow);
    expect(merged.winnerWindowEndsAt, isNotNull);
  });
}
