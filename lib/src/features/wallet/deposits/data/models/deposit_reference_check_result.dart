class DepositReferenceCheckResult {
  const DepositReferenceCheckResult({
    required this.code,
    required this.message,
  });

  factory DepositReferenceCheckResult.fromJson(Map<String, dynamic> json) {
    return DepositReferenceCheckResult(
      code: json['code'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  final String code;
  final String message;

  bool get isAvailable => code == 'OK' || code == 'CAN_VERIFY';
  bool get alreadyUsed => code == 'ALREADY_USED';
}
