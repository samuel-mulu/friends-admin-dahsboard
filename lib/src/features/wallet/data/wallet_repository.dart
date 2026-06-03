import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/paginated_response.dart';
import '../../../core/network/pagination_meta.dart';
import '../../../core/network/api_client.dart';
import 'models/deposit_model.dart';
import 'models/payment_provider.dart';
import 'models/wallet_model.dart';
import 'models/wallet_transaction_model.dart';
import 'models/withdrawal_model.dart';

class WalletRepository {
  WalletRepository(this._apiClient);

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

  Future<DepositModel> createDeposit({
    required PaymentProvider provider,
    required String amount,
    required String transactionRef,
  }) {
    return _apiClient.post<DepositModel>(
      '/deposits',
      data: {
        'provider': provider.apiValue,
        'amount': amount,
        'transactionRef': transactionRef,
      },
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid deposit response.');
        }

        return DepositModel.fromJson(rawData);
      },
    );
  }

  Future<PaginatedResponse<DepositModel>> getMyDeposits({
    int page = 1,
    int pageSize = 20,
  }) async {
    final envelope = await _apiClient.getEnvelope<List<DepositModel>>(
      '/deposits/me',
      queryParameters: {'page': page, 'pageSize': pageSize},
      decoder: (rawData) => _decodeList(rawData, DepositModel.fromJson),
    );

    return PaginatedResponse(
      items: envelope.data,
      pagination: _decodePagination(envelope.meta),
    );
  }

  Future<DepositModel> retryDepositVerification(String depositId) {
    return _apiClient.post<DepositModel>(
      '/deposits/$depositId/retry-verification',
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid deposit retry response.');
        }

        return DepositModel.fromJson(rawData);
      },
    );
  }

  Future<WithdrawalModel> createWithdrawal({
    required PaymentProvider provider,
    required String amount,
    String? receiverPhone,
    String? receiverAccount,
  }) {
    return _apiClient.post<WithdrawalModel>(
      '/withdrawals',
      data: {
        'provider': provider.apiValue,
        'amount': amount,
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

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(apiClientProvider));
});
