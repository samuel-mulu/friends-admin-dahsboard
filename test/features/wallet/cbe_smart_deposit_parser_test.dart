import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/utils/cbe_smart_deposit_parser.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/utils/smart_deposit_parse_result.dart';

void main() {
  group('parseCbeSmartDepositInput', () {
    test('accepts official CBE receipt URL', () {
      final result = parseCbeSmartDepositInput(
        'https://mbreciept.cbe.com.et/receipt/fHCxyU3pPQIUBir8hu',
      );
      expect(result.status, SmartDepositParseStatus.success);
      expect(result.transactionRef, 'fHCxyU3pPQIUBir8hu');
    });

    test('accepts legacy FT reference', () {
      final result = parseCbeSmartDepositInput(' ft26152zn0xy ');
      expect(result.status, SmartDepositParseStatus.success);
      expect(result.transactionRef, 'FT26152ZN0XY');
    });

    test('rejects Telebirr SMS as wrong provider', () {
      const sms =
          'You have transferred ETB 50.00 via Telebirr. '
          'Your transaction number is DJ1A2B3C4D.';
      final result = parseCbeSmartDepositInput(sms);
      expect(result.status, SmartDepositParseStatus.wrongProvider);
    });

    test('marks unverified full CBE SMS as unsupported', () {
      const sms =
          'Dear Customer, your account has been debited ETB 200.00. '
          'Reference FT26152ZN0XY. Thank you for banking with us.';
      final result = parseCbeSmartDepositInput(sms);
      expect(result.status, SmartDepositParseStatus.unsupported);
    });
  });
}
