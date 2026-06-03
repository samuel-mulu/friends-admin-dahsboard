import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/wallet_repository.dart';
import '../../data/models/wallet_model.dart';

final myWalletProvider = FutureProvider<WalletModel>((ref) async {
  final session = ref.watch(authControllerProvider).session;
  if (session == null) {
    throw StateError('You must be logged in to load wallet data.');
  }

  return ref.watch(walletRepositoryProvider).getMyWallet();
});
