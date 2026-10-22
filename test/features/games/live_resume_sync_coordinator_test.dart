import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_resume_sync_coordinator.dart';

void main() {
  group('LiveResumeSyncCoordinator Tests', () {
    test('prevents concurrent resume runs using sync lock', () {
      final coordinator = LiveResumeSyncCoordinator();
      expect(coordinator.isSyncInProgress, isFalse);

      final lockAcquired = coordinator.tryAcquireSyncLock();
      expect(lockAcquired, isTrue);
      expect(coordinator.isSyncInProgress, isTrue);

      final secondLock = coordinator.tryAcquireSyncLock();
      expect(secondLock, isFalse);

      coordinator.releaseSyncLock();
      expect(coordinator.isSyncInProgress, isFalse);
      expect(coordinator.lastSyncCompletedAt, isNotNull);
    });

    test('isSyncStale accurately computes elapsed time against threshold', () {
      final coordinator = LiveResumeSyncCoordinator();
      expect(coordinator.isSyncStale(const Duration(seconds: 1)), isTrue);

      coordinator.releaseSyncLock();
      expect(coordinator.isSyncStale(const Duration(minutes: 1)), isFalse);
    });

    test('shouldThrottleResumeSync throttles repeated rapid calls', () {
      final coordinator = LiveResumeSyncCoordinator();
      expect(coordinator.shouldThrottleResumeSync(), isFalse);

      coordinator.releaseSyncLock();
      expect(
        coordinator.shouldThrottleResumeSync(
          throttle: const Duration(seconds: 10),
        ),
        isTrue,
      );
    });
  });
}
