import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/deposit_config_model.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/telebirr_receipt_preview.dart';
import 'package:friends_bingo_app/src/features/wallet/data/telebirr_receipt_preview_service.dart';

void main() {
  const config = TelebirrDepositConfig(
    providerName: 'Telebirr',
    receiptHelpText: 'Enter the settled amount.',
    receiptBaseUrl: 'https://transactioninfo.ethiotelecom.et/receipt',
    receiverPhoneLast4: '0885',
    receiverName: 'Samueal Mulu Gebremedhin',
  );

  final service = TelebirrReceiptPreviewService(Dio());

  String buildHtml({
    required String invoiceNo,
    required String status,
    required String settledAmount,
    required String totalPaidAmount,
    required String receiverName,
    required String receiverAccount,
  }) {
    return '''
      <html>
        <body>
          <table>
            <tr><td>Invoice No</td><td>$invoiceNo</td></tr>
            <tr><td>Transaction Status</td><td>$status</td></tr>
            <tr><td>Settled Amount</td><td>$settledAmount</td></tr>
            <tr><td>Total Paid Amount</td><td>$totalPaidAmount</td></tr>
            <tr><td>Credited party name</td><td>$receiverName</td></tr>
            <tr><td>Credited party account no</td><td>$receiverAccount</td></tr>
          </table>
        </body>
      </html>
    ''';
  }

  test('passes valid receipt preview using settled amount', () {
    final preview = service.parsePreviewHtml(
      html: buildHtml(
        invoiceNo: 'DFF3WLQB6R',
        status: 'Completed',
        settledAmount: '30.00',
        totalPaidAmount: '31.00',
        receiverName: 'Samueal Mulu Gebremedhin',
        receiverAccount: '2519****0885',
      ),
      transactionRef: 'DFF3WLQB6R',
      submittedAmount: '30',
      config: config,
    );

    expect(preview.status, TelebirrReceiptPreviewStatus.valid);
    expect(preview.settledAmount, '30.00');
    expect(preview.totalPaidAmount, '31.00');
  });

  test('blocks submit when preview sees settled amount mismatch', () {
    final preview = service.parsePreviewHtml(
      html: buildHtml(
        invoiceNo: 'DFF3WLQB6R',
        status: 'Completed',
        settledAmount: '30.00',
        totalPaidAmount: '31.00',
        receiverName: 'Samueal Mulu Gebremedhin',
        receiverAccount: '2519****0885',
      ),
      transactionRef: 'DFF3WLQB6R',
      submittedAmount: '31',
      config: config,
    );

    expect(preview.status, TelebirrReceiptPreviewStatus.amountMismatch);
    expect(preview.canContinueToBackend, isFalse);
  });

  test('blocks submit when preview sees wrong receiver', () {
    final preview = service.parsePreviewHtml(
      html: buildHtml(
        invoiceNo: 'DFF3WLQB6R',
        status: 'Completed',
        settledAmount: '30.00',
        totalPaidAmount: '31.00',
        receiverName: 'Wrong Receiver',
        receiverAccount: '2519****9999',
      ),
      transactionRef: 'DFF3WLQB6R',
      submittedAmount: '30',
      config: config,
    );

    expect(preview.status, TelebirrReceiptPreviewStatus.receiverMismatch);
    expect(preview.canContinueToBackend, isFalse);
  });

  test('blocks submit when preview sees non-completed receipt', () {
    final preview = service.parsePreviewHtml(
      html: buildHtml(
        invoiceNo: 'DFF3WLQB6R',
        status: 'Pending',
        settledAmount: '30.00',
        totalPaidAmount: '31.00',
        receiverName: 'Samueal Mulu Gebremedhin',
        receiverAccount: '2519****0885',
      ),
      transactionRef: 'DFF3WLQB6R',
      submittedAmount: '30',
      config: config,
    );

    expect(preview.status, TelebirrReceiptPreviewStatus.invalidReceipt);
    expect(preview.canContinueToBackend, isFalse);
  });

  test('parses production-style telebirr receipt html', () {
    const productionHtml = '''
      <html><body>
        <table>
          <tr>
            <td>የገንዘብ ተቀባይ ስም/Credited Party name</td>
            <td>Yonas Shiferaw Yowhans</td>
          </tr>
          <tr>
            <td>የገንዘብ ተቀባይ ቴሌብር ቁ./Credited party account no</td>
            <td>2519****3287</td>
          </tr>
          <tr>
            <td>የክፍያው ሁኔታ/transaction status</td>
            <td>Completed</td>
          </tr>
        </table>
        <table>
          <tr><td colspan="3">Invoice details</td></tr>
          <tr>
            <td>የክፍያ ቁጥር/Invoice No.</td>
            <td>Payment date</td>
            <td>Settled Amount</td>
          </tr>
          <tr>
            <td>DFG70KZGZB</td>
            <td>15-06-2026 10:00:00</td>
            <td>10 Birr</td>
          </tr>
          <tr>
            <td></td>
            <td>Total Paid Amount</td>
            <td>10.87 Birr</td>
          </tr>
        </table>
      </body></html>
    ''';

    final preview = service.parsePreviewHtml(
      html: productionHtml,
      transactionRef: 'DFG70KZGZB',
      submittedAmount: '10',
      config: const TelebirrDepositConfig(
        providerName: 'Telebirr',
        receiptHelpText: 'Enter the settled amount.',
        receiptBaseUrl: 'https://transactioninfo.ethiotelecom.et/receipt',
        receiverPhoneLast4: '3287',
        receiverName: 'Yonas Shiferaw Yowhans',
      ),
    );

    expect(preview.status, TelebirrReceiptPreviewStatus.valid);
    expect(preview.settledAmount, '10');
    expect(preview.totalPaidAmount, '10.87');
    expect(preview.creditedPartyAccountNo, '2519****3287');
  });

  test('parses settled amount from invoice row with fee rows below', () {
    const html = '''
      <html><body>
        <table>
          <tr>
            <td>Credited Party name</td>
            <td>Yonas Shiferaw Yowhans</td>
          </tr>
          <tr>
            <td>Credited party account no</td>
            <td>2519****3287</td>
          </tr>
          <tr>
            <td>transaction status</td>
            <td>Completed</td>
          </tr>
        </table>
        <table>
          <tr><td colspan="3">Invoice details</td></tr>
          <tr>
            <td>Invoice No.</td>
            <td>Payment date</td>
            <td>Settled Amount</td>
          </tr>
          <tr>
            <td>DFG70KZGZB</td>
            <td>16-06-2026 17:02:33</td>
            <td>10 Birr</td>
          </tr>
          <tr>
            <td></td>
            <td>Stamp Duty</td>
            <td>0.0 Birr</td>
          </tr>
          <tr>
            <td></td>
            <td>Total Paid Amount</td>
            <td>11 Birr</td>
          </tr>
        </table>
      </body></html>
    ''';

    final preview = service.parsePreviewHtml(
      html: html,
      transactionRef: 'DFG70KZGZB',
      submittedAmount: '10',
      config: const TelebirrDepositConfig(
        providerName: 'Telebirr',
        receiptHelpText: 'Enter the settled amount.',
        receiptBaseUrl: 'https://transactioninfo.ethiotelecom.et/receipt',
        receiverPhoneLast4: '3287',
        receiverName: 'Yonas Shiferaw Yowhans',
      ),
    );

    expect(preview.status, TelebirrReceiptPreviewStatus.valid);
    expect(preview.settledAmount, '10');
    expect(preview.totalPaidAmount, '11');
  });

  test('parses invoice when section title row appears between header and data', () {
    const html = '''
      <html><body>
        <table>
          <tr>
            <td>transaction status</td>
            <td>Completed</td>
          </tr>
          <tr>
            <td>Credited Party name</td>
            <td>Yonas Shiferaw Yowhans</td>
          </tr>
          <tr>
            <td>Credited party account no</td>
            <td>2519****3287</td>
          </tr>
        </table>
        <table>
          <tr>
            <td>Invoice No.</td>
            <td>Payment date</td>
            <td>Settled Amount</td>
          </tr>
          <tr>
            <td colspan="3">የክፍያ ዝርዝር/ Invoice details</td>
          </tr>
          <tr>
            <td>DFG70KZGZB</td>
            <td>15-06-2026 10:00:00</td>
            <td>10 Birr</td>
          </tr>
        </table>
      </body></html>
    ''';

    final preview = service.parsePreviewHtml(
      html: html,
      transactionRef: 'DFG70KZGZB',
      submittedAmount: '10',
      config: const TelebirrDepositConfig(
        providerName: 'Telebirr',
        receiptHelpText: 'Enter the settled amount.',
        receiptBaseUrl: 'https://transactioninfo.ethiotelecom.et/receipt',
        receiverPhoneLast4: '3287',
        receiverName: 'Yonas Shiferaw Yowhans',
      ),
    );

    expect(preview.status, TelebirrReceiptPreviewStatus.valid);
  });

  test('falls back to server verification when receipt html is unparseable', () {
    final preview = service.parsePreviewHtml(
      html: '<html><body><p>Receipt unavailable</p></body></html>',
      transactionRef: 'DFG70KZGZB',
      submittedAmount: '10',
      config: config,
    );

    expect(preview.status, TelebirrReceiptPreviewStatus.previewUnavailable);
    expect(preview.canContinueToBackend, isTrue);
  });
}
