part of 'live_game_screen.dart';

mixin _LiveGameOrchestration on _LiveGameScreenStateBase {
  LiveTransitionController get _transition => controllers.transition;
  LiveCountdownController get _countdown => controllers.countdown;
  LiveRealtimeController get _realtime => controllers.realtime;

  @override
  Future<void> runResumeSync({bool allowCachedOperations = true}) {
    return _loadInitialState(
      showLoading: false,
      includeCalledNumbers: true,
      includeMyCartelas: !_isGuest,
      allowTerminalTransition: true,
      resumeSync: true,
      allowCachedOperations: allowCachedOperations,
    );
  }

  @override
  Future<void> runInitialLoad({
    bool showLoading = true,
    bool includeCalledNumbers = true,
    bool includeMyCartelas = true,
    bool allowTerminalTransition = false,
    GameModel? advanceTarget,
  }) {
    return _loadInitialState(
      showLoading: showLoading,
      includeCalledNumbers: includeCalledNumbers,
      includeMyCartelas: includeMyCartelas,
      allowTerminalTransition: allowTerminalTransition,
      advanceTarget: advanceTarget,
    );
  }

  /// Backend registration deadline for the countdown, confirmed by the latest
  /// canonical operations refetch for the active session.
  DateTime? get _effectiveRegistrationDeadline {
    return _countdown.effectiveRegistrationDeadline(
      canonicalRefetchInFlight: _realtime.canonicalRefetchInFlight,
      postGameSummaryHoldActive: _review.postGameSummaryReviewActive,
      blockingLiveGameExists: _currentReadyCountdownDeferredByLiveGame,
    );
  }

  void _syncRegistrationCountdownDeadline({required GameModel game}) {
    _countdown.syncRegistrationCountdownDeadline(game: game);
  }

  void _clearRegistrationCountdownDeadline() {
    _countdown.clearRegistrationCountdownDeadline();
  }

  void _clearReadyTransitionLock() => _transition.clearReadyTransitionLock();

  void _syncReadyTransitionLock({
    required GameOperationsCurrentResponse? operations,
    required GameModel? mergedGame,
  }) =>
      _transition.syncReadyTransitionLock(
        operations: operations,
        mergedGame: mergedGame,
      );

  void _syncOpenRegistrationBeatsTransitionLock({
    GameOperationsCurrentResponse? operations,
  }) =>
      _transition.syncOpenRegistrationBeatsTransitionLock(operations: operations);

  void _expireReadyTransitionLockIfNeeded() =>
      _transition.expireReadyTransitionLockIfNeeded();

  /// Backend deadline for the winner-window countdown (never estimated locally).
  DateTime? get _effectiveWinnerWindowEndsAt {
    if (_game?.status != GameStatus.winnerWindow) {
      return null;
    }

    return _game?.winnerWindowEndsAt ?? _countdown.winnerWindowEndsAt;
  }

  int get _effectiveBulkSelectionSeconds {
    final configured = _bulkSelectionSeconds;
    final deadline = _effectiveRegistrationDeadline;
    if (deadline == null) {
      return configured;
    }

    final remaining = secondsUntilCeil(deadline, clock: _serverClock);
    if (remaining <= 0) {
      return configured;
    }

    return remaining < configured ? remaining : configured;
  }

  bool get _winnerWindowExpired => isWinnerWindowExpired(
    status: _game?.status,
    windowEndsAt: _effectiveWinnerWindowEndsAt,
    now: _countdownNow(),
  );

  bool _shouldPinTerminalSession(GameModel game) {
    return _review.pinsTerminalSession(game);
  }

  bool _isSameRound(GameModel candidate, GameModel? current) {
    if (current == null) {
      return false;
    }
    if (candidate.id == current.id) {
      return true;
    }
    final currentSessionId = current.sessionId;
    final candidateSessionId = candidate.sessionId;
    return currentSessionId != null &&
        candidateSessionId != null &&
        currentSessionId == candidateSessionId;
  }

  GameModel? _resolveQueueUpcomingGame(
    GameOperationsCurrentResponse? operations, {
    required GameModel? current,
  }) {
    if (operations == null) {
      return null;
    }

    final primary = operations.nextUpcomingGameFor(current: current);
    if (primary != null && !primary.isBigGame) {
      return primary;
    }

    for (final candidate in [
      operations.registrationOpenGame,
      ...operations.queue,
    ]) {
      if (candidate == null) {
        continue;
      }
      if (candidate.isBigGame || _isSameRound(candidate, current)) {
        continue;
      }
      return candidate;
    }

    return null;
  }

  bool _operationsConfirmNoCurrentOrQueuedGame(
    GameOperationsCurrentResponse? operations, {
    required GameModel? current,
  }) {
    if (operations == null) {
      return false;
    }

    return !operations.hasActiveGame &&
        operations.nextUpcomingGameFor(current: current) == null;
  }

  void _enterFinishedReviewFromExpiredWindow() {
    final game = _game;
    if (game == null ||
        game.status != GameStatus.winnerWindow ||
        !_winnerWindowExpired ||
        _review.winnerWindowClosing ||
        _review.postGameSummaryReviewActive) {
      return;
    }

    _review.winnerWindowClosing = true;
    _review.stopWinnerWindowPreloadPolling();

    _realtime.requestTerminalCanonicalRefetch(
      reason: 'winner_window_expired',
      wallet: !_isGuest,
      registrationSessionId: game.sessionId,
      includeCalledNumbers: true,
      includeMyCartelas: false,
    );
  }

  bool get _showsPostGameSummary => _review.showsPostGameSummary;

  static final RegExp _sessionIdPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  bool _looksLikeSessionId(String value) {
    return _sessionIdPattern.hasMatch(value.trim());
  }

  void _joinSessionRoomEarly(String? sessionId) {
    if (sessionId == null || !_looksLikeSessionId(sessionId)) {
      return;
    }

    _applySocketSessionMembership(sessionId);
  }

  void _applySocketSessionMembership(String? sessionId) {
    _socketMembership.apply(
      sessionId,
      join: _socketService.joinGame,
      leave: _socketService.leaveGame,
    );
    _joinedGameId = _socketMembership.joinedSessionId;
    _syncActiveCartelasToProvider();
  }

  void _clearSessionScopedPlayState({
    required bool clearCartelas,
    bool clearCalledNumbers = true,
    bool clearManualMarks = true,
  }) {
    if (clearCartelas) {
      _myCartelas = const [];
      _clearMyCartelaDisplayOrder();
      _gameInfoExpanded = false;
      _syncActiveCartelasToProvider();
      _review.clearSessionScopedReviewState();
      _cn.blockedCartelaFrozenMarks.clear();
      _cn.blockedCartelaFrozenSortResults.clear();
      _cn.blockedCartelaReasonCodeById.clear();
      _cn.blockedCartelaServerReasonById.clear();
      _cn.cartelaSortSignature = null;
    }
    _pendingWinnerWindowPayload = null;
    _pendingBingoInvalidPayload = null;
    _cn.clearSessionScopedState(
      clearCalledNumbers: clearCalledNumbers,
      clearManualMarks: clearManualMarks,
    );
    _countdown.registrationCountdownClosed = false;
    _transition.clearReadyTransitionLock();
  }

  void _resetNextBallCountdownState() {
    _countdown.resetNextBallState();
    _cn.socketAutoCallEnabled = null;
  }

  void _storeWinningPatternCells({
    required String gameCartelaId,
    required List<CompletedPatternModel> patterns,
    List<List<String>>? columns,
    SessionWinnerLastCalledNumber? lastCalledNumber,
  }) {
    _review.winnerCartelaDisplay.storePatterns(
      gameCartelaId: gameCartelaId,
      patterns: patterns,
      columns: columns,
      lastCalledNumber: lastCalledNumber,
    );
  }

  void _storeClaimWinningSnapshot({
    required String gameCartelaId,
    required List<CompletedPatternModel> patterns,
    List<List<String>>? columns,
    SessionWinnerLastCalledNumber? lastCalledNumber,
  }) {
    _review.winnerCartelaDisplay.storeClaimSnapshot(
      gameCartelaId: gameCartelaId,
      patterns: patterns,
      columns: columns ?? _columnsForGameCartela(gameCartelaId),
      lastCalledNumber: lastCalledNumber,
    );
  }

  List<List<String>>? _columnsForGameCartela(String gameCartelaId) {
    for (final cartela in _myCartelas) {
      if (cartela.id == gameCartelaId) {
        return cartela.cartela.columns;
      }
    }
    return null;
  }

  SessionWinnerLastCalledNumber? _sessionLastCalledNumberFromStrip() =>
      _cn.sessionLastCalledNumberFromStrip();

  List<SessionWinnerResultModel> get _sessionWinnerResultsForDisplay {
    return _review.sessionWinnerResultsForDisplay(
      sessionLastCalledNumber: _showsPostGameSummary
          ? _sessionLastCalledNumberFromStrip()
          : null,
    );
  }

  void _applySessionWinnerResults(List<SessionWinnerResultModel> results) {
    _review.applySessionWinnerResults(results);
  }

  void _refreshWinnerDisplayFromSessionStrip() {
    _review.refreshWinnerDisplayFromSessionStrip(
      sessionLastCalledNumber: _showsPostGameSummary
          ? _sessionLastCalledNumberFromStrip()
          : null,
    );
  }

  void _showWinnerCartelaDialogForReview(
    List<SessionWinnerResultModel> results,
  ) {
    if (!mounted || results.isEmpty) {
      return;
    }

    _review.winnerCartelaDialogVisible = true;
    setState(() {});
    unawaited(
      showWinnerCartelaDialog(context: context, results: results).whenComplete(
        () {
          if (mounted) {
            setState(() => _review.winnerCartelaDialogVisible = false);
          } else {
            _review.winnerCartelaDialogVisible = false;
          }
        },
      ),
    );
  }

  void _dismissWinnerCartelaDialogIfOpen() {
    if (!mounted || !_review.winnerCartelaDialogVisible) {
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
    _review.winnerCartelaDialogVisible = false;
  }

  void _applySessionOutcomeFromGame(GameModel? game) {
    final summary = game?.sessionOutcomeSummary;
    if (summary == null) {
      return;
    }

    _review.sessionWinnerCartelaNumbers = summary.winnerCartelaNumbers;
    _review.sessionBlockedCartelaNumbers = summary.blockedCartelaNumbers;
  }

  String? _preferredSocketSessionId({
    required GameModel primaryGame,
    required GameOperationsCurrentResponse? operations,
  }) {
    final syncGame = resolveCalledNumbersSyncGame(
      operations: operations,
      primaryGame: primaryGame,
    );
    if (syncGame?.sessionId != null) {
      return syncGame!.sessionId;
    }
    if (isTerminalGameStatus(primaryGame.status)) {
      return null;
    }
    return primaryGame.sessionId;
  }

  void _recordSessionWinnerCartelaNumber(int cartelaNumber) {
    _review.sessionWinnerCartelaNumbers = mergeSortedCartelaNumbers([
      ..._review.sessionWinnerCartelaNumbers,
      cartelaNumber,
    ]);
    _clearSessionCheckingCartelaNumber(cartelaNumber);
  }

  void _recordSessionBlockedCartelaNumber(int cartelaNumber) {
    _review.sessionBlockedCartelaNumbers = mergeSortedCartelaNumbers([
      ..._review.sessionBlockedCartelaNumbers,
      cartelaNumber,
    ]);
    _review.sessionCheckingCartelaNumbers = _review.sessionCheckingCartelaNumbers
        .where((number) => number != cartelaNumber)
        .toList(growable: false);
  }

  void _recordSessionCheckingCartelaNumber(int cartelaNumber) {
    _review.sessionCheckingCartelaNumbers = mergeSortedCartelaNumbers([
      ..._review.sessionCheckingCartelaNumbers,
      cartelaNumber,
    ]);
  }

  void _clearSessionCheckingCartelaNumber(int cartelaNumber) {
    _review.sessionCheckingCartelaNumbers = _review.sessionCheckingCartelaNumbers
        .where((number) => number != cartelaNumber)
        .toList(growable: false);
  }

  bool get _isAnyClaimChecking => _cn.isAnyClaimChecking(
    hasSessionCheckingCartelaNumbers:
        _review.sessionCheckingCartelaNumbers.isNotEmpty,
  );

  bool get _isAutoCallActiveForSession {
    final game = _game;
    if (game == null) {
      return false;
    }

    if (_cn.socketAutoCallEnabled == false) {
      return false;
    }

    if (_allBallsDrawnForCurrentGame && game.nextAutoCallAt == null) {
      return false;
    }

    return _cn.socketAutoCallEnabled ?? game.operationMode.toUpperCase() == 'AUTO';
  }

  int get _highestKnownCalledOrder => _cn.highestKnownCalledOrder;

  bool get _allBallsDrawnForCurrentGame => isAllBallsDrawn(
    calledNumbersCount: _game?.calledNumbersCount,
    localCalledCount: _cn.calledNumbers.length,
    highestCalledOrder: _highestKnownCalledOrder,
  );

  bool get _isBingoClaimCountdownLocked {
    if (_game?.status == GameStatus.winnerWindow && !_winnerWindowExpired) {
      return false;
    }

    return isBingoClaimCountdownLocked(
      gameStatus: _game?.status,
      autoCallActive: _isAutoCallActiveForSession,
      nextAutoCallAt: _countdown.effectiveNextAutoCallAt(_game),
      clock: _serverClock,
      playPhase: _countdown.nextBallPlayPhase,
      highestKnownCalledOrder: _highestKnownCalledOrder,
      callingPhaseBaselineOrder: _countdown.callingPhaseBaselineOrder,
    );
  }

  bool get _showFinishedCartelaOutcome {
    return _showsPostGameSummary ||
        _livePresentationPhase == LivePresentationPhase.review;
  }

  LiveCountdownTickContext _liveCountdownTickContext() {
    return LiveCountdownTickContext(
      game: _game,
      presentationPhase: _livePresentationPhase,
      isAnyClaimChecking: _isAnyClaimChecking,
      isSyncingCalledNumbers: _cn.isSyncingCalledNumbers,
      autoCallActive: _isAutoCallActiveForSession,
      allBallsDrawn: _allBallsDrawnForCurrentGame,
      connectionStatus: ref.read(realtimeConnectionProvider),
      socketAutoCallEnabled: _cn.socketAutoCallEnabled,
      winnerWindowExpired: _winnerWindowExpired,
      effectiveWinnerWindowEndsAt: _effectiveWinnerWindowEndsAt,
      shouldRunWinnerWindowTicker:
          _game?.status == GameStatus.winnerWindow &&
          _effectiveWinnerWindowEndsAt != null,
      highestKnownCalledOrder: _highestKnownCalledOrder,
    );
  }

  void _syncNextBallCountdownTicker() {
    _countdown.syncNextBallTicker(
      _liveCountdownTickContext,
      onDisplayChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
      onStaleRecovery: _handleNextBallStaleRecovery,
    );
  }

  void _handleNextBallStaleRecovery(NextBallStaleEvaluation evaluation) {
    if (evaluation.shouldSyncCalledNumbers) {
      _countdown.nextBallStaleGuard.recordCalledNumbersSync(
        evaluation.sessionId,
      );
      LiveRealtimeDebug.refetch(
        'stale_called_numbers',
        status: _game?.status.name,
        calledCount: _game?.calledNumbersCount,
      );
      unawaited(
        _cn.refetchCalledNumbersOnly().whenComplete(() {
          if (!mounted) {
            return;
          }
          _syncNextBallCountdownTicker();
        }),
      );
      return;
    }

    if (evaluation.shouldRefetchCanonical) {
      _countdown.nextBallStaleGuard.recordCanonicalRefetch(
        evaluation.sessionId,
      );
      LiveRealtimeDebug.refetch(
        'stale_next_ball',
        status: _game?.status.name,
        calledCount: _game?.calledNumbersCount,
      );
      unawaited(
        _refetchCanonicalImmediate(includeCalledNumbers: true).whenComplete(() {
          if (!mounted) {
            return;
          }
          _syncNextBallCountdownTicker();
        }),
      );
    }
  }

  bool get _cartelaMarksFrozenForEvidence {
    if (_livePresentationPhase == LivePresentationPhase.winnerWindow ||
        _game?.status == GameStatus.winnerWindow) {
      return true;
    }

    if (_showsPostGameSummary ||
        _livePresentationPhase == LivePresentationPhase.review) {
      return true;
    }

    return false;
  }

  bool get _stripShowsWinnerOnly {
    if (_review.sessionWinnerCartelaNumbers.isEmpty) {
      return false;
    }

    final phase = _livePresentationPhase;
    return phase == LivePresentationPhase.checking ||
        phase == LivePresentationPhase.winnerWindow;
  }

  int? _cartelaNumberFromPayload(Map<String, dynamic> payload) {
    final raw = payload['cartelaNumber'];
    if (raw is num) {
      return raw.toInt();
    }
    return null;
  }

  String? _prizeAmountForGameCartela(GameCartelaModel cartela) {
    for (final result in _review.sessionWinnerResults) {
      if (result.gameCartelaId == cartela.id) {
        return result.amount;
      }
    }

    final payouts = _game?.winnerPayoutsSummary;
    if (payouts == null) {
      return null;
    }

    for (final payout in payouts) {
      if (payout.cartelaId == cartela.cartelaId ||
          payout.cartelaNumber == cartela.cartela.number) {
        return payout.amount;
      }
    }

    return null;
  }

  Future<void> _fetchSessionWinnerResultsIfNeeded({bool force = false}) {
    return _review.fetchSessionWinnerResultsIfNeeded(
      force: force,
      onResultsUpdated: () {
        _syncSessionWinnerResultsPolling();
        if (_review.winnerResultsReadyForDialog(
          _sessionWinnerResultsForDisplay,
        )) {
          _review.stopWinnerWindowPreloadPolling();
        }
        _maybeAutoShowWinnerCartelaDialog();
      },
    );
  }

  void _maybeAutoShowWinnerCartelaDialog() {
    if (_review.winnerCartelaDialogVisible) {
      return;
    }

    // Winner modal is finished/post-summary only — never during WINNER_WINDOW.
    if (!_showsPostGameSummary) {
      return;
    }

    final sessionId = _game?.sessionId;
    if (sessionId == null ||
        _review.winnerCartelaDialogAutoShownForSessionId == sessionId) {
      return;
    }

    // Wait for canonical winner-results so prizes/cartela numbers are real
    // (sticky claim snapshots alone produced cartela #0 / 0 ETB).
    if (!_review.sessionWinnerResultsLoaded) {
      return;
    }

    final results = _sessionWinnerResultsForDisplay;
    if (!_review.canAutoShowWinnerDialog(
      postGameSummaryVisible: true,
      resultsForDisplay: results,
    )) {
      return;
    }
    if (!_review.winnerResultsReadyForDialog(results)) {
      return;
    }

    _review.winnerCartelaDialogAutoShownForSessionId = sessionId;
    _showWinnerCartelaDialogForReview(results);
  }

  Future<void> _onWinnerCartelaChipTapped(int cartelaNumber) async {
    if (_review.winnerCartelaDialogVisible) {
      return;
    }

    // Modal is finished-review only; block taps during WINNER_WINDOW / live.
    if (!_showsPostGameSummary) {
      return;
    }

    var results = _sessionWinnerResultsForDisplay;
    if (!_review.winnerResultsReadyForDialog(results)) {
      await _fetchSessionWinnerResultsIfNeeded(force: true);
      if (!mounted) {
        return;
      }
      results = _sessionWinnerResultsForDisplay;
    }

    if (_review.winnerResultsReadyForDialog(results)) {
      final filtered = results
          .where((result) => result.cartelaNumber == cartelaNumber)
          .toList(growable: false);
      _showWinnerCartelaDialogForReview(
        filtered.isNotEmpty ? filtered : results,
      );
    }
  }

  void _maybeAutoExpandForQueuedNextGame() {
    if (!_liveUiMode.showsInlinePlayCartelas || _suppressNextGameQueueHint) {
      return;
    }

    final next = _nextUpcomingGame;
    final current = _game;
    if (next == null || current == null) {
      return;
    }

    final nextSessionId = next.sessionId;
    final currentSessionId = current.sessionId;
    if (nextSessionId == null ||
        nextSessionId.isEmpty ||
        nextSessionId == currentSessionId) {
      return;
    }

    if (next.status != GameStatus.ready || !next.canRegister) {
      return;
    }

    if (_autoExpandedForNextGameSessionId == nextSessionId) {
      return;
    }

    _autoExpandedForNextGameSessionId = nextSessionId;
    if (!_gameInfoExpanded) {
      setState(() => _gameInfoExpanded = true);
    }
  }

  bool get _shouldPollSessionWinnerResults {
    return _review.shouldPollSessionWinnerResults(
      resultsForDisplay: _sessionWinnerResultsForDisplay,
    );
  }

  Future<void> _prefetchNextRegistrationDuringReview() async {
    final current = _game;
    if (current == null || !_review.postGameSummaryReviewActive) {
      return;
    }

    try {
      final operations = await _gamesRepository.getCurrentGameOperations();
      if (!mounted || !_review.postGameSummaryReviewActive) {
        return;
      }

      final nextGame = _resolveQueueUpcomingGame(operations, current: current);
      var nextCartelas = const <GameCartelaModel>[];
      final nextSessionId = nextGame?.sessionId;
      if (!_isGuest &&
          nextSessionId != null &&
          nextSessionId.isNotEmpty &&
          nextSessionId != current.sessionId) {
        try {
          nextCartelas = await _gamesRepository.getMyGameCartelas(
            nextSessionId,
          );
          nextCartelas = List<GameCartelaModel>.from(nextCartelas)
            ..sort((left, right) {
              return left.cartela.number.compareTo(right.cartela.number);
            });
        } catch (_) {
          nextCartelas = const [];
        }
      }

      if (!mounted || !_review.postGameSummaryReviewActive) {
        return;
      }

      setState(() {
        _nextUpcomingGame = nextGame;
        _nextRegistrationCartelas = nextCartelas;
      });
      _maybeAutoExpandForQueuedNextGame();

      if (_livePresentationPhase.isCancelledTerminal &&
          nextGame?.status == GameStatus.ready &&
          (nextGame?.canRegister ?? false)) {
        unawaited(_runFinishedAdvanceSequence(force: true));
      }
    } catch (_) {}
  }

  void _syncSessionWinnerResultsPolling() {
    _review.syncSessionWinnerResultsPolling(
      resultsForDisplay: _sessionWinnerResultsForDisplay,
      fetch: _fetchSessionWinnerResultsIfNeeded,
    );
  }

  void _stopSessionWinnerResultsPolling() {
    _review.stopSessionWinnerResultsPolling();
  }

  void _handleRegistrationCountdownClosed() =>
      _transition.handleRegistrationCountdownClosed();

  void _syncPreparingPhasePolling() => _transition.syncPreparingPhasePolling();

  void _stopPreparingPhasePolling() => _transition.stopPreparingPhasePolling();

  void _syncRegistrationCountdownClosedState({GameModel? game}) =>
      _transition.syncRegistrationCountdownClosedState(game: game);

  void _logPresentationPhaseIfChanged({String? detail}) {
    final phase = _livePresentationPhase;
    if (_lastDebugPhase == phase) {
      return;
    }

    LiveRealtimeDebug.phase(
      _lastDebugPhase?.name ?? 'none',
      phase.name,
      detail: detail,
    );
    _lastDebugPhase = phase;
  }

  void _onGameCancelled(dynamic payload) {
    if (!mounted) {
      return;
    }

    final normalizedPayload = _normalizeSocketPayloadForEvent(
      payload,
      eventName: 'game:cancelled',
      includeCalledNumbers: true,
    );
    if (normalizedPayload == null) {
      return;
    }

    final sessionId = normalizedPayload['sessionId'] as String?;
    final slotId = normalizedPayload['slotId'] as String?;
    if (!_eventAffectsCurrentGame(sessionId: sessionId, slotId: slotId)) {
      return;
    }

    if (!shouldRunCancelTransition(
      currentStatus: _game?.status,
      sessionRoomActive: _joinedGameId != null,
    )) {
      return;
    }

    _realtime.requestTerminalCanonicalRefetch(
      reason: 'game_cancelled',
      wallet: !_isGuest,
      registrationSessionId: _game?.sessionId,
      includeCalledNumbers: true,
      includeMyCartelas: false,
    );
  }

  /// Runs terminal review side effects once after canonical apply already set
  /// FINISHED / NO_WINNER status — avoids a second status mutation.
  void _runTerminalSideEffectsAfterCanonicalApply(GameModel game) {
    if (!isTerminalGameStatus(game.status)) {
      return;
    }

    _review.winnerWindowClosing = false;

    final shouldRunTransition = game.status == GameStatus.cancelled
        ? shouldRunCancelTransition(
            currentStatus: game.status,
            sessionRoomActive: _joinedGameId != null,
          )
        : shouldRunFinishTransition(
            currentStatus: game.status,
            sessionRoomActive: _joinedGameId != null,
            summaryScheduled: _review.postGameSummaryReviewActive,
          );

    if (!shouldEnterTerminalSideEffects(
      alreadyInSummary: _review.postGameSummaryReviewActive,
      sessionRoomActive: _joinedGameId != null,
      shouldRunTransition: shouldRunTransition,
    )) {
      return;
    }

    if (_joinedGameId != null) {
      _applySocketSessionMembership(null);
    }

    if (game.status == GameStatus.noWinner) {
      setState(() {
        _clearSessionScopedPlayState(
          clearCartelas: false,
          clearCalledNumbers: false,
          clearManualMarks: false,
        );
        _review.sessionWinnerResults = const [];
        _review.sessionWinnerResultsLoaded = true;
        _review.sessionWinnerResultsLoading = false;
        _countdown.winnerWindowEndsAt = null;
      });
      _stopSessionWinnerResultsPolling();
    } else if (game.status == GameStatus.finished) {
      setState(() {
        _clearSessionScopedPlayState(
          clearCartelas: false,
          clearCalledNumbers: false,
          clearManualMarks: false,
        );
        if (game.winnerCartelaId != null) {
          _myCartelas = _myCartelas
              .map((cartela) {
                if (cartela.isWinner || cartela.id == game.winnerCartelaId) {
                  return cartela.copyWith(
                    status: GameCartelaStatus.winner,
                    isWinner: true,
                    blockedAt: null,
                  );
                }
                return cartela;
              })
              .toList(growable: false);
        }
        _countdown.winnerWindowEndsAt = null;
      });
      unawaited(_fetchSessionWinnerResultsIfNeeded(force: true));
    }

    _syncWinnerWindowTicker();
    _syncNextBallCountdownTicker();
    _sortMyCartelas();
    _syncCalledNumbersForFinishedReview();

    if (game.status == GameStatus.finished ||
        game.status == GameStatus.noWinner) {
      _startPostGameSummary(scheduleAdvance: true);
    }
  }

  bool _isCurrentLoad(int generation) =>
      mounted && generation == _loadGeneration;

  void _safeSetState(int generation, VoidCallback fn) {
    if (_isCurrentLoad(generation)) {
      setState(fn);
    }
  }

  Future<void> _loadInitialState({
    bool showLoading = true,
    bool includeCalledNumbers = true,
    bool includeMyCartelas = true,
    bool allowTerminalTransition = false,
    GameModel? advanceTarget,
    bool resumeSync = false,
    bool allowCachedOperations = true,
  }) async {
    final generation = ++_loadGeneration;
    final priorSessionId = _game?.sessionId;
    final priorCalledCount = _cn.calledNumbers.length;

    if (resumeSync) {
      _countdown.serverClockSnapOnNextSync = true;
    }

    if (showLoading || _game == null) {
      _safeSetState(generation, () {
        _isLoading = showLoading;
        _errorMessage = null;
        if (showLoading) {
          _emptyMessage = null;
        }
      });
    }

    try {
      if (resumeSync ||
          !_timingConfigLoaded ||
          !_shouldCacheTimingConfigForLivePlay) {
        final timingConfig = await _gamesRepository.getTimeConfig();
        if (!_isCurrentLoad(generation)) {
          return;
        }

        if (resumeSync) {
          _timingConfig = timingConfig;
          _timingConfigLoaded = true;
        } else {
          _safeSetState(generation, () {
            _timingConfig = timingConfig;
            _timingConfigLoaded = true;
          });
        }
        if (timingConfig.serverNow != null) {
          _syncServerClockFromUtc(
            timingConfig.serverNow!,
            snap: resumeSync,
            ignoreOlder: !resumeSync,
          );
        }
      }

      GameOperationsCurrentResponse? operations;
      final skipOperationsBootstrap =
          !resumeSync &&
          widget.embedded &&
          widget.gameId != null &&
          widget.initialGame != null;
      if (!skipOperationsBootstrap) {
        try {
          if (resumeSync && allowCachedOperations) {
            operations = await _loadResumeOperationsCurrent();
          } else {
            operations = await _gamesRepository.getCurrentGameOperations();
          }
        } catch (_) {
          operations = null;
        }
      } else if (widget.initialGame != null) {
        final serverNow = ref.read(serverClockProvider).nowUtc();
        operations = localOperationsSnapshotForGame(
          widget.initialGame!,
          serverNow: serverNow,
        );
      }
      if (!_isCurrentLoad(generation)) {
        return;
      }
      if (operations != null) {
        _syncServerClockFromUtc(
          operations.serverNow,
          snap: resumeSync,
          ignoreOlder: !resumeSync,
        );
        if (resumeSync) {
      LiveRealtimeDebug.resumeSyncOpsApplied(
            liveStatus: operations.liveGame?.status.name,
            registrationStatus:
                operations.registrationOpenGame?.status.name,
            sessionId: operations.liveGame?.sessionId ??
                operations.checkingGame?.sessionId ??
                operations.registrationOpenGame?.sessionId,
            calledCount: operations.liveGame?.calledNumbersCount ??
                operations.checkingGame?.calledNumbersCount,
          );
          LiveRealtimeDebug.log('resume_sync_operations_loaded');
        }
      }

      final loadSelection = await _loadGame(
        operations: operations,
        advanceTarget: resumeSync ? null : (widget.initialGame ?? advanceTarget),
        allowOwnershipLookup: resumeSync ||
            includeMyCartelas ||
            showLoading ||
            _game == null,
      );
      final game = loadSelection.game;
      final preloadedPrimaryCartelas = loadSelection.preloadedPrimaryCartelas;
      if (!_isCurrentLoad(generation)) {
        return;
      }

      final priorGame = _game;
      final effectiveAllowTerminalTransition =
          resumeSync || allowTerminalTransition;
      final holdingTerminalSummary =
          !effectiveAllowTerminalTransition &&
          priorGame != null &&
          _shouldPinTerminalSession(priorGame);
      if (holdingTerminalSummary &&
          (game == null || game.sessionId != priorGame.sessionId)) {
        _safeSetState(generation, () {
          _nextUpcomingGame = _resolveQueueUpcomingGame(
            operations,
            current: priorGame,
          );
          _nextRegistrationCartelas = const [];
          _isLoading = false;
          if (resumeSync) {
            _realtime.canonicalRefetchInFlight = false;
          }
        });
        _maybeAutoExpandForQueuedNextGame();
        if (_review.postGameSummaryReviewActive) {
          unawaited(_prefetchNextRegistrationDuringReview());
        }
        _evaluateLiveRoomSplash();
        return;
      }

      if (game == null) {
        final confirmedEmpty = _operationsConfirmNoCurrentOrQueuedGame(
          operations,
          current: priorGame,
        );
        if (shouldKeepTransitionLockShell(
          lock: _readyTransitionLockActive ? _transition.readyTransitionLock : null,
          currentGame: _game,
          incomingGame: null,
          now: _countdownNow(),
        )) {
          _safeSetState(generation, () {
            _isLoading = false;
            _errorMessage = null;
            _emptyMessage = null;
            _countdown.registrationCountdownClosed = true;
            if (resumeSync) {
              _realtime.canonicalRefetchInFlight = false;
            }
          });
          if (!_transition.lockTimeoutRefetchScheduled &&
              !_realtime.canonicalRefetchInFlight) {
            _transition.lockTimeoutRefetchScheduled = true;
            unawaited(
              _refetchCanonicalImmediate(
                includeCalledNumbers: false,
                registrationSessionId: _transition.readyTransitionLock?.sessionId,
              ),
            );
          }
          _evaluateLiveRoomSplash();
          return;
        }

        if (!confirmedEmpty && priorGame != null) {
          _safeSetState(generation, () {
            _errorMessage = null;
            _emptyMessage = null;
            _lastOperations = operations;
            _nextUpcomingGame = _resolveQueueUpcomingGame(
              operations,
              current: priorGame,
            );
            _isLoading = false;
            if (resumeSync) {
              _realtime.canonicalRefetchInFlight = false;
            }
          });
          _maybeAutoExpandForQueuedNextGame();
          _evaluateLiveRoomSplash();
          return;
        }

        // Terminal transition hold (CANCELLED / FINISHED / NO_WINNER -> READY):
        // the backend can briefly report no current/queued game between emitting
        // the terminal event and opening the next READY registration. Do NOT
        // tear down the UI on that transient gap.
        if (priorGame != null &&
            (isTerminalTransitionActive ||
                shouldHoldTerminalPaint(
                  priorGame: priorGame,
                  operations: operations,
                ))) {
          _safeSetState(generation, () {
            _isLoading = false;
            _errorMessage = null;
            _emptyMessage = null;
            if (resumeSync) {
              _realtime.canonicalRefetchInFlight = false;
            }
          });
          _evaluateLiveRoomSplash();
          return;
        }

        _expireReadyTransitionLockIfNeeded();
        _applySocketSessionMembership(null);
        final waitingForRealtime = !_socketService.isConnected;
        _safeSetState(generation, () {
          _clearReadyTransitionLock();
          _game = null;
          _lastOperations = null;
          _nextUpcomingGame = null;
          _nextRegistrationCartelas = const [];
          _cn.calledNumbers = const [];
          _myCartelas = const [];
          _clearMyCartelaDisplayOrder();
          _cn.claimingCartelaIds.clear();
          _cn.processedClaimedIds.clear();
          _cn.processedResolvedClaimIds.clear();
          _cn.processedCalledNumberIds.clear();
          _cn.processedCalledNumberOrders.clear();
          _cn.pendingClaimCartelaIds.clear();
          _cn.manualMarkedNumbers.clear();
          _cn.lastManualMarkedKey = null;
          _cn.bufferedCalledNumbers = const [];
          _cn.deferredCalledNumbers = const [];
          _cn.marksSessionId = null;
          _cn.marksOwnerUserId = null;
          _cn.restoredMarksSessionId = null;
          _emptyMessage = waitingForRealtime
              ? null
              : 'No game is open right now. Pull down to refresh when the next round starts.';
          _isLoading = false;
          if (resumeSync) {
            _realtime.canonicalRefetchInFlight = false;
          }
        });
        _syncActiveCartelasToProvider();
        _evaluateLiveRoomSplash();
        return;
      }

      final previousSessionId = _game?.sessionId;
      final sessionChanged =
          game.sessionId != null && game.sessionId != previousSessionId;

      if (resumeSync &&
          priorSessionId != null &&
          game.sessionId != null &&
          priorSessionId != game.sessionId) {
        _clearReadyTransitionLock();
        _clearRegistrationCountdownDeadline();
        _resetNextBallCountdownState();
        _cn.clearSessionScopedState(
          clearCalledNumbers: true,
          clearManualMarks: false,
        );
      }

      _syncOpenRegistrationBeatsTransitionLock(operations: operations);

      final calledNumbersSyncGame = resolveCalledNumbersSyncGame(
        operations: operations,
        primaryGame: game,
      );
      final priorCalledNumbersSessionId = priorCalledNumbersSessionIdFromLocal(
        localCalledNumbers: _cn.calledNumbers,
        fallback: priorSessionId,
      );
      final calledNumbersFetchSessionId = calledNumbersSyncGame?.sessionId;

      var effectiveIncludeCalledNumbers = includeCalledNumbers;
      if (resumeSync) {
        if (calledNumbersSyncGame != null) {
          final calledDecision = resolveResumeCalledNumbersFetch(
            game: calledNumbersSyncGame,
            priorSessionId: priorCalledNumbersSessionId,
            localCalledNumbers: _cn.calledNumbers,
            reconnectGapDetected: _resumeReconnectGapDetected(
              calledNumbersSyncGame,
            ),
          );
          effectiveIncludeCalledNumbers = calledDecision.shouldFetch;
          if (!calledDecision.shouldFetch) {
            LiveRealtimeDebug.resumeFetchSkipped(
              type: 'called_numbers',
              reason: calledDecision.reason,
            );
          }
        } else {
          effectiveIncludeCalledNumbers = false;
          LiveRealtimeDebug.resumeFetchSkipped(
            type: 'called_numbers',
            reason: 'no_live_sync_session',
          );
        }
      } else if (!effectiveIncludeCalledNumbers &&
          !sessionChanged &&
          calledNumbersSyncGame != null &&
          _cn.detectsCountDrift(calledNumbersSyncGame)) {
        effectiveIncludeCalledNumbers = true;
      } else if (!effectiveIncludeCalledNumbers &&
          includeCalledNumbers &&
          calledNumbersSyncGame != null) {
        effectiveIncludeCalledNumbers = true;
      }

      var effectiveIncludeMyCartelas = resumeSync ? !_isGuest : includeMyCartelas;
      if (resumeSync && !_isGuest) {
        final myCartelasDecision = resolveResumeMyCartelasFetch(
          game: game,
          priorSessionId: priorSessionId,
          localMyCartelasCount: _myCartelas.length,
          sessionChanged: sessionChanged,
        );
        effectiveIncludeMyCartelas = myCartelasDecision.shouldFetch;
        if (!myCartelasDecision.shouldFetch) {
          LiveRealtimeDebug.resumeFetchSkipped(
            type: 'my_cartelas',
            reason: myCartelasDecision.reason,
          );
        }
      }

      List<CalledNumberModel> calledNumbers = const [];
      List<GameCartelaModel> myCartelas = const [];
      List<GameCartelaModel> nextRegistrationCartelas = const [];

      if (sessionChanged) {
        effectiveIncludeMyCartelas = true;
        if (previousSessionId != null && previousSessionId.isNotEmpty) {
          ref
              .read(registrationStatePatchProvider.notifier)
              .clear(previousSessionId);
        }
        calledNumbers = const [];
        myCartelas = const [];
      }

      final myCartelasSessionId = game.sessionId;
      final parallelCalledNumbersSessionId =
          effectiveIncludeCalledNumbers &&
              calledNumbersFetchSessionId != null &&
              myCartelasSessionId != null &&
              calledNumbersFetchSessionId == myCartelasSessionId
          ? calledNumbersFetchSessionId
          : null;

      if (game.sessionId != null) {
        if (effectiveIncludeMyCartelas && preloadedPrimaryCartelas != null) {
          myCartelas = List<GameCartelaModel>.from(preloadedPrimaryCartelas)
            ..sort((left, right) {
              return left.cartela.number.compareTo(right.cartela.number);
            });
        }

        if (parallelCalledNumbersSessionId != null) {
          if (_isGuest) {
            final snapshot = await _gamesRepository.getCalledNumbers(
              parallelCalledNumbersSessionId,
            );
            if (!_isCurrentLoad(generation)) {
              return;
            }

            calledNumbers = List<CalledNumberModel>.from(snapshot.calledNumbers)
              ..sort((left, right) => left.order.compareTo(right.order));
          } else if (effectiveIncludeMyCartelas &&
              preloadedPrimaryCartelas == null) {
            dynamic snapshot;
            Object? calledNumbersError;
            var myCartelasFailed = false;
            List<GameCartelaModel>? fetchedMyCartelas;

            await Future.wait<void>([
              () async {
                try {
                  snapshot = await _gamesRepository.getCalledNumbers(
                    parallelCalledNumbersSessionId,
                  );
                } catch (error) {
                  calledNumbersError = error;
                }
              }(),
              () async {
                try {
                  fetchedMyCartelas = await _gamesRepository.getMyGameCartelas(
                    game.sessionId!,
                  );
                } catch (_) {
                  myCartelasFailed = true;
                }
              }(),
            ]);

            if (!_isCurrentLoad(generation)) {
              return;
            }

            if (calledNumbersError != null) {
              throw calledNumbersError!;
            }

            if (!myCartelasFailed && fetchedMyCartelas != null) {
              myCartelas = List<GameCartelaModel>.from(fetchedMyCartelas!)
                ..sort((left, right) {
                  return left.cartela.number.compareTo(right.cartela.number);
                });
            } else {
              myCartelas = sessionChanged
                  ? const []
                  : List<GameCartelaModel>.from(_myCartelas);
            }
            calledNumbers = List<CalledNumberModel>.from(
              snapshot.calledNumbers as List<CalledNumberModel>,
            )..sort((left, right) => left.order.compareTo(right.order));
          } else {
            final snapshot = await _gamesRepository.getCalledNumbers(
              parallelCalledNumbersSessionId,
            );
            if (!_isCurrentLoad(generation)) {
              return;
            }

            calledNumbers = List<CalledNumberModel>.from(snapshot.calledNumbers)
              ..sort((left, right) => left.order.compareTo(right.order));
          }
        } else if (!_isGuest &&
            effectiveIncludeMyCartelas &&
            preloadedPrimaryCartelas == null) {
          try {
            myCartelas = await _gamesRepository.getMyGameCartelas(
              game.sessionId!,
            );
          } catch (_) {
            myCartelas = sessionChanged
                ? const []
                : List<GameCartelaModel>.from(_myCartelas);
          }
          if (!_isCurrentLoad(generation)) {
            return;
          }

          myCartelas = List<GameCartelaModel>.from(myCartelas)
            ..sort((left, right) {
              return left.cartela.number.compareTo(right.cartela.number);
            });
        }

        if (!effectiveIncludeMyCartelas && !sessionChanged) {
          myCartelas = List<GameCartelaModel>.from(_myCartelas);
        } else if (resumeSync &&
            !effectiveIncludeMyCartelas &&
            !sessionChanged &&
            game.sessionId == priorSessionId) {
          myCartelas = List<GameCartelaModel>.from(_myCartelas);
        }
      }

      if (effectiveIncludeCalledNumbers &&
          calledNumbersFetchSessionId != null &&
          parallelCalledNumbersSessionId == null) {
        final snapshot = await _gamesRepository.getCalledNumbers(
          calledNumbersFetchSessionId,
        );
        if (!_isCurrentLoad(generation)) {
          return;
        }

        calledNumbers = List<CalledNumberModel>.from(snapshot.calledNumbers)
          ..sort((left, right) => left.order.compareTo(right.order));
      }

      if (resumeSync && effectiveIncludeMyCartelas) {
        LiveRealtimeDebug.resumeSyncMyCartelasLoaded(count: myCartelas.length);
      } else if (resumeSync && !effectiveIncludeMyCartelas) {
        LiveRealtimeDebug.resumeSyncMyCartelasLoaded(count: _myCartelas.length);
      }
      if (resumeSync && effectiveIncludeCalledNumbers) {
        LiveRealtimeDebug.resumeSyncCalledNumbersLoaded(
          count: calledNumbers.length,
        );
      } else if (resumeSync && !effectiveIncludeCalledNumbers) {
        LiveRealtimeDebug.resumeSyncCalledNumbersLoaded(
          count: _cn.calledNumbers.length,
        );
      }

      final nextRegistrationTarget = _resolveQueueUpcomingGame(
        operations,
        current: game,
      );
      final nextSessionId = nextRegistrationTarget?.sessionId;
      if (!_isGuest &&
          nextSessionId != null &&
          nextSessionId.isNotEmpty &&
          nextSessionId != game.sessionId) {
        try {
          nextRegistrationCartelas = await _gamesRepository.getMyGameCartelas(
            nextSessionId,
          );
          if (!_isCurrentLoad(generation)) {
            return;
          }

          nextRegistrationCartelas =
              List<GameCartelaModel>.from(nextRegistrationCartelas)
                ..sort((left, right) {
                  return left.cartela.number.compareTo(right.cartela.number);
                });
        } catch (_) {
          nextRegistrationCartelas = const [];
        }
      }

      if (!_isCurrentLoad(generation)) {
        return;
      }

      final wasFinished =
          _game?.status == GameStatus.finished ||
          _game?.status == GameStatus.noWinner;
      final isFinished =
          game.status == GameStatus.finished ||
          game.status == GameStatus.noWinner;
      final shouldMarkFinished = isFinished && !wasFinished;
      final shouldClearFinished = !isFinished;
      final shouldStaggerCalledNumbers = effectiveIncludeCalledNumbers &&
          !sessionChanged &&
          (resumeSync
              ? shouldStaggerResumeCalledNumbers(
                  priorLocalCount: priorCalledCount,
                  incomingCount: calledNumbers.length,
                )
              : _countNewCalledNumbers(calledNumbers) > 1);

      if (shouldStaggerCalledNumbers && resumeSync) {
        _cn.prepareResumeStaggerHydration();
      }

      _applyCanonicalGame(
        generation: generation,
        game: game,
        operations: operations,
        calledNumbers: calledNumbers,
        myCartelas: myCartelas,
        nextRegistrationCartelas: nextRegistrationCartelas,
        includeCalledNumbers: effectiveIncludeCalledNumbers,
        sessionChanged: sessionChanged,
        shouldStaggerCalledNumbers: shouldStaggerCalledNumbers,
        shouldClearFinished: shouldClearFinished,
        resumeSync: resumeSync,
      );

      if (shouldStaggerCalledNumbers && _isCurrentLoad(generation)) {
        unawaited(
          _hydrateCalledNumbersWithStagger(
            calledNumbers,
            generation: generation,
          ),
        );
      }

      if (shouldMarkFinished && _isCurrentLoad(generation)) {
        _runTerminalSideEffectsAfterCanonicalApply(game);
      } else if (_isCurrentLoad(generation)) {
        _ensurePostGameSummaryHoldIfNeeded();
      }
      _syncWinnerWindowTicker();
      _syncNextBallCountdownTicker();
      _syncPostGameSummaryCountdownTicker();
      _syncSessionWinnerResultsPolling();
      if (resumeSync && _isCurrentLoad(generation)) {
        _scheduleResumeProviderSync(
          operations: operations,
          forceAuxiliaryRefresh: !allowCachedOperations,
        );
      }
      _evaluateLiveRoomSplash();
    } catch (error) {
      if (!_isCurrentLoad(generation)) {
        return;
      }

      _safeSetState(generation, () {
        if (showLoading || _game == null) {
          _game = null;
          _lastOperations = null;
          _nextUpcomingGame = null;
          _nextRegistrationCartelas = const [];
          _timingConfig = null;
          _timingConfigLoaded = false;
          _errorMessage = error is ApiException
              ? error.message
              : 'Could not load live game data.';
        }
        _isLoading = false;
        if (resumeSync) {
          _realtime.canonicalRefetchInFlight = false;
        }
      });
      _evaluateLiveRoomSplash();
    }
  }

  Future<void> _reloadTimeConfig() async {
    if (!mounted) {
      return;
    }

    if (_timingConfigLoaded && _shouldCacheTimingConfigForLivePlay) {
      return;
    }

    try {
      final timingConfig = await _gamesRepository.getTimeConfig();
      if (!mounted) {
        return;
      }

      setState(() {
        _timingConfig = timingConfig;
        _timingConfigLoaded = true;
      });
      if (timingConfig.serverNow != null) {
        _syncServerClockFromUtc(timingConfig.serverNow!);
      }
    } catch (_) {
      // Keep the last loaded config when a background refresh fails.
    }
  }

  bool _registrationTargetIsCurrentGameFor(GameModel? target) {
    if (target == null) {
      return false;
    }
    final game = _game;
    if (game == null || target.id != game.id) {
      return false;
    }
    final targetSessionId = target.sessionId;
    final gameSessionId = game.sessionId;
    if (targetSessionId == null || gameSessionId == null) {
      return true;
    }
    return targetSessionId == gameSessionId;
  }

  String? get _trackedRegistrationSessionId {
    final target = _liveUiMode.registrationTarget;
    if (target == null ||
        target.status != GameStatus.ready ||
        !target.canRegister ||
        _registrationTargetIsCurrentGameFor(target)) {
      return null;
    }

    final sessionId = target.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return null;
    }

    return sessionId;
  }

  Future<GameOperationsCurrentResponse> _loadResumeOperationsCurrent() async {
    final cached = GameOperationsResumeCache.shared.getIfFresh();
    if (cached != null) {
      LiveRealtimeDebug.resumeCacheHit(type: 'operations_current');
      return cached;
    }

    LiveRealtimeDebug.resumeCacheMiss(type: 'operations_current');
    final response = await _gamesRepository.getCurrentGameOperations();
    GameOperationsResumeCache.shared.put(response);
    return response;
  }

  bool _resumeReconnectGapDetected(GameModel game) {
    if (_cn.bufferedCalledNumbers.isNotEmpty ||
        _cn.deferredCalledNumbers.isNotEmpty ||
        _cn.socketBufferedCalledNumbers.isNotEmpty) {
      return true;
    }

    if (!_socketService.isConnected) {
      return true;
    }

    return _cn.detectsCountDrift(game);
  }

  void _prefetchTrackedRegistrationState({bool resumeSync = false}) {
    if (resumeSync) {
      return;
    }

    _runAfterBuild(() {
      final sessionId = _trackedRegistrationSessionId;
      if (_isGuest || sessionId == null) {
        return;
      }

      ref.invalidate(registrationStateProvider(sessionId));
      LiveRealtimeDebug.providerInvalidated(
        provider: 'registrationState',
        reason: 'prefetch_tracked',
        sessionId: sessionId,
      );
    });
  }

  void _scheduleResumeProviderSync({
    required GameOperationsCurrentResponse? operations,
    bool forceAuxiliaryRefresh = false,
  }) {
    _runAfterBuild(() {
      _syncResumeProviders(
        operations: operations,
        forceAuxiliaryRefresh: forceAuxiliaryRefresh,
      );
    });
  }

  void _syncResumeProviders({
    required GameOperationsCurrentResponse? operations,
    bool forceAuxiliaryRefresh = false,
  }) {
    if (operations != null) {
      ref.read(currentGameOperationsProvider.notifier).adoptResumeSnapshot(
        operations,
      );
    }

    final sessionId = _game?.sessionId;
    if (sessionId != null) {
      final shouldInvalidateRegistration = shouldInvalidateRegistrationStateOnResume(
        sessionId: sessionId,
        primaryGame: _game,
      );
      final allowRegistrationRefresh =
          shouldInvalidateRegistration &&
          ResumeAuxiliaryRefreshGate.shouldRunWalletRegistration(
            syncReason: 'app_resume',
            force: forceAuxiliaryRefresh,
          );
      if (allowRegistrationRefresh) {
        ref.invalidate(registrationStateProvider(sessionId));
        LiveRealtimeDebug.providerInvalidated(
          provider: 'registrationState',
          reason: 'resume_sync',
          sessionId: sessionId,
        );
      } else if (shouldInvalidateRegistration) {
        LiveRealtimeDebug.providerInvalidateSkipped(
          provider: 'registrationState',
          reason: 'app_resume_debounced',
          sessionId: sessionId,
        );
      } else {
        LiveRealtimeDebug.providerInvalidateSkipped(
          provider: 'registrationState',
          reason: 'resume_playing_current_session',
          sessionId: sessionId,
        );
      }
    }

    final trackedSessionId = _trackedRegistrationSessionId;
    if (trackedSessionId != null && trackedSessionId != sessionId) {
      if (ResumeAuxiliaryRefreshGate.shouldRunWalletRegistration(
        syncReason: 'app_resume',
        force: forceAuxiliaryRefresh,
      )) {
        ref.invalidate(registrationStateProvider(trackedSessionId));
        LiveRealtimeDebug.providerInvalidated(
          provider: 'registrationState',
          reason: 'resume_sync_tracked',
          sessionId: trackedSessionId,
        );
      } else {
        LiveRealtimeDebug.providerInvalidateSkipped(
          provider: 'registrationState',
          reason: 'app_resume_debounced',
          sessionId: trackedSessionId,
        );
      }
    }
  }

  bool _eventAffectsCurrentGame({String? sessionId, String? slotId}) {
    if (eventAffectsCurrentGame(
      game: _game,
      activeSessionId: _activeSessionId,
      eventSessionId: sessionId,
      eventSlotId: slotId,
      trackedRegistrationSessionId: _trackedRegistrationSessionId,
    )) {
      return true;
    }

    if (sessionId != null && sessionId.isNotEmpty) {
      final ops = _lastOperations;
      if (sessionId == ops?.liveGame?.sessionId ||
          sessionId == ops?.checkingGame?.sessionId) {
        return true;
      }
    }

    return false;
  }

  bool _eventAffectsRegistrationSession({String? sessionId, String? slotId}) {
    return _eventAffectsCurrentGame(sessionId: sessionId, slotId: slotId) ||
        eventAffectsTrackedRegistrationSession(
          trackedRegistrationSessionId: _trackedRegistrationSessionId,
          eventSessionId: sessionId,
        );
  }

  bool _eventAffectsCurrentGameFromPayload(Map<String, dynamic> payload) {
    return _eventAffectsCurrentGame(
      sessionId:
          payload['sessionId'] as String? ??
          payload['gameSessionId'] as String? ??
          payload['id'] as String?,
      slotId: payload['slotId'] as String? ?? payload['gameSlotId'] as String?,
    );
  }

  void _applyCanonicalGame({
    required int generation,
    required GameModel game,
    required GameOperationsCurrentResponse? operations,
    required List<CalledNumberModel> calledNumbers,
    required List<GameCartelaModel> myCartelas,
    required List<GameCartelaModel> nextRegistrationCartelas,
    required bool includeCalledNumbers,
    required bool sessionChanged,
    required bool shouldStaggerCalledNumbers,
    required bool shouldClearFinished,
    bool resumeSync = false,
  }) {
    final previousMarksSessionId = _cn.marksSessionId;
    final marksSessionChanged = previousMarksSessionId != game.sessionId;

    _safeSetState(generation, () {
      _syncReadyTransitionLock(
        operations: operations,
        mergedGame: game,
      );
      _syncOpenRegistrationBeatsTransitionLock(operations: operations);

      if (game.sessionId != _cn.marksSessionId) {
        if (marksSessionChanged) {
          _cn.manualMarkedNumbers.clear();
          _cn.lastManualMarkedKey = null;
          _cn.restoredMarksSessionId = null;
        }
        _cn.marksSessionId = game.sessionId;
        if (game.sessionId == null) {
          _cn.marksOwnerUserId = null;
        }
        _cn.pendingClaimCartelaIds.clear();
        _cn.claimingCartelaIds.clear();
        _cn.processedClaimedIds.clear();
        _cn.processedResolvedClaimIds.clear();
        _cn.bufferedCalledNumbers = const [];
        _cn.deferredCalledNumbers = const [];
        _review.sessionWinnerCartelaNumbers = const [];
        _review.sessionBlockedCartelaNumbers = const [];
        _review.sessionCheckingCartelaNumbers = const [];
      }

      if (sessionChanged) {
        _clearRegistrationCountdownDeadline();
        _resetNextBallCountdownState();
        // Full session transition cleanup
        _clearSessionScopedPlayState(
          clearCartelas: true,
          clearCalledNumbers: true,
          clearManualMarks: false,
        );
        _review.sessionWinnerResults = const [];
        _review.sessionWinnerResultsLoaded = false;
        _review.sessionWinnerResultsLoading = false;
        if (shouldClearWinnerPatternsOnSessionApply(
          sessionChanged: true,
          postGameSummaryAdvancing: _review.postGameSummaryAdvancing,
          incomingStatus: game.status,
        )) {
          _review.clearFinishedReviewVisualState(
            reason: WinnerPatternClearReason.sessionChanged,
          );
        }
        _cn.cartelaSortResults = const {};
        _cn.blockedCartelaFrozenMarks.clear();
        _cn.blockedCartelaFrozenSortResults.clear();
        _cn.blockedCartelaReasonCodeById.clear();
        _cn.blockedCartelaServerReasonById.clear();
        // Join new socket session room
        if (game.sessionId != null) {
          _applySocketSessionMembership(game.sessionId);
        }
      }

      final previousNextAutoCallAt = _game?.nextAutoCallAt;
      final mergedGame = resumeSync
          ? game
          : GameModel.mergeCanonicalSessionState(
              current: _game,
              incoming: game,
            );

      _game = mergedGame;
      final scheduleChanged = !dateTimesEqualForSchedule(
        mergedGame.nextAutoCallAt,
        previousNextAutoCallAt,
      );
      if (scheduleChanged || sessionChanged) {
        _countdown.onNextBallScheduleChanged(
          game: mergedGame,
          nextAutoCallAt: mergedGame.nextAutoCallAt,
          scheduleChanged: scheduleChanged,
        );
      }
      if (_allBallsDrawnForCurrentGame && mergedGame.nextAutoCallAt == null) {
        _cn.socketAutoCallEnabled = false;
      }
      _applySessionOutcomeFromGame(mergedGame);
      final calledNumbersSyncGame = resolveCalledNumbersSyncGame(
        operations: operations,
        primaryGame: mergedGame,
      );
      if (calledNumbersSyncGame != null &&
          calledNumbersSyncGame.sessionId != mergedGame.sessionId) {
        _applySessionOutcomeFromGame(calledNumbersSyncGame);
      }
      _lastOperations = operations;
      _hasBlockingLiveGame =
          operations?.liveGame != null || operations?.checkingGame != null;
      _nextUpcomingGame = _resolveQueueUpcomingGame(
        operations,
        current: mergedGame,
      );
      _nextRegistrationCartelas = nextRegistrationCartelas;
      if (_nextUpcomingGame != null) {
        _reopenRegistrationCountdownIfNeeded(_nextUpcomingGame!);
        _prefetchTrackedRegistrationState(resumeSync: resumeSync);
      }
      _maybeAutoExpandForQueuedNextGame();
      _countdown.winnerWindowEndsAt =
          (calledNumbersSyncGame ?? mergedGame).status == GameStatus.winnerWindow
          ? (calledNumbersSyncGame ?? mergedGame).winnerWindowEndsAt
          : null;
      _syncRegistrationCountdownClosedState(game: mergedGame);
      _reopenRegistrationCountdownIfNeeded(mergedGame);
      _syncRegistrationCountdownDeadline(game: mergedGame);
      if (includeCalledNumbers || sessionChanged) {
        if (!shouldStaggerCalledNumbers) {
          if (resumeSync) {
            _cn.replaceFromResumeSnapshot(calledNumbers);
          } else if (sessionChanged) {
            _cn.applyCalledNumbersSnapshot(
              incoming: calledNumbers,
              sessionChanged: sessionChanged,
            );
          } else {
            _cn.fillCalledNumberGaps(calledNumbers);
          }
        }
      }
      _myCartelas = myCartelas;
      _sortMyCartelas();
      _isLoading = false;
      // Canonical truth is now on screen; feed the reconnect throttle so a
      // socket `connect` right after this apply does not refetch redundantly.
      _realtime.markCanonicalApplied();
      _initialLoadComplete = true;
      if (!_hasCompletedInitialPaint) {
        _hasCompletedInitialPaint = true;
      }

      // A stale refetch may still report winnerWindow while local state already
      // advanced to finished; keep the review hold until we truly leave terminal.
      if (shouldClearFinished && !isTerminalGameStatus(mergedGame.status)) {
        _clearPostGameSummaryHold(
          patternClearReason: WinnerPatternClearReason.sessionChanged,
        );
      }
      if (resumeSync) {
        _realtime.canonicalRefetchInFlight = false;
      }
    });
    _syncActiveCartelasToProvider();
    if (!resumeSync || !includeCalledNumbers) {
      _markCalledNumbersPanelDirty();
    }

    if (previousMarksSessionId != null &&
        previousMarksSessionId.isNotEmpty &&
        previousMarksSessionId != game.sessionId) {
      unawaited(_clearPersistedMarksForSession(previousMarksSessionId));
    }

    final sessionId = game.sessionId;
    if (sessionId != null && sessionId.isNotEmpty && !_isGuest) {
      unawaited(_ensureManualMarksReadyForSession(sessionId));
    }

    final socketSessionId = _preferredSocketSessionId(
      primaryGame: game,
      operations: operations,
    );
    if (socketSessionId == null) {
      _applySocketSessionMembership(null);
    } else {
      _applySocketSessionMembership(socketSessionId);
    }

    _syncPreparingPhasePolling();
    _logPresentationPhaseIfChanged(
      detail: 'status=${game.status.name} called=${game.calledNumbersCount}',
    );
  }

  void _reopenRegistrationCountdownIfNeeded(GameModel game) {
    _countdown.reopenRegistrationCountdownIfNeeded(game);
  }

  Future<void> _refreshCalledNumbersFromUi() {
    return _cn.refreshCalledNumbersFromUi(
      onError: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
      refreshWinnerDisplay: _refreshWinnerDisplayFromSessionStrip,
    );
  }

  void _flushBufferedCalledNumbers() => _cn.flushBufferedCalledNumbers();

  void _releaseCalledNumbersStripHoldIfIdle({bool force = false}) {
    _cn.releaseCalledNumbersStripHoldIfIdle(
      force: force,
      hasSessionCheckingCartelaNumbers:
          _review.sessionCheckingCartelaNumbers.isNotEmpty,
    );
  }

  void _syncCalledNumbersForFinishedReview() {
    setState(() {
      _cn.releaseCalledNumbersStripHoldIfIdle(
        force: true,
        hasSessionCheckingCartelaNumbers: false,
      );
      _refreshWinnerDisplayFromSessionStrip();
    });
    _markCalledNumbersPanelDirty();
    unawaited(_refreshCalledNumbersFromUi());
  }

  void _cancelCanonicalRefetchDebounce() {
    _realtime.cancelCanonicalRefetchDebounce();
  }

  void _scheduleCanonicalRefetch({
    bool wallet = false,
    String? registrationSessionId,
    bool includeCalledNumbers = false,
    bool includeMyCartelas = false,
    String reason = 'screen_schedule',
  }) {
    _realtime.scheduleCanonicalRefetch(
      reason: reason,
      wallet: wallet,
      registrationSessionId: registrationSessionId,
      includeCalledNumbers: includeCalledNumbers,
      includeMyCartelas: includeMyCartelas,
    );
  }

  Future<void> _refetchCanonicalImmediate({
    bool wallet = false,
    String? registrationSessionId,
    bool includeCalledNumbers = true,
    bool includeMyCartelas = false,
    String reason = 'screen_immediate',
  }) {
    return _realtime.refetchCanonicalImmediate(
      reason: reason,
      wallet: wallet,
      registrationSessionId: registrationSessionId,
      includeCalledNumbers: includeCalledNumbers,
      includeMyCartelas: includeMyCartelas,
    );
  }

  Future<void> _refreshMyCartelasSilently() async {
    if (_isGuest) {
      return;
    }

    final sessionId = _game?.sessionId;
    if (sessionId == null || !mounted) {
      return;
    }

    // Phase B1: Debounce to prevent refresh storms when multiple socket events
    // arrive quickly. Target: one refresh within 300-500ms per session.
    _myCartelasRefreshDebounceTimer?.cancel();
    _myCartelasRefreshDebounceTimer = Timer(
      const Duration(milliseconds: 400),
      () async {
        if (!mounted || _game?.sessionId != sessionId) {
          return;
        }

        try {
          final myCartelas = await _gamesRepository.getMyGameCartelas(
            sessionId,
          );
          if (!mounted || _game?.sessionId != sessionId) {
            return;
          }

          // Phase B1: Preserve manual marks and claim in-flight UI.
          // Do not clear cartelas before fetch completes.
          setState(() {
            _myCartelas = myCartelas
              ..sort((left, right) {
                return left.cartela.number.compareTo(right.cartela.number);
              });
            _sortMyCartelas();
          });
          _syncActiveCartelasToProvider();
          _markCalledNumbersPanelDirty();
          // Manual marks are preserved because _cn.manualMarkedNumbers is not cleared
          // and _cn.marksSessionId matches the current session.
        } catch (_) {
          if (!mounted || _game?.sessionId != sessionId) {
            return;
          }
        }
      },
    );
  }

  Future<void> _refreshNextRegistrationCartelasSilently() async {
    if (_isGuest) {
      return;
    }

    final sessionId = _trackedRegistrationSessionId;
    if (sessionId == null || !mounted) {
      return;
    }

    // Phase B1: Debounce to prevent refresh storms.
    _nextCartelasRefreshDebounceTimer?.cancel();
    _nextCartelasRefreshDebounceTimer = Timer(
      const Duration(milliseconds: 400),
      () async {
        if (!mounted || _trackedRegistrationSessionId != sessionId) {
          return;
        }

        try {
          final nextCartelas = await _gamesRepository.getMyGameCartelas(
            sessionId,
          );
          if (!mounted || _trackedRegistrationSessionId != sessionId) {
            return;
          }

          setState(() {
            _nextRegistrationCartelas =
                List<GameCartelaModel>.from(nextCartelas)..sort((left, right) {
                  return left.cartela.number.compareTo(right.cartela.number);
                });
          });
        } catch (_) {
          // Phase B1: Keep current next-registration cartelas if the silent refresh fails.
        }
      },
    );
  }

  GameModel? _resolvePrimaryFromOperations(
    GameOperationsCurrentResponse ops, {
    required bool ownsLiveCartelas,
  }) =>
      _transition.resolvePrimaryFromOperations(
        ops,
        ownsLiveCartelas: ownsLiveCartelas,
      );

  bool _ownsLiveCartelasForOperations(GameOperationsCurrentResponse ops) =>
      _transition.ownsLiveCartelasForOperations(ops);

  Future<({GameModel? game, List<GameCartelaModel>? preloadedPrimaryCartelas})>
  _loadGame({
    GameOperationsCurrentResponse? operations,
    GameModel? advanceTarget,
    bool allowOwnershipLookup = true,
  }) async {
    if (advanceTarget != null) {
      _joinSessionRoomEarly(advanceTarget.sessionId);
      return (game: advanceTarget, preloadedPrimaryCartelas: null);
    }

    final gameId = widget.gameId;
    if (gameId != null) {
      _joinSessionRoomEarly(gameId);

      try {
        return (
          game: await _gamesRepository.getSessionDetail(gameId),
          preloadedPrimaryCartelas: null,
        );
      } catch (_) {
        return (
          game: await _gamesRepository.getSlotDetail(gameId),
          preloadedPrimaryCartelas: null,
        );
      }
    }

    final ops =
        operations ??
        await ref.read(gamesRepositoryProvider).getCurrentGameOperations();

    final liveCandidate = ops.liveGame ?? ops.checkingGame;
    final registrationGame = ops.registrationOpenGame;
    List<GameCartelaModel>? preloadedPrimaryCartelas;
    final liveSessionId = liveCandidate?.sessionId;
    final ownsLocalLiveCartelas =
        liveSessionId != null &&
        liveSessionId.isNotEmpty &&
        _game?.sessionId == liveSessionId &&
        _myCartelas.isNotEmpty;

    // Primary round selection is driven by operations/current plus the
    // authenticated player's live-session ownership from /my-cartelas.
    final game =
        !_isGuest &&
            allowOwnershipLookup &&
            liveCandidate != null &&
            registrationGame != null &&
            liveCandidate.sessionId != null &&
            liveCandidate.sessionId!.isNotEmpty
        ? () {
            final liveSessionId = liveCandidate.sessionId!;
            return _gamesRepository
                .getMyGameCartelas(liveSessionId)
                .then((fetched) {
                  final fetchedCartelas = List<GameCartelaModel>.from(fetched)
                    ..sort((left, right) {
                      return left.cartela.number.compareTo(
                        right.cartela.number,
                      );
                    });
                  final ownsLocalLiveCartelas =
                      _game?.sessionId == liveSessionId &&
                      _myCartelas.isNotEmpty;
                  final ownsLiveCartelas =
                      fetchedCartelas.isNotEmpty || ownsLocalLiveCartelas;

                  if (fetchedCartelas.isNotEmpty) {
                    preloadedPrimaryCartelas = fetchedCartelas;
                  } else if (ownsLocalLiveCartelas) {
                    preloadedPrimaryCartelas =
                        List<GameCartelaModel>.from(_myCartelas)
                          ..sort((left, right) {
                            return left.cartela.number.compareTo(
                              right.cartela.number,
                            );
                          });
                  }

                  return _resolvePrimaryFromOperations(
                    ops,
                    ownsLiveCartelas: ownsLiveCartelas,
                  );
                })
                .catchError((_) {
                  final ownsLiveCartelas =
                      _game?.sessionId == liveSessionId &&
                      _myCartelas.isNotEmpty;
                  if (ownsLiveCartelas) {
                    preloadedPrimaryCartelas =
                        List<GameCartelaModel>.from(_myCartelas)
                          ..sort((left, right) {
                            return left.cartela.number.compareTo(
                              right.cartela.number,
                            );
                          });
                  }
                  return _resolvePrimaryFromOperations(
                    ops,
                    ownsLiveCartelas: ownsLiveCartelas,
                  );
                });
          }()
        : Future.value(
            _resolvePrimaryFromOperations(
              ops,
              ownsLiveCartelas: _ownsLiveCartelasForOperations(ops),
            ) ?? ops.currentGameForPlayer,
          );
    final resolvedGame = await game;
    _joinSessionRoomEarly(resolvedGame?.sessionId);
    return (
      game: resolvedGame,
      preloadedPrimaryCartelas: preloadedPrimaryCartelas,
    );
  }

  Future<void> _bootstrapLiveRoomSplash() async {
    if (widget.embedded || widget.initialGame != null) {
      if (mounted) {
        setState(() => _awaitingLiveRoom = false);
      }
      return;
    }

    final storage = await ref.read(appPreferencesStorageProvider.future);
    if (!mounted) {
      return;
    }

    if (storage.hasSeenRealtimeBrandingSplash()) {
      setState(() => _awaitingLiveRoom = false);
      return;
    }

    _liveRoomSplashStartedAt = DateTime.now();
    _liveRoomSplashTicker = Timer.periodic(const Duration(milliseconds: 250), (
      _,
    ) {
      _evaluateLiveRoomSplash();
    });
    _evaluateLiveRoomSplash();
  }

  bool _canDismissLiveRoomSplash(Duration elapsed) {
    if (elapsed < _LiveGameScreenStateBase._liveRoomSplashMinimum) {
      return false;
    }

    if (_game != null) {
      return true;
    }

    if (elapsed >= _LiveGameScreenStateBase._liveRoomSplashMaximum) {
      return true;
    }

    if (_isGuest) {
      return !_isLoading;
    }

    return _socketService.isConnected && !_isLoading;
  }

  void _evaluateLiveRoomSplash() {
    if (!_awaitingLiveRoom || !mounted || _liveRoomSplashStartedAt == null) {
      return;
    }

    final elapsed = DateTime.now().difference(_liveRoomSplashStartedAt!);
    if (!_canDismissLiveRoomSplash(elapsed)) {
      return;
    }

    unawaited(_dismissLiveRoomSplash());
  }

  Future<void> _dismissLiveRoomSplash() async {
    if (!_awaitingLiveRoom || !mounted) {
      return;
    }

    final storage = await ref.read(appPreferencesStorageProvider.future);
    if (!storage.hasSeenRealtimeBrandingSplash()) {
      await storage.markRealtimeBrandingSplashSeen();
    }

    if (!mounted) {
      return;
    }

    _liveRoomSplashTicker?.cancel();
    setState(() => _awaitingLiveRoom = false);
  }

  Map<String, dynamic>? _normalizeSocketPayloadForEvent(
    dynamic payload, {
    required String eventName,
    bool includeCalledNumbers = false,
    bool wallet = false,
    bool preferRegistrationSessionRefetch = false,
    bool scheduleRefetchOnInvalid = true,
  }) {
    return normalizeSocketPayloadOrHandleInvalid(
      payload,
      eventName: eventName,
      debugLog: (message) => _logInvalidSocketPayloadOnce(eventName, payload),
      onInvalid: scheduleRefetchOnInvalid
          ? () => _scheduleCoalescedInvalidSocketPayloadRefetch(
              includeCalledNumbers: includeCalledNumbers,
              wallet: wallet,
              preferRegistrationSessionRefetch: preferRegistrationSessionRefetch,
            )
          : null,
    );
  }

  void _logInvalidSocketPayloadOnce(String eventName, dynamic payload) {
    if (!kDebugMode) {
      return;
    }

    final logKey = '$eventName:${payload.runtimeType}';
    final now = DateTime.now();
    if (_lastInvalidSocketPayloadLogKey == logKey &&
        _lastInvalidSocketPayloadLogAt != null &&
        now.difference(_lastInvalidSocketPayloadLogAt!) <
            const Duration(seconds: 5)) {
      return;
    }

    _lastInvalidSocketPayloadLogKey = logKey;
    _lastInvalidSocketPayloadLogAt = now;
    debugPrint(
      '[socket_payload] Invalid socket payload for $eventName: '
      '${payload.runtimeType}',
    );
  }

  void _scheduleCoalescedInvalidSocketPayloadRefetch({
    bool includeCalledNumbers = false,
    bool wallet = false,
    bool preferRegistrationSessionRefetch = false,
  }) {
    _invalidSocketPayloadRefetchTimer?.cancel();
    _invalidSocketPayloadRefetchTimer = Timer(
      const Duration(milliseconds: 900),
      () {
        if (!mounted) {
          return;
        }

        _scheduleCanonicalRefetch(
          wallet: wallet,
          includeCalledNumbers: includeCalledNumbers,
          registrationSessionId: preferRegistrationSessionRefetch
              ? (_trackedRegistrationSessionId ?? _game?.sessionId)
              : null,
        );
      },
    );
  }

  void _onNumberCalled(dynamic payload) {
    if (!mounted) {
      return;
    }

    final normalizedPayload = _normalizeSocketPayloadForEvent(
      payload,
      eventName: 'game:number_called',
      includeCalledNumbers: true,
    );
    if (normalizedPayload == null) {
      return;
    }

    if (!_eventAffectsCurrentGameFromPayload(normalizedPayload)) {
      return;
    }

    final game = _game;
    if (game != null &&
        (game.status == GameStatus.winnerWindow ||
            game.status == GameStatus.finished ||
            game.status == GameStatus.noWinner)) {
      return;
    }

    final calledNumber = CalledNumberModel.fromJson(normalizedPayload);
    if (_cn.isConflictingOrderDraw(calledNumber)) {
      LiveRealtimeDebug.log(
        'number_called_conflict order=${calledNumber.order} recovery=canonical',
      );
      _scheduleCanonicalRefetch(includeCalledNumbers: true);
      return;
    }
    if (_cn.isDuplicateCalledNumber(calledNumber)) {
      LiveRealtimeDebug.log(
        'number_called_duplicate order=${calledNumber.order} refresh=false',
      );
      return;
    }

    final gameSessionId = game?.sessionId;
    if (gameSessionId != null &&
        gameSessionId.isNotEmpty &&
        calledNumber.sessionId.isNotEmpty &&
        calledNumber.sessionId != gameSessionId) {
      LiveRealtimeDebug.log(
        'number_called_session_mismatch expected=$gameSessionId '
        'actual=${calledNumber.sessionId} recovery=canonical',
      );
      _scheduleCanonicalRefetch(includeCalledNumbers: true);
      return;
    }

    LiveRealtimeDebug.socket('game:number_called', normalizedPayload);

    final pauseStripForClaim = _isAnyClaimChecking;

    var scheduleChanged = false;
    NumberCalledSchedulePatch? schedulePatch;
    if (game != null) {
      schedulePatch = patchGameFromNumberCalledPayload(game, normalizedPayload);
      scheduleChanged = schedulePatch.scheduleChanged;
    }

    final applyResult = _cn.applyNumberCalledSocket(
      calledNumber: calledNumber,
      pauseStripForClaim: pauseStripForClaim,
    );
    if (applyResult == null) {
      return;
    }

    final highestKnownOrder = applyResult.highestKnownOrder;
    if (game != null && schedulePatch != null) {
      if (schedulePatch.autoCallEnabled != null) {
        _cn.socketAutoCallEnabled = schedulePatch.autoCallEnabled;
      }
      if (schedulePatch.autoCallEnabled == false ||
          highestKnownOrder >= kMaxBingoBalls) {
        _cn.socketAutoCallEnabled = false;
      }
    }

    void applyGameSchedule() {
      if (game != null && schedulePatch != null) {
        _game = schedulePatch.game.copyWith(
          calledNumbersCount: highestKnownOrder > game.calledNumbersCount
              ? highestKnownOrder
              : game.calledNumbersCount,
        );
      }
    }

    applyGameSchedule();

    if (game != null) {
      final updatedGame = _game!;
      if (scheduleChanged) {
        _countdown.onNextBallScheduleChanged(
          game: updatedGame,
          nextAutoCallAt: updatedGame.nextAutoCallAt,
          scheduleChanged: true,
        );
        _syncNextBallCountdownTicker();
      }
    }

    if (applyResult.requiresCanonicalSync) {
      LiveRealtimeDebug.log(
        'number_called_unreconciled order=${calledNumber.order} recovery=canonical',
      );
      _scheduleCanonicalRefetch(
        reason: 'number_called_conflict',
        includeCalledNumbers: true,
      );
    } else if (applyResult.requiresCalledNumbersSync) {
      LiveRealtimeDebug.log(
        'number_called_gap expected=${applyResult.expectedNextOrder} '
        'actual=${applyResult.incomingOrder ?? calledNumber.order} '
        'recovery=called_numbers',
      );
      unawaited(_recoverCalledNumbersAfterSocketGap());
    } else {
      LiveRealtimeDebug.log(
        'number_called_applied order=${calledNumber.order} refresh=false',
      );
    }

    // Non-live status with a ball: ask ops for truth — never invent PLAYING.
    if (game != null && !isLivePlayGameStatus(game.status)) {
      LiveRealtimeDebug.log(
        'number_called needs live reconcile (order=${calledNumber.order})',
      );
      _scheduleCanonicalRefetch(
        reason: 'number_called_needs_live_reconcile',
        includeCalledNumbers: true,
      );
    }
  }

  void _onBingoChecking(dynamic payload) {
    if (!mounted) {
      return;
    }

    final normalizedPayload = _normalizeSocketPayloadForEvent(
      payload,
      eventName: 'game:bingo_checking',
      includeCalledNumbers: true,
    );
    if (normalizedPayload == null) {
      return;
    }

    if (!_eventAffectsCurrentGameFromPayload(normalizedPayload)) {
      return;
    }

    if (normalizedPayload.containsKey('nextAutoCallAt')) {
      _applyAutoCallScheduleFromPayload(normalizedPayload);
    }

    final cartelaNumber = _cartelaNumberFromPayload(normalizedPayload);
    if (cartelaNumber == null) {
      return;
    }

    setState(() {
      _recordSessionCheckingCartelaNumber(cartelaNumber);
    });
    _markCalledNumbersPanelDirty();
  }

  void _onBingoClaimed(dynamic payload) {
    if (!mounted) {
      return;
    }

    final normalizedPayload = _normalizeSocketPayloadForEvent(
      payload,
      eventName: 'game:bingo_claimed',
      includeCalledNumbers: true,
    );
    if (normalizedPayload == null) {
      return;
    }

    if (!_eventAffectsCurrentGameFromPayload(normalizedPayload)) {
      return;
    }

    final claimId = normalizedPayload['claimId'] as String?;
    if (claimId == null || _cn.processedClaimedIds.contains(claimId)) {
      return;
    }

    _cn.processedClaimedIds.add(claimId);

    final gameCartelaId = normalizedPayload['gameCartelaId'] as String?;
    final cartelaNumber = _cartelaNumberFromPayload(normalizedPayload);
    if (gameCartelaId != null) {
      setState(() {
        _cn.pendingClaimCartelaIds.add(gameCartelaId);
        if (cartelaNumber != null) {
          _recordSessionCheckingCartelaNumber(cartelaNumber);
        }
      });
      _markCalledNumbersPanelDirty();
    }
  }

  void _onBingoValid(dynamic payload) {
    if (!mounted) {
      return;
    }

    final normalizedPayload = _normalizeSocketPayloadForEvent(
      payload,
      eventName: 'game:bingo_valid',
      includeCalledNumbers: true,
      wallet: !_isGuest,
    );
    if (normalizedPayload == null) {
      return;
    }

    if (!_eventAffectsCurrentGameFromPayload(normalizedPayload)) {
      return;
    }

    final claimId = normalizedPayload['claimId'] as String?;
    if (claimId == null || _cn.processedResolvedClaimIds.contains(claimId)) {
      return;
    }

    _cn.processedResolvedClaimIds.add(claimId);
    final gameCartelaId = normalizedPayload['gameCartelaId'] as String?;
    final cartelaNumber = _cartelaNumberFromPayload(normalizedPayload);
    final currentUserId = ref.read(authControllerProvider).session?.user.id;
    final completedPatterns = CompletedPatternModel.parseList(
      normalizedPayload['completedPatterns'],
    );
    final lastCalledNumber = parseSessionWinnerLastCalledNumber(
      normalizedPayload['lastCalledNumber'],
    );

    setState(() {
      if (cartelaNumber != null) {
        _clearSessionCheckingCartelaNumber(cartelaNumber);
      }
      if (gameCartelaId != null) {
        _cn.pendingClaimCartelaIds.remove(gameCartelaId);
        _storeClaimWinningSnapshot(
          gameCartelaId: gameCartelaId,
          patterns: completedPatterns,
          lastCalledNumber: lastCalledNumber,
        );
      }
      _myCartelas = _myCartelas
          .map((cartela) {
            if (cartela.id != gameCartelaId) {
              return cartela;
            }

            return cartela.copyWith(
              status: GameCartelaStatus.winner,
              isWinner: true,
              blockedAt: null,
            );
          })
          .toList(growable: false);
    });
    _markCalledNumbersPanelDirty();

    if (normalizedPayload['userId'] == currentUserId) {
      _awaitingPrizeWalletRefresh = true;
    }

    if (normalizedPayload.containsKey('nextAutoCallAt')) {
      _applyAutoCallScheduleFromPayload(normalizedPayload);
    }

    _releaseCalledNumbersStripHoldIfIdle();
  }

  void _onBingoInvalid(dynamic payload) {
    if (!mounted) {
      return;
    }

    final normalizedPayload = _normalizeSocketPayloadForEvent(
      payload,
      eventName: 'game:bingo_invalid',
      includeCalledNumbers: true,
    );
    if (normalizedPayload == null) {
      return;
    }

    if (!_eventAffectsCurrentGameFromPayload(normalizedPayload)) {
      return;
    }

    final gameCartelaId = normalizedPayload['gameCartelaId'] as String?;
    if (_shouldDeferClaimSocketForCartela(gameCartelaId)) {
      setState(() {
        _pendingBingoInvalidPayload = normalizedPayload;
      });
      return;
    }

    _applyBingoInvalidPayload(normalizedPayload);
  }

  void _applyBingoInvalidPayload(Map<String, dynamic> payload) {
    final claimId = payload['claimId'] as String?;
    if (claimId == null || _cn.processedResolvedClaimIds.contains(claimId)) {
      return;
    }

    _cn.processedResolvedClaimIds.add(claimId);
    final gameCartelaId = payload['gameCartelaId'] as String?;
    final cartelaNumber = _cartelaNumberFromPayload(payload);

    setState(() {
      if (gameCartelaId != null) {
        _cn.pendingClaimCartelaIds.remove(gameCartelaId);
        _cn.claimingCartelaIds.remove(gameCartelaId);
        _cn.rememberBlockedCartelaReason(
          gameCartelaId: gameCartelaId,
          reasonCode: payload['reasonCode'] as String?,
          serverReason: payload['reason'] as String?,
        );
      }
      if (cartelaNumber != null) {
        _recordSessionBlockedCartelaNumber(cartelaNumber);
      }
      _myCartelas = _myCartelas
          .map((cartela) {
            if (cartela.id != gameCartelaId) {
              return cartela;
            }

            return cartela.copyWith(
              status: GameCartelaStatus.blocked,
              isWinner: false,
              blockedAt: DateTime.now(),
            );
          })
          .toList(growable: false);
      for (final cartela in _myCartelas) {
        if (cartela.id == gameCartelaId) {
          _freezeBlockedCartela(cartela);
          break;
        }
      }
    });
    _markCalledNumbersPanelDirty();

    _releaseCalledNumbersStripHoldIfIdle();
    if (payload.containsKey('nextAutoCallAt')) {
      _applyAutoCallScheduleFromPayload(payload);
    } else {
      _scheduleCanonicalRefetch(reason: 'bingo_invalid_missing_schedule');
    }
  }

  void _onWinnerWindowEvent(dynamic payload) {
    if (!mounted) {
      return;
    }

    final normalizedPayload = _normalizeSocketPayloadForEvent(
      payload,
      eventName: 'game:winner_window_event',
      includeCalledNumbers: true,
      wallet: !_isGuest,
    );
    if (normalizedPayload == null) {
      return;
    }

    if (!_eventAffectsCurrentGameFromPayload(normalizedPayload)) {
      return;
    }

    final gameCartelaId = normalizedPayload['gameCartelaId'] as String?;
    if (_shouldDeferClaimSocketForCartela(gameCartelaId)) {
      setState(() {
        _pendingWinnerWindowPayload = normalizedPayload;
      });
      return;
    }

    _applyWinnerWindowEventPayload(normalizedPayload);
  }

  void _applyWinnerWindowEventPayload(Map<String, dynamic> payload) {
    _applyWinnerWindowState(
      winnerWindowEndsAt: _parseWinnerWindowEndsAt(
        payload['winnerWindowEndsAt'],
      ),
    );

    final gameCartelaId = payload['gameCartelaId'] as String?;
    final cartelaNumber = _cartelaNumberFromPayload(payload);
    final completedPatterns = CompletedPatternModel.parseList(
      payload['completedPatterns'],
    );
    final lastCalledNumber = parseSessionWinnerLastCalledNumber(
      payload['lastCalledNumber'],
    );
    if (cartelaNumber != null) {
      setState(() {
        _clearSessionCheckingCartelaNumber(cartelaNumber);
        _recordSessionWinnerCartelaNumber(cartelaNumber);
      });
      _markCalledNumbersPanelDirty();
    }
    if (gameCartelaId != null && completedPatterns.isNotEmpty) {
      setState(() {
        _storeClaimWinningSnapshot(
          gameCartelaId: gameCartelaId,
          patterns: completedPatterns,
          lastCalledNumber: lastCalledNumber,
        );
      });
    }

    _releaseCalledNumbersStripHoldIfIdle();
    _scheduleCanonicalRefetch(reason: 'winner_window_enrich');
  }

  void _applyWinnerWindowState({DateTime? winnerWindowEndsAt}) {
    if (!mounted) {
      return;
    }

    final normalized = parseApiDateTime(winnerWindowEndsAt);

    if (normalized != null) {
      _countdown.winnerWindowCountdownTracker.reset();
      _countdown.nextBallPlayPhase = NextBallPlayPhase.counting;
    }

    // Never keep a finished-style winner modal open over the window countdown.
    _dismissWinnerCartelaDialogIfOpen();

    setState(() {
      if (normalized != null) {
        _countdown.winnerWindowEndsAt = normalized;
      }

      if (_game != null &&
          _game!.status != GameStatus.finished &&
          _game!.status != GameStatus.noWinner &&
          _game!.status != GameStatus.cancelled) {
        _game = _game!.copyWith(
          status: GameStatus.winnerWindow,
          winnerWindowEndsAt: normalized ?? _game!.winnerWindowEndsAt,
          canRegister: false,
          registrationOpen: false,
        );
        if (normalized == null && _game!.winnerWindowEndsAt != null) {
          _countdown.winnerWindowEndsAt = _game!.winnerWindowEndsAt;
        }
      }
    });
    _refreshLocalOperationsSnapshotIfNeeded();
    _markCalledNumbersPanelDirty();
    _syncWinnerWindowTicker();
    _syncNextBallCountdownTicker();
  }

  /// Keep local operations aligned when game state advances from socket events
  /// before the next operations/current refetch.
  void _refreshLocalOperationsSnapshotIfNeeded() {
    final game = _game;
    if (game == null) {
      return;
    }

    _lastOperations = localOperationsSnapshotForGame(
      game,
      serverNow: _serverClock.nowUtc(),
    );
  }

  int _countNewCalledNumbers(List<CalledNumberModel> incoming) =>
      _cn.countNewCalledNumbers(incoming);

  Future<void> _hydrateCalledNumbersWithStagger(
    List<CalledNumberModel> incoming, {
    required int generation,
  }) {
    return _cn.hydrateCalledNumbersWithStagger(
      incoming: incoming,
      generation: generation,
      isCurrentLoad: _isCurrentLoad,
      safeSetState: _safeSetState,
    );
  }

  void _syncWinnerWindowWinnerResultsPreload() {
    _review.syncWinnerWindowPreloadPolling(
      windowEndsAt: _effectiveWinnerWindowEndsAt,
      resultsForDisplay: _sessionWinnerResultsForDisplay,
      fetch: _fetchSessionWinnerResultsIfNeeded,
    );
  }

  void _syncWinnerWindowTicker() {
    _countdown.syncWinnerWindowTicker(
      shouldRunWinnerWindowTicker:
          _game?.status == GameStatus.winnerWindow &&
          _effectiveWinnerWindowEndsAt != null,
      onExpired: _enterFinishedReviewFromExpiredWindow,
      onPollSessionWinners: _shouldPollSessionWinnerResults
          ? _syncSessionWinnerResultsPolling
          : null,
      onPreloadSessionWinners: _syncWinnerWindowWinnerResultsPreload,
    );
  }

  void _onGameFinished(dynamic payload) {
    if (!mounted) {
      return;
    }

    final normalizedPayload = _normalizeSocketPayloadForEvent(
      payload,
      eventName: 'game:finished',
      includeCalledNumbers: true,
    );
    if (normalizedPayload == null) {
      return;
    }

    if (!_eventAffectsCurrentGameFromPayload(normalizedPayload)) {
      return;
    }

    _realtime.requestTerminalCanonicalRefetch(
      reason: 'game_finished',
      wallet: !_isGuest,
      registrationSessionId: _game?.sessionId,
      includeCalledNumbers: true,
      includeMyCartelas: false,
    );
  }

  void _startPostGameSummary({required bool scheduleAdvance}) {
    _review.startPostGameSummary(
      scheduleAdvance: scheduleAdvance,
      onStarted: () {
        _syncCalledNumbersForFinishedReview();
        unawaited(
          _fetchSessionWinnerResultsIfNeeded(force: true).whenComplete(() {
            if (mounted) {
              _maybeAutoShowWinnerCartelaDialog();
            }
          }),
        );
        unawaited(_prefetchNextRegistrationDuringReview());
      },
      scheduleAdvanceToNextGame: _scheduleAdvanceToNextGame,
    );
  }

  void _syncPostGameSummaryCountdownTicker() {
    _review.syncPostGameSummaryCountdownTicker();
  }

  Widget? _buildPostGameSummaryBanner() {
    if (!_showsPostGameSummary) {
      return null;
    }

    final winnerNumbers = winnerCartelaNumbersForStrip(
      useSessionWideOutcomeChips: true,
      sessionWinnerCartelaNumbers: _review.sessionWinnerCartelaNumbers,
      myCartelas: _myCartelas,
    );

    return RoundFinishedBanner(
      isLoading: _review.sessionWinnerResultsLoading,
      isLoaded: _review.sessionWinnerResultsLoaded,
      results: _sessionWinnerResultsForDisplay,
      winnerCartelaNumbers: winnerNumbers,
      isNoWinner: _game?.status == GameStatus.noWinner,
      secondsRemaining: postGameSummarySecondsRemaining(
        shownAt: _review.postGameSummaryShownAt,
        now: _countdownNow(),
        minimumHold: _postGameSummaryHold,
      ),
      isAdvancing: _review.postGameSummaryAdvancing,
      onNext: _onPostGameSummaryNextTapped,
      onOpenWinners: _sessionWinnerResultsForDisplay.isEmpty
          ? null
          : () => _showWinnerCartelaDialogForReview(
              _sessionWinnerResultsForDisplay,
            ),
    );
  }

  void _beginPostGameSummaryAdvance() {
    _dismissWinnerCartelaDialogIfOpen();
    _review.beginPostGameSummaryAdvance();
  }

  void _onPostGameSummaryNextTapped() {
    if (!_review.postGameSummaryReviewActive || _review.postGameSummaryAdvancing) {
      return;
    }

    _beginPostGameSummaryAdvance();
    unawaited(_runFinishedAdvanceSequence(force: true));
  }

  /// Restarts the post-game summary hold when canonical data confirms FINISHED
  /// but a stale refetch cleared the timer while merged status stayed terminal.
  void _ensurePostGameSummaryHoldIfNeeded() {
    if (_game?.status != GameStatus.finished &&
        _game?.status != GameStatus.noWinner) {
      return;
    }

    if (!_review.postGameSummaryReviewActive &&
        _livePresentationPhase != LivePresentationPhase.review &&
        !_showsPostGameSummary) {
      return;
    }

    if (!_review.postGameSummaryReviewActive) {
      _startPostGameSummary(scheduleAdvance: true);
      return;
    }

    if (_review.finishTransitionTimer == null || !_review.finishTransitionTimer!.isActive) {
      _scheduleAdvanceToNextGame();
    }
  }

  void _clearPostGameSummaryHold({
    WinnerPatternClearReason patternClearReason =
        WinnerPatternClearReason.clearSessionScopedReview,
    bool clearWinnerPatterns = true,
  }) {
    _dismissWinnerCartelaDialogIfOpen();
    _review.clearPostGameSummaryHold(
      resetRegistrationCountdown: _resetRegistrationCountdownAfterSummary,
      patternClearReason: patternClearReason,
      clearWinnerPatterns: clearWinnerPatterns,
    );
  }

  void _resetRegistrationCountdownAfterSummary() {
    _countdown.registrationCountdownClosed = false;
  }

  bool get _postGameSummaryHoldElapsed => _review.isPostGameSummaryHoldElapsed;

  void _scheduleAdvanceToNextGame() {
    _review.scheduleAdvanceToNextGame(
      runFinishedAdvanceSequence: _runFinishedAdvanceSequence,
    );
  }

  bool get _isTerminalGameStatus =>
      _game?.status == GameStatus.finished ||
      _game?.status == GameStatus.noWinner ||
      _game?.status == GameStatus.cancelled;

  Future<void> _runFinishedAdvanceSequence({bool force = false}) async {
    final shouldHonorReviewHold =
        _review.postGameSummaryReviewActive && !_review.postGameSummaryHoldBypassed;
    if (!mounted ||
        (!force && shouldHonorReviewHold && !_postGameSummaryHoldElapsed)) {
      if (!force) {
        _scheduleAdvanceToNextGame();
      }
      return;
    }

    if (!_review.postGameSummaryAdvancing) {
      _beginPostGameSummaryAdvance();
    }

    final finishedSessionId = _game?.sessionId;

    final advanced = await _advanceToNextGame(
      onlyIfRegistrationAvailable: true,
      force: force,
    );
    if (!mounted) {
      return;
    }

    if (advanced || !_isTerminalGameStatus) {
      if (advanced &&
          finishedSessionId != null &&
          finishedSessionId.isNotEmpty) {
        unawaited(_clearPersistedMarksForSession(finishedSessionId));
      }
      return;
    }

    if (_review.postGameSummaryAdvancing && mounted) {
      setState(() => _review.postGameSummaryAdvancing = false);
    }
  }

  Future<bool> _advanceToNextGame({
    bool onlyIfRegistrationAvailable = false,
    bool force = false,
  }) async {
    if (!mounted) {
      return false;
    }

    if (!force &&
        _review.postGameSummaryReviewActive &&
        !_review.postGameSummaryHoldBypassed &&
        !_postGameSummaryHoldElapsed) {
      _scheduleAdvanceToNextGame();
      return false;
    }

    final currentGame = _game;
    if (currentGame == null) {
      await _loadInitialState(showLoading: false);
      return _game != null;
    }

    if (currentGame.status != GameStatus.finished &&
        currentGame.status != GameStatus.noWinner &&
        currentGame.status != GameStatus.cancelled) {
      return false;
    }

    try {
      final operations = await _gamesRepository.getCurrentGameOperations();
      if (!mounted) {
        return false;
      }

      final nextGame = operations.resolveAdvanceTargetFor(
        terminalGame: currentGame,
      );

      if (nextGame == null ||
          (onlyIfRegistrationAvailable &&
              (nextGame.status != GameStatus.ready || !nextGame.canRegister))) {
        _clearPostGameSummaryHold(
          patternClearReason: WinnerPatternClearReason.sessionChanged,
          clearWinnerPatterns: false,
        );
        await _loadInitialState(
          showLoading: false,
          allowTerminalTransition: true,
        );
        return _game == null ||
            (_game?.status == GameStatus.ready &&
                (_game?.canRegister ?? false));
      }

      await _loadInitialState(
        showLoading: false,
        allowTerminalTransition: true,
        advanceTarget: nextGame,
      );
      if (_game?.status != GameStatus.finished &&
          _game?.status != GameStatus.noWinner &&
          _game?.status != GameStatus.cancelled) {
        _clearPostGameSummaryHold(
          patternClearReason: WinnerPatternClearReason.sessionChanged,
        );
        final advancedGame = _game;
        if (advancedGame != null &&
            advancedGame.status == GameStatus.ready &&
            advancedGame.canRegister) {
          _syncRegistrationCountdownDeadline(game: advancedGame);
        }
        if (mounted) {
          setState(() {});
          if (_game?.sessionId != null) {
            ref.invalidate(registrationStateProvider(_game!.sessionId!));
          }
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ignore: unused_element
  void _showGameFinishedSnackbar({required bool didWin}) {
    final game = _game;
    if (game == null) return;

    if (didWin) {
      final myPayoutAmount = _myWinnerPayoutAmount(game);
      final message = myPayoutAmount != null
          ? '🎉 You won ${formatMoney(myPayoutAmount)} ETB'
          : 'You won! Prize is being updated.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          duration: _snackbarDuration,
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: _snackbarDuration,
          content: const Text('Game finished. Better luck next time!'),
        ),
      );
    }
  }

  void _onWalletUpdated(dynamic payload) {
    if (!mounted) {
      return;
    }

    final normalizedPayload = _normalizeSocketPayloadForEvent(
      payload,
      eventName: 'wallet:updated',
      scheduleRefetchOnInvalid: false,
    );
    if (normalizedPayload != null) {
      LiveRealtimeDebug.socket('wallet:updated', normalizedPayload);
    }

    if (!_isGuest) {
      ref.invalidate(myWalletProvider);
    }

    if (_awaitingPrizeWalletRefresh && mounted) {
      _awaitingPrizeWalletRefresh = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _winnerMessage(
              includeWalletHint: false,
              prizeAmount: _game?.prizeAmount,
            ),
          ),
          duration: _snackbarDuration,
        ),
      );
    }
  }

  Set<String> get _myCartelaIds =>
      _myCartelas.map((cartela) => cartela.cartelaId).toSet();

  String? _myWinnerPayoutAmount(GameModel game) {
    return game.myWinnerPayoutAmount(_myCartelaIds);
  }

  String _winnerMessage({
    required bool includeWalletHint,
    required String? prizeAmount,
  }) {
    final prizeText = (prizeAmount != null && prizeAmount.isNotEmpty)
        ? ' ${formatMoney(prizeAmount)}'
        : '';

    if (includeWalletHint) {
      return 'Bingo approved! You won.$prizeText prize payout will reflect in your wallet shortly.';
    }

    return 'Prize received in wallet.$prizeText';
  }

  DateTime? _parseWinnerWindowEndsAt(Object? raw) => parseApiDateTime(raw);

  DateTime? _parseNextAutoCallAtValue(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is String) {
      return parseApiDateTime(raw);
    }
    if (raw is DateTime) {
      return raw.toLocal();
    }
    return null;
  }

  Future<void> _recoverCalledNumbersAfterSocketGap() async {
    final recovered = await _cn.refetchCalledNumbersOnly();
    if (!mounted) {
      return;
    }

    final game = _game;
    if (!recovered &&
        game != null &&
        (_cn.deferredCalledNumbers.isNotEmpty || _cn.detectsCountDrift(game))) {
      LiveRealtimeDebug.log(
        'number_called_gap_recovery_failed recovery=canonical',
      );
      _scheduleCanonicalRefetch(includeCalledNumbers: true);
    }
  }

  void _applyAutoCallScheduleFromPayload(Map<String, dynamic> payload) {
    final game = _game;
    if (game == null) {
      return;
    }

    final hasNextAutoCallAt = payload.containsKey('nextAutoCallAt');
    final nextAutoCallAt = hasNextAutoCallAt
        ? _parseNextAutoCallAtValue(payload['nextAutoCallAt'])
        : game.nextAutoCallAt;
    final intervalRaw = payload['autoCallIntervalMs'];
    final autoCallIntervalMs = intervalRaw is num
        ? intervalRaw.round()
        : game.autoCallIntervalMs;
    final autoCallEnabled = parseAutoCallEnabledFromPayload(payload);
    final scheduleChanged = hasNextAutoCallAt &&
        !dateTimesEqualForSchedule(nextAutoCallAt, game.nextAutoCallAt);
    final intervalChanged =
        intervalRaw is num && autoCallIntervalMs != game.autoCallIntervalMs;

    if (!scheduleChanged &&
        autoCallEnabled == null &&
        !intervalChanged) {
      return;
    }

    setState(() {
      if (autoCallEnabled != null) {
        _cn.socketAutoCallEnabled = autoCallEnabled;
      }
      _game = game.copyWith(
        nextAutoCallAt: hasNextAutoCallAt
            ? nextAutoCallAt
            : game.nextAutoCallAt,
        autoCallIntervalMs: autoCallIntervalMs,
      );
    });

    final updatedGame = _game!;
    if (scheduleChanged || autoCallEnabled != null || intervalChanged) {
      _countdown.onNextBallScheduleChanged(
        game: updatedGame,
        nextAutoCallAt: updatedGame.nextAutoCallAt,
        scheduleChanged: scheduleChanged,
      );
      if (scheduleChanged) {
        _syncNextBallCountdownTicker();
      }
    }

    LiveRealtimeDebug.log('auto_call_schedule_applied refresh=false');
  }

  bool _shouldDeferClaimSocketForCartela(String? gameCartelaId) {
    return _cn.claimStripHoldActive &&
        gameCartelaId != null &&
        _cn.claimingCartelaIds.contains(gameCartelaId);
  }

  void _flushPendingClaimSocketEvents() {
    final winnerPayload = _pendingWinnerWindowPayload;
    _pendingWinnerWindowPayload = null;
    if (winnerPayload != null) {
      _applyWinnerWindowEventPayload(winnerPayload);
    }

    final invalidPayload = _pendingBingoInvalidPayload;
    _pendingBingoInvalidPayload = null;
    if (invalidPayload != null) {
      _applyBingoInvalidPayload(invalidPayload);
    }
  }

  String? get _marksUserId => ref.read(authControllerProvider).session?.user.id;

  void _resetManualMarksForSession({
    required String? sessionId,
    required String? userId,
  }) {
    _cn.manualMarkedNumbers.clear();
    _cn.lastManualMarkedKey = null;
    _cn.marksSessionId = sessionId;
    _cn.marksOwnerUserId = userId;
    _cn.restoredMarksSessionId = null;
  }

  void _freezeBlockedCartela(GameCartelaModel cartela) {
    final cartelaMarks = manualMarksForCartela(
      cartela: cartela,
      manualMarkedNumbers: _cn.effectiveMarkedNumbers,
    );
    _cn.blockedCartelaFrozenMarks[cartela.id] = cartelaMarks;

    final game = _game;
    if (game != null) {
      _cn.blockedCartelaFrozenSortResults[cartela.id] =
          CartelaMarkedPatternEvaluator.evaluate(
            cartela: cartela,
            manualMarkedNumbers: cartelaMarks,
            ruleKey: game.ruleKey,
          );
    }
  }

  void _ensureBlockedCartelaSnapshots() {
    for (final cartela in _myCartelas) {
      if (cartela.status == GameCartelaStatus.blocked &&
          !_cn.blockedCartelaFrozenMarks.containsKey(cartela.id)) {
        _freezeBlockedCartela(cartela);
      }
    }
  }

  @override
  Set<String> _markedNumbersForCartela(GameCartelaModel cartela) {
    if (cartela.status == GameCartelaStatus.blocked) {
      return _cn.blockedCartelaFrozenMarks[cartela.id] ??
          manualMarksForCartela(
            cartela: cartela,
            manualMarkedNumbers: _cn.effectiveMarkedNumbers,
          );
    }

    return manualMarksForCartela(
      cartela: cartela,
      manualMarkedNumbers: _cn.effectiveMarkedNumbers,
    );
  }

  @override
  CartelaPatternUiResult? _sortResultForCartela(GameCartelaModel cartela) {
    if (cartela.status == GameCartelaStatus.blocked) {
      return _cn.blockedCartelaFrozenSortResults[cartela.id];
    }

    return null;
  }

  String _buildCartelaSortSignature() {
    final game = _game;
    final marks = normalizeManualMarkedNumbers(_cn.effectiveMarkedNumbers).toList()
      ..sort();
    final cartelaState = _myCartelas
        .map(
          (cartela) =>
              '${cartela.id}:${cartela.status.name}:${cartela.isWinner}:${cartela.blockedAt?.millisecondsSinceEpoch ?? 0}',
        )
        .join('|');

    return '${game?.ruleKey ?? 'no-rule'}::$cartelaState::${marks.join('|')}';
  }

  void _sortMyCartelas() {
    final game = _game;
    if (game == null || _myCartelas.isEmpty) {
      _cn.cartelaSortSignature = null;
      _cn.cartelaSortResults = const {};
      return;
    }

    final signature = _buildCartelaSortSignature();
    if (_cn.cartelaSortSignature == signature) {
      return;
    }

    _ensureBlockedCartelaSnapshots();

    final evaluated = <String, CartelaPatternUiResult>{};
    for (final cartela in _myCartelas) {
      evaluated[cartela.id] = CartelaMarkedPatternEvaluator.evaluate(
        cartela: cartela,
        manualMarkedNumbers: _markedNumbersForCartela(cartela),
        ruleKey: game.ruleKey,
      );
    }

    _cn.cartelaSortResults = {
      for (final entry in evaluated.entries)
        entry.key: _cn.blockedCartelaFrozenSortResults[entry.key] ?? entry.value,
    };
    _cn.cartelaSortSignature = signature;
  }

  @override
  Future<void> _persistManualMarks() async {
    final userId = _marksUserId;
    final sessionId = _game?.sessionId ?? _cn.marksSessionId;
    if (userId == null || sessionId == null || sessionId.isEmpty) {
      return;
    }

    try {
      final storage = await ref.read(cartelaMarksStorageProvider.future);
      await storage.save(
        userId: userId,
        gameSessionId: sessionId,
        marks: normalizeManualMarkedNumbers(_cn.manualMarkedNumbers),
      );
      _cn.marksOwnerUserId = userId;
      _cn.restoredMarksSessionId = sessionId;
    } catch (_) {}
  }

  @override
  void _ensureManualMarksReadyForActiveSession() {
    if (_isGuest) {
      if (_cn.manualMarkedNumbers.isNotEmpty ||
          _cn.lastManualMarkedKey != null ||
          _cn.marksOwnerUserId != null ||
          _cn.restoredMarksSessionId != null) {
        setState(() {
          _resetManualMarksForSession(
            sessionId: _game?.sessionId,
            userId: null,
          );
        });
      }
      return;
    }

    final sessionId = _game?.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      if (_cn.manualMarkedNumbers.isNotEmpty ||
          _cn.lastManualMarkedKey != null ||
          _cn.marksSessionId != null ||
          _cn.restoredMarksSessionId != null) {
        setState(() {
          _resetManualMarksForSession(sessionId: null, userId: null);
        });
      }
      return;
    }

    unawaited(_ensureManualMarksReadyForSession(sessionId));
  }

  Future<void> _ensureManualMarksReadyForSession(String sessionId) async {
    final userId = _marksUserId;
    if (userId == null || sessionId.isEmpty || _isGuest) {
      return;
    }

    if (_cn.marksOwnerUserId != null && _cn.marksOwnerUserId != userId) {
      if (!mounted) {
        return;
      }
      setState(() {
        _resetManualMarksForSession(sessionId: sessionId, userId: userId);
      });
    }

    if (_cn.restoredMarksSessionId == sessionId && _cn.marksOwnerUserId == userId) {
      return;
    }

    try {
      final storage = await ref.read(cartelaMarksStorageProvider.future);
      final restored = await storage.load(
        userId: userId,
        gameSessionId: sessionId,
      );
      if (!mounted || _game?.sessionId != sessionId) {
        return;
      }
      final normalizedResolved = normalizeManualMarkedNumbers(restored);

      setState(() {
        _cn.manualMarkedNumbers
          ..clear()
          ..addAll(normalizedResolved);
        _cn.lastManualMarkedKey = null;
        _cn.marksSessionId = sessionId;
        _cn.marksOwnerUserId = userId;
        _cn.restoredMarksSessionId = sessionId;
        _sortMyCartelas();
      });

      LiveRealtimeDebug.log(
        'restored ${normalizedResolved.length} manual marks',
      );
    } catch (_) {}
  }

  Future<void> _clearPersistedMarksForSession(String? sessionId) async {
    final userId = _marksUserId;
    if (userId == null || sessionId == null || sessionId.isEmpty) {
      return;
    }

    try {
      final storage = await ref.read(cartelaMarksStorageProvider.future);
      await storage.clear(userId: userId, gameSessionId: sessionId);
    } catch (_) {}
  }
}
