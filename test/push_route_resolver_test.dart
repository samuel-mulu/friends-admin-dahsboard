import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/notifications/app_notification_category.dart';
import 'package:friends_bingo_app/src/core/notifications/app_push_message.dart';
import 'package:friends_bingo_app/src/core/notifications/push_route_resolver.dart';

void main() {
  test('routes big game registration to big game page', () {
    final route = resolvePushRoute(
      const AppPushMessage(
        category: notificationCategoryBigGameRegistrationOpen,
        title: 'Big Game',
        body: 'Open',
        route: '/games',
      ),
    );

    expect(route, '/games/big-game');
  });

  test('routes winner window with session id to live game', () {
    final route = resolvePushRoute(
      AppPushMessage(
        category: notificationCategoryWinnerWindowStarted,
        title: 'Winner window',
        body: 'Watch now',
        data: const {'sessionId': 'session-1'},
      ),
    );

    expect(route, '/games?sessionId=session-1');
  });
}
