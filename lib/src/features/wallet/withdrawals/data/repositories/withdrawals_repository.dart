import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/paginated_response.dart';
import '../../../../../core/network/pagination_meta.dart';
import '../../../shared/domain/entities/payment_provider.dart';
import '../models/withdrawal_model.dart';

class WithdrawalsRepository {
  WithdrawalsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<WithdrawalModel> createWithdrawal({
    required PaymentProvider provider,
    required String amount,
    required String password,
    String? receiverPhone,
    String? receiverAccount,
  }) {
    return _apiClient.post<WithdrawalModel>(
      '/withdrawals',
      data: {
        'provider': provider.apiValue,
        'amount': amount,
        'password': password,
        if (receiverPhone != null && receiverPhone.isNotEmpty)
          'receiverPhone': receiverPhone,
        if (receiverAccount != null && receiverAccount.isNotEmpty)
          'receiverAccount': receiverAccount,
      },
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid withdrawal response.');
        }

        return WithdrawalModel.fromJson(rawData);
      },
    );
  }

  Future<PaginatedResponse<WithdrawalModel>> getMyWithdrawals({
    int page = 1,
    int pageSize = 20,
  }) async {
    final envelope = await _apiClient.getEnvelope<List<WithdrawalModel>>(
      '/withdrawals/me',
      queryParameters: {'page': page, 'pageSize': pageSize},
      decoder: (rawData) => _decodeList(rawData, WithdrawalModel.fromJson),
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

final withdrawalsRepositoryProvider = Provider<WithdrawalsRepository>((ref) {
  return WithdrawalsRepository(ref.watch(apiClientProvider));
});
