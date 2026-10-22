import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_bingo_app/src/core/realtime/wallet_entity_realtime.dart';
import 'package:friends_bingo_app/src/features/auth/domain/auth_session.dart';
import 'package:friends_bingo_app/src/features/auth/domain/user_profile.dart';
import 'package:friends_bingo_app/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:friends_bingo_app/src/features/wallet/shared/domain/entities/payment_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/withdrawals/application/controllers/withdraw_controller.dart';
import 'package:friends_bingo_app/src/features/wallet/withdrawals/application/models/withdrawal_confirmation_state.dart';

void main() {
  ProviderContainer createContainer({String? phoneNumber}) {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _TestAuthController(_signedInAuthState(phoneNumber: phoneNumber)),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('WithdrawController initializes with choosing provider state and phone', () {
    final container = createContainer(phoneNumber: '0911223344');

    final state = container.read(withdrawControllerProvider);
    expect(state.isChoosingProvider, isTrue);
    expect(state.provider, isNull);
    expect(state.ownPhoneNumber, equals('0911223344'));
  });

  test('selectProvider transitions out of choosing mode and sets provider', () {
    final container = createContainer();

    final controller = container.read(withdrawControllerProvider.notifier);
    controller.selectProvider(PaymentProvider.cbe);

    final state = container.read(withdrawControllerProvider);
    expect(state.isChoosingProvider, isFalse);
    expect(state.provider, equals(PaymentProvider.cbe));
  });

  test('changeProvider returns back to choosing mode and clears confirmation', () {
    final container = createContainer();

    final controller = container.read(withdrawControllerProvider.notifier);
    controller.selectProvider(PaymentProvider.telebirr);
    expect(container.read(withdrawControllerProvider).isChoosingProvider, isFalse);

    controller.changeProvider();
    expect(container.read(withdrawControllerProvider).isChoosingProvider, isTrue);
  });

  test('handleRealtimeUpdate handles approved terminal update', () {
    final container = createContainer();
    final controller = container.read(withdrawControllerProvider.notifier);
    controller.selectProvider(PaymentProvider.telebirr);

    // Simulate tracked withdrawal ID
    container.read(withdrawControllerProvider.notifier).state = container
        .read(withdrawControllerProvider)
        .copyWith(trackedWithdrawalId: 'w-100');

    controller.handleRealtimeUpdate(
      WalletEntityUpdate(
        kind: WalletEntityKind.withdrawal,
        id: 'w-100',
        status: 'APPROVED',
        amount: '200.00',
        receivedAt: DateTime.now(),
      ),
    );

    final state = container.read(withdrawControllerProvider);
    expect(state.confirmation, isNotNull);
    expect(state.confirmation?.kind, equals(WithdrawalConfirmationKind.approved));
    expect(state.confirmation?.amount, equals('200.00'));
  });

  test('handleRealtimeUpdate handles rejected terminal update', () {
    final container = createContainer();
    final controller = container.read(withdrawControllerProvider.notifier);
    controller.selectProvider(PaymentProvider.cbe);

    container.read(withdrawControllerProvider.notifier).state = container
        .read(withdrawControllerProvider)
        .copyWith(trackedWithdrawalId: 'w-200');

    controller.handleRealtimeUpdate(
      WalletEntityUpdate(
        kind: WalletEntityKind.withdrawal,
        id: 'w-200',
        status: 'REJECTED',
        amount: '150.00',
        message: 'Insufficient balance',
        receivedAt: DateTime.now(),
      ),
    );

    final state = container.read(withdrawControllerProvider);
    expect(state.confirmation, isNotNull);
    expect(state.confirmation?.kind, equals(WithdrawalConfirmationKind.rejected));
    expect(state.confirmation?.message, equals('Insufficient balance'));
    expect(state.trackedWithdrawalId, isNull);
  });
}

class _TestAuthController extends AuthController {
  _TestAuthController(this._state);

  final AuthState _state;

  @override
  AuthState build() => _state;
}

AuthState _signedInAuthState({String? phoneNumber}) {
  return AuthState(
    session: AuthSession(
      accessToken: 'token',
      user: UserProfile(
        id: 'user-1',
        fullName: 'Test User',
        phoneNumber: phoneNumber ?? '0911000000',
        role: UserRole.player,
        status: UserStatus.active,
        createdAt: DateTime.utc(2026, 8, 3, 12),
        updatedAt: DateTime.utc(2026, 8, 3, 12),
      ),
    ),
  );
}
