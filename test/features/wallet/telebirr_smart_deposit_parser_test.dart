import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/wallet/deposits/domain/parsers/smart_deposit_parse_result.dart';
import 'package:friends_bingo_app/src/features/wallet/deposits/domain/parsers/telebirr_smart_deposit_parser.dart';

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

    test('real DK SMS: reads code from the receipt link and the amount', () {
      const sms = '''
Dear Samueal
You have transferred ETB 140.00 to Ambaye terefe (2519****0067) on 06/11/2026 07:48:23. Your transaction number is DK66RGL5R0. The service fee is  ETB 1.74 and  15% VAT on the service fee is ETB 0.26. Your current E-Money Account  balance is ETB 364.69. To download your payment information please click this link: https://transactioninfo.ethiotelecom.et/receipt/DK66RGL5R0.

Thank you for using telebirr
Ethio telecom''';
      final result = parseTelebirrSmartDepositInput(sms);
      expect(result.status, SmartDepositParseStatus.success);
      expect(result.transactionRef, 'DK66RGL5R0');
      expect(result.amount, '140');
    });

    test('receipt link code wins and needs no D prefix', () {
      const sms =
          'You have transferred ETB 50.00. '
          'https://transactioninfo.ethiotelecom.et/receipt/XQ12AB34CD.';
      final result = parseTelebirrSmartDepositInput(sms);
      expect(result.status, SmartDepositParseStatus.success);
      expect(result.transactionRef, 'XQ12AB34CD');
    });

    test('SMS without link: reads any D-code from the body (DK, DL, ...)', () {
      const sms =
          'Dear Samuel You have transferred ETB 75.50 to Friends Bingo. '
          'Your transaction number is DL7Q2W9E4R. Thank you for using telebirr';
      final result = parseTelebirrSmartDepositInput(sms);
      expect(result.status, SmartDepositParseStatus.success);
      expect(result.transactionRef, 'DL7Q2W9E4R');
      expect(result.amount, '75.50');
    });

    test('words like "Dear" / "DEAR" are never taken as the code', () {
      const sms =
          'DEAR Customer, You have transferred ETB 20.00. Thank you for using telebirr';
      final result = parseTelebirrSmartDepositInput(sms);
      expect(result.status, SmartDepositParseStatus.incomplete);
    });

    test('official receipt link pasted alone with trailing full stop', () {
      final result = parseTelebirrSmartDepositInput(
        'https://transactioninfo.ethiotelecom.et/receipt/DK66RGL5R0.',
      );
      expect(result.status, SmartDepositParseStatus.success);
      expect(result.transactionRef, 'DK66RGL5R0');
    });
  });
}
