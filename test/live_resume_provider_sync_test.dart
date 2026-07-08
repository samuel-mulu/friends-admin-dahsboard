import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/sync/resume_sync_guard.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_game_resume_owner_registry.dart';

void main() {
  tearDown(() {
    LiveGameResumeOwnerRegistry.resetForTest();
    ResumeSyncGuard.resetForTest();
  });

  group('LiveGameResumeOwnerRegistry', () {
    test('tracks nested activate/deactivate', () {
      expect(LiveGameResumeOwnerRegistry.ownerCount, 0);
      expect(LiveGameResumeOwnerRegistry.isActive, isFalse);

      LiveGameResumeOwnerRegistry.activate();
      LiveGameResumeOwnerRegistry.activate();
      expect(LiveGameResumeOwnerRegistry.ownerCount, 2);
      expect(LiveGameResumeOwnerRegistry.isActive, isTrue);

      LiveGameResumeOwnerRegistry.deactivate();
      expect(LiveGameResumeOwnerRegistry.ownerCount, 1);
      expect(LiveGameResumeOwnerRegistry.isActive, isTrue);
    });
  });

  group('ResumeSyncGuard', () {
    test('starts false and resets for tests', () {
      expect(ResumeSyncGuard.inFlight, isFalse);
      ResumeSyncGuard.inFlight = true;
      expect(ResumeSyncGuard.inFlight, isTrue);
      ResumeSyncGuard.resetForTest();
      expect(ResumeSyncGuard.inFlight, isFalse);
    });
  });
}
