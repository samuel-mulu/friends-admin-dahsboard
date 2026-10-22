import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/paginated_response.dart';
import '../../../../../core/network/pagination_meta.dart';
import '../models/wallet_transaction_model.dart';

class WalletTransactionsRepository {
  WalletTransactionsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedResponse<WalletTransactionModel>> getMyTransactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    final envelope = await _apiClient.getEnvelope<List<WalletTransactionModel>>(
      '/wallet/transactions/me',
      queryParameters: {'page': page, 'pageSize': pageSize},
      decoder: (rawData) =>
          _decodeList(rawData, WalletTransactionModel.fromJson),
    );

    return PaginatedResponse(
      items: envelope.data,
      pagination: _decodePagination(envelope.meta),
    );
  }

  List<T> _decodeList<T>(
    Object? rawData,
    T Function(Map<String, dynamic> json) decoder,
  ) {
    if (rawData is! List) {
      throw StateError('Invalid list response.');
    }

    return rawData
        .whereType<Map<String, dynamic>>()
        .map(decoder)
        .toList(growable: false);
  }

  PaginationMeta _decodePagination(Map<String, dynamic>? meta) {
    final pagination = meta?['pagination'];
    if (pagination is Map<String, dynamic>) {
      return PaginationMeta.fromJson(pagination);
    }

    return PaginationMeta(page: 1, pageSize: 20, totalItems: 0, totalPages: 1);
  }
}

final walletTransactionsRepositoryProvider =
    Provider<WalletTransactionsRepository>((ref) {
  return WalletTransactionsRepository(ref.watch(apiClientProvider));
});
