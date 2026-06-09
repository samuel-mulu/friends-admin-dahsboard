import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/bingo_claim_result.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';

void main() {
  group('BingoClaimResult', () {
    test('parses claim payload when only gameSessionId is provided', () {
      final result = BingoClaimResult.fromJson({
        'claim': {
          'id': 'claim-1',
          'gameSessionId': 'session-1',
          'userId': 'user-1',
          'gameCartelaId': 'game-cartela-1',
          'status': 'VALID',
          'checkedPattern': 'FULL_HOUSE',
          'reason': null,
          'createdAt': '2026-06-08T10:00:00.000Z',
          'checkedAt': '2026-06-08T10:00:01.000Z',
        },
        'progress': 1,
        'isWinner': true,
        'gameStatus': 'WINNER_WINDOW',
        'gameCartelaStatus': 'REGISTERED',
      });

      expect(result.claim.gameId, 'session-1');
      expect(result.isWinner, isTrue);
      expect(result.gameStatus, GameStatus.winnerWindow);
      expect(result.gameCartelaStatus, GameCartelaStatus.registered);
    });
  });
}
