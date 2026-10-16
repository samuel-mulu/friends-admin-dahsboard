import 'package:flutter_test/flutter_test.dart';

/// Mirrors AppPreferencesStorage pending attempt payload encoding.
String encodePendingDepositAttempt({
  required String attemptId,
  required String provider,
  required String amount,
  required String transactionRef,
}) {
  return '$attemptId|$provider|$amount|$transactionRef';
}

Map<String, String>? decodePendingDepositAttempt(String raw) {
  final parts = raw.split('|');
  if (parts.length < 4) {
    return null;
  }
  return {
    'attemptId': parts[0],
    'provider': parts[1],
    'amount': parts[2],
    'transactionRef': parts.sublist(3).join('|'),
  };
}

void main() {
  test('round-trips pending attempt fields including ref with pipes', () {
    final encoded = encodePendingDepositAttempt(
      attemptId: 'att-1',
      provider: 'TELEBIRR',
      amount: '50.00',
      transactionRef: 'ABC|DEF',
    );
    final decoded = decodePendingDepositAttempt(encoded);
    expect(decoded, isNotNull);
    expect(decoded!['attemptId'], 'att-1');
    expect(decoded['provider'], 'TELEBIRR');
    expect(decoded['amount'], '50.00');
    expect(decoded['transactionRef'], 'ABC|DEF');
  });

  test('rejects malformed pending payload', () {
    expect(decodePendingDepositAttempt('only-one'), isNull);
  });
}
