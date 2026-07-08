import '../../data/models/payment_provider.dart';

enum WithdrawalConfirmationKind { pending, approved, rejected }

class WithdrawalConfirmationState {
  const WithdrawalConfirmationState({
    required this.kind,
    this.message,
    this.provider,
    this.amount,
    this.withdrawalId,
  });

  const WithdrawalConfirmationState.pending({
    required this.provider,
    required this.amount,
    required this.withdrawalId,
  }) : kind = WithdrawalConfirmationKind.pending,
       message = null;

  final WithdrawalConfirmationKind kind;
  final String? message;
  final PaymentProvider? provider;
  final String? amount;
  final String? withdrawalId;

  String get switchKey => switch (kind) {
    WithdrawalConfirmationKind.pending => 'pending-$withdrawalId',
    WithdrawalConfirmationKind.approved => 'approved-$withdrawalId-$amount',
    WithdrawalConfirmationKind.rejected => 'rejected-$withdrawalId-$message',
  };
}
