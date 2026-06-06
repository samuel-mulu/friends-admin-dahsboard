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
      decoder: (rawData) => _decodeList(rawData, GameModel.fromSlotJson),
    );
  }

  Future<GameModel?> getCurrentLiveGame() {
    return _apiClient.get<GameModel?>(
      '/games/current/live',
      decoder: (rawData) {
        if (rawData == null) {
          return null;
        }

        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid current live game response.');
        }

        return GameModel.fromLiveJson(rawData);
      },
    );
  }

  Future<GameModel> getSlotDetail(String slotId) {
    return _apiClient.get<GameModel>(
      '/games/slots/$slotId',
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid slot detail response.');
        }
        return GameModel.fromSlotJson(rawData);
      },
    );
  }

  Future<GameModel> getSessionDetail(String sessionId) {
    return _apiClient.get<GameModel>(
      '/games/sessions/$sessionId',
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid session detail response.');
        }
        return GameModel.fromSessionJson(rawData);
      },
    );
  }

  Future<List<CartelaModel>> getCartelas() {
    return _apiClient.get<List<CartelaModel>>(
      '/cartelas',
      decoder: (rawData) => _decodeList(rawData, CartelaModel.fromJson),
    );
  }

  // Register a cartela on an active session (status must be PLAYING).
  Future<GameCartelaModel> registerCartela({
    required String sessionId,
    required String cartelaId,
  }) {
    return _apiClient.post<GameCartelaModel>(
      '/games/sessions/$sessionId/register-cartela',
      data: {'cartelaId': cartelaId},
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid cartela registration response.');
        }

        return GameCartelaModel.fromJson(rawData);
      },
    );
  }

  // Register a cartela for a slot (works for both NEXT and PLAYING slots).
  // For NEXT slots, the backend auto-creates a session if needed.
  Future<GameCartelaModel> registerCartelaForSlot({
    required String slotId,
    required String cartelaId,
  }) {
    return _apiClient.post<GameCartelaModel>(
      '/games/slots/$slotId/register-cartela',
      data: {'cartelaId': cartelaId},
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid cartela registration response.');
        }

        return GameCartelaModel.fromJson(rawData);
      },
    );
  }

  Future<List<GameCartelaModel>> getMyGameCartelas(String sessionId) {
    return _apiClient.get<List<GameCartelaModel>>(
      '/games/sessions/$sessionId/my-cartelas',
      decoder: (rawData) => _decodeList(rawData, GameCartelaModel.fromJson),
    );
  }

  Future<CalledNumbersSnapshot> getCalledNumbers(String sessionId) {
    return _apiClient.get<CalledNumbersSnapshot>(
      '/games/sessions/$sessionId/called-numbers',
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid called numbers response.');
        }

        return CalledNumbersSnapshot.fromJson(rawData);
      },
    );
  }

  Future<BingoClaimResult> claimBingo({
    required String sessionId,
    required String gameCartelaId,
  }) {
    return _apiClient.post<BingoClaimResult>(
      '/games/sessions/$sessionId/bingo',
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
