import '../../data/models/payment_provider.dart';

enum DepositConfirmationKind {
  verifying,
  approved,
  pending,
  underReview,
  rejected,
}

class DepositConfirmationState {
  const DepositConfirmationState({
    required this.kind,
    this.message,
    this.provider,
    this.amount,
    this.transactionRef,
    this.verifiedAt,
    this.depositId,
    this.canRetry = false,
  });

  const DepositConfirmationState.verifying()
    : kind = DepositConfirmationKind.verifying,
      message = null,
      provider = null,
      amount = null,
      transactionRef = null,
      verifiedAt = null,
      depositId = null,
      canRetry = false;

  final DepositConfirmationKind kind;
  final String? message;
  final PaymentProvider? provider;
  final String? amount;
  final String? transactionRef;
  final DateTime? verifiedAt;
  final String? depositId;

  /// When true, rejected card shows "Fix and submit again".
  final bool canRetry;

  String get switchKey => switch (kind) {
    DepositConfirmationKind.verifying => 'verifying',
    DepositConfirmationKind.approved =>
      'approved-${depositId ?? transactionRef}-$amount',
    DepositConfirmationKind.pending =>
      'pending-${depositId ?? transactionRef}-$amount',
    DepositConfirmationKind.underReview =>
      'underReview-${transactionRef ?? depositId}',
    DepositConfirmationKind.rejected =>
      'rejected-${depositId ?? transactionRef}-$message-$canRetry',
  };
}
