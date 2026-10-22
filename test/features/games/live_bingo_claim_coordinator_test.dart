import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_bingo_claim_coordinator.dart';

void main() {
  group('LiveBingoClaimCoordinator Tests', () {
    test('blocks duplicate claims while in-flight', () {
      final coordinator = LiveBingoClaimCoordinator();
      expect(coordinator.isClaimInFlight('cartela-1'), isFalse);

      coordinator.markClaimInFlight('cartela-1');
      expect(coordinator.isClaimInFlight('cartela-1'), isTrue);
      expect(coordinator.isClaimInFlight('cartela-2'), isFalse);

      coordinator.clearClaimInFlight('cartela-1');
      expect(coordinator.isClaimInFlight('cartela-1'), isFalse);
    });

    test('stale attempt ID does not clear a newer in-flight claim', () {
      final coordinator = LiveBingoClaimCoordinator();
      coordinator.markClaimInFlight('cartela-1', 'attempt-1');
      expect(coordinator.isClaimInFlight('cartela-1'), isTrue);

      coordinator.markClaimInFlight('cartela-1', 'attempt-2');
      // Stale attempt-1 completion should not clear attempt-2
      coordinator.clearClaimInFlight('cartela-1', 'attempt-1');
      expect(coordinator.isClaimInFlight('cartela-1'), isTrue);

      // Clearing with current attempt-2 clears it
      coordinator.clearClaimInFlight('cartela-1', 'attempt-2');
      expect(coordinator.isClaimInFlight('cartela-1'), isFalse);
    });

    test('deduplicates auto bingo evaluation attempt keys', () {
      final coordinator = LiveBingoClaimCoordinator();
      const attemptKey = 'session-1:round-1:called-12';

      expect(coordinator.hasAttemptedAutoBingo(attemptKey), isFalse);

      final recorded = coordinator.recordAutoBingoAttempt(attemptKey);
      expect(recorded, isTrue);
      expect(coordinator.hasAttemptedAutoBingo(attemptKey), isTrue);

      final secondAttempt = coordinator.recordAutoBingoAttempt(attemptKey);
      expect(secondAttempt, isFalse);
    });

    test('resets all in-flight claims and keys on reset', () {
      final coordinator = LiveBingoClaimCoordinator();
      coordinator.markClaimInFlight('cartela-1');
      coordinator.recordAutoBingoAttempt('key-1');

      coordinator.reset();
      expect(coordinator.isClaimInFlight('cartela-1'), isFalse);
      expect(coordinator.hasAttemptedAutoBingo('key-1'), isFalse);
    });
  });
}
