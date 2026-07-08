import '../../../../core/utils/l10n.dart';

String? validatePhoneNumber(String? value, AppLocalizations l10n) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return l10n.validatorPhoneRequired;
  }
  if (!RegExp(r'^\d{10,15}$').hasMatch(trimmed)) {
    return l10n.validatorPhoneInvalid;
  }
  return null;
}

String? validatePassword(String? value, AppLocalizations l10n) {
  if ((value ?? '').length < 6) {
    return l10n.validatorPasswordLength;
  }
  return null;
}

String? validateFullName(String? value, AppLocalizations l10n) {
  if ((value?.trim().length ?? 0) < 3) {
    return l10n.validatorFullNameLength;
  }
  return null;
}

String maskPhoneNumber(String phoneNumber) {
  final trimmed = phoneNumber.trim();
  if (trimmed.length <= 4) {
    return trimmed;
  }
  final visiblePrefix = trimmed.substring(0, 4);
  final hiddenLength = trimmed.length - 4;
  return '$visiblePrefix${'*' * hiddenLength}';
}
