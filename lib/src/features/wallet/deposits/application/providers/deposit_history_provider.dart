import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/paginated_response.dart';
import '../../data/models/deposit_model.dart';
import '../../data/repositories/deposits_repository.dart';

final depositHistoryProvider = FutureProvider<PaginatedResponse<DepositModel>>((
  ref,
) async {
  return ref.watch(depositsRepositoryProvider).getMyDeposits(pageSize: 50);
});
