const telebirrReceiptCodePattern = r'^[A-Z0-9]{6,20}$';

String normalizeDepositReceiptCode(String input) {
  final trimmed = input.trim();
  final lower = trimmed.toLowerCase();

  if (lower.contains('/receipt/')) {
    final parts = trimmed.split(RegExp('/receipt/', caseSensitive: false));
    if (parts.length > 1) {
      final tail = parts.last.split('/').first.split('?').first.trim();
      if (tail.isNotEmpty) {
        return tail.toUpperCase();
      }
    }
  }

  return trimmed.toUpperCase();
}

bool isValidTelebirrReceiptCode(String value) {
  return RegExp(telebirrReceiptCodePattern).hasMatch(value);
}

String? validateTelebirrReceiptCode(String? rawValue) {
  final normalized = normalizeDepositReceiptCode(rawValue ?? '');
  if (normalized.isEmpty) {
    return 'Receipt code is required.';
  }
  if (!isValidTelebirrReceiptCode(normalized)) {
    return 'Enter a valid receipt code (6-20 letters and numbers).';
  }
  return null;
}
