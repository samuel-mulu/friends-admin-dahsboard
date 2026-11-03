import '../../../shared/domain/entities/payment_provider.dart';

enum DepositConfirmationKind {
  verifying,
  verificationInProgress,
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
    this.attemptId,
    this.canRetry = false,
    this.retryLabel,
    this.canCheckAgain = false,
    this.checkAgainAvailableAt,
  });

  const DepositConfirmationState.verifying()
    : kind = DepositConfirmationKind.verifying,
      message = null,
      provider = null,
      amount = null,
      transactionRef = null,
      verifiedAt = null,
      depositId = null,
      attemptId = null,
      canRetry = false,
      retryLabel = null,
      canCheckAgain = false,
      checkAgainAvailableAt = null;

  final DepositConfirmationKind kind;
  final String? message;
  final PaymentProvider? provider;
  final String? amount;
  final String? transactionRef;
  final DateTime? verifiedAt;
  final String? depositId;
  final String? attemptId;

  /// When true, rejected card shows "Fix and submit again" (or custom retryLabel).
  final bool canRetry;
  final String? retryLabel;

  /// When true, verification-in-progress card can poll again.
  final bool canCheckAgain;
  final DateTime? checkAgainAvailableAt;

  String get switchKey => switch (kind) {
    DepositConfirmationKind.verifying => 'verifying',
    DepositConfirmationKind.verificationInProgress =>
      'verificationInProgress-${attemptId ?? transactionRef}-$message',
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
