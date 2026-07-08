import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/time/countdown_target_tracker.dart';
import '../../data/models/game_model.dart';
import '../debug/live_realtime_debug.dart';
import '../utils/live_presentation_phase.dart';
import '../utils/next_ball_countdown.dart' as next_ball_countdown;
import '../utils/next_ball_stale_guard.dart';
import '../utils/number_called_schedule_patch.dart';
import 'live_countdown_tick_context.dart';
import 'live_game_host.dart';

/// Registration, winner-window, and next-ball countdown state and deadlines.
class LiveCountdownController {
  LiveCountdownController(
    this.host, {
    NextBallStaleGuard? nextBallStaleGuard,
  }) : nextBallStaleGuard = nextBallStaleGuard ?? NextBallStaleGuard();

  final LiveGameHost host;

  bool registrationCountdownClosed = false;
  String? registrationCountdownScopeKey;
  String? countdownSessionId;
  DateTime? countdownDeadline;
  final CountdownTargetTracker registrationCountdownTracker =
      CountdownTargetTracker();
  final CountdownTargetTracker winnerWindowCountdownTracker =
      CountdownTargetTracker();
  final CountdownTargetTracker nextBallCountdownTracker =
      CountdownTargetTracker();
  final NextBallStaleGuard nextBallStaleGuard;
  bool serverClockSnapOnNextSync = false;
  Timer? nextBallCountdownTicker;
  int? nextBallCountdownSeconds;
  int nextBallZeroForMs = 0;
  next_ball_countdown.NextBallPlayPhase nextBallPlayPhase =
      next_ball_countdown.NextBallPlayPhase.counting;
  int? callingPhaseBaselineOrder;
  DateTime? winnerWindowEndsAt;
  Timer? winnerWindowTicker;

  /// BINGO claim button lock during pre-call / awaiting ball — does not dirty the cartela list.
  final ValueNotifier<bool> bingoClaimLocked = ValueNotifier<bool>(false);

  DateTime? _trackedNextAutoCallAt;
  String? _trackedNextBallSessionScope;
  bool _nextBallScheduleAuthoritativelyNull = false;
  bool _claimPausesNextBallCountdown = false;
  int _activeNextBallTickerCount = 0;
  Duration _nextBallTickerInterval = const Duration(seconds: 1);
  bool _loggedCalledNumbersStaleSync = false;
  bool _loggedCanonicalStaleRefetch = false;
  bool _pausedForAppBackground = false;

  void dispose() {
    bingoClaimLocked.dispose();
    _stopNextBallTicker(clearDisplay: false);
    winnerWindowTicker?.cancel();
    winnerWindowTicker = null;
  }

  void updateBingoClaimLocked(bool value) {
    if (bingoClaimLocked.value == value) {
      return;
    }
    bingoClaimLocked.value = value;
  }

  @visibleForTesting
  int get activeNextBallTickerCount => _activeNextBallTickerCount;

  void pauseForAppBackground() {
    _pausedForAppBackground = true;
    _stopNextBallTicker(clearDisplay: false);
    winnerWindowTicker?.cancel();
    winnerWindowTicker = null;
  }

  void resumeFromAppBackground() {
    _pausedForAppBackground = false;
  }

  /// Countdown target after claim-pause and authoritative-null schedule guards.
  DateTime? effectiveNextAutoCallAt(GameModel? game) {
    if (game == null) {
      return null;
    }
    return _effectiveNextAutoCallTarget(game);
  }

  DateTime? effectiveRegistrationDeadline({
    required bool canonicalRefetchInFlight,
    required bool postGameSummaryHoldActive,
    required bool blockingLiveGameExists,
  }) {
    final game = host.game;
    if (game == null) {
      return null;
    }

    return resolveRegistrationCountdownDeadline(
      game: game,
      timingConfigLoaded: host.timingConfigLoaded,
      isLoading: host.isLoading,
      registrationCountdownClosed: registrationCountdownClosed,
      canonicalRefetchInFlight: canonicalRefetchInFlight,
      countdownSessionId: countdownSessionId,
      sessionKey: host.controllers.transition.registrationCountdownSessionKey(
        game,
      ),
      countdownDeadline: countdownDeadline,
      postGameSummaryHoldActive: postGameSummaryHoldActive,
      blockingLiveGameExists: blockingLiveGameExists,
      now: host.countdownNow(),
    );
  }

  void syncRegistrationCountdownDeadline({required GameModel game}) {
    countdownSessionId =
        host.controllers.transition.registrationCountdownSessionKey(game);
    countdownDeadline = game.scheduledStartAt;
  }

  void clearRegistrationCountdownDeadline() {
    countdownSessionId = null;
    countdownDeadline = null;
  }

  void reopenRegistrationCountdown(GameModel? registration) {
    registrationCountdownClosed = false;
    registrationCountdownScopeKey = null;
    if (registration != null) {
      syncRegistrationCountdownDeadline(game: registration);
      registrationCountdownScopeKey =
          host.controllers.transition.registrationScopeKeyFor(registration);
    }
    registrationCountdownTracker.reset();
  }

  void reopenRegistrationCountdownIfNeeded(GameModel game) {
    if (game.status != GameStatus.ready || !game.canRegister) {
      return;
    }

    final scheduledStartAt = game.scheduledStartAt;
    if (scheduledStartAt == null) {
      return;
    }

    final reopenThreshold = host.countdownNow().add(const Duration(seconds: 5));
    if (!scheduledStartAt.isAfter(reopenThreshold)) {
      return;
    }

    final scopeKey = host.controllers.transition.registrationScopeKeyFor(game);
    registrationCountdownClosed = false;
    registrationCountdownScopeKey = scopeKey;
    syncRegistrationCountdownDeadline(game: game);
  }

  DateTime? effectiveWinnerWindowEndsAt() {
    if (host.game?.status != GameStatus.winnerWindow) {
      return null;
    }
    return host.game?.winnerWindowEndsAt ?? winnerWindowEndsAt;
  }

  bool winnerWindowExpired() {
    return isWinnerWindowExpired(
      status: host.game?.status,
      windowEndsAt: effectiveWinnerWindowEndsAt(),
      now: host.countdownNow(),
    );
  }

  void syncServerClockFromUtc(
    DateTime serverNowUtc, {
    bool snap = false,
    bool ignoreOlder = false,
  }) {
    final clock = host.controllers.realtime.serverClock;
    clock.sync(
      serverNowUtc,
      snap: snap || serverClockSnapOnNextSync,
      ignoreOlder: ignoreOlder,
    );
    serverClockSnapOnNextSync = false;
  }

  void resetNextBallState() {
    _stopNextBallTicker(clearDisplay: true);
    nextBallCountdownTracker.reset();
    nextBallStaleGuard.reset();
    _trackedNextAutoCallAt = null;
    _trackedNextBallSessionScope = null;
    _nextBallScheduleAuthoritativelyNull = false;
    _claimPausesNextBallCountdown = false;
    nextBallPlayPhase = next_ball_countdown.NextBallPlayPhase.counting;
    callingPhaseBaselineOrder = null;
    _loggedCalledNumbersStaleSync = false;
    _loggedCanonicalStaleRefetch = false;
    LiveRealtimeDebug.resetCountdownDedup();
  }

  void setClaimPause(bool paused) {
    _claimPausesNextBallCountdown = paused;
    if (paused) {
      _stopNextBallTicker(clearDisplay: true);
    }
  }

  void onNextBallScheduleChanged({
    required GameModel game,
    required DateTime? nextAutoCallAt,
    required bool scheduleChanged,
  }) {
    final scopeKey = game.sessionId ?? game.id;
    if (!scheduleChanged &&
        dateTimesEqualForSchedule(nextAutoCallAt, _trackedNextAutoCallAt) &&
        scopeKey == _trackedNextBallSessionScope) {
      return;
    }

    if (scheduleChanged ||
        !dateTimesEqualForSchedule(nextAutoCallAt, _trackedNextAutoCallAt) ||
        scopeKey != _trackedNextBallSessionScope) {
      if (nextAutoCallAt == null) {
        nextBallCountdownTracker.reset();
        nextBallStaleGuard.reset();
        _trackedNextAutoCallAt = null;
        _trackedNextBallSessionScope = scopeKey;
        _nextBallScheduleAuthoritativelyNull = true;
        nextBallPlayPhase = next_ball_countdown.NextBallPlayPhase.counting;
        callingPhaseBaselineOrder = null;
        _loggedCalledNumbersStaleSync = false;
        _loggedCanonicalStaleRefetch = false;
        _stopNextBallTicker(clearDisplay: true);
        return;
      }

      _nextBallScheduleAuthoritativelyNull = false;
      _loggedCalledNumbersStaleSync = false;
      _loggedCanonicalStaleRefetch = false;
      if (scheduleChanged ||
          !dateTimesEqualForSchedule(nextAutoCallAt, _trackedNextAutoCallAt)) {
        nextBallCountdownTracker.reset();
      }
      _trackedNextAutoCallAt = nextAutoCallAt;
      _trackedNextBallSessionScope = scopeKey;
    }

    final clock = host.controllers.realtime.serverClock;
    final rawSeconds = next_ball_countdown.nextBallCountdownSeconds(
      nextAutoCallAt,
      clock: clock,
    );
    nextBallStaleGuard.onScheduleOrBallEvent(
      target: nextAutoCallAt,
      sessionId: scopeKey,
      rawRemaining: rawSeconds,
    );
  }

  void syncNextBallTicker(
    LiveCountdownTickContext Function() readContext, {
    required void Function() onDisplayChanged,
    void Function(NextBallStaleEvaluation evaluation)? onStaleRecovery,
  }) {
    if (_pausedForAppBackground) {
      _stopNextBallTicker(clearDisplay: false);
      return;
    }

    final context = readContext();
    final showCountdown =
        context.presentationPhase == LivePresentationPhase.liveCalling ||
        context.presentationPhase == LivePresentationPhase.liveWaitingFirstBall;

    if (!showCountdown || context.game == null) {
      _clearNextBallDisplay();
      _stopNextBallTicker(clearDisplay: false);
      return;
    }

    final game = context.game!;
    if (_shouldStopNextBallTicker(
      game: game,
      autoCallActive: context.autoCallActive,
      allBallsDrawn: context.allBallsDrawn,
    )) {
      if (context.allBallsDrawn) {
        nextBallStaleGuard.reset();
        _trackedNextAutoCallAt = null;
      }
      _clearNextBallDisplay();
      _stopNextBallTicker(clearDisplay: false);
      return;
    }

    final target = _effectiveNextAutoCallTarget(game);
    if (target == null) {
      _clearNextBallDisplay();
      _stopNextBallTicker(clearDisplay: false);
      return;
    }

    if (nextBallCountdownTicker?.isActive == true) {
      _maybeRescheduleNextBallTicker(
        readContext: readContext,
        onDisplayChanged: onDisplayChanged,
        onStaleRecovery: onStaleRecovery,
      );
      _assertSingleActiveNextBallTicker();
      return;
    }

    final displayChanged = _tickNextBallDisplay(
      context: context,
      game: game,
      target: target,
      onStaleRecovery: onStaleRecovery,
      logCountdown: false,
    );
    if (displayChanged) {
      onDisplayChanged();
    }

    _startNextBallTicker(
      readContext: readContext,
      initialInterval: _nextBallCountdownTickInterval(target, context.autoCallActive),
      onDisplayChanged: onDisplayChanged,
      onStaleRecovery: onStaleRecovery,
    );
  }

  void syncWinnerWindowTicker({
    required bool shouldRunWinnerWindowTicker,
    required VoidCallback onExpired,
    VoidCallback? onPollSessionWinners,
    VoidCallback? onPreloadSessionWinners,
  }) {
    winnerWindowTicker?.cancel();
    winnerWindowTicker = null;

    if (_pausedForAppBackground) {
      return;
    }

    if (!shouldRunWinnerWindowTicker ||
        effectiveWinnerWindowEndsAt() == null) {
      onPollSessionWinners?.call();
      return;
    }

    onPreloadSessionWinners?.call();

    if (winnerWindowExpired()) {
      onExpired();
      onPollSessionWinners?.call();
      return;
    }

    winnerWindowTicker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!host.mounted) {
        return;
      }

      onPreloadSessionWinners?.call();

      if (winnerWindowExpired()) {
        winnerWindowTicker?.cancel();
        winnerWindowTicker = null;
        onExpired();
        onPollSessionWinners?.call();
      }
    });
  }

  DateTime? _effectiveNextAutoCallTarget(GameModel game) {
    if (_claimPausesNextBallCountdown || _nextBallScheduleAuthoritativelyNull) {
      return null;
    }
    return game.nextAutoCallAt;
  }

  void stopNextBallTicker({required bool clearDisplay}) {
    _stopNextBallTicker(clearDisplay: clearDisplay);
  }

  bool _tickNextBallDisplay({
    required LiveCountdownTickContext context,
    required GameModel game,
    required DateTime? target,
    void Function(NextBallStaleEvaluation evaluation)? onStaleRecovery,
    bool logCountdown = true,
  }) {
    if (context.isAnyClaimChecking) {
      return false;
    }

    final currentPhase = context.presentationPhase;
    final showCountdownNow =
        currentPhase == LivePresentationPhase.liveCalling ||
        currentPhase == LivePresentationPhase.liveWaitingFirstBall;
    if (!showCountdownNow) {
      return _clearNextBallDisplay();
    }

    if (_shouldStopNextBallTicker(
      game: game,
      autoCallActive: context.autoCallActive,
      allBallsDrawn: context.allBallsDrawn,
    )) {
      if (context.allBallsDrawn) {
        nextBallStaleGuard.reset();
      }
      return _clearNextBallDisplay();
    }

    final clock = host.controllers.realtime.serverClock;
    final state = next_ball_countdown.resolveNextBallCountdownState(
      showCountdown: true,
      hideForSync: context.isSyncingCalledNumbers,
      connectionStatus: context.connectionStatus,
      nextAutoCallAt: target,
      waitingForFirstBall:
          currentPhase == LivePresentationPhase.liveWaitingFirstBall,
      allBallsDrawn: context.allBallsDrawn,
      clock: clock,
    );
    final rawSeconds = next_ball_countdown.nextBallCountdownSeconds(target, clock: clock);
    final resolvedPlayPhase = next_ball_countdown.resolveNextBallPlayPhase(
      gameStatus: game.status,
      autoCallActive: context.autoCallActive,
      nextAutoCallAt: target,
      clock: clock,
    );
    if (resolvedPlayPhase == next_ball_countdown.NextBallPlayPhase.calling &&
        nextBallPlayPhase != next_ball_countdown.NextBallPlayPhase.calling) {
      callingPhaseBaselineOrder = context.highestKnownCalledOrder;
    } else if (resolvedPlayPhase !=
        next_ball_countdown.NextBallPlayPhase.calling) {
      callingPhaseBaselineOrder = null;
    }
    nextBallPlayPhase = resolvedPlayPhase;
    final locked = next_ball_countdown.isBingoClaimCountdownLocked(
      gameStatus: game.status,
      autoCallActive: context.autoCallActive,
      nextAutoCallAt: target,
      clock: clock,
      playPhase: resolvedPlayPhase,
      highestKnownCalledOrder: context.highestKnownCalledOrder,
      callingPhaseBaselineOrder: callingPhaseBaselineOrder,
    );
    updateBingoClaimLocked(locked);
    nextBallStaleGuard.onScheduleOrBallEvent(
      target: target,
      sessionId: game.sessionId ?? game.id,
      rawRemaining: rawSeconds,
    );
    final staleEvaluation = nextBallStaleGuard.evaluate(
      game: game,
      socketAutoCallEnabled: context.socketAutoCallEnabled,
      rawRemaining: rawSeconds,
      effectiveTarget: target,
      useEffectiveTarget: true,
    );
    if (rawSeconds > 0) {
      _loggedCalledNumbersStaleSync = false;
      _loggedCanonicalStaleRefetch = false;
    }
    _maybeRecoverStaleNextBall(
      game: game,
      staleEvaluation: staleEvaluation,
      onStaleRecovery: onStaleRecovery,
    );

    final nextSeconds = nextBallCountdownTracker.apply(
      target: target,
      scopeKey: game.sessionId ?? game.id,
      rawRemaining: rawSeconds,
    );

    final displaySeconds =
        state == next_ball_countdown.NextBallCountdownState.calling
        ? 0
        : nextSeconds;
    final zeroForMs = staleEvaluation.zeroForMs;
    final remainingForLog =
        state == next_ball_countdown.NextBallCountdownState.calling
        ? 0
        : nextSeconds;
    if (logCountdown) {
      LiveRealtimeDebug.countdown(
        target: target,
        serverNow: clock.lastServerNowUtc,
        deviceNow: DateTime.now(),
        offsetMs: clock.offsetMs,
        remaining: remainingForLog,
      );
    }

    if (nextBallCountdownSeconds == displaySeconds &&
        nextBallZeroForMs == zeroForMs) {
      return false;
    }

    nextBallCountdownSeconds = displaySeconds;
    nextBallZeroForMs = zeroForMs;

    return true;
  }

  void _maybeRecoverStaleNextBall({
    required GameModel game,
    required NextBallStaleEvaluation staleEvaluation,
    void Function(NextBallStaleEvaluation evaluation)? onStaleRecovery,
  }) {
    if (staleEvaluation.shouldSyncCalledNumbers &&
        !_loggedCalledNumbersStaleSync) {
      _loggedCalledNumbersStaleSync = true;
      LiveRealtimeDebug.countdownStale(
        phase: game.status.name,
        sessionId: staleEvaluation.sessionId,
        target: staleEvaluation.target,
        zeroForMs: staleEvaluation.zeroForMs,
        recovery: 'called_numbers',
      );
      onStaleRecovery?.call(staleEvaluation);
      return;
    }

    if (staleEvaluation.shouldRefetchCanonical &&
        !_loggedCanonicalStaleRefetch) {
      _loggedCanonicalStaleRefetch = true;
      LiveRealtimeDebug.countdownStale(
        phase: game.status.name,
        sessionId: staleEvaluation.sessionId,
        target: staleEvaluation.target,
        zeroForMs: staleEvaluation.zeroForMs,
        recovery: 'canonical',
      );
      onStaleRecovery?.call(staleEvaluation);
    }
  }

  void _maybeRescheduleNextBallTicker({
    required LiveCountdownTickContext Function() readContext,
    required void Function() onDisplayChanged,
    void Function(NextBallStaleEvaluation evaluation)? onStaleRecovery,
  }) {
    final context = readContext();
    final liveGame = context.game;
    if (liveGame == null) {
      return;
    }

    final target = _effectiveNextAutoCallTarget(liveGame);
    if (target == null) {
      return;
    }

    final desiredInterval = _nextBallCountdownTickInterval(
      target,
      context.autoCallActive,
    );
    if (desiredInterval == _nextBallTickerInterval) {
      return;
    }

    _startNextBallTicker(
      readContext: readContext,
      initialInterval: desiredInterval,
      onDisplayChanged: onDisplayChanged,
      onStaleRecovery: onStaleRecovery,
    );
  }

  void _startNextBallTicker({
    required LiveCountdownTickContext Function() readContext,
    required Duration initialInterval,
    required void Function() onDisplayChanged,
    void Function(NextBallStaleEvaluation evaluation)? onStaleRecovery,
  }) {
    _stopNextBallTicker(clearDisplay: false);
    _nextBallTickerInterval = initialInterval;
    nextBallCountdownTicker = Timer.periodic(_nextBallTickerInterval, (_) {
      if (!host.mounted) {
        return;
      }

      final context = readContext();
      final liveGame = context.game;
      if (liveGame == null) {
        _stopNextBallTicker(clearDisplay: false);
        return;
      }

      if (_shouldStopNextBallTicker(
        game: liveGame,
        autoCallActive: context.autoCallActive,
        allBallsDrawn: context.allBallsDrawn,
      )) {
        nextBallStaleGuard.reset();
        _clearNextBallDisplay();
        _stopNextBallTicker(clearDisplay: false);
        return;
      }

      final target = _effectiveNextAutoCallTarget(liveGame);
      if (target == null) {
        nextBallStaleGuard.reset();
        _clearNextBallDisplay();
        _stopNextBallTicker(clearDisplay: false);
        onDisplayChanged();
        return;
      }

      final displayChanged = _tickNextBallDisplay(
        context: context,
        game: liveGame,
        target: target,
        onStaleRecovery: onStaleRecovery,
      );
      if (displayChanged) {
        onDisplayChanged();
      }

      final desiredInterval = _nextBallCountdownTickInterval(
        target,
        context.autoCallActive,
      );
      if (desiredInterval != _nextBallTickerInterval) {
        scheduleMicrotask(() {
          if (!host.mounted || nextBallCountdownTicker?.isActive != true) {
            return;
          }
          _startNextBallTicker(
            readContext: readContext,
            initialInterval: desiredInterval,
            onDisplayChanged: onDisplayChanged,
            onStaleRecovery: onStaleRecovery,
          );
        });
      }
    });
    _activeNextBallTickerCount = 1;
    _assertSingleActiveNextBallTicker();
  }

  void _stopNextBallTicker({required bool clearDisplay}) {
    nextBallCountdownTicker?.cancel();
    nextBallCountdownTicker = null;
    _activeNextBallTickerCount = 0;
    _nextBallTickerInterval = const Duration(seconds: 1);
    if (!clearDisplay) {
      return;
    }
    _clearNextBallDisplay();
    _loggedCalledNumbersStaleSync = false;
    _loggedCanonicalStaleRefetch = false;
    nextBallPlayPhase = next_ball_countdown.NextBallPlayPhase.counting;
  }

  bool _clearNextBallDisplay() {
    updateBingoClaimLocked(false);
    if (nextBallCountdownSeconds == null && nextBallZeroForMs == 0) {
      return false;
    }
    nextBallCountdownSeconds = null;
    nextBallZeroForMs = 0;
    nextBallPlayPhase = next_ball_countdown.NextBallPlayPhase.counting;
    return true;
  }

  bool _shouldStopNextBallTicker({
    required GameModel game,
    required bool autoCallActive,
    required bool allBallsDrawn,
  }) {
    if (allBallsDrawn) {
      return true;
    }

    return next_ball_countdown.isNextBallCountdownInactive(
      autoCallActive: autoCallActive,
      nextAutoCallAt: _effectiveNextAutoCallTarget(game),
    );
  }

  Duration _nextBallCountdownTickInterval(
    DateTime? nextAutoCallAt,
    bool autoCallActive,
  ) {
    if (nextAutoCallAt == null) {
      return const Duration(seconds: 1);
    }

    final raw = next_ball_countdown.nextBallCountdownSeconds(
      nextAutoCallAt,
      clock: host.controllers.realtime.serverClock,
    );
    return raw <= 2
        ? const Duration(milliseconds: 250)
        : const Duration(seconds: 1);
  }

  void _assertSingleActiveNextBallTicker() {
    assert(
      _activeNextBallTickerCount <= 1,
      'activeNextBallTickerCount=$_activeNextBallTickerCount',
    );
    if (kDebugMode && _activeNextBallTickerCount > 1) {
      LiveRealtimeDebug.log(
        'activeNextBallTickerCount=$_activeNextBallTickerCount (expected <= 1)',
      );
    }
  }
}
