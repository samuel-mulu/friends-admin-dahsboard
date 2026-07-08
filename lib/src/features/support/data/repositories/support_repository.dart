import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated_response.dart';
import '../../../../core/network/pagination_meta.dart';
import '../models/support_message_model.dart';

class SupportRepository {
  SupportRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<SupportMessageModel> submitMessage({
    required SupportCategory category,
    required String message,
  }) {
    return _apiClient.post<SupportMessageModel>(
      '/support/messages',
      data: {
        'category': category.apiValue,
        'message': message,
      },
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid support message response.');
        }

        return SupportMessageModel.fromJson(rawData);
      },
    );
  }

  Future<PaginatedResponse<SupportMessageModel>> getMyMessages({
    int page = 1,
    int pageSize = 20,
  }) async {
    final envelope = await _apiClient.getEnvelope<List<SupportMessageModel>>(
      '/support/messages/me',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
      decoder: (rawData) => _decodeList(rawData, SupportMessageModel.fromJson),
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
      throw StateError('Invalid support messages response.');
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

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.watch(apiClientProvider));
});
