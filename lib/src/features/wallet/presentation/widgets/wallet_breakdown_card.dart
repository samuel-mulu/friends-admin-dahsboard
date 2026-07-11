import 'package:flutter/material.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/wallet_model.dart';
import '../../domain/wallet_balance_math.dart';

enum WalletBreakdownStyle { hero, strip, inline }

class WalletBreakdownCard extends StatelessWidget {
  const WalletBreakdownCard({
    required this.balance,
    required this.lockedBalance,
    this.bonusCartelaBalance = 0,
    this.totalBalance,
    this.style = WalletBreakdownStyle.hero,
    super.key,
  });

  factory WalletBreakdownCard.fromWallet(
    WalletModel wallet, {
    WalletBreakdownStyle style = WalletBreakdownStyle.hero,
  }) {
    return WalletBreakdownCard(
      balance: wallet.balance,
      lockedBalance: wallet.lockedBalance,
      bonusCartelaBalance: wallet.bonusCartelaBalance,
      totalBalance: wallet.totalBalance,
      style: style,
    );
  }

  final String balance;
  final String lockedBalance;
  final int bonusCartelaBalance;
  final String? totalBalance;
  final WalletBreakdownStyle style;

  String get _total =>
      totalBalance ?? WalletBalanceMath.add(balance, lockedBalance);

  bool get _hasLocked => WalletBalanceMath.isPositive(lockedBalance);
  bool get _hasBonusCartelas => bonusCartelaBalance > 0;

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      WalletBreakdownStyle.hero => _buildHeroBreakdown(context),
      WalletBreakdownStyle.strip => _buildStripBreakdown(context),
      WalletBreakdownStyle.inline => _buildInlineBreakdown(context),
    };
  }

  Widget _buildHeroBreakdown(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppBranding.casinoPurple, AppBranding.casinoPurpleDeep],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppBranding.casinoPurple.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  child: Icon(
                    _hasLocked
                        ? Icons.account_balance_wallet_outlined
                        : Icons.savings_outlined,
                    color: AppBranding.gold,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildPrimaryAmount(context)),
              ],
            ),
            if (_hasLocked) ...[
              const SizedBox(height: 20),
              _buildSubRow(
                context,
                label: l10n.walletFreezBalance,
                amount: lockedBalance,
                emphasize: false,
                icon: Icons.ac_unit_outlined,
              ),
            ],
            if (_hasBonusCartelas) ...[
              const SizedBox(height: 20),
              _buildBonusCartelaRow(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStripBreakdown(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (_hasLocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppBranding.casinoPurple, AppBranding.casinoPurpleDeep],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.ac_unit_outlined,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.walletFreezBalance,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatMoney(lockedBalance),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppBranding.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppBranding.casinoPurple, AppBranding.casinoPurpleDeep],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              formatMoney(balance),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppBranding.gold,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineBreakdown(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.walletAvailableBalance,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatMoney(balance),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppBranding.balanceAccent(context),
          ),
        ),
        if (_hasLocked) ...[
          const SizedBox(height: 6),
          Text(
            '${l10n.walletFreezBalance}: ${formatMoney(lockedBalance)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrimaryAmount(BuildContext context, {bool onDark = false}) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final label = _hasLocked ? l10n.walletTotalBalance : l10n.walletAvailableBalance;
    final amount = _hasLocked ? _total : balance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: onDark ? Colors.white70 : Colors.white70,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          formatMoney(amount),
          style: (onDark
                  ? theme.textTheme.titleLarge
                  : theme.textTheme.headlineMedium)
              ?.copyWith(
            color: onDark ? AppBranding.gold : AppBranding.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildBonusCartelaRow(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        const Icon(Icons.redeem_rounded, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Bonus cartelas (normal games)',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ),
        Text(
          '$bonusCartelaBalance',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSubRow(
    BuildContext context, {
    required String label,
    required String amount,
    bool emphasize = false,
    bool onDark = false,
    IconData? icon,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: onDark ? Colors.white70 : Colors.white70),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: onDark ? Colors.white70 : Colors.white70,
            ),
          ),
        ),
        Text(
          formatMoney(amount),
          style: (emphasize
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.bodyMedium)
              ?.copyWith(
            color: onDark ? Colors.white : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
