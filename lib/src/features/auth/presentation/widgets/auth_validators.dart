String? validatePhoneNumber(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Phone number is required.';
  }
  if (!RegExp(r'^\d{10,15}$').hasMatch(trimmed)) {
    return 'Enter a valid phone number.';
  }
  return null;
}

String? validatePassword(String? value) {
  if ((value ?? '').length < 8) {
    return 'Password must be at least 8 characters.';
  }
  return null;
}

String? validateFullName(String? value) {
  if ((value?.trim().length ?? 0) < 3) {
    return 'Full name must be at least 3 characters.';
  }
  return null;
}

String maskPhoneNumber(String phoneNumber) {
  final trimmed = phoneNumber.trim();
  if (trimmed.length <= 4) {
    return trimmed;
  }
  if (trimmed.length <= 7) {
    return '${trimmed.substring(0, 2)}***${trimmed.substring(trimmed.length - 2)}';
  }
  return '${trimmed.substring(0, 4)}***${trimmed.substring(trimmed.length - 3)}';
}
