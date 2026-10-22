class WalletBalanceMath {
  static String add(String left, String right) {
    return _fromCents(_toCents(left) + _toCents(right));
  }

  static bool isPositive(String amount) {
    return _toCents(amount) > 0;
  }

  static int _toCents(String amount) {
    final normalized = amount.trim();
    if (normalized.isEmpty) {
      return 0;
    }

    final parts = normalized.split('.');
    final whole = int.tryParse(parts.first) ?? 0;
    final fractionRaw = parts.length > 1 ? parts[1] : '0';
    final fraction = int.tryParse(fractionRaw.padRight(2, '0').substring(0, 2)) ??
        0;

    return whole * 100 + fraction;
  }

  static String _fromCents(int cents) {
    final negative = cents < 0;
    final absolute = negative ? -cents : cents;
    final whole = absolute ~/ 100;
    final fraction = (absolute % 100).toString().padLeft(2, '0');
    final value = '$whole.$fraction';
    return negative ? '-$value' : value;
  }
}
