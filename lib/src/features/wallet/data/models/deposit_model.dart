import 'payment_provider.dart';

enum DepositStatus {
  pending,
  verifying,
  approved,
  rejected,
  manualReview;

  factory DepositStatus.fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return DepositStatus.pending;
      case 'VERIFYING':
        return DepositStatus.verifying;
      case 'APPROVED':
        return DepositStatus.approved;
      case 'REJECTED':
        return DepositStatus.rejected;
      case 'MANUAL_REVIEW':
        return DepositStatus.manualReview;
      default:
        throw ArgumentError.value(value, 'value', 'Unsupported deposit status');
    }
  }

  String get label {
    switch (this) {
      case DepositStatus.pending:
        return 'Pending';
      case DepositStatus.verifying:
        return 'Verifying';
      case DepositStatus.approved:
        return 'Approved';
      case DepositStatus.rejected:
        return 'Rejected';
      case DepositStatus.manualReview:
        return 'Manual review';
    }
  }

  bool get canRetry {
    return this == DepositStatus.verifying ||
        this == DepositStatus.manualReview;
  }
}

class DepositModel {
  DepositModel({
    required this.id,
    required this.userId,
    required this.provider,
    required this.amount,
    required this.transactionRef,
    required this.status,
    required this.rejectionReason,
    required this.createdAt,
    required this.verifiedAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final PaymentProvider provider;
  final String amount;
  final String transactionRef;
  final DepositStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final DateTime updatedAt;

  factory DepositModel.fromJson(Map<String, dynamic> json) {
    return DepositModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      provider: PaymentProvider.fromApi(json['provider'] as String),
      amount: json['amount'] as String,
      transactionRef: json['transactionRef'] as String,
      status: DepositStatus.fromApi(json['status'] as String),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      verifiedAt: json['verifiedAt'] is String
          ? DateTime.tryParse(json['verifiedAt'] as String)
          : null,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
