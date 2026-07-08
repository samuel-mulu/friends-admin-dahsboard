import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/wallet_history_providers.dart';
import '../widgets/wallet_state_card.dart';

class DepositHistoryScreen extends ConsumerWidget {
  const DepositHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final depositsAsync = ref.watch(depositHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.depositHistoryTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(depositHistoryProvider);
          await ref.read(depositHistoryProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            depositsAsync.when(
              data: (result) {
                if (result.items.isEmpty) {
                  return WalletStateCard(
                    title: l10n.depositHistoryEmpty,
                    message: l10n.depositHistoryEmptyMessage,
                  );
                }

                return Column(
                  children: result.items
                      .map(
                        (deposit) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          deposit.provider.label,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      _HistoryStatusChip(
                                        label: deposit.status.label,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n.depositAmountLabel(
                                      formatMoney(deposit.amount),
                                    ),
                                  ),
                                  Text(
                                    l10n.depositHistoryRef(
                                      deposit.transactionRef,
                                    ),
                                  ),
                                  Text(
                                    l10n.depositCreated(
                                      formatDateTime(deposit.createdAt),
                                    ),
                                  ),
                                  if (deposit.rejectionReason != null)
                                    Text(
                                      l10n.depositRejectionReason(
                                        deposit.rejectionReason!,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => WalletStateCard(
                message: error is ApiException
                    ? error.message
                    : l10n.depositHistoryCouldNotLoad,
                action: FilledButton.tonal(
                  onPressed: () => ref.invalidate(depositHistoryProvider),
                  child: Text(l10n.walletTryAgain),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryStatusChip extends StatelessWidget {
  const _HistoryStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}
