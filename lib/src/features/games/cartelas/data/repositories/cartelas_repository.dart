import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:friends_bingo_app/src/core/network/api_client.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_catalog_page.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';

final cartelasRepositoryProvider = Provider<CartelasRepository>((ref) {
  return CartelasRepository(ref.watch(apiClientProvider));
});

class CartelasRepository {
  CartelasRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<CartelaModel>> getCartelas() {
    return _apiClient.get<List<CartelaModel>>(
      '/cartelas',
      decoder: (rawData) => _decodeList(rawData, CartelaModel.fromJson),
    );
  }

  Future<CartelaCatalogPage> getCartelasPage({
    int limit = 100,
    String? cursor,
    String? search,
    bool shuffle = false,
  }) {
    return _apiClient.get<CartelaCatalogPage>(
      '/cartelas',
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (search != null && search.isNotEmpty) 'search': search,
        if (shuffle) 'shuffle': true,
      },
      decoder: (rawData) {
        if (rawData is Map<String, dynamic>) {
          return CartelaCatalogPage.fromJson(rawData);
        }

        throw StateError('Invalid cartela catalog page response.');
      },
    );
  }

  Future<CartelaModel> getCartelaBoard({
    required String cartelaId,
    required String sessionId,
  }) {
    return _apiClient.get<CartelaModel>(
      '/cartelas/$cartelaId/board',
      queryParameters: {'sessionId': sessionId},
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid cartela board response.');
        }
        return CartelaModel.fromJson(rawData);
      },
    );
  }

  List<T> _decodeList<T>(
    dynamic rawData,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (rawData is! List) {
      throw StateError('Expected list response');
    }

    return rawData
        .cast<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }
}
