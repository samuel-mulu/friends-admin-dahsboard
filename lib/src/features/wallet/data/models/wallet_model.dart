import '../../domain/wallet_balance_math.dart';

class WalletModel {
  WalletModel({
    required this.id,
    required this.userId,
    required this.balance,
    required this.lockedBalance,
    this.bonusCartelaBalance = 0,
    this.bigGameTicketBalance = 0,
    this.bigGameTicketSlotId,
    this.bigGameName,
    this.isFirstTimePlayer = false,
    required this.createdAt,
    required this.updatedAt,
    String? totalBalance,
  }) : _apiTotalBalance = totalBalance;

  final String id;
  final String userId;
  final String balance;
  final String lockedBalance;
  final int bonusCartelaBalance;
  final int bigGameTicketBalance;
  final String? bigGameTicketSlotId;
  final String? bigGameName;
  final bool isFirstTimePlayer;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? _apiTotalBalance;

  String get totalBalance =>
      _apiTotalBalance ?? WalletBalanceMath.add(balance, lockedBalance);

  bool get hasLockedFunds => WalletBalanceMath.isPositive(lockedBalance);

  bool get shouldShowWelcomeBonus =>
      isFirstTimePlayer && bonusCartelaBalance > 0;

  bool get hasBigGameTickets => bigGameTicketBalance > 0;

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      balance: json['balance'] as String,
      lockedBalance: json['lockedBalance'] as String,
      bonusCartelaBalance: json['bonusCartelaBalance'] as int? ?? 0,
      bigGameTicketBalance: (json['bigGameTicketBalance'] as num?)?.toInt() ?? 0,
      bigGameTicketSlotId: json['bigGameTicketSlotId'] as String?,
      bigGameName: json['bigGameName'] as String?,
      isFirstTimePlayer: json['isFirstTimePlayer'] as bool? ?? false,
      totalBalance: json['totalBalance'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'balance': balance,
      'lockedBalance': lockedBalance,
      'bonusCartelaBalance': bonusCartelaBalance,
      'bigGameTicketBalance': bigGameTicketBalance,
      'bigGameTicketSlotId': bigGameTicketSlotId,
      'bigGameName': bigGameName,
      'isFirstTimePlayer': isFirstTimePlayer,
      'totalBalance': totalBalance,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
