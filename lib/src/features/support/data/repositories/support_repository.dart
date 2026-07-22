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

  /// Unseen admin replies for the header feedback badge.
  Future<int> getUnreadReplyCount() {
    return _apiClient.get<int>(
      '/support/messages/me/unread-count',
      decoder: (rawData) {
        if (rawData is Map<String, dynamic>) {
          final count = rawData['count'];
          if (count is int) {
            return count;
          }
          if (count is num) {
            return count.toInt();
          }
        }
        return 0;
      },
    );
  }

  /// Clears the feedback badge after the player opens the hub.
  Future<int> markRepliesSeen() {
    return _apiClient.post<int>(
      '/support/messages/me/mark-seen',
      decoder: (rawData) {
        if (rawData is Map<String, dynamic>) {
          final updated = rawData['updated'];
          if (updated is int) {
            return updated;
          }
          if (updated is num) {
            return updated.toInt();
          }
        }
        return 0;
      },
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
