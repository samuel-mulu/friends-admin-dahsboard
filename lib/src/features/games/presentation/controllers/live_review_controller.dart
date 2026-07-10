import 'dart:async';

import '../../data/models/game_model.dart';
import '../../data/models/session_winner_result_model.dart';
import '../utils/live_api_failure_log.dart';
import '../utils/live_game_finish_transition.dart' as finish_transition;
import '../utils/live_presentation_phase.dart' as presentation_phase;
import '../utils/session_winner_results_for_display.dart' as winner_display;
import '../utils/winner_cartela_live_display.dart';
import '../utils/winner_pattern_clear_policy.dart';
import 'live_game_host.dart';

/// Post-game review state and winner-result coordination.
///
/// UI layers own [BuildContext] and dialog presentation; this controller
/// exposes state and lifecycle commands only.
class LiveReviewController {
  LiveReviewController(this.host);

  final LiveGameHost host;

  DateTime? postGameSummaryShownAt;
  Timer? postGameSummaryCountdownTicker;
  bool postGameSummaryReviewActive = false;
  bool postGameSummaryHoldBypassed = false;
  bool postGameSummaryAdvancing = false;
  Timer? finishTransitionTimer;
  List<SessionWinnerResultModel> sessionWinnerResults = const [];
  bool sessionWinnerResultsLoading = false;
  bool sessionWinnerResultsLoaded = false;
  Timer? sessionWinnerResultsPollTimer;
  Timer? winnerWindowPreloadPollTimer;
  bool winnerCartelaDialogVisible = false;
  String? winnerCartelaDialogAutoShownForSessionId;
  bool winnerWindowClosing = false;
  List<int> sessionWinnerCartelaNumbers = const [];
  List<int> sessionBlockedCartelaNumbers = const [];
  List<int> sessionCheckingCartelaNumbers = const [];
  final WinnerCartelaDisplayCache winnerCartelaDisplay =
      WinnerCartelaDisplayCache();

  void dispose() {
    postGameSummaryCountdownTicker?.cancel();
    finishTransitionTimer?.cancel();
    stopSessionWinnerResultsPolling();
    stopWinnerWindowPreloadPolling();
  }

  Duration get postGameSummaryHold =>
      host.effectiveTimingConfig.finishedSummaryMinimumHold;

  bool pinsTerminalSession(GameModel game) {
    return finish_transition.shouldPinTerminalSession(
      status: game.status,
      postGameSummaryReviewActive: postGameSummaryReviewActive,
    );
  }

  bool get showsPostGameSummary {
    return presentation_phase.canShowPostGameSummary(
      status: host.game?.status,
      windowEndsAt: host.controllers.countdown.effectiveWinnerWindowEndsAt(),
      postGameSummaryReviewActive: postGameSummaryReviewActive,
      now: host.countdownNow(),
    );
  }

  bool get isPostGameSummaryHoldElapsed {
    return presentation_phase.postGameSummaryHoldElapsed(
      shownAt: postGameSummaryShownAt,
      now: host.countdownNow(),
      minimumHold: postGameSummaryHold,
    );
  }

  List<SessionWinnerResultModel> sessionWinnerResultsForDisplay({
    SessionWinnerLastCalledNumber? sessionLastCalledNumber,
  }) {
    return winner_display.sessionWinnerResultsForDisplay(
      apiResults: sessionWinnerResults,
      claimPatternsByGameCartelaId:
          winnerCartelaDisplay.claimPatternsByGameCartelaId,
      sessionLastCalledNumber: sessionLastCalledNumber,
      myCartelas: host.myCartelas,
      winnerPayoutsSummary: host.game?.winnerPayoutsSummary,
    );
  }

  bool winnerResultsReadyForDialog(List<SessionWinnerResultModel> results) {
    return winner_display.winnerResultsReadyForDisplay(results);
  }

  bool hasStickyWinnerPayload() {
    return winnerCartelaDisplay.claimPatternsByGameCartelaId.values.any(
          (patterns) => patterns.isNotEmpty,
        ) ||
        winnerCartelaDisplay.patternCellsByGameCartelaId.values.any(
          (cells) => cells.isNotEmpty,
        );
  }

  bool canAutoShowWinnerDialog({
    required bool summaryOrWinnerWindowVisible,
    required List<SessionWinnerResultModel> resultsForDisplay,
  }) {
    return winner_display.winnerDialogReadyForImmediateShow(
      summaryOrWinnerWindowVisible: summaryOrWinnerWindowVisible,
      hasStickyWinnerPayload: hasStickyWinnerPayload(),
      winnerResultsLoaded: winnerResultsReadyForDialog(resultsForDisplay),
    );
  }

  void applySessionWinnerResults(List<SessionWinnerResultModel> results) {
    if (results.isEmpty) {
      return;
    }

    sessionWinnerResults = results;
    refreshWinnerDisplayFromSessionStrip();
  }

  void refreshWinnerDisplayFromSessionStrip({
    SessionWinnerLastCalledNumber? sessionLastCalledNumber,
  }) {
    if (sessionWinnerResults.isEmpty) {
      return;
    }

    for (final result in sessionWinnerResultsForDisplay(
      sessionLastCalledNumber: sessionLastCalledNumber,
    )) {
      winnerCartelaDisplay.applySessionResult(result);
    }
  }

  void clearFinishedReviewVisualState({
    WinnerPatternClearReason reason =
        WinnerPatternClearReason.clearSessionScopedReview,
  }) {
    if (!shouldClearWinnerPatterns(reason)) {
      return;
    }
    winnerCartelaDisplay.clear();
  }

  void clearFinishedReviewSessionData({
    WinnerPatternClearReason patternClearReason =
        WinnerPatternClearReason.clearSessionScopedReview,
  }) {
    clearFinishedReviewVisualState(reason: patternClearReason);
    sessionWinnerResults = const [];
    sessionWinnerResultsLoaded = false;
    sessionWinnerResultsLoading = false;
  }

  void clearSessionScopedReviewState() {
    sessionWinnerResults = const [];
    sessionWinnerResultsLoading = false;
    sessionWinnerResultsLoaded = false;
    sessionWinnerCartelaNumbers = const [];
    sessionBlockedCartelaNumbers = const [];
    sessionCheckingCartelaNumbers = const [];
    clearFinishedReviewVisualState(
      reason: WinnerPatternClearReason.sessionChanged,
    );
    winnerCartelaDialogAutoShownForSessionId = null;
    winnerWindowClosing = false;
  }

  void clearPostGameSummaryHold({
    void Function()? resetRegistrationCountdown,
    WinnerPatternClearReason patternClearReason =
        WinnerPatternClearReason.clearSessionScopedReview,
    bool clearWinnerPatterns = true,
  }) {
    winnerCartelaDialogVisible = false;
    winnerCartelaDialogAutoShownForSessionId = null;
    winnerWindowClosing = false;
    postGameSummaryReviewActive = false;
    postGameSummaryHoldBypassed = false;
    postGameSummaryAdvancing = false;
    postGameSummaryShownAt = null;
    sessionWinnerResults = const [];
    sessionWinnerResultsLoaded = false;
    sessionWinnerResultsLoading = false;
    if (clearWinnerPatterns) {
      clearFinishedReviewVisualState(reason: patternClearReason);
    }
    finishTransitionTimer?.cancel();
    finishTransitionTimer = null;
    postGameSummaryCountdownTicker?.cancel();
    postGameSummaryCountdownTicker = null;
    stopWinnerWindowPreloadPolling();
    resetRegistrationCountdown?.call();
  }

  Future<void> fetchSessionWinnerResultsIfNeeded({
    bool force = false,
    void Function()? onResultsUpdated,
  }) async {
    if (host.game?.status == GameStatus.noWinner) {
      if (host.mounted) {
        sessionWinnerResults = const [];
        sessionWinnerResultsLoaded = true;
        sessionWinnerResultsLoading = false;
        host.markNeedsBuild();
      }
      return;
    }

    final sessionId = host.game?.sessionId;
    if (sessionId == null) {
      return;
    }

    if (!force &&
        (sessionWinnerResultsLoaded || sessionWinnerResults.isNotEmpty)) {
      return;
    }

    if (sessionWinnerResultsLoading) {
      return;
    }

    sessionWinnerResultsLoading = true;
    host.markNeedsBuild();

    try {
      final response = await host.gamesRepository.getSessionWinnerResults(
        sessionId: sessionId,
      );
      if (!host.mounted) {
        return;
      }

      sessionWinnerResultsLoaded = true;
      sessionWinnerResultsLoading = false;
      if (response.isNotEmpty) {
        applySessionWinnerResults(response);
      }
      host.markNeedsBuild();
      onResultsUpdated?.call();
    } catch (error) {
      if (!host.mounted) {
        return;
      }

      logLiveApiFailure(
        error,
        method: 'GET',
        endpoint: '/games/sessions/$sessionId/winner-results',
        sessionId: sessionId,
      );

      sessionWinnerResultsLoading = false;
      host.markNeedsBuild();
    }
  }

  bool shouldPollSessionWinnerResults({
    required List<SessionWinnerResultModel> resultsForDisplay,
  }) {
    final sessionId = host.game?.sessionId;
    if (sessionId == null || !postGameSummaryReviewActive) {
      return false;
    }

    if (host.game?.status == GameStatus.noWinner) {
      return false;
    }

    return !winnerResultsReadyForDialog(resultsForDisplay);
  }

  void syncSessionWinnerResultsPolling({
    required List<SessionWinnerResultModel> resultsForDisplay,
    required Future<void> Function({bool force}) fetch,
  }) {
    sessionWinnerResultsPollTimer?.cancel();
    sessionWinnerResultsPollTimer = null;

    if (!shouldPollSessionWinnerResults(resultsForDisplay: resultsForDisplay)) {
      return;
    }

    unawaited(fetch(force: true));

    sessionWinnerResultsPollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        if (!host.mounted ||
            !shouldPollSessionWinnerResults(
              resultsForDisplay: resultsForDisplay,
            )) {
          stopSessionWinnerResultsPolling();
          return;
        }

        unawaited(fetch(force: true));
      },
    );
  }

  void stopSessionWinnerResultsPolling() {
    sessionWinnerResultsPollTimer?.cancel();
    sessionWinnerResultsPollTimer = null;
  }

  bool isWinnerWindowPreloadActive({required DateTime? windowEndsAt}) {
    if (host.game?.status != GameStatus.winnerWindow) {
      return false;
    }

    return presentation_phase.shouldPreloadWinnerResultsDuringWindow(
      windowEndsAt,
      now: host.countdownNow(),
    );
  }

  void syncWinnerWindowPreloadPolling({
    required DateTime? windowEndsAt,
    required List<SessionWinnerResultModel> resultsForDisplay,
    required Future<void> Function({bool force}) fetch,
  }) {
    winnerWindowPreloadPollTimer?.cancel();
    winnerWindowPreloadPollTimer = null;

    if (!isWinnerWindowPreloadActive(windowEndsAt: windowEndsAt)) {
      return;
    }

    if (winnerResultsReadyForDialog(resultsForDisplay)) {
      return;
    }

    unawaited(fetch(force: true));

    winnerWindowPreloadPollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        if (!host.mounted ||
            !isWinnerWindowPreloadActive(windowEndsAt: windowEndsAt)) {
          stopWinnerWindowPreloadPolling();
          return;
        }

        final latestResults = sessionWinnerResultsForDisplay();
        if (winnerResultsReadyForDialog(latestResults)) {
          stopWinnerWindowPreloadPolling();
          return;
        }

        unawaited(fetch(force: true));
      },
    );
  }

  void stopWinnerWindowPreloadPolling() {
    winnerWindowPreloadPollTimer?.cancel();
    winnerWindowPreloadPollTimer = null;
  }

  void startPostGameSummary({
    required bool scheduleAdvance,
    required void Function() onStarted,
    required void Function() scheduleAdvanceToNextGame,
  }) {
    final started = !postGameSummaryReviewActive;
    postGameSummaryReviewActive = true;
    postGameSummaryHoldBypassed = false;
    postGameSummaryAdvancing = false;
    if (started) {
      postGameSummaryShownAt = host.countdownNow();
      syncPostGameSummaryCountdownTicker();
      onStarted();
    }
    if (scheduleAdvance) {
      scheduleAdvanceToNextGame();
    }
  }

  void syncPostGameSummaryCountdownTicker() {
    postGameSummaryCountdownTicker?.cancel();
    postGameSummaryCountdownTicker = null;
    if (!showsPostGameSummary) {
      return;
    }

    void tick() {
      if (!host.mounted) {
        return;
      }
      host.markNeedsBuild();
      if (presentation_phase.postGameSummaryHoldElapsed(
        shownAt: postGameSummaryShownAt,
        now: host.countdownNow(),
        minimumHold: postGameSummaryHold,
      )) {
        postGameSummaryCountdownTicker?.cancel();
        postGameSummaryCountdownTicker = null;
      }
    }

    tick();
    postGameSummaryCountdownTicker = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => tick(),
    );
  }

  void beginPostGameSummaryAdvance() {
    if (!postGameSummaryReviewActive || postGameSummaryAdvancing) {
      return;
    }

    winnerCartelaDialogVisible = false;
    // Policy: patterns stay sticky through advance until sessionChanged apply.
    clearFinishedReviewVisualState(
      reason: WinnerPatternClearReason.postGameAdvanceBegin,
    );
    finishTransitionTimer?.cancel();
    finishTransitionTimer = null;
    postGameSummaryCountdownTicker?.cancel();
    postGameSummaryCountdownTicker = null;
    postGameSummaryHoldBypassed = true;
    postGameSummaryAdvancing = true;
    host.markNeedsBuild();
  }

  void scheduleAdvanceToNextGame({
    required Future<void> Function({bool force}) runFinishedAdvanceSequence,
  }) {
    finishTransitionTimer?.cancel();

    final delay = postGameSummaryReviewActive && !postGameSummaryHoldBypassed
        ? presentation_phase.postGameSummaryRemainingHold(
            shownAt: postGameSummaryShownAt ?? host.countdownNow(),
            now: host.countdownNow(),
            minimumHold: postGameSummaryHold,
          )
        : Duration.zero;
    if (postGameSummaryReviewActive && postGameSummaryShownAt == null) {
      postGameSummaryShownAt = host.countdownNow();
    }

    finishTransitionTimer = Timer(delay, () {
      if (!host.mounted) {
        return;
      }
      unawaited(runFinishedAdvanceSequence());
    });
  }
}
