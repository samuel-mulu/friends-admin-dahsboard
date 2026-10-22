import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:friends_bingo_app/src/core/network/api_client.dart';
import 'package:friends_bingo_app/src/core/network/paginated_response.dart';
import 'package:friends_bingo_app/src/core/network/pagination_meta.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/history/domain/entities/attended_game_history_entry.dart';

class GameHistoryRepository {
  GameHistoryRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedResponse<GameModel>> getGameHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    final envelope = await _apiClient.getEnvelope<List<GameModel>>(
      '/games/history',
      queryParameters: {'page': page, 'pageSize': pageSize},
      decoder: (rawData) => _decodeList(rawData, GameModel.fromSessionJson),
    );

    return PaginatedResponse(
      items: envelope.data,
      pagination: _decodePagination(envelope.meta),
    );
  }

  Future<PaginatedResponse<AttendedGameHistoryEntry>> getMyAttendedGameHistory({
    int page = 1,
    int pageSize = 50,
  }) async {
    final envelope = await _apiClient
        .getEnvelope<List<AttendedGameHistoryEntry>>(
          '/games/my-history',
          queryParameters: {'page': page, 'pageSize': pageSize},
          decoder: (rawData) =>
              _decodeList(rawData, AttendedGameHistoryEntry.fromSessionJson),
        );

    return PaginatedResponse(
      items: envelope.data,
      pagination: _decodePagination(envelope.meta),
    );
  }

  PaginationMeta _decodePagination(Map<String, dynamic>? meta) {
    final pagination = meta?['pagination'];
    if (pagination is Map<String, dynamic>) {
      return PaginationMeta.fromJson(pagination);
    }
    return PaginationMeta(page: 1, pageSize: 20, totalItems: 0, totalPages: 0);
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
}

final gameHistoryRepositoryProvider = Provider<GameHistoryRepository>((ref) {
  return GameHistoryRepository(ref.watch(apiClientProvider));
});
