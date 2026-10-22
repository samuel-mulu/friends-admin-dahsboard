import '../../../shared/domain/entities/payment_provider.dart';
import 'deposit_model.dart';

class PendingDepositVerification {
  const PendingDepositVerification({
    required this.attemptId,
    required this.code,
    required this.message,
    required this.retryAfterSeconds,
    required this.provider,
    required this.amount,
    required this.transactionRef,
  });

  final String attemptId;
  final String code;
  final String message;
  final int retryAfterSeconds;
  final PaymentProvider provider;
  final String amount;
  final String transactionRef;

  factory PendingDepositVerification.fromJson(Map<String, dynamic> json) {
    return PendingDepositVerification(
      attemptId: json['attemptId'] as String,
      code: json['code'] as String? ?? 'VERIFICATION_PENDING',
      message:
          json['message'] as String? ??
          'Payment verification is still processing.',
      retryAfterSeconds: (json['retryAfterSeconds'] as num?)?.toInt() ?? 5,
      provider: PaymentProvider.fromApi(json['provider'] as String),
      amount: json['amount']?.toString() ?? '',
      transactionRef: json['transactionRef'] as String? ?? '',
    );
  }

  static bool isPendingJson(Map<String, dynamic> json) {
    return json['verificationStatus'] == 'pending' &&
        json['attemptId'] is String;
  }
}

sealed class DepositSubmitResult {
  const DepositSubmitResult();
}

class DepositSubmitApproved extends DepositSubmitResult {
  const DepositSubmitApproved(this.deposit);
  final DepositModel deposit;
}

class DepositSubmitPendingVerification extends DepositSubmitResult {
  const DepositSubmitPendingVerification(this.pending);
  final PendingDepositVerification pending;
}
