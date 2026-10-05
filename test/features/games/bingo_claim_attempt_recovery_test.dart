import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/bingo_claim_result.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';

void main() {
  group('Bingo claim attempt status parsing', () {
    test('parses FAILED with retryAllowed', () {
      final status = BingoClaimAttemptStatus.fromJson({
        'claimAttemptId': 'a1',
        'status': 'FAILED',
        'gameCartelaStatus': 'REGISTERED',
        'gameStatus': 'PLAYING',
        'isWinner': false,
        'retryAllowed': true,
        'failureCode': 'DB_TRANSACTION_TIMEOUT',
        'nextAutoCallAt': '2026-10-05T12:00:05.000Z',
      });

      expect(status.status, BingoClaimStatus.failed);
      expect(status.retryAllowed, isTrue);
      expect(status.gameCartelaStatus, GameCartelaStatus.registered);
      expect(status.failureCode, 'DB_TRANSACTION_TIMEOUT');
      expect(status.status.isTerminal, isTrue);
    });

    test('parses CHECKING as non-terminal', () {
      final status = BingoClaimAttemptStatus.fromJson({
        'claimAttemptId': 'a1',
        'status': 'CHECKING',
        'gameCartelaStatus': 'REGISTERED',
        'gameStatus': 'PLAYING',
        'isWinner': false,
        'retryAllowed': false,
      });

      expect(status.status, BingoClaimStatus.checking);
      expect(status.status.isTerminal, isFalse);
    });

    test('BingoClaimResult FAILED exposes retryAllowed without blocking cartela', () {
      final result = BingoClaimResult.fromJson({
        'claim': {
          'id': 'c1',
          'claimAttemptId': 'a1',
          'gameSessionId': 's1',
          'userId': 'u1',
          'gameCartelaId': 'gc1',
          'status': 'FAILED',
          'checkedPattern': null,
          'reason': 'Claim could not be completed. You can try again.',
          'failureCode': 'DB_UNAVAILABLE',
          'createdAt': '2026-10-05T12:00:00.000Z',
          'checkedAt': '2026-10-05T12:00:01.000Z',
        },
        'progress': null,
        'isWinner': false,
        'gameStatus': 'PLAYING',
        'gameCartelaStatus': 'REGISTERED',
        'failureCode': 'DB_UNAVAILABLE',
        'retryAllowed': true,
        'nextAutoCallAt': '2026-10-05T12:00:05.000Z',
      });

      expect(result.isFailed, isTrue);
      expect(result.retryAllowed, isTrue);
      expect(result.gameCartelaStatus, GameCartelaStatus.registered);
      expect(result.gameStatus, GameStatus.playing);
    });

    test('REGISTERED cartela status alone is not a claim failure signal', () {
      // Recovery must use claim-attempt status, not cartela REGISTERED.
      final attemptChecking = BingoClaimAttemptStatus.fromJson({
        'claimAttemptId': 'a1',
        'status': 'CHECKING',
        'gameCartelaStatus': 'REGISTERED',
        'gameStatus': 'PLAYING',
        'isWinner': false,
        'retryAllowed': false,
      });
      final attemptFailed = BingoClaimAttemptStatus.fromJson({
        'claimAttemptId': 'a1',
        'status': 'FAILED',
        'gameCartelaStatus': 'REGISTERED',
        'gameStatus': 'PLAYING',
        'isWinner': false,
        'retryAllowed': true,
      });

      expect(attemptChecking.gameCartelaStatus, attemptFailed.gameCartelaStatus);
      expect(attemptChecking.status, isNot(attemptFailed.status));
      expect(attemptFailed.retryAllowed, isTrue);
      expect(attemptChecking.retryAllowed, isFalse);
    });
  });
}
