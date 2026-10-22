import 'deposit_receipt_code.dart';
import 'smart_deposit_parse_result.dart';

final RegExp _telebirrTransferredAmountPattern = RegExp(
  r'You have transferred\s+ETB\s+([\d,]+(?:\.\d{1,2})?)',
  caseSensitive: false,
);

final RegExp _telebirrDjTransactionPattern = RegExp(
  r'\b(DJ[A-Z0-9]{6,20})\b',
  caseSensitive: false,
);

final RegExp _cbeHostPattern = RegExp(
  r'mbreciept\.cbe\.com\.et|cbe\.com\.et',
  caseSensitive: false,
);

final RegExp _cbeFtTokenPattern = RegExp(r'\bFT[A-Z0-9]{6,}\b', caseSensitive: false);

/// Parses Telebirr Smart Deposit input for a Telebirr-selected provider only.
///
/// Accepts full SMS, official receipt URL, or bare receipt / DJ reference.
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
  final djRef = _telebirrDjTransactionPattern.firstMatch(text)?.group(1);

  if (djRef != null) {
    final normalized = normalizeDepositReceiptCode(djRef);
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

  // SMS-like body without a DJ reference — do not invent alternate formats.
  if (amount != null || text.toLowerCase().contains('telebirr')) {
    return const SmartDepositParseResult.incomplete();
  }

  return const SmartDepositParseResult.unsupported();
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
      !_telebirrDjTransactionPattern.hasMatch(text) &&
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
