import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../models/admin_broadcast_model.dart';

class BroadcastsRepository {
  BroadcastsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PlayerBroadcastsResponse> getMyBroadcasts() {
    return _apiClient.get<PlayerBroadcastsResponse>(
      '/notifications/broadcasts',
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid broadcasts response.');
        }

        return PlayerBroadcastsResponse.fromJson(rawData);
      },
    );
  }

  Future<void> dismissBroadcast(String id) {
    return _apiClient.delete<Object?>(
      '/notifications/broadcasts/$id',
      decoder: (rawData) => rawData,
    );
  }
}

final broadcastsRepositoryProvider = Provider<BroadcastsRepository>((ref) {
  return BroadcastsRepository(ref.watch(apiClientProvider));
});
