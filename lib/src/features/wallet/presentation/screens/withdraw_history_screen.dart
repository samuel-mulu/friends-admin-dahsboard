import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/wallet_history_providers.dart';
import '../widgets/wallet_state_card.dart';

class WithdrawHistoryScreen extends ConsumerWidget {
  const WithdrawHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withdrawalsAsync = ref.watch(withdrawalHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Withdrawal history')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(withdrawalHistoryProvider);
          await ref.read(withdrawalHistoryProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            withdrawalsAsync.when(
              data: (result) {
                if (result.items.isEmpty) {
                  return const WalletStateCard(
                    title: 'No withdrawals yet',
                    message: 'Your withdrawal requests will appear here.',
                  );
                }

                return Column(
                  children: result.items
                      .map(
                        (withdrawal) => Padding(
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
                                          withdrawal.provider.label,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(withdrawal.status.label),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Amount: ${formatMoney(withdrawal.amount)}',
                                  ),
                                  if (withdrawal.receiverPhone != null)
                                    Text('Phone: ${withdrawal.receiverPhone}'),
                                  if (withdrawal.receiverAccount != null)
                                    Text(
                                      'Account: ${withdrawal.receiverAccount}',
                                    ),
                                  Text(
                                    'Created: ${formatDateTime(withdrawal.createdAt)}',
                                  ),
                                  if (withdrawal.adminNote != null)
                                    Text('Note: ${withdrawal.adminNote}'),
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
                    : 'Could not load withdrawal history.',
                action: FilledButton.tonal(
                  onPressed: () => ref.invalidate(withdrawalHistoryProvider),
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
