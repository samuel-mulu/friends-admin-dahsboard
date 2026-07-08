import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/paginated_response.dart';
import '../../data/models/deposit_model.dart';
import '../../data/models/wallet_transaction_model.dart';
import '../../data/models/withdrawal_model.dart';
import '../../data/wallet_repository.dart';

final walletTransactionsProvider =
    FutureProvider<PaginatedResponse<WalletTransactionModel>>((ref) async {
      return ref
          .watch(walletRepositoryProvider)
          .getMyTransactions(pageSize: 50);
    });

final depositHistoryProvider = FutureProvider<PaginatedResponse<DepositModel>>((
  ref,
) async {
  return ref.watch(walletRepositoryProvider).getMyDeposits(pageSize: 50);
});

final withdrawalHistoryProvider =
    FutureProvider<PaginatedResponse<WithdrawalModel>>((ref) async {
      return ref.watch(walletRepositoryProvider).getMyWithdrawals(pageSize: 50);
    });
