import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/winning_ball_cell.dart';
import '../../data/models/called_number_model.dart';
import '../../data/models/game_cartela_model.dart';
import '../../data/models/game_model.dart';
import '../utils/bingo_claim_eligibility.dart';
import '../utils/cartela_marked_pattern_evaluator.dart';
import '../utils/live_called_number_sync.dart';
import 'live_game_host.dart';

class NumberCalledSocketApplyResult {
  const NumberCalledSocketApplyResult({
    required this.applied,
    required this.requiresCalledNumbersSync,
    required this.requiresCanonicalSync,
    required this.highestKnownOrder,
    this.expectedNextOrder,
    this.incomingOrder,
  });

  final bool applied;
  final bool requiresCalledNumbersSync;
  final bool requiresCanonicalSync;
  final int highestKnownOrder;
  final int? expectedNextOrder;
  final int? incomingOrder;
}

/// Called-number strip state, reconciliation buffers, and claim holds.
class LiveCalledNumbersController {
  LiveCalledNumbersController(this.host);

  final LiveGameHost host;

  List<CalledNumberModel> calledNumbers = const [];
  bool isSyncingCalledNumbers = false;
  bool isRefreshingCalledNumbersPanel = false;
  final ValueNotifier<int> calledNumbersPanelRevision = ValueNotifier<int>(0);
  List<CalledNumberModel> bufferedCalledNumbers = const [];
  List<CalledNumberModel> deferredCalledNumbers = const [];
  final Set<String> claimingCartelaIds = <String>{};
  bool claimStripHoldActive = false;
  DateTime? preClaimNextAutoCallAt;
  final Set<String> processedClaimedIds = <String>{};
  final Set<String> processedResolvedClaimIds = <String>{};
  final Set<String> processedCalledNumberIds = <String>{};
  final Set<int> processedCalledNumberOrders = <int>{};
  final Set<String> processedCalledDrawKeys = <String>{};
  final Set<String> pendingClaimCartelaIds = <String>{};
  final Set<String> manualMarkedNumbers = <String>{};
  String? lastManualMarkedKey;
  String? marksSessionId;
  String? marksOwnerUserId;
  String? restoredMarksSessionId;
  Map<String, CartelaPatternUiResult> cartelaSortResults = const {};
  String? cartelaSortSignature;
  final Map<String, Set<String>> blockedCartelaFrozenMarks =
      <String, Set<String>>{};
  final Map<String, CartelaPatternUiResult> blockedCartelaFrozenSortResults =
      <String, CartelaPatternUiResult>{};
  final Map<String, String?> blockedCartelaReasonCodeById = <String, String?>{};
  final Map<String, String?> blockedCartelaServerReasonById = <String, String?>{};

  void rememberBlockedCartelaReason({
    required String gameCartelaId,
    String? reasonCode,
    String? serverReason,
  }) {
    if (reasonCode != null && reasonCode.trim().isNotEmpty) {
      blockedCartelaReasonCodeById[gameCartelaId] = reasonCode;
    }
    if (serverReason != null && serverReason.trim().isNotEmpty) {
      blockedCartelaServerReasonById[gameCartelaId] = serverReason;
    }
  }

  String? blockedReasonCodeFor(String gameCartelaId) {
    return blockedCartelaReasonCodeById[gameCartelaId];
  }

  String? blockedServerReasonFor(String gameCartelaId) {
    return blockedCartelaServerReasonById[gameCartelaId];
  }
  List<CalledNumberModel> socketBufferedCalledNumbers = const [];
  bool? socketAutoCallEnabled;
  Timer? disconnectedPollTimer;

  Duration get staggerInterval =>
      host.effectiveTimingConfig.missedNumberStaggerInterval;

  int get staggerMaxBalls =>
      host.effectiveTimingConfig.missedNumberStaggerMaxBalls;

  void dispose() {
    disconnectedPollTimer?.cancel();
    calledNumbersPanelRevision.dispose();
  }

  Set<String> get effectiveMarkedNumbers => manualMarkedNumbers;

  int get highestKnownCalledOrder {
    if (processedCalledNumberOrders.isEmpty) {
      return 0;
    }

    return processedCalledNumberOrders.reduce(
      (left, right) => left > right ? left : right,
    );
  }

  bool detectsCountDrift(GameModel game) =>
      game.calledNumbersCount > calledNumbers.length;

  bool isAnyClaimChecking({required bool hasSessionCheckingCartelaNumbers}) {
    return shouldPauseCalledNumbersStripForClaim(
      claimStripHoldActive: claimStripHoldActive,
      hasClaimingCartelaIds: claimingCartelaIds.isNotEmpty,
      hasSessionCheckingCartelaNumbers: hasSessionCheckingCartelaNumbers,
    );
  }

  bool isConflictingOrderDraw(CalledNumberModel calledNumber) {
    final incomingKey = calledDrawDedupKeyFor(calledNumber);
    for (final existing in [
      ...calledNumbers,
      ...bufferedCalledNumbers,
      ...deferredCalledNumbers,
    ]) {
      if (existing.order == calledNumber.order &&
          calledDrawDedupKeyFor(existing) != incomingKey) {
        return true;
      }
    }
    return false;
  }

  bool isDuplicateCalledNumber(CalledNumberModel calledNumber) {
    if (isConflictingOrderDraw(calledNumber)) {
      return false;
    }

    if (processedCalledDrawKeys.contains(calledDrawDedupKeyFor(calledNumber))) {
      return true;
    }

    return processedCalledNumberIds.contains(calledNumber.id) ||
        processedCalledNumberOrders.contains(calledNumber.order);
  }

  bool canClaimBingoForCartela({
    required GameModel? game,
    required GameCartelaModel gameCartela,
    required bool winnerWindowExpired,
    required bool isCountdownLocked,
  }) {
    if (!isCartelaEligibleForBingoClaim(
      game: game,
      gameCartela: gameCartela,
      winnerWindowExpired: winnerWindowExpired,
      hasPendingClaim: pendingClaimCartelaIds.contains(gameCartela.id),
      isCountdownLocked: isCountdownLocked,
    )) {
      return false;
    }

    if (calledNumbers.isEmpty && (game?.calledNumbersCount ?? 0) == 0) {
      return false;
    }

    return true;
  }

  SessionWinnerLastCalledNumber? sessionLastCalledNumberFromStrip() {
    if (calledNumbers.isEmpty) {
      return null;
    }

    final last = calledNumbers.last;
    return SessionWinnerLastCalledNumber(
      letter: last.letter,
      number: last.number,
    );
  }

  void markCalledNumbersPanelDirty() {
    calledNumbersPanelRevision.value++;
  }

  void rebuildCalledNumberTracking() {
    final ids = <String>{};
    final orders = <int>{};
    final drawKeys = <String>{};

    for (final item in [
      ...calledNumbers,
      ...bufferedCalledNumbers,
      ...deferredCalledNumbers,
    ]) {
      ids.add(item.id);
      orders.add(item.order);
      drawKeys.add(calledDrawDedupKeyFor(item));
    }

    processedCalledNumberIds
      ..clear()
      ..addAll(ids);
    processedCalledNumberOrders
      ..clear()
      ..addAll(orders);
    processedCalledDrawKeys
      ..clear()
      ..addAll(drawKeys);
  }

  void applyCalledNumbersSnapshot({
    required List<CalledNumberModel> incoming,
    required bool sessionChanged,
  }) {
    calledNumbers = normalizeCalledNumbers(incoming);
    deferredCalledNumbers = pruneDeferredCalledNumbers(
      committed: calledNumbers,
      deferred: sessionChanged ? const [] : deferredCalledNumbers,
    );
    rebuildCalledNumberTracking();
    isSyncingCalledNumbers = false;
  }

  /// Adds only draws missing from the local strip; never re-applies known balls.
  void fillCalledNumberGaps(List<CalledNumberModel> incoming) {
    final authoritative = normalizeCalledNumbers(incoming);
    final committedOrders = calledNumbers.map((item) => item.order).toSet();
    final missing = authoritative
        .where((number) => !committedOrders.contains(number.order))
        .toList(growable: false);
    if (missing.isEmpty) {
      deferredCalledNumbers = pruneDeferredCalledNumbers(
        committed: calledNumbers,
        deferred: deferredCalledNumbers,
      );
      isSyncingCalledNumbers = deferredCalledNumbers.isNotEmpty;
      return;
    }

    calledNumbers = mergeCalledNumbers(
      current: calledNumbers,
      incoming: missing,
    );
    deferredCalledNumbers = pruneDeferredCalledNumbers(
      committed: calledNumbers,
      deferred: deferredCalledNumbers,
    );
    rebuildCalledNumberTracking();
    isSyncingCalledNumbers = deferredCalledNumbers.isNotEmpty;
    markCalledNumbersPanelDirty();
  }

  /// Full backend snapshot on resume/reconnect — never merge stale local/socket balls.
  void replaceFromResumeSnapshot(List<CalledNumberModel> incoming) {
    bufferedCalledNumbers = const [];
    deferredCalledNumbers = const [];
    socketBufferedCalledNumbers = const [];
    calledNumbers = normalizeCalledNumbers(incoming);
    rebuildCalledNumberTracking();
    isSyncingCalledNumbers = false;
    markCalledNumbersPanelDirty();
  }

  /// Clears reconcile buffers before resume stagger without committing yet.
  void prepareResumeStaggerHydration() {
    bufferedCalledNumbers = const [];
    deferredCalledNumbers = const [];
    socketBufferedCalledNumbers = const [];
    isSyncingCalledNumbers = true;
    markCalledNumbersPanelDirty();
  }

  int countNewCalledNumbers(List<CalledNumberModel> incoming) {
    return incoming
        .where((number) => !isDuplicateCalledNumber(number))
        .length;
  }

  void clearSessionScopedState({
    bool clearCalledNumbers = true,
    bool clearManualMarks = true,
    bool clearCartelaSort = false,
  }) {
    pendingClaimCartelaIds.clear();
    claimingCartelaIds.clear();
    claimStripHoldActive = false;
    preClaimNextAutoCallAt = null;
    processedClaimedIds.clear();
    processedResolvedClaimIds.clear();
    processedCalledNumberIds.clear();
    processedCalledNumberOrders.clear();
    processedCalledDrawKeys.clear();
    bufferedCalledNumbers = const [];
    deferredCalledNumbers = const [];
    if (clearManualMarks) {
      manualMarkedNumbers.clear();
      lastManualMarkedKey = null;
    }
    if (clearCartelaSort) {
      cartelaSortResults = const {};
      cartelaSortSignature = null;
      blockedCartelaFrozenMarks.clear();
      blockedCartelaFrozenSortResults.clear();
      blockedCartelaReasonCodeById.clear();
      blockedCartelaServerReasonById.clear();
    }
    if (clearCalledNumbers) {
      calledNumbers = const [];
    }
    isSyncingCalledNumbers = false;
  }

  NumberCalledSocketApplyResult? applyNumberCalledSocket({
    required CalledNumberModel calledNumber,
    required bool pauseStripForClaim,
  }) {
    if (isDuplicateCalledNumber(calledNumber)) {
      return null;
    }

    final committedNumbers = pauseStripForClaim
        ? mergeCalledNumbers(
            current: calledNumbers,
            incoming: bufferedCalledNumbers,
          )
        : calledNumbers;
    final reconcileResult = applyLiveCalledNumberNotification(
      committed: committedNumbers,
      deferred: deferredCalledNumbers,
      incoming: calledNumber,
    );
    if (reconcileResult.isDuplicate) {
      return null;
    }

    final highestKnownOrder = reconcileResult.deferred.isNotEmpty
        ? reconcileResult.deferred.last.order
        : (reconcileResult.committed.isNotEmpty
              ? reconcileResult.committed.last.order
              : calledNumber.order);

    deferredCalledNumbers = reconcileResult.deferred;
    if (pauseStripForClaim) {
      bufferedCalledNumbers = mergeCalledNumbers(
        current: bufferedCalledNumbers,
        incoming: reconcileResult.accepted,
      );
    } else {
      calledNumbers = mergeCalledNumbers(
        current: calledNumbers,
        incoming: reconcileResult.accepted,
      );
    }
    rebuildCalledNumberTracking();
    isSyncingCalledNumbers =
        reconcileResult.requiresCanonicalSync ||
        reconcileResult.requiresCalledNumbersSync ||
        deferredCalledNumbers.isNotEmpty;
    markCalledNumbersPanelDirty();

    return NumberCalledSocketApplyResult(
      applied: true,
      requiresCalledNumbersSync: reconcileResult.requiresCalledNumbersSync,
      requiresCanonicalSync: reconcileResult.requiresCanonicalSync,
      highestKnownOrder: highestKnownOrder,
      expectedNextOrder: reconcileResult.expectedNextOrder,
      incomingOrder: reconcileResult.incomingOrder,
    );
  }

  void flushBufferedCalledNumbers() {
    if (bufferedCalledNumbers.isEmpty) {
      return;
    }

    calledNumbers = mergeCalledNumbers(
      current: calledNumbers,
      incoming: bufferedCalledNumbers,
    );
    bufferedCalledNumbers = const [];
    deferredCalledNumbers = pruneDeferredCalledNumbers(
      committed: calledNumbers,
      deferred: deferredCalledNumbers,
    );
    rebuildCalledNumberTracking();
    markCalledNumbersPanelDirty();
  }

  void releaseCalledNumbersStripHoldIfIdle({
    bool force = false,
    required bool hasSessionCheckingCartelaNumbers,
  }) {
    if (!force &&
        (claimingCartelaIds.isNotEmpty || hasSessionCheckingCartelaNumbers)) {
      return;
    }

    claimStripHoldActive = false;
    flushBufferedCalledNumbers();
    if (deferredCalledNumbers.isEmpty) {
      return;
    }

    calledNumbers = mergeCalledNumbers(
      current: calledNumbers,
      incoming: deferredCalledNumbers,
    );
    deferredCalledNumbers = const [];
    rebuildCalledNumberTracking();
    markCalledNumbersPanelDirty();
  }

  void syncCalledNumbersForFinishedReview({
    required void Function() refreshWinnerDisplay,
    required Future<void> Function() refreshFromUi,
  }) {
    releaseCalledNumbersStripHoldIfIdle(
      force: true,
      hasSessionCheckingCartelaNumbers: false,
    );
    refreshWinnerDisplay();
    markCalledNumbersPanelDirty();
    unawaited(refreshFromUi());
  }

  Future<void> refreshCalledNumbersFromUi({
    required void Function(String message) onError,
    required void Function() refreshWinnerDisplay,
  }) async {
    final sessionId = host.game?.sessionId;
    if (sessionId == null || isRefreshingCalledNumbersPanel) {
      return;
    }

    isRefreshingCalledNumbersPanel = true;
    markCalledNumbersPanelDirty();
    host.markNeedsBuild();

    try {
      final snapshot = await host.gamesRepository.getCalledNumbers(sessionId);
      if (!host.mounted) {
        return;
      }

      calledNumbers = normalizeCalledNumbers(snapshot.calledNumbers);
      bufferedCalledNumbers = const [];
      deferredCalledNumbers = const [];
      rebuildCalledNumberTracking();
      isSyncingCalledNumbers = false;
      refreshWinnerDisplay();
      markCalledNumbersPanelDirty();
      host.markNeedsBuild();
    } catch (error) {
      if (!host.mounted) {
        return;
      }

      onError(
        error is ApiException
            ? error.displayMessage
            : 'Could not refresh called numbers.',
      );
    } finally {
      if (host.mounted) {
        isRefreshingCalledNumbersPanel = false;
        markCalledNumbersPanelDirty();
        host.markNeedsBuild();
      }
    }
  }

  Future<bool> refetchCalledNumbersOnly() async {
    final sessionId = host.game?.sessionId;
    if (sessionId == null) {
      return false;
    }

    try {
      final snapshot = await host.gamesRepository.getCalledNumbers(sessionId);
      if (!host.mounted) {
        return false;
      }

      fillCalledNumberGaps(snapshot.calledNumbers);
      host.markNeedsBuild();

      final game = host.game;
      final unresolvedGap =
          deferredCalledNumbers.isNotEmpty ||
          (game != null && detectsCountDrift(game));
      isSyncingCalledNumbers = unresolvedGap;
      return !unresolvedGap;
    } catch (_) {
      // Keep current balls visible while reconnecting.
      return false;
    }
  }

  Future<void> hydrateCalledNumbersWithStagger({
    required List<CalledNumberModel> incoming,
    required int generation,
    required bool Function(int generation) isCurrentLoad,
    required void Function(int generation, VoidCallback fn) safeSetState,
  }) async {
    final sorted = normalizeCalledNumbers(incoming);
    final newOnes = sorted
        .where((number) => !isDuplicateCalledNumber(number))
        .toList(growable: false);

    if (newOnes.length <= 1) {
      safeSetState(generation, () {
        calledNumbers = sorted;
        deferredCalledNumbers = pruneDeferredCalledNumbers(
          committed: sorted,
          deferred: deferredCalledNumbers,
        );
        rebuildCalledNumberTracking();
        isSyncingCalledNumbers = false;
      });
      return;
    }

    safeSetState(generation, () {
      isSyncingCalledNumbers = true;
    });

    var perBallMicros = newOnes.length <= staggerMaxBalls
        ? staggerInterval.inMicroseconds
        : (staggerInterval.inMicroseconds * staggerMaxBalls) ~/ newOnes.length;
    const minPerBallMicros = 40000;
    if (perBallMicros < minPerBallMicros) {
      perBallMicros = minPerBallMicros;
    }
    final staggerDelay = Duration(microseconds: perBallMicros);

    for (final ball in newOnes) {
      if (!isCurrentLoad(generation) || !host.mounted) {
        return;
      }

      await Future<void>.delayed(staggerDelay);

      if (!isCurrentLoad(generation) || !host.mounted) {
        return;
      }

      safeSetState(generation, () {
        if (processedCalledNumberIds.contains(ball.id) ||
            processedCalledNumberOrders.contains(ball.order)) {
          return;
        }

        calledNumbers = mergeCalledNumbers(
          current: calledNumbers,
          incoming: [ball],
        );
        deferredCalledNumbers = pruneDeferredCalledNumbers(
          committed: calledNumbers,
          deferred: deferredCalledNumbers,
        );
        rebuildCalledNumberTracking();
      });
    }

    if (!isCurrentLoad(generation) || !host.mounted) {
      return;
    }

    safeSetState(generation, () {
      calledNumbers = sorted;
      deferredCalledNumbers = pruneDeferredCalledNumbers(
        committed: sorted,
        deferred: deferredCalledNumbers,
      );
      rebuildCalledNumberTracking();
      isSyncingCalledNumbers = false;
    });
  }

  void startDisconnectedPolling({required bool Function() isSocketConnected}) {
    disconnectedPollTimer?.cancel();
    disconnectedPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!host.mounted || isSocketConnected()) {
        stopDisconnectedPolling();
        return;
      }

      unawaited(refetchCalledNumbersOnly());
    });
  }

  void stopDisconnectedPolling() {
    disconnectedPollTimer?.cancel();
    disconnectedPollTimer = null;
  }
}
