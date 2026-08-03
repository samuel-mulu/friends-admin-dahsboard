import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/utils/cbe_manual_receipt_reference.dart';

void main() {
  group('normalizeCbeManualReceiptReference', () {
    test('normalizes a legacy FT reference', () {
      expect(
        normalizeCbeManualReceiptReference(' ft26152zn0xy '),
        'FT26152ZN0XY',
      );
    });

    test('preserves a case-sensitive mobile receipt token', () {
      expect(
        normalizeCbeManualReceiptReference('fHCxyU3pPQIUBir8hu'),
        'fHCxyU3pPQIUBir8hu',
      );
    });

    test('extracts a token from the official receipt path', () {
      expect(
        normalizeCbeManualReceiptReference(
          'https://mbreciept.cbe.com.et/receipt/fHCxyU3pPQIUBir8hu',
        ),
        'fHCxyU3pPQIUBir8hu',
      );
    });

    test('extracts a token from the official receipt query', () {
      expect(
        normalizeCbeManualReceiptReference(
          'https://mbreciept.cbe.com.et/?id=fHCxyU3pPQIUBir8hu',
        ),
        'fHCxyU3pPQIUBir8hu',
      );
    });

    test('rejects another host and an unrelated path', () {
      expect(
        normalizeCbeManualReceiptReference(
          'https://example.com/receipt/fHCxyU3pPQIUBir8hu',
        ),
        isNull,
      );
      expect(
        normalizeCbeManualReceiptReference(
          'https://mbreciept.cbe.com.et/other/fHCxyU3pPQIUBir8hu',
        ),
        isNull,
      );
    });

    test('rejects a receipt URL with no ID', () {
      expect(
        normalizeCbeManualReceiptReference(
          'https://mbreciept.cbe.com.et/receipt',
        ),
        isNull,
      );
    });
  });
}
