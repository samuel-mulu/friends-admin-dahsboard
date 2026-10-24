import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/config/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.clean();
  });

  test('dotenv.load loads .env from asset bundle if bundled', () async {
    await dotenv.load(fileName: '.env');
    expect(dotenv.isInitialized, isTrue);
    expect(dotenv.maybeGet('API_BASE_URL'), 'https://apitesting.friendscheweta.com');
    expect(dotenv.maybeGet('SOCKET_URL'), 'https://apitesting.friendscheweta.com');
  });

  test('AppConfig handles uninitialized dotenv gracefully when defines are provided', () {
    dotenv.clean();
    expect(dotenv.isInitialized, isFalse);
    // When dotenv is not initialized, AppConfig should not throw NotInitializedError
    // If API_BASE_URL is not defined in fromEnvironment, it should throw StateError about missing API_BASE_URL,
    // NOT NotInitializedError from DotEnv!
    expect(
      () => AppConfig.fromEnvironment(),
      throwsA(isA<StateError>()),
    );
  });

  test('dart-define takes precedence over .env for booleans and strings', () async {
    await dotenv.load(fileName: '.env');
    expect(dotenv.maybeGet('REALTIME_DEBUG'), 'true');

    final config = AppConfig.fromEnvironment();
    // If REALTIME_DEBUG was passed via --dart-define=REALTIME_DEBUG=false,
    // config.realtimeDebug must be false despite .env being true!
    const hasDefine = bool.hasEnvironment('REALTIME_DEBUG');
    if (hasDefine) {
      expect(config.realtimeDebug, isFalse);
    } else {
      expect(config.realtimeDebug, isTrue);
    }
  });
}
