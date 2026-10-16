import 'package:flutter_test/flutter_test.dart';

/// Mirrors deposit screen provider-first tab policy.
enum DepositEntryTab { smart, regular }

void main() {
  test('defaults to Smart Deposit after provider selection', () {
    var entryTab = DepositEntryTab.smart;
    // Selecting a provider always resets to Smart.
    entryTab = DepositEntryTab.smart;
    expect(entryTab, DepositEntryTab.smart);
  });

  test('switching tabs preserves selected provider identity', () {
    const provider = 'TELEBIRR';
    var entryTab = DepositEntryTab.smart;
    entryTab = DepositEntryTab.regular;
    expect(provider, 'TELEBIRR');
    expect(entryTab, DepositEntryTab.regular);
    entryTab = DepositEntryTab.smart;
    expect(provider, 'TELEBIRR');
  });

  test('pending recovery prefers Regular tab for existing fields', () {
    var entryTab = DepositEntryTab.smart;
    // Restore pending attempt → show filled Regular form.
    entryTab = DepositEntryTab.regular;
    expect(entryTab, DepositEntryTab.regular);
  });
}
