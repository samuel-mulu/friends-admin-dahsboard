import 'deposit_receipt_code.dart';
import 'smart_deposit_parse_result.dart';

final RegExp _telebirrTransferredAmountPattern = RegExp(
  r'You have transferred\s+ETB\s+([\d,]+(?:\.\d{1,2})?)',
  caseSensitive: false,
);

/// Official receipt link inside the SMS. The capture stops at the first
/// non-alphanumeric character, so the SMS's trailing "." is not included.
final RegExp _telebirrReceiptLinkPattern = RegExp(
  r'transactioninfo\.ethiotelecom\.et/receipt/([A-Za-z0-9]{6,20})',
  caseSensitive: false,
);

/// Transaction number in the SMS body: "D" + any capital letter (DJ, DK, ...)
/// + capitals/digits, 8–20 chars. Case-sensitive so words like "Dear" never
/// match; a digit is also required (see [_findTelebirrTransactionCode]).
final RegExp _telebirrSmsCodePattern = RegExp(r'\b(D[A-Z][A-Z0-9]{6,18})\b');

final RegExp _digitPattern = RegExp(r'\d');

final RegExp _cbeHostPattern = RegExp(
  r'mbreciept\.cbe\.com\.et|cbe\.com\.et',
  caseSensitive: false,
);

final RegExp _cbeFtTokenPattern = RegExp(r'\bFT[A-Z0-9]{6,}\b', caseSensitive: false);

/// Parses Telebirr Smart Deposit input for a Telebirr-selected provider only.
///
/// Accepts full SMS, official receipt URL, or bare receipt code.
/// Never switches provider; rejects clear CBE markers.
SmartDepositParseResult parseTelebirrSmartDepositInput(String raw) {
  final text = raw.trim();
  if (text.isEmpty) {
    return const SmartDepositParseResult.incomplete();
  }

  if (_looksLikeCbeInput(text)) {
    return const SmartDepositParseResult.wrongProvider();
  }

  final amount = _extractTransferredAmount(text);
  final code = _findTelebirrTransactionCode(text);

  if (code != null) {
    final normalized = normalizeDepositReceiptCode(code);
    if (isValidTelebirrReceiptCode(normalized)) {
      return SmartDepositParseResult.success(
        transactionRef: normalized,
        amount: amount,
      );
    }
  }

  // Official receipt URL or bare receipt code (no SMS body).
  if (_isUrlOrBareCode(text)) {
    final normalized = normalizeDepositReceiptCode(text);
    if (isValidTelebirrReceiptCode(normalized)) {
      return SmartDepositParseResult.success(
        transactionRef: normalized,
        amount: amount,
      );
    }
    return const SmartDepositParseResult.incomplete();
  }

  // SMS-like body without a receipt link or transaction number.
  if (amount != null || text.toLowerCase().contains('telebirr')) {
    return const SmartDepositParseResult.incomplete();
  }

  return const SmartDepositParseResult.unsupported();
}

/// Receipt link code first (official, any prefix), else the first D-code in
/// the SMS body that contains a digit.
String? _findTelebirrTransactionCode(String text) {
  final fromLink = _telebirrReceiptLinkPattern.firstMatch(text)?.group(1);
  if (fromLink != null) {
    return fromLink;
  }
  for (final match in _telebirrSmsCodePattern.allMatches(text)) {
    final candidate = match.group(1)!;
    if (_digitPattern.hasMatch(candidate)) {
      return candidate;
    }
  }
  return null;
}

String? _extractTransferredAmount(String text) {
  final match = _telebirrTransferredAmountPattern.firstMatch(text);
  if (match == null) {
    return null;
  }
  final rawAmount = match.group(1)?.replaceAll(',', '').trim();
  if (rawAmount == null || rawAmount.isEmpty) {
    return null;
  }
  final value = double.tryParse(rawAmount);
  if (value == null || value <= 0) {
    return null;
  }
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(2);
}

bool _looksLikeCbeInput(String text) {
  if (_cbeHostPattern.hasMatch(text)) {
    return true;
  }
  final lower = text.toLowerCase();
  if (lower.contains('commercial bank of ethiopia')) {
    return true;
  }
  // Bare FT-style CBE refs pasted into Telebirr Smart.
  if (_cbeFtTokenPattern.hasMatch(text) &&
      !_telebirrSmsCodePattern.hasMatch(text) &&
      !lower.contains('telebirr') &&
      !lower.contains('you have transferred')) {
    return true;
  }
  return false;
}

bool _isUrlOrBareCode(String text) {
  if (text.contains(' ') || text.contains('\n')) {
    return false;
  }
  final lower = text.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return true;
  }
  return RegExp(r'^[A-Za-z0-9]{6,20}$').hasMatch(text);
}
