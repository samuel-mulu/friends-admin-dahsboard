import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/wallet_history_providers.dart';
import '../widgets/wallet_state_card.dart';

class WalletTransactionsScreen extends ConsumerWidget {
  const WalletTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(walletTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet transactions')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletTransactionsProvider);
          await ref.read(walletTransactionsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            transactionsAsync.when(
              data: (result) {
                if (result.items.isEmpty) {
                  return const WalletStateCard(
                    title: 'No transactions yet',
                    message:
                        'Your wallet ledger will show up here after deposits, entries, and withdrawals.',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Showing ${result.items.length} of ${result.pagination.totalItems} transactions',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ...result.items.map(
                      (transaction) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: ListTile(
                            title: Text(transaction.type.label),
                            subtitle: Text(
                              '${formatDateTime(transaction.createdAt)}\n${transaction.description ?? 'Wallet activity'}',
                            ),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatMoney(transaction.amount)),
                                const SizedBox(height: 4),
                                Text(
                                  'Bal: ${formatMoney(transaction.balanceAfter)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => WalletStateCard(
                message: error is ApiException
                    ? error.message
                    : 'Could not load transaction history.',
                action: FilledButton.tonal(
                  onPressed: () => ref.invalidate(walletTransactionsProvider),
                  child: const Text('Try again'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
