import 'package:flutter_test/flutter_test.dart';

import 'package:friends_bingo_app/src/core/notifications/app_notification_category.dart';
import 'package:friends_bingo_app/src/core/notifications/notification_display_policy.dart';

void main() {
  test('dedupes the same category and entity within the window', () {
    final throttle = NotificationDisplayThrottle(
      nowMs: () => 1_000_000,
    );

    expect(
      throttle.shouldDisplay(
        category: notificationCategoryRegistrationOpen,
        entityId: 'session-1',
      ),
      isTrue,
    );
    throttle.recordDisplayed(
      category: notificationCategoryRegistrationOpen,
      entityId: 'session-1',
    );

    expect(
      throttle.shouldDisplay(
        category: notificationCategoryRegistrationOpen,
        entityId: 'session-1',
      ),
      isFalse,
    );
  });

  test('rate-limits routine pushes but keeps winner pushes', () {
    var now = 0;
    final throttle = NotificationDisplayThrottle(nowMs: () => now);

    for (var index = 0; index < 4; index++) {
      expect(
        throttle.shouldDisplay(
          category: notificationCategoryGameStarted,
          entityId: 'session-$index',
        ),
        isTrue,
      );
      throttle.recordDisplayed(
        category: notificationCategoryGameStarted,
        entityId: 'session-$index',
      );
    }

    expect(
      throttle.shouldDisplay(
        category: notificationCategoryGameStarted,
        entityId: 'session-5',
      ),
      isFalse,
    );

    expect(
      throttle.shouldDisplay(
        category: notificationCategoryWinnerAnnouncement,
        entityId: 'session-5',
      ),
      isTrue,
    );
  });
}
