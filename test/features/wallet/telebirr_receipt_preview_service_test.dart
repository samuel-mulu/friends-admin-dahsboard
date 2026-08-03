import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/deposit_config_model.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/telebirr_client_receipt_payload.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/telebirr_receipt_preview.dart';
import 'package:friends_bingo_app/src/features/wallet/data/telebirr_receipt_preview_service.dart';

/// Mirrors the live Telebirr receipt layout (Amharic label + English label in a
/// single cell, invoice details rendered as a column table).
String buildReceiptHtml({
  required String invoiceNumber,
  required String receiverName,
  required String receiverAccount,
  String transactionStatus = 'Completed',
  String settledAmount = '10 Birr',
  String totalPaidAmount = '10.16 Birr',
}) {
  return '''
<html>
  <body>
    <table>
      <tr>
        <td>የገንዘብ ተቀባይ ስም/Credited Party name</td>
        <td>$receiverName</td>
      </tr>
      <tr>
        <td>የገንዘብ ተቀባይ ቴሌብር ቁ./Credited party account no</td>
        <td>$receiverAccount</td>
      </tr>
      <tr>
        <td>የክፍያው ሁኔታ/transaction status</td>
        <td>$transactionStatus</td>
      </tr>
      <tr>
        <td>ጠቅላላ የተከፈለ/Total Paid Amount</td>
        <td>$totalPaidAmount</td>
      </tr>
    </table>
    <table>
      <tr>
        <td>የክፍያ ቁጥር/Invoice No.</td>
        <td>የክፍያ ቀን/Payment date</td>
        <td>የተከፈለው መጠን/Settled Amount</td>
      </tr>
      <tr>
        <td>$invoiceNumber</td>
        <td>28-07-2026 16:54:42</td>
        <td>$settledAmount</td>
      </tr>
    </table>
  </body>
</html>
''';
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: '', isOptional: true);
  });

  final service = TelebirrReceiptPreviewService(Dio());

  final config = TelebirrDepositConfig.fromJson({
    'providerName': 'Telebirr',
    'receiverPhoneLast4': '3287',
    'receiverName': 'Yonas shiferaw yowhans',
    'accounts': [
      {
        'settlementAccount': '0952723287',
        'receiverName': 'Yonas shiferaw yowhans',
        'receiverPhoneLast4': '3287',
      },
      {
        'settlementAccount': '0961355799',
        'receiverName': 'bisrat teklay gebreslassie',
        'receiverPhoneLast4': '5799',
      },
    ],
  });

  TelebirrReceiptPreview preview({
    required String receiverName,
    required String receiverAccount,
    String submittedAmount = '10',
    TelebirrDepositConfig? overrideConfig,
  }) {
    return service.parsePreviewHtml(
      html: buildReceiptHtml(
        invoiceNumber: 'DGS1BJ2WJ3',
        receiverName: receiverName,
        receiverAccount: receiverAccount,
      ),
      transactionRef: 'DGS1BJ2WJ3',
      submittedAmount: submittedAmount,
      config: overrideConfig ?? config,
    );
  }

  group('TelebirrReceiptPreviewService receiver matching', () {
    test('accepts a receipt whose receiver name is spelled differently', () {
      final result = preview(
        receiverName: 'Yonas Shiferaw Yohanes',
        receiverAccount: '2519****3287',
      );

      expect(result.status, TelebirrReceiptPreviewStatus.valid);
      expect(result.receiptParseStatus, TelebirrReceiptParseStatus.parsed);

      final payload = result.toClientReceiptPayload();
      expect(payload, isNotNull);
      expect(payload!.settledAmount, '10');
      expect(payload.creditedPartyAccountNo, '2519****3287');
    });

    test('accepts a receipt paid to the second configured account', () {
      final result = preview(
        receiverName: 'Bisrat Teklay Gebresilassie',
        receiverAccount: '2519****5799',
      );

      expect(result.status, TelebirrReceiptPreviewStatus.valid);
    });

    test('rejects a receipt paid to an unknown phone number', () {
      final result = preview(
        receiverName: 'Yonas shiferaw yowhans',
        receiverAccount: '2519****1111',
      );

      expect(result.status, TelebirrReceiptPreviewStatus.receiverMismatch);
      expect(result.toClientReceiptPayload(), isNull);
    });

    test('derives the last4 from the settlement account when not configured', () {
      final result = preview(
        receiverName: 'Any Spelling',
        receiverAccount: '2519****3287',
        overrideConfig: TelebirrDepositConfig.fromJson({
          'accounts': [
            {'settlementAccount': '0952723287'},
          ],
        }),
      );

      expect(result.status, TelebirrReceiptPreviewStatus.valid);
    });

    test('falls back to an exact name match when no digits are configured', () {
      final nameOnlyConfig = TelebirrDepositConfig.fromJson({
        'accounts': [
          {'settlementAccount': 'TELEBIRR', 'receiverName': 'Exact Name'},
        ],
      });

      expect(
        preview(
          receiverName: 'exact name',
          receiverAccount: '2519****3287',
          overrideConfig: nameOnlyConfig,
        ).status,
        TelebirrReceiptPreviewStatus.valid,
      );
      expect(
        preview(
          receiverName: 'Someone Else',
          receiverAccount: '2519****3287',
          overrideConfig: nameOnlyConfig,
        ).status,
        TelebirrReceiptPreviewStatus.receiverMismatch,
      );
    });
  });

  group('TelebirrReceiptPreviewService amount checks', () {
    test('reports the settled amount when the typed amount differs', () {
      final result = preview(
        receiverName: 'Yonas shiferaw yowhans',
        receiverAccount: '2519****3287',
        submittedAmount: '10.16',
      );

      expect(result.status, TelebirrReceiptPreviewStatus.amountMismatch);
      expect(result.settledAmount, '10');
      expect(result.canContinueToBackend, isFalse);
    });
  });
}
