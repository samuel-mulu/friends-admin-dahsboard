import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/paginated_response.dart';
import '../../data/models/withdrawal_model.dart';
import '../../data/repositories/withdrawals_repository.dart';

final withdrawalHistoryProvider =
    FutureProvider<PaginatedResponse<WithdrawalModel>>((ref) async {
  return ref
      .watch(withdrawalsRepositoryProvider)
      .getMyWithdrawals(pageSize: 50);
});
