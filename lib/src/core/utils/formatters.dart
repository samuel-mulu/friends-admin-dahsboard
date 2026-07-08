String formatDateTime(DateTime? value) {
  if (value == null) {
    return 'N/A';
  }

  final local = value.toLocal();
  final date =
      '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)}';
  final time = '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
  return '$date $time';
}

String formatMoney(String amount) {
  return '$amount ETB';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
