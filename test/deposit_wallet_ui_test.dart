import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/payment_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/models/deposit_confirmation_state.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/widgets/deposit_confirmation_banner.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/widgets/deposit_guide_steps.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/widgets/deposit_form_section.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/widgets/deposit_settlement_account_card.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  testWidgets('DepositConfirmationBanner shows approved check icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        DepositConfirmationBanner(
          state: const DepositConfirmationState(
            kind: DepositConfirmationKind.approved,
            provider: PaymentProvider.telebirr,
            amount: '10',
            transactionRef: 'DFN37ALDLB',
          ),
          onDismiss: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('DFN37ALDLB'), findsOneWidget);
  });

  testWidgets('DepositConfirmationBanner shows rejected close icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        DepositConfirmationBanner(
          state: const DepositConfirmationState(
            kind: DepositConfirmationKind.rejected,
            message: 'Receipt could not be verified.',
          ),
          onDismiss: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Deposit failed'), findsOneWidget);
  });

  testWidgets('DepositGuideSteps renders three steps for Telebirr', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const DepositGuideSteps(provider: PaymentProvider.telebirr)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DepositGuideSteps), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('DepositGuideSteps opens expanded image modal on tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const DepositGuideSteps(provider: PaymentProvider.telebirr)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tap to enlarge').first);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('DepositFormSection uppercases transaction reference input', (
    tester,
  ) async {
    final amountController = TextEditingController();
    final transactionRefController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DepositFormSection(
            provider: PaymentProvider.cbe,
            amountController: amountController,
            transactionRefController: transactionRefController,
            receiptLabel: 'FT reference',
            amountValidator: (_) => null,
            transactionRefValidator: (_) => null,
            onFieldChanged: () {},
          ),
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'ft123abc');
    await tester.pump();

    expect(transactionRefController.text, 'FT123ABC');
  });

  testWidgets('confirmation clears when form field changes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const _ConfirmationClearHarness(),
      ),
    );

    expect(find.byType(DepositConfirmationBanner), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '200');
    await tester.pump();

    expect(find.byType(DepositConfirmationBanner), findsNothing);
  });

  testWidgets('DepositSettlementAccountCard shows account and copy icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const DepositSettlementAccountCard(
          settlementAccount: '1000652243146',
          receiverName: 'Yonas Shiferaw Yohanes',
        ),
      ),
    );

    expect(find.text('1000652243146'), findsOneWidget);
    expect(find.text('Yonas Shiferaw Yohanes'), findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
  });
}

class _ConfirmationClearHarness extends StatefulWidget {
  const _ConfirmationClearHarness();

  @override
  State<_ConfirmationClearHarness> createState() =>
      _ConfirmationClearHarnessState();
}

class _ConfirmationClearHarnessState extends State<_ConfirmationClearHarness> {
  DepositConfirmationState? _confirmation = const DepositConfirmationState(
    kind: DepositConfirmationKind.approved,
    provider: PaymentProvider.cbe,
    amount: '100',
    transactionRef: 'FT123456',
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
            DepositConfirmationBanner(
              state: _confirmation!,
              onDismiss: _clearConfirmation,
            ),
        ],
      ),
    );
  }
}
