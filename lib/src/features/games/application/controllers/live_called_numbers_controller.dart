import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import 'package:friends_bingo_app/src/features/games/claims/data/storage/bingo_claim_attempt_storage.dart';
import 'package:friends_bingo_app/src/features/games/claims/data/models/bingo_claim_result.dart';
import 'package:friends_bingo_app/src/features/games/claims/domain/bingo_claim_source.dart';
import 'package:friends_bingo_app/src/features/games/patterns/domain/winning_ball_cell.dart';
import '../../data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import '../../data/models/game_model.dart';
import '../../presentation/debug/bingo_claim_diagnostics.dart';
import '../../presentation/utils/bingo_claim_eligibility.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_mark_helpers.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_marked_pattern_evaluator.dart';
import '../../presentation/utils/live_called_number_monotonic.dart';
import '../../presentation/utils/live_called_number_sync.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/merge_registered_cartelas.dart';
import 'live_game_host.dart';

import 'package:friends_bingo_app/src/features/games/claims/domain/bingo_claim_attempt.dart';

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

class LiveCalledNumbersController {
  LiveCalledNumbersController(
    this.host, {
    BingoClaimAttemptStorage? claimStorage,
    Future<BingoClaimAttemptStatus> Function(String, String)? recoverClaim,
    Future<BingoClaimResult?> Function(BingoClaimAttempt)? resubmitClaim,
    DateTime Function()? claimNow,
  }) : _claimStorage = claimStorage ?? BingoClaimAttemptStorage(),
       _recoverClaim = recoverClaim,
       _resubmitClaim = resubmitClaim,
       _claimNow = claimNow ?? DateTime.now;

  final LiveGameHost host;
  final BingoClaimAttemptStorage _claimStorage;
  final Future<BingoClaimAttemptStatus> Function(String, String)? _recoverClaim;
  final Future<BingoClaimResult?> Function(BingoClaimAttempt)? _resubmitClaim;
  final DateTime Function() _claimNow;
  final Map<String, BingoClaimAttempt> _claimAttempts = {};
  final Set<String> _resolvedClaimAttemptIds = {};
  final Set<String> _resolvedClaimCartelaIds = {};
  Timer? _claimRecoveryTimer;
  String? _claimUserId;
  String? _claimSessionId;
  int _claimScopeGeneration = 0;
  bool _claimDisposed = false;
  bool _claimForeground = true;
  bool claimScopeLoading = false;
  Object? claimRecoveryStorageError;
  bool _claimScopeReadInFlight = false;
  void Function(BingoClaimAttempt, BingoClaimAttemptStatus)? onClaimRecovered;
  Future<void> Function(BingoClaimAttempt, BingoClaimAttemptStatus)?
  beforeClaimRecovered;
  /// Applies a same-UUID POST result recovered outside the GET path.
  void Function(BingoClaimAttempt, BingoClaimResult)? onClaimResubmitResult;
  VoidCallback? onClaimRecoveryChanged;

  BingoClaimAttempt? claimAttemptFor(String cartelaId) =>
      _claimAttempts[cartelaId];

  /// Unresolved attempt still awaiting authoritative GET/HTTP (not retryDenied).
  /// Drives CONFIRMING UI so the button is never silent gray mid-recovery.
  bool isConfirmingClaim(String cartelaId) {
    final attempt = _claimAttempts[cartelaId];
    return attempt != null && !attempt.terminal;
  }

  /// Cartelas with an in-flight POST or non-terminal recovery identity.
  Set<String> get confirmingOrClaimingCartelaIds => {
    ...claimingCartelaIds,
    for (final entry in _claimAttempts.entries)
      if (!entry.value.terminal) entry.key,
  };

  /// Automatic recovery has done everything it safely can for this cartela
  /// (same-UUID retry budget exhausted, or no retry hook configured) and the
  /// claim is still unresolved. Drives a persistent, non-blocking escalation
  /// banner rather than relying on a one-shot SnackBar having been seen.
  BingoClaimAttempt? get claimNeedingEscalation {
    for (final entry in _claimAttempts.entries) {
      final attempt = entry.value;
      if (!attempt.terminal &&
          claimRecoveryFailedCartelaIds.contains(entry.key) &&
          (attempt.sameUuidPostRetries >=
                  BingoClaimAttempt.maxSameUuidPostRetries ||
              _resubmitClaim == null)) {
        return attempt;
      }
    }
    return null;
  }

  bool hasResolvedClaimAttempt(String? attemptId) =>
      _resolvedClaimAttemptIds.contains(attemptId);

  bool hasResolvedClaimForCartela(String cartelaId) =>
      _resolvedClaimCartelaIds.contains(cartelaId);

  bool isCurrentClaimAttempt(BingoClaimAttempt attempt) =>
      !_claimDisposed &&
      !attempt.terminal &&
      identical(_claimAttempts[attempt.gameCartelaId], attempt) &&
      attempt.userId == _claimUserId &&
      attempt.sessionId == _claimSessionId;

  bool claimOutcomeMatchesView(BingoClaimAttempt attempt, GameModel? game) =>
      !_claimDisposed &&
      attempt.userId == _claimUserId &&
      attempt.sessionId == _claimSessionId &&
      attempt.sessionId == game?.sessionId &&
      attempt.roundIndex == game?.displayRoundIndex &&
      (_claimAttempts[attempt.gameCartelaId] == null ||
          identical(_claimAttempts[attempt.gameCartelaId], attempt));

  List<GameCartelaModel> cartelasAfterClaimRecovery({
    required BingoClaimAttempt attempt,
    required BingoClaimAttemptStatus result,
    required GameModel? game,
    required List<GameCartelaModel> cartelas,
  }) {
    if (!claimOutcomeMatchesView(attempt, game)) return cartelas;
    final status = cartelaStatusForClaimOutcome(
      status: result.status,
      reportedCartelaStatus: result.gameCartelaStatus,
    );
    if (status == null) return cartelas;
    return patchCartelaTerminalStatus(
      cartelas: cartelas,
      gameCartelaId: attempt.gameCartelaId,
      status: status,
      now: _claimNow(),
    );
  }

  /// Single owner path for claim resolution (terminal or confirming).
  ///
  /// [applyCartelas] runs **before** pending/attempt locks are cleared, so a
  /// caller wrapping this in one `setState` never exposes REGISTERED + no
  /// pending between those updates. Use for HTTP, recovery GET, and resubmit.
  ClaimResolution resolveTerminalClaim({
    required BingoClaimAttempt attempt,
    required BingoClaimStatus status,
    required bool retryAllowed,
    required List<GameCartelaModel> cartelas,
    required void Function(List<GameCartelaModel> next) applyCartelas,
    GameCartelaStatus? reportedCartelaStatus,
  }) {
    if (!isCurrentClaimAttempt(attempt)) {
      return ClaimResolution(applied: false, cartelas: cartelas);
    }

    final cartelaStatus = cartelaStatusForClaimOutcome(
      status: status,
      reportedCartelaStatus: reportedCartelaStatus,
    );
    var nextCartelas = cartelas;
    if (cartelaStatus != null) {
      nextCartelas = patchCartelaTerminalStatus(
        cartelas: cartelas,
        gameCartelaId: attempt.gameCartelaId,
        status: cartelaStatus,
        now: _claimNow(),
      );
    }
    applyCartelas(nextCartelas);
    releaseEligibilityLocksForCartelas(nextCartelas);

    final applied = applyAuthoritativeClaimStatus(
      attempt,
      status,
      retryAllowed: retryAllowed,
    );
    if (!applied) {
      return ClaimResolution(applied: false, cartelas: cartelas);
    }
    return ClaimResolution(
      applied: true,
      cartelas: nextCartelas,
      cartelaStatus: cartelaStatus,
    );
  }

  /// Socket/presentation path when there is no live attempt to clear: still
  /// apply terminal cartela status through the same patch helper, then drop
  /// any leftover pending/claiming flags for that cartela in the same call.
  List<GameCartelaModel> applyPresentedTerminalCartela({
    required List<GameCartelaModel> cartelas,
    required String gameCartelaId,
    required GameCartelaStatus status,
  }) {
    final patched = patchCartelaTerminalStatus(
      cartelas: cartelas,
      gameCartelaId: gameCartelaId,
      status: status,
      now: _claimNow(),
    );
    pendingClaimCartelaIds.remove(gameCartelaId);
    claimingCartelaIds.remove(gameCartelaId);
    claimRecoveryFailedCartelaIds.remove(gameCartelaId);
    releaseEligibilityLocksForCartelas(patched);
    claimStripHoldActive = confirmingOrClaimingCartelaIds.isNotEmpty;
    if (!claimStripHoldActive) preClaimNextAutoCallAt = null;
    return patched;
  }

  /// Historical / cross-round terminal when [claimOutcomeMatchesView] is false.
  ///
  /// INVALID for a verified same-session cartela safely paints BLOCKED (chain
  /// permanent block). Otherwise retains [claimEligibilityLockedCartelaIds]
  /// so Bingo cannot reopen while the cartela is still locally REGISTERED.
  ClaimResolution resolveHistoricalTerminalClaim({
    required BingoClaimAttempt attempt,
    required BingoClaimStatus status,
    required bool retryAllowed,
    required List<GameCartelaModel> cartelas,
    required void Function(List<GameCartelaModel> next) applyCartelas,
    required GameModel? game,
    GameCartelaStatus? reportedCartelaStatus,
  }) {
    if (!isCurrentClaimAttempt(attempt)) {
      return ClaimResolution(applied: false, cartelas: cartelas);
    }
    if (attempt.claimAttemptId.isEmpty || attempt.gameCartelaId.isEmpty) {
      return ClaimResolution(applied: false, cartelas: cartelas);
    }

    final sameSession =
        game != null &&
        attempt.sessionId == game.sessionId &&
        attempt.sessionId == _claimSessionId &&
        attempt.userId == _claimUserId;

    GameCartelaModel? matchingCartela;
    if (sameSession) {
      for (final cartela in cartelas) {
        if (cartela.id == attempt.gameCartelaId &&
            cartela.userId == attempt.userId &&
            (cartela.gameId.isEmpty ||
                cartela.gameId == attempt.sessionId)) {
          matchingCartela = cartela;
          break;
        }
      }
    }

    if (status == BingoClaimStatus.invalid) {
      if (matchingCartela != null) {
        // Same GameCartela id stays BLOCKED for the whole chain session.
        final resolved = resolveTerminalClaim(
          attempt: attempt,
          status: status,
          retryAllowed: retryAllowed,
          cartelas: cartelas,
          applyCartelas: applyCartelas,
          reportedCartelaStatus:
              reportedCartelaStatus ?? GameCartelaStatus.blocked,
        );
        claimEligibilityLockedCartelaIds.remove(attempt.gameCartelaId);
        return resolved;
      }
      // No verified local cartela to paint: keep a hard lock, then clear the
      // attempt identity so storage does not retain a stale UUID.
      claimEligibilityLockedCartelaIds.add(attempt.gameCartelaId);
      applyAuthoritativeClaimStatus(
        attempt,
        status,
        retryAllowed: retryAllowed,
      );
      return ClaimResolution(applied: true, cartelas: cartelas);
    }

    // Historical VALID must not paint WINNER onto the newer round.
    applyAuthoritativeClaimStatus(
      attempt,
      status,
      retryAllowed: retryAllowed,
    );
    return ClaimResolution(applied: true, cartelas: cartelas);
  }

  /// Drop eligibility locks once cartelas show an authoritative terminal
  /// status (or the cartela left the list).
  void releaseEligibilityLocksForCartelas(List<GameCartelaModel> cartelas) {
    if (claimEligibilityLockedCartelaIds.isEmpty) return;
    final byId = <String, GameCartelaModel>{
      for (final cartela in cartelas) cartela.id: cartela,
    };
    claimEligibilityLockedCartelaIds.removeWhere((id) {
      final cartela = byId[id];
      if (cartela == null) return true;
      return isTerminalCartelaStatus(cartela.status);
    });
  }

  Future<void> bindClaimRecoveryScope(String? userId, String? sessionId) async {
    if (_claimDisposed) return;
    if (_claimUserId == userId &&
        _claimSessionId == sessionId &&
        (!claimScopeLoading || _claimScopeReadInFlight)) {
      return;
    }
    final generation = ++_claimScopeGeneration;
    _claimUserId = userId;
    _claimSessionId = sessionId;
    _claimRecoveryTimer?.cancel();
    _claimAttempts.clear();
    _resolvedClaimAttemptIds.clear();
    _resolvedClaimCartelaIds.clear();
    activeClaimAttemptIdByCartelaId.clear();
    claimingCartelaIds.clear();
    pendingClaimCartelaIds.clear();
    claimRecoveryFailedCartelaIds.clear();
    claimEligibilityLockedCartelaIds.clear();
    claimStripHoldActive = false;
    preClaimNextAutoCallAt = null;
    claimScopeLoading = userId != null && sessionId != null;
    _claimScopeReadInFlight = claimScopeLoading;
    if (!claimScopeLoading) return;
    try {
      final stored = await _claimStorage.load(userId!, sessionId!);
      if (_claimDisposed || generation != _claimScopeGeneration) return;
      for (final identity in stored) {
        final attempt = BingoClaimAttempt(
          userId: userId,
          sessionId: sessionId,
          gameCartelaId: identity['gameCartelaId'] as String,
          claimAttemptId: identity['claimAttemptId'] as String,
          roundIndex: identity['roundIndex'] as int,
          claimSource: BingoClaimSource.fromIdentity(identity['claimSource']),
        )..postInFlight = false;
        attempt.terminal = identity['retryDenied'] == true;
        _claimAttempts[attempt.gameCartelaId] = attempt;
        activeClaimAttemptIdByCartelaId[attempt.gameCartelaId] =
            attempt.claimAttemptId;
        pendingClaimCartelaIds.add(attempt.gameCartelaId);
        if (!attempt.terminal) attempt.nextRecoveryAt = _claimNow();
      }
      claimScopeLoading = false;
      claimRecoveryStorageError = null;
      onClaimRecoveryChanged?.call();
      _scheduleClaimRecovery();
    } catch (error) {
      claimRecoveryStorageError = error;
      // Fail closed: an unreadable identity cannot authorize a fresh POST.
      // Resume/refresh can retry loading the same scope.
    } finally {
      if (generation == _claimScopeGeneration) _claimScopeReadInFlight = false;
    }
  }

  BingoClaimAttempt? beginClaimAttempt({
    required String gameCartelaId,
    required String claimAttemptId,
    required int roundIndex,
    BingoClaimSource claimSource = BingoClaimSource.manual,
    String? autoBingoAttemptKey,
  }) {
    if (_claimDisposed ||
        claimScopeLoading ||
        _claimUserId == null ||
        _claimSessionId == null ||
        _claimAttempts.containsKey(gameCartelaId) ||
        activeClaimAttemptIdByCartelaId.containsKey(gameCartelaId)) {
      return null;
    }
    final attempt = BingoClaimAttempt(
      userId: _claimUserId!,
      sessionId: _claimSessionId!,
      gameCartelaId: gameCartelaId,
      claimAttemptId: claimAttemptId,
      roundIndex: roundIndex,
      claimSource: claimSource,
      autoBingoAttemptKey: autoBingoAttemptKey,
    );
    _claimAttempts[gameCartelaId] = attempt;
    activeClaimAttemptIdByCartelaId[gameCartelaId] = claimAttemptId;
    claimingCartelaIds.add(gameCartelaId);
    claimStripHoldActive = true;
    return attempt;
  }

  Future<void> persistClaimAttempt(BingoClaimAttempt attempt) =>
      _claimStorage.save(attempt.identity);

  /// Safe only before the POST is sent (e.g. local persistence failure).
  void cancelUnsentClaim(BingoClaimAttempt attempt) {
    unawaited(_claimStorage.remove(attempt.identity).catchError((Object _) {}));
    if (!isCurrentClaimAttempt(attempt)) return;
    _clearClaimAttempt(attempt);
    onClaimRecoveryChanged?.call();
  }

  void finishClaimSubmission(BingoClaimAttempt attempt) {
    attempt.postInFlight = false;
    if (!isCurrentClaimAttempt(attempt)) return;
    claimingCartelaIds.remove(attempt.gameCartelaId);
    // Keep pending so strip/eligibility treat this as CONFIRMING until GET.
    pendingClaimCartelaIds.add(attempt.gameCartelaId);
    claimStripHoldActive = confirmingOrClaimingCartelaIds.isNotEmpty;
    if (!claimStripHoldActive) preClaimNextAutoCallAt = null;
    onClaimRecoveryChanged?.call();
    _scheduleClaimRecovery();
  }

  /// The only path that clears a submitted attempt's identity and retry locks.
  bool applyAuthoritativeClaimStatus(
    BingoClaimAttempt attempt,
    BingoClaimStatus status, {
    required bool retryAllowed,
  }) {
    if (!isCurrentClaimAttempt(attempt)) return false;
    if (!status.isTerminal) {
      final now = _claimNow();
      if (now.difference(attempt.createdAt) >= const Duration(seconds: 15)) {
        return applyAuthoritativeClaimStatus(
          attempt,
          BingoClaimStatus.failed,
          retryAllowed: true,
        );
      }
      pendingClaimCartelaIds.add(attempt.gameCartelaId);
      attempt.recoveryErrors = 0;
      attempt.nextRecoveryAt = now.add(
        status == BingoClaimStatus.pending
            ? const Duration(seconds: 15)
            : const Duration(milliseconds: 700),
      );
    } else {
      final retryDenied =
          (status == BingoClaimStatus.failed ||
              status == BingoClaimStatus.alreadyResolved) &&
          !retryAllowed;
      attempt.terminal = true;
      attempt.terminalStatus = status;
      _resolvedClaimAttemptIds.add(attempt.claimAttemptId);
      _resolvedClaimCartelaIds.add(attempt.gameCartelaId);
      attempt.nextRecoveryAt = null;
      if (retryDenied) {
        claimingCartelaIds.remove(attempt.gameCartelaId);
        pendingClaimCartelaIds.add(attempt.gameCartelaId);
        unawaited(
          _claimStorage.save(attempt.identity).catchError((Object _) {}),
        );
      } else {
        _clearClaimAttempt(attempt);
        unawaited(
          _claimStorage.remove(attempt.identity).catchError((Object _) {}),
        );
      }
      claimStripHoldActive = confirmingOrClaimingCartelaIds.isNotEmpty;
      if (!claimStripHoldActive) preClaimNextAutoCallAt = null;
    }
    onClaimRecoveryChanged?.call();
    _scheduleClaimRecovery();
    return true;
  }

  void _clearClaimAttempt(BingoClaimAttempt attempt) {
    _claimAttempts.remove(attempt.gameCartelaId);
    activeClaimAttemptIdByCartelaId.remove(attempt.gameCartelaId);
    claimingCartelaIds.remove(attempt.gameCartelaId);
    pendingClaimCartelaIds.remove(attempt.gameCartelaId);
    claimRecoveryFailedCartelaIds.remove(attempt.gameCartelaId);
    claimStripHoldActive = confirmingOrClaimingCartelaIds.isNotEmpty;
    if (!claimStripHoldActive) preClaimNextAutoCallAt = null;
  }

  Future<void> recoverClaimAttempt(BingoClaimAttempt attempt) {
    if (!isCurrentClaimAttempt(attempt) || !_claimForeground) {
      return Future<void>.value();
    }
    final existing = attempt.recoveryInFlight;
    if (existing != null) return existing;
    final recovery = _runClaimRecovery(attempt);
    attempt.recoveryInFlight = recovery;
    return recovery;
  }

  Future<void> _runClaimRecovery(BingoClaimAttempt attempt) async {
    attempt.nextRecoveryAt = null;
    try {
      final result =
          await (_recoverClaim?.call(
                attempt.sessionId,
                attempt.claimAttemptId,
              ) ??
              host.gamesRepository.getBingoClaimAttempt(
                sessionId: attempt.sessionId,
                claimAttemptId: attempt.claimAttemptId,
              ));
      if (!isCurrentClaimAttempt(attempt)) return;
      if (result.claimAttemptId != attempt.claimAttemptId) {
        throw StateError('Recovery returned another claim attempt');
      }
      BingoClaimDiagnostics.record(
        event: 'bingo.recovery.result',
        claimAttemptId: attempt.claimAttemptId,
        sessionId: attempt.sessionId,
        cartelaId: attempt.gameCartelaId,
        claimStatus: result.status.name,
        state: 'get_ok',
      );
      // Never POST again once the backend has accepted the attempt (CHECKING+).
      await beforeClaimRecovered?.call(attempt, result);
      if (!isCurrentClaimAttempt(attempt)) return;
      if (result.status.isTerminal) {
        // Prefer the screen path (`resolveTerminalClaim` /
        // `resolveHistoricalTerminalClaim`) so cartela + locks share one
        // setState. If the callback is absent or leaves the attempt current,
        // fall back without unlocking a still-REGISTERED INVALID cartela.
        onClaimRecovered?.call(attempt, result);
        if (isCurrentClaimAttempt(attempt)) {
          if (result.status == BingoClaimStatus.invalid) {
            claimEligibilityLockedCartelaIds.add(attempt.gameCartelaId);
          }
          applyAuthoritativeClaimStatus(
            attempt,
            result.status,
            retryAllowed: result.retryAllowed,
          );
        }
      } else if (applyAuthoritativeClaimStatus(
        attempt,
        result.status,
        retryAllowed: result.retryAllowed,
      )) {
        onClaimRecoveryChanged?.call();
      }
    } catch (error) {
      if (!isCurrentClaimAttempt(attempt)) return;
      BingoClaimDiagnostics.record(
        event: 'bingo.recovery.result',
        claimAttemptId: attempt.claimAttemptId,
        sessionId: attempt.sessionId,
        cartelaId: attempt.gameCartelaId,
        statusCode: error is ApiException ? error.statusCode : null,
        dioType: error is ApiException ? error.dioExceptionType : null,
        state: 'get_error',
        detail: error is ApiException
            ? error.message
            : error.runtimeType.toString(),
      );
      // Proof of non-delivery requires TWO independent signals, never one
      // Dio exception type alone: (1) the original POST's own TCP handshake
      // never completed — structurally it cannot have sent any request
      // bytes — AND (2) this separate recovery GET, right now, also cannot
      // even connect. A 404/5xx/receiveTimeout GET means NestJS WAS reached
      // and is never treated as proof. This can never fire for a claim that
      // reached CHECKING, because reaching CHECKING requires the original
      // POST to have connected in the first place.
      //
      // Re-audited for the 6s claimPostReceiveTimeout (down from 32s): this
      // conclusion is unaffected. `postConnectNeverCompleted` is only ever
      // set from DioExceptionType.connectionTimeout, which is governed by
      // Dio's `connectTimeout` (TCP handshake, still the global 15s — never
      // overridden per-call) and is entirely independent of the shortened
      // `receiveTimeout`. A 6s POST that times out waiting for a response
      // throws `receiveTimeout`, not `connectionTimeout` — it already
      // connected and may well have been dispatched/accepted by Nest — so it
      // can never satisfy this condition and is correctly left to fall
      // through to ambiguous retention / same-UUID retry below, the same as
      // before this timeout change.
      final getNeverConnected = error is ApiException &&
          (error.dioExceptionType == 'connectionTimeout' ||
              error.dioExceptionType == 'connectionError');
      if (attempt.postConnectNeverCompleted && getNeverConnected) {
        BingoClaimDiagnostics.record(
          event: 'bingo.terminal',
          claimAttemptId: attempt.claimAttemptId,
          sessionId: attempt.sessionId,
          cartelaId: attempt.gameCartelaId,
          state: 'auto_cleared_never_dispatched',
        );
        cancelUnsentClaim(attempt);
        return;
      }
      final notFound = error is ApiException && error.statusCode == 404;
      if (notFound &&
          !attempt.postInFlight &&
          attempt.sameUuidPostRetries < BingoClaimAttempt.maxSameUuidPostRetries &&
          _resubmitClaim != null) {
        attempt.sameUuidPostRetries++;
        BingoClaimDiagnostics.record(
          event: 'bingo.retry.start',
          claimAttemptId: attempt.claimAttemptId,
          sessionId: attempt.sessionId,
          cartelaId: attempt.gameCartelaId,
          retryCount: attempt.sameUuidPostRetries,
          state: 'same_uuid_post',
          detail: 'recovery_get_404',
        );
        try {
          final posted = await _resubmitClaim(attempt);
          if (!isCurrentClaimAttempt(attempt)) return;
          if (posted != null) {
            BingoClaimDiagnostics.record(
              event: 'bingo.retry.result',
              claimAttemptId: attempt.claimAttemptId,
              sessionId: attempt.sessionId,
              cartelaId: attempt.gameCartelaId,
              claimStatus: posted.claim.status.name,
              retryCount: attempt.sameUuidPostRetries,
              state: 'same_uuid_ok',
            );
            claimRecoveryFailedCartelaIds.remove(attempt.gameCartelaId);
            attempt.serverClaimId = posted.claim.id;
            // Prefer screen resolve path; fall back so unit tests / skipped
            // presentation still clear the attempt.
            onClaimResubmitResult?.call(attempt, posted);
            if (isCurrentClaimAttempt(attempt)) {
              applyAuthoritativeClaimStatus(
                attempt,
                posted.claim.status,
                retryAllowed: posted.retryAllowed,
              );
            }
            return;
          }
        } catch (retryError) {
          BingoClaimDiagnostics.record(
            event: 'bingo.retry.result',
            claimAttemptId: attempt.claimAttemptId,
            sessionId: attempt.sessionId,
            cartelaId: attempt.gameCartelaId,
            retryCount: attempt.sameUuidPostRetries,
            statusCode:
                retryError is ApiException ? retryError.statusCode : null,
            dioType: retryError is ApiException
                ? retryError.dioExceptionType
                : null,
            state: 'same_uuid_failed',
            detail: retryError is ApiException
                ? retryError.message
                : retryError.runtimeType.toString(),
          );
          // Fall through to CONFIRMING + backoff; never invent INVALID.
        }
      }
      if (!isCurrentClaimAttempt(attempt)) return;
      claimRecoveryFailedCartelaIds.add(attempt.gameCartelaId);
      const backoff = [1, 2, 4, 8, 15];
      final index = attempt.recoveryErrors.clamp(0, backoff.length - 1);
      attempt.recoveryErrors++;
      attempt.nextRecoveryAt = _claimNow().add(
        Duration(seconds: backoff[index]),
      );
      onClaimRecoveryChanged?.call();
    } finally {
      attempt.recoveryInFlight = null;
      _scheduleClaimRecovery();
    }
  }

  void reconcileClaimAttempts() {
    if (claimScopeLoading) {
      unawaited(bindClaimRecoveryScope(_claimUserId, _claimSessionId));
      return;
    }
    for (final attempt in _claimAttempts.values.toList()) {
      if (isCurrentClaimAttempt(attempt)) {
        unawaited(recoverClaimAttempt(attempt));
      }
    }
  }

  void setClaimRecoveryForeground(bool foreground) {
    _claimForeground = foreground;
    if (!foreground) {
      _claimRecoveryTimer?.cancel();
    } else {
      reconcileClaimAttempts();
      _scheduleClaimRecovery();
    }
  }

  void _scheduleClaimRecovery() {
    _claimRecoveryTimer?.cancel();
    if (_claimDisposed || !_claimForeground) return;
    DateTime? earliest;
    for (final attempt in _claimAttempts.values) {
      final due = attempt.nextRecoveryAt;
      if (!attempt.terminal &&
          attempt.recoveryInFlight == null &&
          due != null &&
          (earliest == null || due.isBefore(earliest))) {
        earliest = due;
      }
    }
    if (earliest == null) return;
    final scheduledAt = earliest;
    final wait = earliest.difference(_claimNow());
    _claimRecoveryTimer = Timer(wait.isNegative ? Duration.zero : wait, () {
      // Timer rounds to milliseconds. Do not abandon an attempt if the callback
      // fires just before its DateTime deadline (or wall clock moves backwards).
      final now = _claimNow();
      final cutoff = now.isBefore(scheduledAt) ? scheduledAt : now;
      for (final attempt in _claimAttempts.values.toList()) {
        final due = attempt.nextRecoveryAt;
        if (due != null && !due.isAfter(cutoff)) {
          unawaited(recoverClaimAttempt(attempt));
        }
      }
    });
  }

  static const _disconnectedPollInterval = Duration(seconds: 10);

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

  /// Claim HTTP failed and my-cartelas recovery also failed — keep Bingo off
  /// until an authoritative claim-attempt recovery clears this cartela id.
  final Set<String> claimRecoveryFailedCartelaIds = <String>{};

  /// Historical INVALID (or equivalent) where BLOCKED could not yet be painted.
  /// Keeps Bingo off per cartela until cartelas show an authoritative terminal
  /// status — failed canonical refetch must not reopen eligibility.
  final Set<String> claimEligibilityLockedCartelaIds = <String>{};

  /// Active claimAttemptId per gameCartelaId while Checking / unresolved.
  final Map<String, String> activeClaimAttemptIdByCartelaId =
      <String, String>{};
  final Set<String> manualMarkedNumbers = <String>{};
  String? lastManualMarkedKey;
  String? marksSessionId;
  String? marksOwnerUserId;
  String? restoredMarksSessionId;

  /// Server-authoritative Auto Mark gate (`effectiveAutoMark`).
  /// When true, [effectiveMarkedNumbers] merges called-number keys for display.
  bool effectiveAutoMark = false;

  /// Server-authoritative Auto Bingo gate (`effectiveAutoBingo`).
  /// Independent of [effectiveAutoMark]; Nest remains claim authority.
  bool effectiveAutoBingo = false;

  /// FIFO gameCartelaIds awaiting AUTO claim submit (local scheduler only).
  List<String> autoBingoQueue = <String>[];

  /// Non-reentrant drain guard (R4).
  bool autoBingoDrainActive = false;

  /// Bumped on session/round transition; fences stale async drain work (R4).
  int autoBingoGeneration = 0;

  /// True while an AUTO `_submitBingoClaim` await is in flight.
  bool autoBingoSubmitInFlight = false;

  /// Attempt-level dedupe: session|round|cartela|completingOrder (R2).
  final Set<String> autoBingoAttemptDedupeKeys = <String>{};
  final Set<String> autoBingoDrainAttemptKeys = <String>{};

  /// Terminal suppress: session|round|cartela (R2).
  final Set<String> autoBingoTerminalSuppressKeys = <String>{};

  String? _autoBingoScopeSessionId;
  int _autoBingoScopeRoundIndex = 0;

  /// Called-number mark keys for the active strip (`B:5`). Session-scoped.
  final Set<String> calledMarkKeys = <String>{};

  Set<String>? _cachedEffectiveMarkedNumbers;

  Map<String, CartelaPatternUiResult> cartelaSortResults = const {};
  String? cartelaSortSignature;
  final Map<String, Set<String>> blockedCartelaFrozenMarks =
      <String, Set<String>>{};
  final Map<String, CartelaPatternUiResult> blockedCartelaFrozenSortResults =
      <String, CartelaPatternUiResult>{};
  final Map<String, String?> blockedCartelaReasonCodeById = <String, String?>{};
  final Map<String, String?> blockedCartelaServerReasonById =
      <String, String?>{};

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
    _claimDisposed = true;
    _claimRecoveryTimer?.cancel();
    disconnectedPollTimer?.cancel();
    calledNumbersPanelRevision.dispose();
  }

  /// Visual marks for cartela cells. Manual marks are always included.
  /// When [effectiveAutoMark] is true, also includes marks derived from the
  /// authoritative called-number strip. Never write this set to storage.
  Set<String> get effectiveMarkedNumbers {
    if (!effectiveAutoMark) {
      return manualMarkedNumbers;
    }

    final cached = _cachedEffectiveMarkedNumbers;
    if (cached != null) {
      return cached;
    }

    final next = visualMarkedNumbers(
      manualMarkedNumbers: manualMarkedNumbers,
      calledNumbers: calledNumbers,
      effectiveAutoMark: true,
    );
    _cachedEffectiveMarkedNumbers = next;
    return next;
  }

  void setEffectiveAutoMark(bool value) {
    if (effectiveAutoMark == value) {
      return;
    }
    effectiveAutoMark = value;
    invalidateEffectiveMarkedNumbersCache();
  }

  void setEffectiveAutoBingo(bool value) {
    if (effectiveAutoBingo == value) {
      return;
    }
    effectiveAutoBingo = value;
    if (!value) {
      // Stop scheduling only — never cancel accepted recovery identities.
      clearAutoBingoQueue();
    }
  }

  void clearAutoBingoQueue() {
    autoBingoQueue = <String>[];
  }

  /// Aligns Auto Bingo dedupe/queue with the active session/round (R2/R4).
  void ensureAutoBingoScope({
    required String? sessionId,
    required int roundIndex,
  }) {
    if (sessionId == _autoBingoScopeSessionId &&
        roundIndex == _autoBingoScopeRoundIndex) {
      return;
    }
    _autoBingoScopeSessionId = sessionId;
    _autoBingoScopeRoundIndex = roundIndex;
    autoBingoGeneration++;
    clearAutoBingoQueue();
    autoBingoAttemptDedupeKeys.clear();
    autoBingoDrainAttemptKeys.clear();
    autoBingoTerminalSuppressKeys.clear();
  }

  void notifyManualMarksChanged() {
    invalidateEffectiveMarkedNumbersCache();
  }

  void invalidateEffectiveMarkedNumbersCache() {
    _cachedEffectiveMarkedNumbers = null;
  }

  bool isCalledMarkKey(String key) => calledMarkKeys.contains(key);

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
      hasClaimingCartelaIds: confirmingOrClaimingCartelaIds.isNotEmpty,
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
    int? chainBingoArmedAfterCalledCount,
  }) {
    final effectiveCalledCount = calledNumbers.isNotEmpty
        ? calledNumbers.length
        : (game?.calledNumbersCount ?? 0);
    if (isTerminalCartelaStatus(gameCartela.status)) {
      claimEligibilityLockedCartelaIds.remove(gameCartela.id);
    }

    if (!isCartelaEligibleForBingoClaim(
      game: game,
      gameCartela: gameCartela,
      winnerWindowExpired: winnerWindowExpired,
      hasPendingClaim: pendingClaimCartelaIds.contains(gameCartela.id),
      isCountdownLocked: isCountdownLocked,
      calledNumbersCount: effectiveCalledCount,
      chainBingoArmedAfterCalledCount: chainBingoArmedAfterCalledCount,
    )) {
      return false;
    }

    if (claimScopeLoading ||
        _claimAttempts.containsKey(gameCartela.id) ||
        activeClaimAttemptIdByCartelaId.containsKey(gameCartela.id) ||
        claimRecoveryFailedCartelaIds.contains(gameCartela.id) ||
        claimEligibilityLockedCartelaIds.contains(gameCartela.id)) {
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
    // Auto Mark paints from the called strip; rebuild cartelas when it changes.
    if (effectiveAutoMark) {
      host.markNeedsBuild();
    }
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

    // Visual Auto Mark follows the committed strip only (not claim buffers).
    calledMarkKeys
      ..clear()
      ..addAll(calledNumberMarkKeys(calledNumbers));
    invalidateEffectiveMarkedNumbersCache();
  }

  void applyCalledNumbersSnapshot({
    required List<CalledNumberModel> incoming,
    required bool sessionChanged,
  }) {
    calledNumbers = _applyMonotonicSnapshot(
      incoming: incoming,
      preferIncomingIfNewerSocket: false,
      forceAcceptIncoming: sessionChanged,
    );
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

  /// Full backend snapshot on resume/reconnect — keep socket-ahead balls
  /// when HTTP is shorter for the same session.
  void replaceFromResumeSnapshot(List<CalledNumberModel> incoming) {
    bufferedCalledNumbers = const [];
    deferredCalledNumbers = const [];
    socketBufferedCalledNumbers = const [];
    calledNumbers = _applyMonotonicSnapshot(
      incoming: incoming,
      preferIncomingIfNewerSocket: true,
    );
    rebuildCalledNumberTracking();
    isSyncingCalledNumbers = false;
    markCalledNumbersPanelDirty();
  }

  List<CalledNumberModel> _applyMonotonicSnapshot({
    required List<CalledNumberModel> incoming,
    required bool preferIncomingIfNewerSocket,
    bool forceAcceptIncoming = false,
  }) {
    final normalizedIncoming = normalizeCalledNumbers(incoming);
    if (forceAcceptIncoming) {
      return normalizedIncoming;
    }

    final local = calledNumbers;
    final localSessionId =
        local.isNotEmpty ? local.first.sessionId : host.game?.sessionId;
    final incomingSessionId = normalizedIncoming.isNotEmpty
        ? normalizedIncoming.first.sessionId
        : host.game?.sessionId;

    final merge = mergeCalledNumbersMonotonic(
      sessionId: incomingSessionId,
      localSessionId: localSessionId,
      localOrders: local.map((item) => item.order).toList(growable: false),
      incomingOrders: normalizedIncoming
          .map((item) => item.order)
          .toList(growable: false),
      preferIncomingIfNewerSocket: preferIncomingIfNewerSocket,
      socketMaxOrder:
          preferIncomingIfNewerSocket ? highestKnownCalledOrder : null,
    );

    if (!merge.rejectedRollback) {
      return normalizedIncoming;
    }

    final byOrder = <int, CalledNumberModel>{
      for (final item in normalizedIncoming) item.order: item,
      for (final item in local) item.order: item,
    };
    return normalizeCalledNumbers([
      for (final order in merge.orders)
        if (byOrder[order] != null) byOrder[order]!,
    ]);
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
    _claimScopeGeneration++;
    _claimRecoveryTimer?.cancel();
    _claimAttempts.clear();
    _resolvedClaimAttemptIds.clear();
    _resolvedClaimCartelaIds.clear();
    _claimUserId = null;
    _claimSessionId = null;
    claimScopeLoading = false;
    pendingClaimCartelaIds.clear();
    claimingCartelaIds.clear();
    claimRecoveryFailedCartelaIds.clear();
    claimEligibilityLockedCartelaIds.clear();
    activeClaimAttemptIdByCartelaId.clear();
    claimStripHoldActive = false;
    preClaimNextAutoCallAt = null;
    ensureAutoBingoScope(sessionId: null, roundIndex: 0);
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
      calledMarkKeys.clear();
    }
    invalidateEffectiveMarkedNumbersCache();
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
        (confirmingOrClaimingCartelaIds.isNotEmpty ||
            hasSessionCheckingCartelaNumbers)) {
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
    void Function(CalledNumberModel ball)? onBallRevealed,
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
      if (newOnes.length == 1) {
        onBallRevealed?.call(newOnes.first);
      }
      return;
    }

    // Many missed balls on catch-up: sound only the latest to avoid noise.
    final soundEveryBall = newOnes.length <= 5;

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

      var revealed = false;
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
        revealed = true;
      });
      if (revealed && (soundEveryBall || identical(ball, newOnes.last))) {
        onBallRevealed?.call(ball);
      }
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
    if (disconnectedPollTimer != null) {
      return;
    }
    disconnectedPollTimer = Timer.periodic(_disconnectedPollInterval, (_) {
      if (!host.mounted || !host.isAppInForeground || isSocketConnected()) {
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
