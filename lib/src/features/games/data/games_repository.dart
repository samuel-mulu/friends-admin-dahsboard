import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated_response.dart';
import '../../../core/network/pagination_meta.dart';
import '../domain/attended_game_history_entry.dart';
import '../domain/bulk_register_result.dart';
import 'models/bingo_claim_result.dart';
import 'models/bulk_reserve_cartelas_result.dart';
import 'models/cartela_catalog_page.dart';
import 'models/cartela_model.dart';
import 'models/cartela_reservation_model.dart';
import 'models/called_numbers_snapshot.dart';
import 'models/game_cartela_model.dart';
import 'models/game_model.dart';
import 'models/game_timing_config_model.dart';
import 'models/house_champions_model.dart';
import 'models/registration_state_model.dart';
import 'models/session_winner_result_model.dart';

class GamesRepository {
  GamesRepository(this._apiClient);

  final ApiClient _apiClient;
  static const Duration _bulkOperationTimeout = Duration(seconds: 60);

  Future<GameTimingConfigModel> getTimeConfig() {
    return _apiClient.get<GameTimingConfigModel>(
      '/games/time-config',
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid time config response.');
        }

        return GameTimingConfigModel.fromJson(rawData);
      },
    );
  }

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

  Future<GameModel?> getCurrentBigGame() {
    return _apiClient.get<GameModel?>(
      '/games/big-game/current',
      decoder: (rawData) {
        if (rawData == null) {
          return null;
        }
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid big game response.');
        }
        return GameModel.fromSessionJson(rawData);
      },
    );
  }

  Future<GameOperationsCurrentResponse> getCurrentGameOperations() {
    return _apiClient.get<GameOperationsCurrentResponse>(
      '/games/operations/current',
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid game operations response.');
        }

        return GameOperationsCurrentResponse.fromJson(rawData);
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

  // Register a cartela on an active session (status must be PLAYING).
  Future<GameCartelaModel> registerCartela({
    required String sessionId,
    required String cartelaId,
  }) async {
    try {
      return await _apiClient.post<GameCartelaModel>(
        '/games/sessions/$sessionId/register-cartela',
        data: {'cartelaId': cartelaId},
        decoder: (rawData) {
          if (rawData is! Map<String, dynamic>) {
            throw StateError('Invalid cartela registration response.');
          }

          return GameCartelaModel.fromJson(rawData);
        },
      );
    } catch (error) {
      final recovered = await _recoverCommittedRegistration(
        cartelaId: cartelaId,
        sessionId: sessionId,
      );
      if (recovered != null) {
        return recovered;
      }
      rethrow;
    }
  }

  // Register a cartela for a slot (works for both NEXT and PLAYING slots).
  // For NEXT slots, the backend auto-creates a session if needed.
  Future<GameCartelaModel> registerCartelaForSlot({
    required String slotId,
    required String cartelaId,
  }) async {
    try {
      return await _apiClient.post<GameCartelaModel>(
        '/games/slots/$slotId/register-cartela',
        data: {'cartelaId': cartelaId},
        decoder: (rawData) {
          if (rawData is! Map<String, dynamic>) {
            throw StateError('Invalid cartela registration response.');
          }

          return GameCartelaModel.fromJson(rawData);
        },
      );
    } catch (error) {
      final recovered = await _recoverCommittedRegistration(
        cartelaId: cartelaId,
        slotId: slotId,
      );
      if (recovered != null) {
        return recovered;
      }
      rethrow;
    }
  }

  Future<GameCartelaModel?> _recoverCommittedRegistration({
    required String cartelaId,
    String? sessionId,
    String? slotId,
  }) async {
    try {
      final effectiveSessionId =
          sessionId ?? (slotId == null ? null : (await getSlotDetail(slotId)).sessionId);
      if (effectiveSessionId == null || effectiveSessionId.isEmpty) {
        return null;
      }

      final myCartelas = await getMyGameCartelas(effectiveSessionId);
      for (final gameCartela in myCartelas) {
        if (gameCartela.cartelaId == cartelaId) {
          return gameCartela;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<BulkRegisterResult> registerCartelasForSlot({
    required String slotId,
    required List<({String cartelaId, int cartelaNumber})> cartelas,
    String? sessionId,
    void Function(int completed, int total)? onProgress,
  }) async {
    final total = cartelas.length;
    onProgress?.call(0, total);

    try {
      final result = await _apiClient.post<BulkRegisterResult>(
        '/games/slots/$slotId/register-cartelas-bulk',
        data: {
          'cartelas': [
            for (final cartela in cartelas)
              {
                'cartelaId': cartela.cartelaId,
                'cartelaNumber': cartela.cartelaNumber,
              },
          ],
        },
        receiveTimeout: _bulkOperationTimeout,
        decoder: (rawData) => _decodeBulkRegisterResult(rawData),
      );

      onProgress?.call(total, total);

      return _reconcileBulkRegistration(
        slotId: slotId,
        providedSessionId: sessionId,
        requestedCartelas: cartelas,
        result: result,
      );
    } catch (error) {
      onProgress?.call(total, total);

      final reconciled = await _reconcileBulkRegistration(
        slotId: slotId,
        providedSessionId: sessionId,
        requestedCartelas: cartelas,
        result: const BulkRegisterResult(successes: [], failures: []),
      );
      if (reconciled.hasSuccesses) {
        return reconciled;
      }

      if (error is ApiException && error.isConnectivityFailure) {
        final recovered = await _recoverBulkRegistrationAfterConnectivityFailure(
          slotId: slotId,
          providedSessionId: sessionId,
          requestedCartelas: cartelas,
        );
        if (recovered.hasSuccesses) {
          return recovered;
        }
      }

      final message = error is ApiException
          ? (error.statusCode == 503
                ? 'Registration is busy. Please try again in a moment.'
                : error.displayMessage)
          : 'Could not register selected cartelas.';
      return BulkRegisterResult(
        successes: const [],
        failures: [
          for (final cartela in cartelas)
            BulkRegisterFailure(
              cartelaId: cartela.cartelaId,
              cartelaNumber: cartela.cartelaNumber,
              reason: message,
            ),
        ],
      );
    }
  }

  BulkRegisterResult _decodeBulkRegisterResult(Object? rawData) {
    if (rawData is! Map<String, dynamic>) {
      throw StateError('Invalid bulk cartela registration response.');
    }

    final successItems = rawData['successes'];
    final failureItems = rawData['failures'];
    if (successItems is! List || failureItems is! List) {
      throw StateError('Invalid bulk cartela registration payload.');
    }

    final successes = <GameCartelaModel>[];
    for (final item in successItems.whereType<Map<String, dynamic>>()) {
      try {
        successes.add(GameCartelaModel.fromJson(item));
      } catch (_) {}
    }

    final failures = failureItems
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => BulkRegisterFailure(
            cartelaId: item['cartelaId'] as String,
            cartelaNumber: (item['cartelaNumber'] as num).toInt(),
            reason: item['reason'] as String,
          ),
        )
        .toList(growable: false);

    return BulkRegisterResult(successes: successes, failures: failures);
  }

  Future<BulkRegisterResult> _recoverBulkRegistrationAfterConnectivityFailure({
    required String slotId,
    required String? providedSessionId,
    required List<({String cartelaId, int cartelaNumber})> requestedCartelas,
  }) async {
    try {
      final effectiveSessionId = providedSessionId ?? (await getSlotDetail(slotId)).sessionId;
      if (effectiveSessionId == null || effectiveSessionId.isEmpty) {
        return const BulkRegisterResult(successes: [], failures: []);
      }

      final myCartelas = await getMyGameCartelas(effectiveSessionId);
      final registeredByCartelaId = <String, GameCartelaModel>{
        for (final item in myCartelas) item.cartelaId: item,
      };

      final successes = <GameCartelaModel>[];
      final failures = <BulkRegisterFailure>[];
      for (final cartela in requestedCartelas) {
        final registered = registeredByCartelaId[cartela.cartelaId];
        if (registered != null) {
          successes.add(registered);
        } else {
          failures.add(
            BulkRegisterFailure(
              cartelaId: cartela.cartelaId,
              cartelaNumber: cartela.cartelaNumber,
              reason: 'UNKNOWN',
            ),
          );
        }
      }

      return BulkRegisterResult(successes: successes, failures: failures);
    } catch (_) {
      return const BulkRegisterResult(successes: [], failures: []);
    }
  }

  Future<BulkRegisterResult> _reconcileBulkRegistration({
    required String slotId,
    required String? providedSessionId,
    required List<({String cartelaId, int cartelaNumber})> requestedCartelas,
    required BulkRegisterResult result,
  }) async {
    try {
      final effectiveSessionId = providedSessionId ?? (await getSlotDetail(slotId)).sessionId;
      if (effectiveSessionId == null || effectiveSessionId.isEmpty) {
        return result;
      }

      final myCartelas = await getMyGameCartelas(effectiveSessionId);
      final registeredByCartelaId = <String, GameCartelaModel>{
        for (final item in myCartelas) item.cartelaId: item,
      };

      final successByCartelaId = <String, GameCartelaModel>{
        for (final item in result.successes) item.cartelaId: item,
      };
      final failuresByCartelaId = <String, BulkRegisterFailure>{
        for (final item in result.failures) item.cartelaId: item,
      };

      for (final cartela in requestedCartelas) {
        if (successByCartelaId.containsKey(cartela.cartelaId)) {
          failuresByCartelaId.remove(cartela.cartelaId);
          continue;
        }

        final registered = registeredByCartelaId[cartela.cartelaId];
        if (registered != null) {
          successByCartelaId[cartela.cartelaId] = registered;
          failuresByCartelaId.remove(cartela.cartelaId);
        }
      }

      return BulkRegisterResult(
        successes: successByCartelaId.values.toList(growable: false),
        failures: failuresByCartelaId.values.toList(growable: false),
      );
    } catch (_) {
      return result;
    }
  }

  Future<CartelaReservationModel> reserveCartelaForSlot({
    required String slotId,
    required String cartelaId,
    bool preserveOtherReservations = true,
  }) {
    return _apiClient.post<CartelaReservationModel>(
      '/games/slots/$slotId/cartelas/$cartelaId/reserve',
      data: preserveOtherReservations
          ? null
          : {'preserveOtherReservations': false},
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid cartela reservation response.');
        }

        return CartelaReservationModel.fromJson(rawData);
      },
    );
  }

  Future<CartelaReservationModel> reserveCartela({
    required String sessionId,
    required String cartelaId,
    bool preserveOtherReservations = true,
  }) {
    return _apiClient.post<CartelaReservationModel>(
      '/games/sessions/$sessionId/cartelas/$cartelaId/reserve',
      data: preserveOtherReservations
          ? null
          : {'preserveOtherReservations': false},
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid cartela reservation response.');
        }

        return CartelaReservationModel.fromJson(rawData);
      },
    );
  }

  Future<BulkReserveCartelasResult> reserveCartelasBulk({
    required String sessionId,
    required List<String> cartelaIds,
  }) {
    return _apiClient.post<BulkReserveCartelasResult>(
      '/games/sessions/$sessionId/reserve-cartelas-bulk',
      data: {'cartelaIds': cartelaIds},
      receiveTimeout: _bulkOperationTimeout,
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid bulk cartela reservation response.');
        }

        return BulkReserveCartelasResult.fromJson(rawData);
      },
    );
  }

  Future<BulkReserveCartelasResult> reserveCartelasBulkForSlot({
    required String slotId,
    required List<String> cartelaIds,
  }) {
    return _apiClient.post<BulkReserveCartelasResult>(
      '/games/slots/$slotId/reserve-cartelas-bulk',
      data: {'cartelaIds': cartelaIds},
      receiveTimeout: _bulkOperationTimeout,
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid bulk cartela reservation response.');
        }

        return BulkReserveCartelasResult.fromJson(rawData);
      },
    );
  }

  Future<GameCartelaModel> confirmReservation(
    String reservationId, {
    String? slotId,
    String? cartelaId,
    String? sessionId,
  }) async {
    try {
      return await _apiClient.post<GameCartelaModel>(
        '/games/reservations/$reservationId/confirm',
        decoder: (rawData) {
          if (rawData is! Map<String, dynamic>) {
            throw StateError('Invalid cartela confirmation response.');
          }

          return GameCartelaModel.fromJson(rawData);
        },
      );
    } catch (error) {
      if (cartelaId != null) {
        final recovered = await _recoverCommittedRegistration(
          cartelaId: cartelaId,
          sessionId: sessionId,
          slotId: slotId,
        );
        if (recovered != null) {
          return recovered;
        }
      }
      rethrow;
    }
  }

  Future<void> cancelReservation(String reservationId) {
    return _apiClient.post<void>(
      '/games/reservations/$reservationId/cancel',
      decoder: (_) {},
    );
  }

  Future<RegistrationStateResponse> getRegistrationState(
    String sessionId, {
    String view = 'slim',
  }) {
    return _apiClient.get<RegistrationStateResponse>(
      '/games/sessions/$sessionId/registration-state',
      queryParameters: {'view': view},
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid registration state response.');
        }

        return RegistrationStateResponse.fromJson(rawData);
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

  PaginationMeta _decodePagination(Map<String, dynamic>? meta) {
    final pagination = meta?['pagination'];
    if (pagination is Map<String, dynamic>) {
      return PaginationMeta.fromJson(pagination);
    }
    return PaginationMeta(page: 1, pageSize: 20, totalItems: 0, totalPages: 0);
  }

  Future<List<SessionWinnerResultModel>> getSessionWinnerResults({
    required String sessionId,
  }) {
    return _apiClient.get<List<SessionWinnerResultModel>>(
      '/games/sessions/$sessionId/winner-results',
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid winner results response.');
        }

        return SessionWinnerResultModel.parseList(rawData['winnerResults']);
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
