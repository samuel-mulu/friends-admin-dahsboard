import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/payment_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/widgets/deposit_provider_chips.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';

void main() {
  testWidgets('DepositProviderChips renders Awash and BOA without coming soon when set is empty', (tester) async {
    PaymentProvider selected = PaymentProvider.cbe;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return DepositProviderChips(
                value: selected,
                availableProviders: const [
                  PaymentProvider.telebirr,
                  PaymentProvider.cbe,
                  PaymentProvider.awash,
                  PaymentProvider.boa,
                ],
                depositConfig: null,
                comingSoonProviders: const {},
                isChoosing: true,
                onChangePressed: () {},
                onChanged: (p) => setState(() => selected = p),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Coming Soon'), findsNothing);
    expect(find.text('Awash Bank'), findsOneWidget);
    expect(find.text('Bank of Abyssinia'), findsOneWidget);

    await tester.tap(find.text('Awash Bank'));
    await tester.pumpAndSettle();
    expect(selected, PaymentProvider.awash);
  });
}
