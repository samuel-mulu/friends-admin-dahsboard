import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/payment_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/models/withdrawal_confirmation_state.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/widgets/wallet_breakdown_card.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/widgets/withdraw_balance_strip.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/widgets/withdrawal_confirmation_banner.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  testWidgets('WithdrawalConfirmationBanner shows approved check icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        WithdrawalConfirmationBanner(
          state: WithdrawalConfirmationState(
            kind: WithdrawalConfirmationKind.approved,
            provider: PaymentProvider.telebirr,
            amount: '500',
            withdrawalId: 'withdrawal-1',
          ),
          onDismiss: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Withdrawal approved'), findsOneWidget);
  });

  testWidgets('WithdrawalConfirmationBanner shows pending spinner', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        WithdrawalConfirmationBanner(
          state: WithdrawalConfirmationState.pending(
            provider: PaymentProvider.cbe,
            amount: '250',
            withdrawalId: 'withdrawal-2',
          ),
          onDismiss: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Withdrawal submitted'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('confirmation clears when form field changes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const _ConfirmationClearHarness(),
      ),
    );

    expect(find.byType(WithdrawalConfirmationBanner), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '200');
    await tester.pump();

    expect(find.byType(WithdrawalConfirmationBanner), findsNothing);
  });

  testWidgets('amount validator rejects value above available balance', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const _AmountValidationHarness(availableBalance: '100'),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '150');
    await tester.tap(find.text('Validate'));
    await tester.pump();

    expect(
      find.text('Amount exceeds your available balance.'),
      findsOneWidget,
    );
  });

  testWidgets('WithdrawBalanceStrip shows withdrawable balance when nothing is locked', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const WithdrawBalanceStrip(
          availableBalance: '500.00',
          lockedBalance: '0.00',
          totalBalance: '500.00',
        ),
      ),
    );

    expect(find.textContaining('500.00 ETB'), findsOneWidget);
    expect(find.text('Freez balance'), findsNothing);
  });

  testWidgets('WithdrawBalanceStrip shows only freez balance when funds are locked', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const WithdrawBalanceStrip(
          availableBalance: '500.00',
          lockedBalance: '250.00',
          totalBalance: '750.00',
        ),
      ),
    );

    expect(find.text('Freez balance'), findsOneWidget);
    expect(find.textContaining('250.00 ETB'), findsOneWidget);
    expect(find.text('Available balance'), findsNothing);
    expect(find.text('Locked balance'), findsNothing);
    expect(find.textContaining('500.00'), findsNothing);
  });

  testWidgets('WalletBreakdownCard shows total when funds are locked', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const WalletBreakdownCard(
          balance: '500.00',
          lockedBalance: '500.00',
          totalBalance: '1000.00',
        ),
      ),
    );

    expect(find.text('Total wallet'), findsOneWidget);
    expect(find.textContaining('1000.00 ETB'), findsOneWidget);
    expect(find.text('Freez balance'), findsOneWidget);
    expect(find.text('Available balance'), findsNothing);
    expect(find.text('Locked balance'), findsNothing);
  });

  testWidgets('WalletBreakdownCard inline keeps available large and freez small', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const WalletBreakdownCard(
          balance: '8641.00',
          lockedBalance: '300.00',
          totalBalance: '8941.00',
          style: WalletBreakdownStyle.inline,
        ),
      ),
    );

    expect(find.text('Available balance'), findsOneWidget);
    expect(find.textContaining('8641.00 ETB'), findsOneWidget);
    expect(find.textContaining('Freez balance: 300.00 ETB'), findsOneWidget);
  });

  testWidgets('WalletBreakdownCard shows only available when nothing is locked', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const WalletBreakdownCard(
          balance: '1000.00',
          lockedBalance: '0.00',
        ),
      ),
    );

    expect(find.text('Available balance'), findsOneWidget);
    expect(find.textContaining('1000.00 ETB'), findsOneWidget);
    expect(find.text('Total wallet'), findsNothing);
    expect(find.text('Locked balance'), findsNothing);
  });
}

class _ConfirmationClearHarness extends StatefulWidget {
  const _ConfirmationClearHarness();

  @override
  State<_ConfirmationClearHarness> createState() =>
      _ConfirmationClearHarnessState();
}

class _ConfirmationClearHarnessState extends State<_ConfirmationClearHarness> {
  WithdrawalConfirmationState? _confirmation =
      WithdrawalConfirmationState.pending(
        provider: PaymentProvider.telebirr,
        amount: '100',
        withdrawalId: 'withdrawal-3',
      );

  void _clearConfirmation() => setState(() => _confirmation = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextFormField(
            onChanged: (_) => _clearConfirmation(),
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          if (_confirmation != null)
            WithdrawalConfirmationBanner(
              state: _confirmation!,
              onDismiss: _clearConfirmation,
            ),
        ],
      ),
    );
  }
}

class _AmountValidationHarness extends StatefulWidget {
  const _AmountValidationHarness({required this.availableBalance});

  final String availableBalance;

  @override
  State<_AmountValidationHarness> createState() =>
      _AmountValidationHarnessState();
}

class _AmountValidationHarnessState extends State<_AmountValidationHarness> {
  final _formKey = GlobalKey<FormState>();

  String? _validateAmount(String? value) {
    final trimmed = value?.trim() ?? '';
    final parsed = double.tryParse(trimmed);
    final available = double.tryParse(widget.availableBalance);
    if (parsed != null && available != null && parsed > available) {
      return 'Amount exceeds your available balance.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              validator: _validateAmount,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            TextButton(
              onPressed: () => _formKey.currentState?.validate(),
              child: const Text('Validate'),
            ),
          ],
        ),
      ),
    );
  }
}
