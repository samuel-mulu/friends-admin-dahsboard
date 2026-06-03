import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'models/bingo_claim_result.dart';
import 'models/cartela_model.dart';
import 'models/called_numbers_snapshot.dart';
import 'models/game_cartela_model.dart';
import 'models/game_model.dart';

class GamesRepository {
  GamesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<GameModel>> getGames() {
    return _apiClient.get<List<GameModel>>(
      '/games',
      decoder: (rawData) => _decodeList(rawData, GameModel.fromJson),
    );
  }

  Future<GameModel> getGameDetail(String gameId) {
    return _apiClient.get<GameModel>(
      '/games/$gameId',
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid game detail response.');
        }

        return GameModel.fromJson(rawData);
      },
    );
  }

  Future<List<CartelaModel>> getCartelas() {
    return _apiClient.get<List<CartelaModel>>(
      '/cartelas',
      decoder: (rawData) => _decodeList(rawData, CartelaModel.fromJson),
    );
  }

  Future<GameCartelaModel> registerCartela({
    required String gameId,
    required String cartelaId,
  }) {
    return _apiClient.post<GameCartelaModel>(
      '/games/$gameId/register-cartela',
      data: {'cartelaId': cartelaId},
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid cartela registration response.');
        }

        return GameCartelaModel.fromJson(rawData);
      },
    );
  }

  Future<List<GameCartelaModel>> getMyGameCartelas(String gameId) {
    return _apiClient.get<List<GameCartelaModel>>(
      '/games/$gameId/my-cartelas',
      decoder: (rawData) => _decodeList(rawData, GameCartelaModel.fromJson),
    );
  }

  Future<CalledNumbersSnapshot> getCalledNumbers(String gameId) {
    return _apiClient.get<CalledNumbersSnapshot>(
      '/games/$gameId/called-numbers',
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid called numbers response.');
        }

        return CalledNumbersSnapshot.fromJson(rawData);
      },
    );
  }

  Future<BingoClaimResult> claimBingo({
    required String gameId,
    required String gameCartelaId,
  }) {
    return _apiClient.post<BingoClaimResult>(
      '/games/$gameId/bingo',
      data: {'gameCartelaId': gameCartelaId},
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid bingo claim response.');
        }

        return BingoClaimResult.fromJson(rawData);
      },
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
}

final gamesRepositoryProvider = Provider<GamesRepository>((ref) {
  return GamesRepository(ref.watch(apiClientProvider));
});
