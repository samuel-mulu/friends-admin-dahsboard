/// Shared text helpers for deposit receipt OCR parsing.
class ReceiptOcrTextUtils {
  const ReceiptOcrTextUtils._();

  static String normalize(String rawText) {
    return rawText.toUpperCase().replaceAll('\u00A0', ' ').trim();
  }

  static String? normalizeAmount(String rawValue) {
    final sanitized = rawValue.replaceAll(',', '').trim();
    if (sanitized.isEmpty) return null;

    final parsed = double.tryParse(sanitized);
    if (parsed == null || parsed <= 0 || parsed >= 100000) return null;

    return parsed.toStringAsFixed(2);
  }

  /// OCR confusions for receipt reference tokens.
  /// Only substitutes when a letter sits between two digits so legitimate
  /// alphanumeric chars (e.g. B in FT…DB3X, L in D…LDP) are preserved.
  /// Handles O→0, S→5, I/L→1, B→8, Z→2.
  static String applyOcrCorrections(String input) {
    return input.replaceAllMapped(
      RegExp(r'(?<=[0-9])[ILOSBZ](?=[0-9])'),
      (m) => switch (m.group(0)!) {
        'I' || 'L' => '1',
        'O' => '0',
        'S' => '5',
        'B' => '8',
        'Z' => '2',
        _ => m.group(0)!,
      },
    );
  }

  static bool containsAny(String source, List<String> needles) {
    for (final needle in needles) {
      if (source.contains(needle)) return true;
    }
    return false;
  }
}
