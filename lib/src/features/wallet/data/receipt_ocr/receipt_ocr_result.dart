class ReceiptOcrResult {
  const ReceiptOcrResult({
    required this.reference,
    required this.amount,
    required this.rawText,
    required this.provider,
    required this.confidence,
  });

  final String? reference;
  final String? amount;
  final String rawText;
  final String provider;
  final double confidence;

  bool get hasReference => reference != null && reference!.trim().isNotEmpty;

  bool get hasAmount => amount != null && amount!.trim().isNotEmpty;

  bool get hasDetectedValue => hasReference || hasAmount;

  /// True when confidence is below the threshold where we trust the result
  /// enough to pre-fill deposit fields.  Below this threshold the UI should
  /// show the failure message and not apply the result.
  bool get isLowConfidence => confidence < 0.60;
}
