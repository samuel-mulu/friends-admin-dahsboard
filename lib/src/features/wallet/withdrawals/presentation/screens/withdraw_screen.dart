import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/realtime/wallet_entity_realtime.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/friends_bingo_loader.dart';
import '../../../../auth/presentation/controllers/auth_controller.dart';
import '../../../overview/application/providers/wallet_provider.dart';
import '../../data/models/withdrawal_model.dart';
import '../../application/controllers/withdraw_controller.dart';
import '../../application/providers/withdrawal_history_provider.dart';
import '../widgets/withdraw_balance_strip.dart';
import '../widgets/withdraw_form_section.dart';
import '../widgets/withdraw_provider_chips.dart';
import '../widgets/withdrawal_requests_table.dart';

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  String? _initializedUserId;

  @override
  Widget build(BuildContext context) {
    ref.listen<WalletEntityRealtimeState>(walletEntityRealtimeProvider, (
      previous,
      next,
    ) {
      final update = next.lastUpdate;
      if (update == null || update.kind != WalletEntityKind.withdrawal) {
        return;
      }
      ref.read(withdrawControllerProvider.notifier).handleRealtimeUpdate(update);
    });

    final l10n = context.l10n;
    final state = ref.watch(withdrawControllerProvider);
    final walletAsync = ref.watch(myWalletProvider);
    final withdrawalsAsync = ref.watch(withdrawalHistoryProvider);
    final sessionUserId = ref.watch(authControllerProvider).session?.user.id;

    if (sessionUserId != null && _initializedUserId != sessionUserId) {
      _initializedUserId = sessionUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          ref
              .read(withdrawControllerProvider.notifier)
              .loadSavedCbeAccount(sessionUserId),
        );
      });
    }

    final availableBalance = walletAsync.asData?.value.balance;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.withdrawScreenTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              walletAsync.maybeWhen(
                data: (wallet) => WithdrawBalanceStrip(
                  availableBalance: wallet.balance,
                  lockedBalance: wallet.lockedBalance,
                  totalBalance: wallet.totalBalance,
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              WithdrawProviderChips(
                value: state.provider,
                isChoosing: state.isChoosingProvider || state.provider == null,
                onChangePressed: () => ref
                    .read(withdrawControllerProvider.notifier)
                    .changeProvider(),
                onChanged: (provider) => ref
                    .read(withdrawControllerProvider.notifier)
                    .selectProvider(provider),
              ),
              if (!state.isChoosingProvider && state.provider != null) ...[
                const SizedBox(height: 16),
                WithdrawFormSection(availableBalance: availableBalance),
              ],
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                l10n.withdrawRequestsTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              withdrawalsAsync.when(
                data: (result) {
                  if (result.items.isEmpty) {
                    return Text(
                      l10n.withdrawHistoryEmptyMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    );
                  }

                  return WithdrawalRequestsTable(
                    withdrawals: result.items,
                    compact: true,
                    initialFilter: result.items.any(
                      (w) => w.status == WithdrawalStatus.pending,
                    )
                        ? WithdrawalHistoryFilter.pending
                        : WithdrawalHistoryFilter.all,
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: FriendsBingoLoader.inline(),
                ),
                error: (_, _) => Text(
                  l10n.withdrawHistoryCouldNotLoad,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
