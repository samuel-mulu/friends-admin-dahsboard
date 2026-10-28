import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/wallet/deposits/application/models/deposit_state.dart';
import 'package:friends_bingo_app/src/features/wallet/shared/domain/entities/payment_provider.dart';

void main() {
  test('Telebirr supports Smart and Regular deposit tabs', () {
    expect(PaymentProvider.telebirr.supportsSmartDepositEntry, isTrue);
  });

  test('CBE, Awash, and BOA use Regular deposit entry only', () {
    expect(PaymentProvider.cbe.supportsSmartDepositEntry, isFalse);
    expect(PaymentProvider.awash.supportsSmartDepositEntry, isFalse);
    expect(PaymentProvider.boa.supportsSmartDepositEntry, isFalse);
  });

  test('selecting Telebirr defaults to Smart tab', () {
    const provider = PaymentProvider.telebirr;
    final entryTab = provider.supportsSmartDepositEntry
        ? DepositEntryTab.smart
        : DepositEntryTab.regular;
    expect(entryTab, DepositEntryTab.smart);
  });

  test('selecting CBE defaults to Regular tab', () {
    const provider = PaymentProvider.cbe;
    final entryTab = provider.supportsSmartDepositEntry
        ? DepositEntryTab.smart
        : DepositEntryTab.regular;
    expect(entryTab, DepositEntryTab.regular);
  });
}
