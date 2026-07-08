import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/telebirr_client_receipt_payload.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/telebirr_receipt_preview.dart';

void main() {
  test('TelebirrClientReceiptPayload serializes parsed receipt fields', () {
    const payload = TelebirrClientReceiptPayload(
      invoiceNumber: 'DFF7WNHH5N',
      transactionStatus: 'Completed',
      settledAmount: '10.00',
      creditedPartyName: 'Yonas Shiferaw Yowhans',
      creditedPartyAccountNo: '2519****3287',
    );

    expect(
      payload.toJson(),
      {
        'invoiceNumber': 'DFF7WNHH5N',
        'transactionStatus': 'Completed',
        'settledAmount': '10.00',
        'creditedPartyName': 'Yonas Shiferaw Yowhans',
        'creditedPartyAccountNo': '2519****3287',
      },
    );
  });

  test('valid preview builds client receipt payload and parsed status', () {
    const preview = TelebirrReceiptPreview(
      status: TelebirrReceiptPreviewStatus.valid,
      transactionRef: 'DFF7WNHH5N',
      settledAmount: '10.00',
      creditedPartyName: 'Yonas Shiferaw Yowhans',
      creditedPartyAccountNo: '2519****3287',
      transactionStatus: 'Completed',
    );

    expect(preview.receiptParseStatus, TelebirrReceiptParseStatus.parsed);
    expect(
      preview.toClientReceiptPayload()?.toJson(),
      {
        'invoiceNumber': 'DFF7WNHH5N',
        'transactionStatus': 'Completed',
        'settledAmount': '10.00',
        'creditedPartyName': 'Yonas Shiferaw Yowhans',
        'creditedPartyAccountNo': '2519****3287',
      },
    );
  });

  test('preview unavailable uses unavailable parse status without payload', () {
    const preview = TelebirrReceiptPreview(
      status: TelebirrReceiptPreviewStatus.previewUnavailable,
      transactionRef: 'DFF7WNHH5N',
      message: 'Could not preview receipt.',
    );

    expect(
      preview.receiptParseStatus,
      TelebirrReceiptParseStatus.unavailable,
    );
    expect(preview.toClientReceiptPayload(), isNull);
  });
}
