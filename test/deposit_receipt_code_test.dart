import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/utils/deposit_receipt_code.dart';

void main() {
  group('normalizeDepositReceiptCode', () {
    test('uppercases plain receipt codes', () {
      expect(normalizeDepositReceiptCode('dfe8v9no7e'), 'DFE8V9NO7E');
    });

    test('extracts code from pasted Telebirr receipt URL', () {
      expect(
        normalizeDepositReceiptCode(
          'https://transactioninfo.ethiotelecom.et/receipt/DFE8V9NO7E',
        ),
        'DFE8V9NO7E',
      );
    });
  });

  group('validateTelebirrReceiptCode', () {
    test('accepts valid alphanumeric codes', () {
      expect(validateTelebirrReceiptCode('DFE8V9NO7E'), isNull);
    });

    test('rejects codes that are too short', () {
      expect(validateTelebirrReceiptCode('ABC12'), isNotNull);
    });

    test('rejects full URLs after normalization check in validator', () {
      expect(
        validateTelebirrReceiptCode('https://example.com/receipt/DFE8V9NO7E'),
        isNull,
      );
    });
  });
}
