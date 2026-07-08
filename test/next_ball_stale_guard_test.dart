import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/next_ball_stale_guard.dart';

GameModel _playingAutoGame({DateTime? nextAutoCallAt}) {
  return GameModel.fromOperationJson({
    'slotId': 'slot-1',
    'sessionId': 'session-1',
    'staticCode': 'FULL_HOUSE-S1',
    'playCode': 'BINGO-1',
    'playerStatus': 'playing',
    'rawStatus': 'PLAYING',
    'operationMode': 'AUTO',
    'canRegister': false,
    'registrationOpen': false,
    'entryFee': '10',
    'prizePerCartela': '8',
    'prizeAmount': '16',
    'registeredCartelasCount': 2,
    'calledNumbersCount': 3,
    'nextAutoCallAt': nextAutoCallAt?.toIso8601String(),
    'gameRule': {
      'id': 'rule-1',
      'key': 'FULL_HOUSE',
      'name': 'Full House',
    },
  });
}

void main() {
  group('NextBallStaleGuard', () {
    test('called-numbers sync triggers once after 2s at zero', () {
      var now = DateTime(2026, 6, 18, 12, 0, 0);
      final guard = NextBallStaleGuard(now: () => now);
      final target = now.subtract(const Duration(seconds: 1));
      final game = _playingAutoGame(nextAutoCallAt: target);

      guard.onScheduleOrBallEvent(
        target: target,
        sessionId: 'session-1',
        rawRemaining: 0,
      );

      var result = guard.evaluate(
        game: game,
        socketAutoCallEnabled: true,
        rawRemaining: 0,
      );
      expect(result.shouldSyncCalledNumbers, isFalse);
      expect(result.shouldRefetchCanonical, isFalse);

      now = now.add(const Duration(seconds: 2));
      result = guard.evaluate(
        game: game,
        socketAutoCallEnabled: true,
        rawRemaining: 0,
      );
      expect(result.shouldSyncCalledNumbers, isTrue);
      expect(result.shouldRefetchCanonical, isFalse);

      guard.recordCalledNumbersSync('session-1');
      result = guard.evaluate(
        game: game,
        socketAutoCallEnabled: true,
        rawRemaining: 0,
      );
      expect(result.shouldSyncCalledNumbers, isFalse);
      expect(result.shouldRefetchCanonical, isFalse);
    });

    test('canonical refresh triggers once after 6s once called numbers synced', () {
      var now = DateTime(2026, 6, 18, 12, 0, 0);
      final guard = NextBallStaleGuard(now: () => now);
      final target = now.subtract(const Duration(seconds: 2));
      final game = _playingAutoGame(nextAutoCallAt: target);

      guard.onScheduleOrBallEvent(
        target: target,
        sessionId: 'session-1',
        rawRemaining: 0,
      );

      now = now.add(const Duration(seconds: 2));
      guard.evaluate(
        game: game,
        socketAutoCallEnabled: true,
        rawRemaining: 0,
      );
      guard.recordCalledNumbersSync('session-1');

      now = now.add(const Duration(seconds: 3));
      var result = guard.evaluate(
        game: game,
        socketAutoCallEnabled: true,
        rawRemaining: 0,
      );
      expect(result.shouldRefetchCanonical, isFalse);

      now = now.add(const Duration(seconds: 1));
      result = guard.evaluate(
        game: game,
        socketAutoCallEnabled: true,
        rawRemaining: 0,
      );
      expect(result.shouldRefetchCanonical, isTrue);

      guard.recordCanonicalRefetch('session-1');
      result = guard.evaluate(
        game: game,
        socketAutoCallEnabled: true,
        rawRemaining: 0,
      );
      expect(result.shouldRefetchCanonical, isFalse);
    });

    test('new target resets zero timer and recovery flags', () {
      var now = DateTime(2026, 6, 18, 12, 0, 0);
      final guard = NextBallStaleGuard(now: () => now);
      final expiredTarget = now.subtract(const Duration(seconds: 2));
      final game = _playingAutoGame(nextAutoCallAt: expiredTarget);

      guard.onScheduleOrBallEvent(
        target: expiredTarget,
        sessionId: 'session-1',
        rawRemaining: 0,
      );
      now = now.add(const Duration(seconds: 4));
      guard.evaluate(
        game: game,
        socketAutoCallEnabled: true,
        rawRemaining: 0,
      );
      guard.recordCalledNumbersSync('session-1');

      final freshTarget = now.add(const Duration(seconds: 8));
      guard.onScheduleOrBallEvent(
        target: freshTarget,
        sessionId: 'session-1',
        rawRemaining: 8,
      );

      final result = guard.evaluate(
        game: _playingAutoGame(nextAutoCallAt: freshTarget),
        socketAutoCallEnabled: true,
        rawRemaining: 8,
      );
      expect(result.shouldSyncCalledNumbers, isFalse);
      expect(result.shouldRefetchCanonical, isFalse);
      expect(result.zeroForMs, 0);
    });

    test('effective target overrides stale game field', () {
      final now = DateTime(2026, 6, 18, 12, 0, 0);
      final guard = NextBallStaleGuard(now: () => now);
      final staleTarget = now.subtract(const Duration(seconds: 2));
      final game = _playingAutoGame(nextAutoCallAt: staleTarget);

      guard.onScheduleOrBallEvent(
        target: null,
        sessionId: 'session-1',
        rawRemaining: 0,
      );

      final result = guard.evaluate(
        game: game,
        socketAutoCallEnabled: true,
        rawRemaining: 0,
        effectiveTarget: null,
        useEffectiveTarget: true,
      );

      expect(result.target, isNull);
      expect(result.shouldSyncCalledNumbers, isFalse);
      expect(result.shouldRefetchCanonical, isFalse);
    });
  });
}
