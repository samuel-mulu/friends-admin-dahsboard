import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/auth/application/controllers/auth_controller.dart';
import 'package:friends_bingo_app/src/features/auth/domain/auth_session.dart';
import 'package:friends_bingo_app/src/features/auth/domain/user_profile.dart';
import 'package:friends_bingo_app/src/features/wallet/deposits/application/controllers/deposit_controller.dart';
import 'package:friends_bingo_app/src/features/wallet/shared/domain/entities/payment_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/shared/presentation/wallet_flow_back.dart';
import 'package:friends_bingo_app/src/features/wallet/withdrawals/application/controllers/withdraw_controller.dart';

void main() {
  test('deposit back restores provider chooser without consuming unrelated routes',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final deposit = container.read(depositControllerProvider.notifier);
    deposit.selectProvider(PaymentProvider.cbe);
    expect(
      container.read(depositControllerProvider).isChoosingProvider,
      isFalse,
    );

    expect(
      tryConsumeWalletProviderStepBack(
        container: container,
        location: '/wallet/deposit',
      ),
      isTrue,
    );
    expect(
      container.read(depositControllerProvider).isChoosingProvider,
      isTrue,
    );

    expect(
      tryConsumeWalletProviderStepBack(
        container: container,
        location: '/wallet/deposit',
      ),
      isFalse,
    );
  });

  test('withdraw back restores provider chooser', () {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _TestAuthController(_signedInAuthState()),
        ),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(withdrawControllerProvider.notifier)
        .selectProvider(PaymentProvider.telebirr);
    expect(
      container.read(withdrawControllerProvider).isChoosingProvider,
      isFalse,
    );

    expect(
      tryConsumeWalletProviderStepBack(
        container: container,
        location: '/wallet/withdraw',
      ),
      isTrue,
    );
    expect(
      container.read(withdrawControllerProvider).isChoosingProvider,
      isTrue,
    );
  });

  test('unrelated locations are ignored', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(depositControllerProvider.notifier)
        .selectProvider(PaymentProvider.cbe);

    expect(
      tryConsumeWalletProviderStepBack(
        container: container,
        location: '/wallet',
      ),
      isFalse,
    );
    expect(
      container.read(depositControllerProvider).isChoosingProvider,
      isFalse,
    );
  });
}

class _TestAuthController extends AuthController {
  _TestAuthController(this._state);

  final AuthState _state;

  @override
  AuthState build() => _state;
}

AuthState _signedInAuthState() {
  return AuthState(
    session: AuthSession(
      accessToken: 'token',
      user: UserProfile(
        id: 'user-1',
        fullName: 'Test User',
        phoneNumber: '0911000000',
        role: UserRole.player,
        status: UserStatus.active,
        createdAt: DateTime.utc(2026, 8, 3, 12),
        updatedAt: DateTime.utc(2026, 8, 3, 12),
      ),
    ),
  );
}
