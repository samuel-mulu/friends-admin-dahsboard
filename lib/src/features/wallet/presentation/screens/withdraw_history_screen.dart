import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/friends_bingo_loader.dart';
import '../providers/wallet_history_providers.dart';
import '../widgets/wallet_state_card.dart';
import '../widgets/withdrawal_requests_table.dart';

class WithdrawHistoryScreen extends ConsumerWidget {
  const WithdrawHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final withdrawalsAsync = ref.watch(withdrawalHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.withdrawHistoryTitle)),
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
                  return WalletStateCard(
                    title: l10n.withdrawHistoryEmpty,
                    message: l10n.withdrawHistoryEmptyMessage,
                  );
                }

                return WithdrawalRequestsTable(withdrawals: result.items);
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 80),
                child: FriendsBingoLoader.inline(),
              ),
              error: (error, _) => WalletStateCard(
                message: error is ApiException
                    ? error.message
                    : l10n.withdrawHistoryCouldNotLoad,
                action: FilledButton.tonal(
                  onPressed: () => ref.invalidate(withdrawalHistoryProvider),
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
