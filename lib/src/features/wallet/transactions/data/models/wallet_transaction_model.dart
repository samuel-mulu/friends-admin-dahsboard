enum WalletTransactionType {
  deposit,
  withdrawRequest,
  withdrawPaid,
  withdrawRefund,
  gameEntry,
  prizeWin,
  refund,
  adminAdjustment;

  factory WalletTransactionType.fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'DEPOSIT':
        return WalletTransactionType.deposit;
      case 'WITHDRAW_REQUEST':
        return WalletTransactionType.withdrawRequest;
      case 'WITHDRAW_PAID':
        return WalletTransactionType.withdrawPaid;
      case 'WITHDRAW_REFUND':
        return WalletTransactionType.withdrawRefund;
      case 'GAME_ENTRY':
        return WalletTransactionType.gameEntry;
      case 'PRIZE_WIN':
        return WalletTransactionType.prizeWin;
      case 'REFUND':
        return WalletTransactionType.refund;
      case 'ADMIN_ADJUSTMENT':
        return WalletTransactionType.adminAdjustment;
      default:
        throw ArgumentError.value(
          value,
          'value',
          'Unsupported wallet transaction type',
        );
    }
  }

  String get label {
    switch (this) {
      case WalletTransactionType.deposit:
        return 'Deposit';
      case WalletTransactionType.withdrawRequest:
        return 'Withdraw request';
      case WalletTransactionType.withdrawPaid:
        return 'Withdraw paid';
      case WalletTransactionType.withdrawRefund:
        return 'Withdraw refund';
      case WalletTransactionType.gameEntry:
        return 'Game entry';
      case WalletTransactionType.prizeWin:
        return 'Prize win';
      case WalletTransactionType.refund:
        return 'Refund';
      case WalletTransactionType.adminAdjustment:
        return 'Admin adjustment';
    }
  }
}

class WalletTransactionModel {
  WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.referenceType,
    required this.referenceId,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final WalletTransactionType type;
  final String amount;
  final String balanceBefore;
  final String balanceAfter;
  final String? referenceType;
  final String? referenceId;
  final String? description;
  final DateTime createdAt;

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: WalletTransactionType.fromApi(json['type'] as String),
      amount: json['amount'] as String,
      balanceBefore: json['balanceBefore'] as String,
      balanceAfter: json['balanceAfter'] as String,
      referenceType: json['referenceType'] as String?,
      referenceId: json['referenceId'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
