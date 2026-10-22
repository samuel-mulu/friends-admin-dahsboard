import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/claims/domain/bingo_claim_source.dart';
import 'package:friends_bingo_app/src/features/games/registration/data/models/bulk_reserve_cartelas_result.dart';
import 'package:friends_bingo_app/src/features/games/registration/data/models/cartela_reservation_model.dart';
import 'package:friends_bingo_app/src/features/games/registration/data/models/registration_state_model.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/bulk_register_result.dart';
import 'package:friends_bingo_app/src/features/games/claims/data/models/bingo_claim_result.dart';
import 'models/called_numbers_snapshot.dart';
import 'models/chain_round_plan_model.dart';
import 'models/game_model.dart';
import 'models/game_timing_config_model.dart';
import 'models/round_winner_history_model.dart';
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

  /// CHAIN_GAME only — the fixed pattern/prize ladder for a chain session.
  Future<ChainRoundPlan> getChainRoundPlan(String sessionId) {
    return _apiClient.get<ChainRoundPlan>(
      '/games/sessions/$sessionId/chain-rounds',
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid chain round plan response.');
        }
        return ChainRoundPlan.fromJson(rawData);
      },
    );
  }

  // Register a cartela on an active session (status must be PLAYING).
  Future<GameCartelaModel> registerCartela({
    required String sessionId,
    required String cartelaId,
    String? paymentSource,
  }) async {
    try {
      return await _apiClient.post<GameCartelaModel>(
        '/games/sessions/$sessionId/register-cartela',
        data: {
          'cartelaId': cartelaId,
          'paymentSource': ?paymentSource,
        },
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
    String? paymentSource,
  }) async {
    try {
      return await _apiClient.post<GameCartelaModel>(
        '/games/slots/$slotId/register-cartela',
        data: {
          'cartelaId': cartelaId,
          'paymentSource': ?paymentSource,
        },
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
    String? paymentSource,
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
          'paymentSource': ?paymentSource,
        },
        receiveTimeout: _bulkOperationTimeout,
        decoder: (rawData) => _decodeBulkRegisterResult(rawData),
      );

      onProgress?.call(total, total);

      return await _reconcileBulkRegistration(
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

    final myCartelaItems = rawData['myCartelas'];
    List<GameCartelaModel>? myCartelas;
    if (myCartelaItems is List) {
      myCartelas = <GameCartelaModel>[];
      for (final item in myCartelaItems.whereType<Map<String, dynamic>>()) {
        try {
          myCartelas.add(GameCartelaModel.fromJson(item));
        } catch (_) {}
      }
    }

    return BulkRegisterResult(
      successes: successes,
      failures: failures,
      myCartelas: myCartelas,
    );
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
        myCartelas: result.myCartelas ?? myCartelas,
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

  /// Deliberately short POST wait budget (6s) — much shorter than the Nest
  /// worst case (accept txn `{maxWait:10s,timeout:10s}` + validate txn
  /// `{maxWait:20s,timeout:20s}` sequential ≈30s in the same HTTP request).
  /// A 6s `receiveTimeout` is therefore expected to fire routinely on a
  /// claim the backend is still processing, not just on a genuinely broken
  /// connection. This is safe ONLY because every caller treats it as
  /// ambiguous, never as INVALID/BLOCKED: [LiveCalledNumbersController]
  /// always falls through to the recovery GET (same claimAttemptId), waits
  /// through CHECKING, applies VALID/INVALID the moment the GET reports it,
  /// and on 404 uses the bounded same-UUID POST retry — never inventing a
  /// terminal result from the timeout itself. Does not delay fast successful
  /// responses — only when one is missing/slow. GET uses the global 15s Dio
  /// default (no $transaction) so recovery starts/fails promptly instead of
  /// blocking behind a larger budget.
  static const claimPostReceiveTimeout = Duration(seconds: 6);

  Future<BingoClaimResult> claimBingo({
    required String sessionId,
    required String gameCartelaId,
    required String claimAttemptId,
    DateTime? clientTapAt,
    BingoClaimSource claimSource = BingoClaimSource.manual,
  }) {
    return _apiClient.post<BingoClaimResult>(
      '/games/sessions/$sessionId/bingo',
      data: {
        'gameCartelaId': gameCartelaId,
        'claimAttemptId': claimAttemptId,
        if (clientTapAt != null) 'clientTapAt': clientTapAt.toUtc().toIso8601String(),
        // Omit MANUAL so older Nest builds that ignore unknown fields stay happy;
        // AUTO must be sent for A6.1 grant gating.
        if (claimSource != BingoClaimSource.manual)
          'claimSource': claimSource.apiValue,
      },
      receiveTimeout: claimPostReceiveTimeout,
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid bingo claim response.');
        }

        return BingoClaimResult.fromJson(rawData);
      },
    );
  }

  Future<BingoClaimAttemptStatus> getBingoClaimAttempt({
    required String sessionId,
    required String claimAttemptId,
  }) {
    return _apiClient.get<BingoClaimAttemptStatus>(
      '/games/sessions/$sessionId/bingo-claims/$claimAttemptId',
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid bingo claim attempt response.');
        }
        return BingoClaimAttemptStatus.fromJson(rawData);
      },
    );
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

  Future<RoundWinnerHistory> getBigGameSlotRoundWinners({
    required String slotId,
  }) {
    return _apiClient.get<RoundWinnerHistory>(
      '/games/slots/$slotId/big-game/round-winners',
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid Big Game round winners response.');
        }
        return RoundWinnerHistory.fromJson(rawData);
      },
    );
  }

  Future<RoundWinnerHistory> getChainSessionRoundWinners({
    required String sessionId,
  }) {
    return _apiClient.get<RoundWinnerHistory>(
      '/games/sessions/$sessionId/round-winners',
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw StateError('Invalid Chain round winners response.');
        }
        return RoundWinnerHistory.fromJson(rawData);
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
