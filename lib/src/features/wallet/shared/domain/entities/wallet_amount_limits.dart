import 'package:flutter/services.dart';

/// Fixed deposit/withdraw amount bounds for one transaction (ETB).
abstract final class WalletAmountLimits {
  static const double minDeposit = 10;
  static const double maxDeposit = 10000;
  static const double minWithdraw = 500;
  static const double maxWithdraw = 10000;

  static final RegExp amountPattern = RegExp(r'^\d+(\.\d{1,2})?$');

  static double? tryParseAmount(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty || !amountPattern.hasMatch(trimmed)) {
      return null;
    }
    return double.tryParse(trimmed);
  }

  static bool isInDepositRange(double amount) {
    return amount >= minDeposit && amount <= maxDeposit;
  }

  static bool isInWithdrawRange(double amount) {
    return amount >= minWithdraw && amount <= maxWithdraw;
  }

  /// True when [value] is a complete, in-range deposit amount.
  static bool isSubmittableDeposit(String? value) {
    final parsed = tryParseAmount(value);
    return parsed != null && isInDepositRange(parsed);
  }

  /// True when [value] is a complete, in-range withdraw amount
  /// (balance check is separate).
  static bool isSubmittableWithdraw(String? value) {
    final parsed = tryParseAmount(value);
    return parsed != null && isInWithdrawRange(parsed);
  }

  static String formatLimit(double amount) {
    final whole = amount.round();
    final digits = whole.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      if (i > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// Digits + optional decimals (max 2). Rejects values that already exceed [maxAmount].
class WalletAmountInputFormatter extends TextInputFormatter {
  const WalletAmountInputFormatter({required this.maxAmount});

  final double maxAmount;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    // Allow intermediate typing: "12." or leading digits only.
    if (!RegExp(r'^\d+\.?\d{0,2}$').hasMatch(text)) {
      return oldValue;
    }

    if (text == '.' || text.endsWith('.')) {
      return newValue;
    }

    final parsed = double.tryParse(text);
    if (parsed != null && parsed > maxAmount) {
      return oldValue;
    }

    return newValue;
  }
}
