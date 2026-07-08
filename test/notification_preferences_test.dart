import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/notifications/app_notification_category.dart';
import 'package:friends_bingo_app/src/core/notifications/notification_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('notification settings persist', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = NotificationPreferencesStore(prefs);

    await store.save(
      const NotificationPreferencesState(
        pushEnabled: false,
        gameStartedEnabled: false,
        gameFinishedEnabled: true,
        winnerAnnouncementsEnabled: false,
        depositApprovedEnabled: true,
        systemEnabled: false,
      ),
    );

    final restored = store.load();
    expect(restored.pushEnabled, isFalse);
    expect(restored.gameStartedEnabled, isFalse);
    expect(restored.gameFinishedEnabled, isTrue);
    expect(restored.winnerAnnouncementsEnabled, isFalse);
    expect(restored.depositApprovedEnabled, isTrue);
    expect(restored.systemEnabled, isFalse);
  });

  test('new game push categories respect game started toggle', () {
    const disabled = NotificationPreferencesState(gameStartedEnabled: false);
    const enabled = NotificationPreferencesState(gameStartedEnabled: true);

    for (final category in [
      notificationCategoryRegistrationOpen,
      notificationCategoryBigGameRegistrationOpen,
      notificationCategoryBigGameTomorrow,
      notificationCategoryBigGameToday,
      notificationCategoryBonusGameStarted,
    ]) {
      expect(disabled.allowsCategory(category), isFalse);
      expect(enabled.allowsCategory(category), isTrue);
    }
  });

  test('withdrawal completed follows withdrawal approved toggle', () {
    const disabled = NotificationPreferencesState(
      withdrawalApprovedEnabled: false,
    );
    const enabled = NotificationPreferencesState(withdrawalApprovedEnabled: true);

    expect(
      disabled.allowsCategory(notificationCategoryWithdrawalCompleted),
      isFalse,
    );
    expect(
      enabled.allowsCategory(notificationCategoryWithdrawalCompleted),
      isTrue,
    );
  });
}
