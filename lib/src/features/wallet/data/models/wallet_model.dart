class WalletModel {
  WalletModel({
    required this.id,
    required this.userId,
    required this.balance,
    required this.lockedBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String balance;
  final String lockedBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      balance: json['balance'] as String,
      lockedBalance: json['lockedBalance'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
