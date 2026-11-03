import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_bingo_app/src/core/realtime/wallet_entity_realtime.dart';
import 'package:friends_bingo_app/src/features/auth/domain/auth_session.dart';
import 'package:friends_bingo_app/src/features/auth/domain/user_profile.dart';
import 'package:friends_bingo_app/src/features/auth/application/controllers/auth_controller.dart';
import 'package:friends_bingo_app/src/features/wallet/shared/domain/entities/payment_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/deposits/application/controllers/deposit_controller.dart';
import 'package:friends_bingo_app/src/features/wallet/deposits/application/models/deposit_confirmation_state.dart';
import 'package:friends_bingo_app/src/features/wallet/deposits/application/models/deposit_state.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _TestAuthController(_signedInAuthState()),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('DepositController initializes in smart entry tab', () {
    final container = createContainer();

    final state = container.read(depositControllerProvider);
    expect(state.entryTab, equals(DepositEntryTab.smart));
    expect(state.isChoosingProvider, isTrue);
    expect(state.provider, isNull);
  });

  test('switchTab toggles between smart and regular tabs', () {
    final container = createContainer();

    final controller = container.read(depositControllerProvider.notifier);
    controller.switchTab(DepositEntryTab.regular);

    expect(
      container.read(depositControllerProvider).entryTab,
      equals(DepositEntryTab.regular),
    );
  });

  test('selectProvider sets provider and resets choosing mode', () {
    final container = createContainer();

    final controller = container.read(depositControllerProvider.notifier);
    controller.selectProvider(PaymentProvider.cbe);

    final state = container.read(depositControllerProvider);
    expect(state.isChoosingProvider, isFalse);
    expect(state.provider, equals(PaymentProvider.cbe));
    expect(state.entryTab, equals(DepositEntryTab.regular));
  });

  test('selectProvider opens Smart tab for Telebirr only', () {
    final container = createContainer();
    final controller = container.read(depositControllerProvider.notifier);

    controller.selectProvider(PaymentProvider.telebirr);
    expect(
      container.read(depositControllerProvider).entryTab,
      equals(DepositEntryTab.smart),
    );

    controller.selectProvider(PaymentProvider.awash);
    expect(
      container.read(depositControllerProvider).entryTab,
      equals(DepositEntryTab.regular),
    );
  });

  test('changeProvider returns to choosing provider mode', () {
    final container = createContainer();

    final controller = container.read(depositControllerProvider.notifier);
    controller.selectProvider(PaymentProvider.telebirr);
    expect(container.read(depositControllerProvider).isChoosingProvider, isFalse);

    controller.changeProvider();
    expect(container.read(depositControllerProvider).isChoosingProvider, isTrue);
  });

  test('clearConfirmation resets confirmation and tracked deposit ID', () {
    final container = createContainer();
    final controller = container.read(depositControllerProvider.notifier);
    controller.selectProvider(PaymentProvider.cbe);

    controller.applyDepositTerminalStatus(
      kind: DepositConfirmationKind.rejected,
      depositId: 'dep-1',
      provider: PaymentProvider.cbe,
      amount: '50.00',
    );
    expect(container.read(depositControllerProvider).confirmation, isNotNull);

    controller.clearConfirmation();
    expect(container.read(depositControllerProvider).confirmation, isNull);
    expect(container.read(depositControllerProvider).trackedDepositId, isNull);
  });

  test('applyDepositTerminalStatus clears smart parse result on approval', () {
    final container = createContainer();
    final controller = container.read(depositControllerProvider.notifier);
    controller.selectProvider(PaymentProvider.telebirr);
    controller.parseSmartInput(
      'Dear Customer, You have transferred ETB 100.00 to Friends Bingo. '
      'Your transaction number is DJ1A2B3C4D.',
    );
    expect(
      container.read(depositControllerProvider).smartParseResult?.isSuccess,
      isTrue,
    );

    controller.applyDepositTerminalStatus(
      kind: DepositConfirmationKind.approved,
      depositId: 'dep-1',
      provider: PaymentProvider.telebirr,
      amount: '50.00',
      transactionRef: 'ABC123',
    );

    expect(
      container.read(depositControllerProvider).smartParseResult,
      isNull,
    );
    expect(
      container.read(depositControllerProvider).confirmation?.kind,
      DepositConfirmationKind.approved,
    );
  });

  test('handleRealtimeUpdate processes approved terminal event', () {
    final container = createContainer();
    final controller = container.read(depositControllerProvider.notifier);
    controller.selectProvider(PaymentProvider.telebirr);

    controller.applyDepositTerminalStatus(
      kind: DepositConfirmationKind.pending,
      depositId: 'dep-99',
      provider: PaymentProvider.telebirr,
      amount: '100.00',
    );

    controller.handleRealtimeUpdate(
      WalletEntityUpdate(
        kind: WalletEntityKind.deposit,
        id: 'dep-99',
        status: 'APPROVED',
        amount: '100.00',
        receivedAt: DateTime.now(),
      ),
    );

    final state = container.read(depositControllerProvider);
    expect(state.confirmation?.kind, equals(DepositConfirmationKind.approved));
    expect(state.confirmation?.amount, equals('100.00'));
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
