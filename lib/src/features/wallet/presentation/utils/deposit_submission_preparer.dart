import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/payment_provider.dart';
import '../../data/models/telebirr_client_receipt_payload.dart';
import '../../data/models/telebirr_receipt_preview.dart';
import '../../data/telebirr_receipt_preview_service.dart';
import '../providers/deposit_config_provider.dart';
import 'cbe_manual_receipt_reference.dart';
import 'deposit_receipt_code.dart';

class PreparedDepositPayload {
  const PreparedDepositPayload({
    required this.transactionRef,
    this.cbeManualReceiptUrl,
    this.receiptParseStatus,
    this.clientReceipt,
    this.validationError,
  });

  final String transactionRef;
  final String? cbeManualReceiptUrl;
  final TelebirrReceiptParseStatus? receiptParseStatus;
  final TelebirrClientReceiptPayload? clientReceipt;
  final String? validationError;
}

abstract final class DepositSubmissionPreparer {
  static Future<PreparedDepositPayload> prepare({
    required Ref ref,
    required PaymentProvider provider,
    required String amount,
    required String rawTransactionInput,
  }) async {
    TelebirrReceiptParseStatus? receiptParseStatus;
    TelebirrClientReceiptPayload? clientReceipt;
    String? cbeManualReceiptUrl;
    late final String transactionRef;

    if (provider == PaymentProvider.telebirr) {
      transactionRef = normalizeDepositReceiptCode(rawTransactionInput);
      final depositConfig = await ref.read(depositConfigProvider.future);
      final approvalMode = depositConfig
          .providerForKey(PaymentProvider.telebirr.apiValue)
          ?.approvalMode;
      if (approvalMode == 'local') {
        final preview = await ref
            .read(telebirrReceiptPreviewServiceProvider)
            .preview(
              transactionRef: transactionRef,
              submittedAmount: amount,
              config: depositConfig.telebirr,
            );
        receiptParseStatus = preview.receiptParseStatus;
        clientReceipt = preview.toClientReceiptPayload();

        if (preview.status == TelebirrReceiptPreviewStatus.previewUnavailable) {
          receiptParseStatus = TelebirrReceiptParseStatus.unavailable;
          clientReceipt = null;
        } else if (preview.status != TelebirrReceiptPreviewStatus.valid ||
            clientReceipt == null) {
          return PreparedDepositPayload(
            transactionRef: transactionRef,
            validationError: 'Receipt preview validation failed',
          );
        }
      }
    } else if (provider == PaymentProvider.cbe) {
      final depositConfig = await ref.read(depositConfigProvider.future);
      final cbeConfig =
          depositConfig.providerForKey(PaymentProvider.cbe.apiValue);
      if (cbeConfig?.approvalMode == 'manual') {
        final normalized = normalizeCbeManualReceiptReference(
          rawTransactionInput,
          receiptBaseUrl: cbeConfig!.receiptBaseUrl.isEmpty
              ? kDefaultCbeReceiptBaseUrl
              : cbeConfig.receiptBaseUrl,
        );
        if (normalized == null) {
          return PreparedDepositPayload(
            transactionRef: rawTransactionInput,
            validationError:
                'Enter a valid CBE receipt ID or official receipt URL.',
          );
        }
        transactionRef = normalized;
        if (isReceiptUrlInput(rawTransactionInput)) {
          cbeManualReceiptUrl = rawTransactionInput;
        }
      } else {
        transactionRef = rawTransactionInput.toUpperCase();
      }
    } else {
      transactionRef = rawTransactionInput.toUpperCase();
    }

    return PreparedDepositPayload(
      transactionRef: transactionRef,
      cbeManualReceiptUrl: cbeManualReceiptUrl,
      receiptParseStatus: receiptParseStatus,
      clientReceipt: clientReceipt,
    );
  }
}
