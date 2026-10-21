import 'package:friends_bingo_app/l10n/app_localizations.dart';
import '../../data/models/payment_provider.dart';
import '../../domain/wallet_amount_limits.dart';

abstract final class WalletValidationUtils {
  static String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  static String normalizePhoneKey(String phone) {
    final digits = digitsOnly(phone);
    if (digits.startsWith('251') && digits.length >= 12) {
      return digits.substring(digits.length - 9);
    }
    if (digits.startsWith('0') && digits.length >= 10) {
      return digits.substring(digits.length - 9);
    }
    return digits;
  }

  static bool phonesMatch(String a, String b) {
    final left = normalizePhoneKey(a);
    final right = normalizePhoneKey(b);
    if (left.isEmpty || right.isEmpty) return false;
    return left == right || left.endsWith(right) || right.endsWith(left);
  }

  static bool isOtherTelebirrNumber({
    required PaymentProvider? provider,
    required String? ownPhone,
    required String enteredPhone,
  }) {
    if (provider != PaymentProvider.telebirr) return false;
    final own = ownPhone?.trim();
    final entered = enteredPhone.trim();
    if (own == null || own.isEmpty || entered.isEmpty) return false;
    return !phonesMatch(own, entered);
  }

  static String? validateAmount({
    required String? value,
    required String? availableBalance,
    required AppLocalizations l10n,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return l10n.validatorAmountRequired;
    if (!WalletAmountLimits.amountPattern.hasMatch(trimmed)) {
      return l10n.validatorAmountInvalid;
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed <= 0) return l10n.validatorAmountPositive;
    if (parsed < WalletAmountLimits.minWithdraw) {
      return l10n.validatorWithdrawAmountMin(
        WalletAmountLimits.formatLimit(WalletAmountLimits.minWithdraw),
      );
    }
    if (parsed > WalletAmountLimits.maxWithdraw) {
      return l10n.validatorWithdrawAmountMax(
        WalletAmountLimits.formatLimit(WalletAmountLimits.maxWithdraw),
      );
    }
    final available = double.tryParse(availableBalance ?? '');
    if (available != null && parsed > available) {
      return l10n.withdrawAmountExceedsAvailable;
    }
    return null;
  }

  static String? validateReceiver({
    required String? value,
    required PaymentProvider? provider,
    required AppLocalizations l10n,
  }) {
    if (provider == null) return null;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      final phoneReq =
          l10n.validatorPhoneRequired.replaceFirst('Phone number', '').trim();
      return '${provider.receiverFieldLabel} $phoneReq';
    }
    if (provider == PaymentProvider.telebirr &&
        !RegExp(r'^\d{10,15}$').hasMatch(trimmed)) {
      return l10n.validatorPhoneInvalid;
    }
    if (provider == PaymentProvider.cbe) {
      final digits = digitsOnly(trimmed);
      if (digits != trimmed) return 'CBE account must be numbers only.';
      if (!digits.startsWith('1000')) return 'CBE account should start with 1000.';
      if (digits.length < 5) return 'Enter your full CBE account number.';
    }
    return null;
  }
}
