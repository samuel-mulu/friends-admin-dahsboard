import 'telebirr_client_receipt_payload.dart';

enum TelebirrReceiptPreviewStatus {
  valid,
  invalidReceipt,
  amountMismatch,
  receiverMismatch,
  previewUnavailable,
}

class TelebirrReceiptPreview {
  const TelebirrReceiptPreview({
    required this.status,
    required this.transactionRef,
    this.settledAmount,
    this.totalPaidAmount,
    this.creditedPartyName,
    this.creditedPartyAccountNo,
    this.transactionStatus,
    this.message,
  });

  final TelebirrReceiptPreviewStatus status;
  final String transactionRef;
  final String? settledAmount;
  final String? totalPaidAmount;
  final String? creditedPartyName;
  final String? creditedPartyAccountNo;
  final String? transactionStatus;
  final String? message;

  bool get canContinueToBackend =>
      status == TelebirrReceiptPreviewStatus.valid ||
      status == TelebirrReceiptPreviewStatus.previewUnavailable;

  /// Local approval mode requires a successful client-side receipt parse.
  /// Automatic mode may continue without one (verify.et handles it).
  bool get hasParsedClientReceipt =>
      status == TelebirrReceiptPreviewStatus.valid &&
      toClientReceiptPayload() != null;

  TelebirrReceiptParseStatus get receiptParseStatus {
    switch (status) {
      case TelebirrReceiptPreviewStatus.valid:
        return TelebirrReceiptParseStatus.parsed;
      case TelebirrReceiptPreviewStatus.previewUnavailable:
        return TelebirrReceiptParseStatus.unavailable;
      case TelebirrReceiptPreviewStatus.invalidReceipt:
      case TelebirrReceiptPreviewStatus.amountMismatch:
      case TelebirrReceiptPreviewStatus.receiverMismatch:
        return TelebirrReceiptParseStatus.unavailable;
    }
  }

  TelebirrClientReceiptPayload? toClientReceiptPayload() {
    if (status != TelebirrReceiptPreviewStatus.valid) {
      return null;
    }

    final invoiceNumber = transactionRef.trim();
    final settledAmountValue = settledAmount?.trim();
    final transactionStatusValue = transactionStatus?.trim();
    final creditedPartyNameValue = creditedPartyName?.trim();
    final creditedPartyAccountValue = creditedPartyAccountNo?.trim();

    if (invoiceNumber.isEmpty ||
        settledAmountValue == null ||
        settledAmountValue.isEmpty ||
        transactionStatusValue == null ||
        transactionStatusValue.isEmpty ||
        creditedPartyNameValue == null ||
        creditedPartyNameValue.isEmpty ||
        creditedPartyAccountValue == null ||
        creditedPartyAccountValue.isEmpty) {
      return null;
    }

    return TelebirrClientReceiptPayload(
      invoiceNumber: invoiceNumber,
      transactionStatus: transactionStatusValue,
      settledAmount: settledAmountValue,
      creditedPartyName: creditedPartyNameValue,
      creditedPartyAccountNo: creditedPartyAccountValue,
    );
  }
}
