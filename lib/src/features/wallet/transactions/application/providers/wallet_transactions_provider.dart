import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/paginated_response.dart';
import '../../data/models/wallet_transaction_model.dart';
import '../../data/repositories/wallet_transactions_repository.dart';

final walletTransactionsProvider =
    FutureProvider<PaginatedResponse<WalletTransactionModel>>((ref) async {
  return ref
      .watch(walletTransactionsRepositoryProvider)
      .getMyTransactions(pageSize: 50);
});
