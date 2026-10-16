import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/utils/smart_deposit_parse_result.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/utils/telebirr_smart_deposit_parser.dart';

void main() {
  group('parseTelebirrSmartDepositInput', () {
    test('extracts DJ reference and transferred amount from SMS', () {
      const sms =
          'Dear Customer, You have transferred ETB 100.00 to Friends Bingo. '
          'Service fee ETB 1.00 VAT ETB 0.15. Your remaining balance is ETB 50.00. '
          'Your transaction number is DJ1A2B3C4D.';
      final result = parseTelebirrSmartDepositInput(sms);
      expect(result.status, SmartDepositParseStatus.success);
      expect(result.transactionRef, 'DJ1A2B3C4D');
      expect(result.amount, '100');
    });

    test('extracts receipt code from official Telebirr receipt URL', () {
      final result = parseTelebirrSmartDepositInput(
        'https://transactioninfo.ethiotelecom.et/receipt/DJ9XYZ12AB',
      );
      expect(result.status, SmartDepositParseStatus.success);
      expect(result.transactionRef, 'DJ9XYZ12AB');
    });

    test('accepts bare receipt code', () {
      final result = parseTelebirrSmartDepositInput('dfe8v9no7e');
      expect(result.status, SmartDepositParseStatus.success);
      expect(result.transactionRef, 'DFE8V9NO7E');
    });

    test('rejects CBE receipt URL as wrong provider', () {
      final result = parseTelebirrSmartDepositInput(
        'https://mbreciept.cbe.com.et/receipt/fHCxyU3pPQIUBir8hu',
      );
      expect(result.status, SmartDepositParseStatus.wrongProvider);
    });

    test('rejects bare CBE FT reference as wrong provider', () {
      final result = parseTelebirrSmartDepositInput('FT26152ZN0XY');
      expect(result.status, SmartDepositParseStatus.wrongProvider);
    });
  });
}
