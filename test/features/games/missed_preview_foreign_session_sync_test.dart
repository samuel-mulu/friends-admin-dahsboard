import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/missed_preview_foreign_session_sync.dart';

void main() {
  group('shouldSyncMissedPreviewForForeignSession', () {
    test('Game A event while primary is B and user owns B only → true', () {
      expect(
        shouldSyncMissedPreviewForForeignSession(
          eventSessionId: 'session-a',
          primarySessionId: 'session-b',
          trackedRegistrationSessionId: 'session-b',
          ownsSession: (id) => id == 'session-b',
        ),
        isTrue,
      );
    });

    test('event for owned primary session → false', () {
      expect(
        shouldSyncMissedPreviewForForeignSession(
          eventSessionId: 'session-a',
          primarySessionId: 'session-a',
          trackedRegistrationSessionId: null,
          ownsSession: (id) => id == 'session-a',
        ),
        isFalse,
      );
    });

    test('event for registration session only → false', () {
      expect(
        shouldSyncMissedPreviewForForeignSession(
          eventSessionId: 'session-b',
          primarySessionId: 'session-b',
          trackedRegistrationSessionId: 'session-b',
          ownsSession: (_) => false,
        ),
        isFalse,
      );
    });

    test('null session → false', () {
      expect(
        shouldSyncMissedPreviewForForeignSession(
          eventSessionId: null,
          primarySessionId: 'session-b',
          trackedRegistrationSessionId: 'session-b',
          ownsSession: (_) => false,
        ),
        isFalse,
      );
    });
  });
}
