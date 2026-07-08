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
      expect(result.completedPatterns, isEmpty);
    });

    test('parses completedPatterns from valid claim payload', () {
      final result = BingoClaimResult.fromJson({
        'claim': {
          'id': 'claim-1',
          'gameSessionId': 'session-1',
          'userId': 'user-1',
          'gameCartelaId': 'game-cartela-1',
          'status': 'VALID',
          'checkedPattern': 'ROWS:ROW_1',
          'reason': null,
          'createdAt': '2026-06-08T10:00:00.000Z',
          'checkedAt': '2026-06-08T10:00:01.000Z',
        },
        'progress': 1,
        'isWinner': true,
        'gameStatus': 'WINNER_WINDOW',
        'gameCartelaStatus': 'WINNER',
        'completedPatterns': [
          {
            'type': 'ROW',
            'key': 'ROW_1',
            'numbers': [7, 22, 37, 56, 74],
            'cells': [
              [0, 0],
              [1, 0],
            ],
          },
        ],
      });

      expect(result.completedPatterns, hasLength(1));
      expect(result.completedPatterns.first.highlightCellIndexes, {0, 5});
    });

    test('parses winnerWindowEndsAt from claim response', () {
      final endsAt = DateTime.now().add(const Duration(seconds: 15));
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
        'gameCartelaStatus': 'WINNER',
        'winnerWindowEndsAt': endsAt.toIso8601String(),
      });

      expect(result.winnerWindowEndsAt, isNotNull);
      expect(
        result.winnerWindowEndsAt!.difference(DateTime.now()).inSeconds,
        greaterThan(10),
      );
    });

    test('parses INVALID_LATE_CLAIM reasonCode from top-level response', () {
      final result = BingoClaimResult.fromJson({
        'claim': {
          'id': 'claim-2',
          'gameSessionId': 'session-1',
          'userId': 'user-1',
          'gameCartelaId': 'game-cartela-1',
          'status': 'INVALID',
          'checkedPattern': 'COLUMN',
          'reason': 'Late claim',
          'createdAt': '2026-06-08T10:00:00.000Z',
          'checkedAt': '2026-06-08T10:00:01.000Z',
        },
        'reasonCode': 'INVALID_LATE_CLAIM',
        'progress': 1,
        'isWinner': false,
        'gameStatus': 'PLAYING',
        'gameCartelaStatus': 'BLOCKED',
      });

      expect(result.reasonCode, 'INVALID_LATE_CLAIM');
      expect(result.claim.reasonCode, isNull);
      expect(result.gameCartelaStatus, GameCartelaStatus.blocked);
    });

    test('parses nextAutoCallAt when included in claim response', () {
      final resumeAt = DateTime.parse('2026-06-08T10:00:08.000Z');
      final result = BingoClaimResult.fromJson({
        'claim': {
          'id': 'claim-3',
          'gameSessionId': 'session-1',
          'userId': 'user-1',
          'gameCartelaId': 'game-cartela-1',
          'status': 'INVALID',
          'checkedPattern': 'ROWS:ROW_1',
          'reason': 'Late claim',
          'createdAt': '2026-06-08T10:00:00.000Z',
          'checkedAt': '2026-06-08T10:00:01.000Z',
        },
        'reasonCode': 'INVALID_LATE_CLAIM',
        'progress': null,
        'isWinner': false,
        'gameStatus': 'PLAYING',
        'gameCartelaStatus': 'BLOCKED',
        'nextAutoCallAt': resumeAt.toIso8601String(),
      });

      expect(result.hasNextAutoCallAt, isTrue);
      expect(result.nextAutoCallAt, resumeAt.toLocal());
    });
  });
}
