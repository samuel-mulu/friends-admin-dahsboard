import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/core/network/paginated_response.dart';
import 'package:friends_bingo_app/src/core/network/pagination_meta.dart';
import 'package:friends_bingo_app/src/features/auth/domain/auth_session.dart';
import 'package:friends_bingo_app/src/features/auth/domain/user_profile.dart';
import 'package:friends_bingo_app/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/payment_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/wallet_model.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/withdrawal_model.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/controllers/withdraw_controller.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/providers/wallet_history_providers.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/screens/withdraw_screen.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/widgets/withdraw_balance_strip.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/widgets/withdraw_provider_chips.dart';

void main() {
  testWidgets('WithdrawScreen renders balance strip, provider chips, and history',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _TestAuthController(_signedInAuthState()),
        ),
        myWalletProvider.overrideWith(
          (ref) => Future.value(
            WalletModel(
              id: 'w-1',
              userId: 'user-1',
              balance: '250.00',
              lockedBalance: '50.00',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        ),
        withdrawalHistoryProvider.overrideWith(
          (ref) => Future.value(
            PaginatedResponse<WithdrawalModel>(
              items: [],
              pagination: PaginationMeta(
                page: 1,
                pageSize: 20,
                totalItems: 0,
                totalPages: 1,
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WithdrawScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(WithdrawBalanceStrip), findsOneWidget);
    expect(find.byType(WithdrawProviderChips), findsOneWidget);

    // Select CBE provider via controller
    container
        .read(withdrawControllerProvider.notifier)
        .selectProvider(PaymentProvider.cbe);
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
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
