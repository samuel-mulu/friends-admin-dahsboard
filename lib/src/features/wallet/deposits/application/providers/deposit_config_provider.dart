import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/deposit_config_model.dart';
import '../../data/repositories/deposits_repository.dart';

final depositConfigProvider = FutureProvider<DepositConfigModel>((ref) {
  return ref.watch(depositsRepositoryProvider).getDepositConfig();
});
