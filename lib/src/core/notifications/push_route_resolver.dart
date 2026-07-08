import 'app_notification_category.dart';
import 'app_push_message.dart';

String _normalizeGamesRoute(String route) {
  if (route.startsWith('/games/live')) {
    return route.replaceFirst('/games/live', '/games');
  }
  return route;
}

String resolvePushRoute(AppPushMessage message) {
  final explicitRoute = message.route;
  if (explicitRoute != null && explicitRoute.startsWith('/')) {
    final normalized = _normalizeGamesRoute(explicitRoute);
    if (normalized.contains('sessionId=') ||
        normalized == '/games/big-game' ||
        normalized.startsWith('/wallet/')) {
      return normalized;
    }
  }

  final sessionId = message.data['sessionId'];
  switch (message.category) {
    case notificationCategoryBigGameRegistrationOpen:
    case notificationCategoryBigGameTomorrow:
    case notificationCategoryBigGameToday:
      return '/games/big-game';
    case notificationCategoryRegistrationOpen:
      return '/games';
    case notificationCategoryWinnerWindowStarted:
    case notificationCategoryGameStarted:
    case notificationCategoryBonusGameStarted:
    case notificationCategoryWinnerAnnouncement:
    case notificationCategoryGameFinished:
      if (sessionId != null && sessionId.isNotEmpty) {
        return '/games?sessionId=$sessionId';
      }
      return '/games';
    case notificationCategoryDepositApproved:
      return '/wallet/deposits';
    case notificationCategoryWithdrawalApproved:
    case notificationCategoryWithdrawalCompleted:
    case notificationCategoryWithdrawalRejected:
      return '/wallet/withdrawals';
    default:
      return explicitRoute ?? '/games';
  }
}
