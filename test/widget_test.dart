import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_bingo_app/src/core/config/app_config.dart';
import 'package:friends_bingo_app/src/core/device/screen_awake_service.dart';
import 'package:friends_bingo_app/src/core/routing/app_router.dart';
import 'package:friends_bingo_app/src/core/realtime/socket_service.dart';
import 'package:friends_bingo_app/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:friends_bingo_app/src/features/auth/security/biometric_auth_service.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('appRouterProvider resolves without circular dependency', () {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});

    final container = ProviderContainer(
      overrides: [
        biometricAuthServiceProvider.overrideWithValue(
          _TestBiometricAuthService(),
        ),
        screenAwakeServiceProvider.overrideWithValue(_TestScreenAwakeService()),
        socketServiceProvider.overrideWithValue(_TestSocketService()),
      ],
    );
    addTearDown(container.dispose);

    expect(() => container.read(appRouterProvider), returnsNormally);
    expect(() => container.read(authControllerProvider), returnsNormally);
    expect(container.read(appRouterProvider), isNotNull);
  });
}

class _TestBiometricAuthService extends BiometricAuthService {
  _TestBiometricAuthService() : super(LocalAuthentication());

  @override
  Future<bool> isBiometricAvailable() async => false;
}

class _TestSocketService extends SocketService {
  _TestSocketService()
    : super(
        AppConfig(
          apiBaseUrl: 'http://localhost:3002',
          socketBaseUrl: 'http://localhost:3002',
        ),
      );

  @override
  void connect(String token) {}

  @override
  void connectAsGuest() {}

  @override
  void disconnect() {}
}

class _TestScreenAwakeService implements ScreenAwakeService {
  @override
  Future<void> setEnabled(bool enabled) async {}
}
