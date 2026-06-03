import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/wallet_provider.dart';
import '../widgets/wallet_balance_card.dart';
import '../widgets/wallet_state_card.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(myWalletProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myWalletProvider);
        await ref.read(myWalletProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          walletAsync.when(
            data: (wallet) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WalletBalanceCard(
                  title: 'Available balance',
                  amount: formatMoney(wallet.balance),
                  icon: Icons.savings_outlined,
                ),
                const SizedBox(height: 12),
                WalletBalanceCard(
                  title: 'Locked balance',
                  amount: formatMoney(wallet.lockedBalance),
                  icon: Icons.lock_outline,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => context.push('/wallet/deposit'),
                        child: const Text('Deposit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push('/wallet/withdraw'),
                        child: const Text('Withdraw'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ActionLinkCard(
                  title: 'Transaction history',
                  subtitle: 'Review every wallet ledger movement.',
                  icon: Icons.receipt_long_outlined,
                  onTap: () => context.push('/wallet/transactions'),
                ),
                const SizedBox(height: 12),
                _ActionLinkCard(
                  title: 'Deposit history',
                  subtitle:
                      'Track verification progress and retry when needed.',
                  icon: Icons.account_balance_outlined,
                  onTap: () => context.push('/wallet/deposits'),
                ),
                const SizedBox(height: 12),
                _ActionLinkCard(
                  title: 'Withdrawal history',
                  subtitle: 'Follow request, approval, and payout statuses.',
                  icon: Icons.call_made_outlined,
                  onTap: () => context.push('/wallet/withdrawals'),
                ),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => WalletStateCard(
              message: error is ApiException
                  ? error.message
                  : 'Could not load wallet details.',
              action: FilledButton.tonal(
                onPressed: () => ref.invalidate(myWalletProvider),
                child: const Text('Try again'),
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
