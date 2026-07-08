import 'package:flutter/material.dart';
import 'wallet_breakdown_card.dart';

/// Compact gradient balance strip for the withdraw screen.
class WithdrawBalanceStrip extends StatelessWidget {
  const WithdrawBalanceStrip({
    required this.availableBalance,
    required this.lockedBalance,
    this.totalBalance,
    super.key,
  });

  final String availableBalance;
  final String lockedBalance;
  final String? totalBalance;

  @override
  Widget build(BuildContext context) {
    return WalletBreakdownCard(
      balance: availableBalance,
      lockedBalance: lockedBalance,
      totalBalance: totalBalance,
      style: WalletBreakdownStyle.strip,
    );
  }
}
