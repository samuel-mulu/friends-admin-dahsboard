import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/storage/app_preferences_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppPreferencesStorage first-launch preferences', () {
    test('defaults to incomplete on fresh install', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await AppPreferencesStorage.create();

      expect(storage.hasCompletedFirstLaunchPreferences(), isFalse);
    });

    test('marks completion and persists across reads', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await AppPreferencesStorage.create();

      await storage.markFirstLaunchPreferencesCompleted();

      expect(storage.hasCompletedFirstLaunchPreferences(), isTrue);

      final reread = await AppPreferencesStorage.create();
      expect(reread.hasCompletedFirstLaunchPreferences(), isTrue);
    });

    test('reads pre-seeded completion flag', () async {
      SharedPreferences.setMockInitialValues({
        'first_launch_preferences_completed': true,
      });
      final storage = await AppPreferencesStorage.create();

      expect(storage.hasCompletedFirstLaunchPreferences(), isTrue);
    });
  });
}
