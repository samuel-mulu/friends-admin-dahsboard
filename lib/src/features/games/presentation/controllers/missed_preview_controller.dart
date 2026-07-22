import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/called_number_model.dart';
import '../../data/models/game_model.dart';
import '../debug/missed_preview_debug.dart';
import '../utils/missed_live_preview_numbers.dart';
import '../utils/missed_live_preview_resolver.dart';
import '../utils/missed_live_preview_sync.dart';
import '../utils/missed_overlap_lifecycle.dart';
import 'live_game_host.dart';

/// Read-only observer of an unowned live round (Player 2 watching Game A while
/// registered for Game B).
///
/// Owns the full missed-player layout lifecycle:
/// overlap (preview + "Live & next round" card) → handoff hold → clean Game B
/// registration. Never mutates Player 1 engine state (`host.game`, called
/// numbers strip, winner flow) or triggers `runInitialLoad`. Soft-adopts
/// operations into `host.lastOperations` only so UI mode stays in sync with
/// the observer when Game A clears.
class MissedPreviewController {
  MissedPreviewController(this.host);

  final LiveGameHost host;

  static const Duration pollInterval = Duration(seconds: 2);

  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  GameOperationsCurrentResponse? _previewOps;
  List<CalledNumberModel> _calledNumbers = const [];
  String? _sessionId;
  MissedOverlapLifecycle _lifecycle = MissedOverlapLifecycle.none;

  Timer? _pollTimer;
  bool _fetchInFlight = false;
  bool _pokeQueued = false;
  bool _disposed = false;

  List<CalledNumberModel> get calledNumbers => _calledNumbers;

  MissedOverlapLifecycle get lifecycle => _lifecycle;

  MissedOverlapPhase get phase => _lifecycle.phase;

  bool get showMissedRoundWrapper => _lifecycle.showMissedRoundWrapper;

  bool get showHandoffHold => _lifecycle.showHandoffHold;

  /// Live/checking/WW session for the "Missed · …" line — null during handoff.
  GameModel? get blockingLiveGame => _lifecycle.blockingLiveGame;

  GameOperationsCurrentResponse? get _effectiveOps =>
      _previewOps ?? host.lastOperations;

  MissedLivePreviewResolution get resolution => resolveMissedLivePreview(
        operations: _effectiveOps,
        ownsSession: host.ownsSessionForPreview,
      );

  void syncFromCanonical({
    required GameOperationsCurrentResponse? operations,
    required List<CalledNumberModel> sharedCalledNumbers,
  }) {
    if (_disposed || !host.mounted) {
      return;
    }

    _previewOps = operations;
    final res = resolveMissedLivePreview(
      operations: operations,
      ownsSession: host.ownsSessionForPreview,
    );
    final sessionId = res.showPreview ? res.previewSession?.sessionId : null;

    if (sessionId == null || sessionId.isEmpty) {
      _applyLifecycleFromOps(operations, reason: 'canonical_no_preview');
      return;
    }

    if (_sessionId != sessionId) {
      _sessionId = sessionId;
      _calledNumbers = const [];
      MissedPreviewDebug.log('session_started session=$sessionId');
    }

    _adoptSessionNumbers(
      missedPreviewSessionNumbersFromSnapshot(
        snapshot: sharedCalledNumbers,
        sessionId: sessionId,
      ),
      source: 'canonical',
    );
    _applyLifecycleFromOps(operations, reason: 'canonical_overlap');
    _ensurePolling();
    _bump();
  }

  void onForeignNumberCalled(CalledNumberModel calledNumber) {
    if (_disposed || !host.mounted) {
      return;
    }

    final sessionId = calledNumber.sessionId;
    if (sessionId.isEmpty) {
      _pokePoll(reason: 'number_called_no_session');
      return;
    }

    if (_sessionId == null || _sessionId != sessionId) {
      _pokePoll(reason: 'number_called_new_session');
      return;
    }

    if (isMissedPreviewSessionConflict(
          sessionNumbers: _calledNumbers,
          incoming: calledNumber,
        ) ||
        isMissedPreviewSessionDuplicate(
          sessionNumbers: _calledNumbers,
          incoming: calledNumber,
        )) {
      return;
    }

    _calledNumbers = mergeMissedPreviewSessionCalledNumber(
      sessionNumbers: _calledNumbers,
      incoming: calledNumber,
    );
    _previewOps = bumpMissedPreviewCalledCountInOperations(
      operations: _previewOps,
      sessionId: sessionId,
      incomingOrder: calledNumber.order,
    );
    MissedPreviewDebug.numberApplied(
      order: calledNumber.order,
      sessionId: sessionId,
      previewBallCount: _calledNumbers.length,
      remaining: missedPreviewRemainingCount(
        previewSession: resolution.previewSession,
        filteredPreviewLength: _calledNumbers.length,
      ),
    );
    _bump();
  }

  void onForeignPhaseEvent({required String reason}) {
    if (_disposed || !host.mounted) {
      return;
    }
    _pokePoll(reason: reason);
  }

  void _ensurePolling() {
    if (_disposed || _pollTimer != null) {
      return;
    }
    _pollTimer = Timer.periodic(pollInterval, (_) => unawaited(_poll()));
    MissedPreviewDebug.log('poll_started interval=${pollInterval.inSeconds}s');
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _pokePoll({required String reason}) {
    _ensurePolling();
    if (_fetchInFlight) {
      _pokeQueued = true;
      return;
    }
    MissedPreviewDebug.log('poke reason=$reason');
    unawaited(_poll());
  }

  Future<void> _poll() async {
    if (_disposed || _fetchInFlight || !host.mounted) {
      return;
    }
    _fetchInFlight = true;
    try {
      final ops = await host.gamesRepository.getCurrentGameOperations();
      if (_disposed || !host.mounted) {
        return;
      }
      _previewOps = ops;

      final res = resolveMissedLivePreview(
        operations: ops,
        ownsSession: host.ownsSessionForPreview,
      );
      final sessionId = res.showPreview ? res.previewSession?.sessionId : null;

      if (sessionId != null && sessionId.isNotEmpty) {
        if (_sessionId != sessionId) {
          _sessionId = sessionId;
          _calledNumbers = const [];
          MissedPreviewDebug.log('session_started session=$sessionId src=poll');
        }

        final snapshot = await host.gamesRepository.getCalledNumbers(sessionId);
        if (_disposed || !host.mounted) {
          return;
        }
        _adoptSessionNumbers(
          missedPreviewSessionNumbersFromSnapshot(
            snapshot: snapshot.calledNumbers,
            sessionId: sessionId,
          ),
          source: 'poll',
        );
      } else {
        _sessionId = null;
        _calledNumbers = const [];
      }

      _applyLifecycleFromOps(ops, reason: 'poll');
      _bump();
    } catch (error) {
      MissedPreviewDebug.log('poll_failed error=$error');
    } finally {
      _fetchInFlight = false;
      if (_pokeQueued && !_disposed && host.mounted) {
        _pokeQueued = false;
        unawaited(_poll());
      }
    }
  }

  void _applyLifecycleFromOps(
    GameOperationsCurrentResponse? operations, {
    required String reason,
  }) {
    final res = resolveMissedLivePreview(
      operations: operations,
      ownsSession: host.ownsSessionForPreview,
    );
    final next = resolveMissedOverlapLifecycle(
      previousPhase: _lifecycle.phase,
      resolution: res,
      operations: operations,
      isGuest: host.isGuest,
    );

    final phaseChanged = next.phase != _lifecycle.phase;
    final leftOverlap = phaseChanged &&
        _lifecycle.phase == MissedOverlapPhase.overlapping &&
        next.phase != MissedOverlapPhase.overlapping;
    _lifecycle = next;

    if (phaseChanged) {
      MissedPreviewDebug.log(
        'lifecycle phase=${next.phase.name} reason=$reason '
        'wrapper=${next.showMissedRoundWrapper} handoff=${next.showHandoffHold}',
      );
    }

    // Soft-adopt ops into host so LiveUiMode leaves missedRoundRegistration
    // without a full canonical reload (Player 1 engine untouched).
    if (operations != null && phaseChanged) {
      _softAdoptHostOperations(operations);
    }

    // Drop Game A balls from the shared strip once overlap ends so Game B
    // READY registration is not poisoned into liveCalling.
    if (leftOverlap) {
      _clearForeignSharedCalledNumbers();
    }

    if (next.phase == MissedOverlapPhase.overlapping ||
        next.phase == MissedOverlapPhase.handoff) {
      _ensurePolling();
    } else {
      _stopPolling();
    }
  }

  void _clearForeignSharedCalledNumbers() {
    final primary = host.game;
    final primarySessionId = primary?.sessionId;
    if (primary == null ||
        primarySessionId == null ||
        primarySessionId.isEmpty ||
        primary.status != GameStatus.ready) {
      return;
    }

    final strip = host.controllers.calledNumbers.calledNumbers;
    if (strip.isEmpty) {
      return;
    }
    final hasOnlyForeign =
        strip.every((entry) => entry.sessionId != primarySessionId);
    if (!hasOnlyForeign) {
      return;
    }

    host.controllers.calledNumbers.clearSessionScopedState(
      clearCalledNumbers: true,
      clearManualMarks: false,
    );
    MissedPreviewDebug.log(
      'cleared_foreign_strip primary=$primarySessionId was=${strip.length}',
    );
  }

  void _softAdoptHostOperations(GameOperationsCurrentResponse operations) {
    // Player 1 owns the live/checking session — never overwrite their ops.
    if (host.ownsSessionForPreview(operations.liveGame?.sessionId) ||
        host.ownsSessionForPreview(operations.checkingGame?.sessionId)) {
      return;
    }

    final primary = host.game;
    if (primary != null &&
        host.ownsSessionForPreview(primary.sessionId) &&
        (primary.status == GameStatus.playing ||
            primary.status == GameStatus.checking ||
            primary.status == GameStatus.winnerWindow ||
            primary.status == GameStatus.finished ||
            primary.status == GameStatus.noWinner)) {
      return;
    }

    host.lastOperations = operations;
    host.hasBlockingLiveGame =
        operations.liveGame != null || operations.checkingGame != null;
  }

  void _adoptSessionNumbers(
    List<CalledNumberModel> incoming, {
    required String source,
  }) {
    if (incoming.isEmpty) {
      return;
    }
    if (incoming.length < _calledNumbers.length) {
      return;
    }
    final changed = incoming.length != _calledNumbers.length ||
        (incoming.isNotEmpty &&
            _calledNumbers.isNotEmpty &&
            incoming.last.order != _calledNumbers.last.order);
    _calledNumbers = incoming;
    if (_sessionId != null) {
      _previewOps = bumpMissedPreviewCalledCountInOperations(
        operations: _previewOps,
        sessionId: _sessionId!,
        incomingOrder: incoming.last.order,
      );
    }
    if (changed) {
      MissedPreviewDebug.log(
        'adopted source=$source count=${incoming.length} '
        'last=${incoming.last.order}',
      );
    }
  }

  void _bump() {
    if (_disposed) {
      return;
    }
    revision.value++;
    host.markNeedsBuild();
  }

  void dispose() {
    _disposed = true;
    _stopPolling();
    revision.dispose();
  }
}
