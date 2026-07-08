import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/wallet_transaction_model.dart';
import '../providers/wallet_history_providers.dart';
import '../widgets/wallet_state_card.dart';

class WalletTransactionsScreen extends ConsumerWidget {
  const WalletTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final transactionsAsync = ref.watch(walletTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.txHistoryTitle)),
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
                  return WalletStateCard(
                    title: l10n.txHistoryEmpty,
                    message: l10n.txHistoryEmptyMessage,
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.txHistoryShowing(result.items.length, result.pagination.totalItems),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ...result.items.map(
                      (transaction) {
                        final subtitle = _transactionSubtitle(
                          l10n,
                          transaction,
                        );

                        return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: ListTile(
                            title: Text(transaction.type.label),
                            subtitle: Text(
                              '${formatDateTime(transaction.createdAt)}\n$subtitle',
                            ),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatMoney(transaction.amount)),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.txHistoryBalanceAfter(formatMoney(transaction.balanceAfter)),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                      },
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
                    : l10n.txHistoryCouldNotLoad,
                action: FilledButton.tonal(
                  onPressed: () => ref.invalidate(walletTransactionsProvider),
                  child: Text(l10n.walletTryAgain),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _transactionSubtitle(dynamic l10n, WalletTransactionModel transaction) {
    if (transaction.type == WalletTransactionType.withdrawRequest) {
      final description = transaction.description?.trim();
      if (description != null && description.isNotEmpty) {
        return '$description\n${l10n.txWithdrawRequestLockedNote}';
      }
      return l10n.txWithdrawRequestLockedNote;
    }

    return transaction.description ?? l10n.txHistoryWalletActivity;
  }
}
