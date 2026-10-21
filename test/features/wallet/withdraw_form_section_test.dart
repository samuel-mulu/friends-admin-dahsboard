import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/features/auth/domain/auth_session.dart';
import 'package:friends_bingo_app/src/features/auth/domain/user_profile.dart';
import 'package:friends_bingo_app/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/payment_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/controllers/withdraw_controller.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/widgets/withdraw_form_section.dart';

void main() {
  testWidgets('WithdrawFormSection renders amount and receiver inputs for selected provider',
      (tester) async {
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: WithdrawFormSection(availableBalance: '500.00'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(FilledButton), findsOneWidget);
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
