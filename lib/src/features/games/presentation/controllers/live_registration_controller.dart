import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../data/models/bulk_reserve_cartelas_result.dart';
import '../../data/models/game_cartela_model.dart';
import '../../data/models/game_model.dart';
import '../../domain/cartela_availability.dart';
import '../../domain/cartela_board_preview_cache.dart';
import '../../domain/registration_state_patch.dart';
import '../providers/games_providers.dart';
import '../providers/registration_state_patch_provider.dart';
import '../utils/cartela_display_order.dart';
import '../providers/current_game_operations_provider.dart';
import '../utils/current_cartela_snapshot_guard.dart';
import '../utils/merge_registered_cartelas.dart';
import '../utils/registration_error_helpers.dart';
import '../utils/registration_ux_metrics.dart';
import 'live_game_host.dart';
import 'registration_action_result.dart';
import 'registration_panel_session.dart';

void _bulkDebugLog(String message) {
  if (kDebugMode) {
    debugPrint('[bulk_debug] $message');
  }
}

/// Registration cartelas, tracked sessions, panel selection, and silent refresh.
class LiveRegistrationController {
  LiveRegistrationController(this.host);

  final LiveGameHost host;

  List<GameCartelaModel> myCartelas = const [];
  List<String> myCartelaDisplayOrderIds = const [];
  List<GameCartelaModel> nextRegistrationCartelas = const [];
  List<int>? pendingAutoOpenCartelaNumbers;
  Timer? myCartelasRefreshDebounceTimer;
  Timer? nextCartelasRefreshDebounceTimer;
  final CurrentCartelaSnapshotGuard currentCartelaSnapshotGuard =
      CurrentCartelaSnapshotGuard();
  final CurrentCartelaSnapshotGuard nextRegistrationCartelaSnapshotGuard =
      CurrentCartelaSnapshotGuard();
  final Map<String, RegistrationPanelSession> _panelSessions =
      <String, RegistrationPanelSession>{};

  void dispose() {
    myCartelasRefreshDebounceTimer?.cancel();
    nextCartelasRefreshDebounceTimer?.cancel();
    for (final session in _panelSessions.values) {
      session.dispose();
    }
    _panelSessions.clear();
  }

  bool get hasVisibleCurrentSessionCartelas => myCartelas.isNotEmpty;

  List<GameCartelaModel> get orderedMyCartelas => applyCartelaDisplayOrder(
    cartelas: myCartelas,
    orderIds: myCartelaDisplayOrderIds,
  );

  void clearMyCartelaDisplayOrder() {
    myCartelaDisplayOrderIds = const [];
  }

  void reorderMyCartela(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) {
      return;
    }

    final ordered = orderedMyCartelas;
    if (fromIndex < 0 ||
        toIndex < 0 ||
        fromIndex >= ordered.length ||
        toIndex >= ordered.length) {
      return;
    }

    host.markNeedsBuild(() {
      myCartelaDisplayOrderIds = reorderCartelaDisplayOrderIds(
        cartelas: ordered,
        fromIndex: fromIndex,
        toIndex: toIndex,
      );
    });
  }

  void clearPendingAutoOpenCartelaNumbers() {
    if (pendingAutoOpenCartelaNumbers == null) {
      return;
    }
    host.markNeedsBuild(() {
      pendingAutoOpenCartelaNumbers = null;
    });
  }

  void setPendingAutoOpenFromMyCartelas() {
    if (myCartelas.isEmpty) {
      return;
    }
    host.markNeedsBuild(() {
      pendingAutoOpenCartelaNumbers =
          myCartelas
              .map((cartela) => cartela.cartela.number)
              .toList(growable: false)
            ..sort();
    });
  }

  RegistrationPanelSession panelSessionFor(String slotId) {
    return _panelSessions.putIfAbsent(slotId, RegistrationPanelSession.new);
  }

  void resetPanelSession(String slotId) {
    _panelSessions.remove(slotId)?.dispose();
  }

  void resetCurrentCartelaSession(String? sessionId) {
    currentCartelaSnapshotGuard.reset(sessionId);
  }

  CurrentCartelaSnapshotToken captureCurrentSessionFetchToken(String sessionId) {
    return currentCartelaSnapshotGuard.captureForFetch(sessionId);
  }

  CurrentCartelaSnapshotToken captureCurrentSessionSnapshotToken(
    String sessionId,
  ) {
    return currentCartelaSnapshotGuard.capture(sessionId);
  }

  bool canApplyCurrentSessionRemoteSnapshot(
    CurrentCartelaSnapshotToken token,
    String responseSessionId,
  ) {
    return currentCartelaSnapshotGuard.canApplyRemote(
      token,
      responseSessionId: responseSessionId,
    );
  }

  bool canApplyCurrentSessionSnapshot(
    CurrentCartelaSnapshotToken token,
    String responseSessionId,
  ) {
    return currentCartelaSnapshotGuard.canApply(
      token,
      responseSessionId: responseSessionId,
    );
  }

  List<GameCartelaModel> sortedMyCartelas(List<GameCartelaModel> cartelas) {
    return List<GameCartelaModel>.from(cartelas)
      ..sort((left, right) {
        return left.cartela.number.compareTo(right.cartela.number);
      });
  }

  bool tryApplyMyCartelasRemoteSnapshot({
    required CurrentCartelaSnapshotToken token,
    required String responseSessionId,
    required List<GameCartelaModel> cartelas,
  }) {
    if (!canApplyCurrentSessionRemoteSnapshot(token, responseSessionId)) {
      return false;
    }

    host.markNeedsBuild(() {
      myCartelas = sortedMyCartelas(cartelas);
    });
    currentCartelaSnapshotGuard.markRemoteApplied(token);
    return true;
  }

  void applyMyCartelasOptimisticMerge({
    required String sessionId,
    required List<GameCartelaModel> incoming,
  }) {
    if (incoming.isEmpty) {
      return;
    }

    host.markNeedsBuild(() {
      myCartelas = sortedMyCartelas(
        mergeRegisteredCartelas(
          current: myCartelas,
          incoming: incoming,
          sessionId: sessionId,
        ),
      );
    });
  }

  void clearMyCartelasForSessionTransition() {
    host.markNeedsBuild(() {
      myCartelas = const [];
      clearMyCartelaDisplayOrder();
    });
  }

  void noteConfirmedCurrentSessionRegistrationMutation(String sessionId) {
    if (host.game?.sessionId != sessionId) {
      return;
    }
    if (currentCartelaSnapshotGuard.currentSessionId != sessionId) {
      currentCartelaSnapshotGuard.reset(sessionId);
    }
    currentCartelaSnapshotGuard.bumpForConfirmedRegistration(sessionId);
  }

  void resetNextRegistrationCartelaSession(String? sessionId) {
    nextRegistrationCartelaSnapshotGuard.reset(sessionId);
  }

  CurrentCartelaSnapshotToken captureNextRegistrationSnapshotToken(
    String sessionId,
  ) {
    return nextRegistrationCartelaSnapshotGuard.capture(sessionId);
  }

  bool canApplyNextRegistrationSnapshot(
    CurrentCartelaSnapshotToken token,
    String responseSessionId,
  ) {
    return nextRegistrationCartelaSnapshotGuard.canApply(
      token,
      responseSessionId: responseSessionId,
    );
  }

  bool shouldApplyNextRegistrationCartelasSnapshot({
    required CurrentCartelaSnapshotToken? snapshotToken,
    required String responseSessionId,
  }) {
    if (snapshotToken == null) {
      return true;
    }
    return canApplyNextRegistrationSnapshot(snapshotToken, responseSessionId);
  }

  void noteConfirmedNextRegistrationSessionRegistrationMutation(
    String sessionId,
  ) {
    if (trackedRegistrationSessionId != sessionId) {
      return;
    }
    if (nextRegistrationCartelaSnapshotGuard.currentSessionId != sessionId) {
      nextRegistrationCartelaSnapshotGuard.reset(sessionId);
    }
    nextRegistrationCartelaSnapshotGuard.bumpForConfirmedRegistration(
      sessionId,
    );
  }

  List<GameCartelaModel> sortedNextRegistrationCartelas(
    List<GameCartelaModel> cartelas,
  ) {
    return List<GameCartelaModel>.from(cartelas)
      ..sort((left, right) {
        return left.cartela.number.compareTo(right.cartela.number);
      });
  }

  String? effectiveSessionIdFor(
    String slotId, {
    String? widgetSessionId,
    List<GameCartelaModel> registeredCartelas = const [],
  }) {
    final session = panelSessionFor(slotId);
    if (session.resolvedSessionId != null &&
        session.resolvedSessionId!.isNotEmpty) {
      return session.resolvedSessionId;
    }
    if (widgetSessionId != null && widgetSessionId.isNotEmpty) {
      return widgetSessionId;
    }
    if (registeredCartelas.isNotEmpty) {
      return registeredCartelas.first.gameId;
    }
    if (session.trackedRegisteredCartelas.isNotEmpty) {
      return session.trackedRegisteredCartelas.first.gameId;
    }
    return null;
  }

  String? get trackedRegistrationSessionId {
    final target = host.liveUiMode.registrationTarget;
    if (target == null ||
        target.status != GameStatus.ready ||
        !target.canRegister ||
        registrationTargetIsCurrentGame(target)) {
      return null;
    }

    final sessionId = target.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return null;
    }

    return sessionId;
  }

  bool registrationTargetIsCurrentGame(GameModel? target) {
    final game = host.game;
    if (game == null || target == null) {
      return false;
    }
    if (game.id == target.id) {
      return true;
    }
    final gameSession = game.sessionId;
    final targetSession = target.sessionId;
    return gameSession != null &&
        targetSession != null &&
        gameSession == targetSession;
  }

  void prefetchTrackedRegistrationState() {
    final sessionId = trackedRegistrationSessionId;
    if (host.isGuest || sessionId == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!host.mounted) {
        return;
      }
      host.ref.invalidate(registrationStateProvider(sessionId));
    });
  }

  RegistrationActionResult enterSelectMode({
    required String slotId,
    required bool isGuest,
    required int? maxAffordable,
    required RegistrationLimitKind limitKind,
  }) {
    if (isGuest) {
      return const RegistrationGuestRequired();
    }

    if (maxAffordable != null && maxAffordable < 1) {
      return RegistrationInsufficientBalance(
        maxAffordable: maxAffordable,
        limitKind: limitKind,
      );
    }

    panelSessionFor(slotId).selectModeEnabled = true;
    host.markNeedsBuild();
    return const RegistrationActionSuccess();
  }

  RegistrationActionResult toggleCartelaSelection({
    required String slotId,
    required RegistrationCartelaSelectionInput cartela,
    required int? maxAffordable,
    required RegistrationLimitKind limitKind,
  }) {
    final session = panelSessionFor(slotId);

    if (session.registeringCartelaIds.isNotEmpty) {
      return const RegistrationActionIgnored();
    }

    if (session.togglingCartelaIds.contains(cartela.cartelaId)) {
      return const RegistrationActionIgnored();
    }

    final selectedBefore = session.selectedCartelaIds.contains(
      cartela.cartelaId,
    );
    _bulkDebugLog(
      'tap cartela=${cartela.cartelaNumber} selectedBefore=$selectedBefore selectMode=${session.selectModeEnabled}',
    );

    session.togglingCartelaIds.add(cartela.cartelaId);
    try {
      return _toggleCartelaSelectionInternal(
        session: session,
        cartela: cartela,
        maxAffordable: maxAffordable,
        limitKind: limitKind,
      );
    } finally {
      session.togglingCartelaIds.remove(cartela.cartelaId);
    }
  }

  RegistrationActionResult _toggleCartelaSelectionInternal({
    required RegistrationPanelSession session,
    required RegistrationCartelaSelectionInput cartela,
    required int? maxAffordable,
    required RegistrationLimitKind limitKind,
  }) {
    if (session.registeringCartelaIds.isNotEmpty) {
      return const RegistrationActionIgnored();
    }

    final isRemoving = session.selectedCartelaIds.contains(cartela.cartelaId);

    if (!isRemoving && cartela.availability != CartelaAvailability.available) {
      return const RegistrationCartelaUnavailable();
    }

    if (!isRemoving && !_canAddMoreSelections(session, maxAffordable)) {
      return RegistrationInsufficientBalance(
        maxAffordable: maxAffordable,
        limitKind: limitKind,
      );
    }

    if (isRemoving) {
      session.selectedCartelaIds.remove(cartela.cartelaId);
      session.selectedCartelaNumbers.remove(cartela.cartelaId);
      _bulkDebugLog(
        'deselect cartela=${cartela.cartelaNumber} selected_set=[${session.selectedCartelaIds.map((id) => session.selectedCartelaNumbers[id]).join(',')}]',
      );
      host.markNeedsBuild();
      return const RegistrationActionSuccess();
    }

    session.selectedCartelaIds.add(cartela.cartelaId);
    session.selectedCartelaNumbers[cartela.cartelaId] = cartela.cartelaNumber;
    _bulkDebugLog(
      'selected_set after_add=[${session.selectedCartelaIds.map((id) => session.selectedCartelaNumbers[id]).join(',')}]',
    );
    host.markNeedsBuild();
    return const RegistrationActionSuccess();
  }

  bool _canAddMoreSelections(
    RegistrationPanelSession session,
    int? maxAffordable,
  ) {
    if (maxAffordable == null) {
      return true;
    }
    return session.selectionCount < maxAffordable;
  }

  void exitSelectMode(String slotId) {
    final session = panelSessionFor(slotId);
    _bulkDebugLog(
      'exit_select_mode selectedBefore=[${session.selectedCartelaIds.map((id) => session.selectedCartelaNumbers[id]).join(',')}]',
    );
    session.exitSelectMode();
    host.markNeedsBuild();
  }

  void cancelSelection(String slotId) {
    final session = panelSessionFor(slotId);
    _bulkDebugLog(
      'clear_selection selectedBefore=[${session.selectedCartelaIds.map((id) => session.selectedCartelaNumbers[id]).join(',')}]',
    );
    session.clearSelection();
    host.markNeedsBuild();
  }

  void scheduleBulkReserve(String slotId) {
    final session = panelSessionFor(slotId);
    session.bulkReserveDebounceTimer?.cancel();
    session.bulkReserveDebounceTimer = Timer(
      const Duration(milliseconds: 150),
      () {
        unawaited(
          flushBulkReserve(
            slotId: slotId,
            widgetSessionId: null,
            forceAllSelected: false,
          ),
        );
      },
    );
  }

  Future<RegistrationActionResult> reserveSelected({
    required String slotId,
    required String? widgetSessionId,
  }) {
    return flushBulkReserve(
      slotId: slotId,
      widgetSessionId: widgetSessionId,
      forceAllSelected: true,
    );
  }

  Future<RegistrationActionResult> flushBulkReserve({
    required String slotId,
    required String? widgetSessionId,
    bool forceAllSelected = false,
  }) async {
    final session = panelSessionFor(slotId);
    if (!host.mounted || !session.selectModeEnabled) {
      return const RegistrationActionIgnored();
    }

    final cartelaIds = forceAllSelected
        ? session.selectedCartelaIds
              .where((id) => !session.selectionReservations.containsKey(id))
              .toList(growable: false)
        : session.pendingBulkReserveIds.toList(growable: false);

    if (cartelaIds.isEmpty) {
      return const RegistrationActionIgnored();
    }

    if (session.bulkReserveInFlight) {
      if (!forceAllSelected) {
        return const RegistrationActionIgnored();
      }

      while (session.bulkReserveInFlight && host.mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      if (!host.mounted) {
        return const RegistrationActionIgnored();
      }
    }

    if (!forceAllSelected) {
      session.pendingBulkReserveIds.removeAll(cartelaIds);
    }

    session.bulkReserveInFlight = true;
    final reserveGeneration = session.bulkReserveGeneration;

    _bulkDebugLog(
      'flush_start generation=$reserveGeneration selected=[${session.selectedCartelaIds.map((id) => session.selectedCartelaNumbers[id]).join(',')}] pending=[${cartelaIds.map((id) => session.selectedCartelaNumbers[id] ?? id).join(',')}]',
    );

    try {
      final actorUserId = host.ref
          .read(authControllerProvider)
          .session
          ?.user
          .id;
      final result = widgetSessionId != null
          ? await host.gamesRepository.reserveCartelasBulk(
              sessionId: widgetSessionId,
              cartelaIds: cartelaIds,
            )
          : await host.gamesRepository.reserveCartelasBulkForSlot(
              slotId: slotId,
              cartelaIds: cartelaIds,
            );

      _bulkDebugLog(
        'flush_response generation=$reserveGeneration currentGen=${session.bulkReserveGeneration} reservations=[${result.reservations.map((r) => session.selectedCartelaNumbers[r.cartelaId] ?? r.cartelaId).join(',')}] selectMode=${session.selectModeEnabled}',
      );

      final staleGeneration =
          reserveGeneration != session.bulkReserveGeneration;
      final selectModeEnded = !host.mounted || !session.selectModeEnabled;
      if (staleGeneration || selectModeEnded) {
        _bulkDebugLog(
          'flush_cancelled staleGen=$staleGeneration selectModeEnded=$selectModeEnded',
        );
        await _cancelStaleReservationIds(
          result.reservations.map((reservation) => reservation.id),
        );
        return const RegistrationReserveFlushCancelled();
      }

      final changes = <RegistrationCartelaChange>[];
      host.markNeedsBuild(() {
        session.resolvedSessionId = result.sessionId;
        for (final reservation in result.reservations) {
          final cartelaNumber =
              session.selectedCartelaNumbers[reservation.cartelaId];
          if (cartelaNumber == null) {
            _bulkDebugLog(
              'skip_reservation cartelaId=${reservation.cartelaId} reservationId=${reservation.id} reason=no_cartela_number',
            );
            continue;
          }

          if (!session.selectedCartelaIds.contains(reservation.cartelaId)) {
            _bulkDebugLog(
              'skip_reservation cartela=$cartelaNumber reservationId=${reservation.id} reason=deselected',
            );
            continue;
          }

          _bulkDebugLog(
            'apply_reservation cartela=$cartelaNumber reservationId=${reservation.id} selectedStill=true',
          );

          session.selectionReservations[reservation.cartelaId] =
              SelectionReservationHold(
                reservationId: reservation.id,
                sessionId: result.sessionId,
                cartelaId: reservation.cartelaId,
                cartelaNumber: cartelaNumber,
                expiresAt: reservation.expiresAt,
              );
          changes.add(
            RegistrationCartelaChange(
              cartelaId: reservation.cartelaId,
              cartelaNumber: cartelaNumber,
              owner: 'RESERVED_ME',
              actorUserId: actorUserId,
              expiresAt: reservation.expiresAt,
            ),
          );
        }
      });

      if (changes.isNotEmpty) {
        host.ref
            .read(registrationStatePatchProvider.notifier)
            .applyChanges(result.sessionId, changes);
      }

      final appliedReservationIds = changes
          .map(
            (change) => result.reservations
                .firstWhere((r) => r.cartelaId == change.cartelaId)
                .id,
          )
          .toSet();
      final skippedReservations = result.reservations
          .where((r) => !appliedReservationIds.contains(r.id))
          .toList();
      if (skippedReservations.isNotEmpty) {
        for (final r in skippedReservations) {
          _bulkDebugLog(
            'cancel_server_reservation cartela=${session.selectedCartelaNumbers[r.cartelaId] ?? r.cartelaId} reservationId=${r.id} reason=skipped',
          );
        }
        unawaited(
          _cancelStaleReservationIds(skippedReservations.map((r) => r.id)),
        );
      }

      final reservedIds = result.reservations
          .map((reservation) => reservation.cartelaId)
          .toSet();
      unawaited(_prefetchBoardsForSession(result.sessionId, reservedIds));

      if (result.failures.isNotEmpty) {
        _finalizeBulkReserveFailures(
          slotId: slotId,
          failures: result.failures,
          sessionId: result.sessionId,
        );
      }

      final failureIds = result.failures
          .map((failure) => failure.cartelaId)
          .toSet();
      final failedIds = cartelaIds
          .where((id) => !reservedIds.contains(id) && !failureIds.contains(id))
          .toSet();
      if (failedIds.isNotEmpty) {
        rollbackOptimisticSelections(
          slotId: slotId,
          cartelaIds: failedIds,
          sessionId: result.sessionId,
        );
      }

      return RegistrationActionSuccess(resolvedSessionId: result.sessionId);
    } catch (error) {
      if (!host.mounted || !session.selectModeEnabled) {
        return const RegistrationActionIgnored();
      }

      if (reserveGeneration != session.bulkReserveGeneration) {
        return const RegistrationReserveFlushCancelled();
      }

      rollbackOptimisticSelections(
        slotId: slotId,
        cartelaIds: cartelaIds.toSet(),
        sessionId: effectiveSessionIdFor(
          slotId,
          widgetSessionId: widgetSessionId,
        ),
      );

      RegistrationUxMetrics.bulkReserveFailure(cartelaCount: cartelaIds.length);

      if (error is ApiException &&
          (isRegistrationClosedError(error) || isSessionNotReadyError(error))) {
        unawaited(
          host.ref.read(currentGameOperationsProvider.notifier).refresh(),
        );
        return const RegistrationNetworkError(message: 'Registration closed.');
      }

      final message = error is ApiException
          ? error.displayMessage
          : 'Could not reserve selected cartelas.';
      return RegistrationNetworkError(message: message);
    } finally {
      session.bulkReserveInFlight = false;
      if (session.pendingBulkReserveIds.isNotEmpty) {
        scheduleBulkReserve(slotId);
      }
    }
  }

  Future<void> _cancelStaleReservationIds(
    Iterable<String> reservationIds,
  ) async {
    if (reservationIds.isEmpty) {
      return;
    }

    for (final reservationId in reservationIds) {
      try {
        await host.gamesRepository.cancelReservation(reservationId);
      } catch (_) {}
    }
  }

  Future<void> _prefetchBoardsForSession(
    String sessionId,
    Set<String> cartelaIds,
  ) async {
    if (cartelaIds.isEmpty) {
      return;
    }

    for (final cartelaId in cartelaIds) {
      try {
        final board = await host.gamesRepository.getCartelaBoard(
          cartelaId: cartelaId,
          sessionId: sessionId,
        );
        CartelaBoardPreviewCache.put(board);
      } catch (_) {}
    }
  }

  void _finalizeBulkReserveFailures({
    required String slotId,
    required List<BulkReserveFailure> failures,
    required String sessionId,
  }) {
    if (failures.isEmpty) {
      return;
    }

    final session = panelSessionFor(slotId);
    final changes = <RegistrationCartelaChange>[];
    host.markNeedsBuild(() {
      for (final failure in failures) {
        session.pendingBulkReserveIds.remove(failure.cartelaId);
        session.selectionReservations.remove(failure.cartelaId);
        final cartelaNumber = session.selectedCartelaNumbers.remove(
          failure.cartelaId,
        );
        session.selectedCartelaIds.remove(failure.cartelaId);
        if (cartelaNumber == null) {
          continue;
        }

        final normalizedReason = failure.reason.toLowerCase();
        final isTaken =
            normalizedReason.contains('taken') ||
            normalizedReason.contains('choosing') ||
            normalizedReason.contains('registered') ||
            normalizedReason.contains('live game');
        changes.add(
          RegistrationCartelaChange(
            cartelaId: failure.cartelaId,
            cartelaNumber: cartelaNumber,
            owner: isTaken ? 'OTHER' : 'AVAILABLE',
          ),
        );
      }
    });

    if (changes.isNotEmpty) {
      host.ref
          .read(registrationStatePatchProvider.notifier)
          .applyChanges(sessionId, changes);
    }
  }

  void rollbackOptimisticSelections({
    required String slotId,
    required Set<String> cartelaIds,
    String? sessionId,
  }) {
    if (cartelaIds.isEmpty) {
      return;
    }

    final session = panelSessionFor(slotId);
    final changes = <RegistrationCartelaChange>[];
    host.markNeedsBuild(() {
      for (final cartelaId in cartelaIds) {
        session.pendingBulkReserveIds.remove(cartelaId);
        session.selectionReservations.remove(cartelaId);
        final cartelaNumber = session.selectedCartelaNumbers.remove(cartelaId);
        session.selectedCartelaIds.remove(cartelaId);
        if (cartelaNumber != null && sessionId != null) {
          changes.add(
            RegistrationCartelaChange(
              cartelaId: cartelaId,
              cartelaNumber: cartelaNumber,
              owner: 'AVAILABLE',
            ),
          );
        }
      }
    });

    if (sessionId != null && changes.isNotEmpty) {
      host.ref
          .read(registrationStatePatchProvider.notifier)
          .applyChanges(sessionId, changes);
      host.ref.invalidate(registrationStateProvider(sessionId));
    }
  }

  Future<RegistrationActionResult> unselectReservedCartela({
    required String slotId,
    required String cartelaId,
    required int cartelaNumber,
    required String? widgetSessionId,
    List<GameCartelaModel> registeredCartelas = const [],
  }) async {
    final session = panelSessionFor(slotId);
    session.pendingBulkReserveIds.remove(cartelaId);
    final reservation = session.selectionReservations.remove(cartelaId);
    final sessionId =
        reservation?.sessionId ??
        effectiveSessionIdFor(
          slotId,
          widgetSessionId: widgetSessionId,
          registeredCartelas: registeredCartelas,
        );

    host.markNeedsBuild(() {
      session.selectedCartelaIds.remove(cartelaId);
      session.selectedCartelaNumbers.remove(cartelaId);
    });

    _bulkDebugLog(
      'deselect cartela=$cartelaNumber hadReservation=${reservation != null} selected_set=[${session.selectedCartelaIds.map((id) => session.selectedCartelaNumbers[id]).join(',')}]',
    );

    if (sessionId != null) {
      host.ref
          .read(registrationStatePatchProvider.notifier)
          .applyChanges(sessionId, [
            RegistrationCartelaChange(
              cartelaId: cartelaId,
              cartelaNumber: cartelaNumber,
              owner: 'AVAILABLE',
            ),
          ]);
    }

    if (reservation != null) {
      await releaseReservationHold(reservation);
      return const RegistrationActionSuccess();
    }

    if (sessionId != null) {
      host.ref.invalidate(registrationStateProvider(sessionId));
    }
    return const RegistrationActionSuccess();
  }

  Future<void> releaseReservationHolds(
    List<SelectionReservationHold> reservations,
  ) async {
    for (final reservation in reservations) {
      await releaseReservationHold(reservation);
    }
  }

  Future<void> releaseReservationHold(
    SelectionReservationHold reservation,
  ) async {
    try {
      await host.gamesRepository.cancelReservation(reservation.reservationId);
    } catch (_) {
      if (!host.mounted) {
        return;
      }
      host.ref.invalidate(registrationStateProvider(reservation.sessionId));
    }
  }

  void forgetSelectionReservations({
    required String slotId,
    required Set<String> cartelaIds,
    bool cancelOnServer = true,
  }) {
    if (cartelaIds.isEmpty) {
      return;
    }

    final session = panelSessionFor(slotId);
    final holdsToCancel = <SelectionReservationHold>[];
    final availabilityChangesBySession =
        <String, List<RegistrationCartelaChange>>{};

    for (final cartelaId in cartelaIds) {
      final hold = session.selectionReservations.remove(cartelaId);
      final cartelaNumber =
          hold?.cartelaNumber ?? session.selectedCartelaNumbers[cartelaId];
      final sessionId = hold?.sessionId;

      session.selectedCartelaIds.remove(cartelaId);
      session.selectedCartelaNumbers.remove(cartelaId);

      if (hold != null && cancelOnServer) {
        holdsToCancel.add(hold);
      }

      if (sessionId == null || cartelaNumber == null) {
        continue;
      }

      availabilityChangesBySession
          .putIfAbsent(sessionId, () => [])
          .add(
            RegistrationCartelaChange(
              cartelaId: cartelaId,
              cartelaNumber: cartelaNumber,
              owner: 'AVAILABLE',
            ),
          );
    }

    host.markNeedsBuild();

    final notifier = host.ref.read(registrationStatePatchProvider.notifier);
    for (final entry in availabilityChangesBySession.entries) {
      notifier.applyChanges(entry.key, entry.value);
      host.ref.invalidate(registrationStateProvider(entry.key));
    }

    if (holdsToCancel.isNotEmpty) {
      unawaited(releaseReservationHolds(holdsToCancel));
    }
  }

  void applyRegistrationPatch(
    String sessionId,
    List<GameCartelaModel> registeredCartelas,
  ) {
    if (registeredCartelas.isEmpty) {
      return;
    }

    final actorUserId = host.ref.read(authControllerProvider).session?.user.id;
    host.ref
        .read(registrationStatePatchProvider.notifier)
        .applyChanges(
          sessionId,
          registeredCartelas
              .map(
                (cartela) => RegistrationCartelaChange(
                  cartelaId: cartela.cartelaId,
                  cartelaNumber: cartela.cartela.number,
                  owner: 'ME',
                  actorUserId: actorUserId,
                ),
              )
              .toList(growable: false),
        );
  }

  void handleCartelasRegistered(List<GameCartelaModel> registeredCartelas) {
    if (!host.mounted || registeredCartelas.isEmpty) {
      return;
    }

    final game = host.game;
    if (game == null) {
      return;
    }

    final registeredSessionId = registeredCartelas.first.gameId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!host.mounted || host.game == null) {
        return;
      }

      final currentSessionId = host.game?.sessionId;
      host.ref.invalidate(registrationStateProvider(registeredSessionId));
      applyRegistrationPatch(registeredSessionId, registeredCartelas);
      host.ref.invalidate(myWalletProvider);

      if (currentSessionId != null &&
          registeredSessionId == currentSessionId) {
        applyMyCartelasOptimisticMerge(
          sessionId: registeredSessionId,
          incoming: registeredCartelas,
        );
        noteConfirmedCurrentSessionRegistrationMutation(registeredSessionId);
        unawaited(refreshMyCartelasSilently());
      } else if (registeredSessionId == trackedRegistrationSessionId) {
        noteConfirmedNextRegistrationSessionRegistrationMutation(
          registeredSessionId,
        );
        host.markNeedsBuild(() {
          nextRegistrationCartelas = sortedNextRegistrationCartelas(
            mergeRegisteredCartelas(
              current: nextRegistrationCartelas,
              incoming: registeredCartelas,
              sessionId: registeredSessionId,
            ),
          );
        });
        unawaited(refreshNextRegistrationCartelasSilently());
      }
    });
  }

  Future<void> refreshMyCartelasSilently({VoidCallback? onUpdated}) async {
    if (host.isGuest) {
      return;
    }

    final sessionId = host.game?.sessionId;
    if (sessionId == null || !host.mounted) {
      return;
    }

    myCartelasRefreshDebounceTimer?.cancel();
    myCartelasRefreshDebounceTimer = Timer(
      const Duration(milliseconds: 400),
      () async {
        if (!host.mounted || host.game?.sessionId != sessionId) {
          return;
        }

        try {
          final snapshotToken = captureCurrentSessionFetchToken(sessionId);
          final cartelas = await host.gamesRepository.getMyGameCartelas(
            sessionId,
          );
          if (!host.mounted || host.game?.sessionId != sessionId) {
            return;
          }
          tryApplyMyCartelasRemoteSnapshot(
            token: snapshotToken,
            responseSessionId: sessionId,
            cartelas: cartelas,
          );
          onUpdated?.call();
        } catch (_) {
          if (!host.mounted || host.game?.sessionId != sessionId) {
            return;
          }
        }
      },
    );
  }

  Future<void> refreshNextRegistrationCartelasSilently() async {
    if (host.isGuest) {
      return;
    }

    final sessionId = trackedRegistrationSessionId;
    if (sessionId == null || !host.mounted) {
      return;
    }

    nextCartelasRefreshDebounceTimer?.cancel();
    nextCartelasRefreshDebounceTimer = Timer(
      const Duration(milliseconds: 400),
      () async {
        if (!host.mounted || trackedRegistrationSessionId != sessionId) {
          return;
        }

        try {
          final snapshotToken = captureNextRegistrationSnapshotToken(sessionId);
          final nextCartelas = await host.gamesRepository.getMyGameCartelas(
            sessionId,
          );
          if (!host.mounted || trackedRegistrationSessionId != sessionId) {
            return;
          }
          if (!canApplyNextRegistrationSnapshot(snapshotToken, sessionId)) {
            return;
          }

          host.markNeedsBuild(() {
            nextRegistrationCartelas = sortedNextRegistrationCartelas(
              nextCartelas,
            );
          });
        } catch (_) {
          // Keep current next-registration cartelas if the silent refresh fails.
        }
      },
    );
  }
}
