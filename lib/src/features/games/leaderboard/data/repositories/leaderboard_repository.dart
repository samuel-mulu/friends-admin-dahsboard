import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:friends_bingo_app/src/core/network/api_client.dart';
import '../models/house_champions_model.dart';

class LeaderboardRepository {
  LeaderboardRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<HouseChampionsResponse> getCartelaWinsLeaderboard({
    required String period,
    int limit = 15,
  }) {
    return _apiClient.get<HouseChampionsResponse>(
      '/games/leaderboard/cartela-wins',
      queryParameters: {
        'period': period,
        'limit': limit,
      },
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid house champions response.');
        }

        return HouseChampionsResponse.fromJson(rawData);
      },
    );
  }
}

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(ref.watch(apiClientProvider));
});
