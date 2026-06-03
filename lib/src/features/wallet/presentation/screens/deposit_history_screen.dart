import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/deposit_model.dart';
import '../../data/wallet_repository.dart';
import '../providers/wallet_history_providers.dart';
import '../providers/wallet_provider.dart';
import '../widgets/wallet_state_card.dart';

class DepositHistoryScreen extends ConsumerStatefulWidget {
  const DepositHistoryScreen({super.key});

  @override
  ConsumerState<DepositHistoryScreen> createState() =>
      _DepositHistoryScreenState();
}

class _DepositHistoryScreenState extends ConsumerState<DepositHistoryScreen> {
  final Set<String> _retryingIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final depositsAsync = ref.watch(depositHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Deposit history')),
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
                  return const WalletStateCard(
                    title: 'No deposits yet',
                    message: 'Your deposit requests will appear here.',
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
                                    'Amount: ${formatMoney(deposit.amount)}',
                                  ),
                                  Text('Ref: ${deposit.transactionRef}'),
                                  Text(
                                    'Created: ${formatDateTime(deposit.createdAt)}',
                                  ),
                                  if (deposit.rejectionReason != null)
                                    Text('Reason: ${deposit.rejectionReason}'),
                                  if (deposit.status.canRetry) ...[
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: FilledButton.tonal(
                                        onPressed:
                                            _retryingIds.contains(deposit.id)
                                            ? null
                                            : () => _retryDeposit(deposit),
                                        child: _retryingIds.contains(deposit.id)
                                            ? const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Text('Retry verification'),
                                      ),
                                    ),
                                  ],
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
                    : 'Could not load deposit history.',
                action: FilledButton.tonal(
                  onPressed: () => ref.invalidate(depositHistoryProvider),
                  child: const Text('Try again'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _retryDeposit(DepositModel deposit) async {
    setState(() {
      _retryingIds.add(deposit.id);
    });

    try {
      final updated = await ref
          .read(walletRepositoryProvider)
          .retryDepositVerification(deposit.id);

      ref.invalidate(myWalletProvider);
      ref.invalidate(depositHistoryProvider);
      ref.invalidate(walletTransactionsProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification retried. Status: ${updated.status.label}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Could not retry verification.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _retryingIds.remove(deposit.id);
        });
      }
    }
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
