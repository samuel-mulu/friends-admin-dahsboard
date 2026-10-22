enum SmartDepositParseStatus {
  success,
  wrongProvider,
  unsupported,
  incomplete,
}

/// Outcome of provider-scoped Smart Deposit parsing.
///
/// Provider is never inferred from the pasted text — callers always parse
/// with the already-selected [PaymentProvider].
class SmartDepositParseResult {
  const SmartDepositParseResult({
    required this.status,
    this.transactionRef,
    this.amount,
  });

  const SmartDepositParseResult.success({
    required String transactionRef,
    String? amount,
  }) : this(
         status: SmartDepositParseStatus.success,
         transactionRef: transactionRef,
         amount: amount,
       );

  const SmartDepositParseResult.wrongProvider()
    : this(status: SmartDepositParseStatus.wrongProvider);

  const SmartDepositParseResult.unsupported()
    : this(status: SmartDepositParseStatus.unsupported);

  const SmartDepositParseResult.incomplete()
    : this(status: SmartDepositParseStatus.incomplete);

  final SmartDepositParseStatus status;
  final String? transactionRef;
  final String? amount;

  bool get isSuccess => status == SmartDepositParseStatus.success;
}
