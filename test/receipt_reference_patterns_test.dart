import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/payment_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/data/receipt_ocr/receipt_reference_patterns.dart';

void main() {
  group('detectReference', () {
    test('Telebirr detects DFN97J9LDP', () {
      expect(
        ReceiptReferencePatterns.detectReference(
          PaymentProvider.telebirr,
          'Receipt ID: DFN97J9LDP',
        ),
        'DFN97J9LDP',
      );
    });

    test('CBE detects FT26174PCT3Q', () {
      expect(
        ReceiptReferencePatterns.detectReference(
          PaymentProvider.cbe,
          'Reference FT26174PCT3Q',
        ),
        'FT26174PCT3Q',
      );
    });

    test('BOA detects FT261741KQ7X', () {
      expect(
        ReceiptReferencePatterns.detectReference(
          PaymentProvider.boa,
          'Payment ref FT261741KQ7X',
        ),
        'FT261741KQ7X',
      );
    });

    test('Awash detects 260623100618387', () {
      expect(
        ReceiptReferencePatterns.detectReference(
          PaymentProvider.awash,
          'Reference number 260623100618387',
        ),
        '260623100618387',
      );
    });
  });

  group('detectAmount', () {
    test('detects ETB 10.00', () {
      expect(
        ReceiptReferencePatterns.detectAmount(
          PaymentProvider.telebirr,
          'ETB 10.00',
        ),
        '10.00',
      );
    });

    test('ignores service charge when transferred amount exists', () {
      expect(
        ReceiptReferencePatterns.detectAmount(PaymentProvider.telebirr, '''
Service Charge: 1.00 ETB
Transferred Amount: 10.00 ETB
Total Amount Debited: 11.00 ETB
'''),
        '10.00',
      );
    });

    test('strips negative sign from -11.00 ETB', () {
      expect(
        ReceiptReferencePatterns.detectAmount(
          PaymentProvider.awash,
          '-11.00 ETB',
        ),
        '11.00',
      );
    });

    test('chooses transferred amount over total debited', () {
      expect(
        ReceiptReferencePatterns.detectAmount(PaymentProvider.cbe, '''
Total amount debited: 10.61 ETB
Transferred Amount: 10.00 ETB
'''),
        '10.00',
      );
    });
  });
}
