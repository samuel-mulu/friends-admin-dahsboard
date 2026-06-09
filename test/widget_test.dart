import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_bingo_app/src/core/routing/app_router.dart';
import 'package:friends_bingo_app/src/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('appRouterProvider resolves without circular dependency', () {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});

    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(() => container.read(appRouterProvider), returnsNormally);
    expect(() => container.read(authControllerProvider), returnsNormally);
    expect(container.read(appRouterProvider), isNotNull);
  });
}
