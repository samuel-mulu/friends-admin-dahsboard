import 'cbe_manual_receipt_reference.dart';
import 'smart_deposit_parse_result.dart';

final RegExp _telebirrMarkerPattern = RegExp(
  r'telebirr|ethiotelecom\.et|you have transferred\s+etb|\bDJ[A-Z0-9]{6,20}\b',
  caseSensitive: false,
);

/// Parses CBE Smart Deposit input using only verified formats:
/// official CBE receipt URL or bare FT / mobile receipt token.
///
/// Full CBE SMS bodies are unsupported (no verified message samples in-repo).
/// Never switches provider; rejects clear Telebirr markers.
SmartDepositParseResult parseCbeSmartDepositInput(
  String raw, {
  String receiptBaseUrl = kDefaultCbeReceiptBaseUrl,
}) {
  final text = raw.trim();
  if (text.isEmpty) {
    return const SmartDepositParseResult.incomplete();
  }

  if (_telebirrMarkerPattern.hasMatch(text)) {
    return const SmartDepositParseResult.wrongProvider();
  }

  // Do not invent CBE SMS formats — multi-line / prose messages are unsupported.
  if (_looksLikeUnverifiedMessage(text)) {
    return const SmartDepositParseResult.unsupported();
  }

  final normalized = normalizeCbeManualReceiptReference(
    text,
    receiptBaseUrl: receiptBaseUrl,
  );
  if (normalized == null) {
    return const SmartDepositParseResult.incomplete();
  }

  return SmartDepositParseResult.success(transactionRef: normalized);
}

bool _looksLikeUnverifiedMessage(String text) {
  if (text.contains('\n')) {
    return true;
  }
  if (text.length > 80 && text.contains(' ')) {
    return true;
  }
  final lower = text.toLowerCase();
  return lower.contains('transferred') ||
      lower.contains('debited') ||
      lower.contains('credited') ||
      lower.contains('dear ');
}
