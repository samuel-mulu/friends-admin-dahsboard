import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/friends_bingo_loader.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/network/api_exception.dart';
import '../providers/wallet_provider.dart';
import '../widgets/wallet_breakdown_card.dart';
import '../widgets/wallet_state_card.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final walletAsync = ref.watch(myWalletProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myWalletProvider);
        await ref.read(myWalletProvider.future);
      },
      child: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          walletAsync.when(
            data: (wallet) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WalletBreakdownCard.fromWallet(wallet),
                VGap.md,
                Text(
                  l10n.walletQuickDeposit,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                VGap.xl,
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppBranding.goldAccent,
                    foregroundColor: AppBranding.brandPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => context.push('/wallet/deposit'),
                  child: Text(l10n.walletDeposit),
                ),
                VGap.md,
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppBranding.brandPurple,
                    side: const BorderSide(color: AppBranding.goldAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => context.push('/wallet/withdraw'),
                  child: Text(l10n.walletWithdraw),
                ),
                VGap.xl,
                _ActionLinkCard(
                  title: l10n.walletTransactionHistory,
                  subtitle: l10n.walletTransactionHistorySubtitle,
                  icon: Icons.receipt_long_outlined,
                  onTap: () => context.push('/wallet/transactions'),
                ),
                VGap.xl,
                _ActionLinkCard(
                  title: l10n.walletDepositHistory,
                  subtitle: l10n.walletDepositHistorySubtitle,
                  icon: Icons.account_balance_outlined,
                  onTap: () => context.push('/wallet/deposits'),
                ),
                VGap.xl,
                _ActionLinkCard(
                  title: l10n.walletWithdrawalHistory,
                  subtitle: l10n.walletWithdrawalHistorySubtitle,
                  icon: Icons.call_made_outlined,
                  onTap: () => context.push('/wallet/withdrawals'),
                ),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 80),
              child: FriendsBingoLoader.inline(),
            ),
            error: (error, _) => WalletStateCard(
              message: error is ApiException
                  ? error.message
                  : l10n.walletCouldNotLoad,
              action: FilledButton.tonal(
                onPressed: () => ref.invalidate(myWalletProvider),
                child: Text(l10n.walletTryAgain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionLinkCard extends StatelessWidget {
  const _ActionLinkCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Icon(
                  icon,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
