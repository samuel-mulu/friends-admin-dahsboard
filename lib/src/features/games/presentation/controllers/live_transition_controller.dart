import 'dart:async';

import '../../data/models/game_model.dart';
import '../utils/live_presentation_phase.dart';
import '../utils/live_preparing_poll_sync_gate.dart';
import '../utils/live_ready_transition_lock.dart' as transition_lock;
import '../utils/live_session_ownership.dart';
import 'live_game_host.dart';

/// READY close handoff, transition lock, and primary selection during gaps.
class LiveTransitionController {
  LiveTransitionController(this.host);

  final LiveGameHost host;
  static const _preparingPhasePollInterval = Duration(seconds: 10);

  transition_lock.ReadyTransitionLock? readyTransitionLock;
  Timer? readyTransitionLockTimeoutTimer;
  bool lockTimeoutRefetchScheduled = false;
  Timer? preparingPhasePollTimer;

  bool get readyTransitionLockActive =>
      readyTransitionLock != null &&
      readyTransitionLock!.isActiveAt(host.countdownNow());

  void dispose() {
    readyTransitionLockTimeoutTimer?.cancel();
    preparingPhasePollTimer?.cancel();
  }

  void startReadyTransitionLock({
    required GameModel game,
    required transition_lock.ReadyTransitionReason reason,
  }) {
    final sessionId = game.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return;
    }

    readyTransitionLockTimeoutTimer?.cancel();
    readyTransitionLockTimeoutTimer = null;
    lockTimeoutRefetchScheduled = false;

    readyTransitionLock = transition_lock.startReadyTransitionLock(
      game: game,
      reason: reason,
      startedAt: host.countdownNow(),
    );

    readyTransitionLockTimeoutTimer = Timer(
      transition_lock.kReadyTransitionLockTimeout,
      () {
        if (!host.mounted || readyTransitionLock == null) {
          return;
        }
        expireReadyTransitionLockIfNeeded();
      },
    );
  }

  void clearReadyTransitionLock() {
    readyTransitionLockTimeoutTimer?.cancel();
    readyTransitionLockTimeoutTimer = null;
    readyTransitionLock = null;
    lockTimeoutRefetchScheduled = false;
  }

  void syncReadyTransitionLock({
    required GameOperationsCurrentResponse? operations,
    required GameModel? mergedGame,
  }) {
    final lock = readyTransitionLock;
    if (lock == null) {
      return;
    }

    if (transition_lock.shouldClearReadyTransitionLock(
      lock: lock,
      operations: operations,
      pinnedGame: mergedGame ?? host.game,
      now: host.countdownNow(),
    )) {
      final timedOut = transition_lock.readyTransitionLockExpired(
        lock,
        host.countdownNow(),
      );
      clearReadyTransitionLock();
      if (timedOut && !lockTimeoutRefetchScheduled) {
        lockTimeoutRefetchScheduled = true;
        unawaited(
          host.controllers.realtime.refetchCanonicalImmediate(
            reason: 'ready_transition_lock_timeout',
            includeCalledNumbers: lock.isPreparingToPlay,
            registrationSessionId: lock.sessionId,
          ),
        );
      }
    }
  }

  void syncOpenRegistrationBeatsTransitionLock({
    GameOperationsCurrentResponse? operations,
  }) {
    final lock = readyTransitionLock;
    if (lock != null && lock.isActiveAt(host.countdownNow())) {
      if (lock.isPreparingToPlay) {
        return;
      }
    }

    final registration = operations?.registrationOpenGame;
    if (!transition_lock.registrationOpenGameSupersedesTransitionLock(
      registrationOpenGame: registration,
      lockedSessionId: lock?.sessionId,
      lockReason: lock?.reason,
      now: host.countdownNow(),
    )) {
      return;
    }

    if (readyTransitionLock != null) {
      clearReadyTransitionLock();
    }
    host.controllers.countdown.reopenRegistrationCountdown(registration);
  }

  void expireReadyTransitionLockIfNeeded() {
    final lock = readyTransitionLock;
    if (lock == null ||
        !transition_lock.readyTransitionLockExpired(
          lock,
          host.countdownNow(),
        )) {
      return;
    }

    final sessionId = lock.sessionId;
    host.markNeedsBuild(clearReadyTransitionLock);
    if (!lockTimeoutRefetchScheduled) {
      lockTimeoutRefetchScheduled = true;
      unawaited(
        host.controllers.realtime.refetchCanonicalImmediate(
          reason: 'ready_transition_lock_expired',
          includeCalledNumbers: lock.isPreparingToPlay,
          registrationSessionId: sessionId,
        ),
      );
    }
  }

  bool isEmptyRegistrationCloseCandidate(GameModel game) {
    return host.myCartelas.isEmpty &&
        game.registeredCartelasCount == 0 &&
        game.status == GameStatus.ready &&
        game.calledNumbersCount == 0;
  }

  void handleRegistrationCountdownClosed() {
    final game = host.game;
    final countdown = host.controllers.countdown;
    if (!host.mounted ||
        game == null ||
        countdown.registrationCountdownClosed) {
      return;
    }

    if (isEmptyRegistrationCloseCandidate(game)) {
      handleEmptyRegistrationClosed(game);
      return;
    }

    enterRegistrationPreparing(game);
  }

  void enterRegistrationPreparing(GameModel game) {
    final countdown = host.controllers.countdown;
    final enteringPreparing = !countdown.registrationCountdownClosed;
    host.markNeedsBuild(() {
      countdown.registrationCountdownClosed = true;
      countdown.registrationCountdownScopeKey = registrationScopeKeyFor(game);
      if (transition_lock.shouldStartReadyTransitionLockPreparing(
        game: game,
        hasOwnedCartelas: host.myCartelas.isNotEmpty,
      )) {
        startReadyTransitionLock(
          game: game,
          reason: transition_lock.ReadyTransitionReason.preparingToPlay,
        );
      }
    });
    if (enteringPreparing) {
      schedulePreparingPhaseCatchUpRefetch();
    }
  }

  void handleEmptyRegistrationClosed(GameModel game) {
    final countdown = host.controllers.countdown;
    host.markNeedsBuild(() {
      countdown.registrationCountdownClosed = true;
      countdown.registrationCountdownScopeKey = registrationScopeKeyFor(game);
      if (transition_lock.shouldStartReadyTransitionLockNoPlayers(
        game: game,
        zeroPlayers: true,
      )) {
        startReadyTransitionLock(
          game: game,
          reason: transition_lock.ReadyTransitionReason.noPlayersHandoff,
        );
      }
    });

    stopPreparingPhasePolling();

    unawaited(
      host.controllers.realtime.refetchCanonicalImmediate(
        reason: 'registration_countdown_closed',
        includeCalledNumbers: false,
        registrationSessionId: game.sessionId,
      ),
    );
  }

  String registrationScopeKeyFor(GameModel game) {
    return '${game.id}:${game.sessionId ?? 'no-session'}';
  }

  String registrationCountdownSessionKey(GameModel game) {
    return game.sessionId ?? '${game.id}:no-session';
  }

  GameModel? resolvePrimaryFromOperations(
    GameOperationsCurrentResponse ops, {
    required bool ownsLiveCartelas,
  }) {
    return transition_lock.resolvePrimaryGameForOperationsWithTransitionLock(
      operations: ops,
      ownsLiveCartelas: ownsLiveCartelas,
      lock: readyTransitionLockActive ? readyTransitionLock : null,
      now: host.countdownNow(),
    );
  }

  bool ownsLiveCartelasForOperations(GameOperationsCurrentResponse ops) {
    final liveSessionId =
        ops.liveGame?.sessionId ?? ops.checkingGame?.sessionId;
    if (ownsLiveSessionCartelas(
      liveSessionId: liveSessionId,
      primarySessionId: host.game?.sessionId,
      cartelaSessionIds: host.myCartelas.map((cartela) => cartela.gameId),
    )) {
      return true;
    }
    final lock = readyTransitionLock;
    if (readyTransitionLockActive &&
        lock != null &&
        host.myCartelas.isNotEmpty &&
        host.game?.sessionId == lock.sessionId) {
      return true;
    }
    return false;
  }

  void syncRegistrationCountdownClosedState({GameModel? game}) {
    final current = game ?? host.game;
    final countdown = host.controllers.countdown;
    if (current == null) {
      countdown.registrationCountdownClosed = false;
      countdown.registrationCountdownScopeKey = null;
      return;
    }

    if (current.status != GameStatus.ready) {
      countdown.registrationCountdownClosed = false;
      countdown.registrationCountdownScopeKey = null;
      return;
    }

    final scopeKey = registrationScopeKeyFor(current);
    final reopenThreshold = host.countdownNow().add(const Duration(seconds: 5));
    if (current.canRegister &&
        current.scheduledStartAt != null &&
        current.scheduledStartAt!.isAfter(reopenThreshold)) {
      countdown.registrationCountdownClosed = false;
      countdown.registrationCountdownScopeKey = scopeKey;
      countdown.syncRegistrationCountdownDeadline(game: current);
      countdown.registrationCountdownTracker.reset();
      return;
    }

    if (readyTransitionLockActive &&
        current.sessionId != null &&
        current.sessionId == readyTransitionLock!.sessionId) {
      countdown.registrationCountdownClosed = true;
      countdown.registrationCountdownScopeKey = registrationScopeKeyFor(
        current,
      );
      return;
    }

    if (!current.canRegister) {
      final scheduledStartAt = current.scheduledStartAt;
      if (scheduledStartAt != null &&
          scheduledStartAt.isAfter(
            host.countdownNow().add(const Duration(seconds: 5)),
          )) {
        countdown.registrationCountdownClosed = false;
        countdown.registrationCountdownScopeKey = registrationScopeKeyFor(
          current,
        );
        return;
      }

      if (isEmptyRegistrationCloseCandidate(current)) {
        handleEmptyRegistrationClosed(current);
      } else {
        enterRegistrationPreparing(current);
      }
      return;
    }

    if (countdown.registrationCountdownScopeKey != scopeKey) {
      countdown.registrationCountdownClosed = false;
      countdown.registrationCountdownScopeKey = scopeKey;
    }

    if (LivePresentationPhaseResolver.registrationCountdownElapsed(
      game: current,
      registrationCountdownClosed: countdown.registrationCountdownClosed,
      staleAfter: host.preparingPhaseCap,
      now: host.countdownNow(),
      blockingLiveGameExists: host.currentReadyCountdownDeferredByLiveGame,
    )) {
      if (isEmptyRegistrationCloseCandidate(current)) {
        handleEmptyRegistrationClosed(current);
      } else {
        enterRegistrationPreparing(current);
      }
    } else if (!countdown.registrationCountdownClosed) {
      final scheduledStartAt = current.scheduledStartAt;
      final reopenThreshold = host.countdownNow().add(
        const Duration(seconds: 5),
      );
      if (scheduledStartAt != null &&
          scheduledStartAt.isAfter(reopenThreshold)) {
        countdown.registrationCountdownClosed = false;
      }
    }
  }

  void syncPreparingPhasePolling() {
    if (host.liveUiMode.presentationPhase ==
        LivePresentationPhase.preparingGame) {
      startPreparingPhasePolling();
      return;
    }
    stopPreparingPhasePolling();
  }

  void startPreparingPhasePolling() {
    if (preparingPhasePollTimer != null) {
      return;
    }
    preparingPhasePollTimer = Timer.periodic(_preparingPhasePollInterval, (_) {
      if (!host.mounted || !host.isAppInForeground) {
        stopPreparingPhasePolling();
        return;
      }
      if (host.liveUiMode.presentationPhase !=
          LivePresentationPhase.preparingGame) {
        stopPreparingPhasePolling();
        return;
      }
      if (shouldSkipPreparingPollDuringSync(
        resumeSyncInFlight: host.controllers.realtime.resumeSyncInFlight,
        canonicalRefetchInFlight:
            host.controllers.realtime.canonicalRefetchInFlight,
      )) {
        return;
      }
      unawaited(
        host.controllers.realtime.refetchCanonicalImmediate(
          reason: 'preparing_phase_poll',
          includeCalledNumbers: true,
          registrationSessionId: host.game?.sessionId,
        ),
      );
    });
  }

  void stopPreparingPhasePolling() {
    preparingPhasePollTimer?.cancel();
    preparingPhasePollTimer = null;
  }

  void schedulePreparingPhaseCatchUpRefetch() {
    if (shouldSkipPreparingPollDuringSync(
      resumeSyncInFlight: host.controllers.realtime.resumeSyncInFlight,
      canonicalRefetchInFlight:
          host.controllers.realtime.canonicalRefetchInFlight,
    )) {
      return;
    }
    unawaited(
      host.controllers.realtime.refetchCanonicalImmediate(
        reason: 'preparing_phase_catch_up',
        includeCalledNumbers: true,
        registrationSessionId: host.game?.sessionId,
      ),
    );
  }
}
