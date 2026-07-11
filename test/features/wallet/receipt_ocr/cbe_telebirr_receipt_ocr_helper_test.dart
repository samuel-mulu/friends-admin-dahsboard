import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/payment_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/data/receipt_ocr/cbe_receipt_ocr_helper.dart';
import 'package:friends_bingo_app/src/features/wallet/data/receipt_ocr/receipt_reference_patterns.dart';
import 'package:friends_bingo_app/src/features/wallet/data/receipt_ocr/telebirr_receipt_ocr_helper.dart';

void main() {
  group('CbeReceiptOcrHelper', () {
    test('parses 1.0 debit screenshot with FT26174FTFF8', () {
      const raw = '''
Thank you Success
Transaction Completed Successfully!
Transaction Summary
ETB 1.0 has been debited from Samueal Mulu Gebremedhin ETB-3278 for Yonas Shiferaw Yohanes ETB-3146 on Jun 23, 2026 07:30 PM with transaction ID: FT26174FTFF8.
Reason: MB Transfer
Total Amount Debited: 1.61 ETB with Service Charge of ETB0.50, VAT (15%) of ETB0.08 and Disaster Recovery (5%) of ETB0.03.
Commercial Bank of Ethiopia
''';

      final result = CbeReceiptOcrHelper.parse(raw);

      expect(result.reference, 'FT26174FTFF8');
      expect(result.amount, '1.00');
      expect(result.confidence, greaterThanOrEqualTo(0.85));
      expect(result.isLowConfidence, isFalse);
    });

    test('parses 60.0 debit screenshot with FT261741DB3X', () {
      const raw = '''
Transaction Completed Successfully!
ETB 60.0 has been debited from Samueal Mulu Gebremedhin ETB-3278 for Menur Shemsu Hamid ETB-9341 on Jun 23, 2026 07:24 PM with transaction ID: FT261741DB3X.
Reason: MB Transfer
Total Amount Debited: 60.61 ETB with Service Charge of ETB0.50, VAT (15%) of ETB0.08 and Disaster Recovery (5%) of ETB0.03.
Commercial Bank of Ethiopia
''';

      final result = CbeReceiptOcrHelper.parse(raw);

      expect(result.reference, 'FT261741DB3X');
      expect(result.amount, '60.00');
      expect(result.confidence, greaterThanOrEqualTo(0.85));
    });

    test('parses 10.0 debit screenshot with FT26174PCT3Q', () {
      const raw = '''
Transaction Completed Successfully!
ETB 10.0 has been debited from Samueal Mulu Gebremedhin ETB-3278 for Yonas Shiferaw Yohanes ETB-3146 on Jun 23, 2026 03:37 PM with transaction ID: FT26174PCT3Q.
Reason: Mobile Banking Transfer
Total Amount Debited: 10.61 ETB with Service Charge of ETB0.50, VAT (15%) of ETB0.08 and Disaster Recovery (5%) of ETB0.03.
Commercial Bank of Ethiopia
''';

      final result = CbeReceiptOcrHelper.parse(raw);

      expect(result.reference, 'FT26174PCT3Q');
      expect(result.amount, '10.00');
      expect(result.confidence, greaterThanOrEqualTo(0.85));
    });

    test('parses cropped ID: FT snippet with high enough confidence', () {
      const raw = 'ID: FT26174FTFF8';

      final result = CbeReceiptOcrHelper.parse(raw);

      expect(result.reference, 'FT26174FTFF8');
      expect(result.confidence, greaterThanOrEqualTo(0.60));
      expect(result.isLowConfidence, isFalse);
    });

    test('does not prefer fee total over debit amount', () {
      const raw = '''
ETB 60.0 has been debited from A for B with transaction ID: FT261741DB3X.
Total Amount Debited: 60.61 ETB with Service Charge of ETB0.50
Commercial Bank of Ethiopia
''';

      final result = CbeReceiptOcrHelper.parse(raw);

      expect(result.amount, '60.00');
      expect(result.amount, isNot('60.61'));
    });

    test('applies OCR corrections near digits on FT tokens', () {
      // O next to digit → 0
      const raw = '''
ETB 20.0 has been debited with transaction ID: FT2617O4ABC1
Commercial Bank of Ethiopia
''';

      final result = CbeReceiptOcrHelper.parse(raw);

      expect(result.reference, 'FT261704ABC1');
      expect(result.amount, '20.00');
      expect(result.confidence, greaterThanOrEqualTo(0.60));
    });
  });

  group('TelebirrReceiptOcrHelper', () {
    test('parses success screen with DFN97J9LDP and -11.00 (ETB)', () {
      const raw = '''
Successful
-11.00 (ETB)
Transaction Time: 2026/06/23 14:20:38
Transaction Type: Transfer Money
Transaction To: Yonas
Transaction Number:               DFN97J9LDP
QR Code
TelePlay
''';

      final result = TelebirrReceiptOcrHelper.parse(raw);

      expect(result.reference, 'DFN97J9LDP');
      expect(result.amount, '11.00');
      expect(result.confidence, greaterThanOrEqualTo(0.85));
      expect(result.isLowConfidence, isFalse);
    });

    test('parses spaced Transaction Number label/value crop', () {
      const raw = 'Transaction Number:                         DFN97J9LDP';

      final result = TelebirrReceiptOcrHelper.parse(raw);

      expect(result.reference, 'DFN97J9LDP');
      expect(result.confidence, greaterThanOrEqualTo(0.60));
      expect(result.isLowConfidence, isFalse);
    });

    test('prefers whole-birr paren amount over fee fragments', () {
      const raw = '''
Successful
-50.00 (ETB)
Transaction Number: DFE8V9NO7E
Service Charge ETB 1.00
''';

      final result = TelebirrReceiptOcrHelper.parse(raw);

      expect(result.reference, 'DFE8V9NO7E');
      expect(result.amount, '50.00');
    });
  });

  group('ReceiptReferencePatterns routes helpers', () {
    test('CBE parse uses CBE helper', () {
      const raw = '''
ETB 1.0 has been debited with transaction ID: FT26174FTFF8.
Commercial Bank of Ethiopia
''';

      final result = ReceiptReferencePatterns.parse(PaymentProvider.cbe, raw);

      expect(result.provider, 'CBE');
      expect(result.reference, 'FT26174FTFF8');
      expect(result.amount, '1.00');
    });

    test('Telebirr parse uses Telebirr helper', () {
      const raw = '''
-11.00 (ETB)
Transaction Number: DFN97J9LDP
''';

      final result = ReceiptReferencePatterns.parse(
        PaymentProvider.telebirr,
        raw,
      );

      expect(result.provider, 'TELEBIRR');
      expect(result.reference, 'DFN97J9LDP');
      expect(result.amount, '11.00');
    });
  });
}
