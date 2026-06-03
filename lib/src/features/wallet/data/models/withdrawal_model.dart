import 'payment_provider.dart';

enum WithdrawalStatus {
  pending,
  approved,
  paid,
  rejected,
  failed,
  refunded;

  factory WithdrawalStatus.fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return WithdrawalStatus.pending;
      case 'APPROVED':
        return WithdrawalStatus.approved;
      case 'PAID':
        return WithdrawalStatus.paid;
      case 'REJECTED':
        return WithdrawalStatus.rejected;
      case 'FAILED':
        return WithdrawalStatus.failed;
      case 'REFUNDED':
        return WithdrawalStatus.refunded;
      default:
        throw ArgumentError.value(
          value,
          'value',
          'Unsupported withdrawal status',
        );
    }
  }

  String get label {
    switch (this) {
      case WithdrawalStatus.pending:
        return 'Pending';
      case WithdrawalStatus.approved:
        return 'Approved';
      case WithdrawalStatus.paid:
        return 'Paid';
      case WithdrawalStatus.rejected:
        return 'Rejected';
      case WithdrawalStatus.failed:
        return 'Failed';
      case WithdrawalStatus.refunded:
        return 'Refunded';
    }
  }
}

class WithdrawalModel {
  WithdrawalModel({
    required this.id,
    required this.userId,
    required this.provider,
    required this.amount,
    required this.receiverPhone,
    required this.receiverAccount,
    required this.payoutRef,
    required this.status,
    required this.adminNote,
    required this.createdAt,
    required this.updatedAt,
    required this.paidAt,
  });

  final String id;
  final String userId;
  final PaymentProvider provider;
  final String amount;
  final String? receiverPhone;
  final String? receiverAccount;
  final String? payoutRef;
  final WithdrawalStatus status;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      provider: PaymentProvider.fromApi(json['provider'] as String),
      amount: json['amount'] as String,
      receiverPhone: json['receiverPhone'] as String?,
      receiverAccount: json['receiverAccount'] as String?,
      payoutRef: json['payoutRef'] as String?,
      status: WithdrawalStatus.fromApi(json['status'] as String),
      adminNote: json['adminNote'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      paidAt: json['paidAt'] is String
          ? DateTime.tryParse(json['paidAt'] as String)
          : null,
    );
  }
}
