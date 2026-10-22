import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/api_client.dart';
import '../models/wallet_model.dart';

class WalletOverviewRepository {
  WalletOverviewRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<WalletModel> getMyWallet() {
    return _apiClient.get<WalletModel>(
      '/wallet/me',
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid wallet response.');
        }

        return WalletModel.fromJson(rawData);
      },
    );
  }
}

final walletOverviewRepositoryProvider =
    Provider<WalletOverviewRepository>((ref) {
  return WalletOverviewRepository(ref.watch(apiClientProvider));
});
