import '../../data/models/payment_provider.dart';

enum DepositConfirmationKind { verifying, approved, pending, rejected }

class DepositConfirmationState {
  const DepositConfirmationState({
    required this.kind,
    this.message,
    this.provider,
    this.amount,
    this.transactionRef,
    this.verifiedAt,
  });

  const DepositConfirmationState.verifying()
    : kind = DepositConfirmationKind.verifying,
      message = null,
      provider = null,
      amount = null,
      transactionRef = null,
      verifiedAt = null;

  final DepositConfirmationKind kind;
  final String? message;
  final PaymentProvider? provider;
  final String? amount;
  final String? transactionRef;
  final DateTime? verifiedAt;

  String get switchKey => switch (kind) {
    DepositConfirmationKind.verifying => 'verifying',
    DepositConfirmationKind.approved =>
      'approved-$transactionRef-$amount',
    DepositConfirmationKind.pending => 'pending-$transactionRef-$amount',
    DepositConfirmationKind.rejected => 'rejected-$message',
  };
}
