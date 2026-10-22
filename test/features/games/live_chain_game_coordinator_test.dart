import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/chain_round_plan_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_chain_game_coordinator.dart';

void main() {
  group('LiveChainGameCoordinator Tests', () {
    test('initial state is unlatched and empty plan', () {
      final coordinator = LiveChainGameCoordinator();
      expect(coordinator.latchedPausedUntil, isNull);
      expect(coordinator.latchedSessionId, isNull);
      expect(coordinator.chainRoundPlan, isNull);
      expect(coordinator.isPaused, isFalse);
    });

    test('accurately computes remaining pause seconds and notifies listeners', () {
      final now = DateTime.now();
      final pauseEndsAt = now.add(const Duration(seconds: 15));
      final coordinator = LiveChainGameCoordinator();

      coordinator.syncPauseDeadline(pauseEndsAt);
      expect(coordinator.isPaused, isTrue);
      expect(coordinator.remainingSeconds(now), 15);

      coordinator.clearPause();
      expect(coordinator.isPaused, isFalse);
      expect(coordinator.remainingSeconds(now), 0);
    });

    test('syncPauseLatch sets latched values when chain game has pausedUntil', () {
      final coordinator = LiveChainGameCoordinator();
      final pauseTime = DateTime.now().add(const Duration(seconds: 20));

      coordinator.syncPauseLatch(
        isChainGame: true,
        sessionId: 'session-101',
        roundPausedUntil: pauseTime,
      );

      expect(coordinator.latchedPausedUntil, equals(pauseTime));
      expect(coordinator.latchedSessionId, equals('session-101'));
    });

    test('clearPauseLatch resets latched values to null', () {
      final coordinator = LiveChainGameCoordinator();
      coordinator.syncPauseLatch(
        isChainGame: true,
        sessionId: 'session-101',
        roundPausedUntil: DateTime.now().add(const Duration(seconds: 20)),
      );

      coordinator.clearPauseLatch();

      expect(coordinator.latchedPausedUntil, isNull);
      expect(coordinator.latchedSessionId, isNull);
    });

    test('isRefetchLatchActive returns true only when conditions met', () {
      final coordinator = LiveChainGameCoordinator();
      final now = DateTime.now();
      final futurePause = now.add(const Duration(seconds: 15));

      // 1. Not in flight -> false
      expect(
        coordinator.isRefetchLatchActive(
          canonicalRefetchInFlight: false,
          currentSessionId: 'session-1',
          now: now,
        ),
        isFalse,
      );

      // Latched
      coordinator.syncPauseLatch(
        isChainGame: true,
        sessionId: 'session-1',
        roundPausedUntil: futurePause,
      );

      // 2. In flight & matching session & before deadline -> true
      expect(
        coordinator.isRefetchLatchActive(
          canonicalRefetchInFlight: true,
          currentSessionId: 'session-1',
          now: now,
        ),
        isTrue,
      );

      // 3. Different session -> false
      expect(
        coordinator.isRefetchLatchActive(
          canonicalRefetchInFlight: true,
          currentSessionId: 'other-session',
          now: now,
        ),
        isFalse,
      );

      // 4. Past deadline -> false
      expect(
        coordinator.isRefetchLatchActive(
          canonicalRefetchInFlight: true,
          currentSessionId: 'session-1',
          now: futurePause.add(const Duration(seconds: 1)),
        ),
        isFalse,
      );
    });

    test('updatePlan sets active plan and key', () {
      final coordinator = LiveChainGameCoordinator();
      const plan = ChainRoundPlan(
        sessionId: 'session-1',
        roundCount: 3,
        currentRound: 1,
        totalPrizeAmount: '300',
        currentRoundPrizeAmount: '100',
        rounds: [],
      );

      coordinator.setPlan(plan, key: 'plan-key-1');
      expect(coordinator.chainRoundPlan, equals(plan));
      expect(coordinator.chainRoundPlanKey, equals('plan-key-1'));

      coordinator.clearPlan();
      expect(coordinator.chainRoundPlan, isNull);
      expect(coordinator.chainRoundPlanKey, isNull);
    });
  });
}
