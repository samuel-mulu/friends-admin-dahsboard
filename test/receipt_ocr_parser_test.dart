import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/payment_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/data/receipt_ocr/receipt_reference_patterns.dart';

void main() {
  group('CBE OCR v2 — amount extraction', () {
    test('CBE 60 ETB screenshot: returns transferred amount, not total debited', () {
      const raw = '''
ETB 60.0 has been debited from Samueal Mulu Gebreremedhin ETB 3278 for Yonas
Shiferaw Yohanes ETB-3146 on Jun 23, 2026 02:58 PM with transaction ID:
FT261741DB3X Reason: MB Transfer
Total Amount Debited: 60.61 ETB with Service Charge of ETB0.50, VAT (15%) of
ETB0.08 and Disaster Recovery (5%) of ETB0.03.
Commercial Bank of Ethiopia
''';
      final result = ReceiptReferencePatterns.parse(PaymentProvider.cbe, raw);
      expect(result.amount, '60.00');
      expect(result.reference, 'FT261741DB3X');
      expect(result.confidence, greaterThanOrEqualTo(0.85));
    });

    test('CBE 10 ETB screenshot: returns transferred amount, not total debited', () {
      const raw = '''
ETB 10.0 has been debited from Samueal Mia Mulu Gebreremedhin ETB 3278 for
Memar Shemsu Hamid ETB-8941 on Jun 23, 2026 with transaction ID: FT26174PCT3Q
Total Amount Debited: 10.61 ETB with Service Charge of ETB0.50, VAT (15%) of
ETB0.08 and Disaster Recovery (5%) of ETB0.03.
Commercial Bank of Ethiopia
''';
      final result = ReceiptReferencePatterns.parse(PaymentProvider.cbe, raw);
      expect(result.amount, '10.00');
      expect(result.reference, 'FT26174PCT3Q');
      expect(result.confidence, greaterThanOrEqualTo(0.85));
    });

    test('CBE PDF receipt: Transferred Amount label wins over total debited', () {
      const raw = '''
Transferred Amount: 10.00 ETB
Reference No. FT26174PCT3Q
Total amount debited from customer's account: 10.61 ETB
Commercial Bank of Ethiopia
''';
      final result = ReceiptReferencePatterns.parse(PaymentProvider.cbe, raw);
      expect(result.amount, '10.00');
      expect(result.reference, 'FT26174PCT3Q');
      expect(result.confidence, greaterThanOrEqualTo(0.85));
    });

    test('fee-only trap: only Total Amount Debited → low confidence', () {
      const raw = '''
Total Amount Debited: 60.61 ETB
Service Charge: 0.50
VAT: 0.08
Commercial Bank of Ethiopia
''';
      final result = ReceiptReferencePatterns.parse(PaymentProvider.cbe, raw);
      expect(result.isLowConfidence, isTrue,
          reason: 'Amount came only from Total Amount Debited (includes fees)');
    });

    test('no CBE markers → confidence 0', () {
      const raw = '''
ETB 60.0 has been debited
transaction ID: FT261741DB3X
Total Amount Debited: 60.61 ETB
''';
      final result = ReceiptReferencePatterns.parse(PaymentProvider.cbe, raw);
      expect(result.confidence, 0.0);
      expect(result.amount, isNull);
      expect(result.reference, isNull);
    });
  });

  group('CBE OCR v2 — reference extraction', () {
    test('labeled "transaction ID:" extracts FT reference', () {
      final ref = ReceiptReferencePatterns.detectReference(
        PaymentProvider.cbe,
        'Commercial Bank of Ethiopia\ntransaction ID: FT261741DB3X\n',
      );
      expect(ref, 'FT261741DB3X');
    });

    test('labeled "Reference No." extracts FT reference', () {
      final ref = ReceiptReferencePatterns.detectReference(
        PaymentProvider.cbe,
        'Commercial Bank of Ethiopia\nReference No. FT26174PCT3Q\n',
      );
      expect(ref, 'FT26174PCT3Q');
    });

    test('OCR confusion: space-split reference is cleaned and uppercased', () {
      const raw = 'Commercial Bank of Ethiopia\ntransaction ID: ft26174 pct3q\n';
      final result = ReceiptReferencePatterns.parse(PaymentProvider.cbe, raw);
      expect(result.reference, 'FT26174PCT3Q');
    });

    test('OCR digit confusion: l between digits corrected to 1', () {
      const raw = 'Commercial Bank of Ethiopia\ntransaction ID: FT26l74PCT3Q\n';
      final result = ReceiptReferencePatterns.parse(PaymentProvider.cbe, raw);
      expect(result.reference, 'FT26174PCT3Q');
    });

    test('trailing non-digit letter NOT corrected (e.g. Q stays Q)', () {
      const raw = 'Commercial Bank of Ethiopia\ntransaction ID: FT26174PCT3Q\n';
      final ref = ReceiptReferencePatterns.detectReference(
        PaymentProvider.cbe,
        raw,
      );
      expect(ref, 'FT26174PCT3Q');
    });

    test('bare FT pattern found when no label present', () {
      const raw = 'Commercial Bank of Ethiopia\nFT26174FTFF8 some text';
      final ref = ReceiptReferencePatterns.detectReference(
        PaymentProvider.cbe,
        raw,
      );
      expect(ref, 'FT26174FTFF8');
    });
  });

  group('CBE OCR v2 — amount normalization', () {
    test('60.0 normalizes to 60.00', () {
      final amount = ReceiptReferencePatterns.detectAmount(
        PaymentProvider.cbe,
        'Commercial Bank of Ethiopia\nETB 60.0 has been debited\n',
      );
      expect(amount, '60.00');
    });

    test('1.0 normalizes to 1.00', () {
      final amount = ReceiptReferencePatterns.detectAmount(
        PaymentProvider.cbe,
        'Commercial Bank of Ethiopia\nETB 1.0 has been debited\n',
      );
      expect(amount, '1.00');
    });

    test('10,000.50 normalizes to 10000.50', () {
      final amount = ReceiptReferencePatterns.detectAmount(
        PaymentProvider.cbe,
        'Commercial Bank of Ethiopia\nTransferred Amount: 10,000.50 ETB\n',
      );
      expect(amount, '10000.50');
    });
  });

  group('CBE OCR v2 — confidence scoring', () {
    test('both found cleanly → confidence 1.0', () {
      const raw = '''
ETB 60.0 has been debited
transaction ID: FT261741DB3X
Commercial Bank of Ethiopia
''';
      final result = ReceiptReferencePatterns.parse(PaymentProvider.cbe, raw);
      expect(result.confidence, 1.0);
    });

    test('both found but reference had OCR correction → confidence 0.85', () {
      const raw = '''
ETB 60.0 has been debited
transaction ID: FT26l74PCT3Q
Commercial Bank of Ethiopia
''';
      final result = ReceiptReferencePatterns.parse(PaymentProvider.cbe, raw);
      // debitedStatement (0.70) + corrected ref (0.15) = 0.85
      expect(result.confidence, closeTo(0.85, 0.001));
      expect(result.reference, 'FT26174PCT3Q');
    });

    test('amount found from generic Amount label alone → above threshold, not low confidence', () {
      const raw = 'Amount: 100.00 ETB\nCBE\n';
      final result = ReceiptReferencePatterns.parse(PaymentProvider.cbe, raw);
      expect(result.amount, '100.00');
      expect(result.isLowConfidence, isFalse,
          reason: 'Generic Amount label alone scores 0.62 which is ≥ 0.60');
    });
  });

  group('Telebirr parser — unchanged by CBE v2', () {
    test('Telebirr D-reference still detected', () {
      final ref = ReceiptReferencePatterns.detectReference(
        PaymentProvider.telebirr,
        'Reference: DA12345678\n',
      );
      expect(ref, 'DA12345678');
    });
  });
}
