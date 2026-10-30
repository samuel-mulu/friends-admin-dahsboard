part of 'live_game_screen.dart';

class _OperationsSyncRequestContext {
  const _OperationsSyncRequestContext({
    required this.activeSessionId,
    required this.registrationSessionId,
  });

  final String? activeSessionId;
  final String? registrationSessionId;
}

class _OperationsSyncSnapshot {
  const _OperationsSyncSnapshot({
    required this.fetchResult,
    required this.requestContext,
  });

  final OperationsSyncFetchResult fetchResult;
  final _OperationsSyncRequestContext requestContext;
}

abstract class _LiveGameScreenStateBase extends ConsumerState<LiveGameScreen>
    with WidgetsBindingObserver
    implements LiveGameHost {
  @override
  late LiveGameControllers controllers;

  @override
  bool get embedded => widget.embedded;

  @override
  bool get isAppInForeground => _isAppInForeground;

  @override
  String? get gameId => widget.gameId;

  @override
  GameModel? get initialGame => widget.initialGame;

  @override
  GamesRepository get gamesRepository => _gamesRepository;

  @override
  CartelasRepository get cartelasRepository => _cartelasRepository;

  @override
  SocketService get socketService => _socketService;

  @override
  ServerClockService get serverClock => _serverClock;

  @override
  void markNeedsBuild([VoidCallback? fn]) {
    if (!isLiveHostActive) {
      return;
    }

    void apply() {
      if (!isLiveHostActive) {
        return;
      }
      LiveCartelaScrollDebug.fullScreenRebuild();
      if (fn != null) {
        setState(fn);
      } else {
        setState(() {});
      }
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.midFrameMicrotasks ||
        phase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
      return;
    }

    apply();
  }

  void _runAfterBuild(VoidCallback fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      fn();
    });
  }

  void _playGameSound(
    SoundEvent event, {
    String? sessionId,
    String? dedupeKey,
  }) {
    if (!isLiveHostActive) {
      return;
    }
    final game = _game;
    unawaited(
      ref
          .read(gameSoundServiceProvider)
          .play(
            event,
            sessionId: sessionId ?? game?.sessionId,
            dedupeKey: dedupeKey,
            // A Chain Game replays the one-shot cues every round inside one session.
            roundKey: game != null && game.isChainGame
                ? game.displayRoundIndex
                : null,
          ),
    );
  }

  /// True while this screen can safely use [ref] and [setState].
  @override
  bool get isLiveHostActive => mounted && !_hostTornDown;

  bool _hostTornDown = false;
  String? _cachedMarksUserId;
  CartelaMarksStorage? _cartelaMarksStorage;
  late final ServerClockService _serverClock;

  @override
  List<GameCartelaModel> get myCartelas => _registration.myCartelas;

  LiveRegistrationController get _registration => controllers.registration;

  LiveReviewController get _review => controllers.review;

  LiveCalledNumbersController get _cn => controllers.calledNumbers;

  List<GameCartelaModel> get _myCartelas => _registration.myCartelas;

  set _myCartelas(List<GameCartelaModel> value) {
    _registration.myCartelas = value;
  }

  List<GameCartelaModel> get _nextRegistrationCartelas =>
      _registration.nextRegistrationCartelas;

  set _nextRegistrationCartelas(List<GameCartelaModel> value) {
    _registration.nextRegistrationCartelas = value;
  }

  @override
  LiveUiModeState get liveUiMode => _liveUiMode;
  bool _isLoading = true;
  String? _errorMessage;
  String? _emptyMessage;
  GameModel? _game;
  String? _joinedGameId;
  List<String> _myCartelaDisplayOrderIds = const [];
  final Map<String, Map<String, dynamic>> _pendingWinnerWindowPayloads = {};
  final Map<String, Map<String, dynamic>> _pendingBingoInvalidPayloads = {};
  bool _awaitingPrizeWalletRefresh = false;
  Timer? _liveRoomSplashTicker;
  bool _awaitingLiveRoom = true;
  bool _initialLoadComplete = false;
  bool _hasCompletedInitialPaint = false;
  DateTime? _liveRoomSplashStartedAt;
  int _loadGeneration = 0;
  ProviderSubscription<AuthState>? _authSessionSubscription;
  ProviderSubscription<AsyncValue<FeatureSettingsUiState>>?
  _featureSettingsSubscription;
  LivePresentationPhase? _lastDebugPhase;
  final bool _isSyncingLiveGame = false;

  /// True while cartela list is idle — false during scroll so pulses don't fight the gesture.
  final ValueNotifier<bool> _liveCartelaScrollIdle = ValueNotifier<bool>(true);

  /// Smart/Lines grid order updates deferred until scroll idle.
  bool _pendingCartelaSortDisplayApply = false;

  List<GameCartelaModel>? _frozenPlayCartelaOrder;

  int? _lastCalledNumbersDirtyCount;
  int? _lastCalledNumbersDirtyOrder;

  late final LiveCartelaLiveStore _cartelaLiveStore = LiveCartelaLiveStore();

  LiveCartelaLiveStore get cartelaLiveStore => _cartelaLiveStore;
  Timer? _invalidSocketPayloadRefetchTimer;
  String? _lastInvalidSocketPayloadLogKey;
  DateTime? _lastInvalidSocketPayloadLogAt;
  GameTimingConfigModel? _timingConfig;
  bool _timingConfigLoaded = false;
  GameModel? _nextUpcomingGame;
  GameOperationsCurrentResponse? _lastOperations;

  /// After finish/cancel with no next READY, ignore ops terminal fallback for
  /// this session until a real next game appears.
  String? _releasedIdleTerminalSessionId;
  bool _hasBlockingLiveGame = false;
  List<int>? _pendingAutoOpenCartelaNumbers;
  Timer? _myCartelasRefreshDebounceTimer;
  Timer? _nextCartelasRefreshDebounceTimer;
  final LiveSocketSessionMembership _socketMembership =
      LiveSocketSessionMembership();
  bool _gameInfoExpanded = false;
  String? _autoExpandedForNextGameSessionId;
  DateTime? _lastSocketAppliedAt;
  bool _listenersRegistered = false;
  bool _isAppInForeground = true;

  static const _liveRoomSplashMinimum = Duration(milliseconds: 1500);
  static const _liveRoomSplashMaximum = Duration(seconds: 15);

  GameTimingConfigModel get _effectiveTimingConfig =>
      _timingConfig ?? GameTimingConfigModel.fallback;

  Duration get _postGameSummaryHold => _review.postGameSummaryHold;

  Duration get _snackbarDuration => const Duration(seconds: 4);

  bool get _hasVisibleCurrentSessionCartelas => _myCartelas.isNotEmpty;

  bool get _embeddedBigGame =>
      widget.embedded &&
      (_game?.isBigGame ?? widget.initialGame?.isBigGame ?? false);

  bool get _suppressEmbeddedBigGameEmptyCartelaState =>
      shouldSuppressEmbeddedBigGameEmptyCartelaState(
        embeddedBigGame: _embeddedBigGame,
        isGuest: isGuest,
        hasPrimarySessionCartelas: _hasVisibleCurrentSessionCartelas,
        initialLoadComplete: _initialLoadComplete,
        isLoading: _isLoading,
        resumeSyncInFlight: controllers.realtime.resumeSyncInFlight,
        canonicalRefetchInFlight: controllers.realtime.canonicalRefetchInFlight,
      );

  DateTime? get _resolverWinnerWindowEndsAt {
    if (_game?.status != GameStatus.winnerWindow) {
      return null;
    }
    return _game?.winnerWindowEndsAt ??
        controllers.countdown.winnerWindowEndsAt;
  }

  bool get _resolverWinnerWindowExpired => isWinnerWindowExpired(
    status: _game?.status,
    windowEndsAt: _resolverWinnerWindowEndsAt,
    now: _countdownNow(),
  );

  bool get _resolverPinsTerminalSession {
    final game = _game;
    if (game == null) {
      return false;
    }
    return _review.pinsTerminalSession(game);
  }

  bool get _suppressNextGameQueueHint {
    return _livePresentationPhase == LivePresentationPhase.winnerWindow ||
        _livePresentationPhase == LivePresentationPhase.checking ||
        _livePresentationPhase == LivePresentationPhase.review;
  }

  bool get _currentReadyCountdownDeferredByLiveGame =>
      _liveUiMode.hideRegistrationCountdown &&
      _game?.status == GameStatus.ready &&
      (_game?.canRegister ?? false);

  bool get _ownsLiveSessionCartelas {
    if (!_hasVisibleCurrentSessionCartelas) {
      return false;
    }
    final ops = _lastOperations;
    final liveSessionId =
        ops?.liveGame?.sessionId ?? ops?.checkingGame?.sessionId;
    return ownsLiveSessionCartelas(
      liveSessionId: liveSessionId,
      primarySessionId: _game?.sessionId,
      cartelaSessionIds: _myCartelas.map((cartela) => cartela.gameId),
    );
  }

  /// Local round that already advanced to a live status and holds this player's
  /// cartelas, used only while `operations/current` still lags behind.
  GameModel? get _ownedLiveGameFallback {
    if (isGuest) {
      return null;
    }
    final game = _game;
    if (game == null || !keepsOwnedLiveGamePrimary(game.status)) {
      return null;
    }
    final sessionId = game.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return null;
    }
    return ownsSessionByCartelas(
          sessionId,
          _myCartelas.map((cartela) => cartela.gameId),
        )
        ? game
        : null;
  }

  /// Cartela session ids used for missed-preview ownership (current + next).
  Iterable<String> get _ownershipCartelaSessionIds sync* {
    for (final cartela in _myCartelas) {
      yield cartela.gameId;
    }
    for (final cartela in _nextRegistrationCartelas) {
      yield cartela.gameId;
    }
  }

  Widget _buildMissedLivePreviewSection() {
    // Big Game embeds LiveGameScreen; never show other-game missed preview there.
    if (widget.embedded) {
      return const SizedBox.shrink();
    }

    final observer = controllers.missedPreview;
    return ValueListenableBuilder<int>(
      valueListenable: observer.revision,
      builder: (context, _, child) {
        final previewResolution = observer.resolution;
        final previewSession = previewResolution.previewSession;
        if (!previewResolution.showPreview || previewSession == null) {
          return const SizedBox.shrink();
        }

        final previewNumbers = filterMissedPreviewCalledNumbers(
          sharedCalledNumbers: observer.calledNumbers,
          previewSessionId: previewSession.sessionId,
        );
        final previewActiveNumber = missedPreviewActiveNumber(previewNumbers);
        final previewRemaining = missedPreviewRemainingCount(
          previewSession: previewSession,
          filteredPreviewLength: observer.calledNumbers.length,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VGap.sm,
            MissedLiveGamePreview(
              key: ValueKey(
                'missed-preview-${previewSession.sessionId}-'
                '${previewResolution.phase.name}-'
                '${previewActiveNumber ?? 0}',
              ),
              session: previewSession,
              title: previewSession.localizedRuleName(ref),
              phase: previewResolution.phase,
              calledNumbers: previewNumbers,
              activeNumber: previewActiveNumber,
              remainingCount: previewRemaining,
            ),
          ],
        );
      },
    );
  }

  @override
  bool ownsSessionForPreview(String? sessionId) =>
      _ownsSessionForPreview(sessionId);

  bool _ownsSessionForPreview(String? sessionId) =>
      ownsSessionByCartelas(sessionId, _ownershipCartelaSessionIds);

  String? get _registrationGridSessionId {
    final registrationOpen = _lastOperations?.registrationOpenGame;
    if (registrationOpen?.sessionId != null &&
        registrationOpen!.sessionId!.isNotEmpty) {
      return registrationOpen.sessionId;
    }
    final game = _game;
    if (game?.status == GameStatus.ready &&
        game?.sessionId != null &&
        game!.sessionId!.isNotEmpty) {
      return game.sessionId;
    }
    return null;
  }

  bool _isRegistrationGridReady(String? sessionId) {
    if (sessionId == null || sessionId.isEmpty) {
      return false;
    }
    return ref.watch(registrationStateProvider(sessionId)).hasValue;
  }

  GameOperationsCurrentResponse? get _operationsForLiveUiMode {
    final game = _game;
    if (!_embeddedBigGame || game == null || !game.isBigGame) {
      return _lastOperations;
    }

    final now = _countdownNow();
    if (game.status == GameStatus.ready &&
        bigGameRegistrationEligible(game, now)) {
      final ops = _lastOperations;
      final regSessionId = ops?.registrationOpenGame?.sessionId;
      final liveBlocksRegistration =
          ops?.liveGame != null &&
          ops!.liveGame!.sessionId != game.sessionId &&
          keepsOwnedLiveGamePrimary(ops.liveGame!.status);
      if (ops == null ||
          !ops.hasActiveGame ||
          regSessionId != game.sessionId ||
          liveBlocksRegistration) {
        return localOperationsSnapshotForGame(game, serverNow: now);
      }
    }

    return _lastOperations;
  }

  LiveUiModeState get _liveUiMode {
    return resolveLiveUiMode(
      ResolveLiveUiModeInput(
        operations: _operationsForLiveUiMode,
        pinnedPrimaryGame: _resolverPinsTerminalSession ? _game : null,
        ownedLiveGameFallback: _ownedLiveGameFallback,
        ownsLiveSessionCartelas: _ownsLiveSessionCartelas,
        hasPrimarySessionCartelas: _hasVisibleCurrentSessionCartelas,
        calledNumbers: _cn.calledNumbers,
        holds: LiveSessionHolds(
          postGameSummaryReviewActive: _review.postGameSummaryReviewActive,
          pinTerminalSession: _resolverPinsTerminalSession,
          registrationCountdownClosed:
              controllers.countdown.registrationCountdownClosed,
          readyTransitionLock: controllers.transition.readyTransitionLockActive
              ? controllers.transition.readyTransitionLock
              : null,
          canonicalRefetchInFlight:
              controllers.realtime.canonicalRefetchInFlight,
          postGameSummaryAdvancing: _review.postGameSummaryAdvancing,
          registrationGridReady: _isRegistrationGridReady(
            _registrationGridSessionId,
          ),
        ),
        now: _countdownNow(),
        preparingStaleAfter: _preparingPhaseCap,
        isGuest: isGuest,
        isLoading: _isLoading,
        awaitingLiveRoom: _awaitingLiveRoom,
        hasError: _errorMessage != null,
        winnerWindowExpired: _resolverWinnerWindowExpired,
        excludeBigGame: !widget.embedded,
        embeddedBigGame: _embeddedBigGame,
      ),
    );
  }

  bool get _readyTransitionLockActive =>
      controllers.transition.readyTransitionLockActive;

  GameModel? get _queueUpcomingGameForDisplay {
    final nextGame = _nextUpcomingGame;
    if (nextGame == null) {
      return null;
    }
    final currentSessionId = _game?.sessionId;
    if (currentSessionId != null && nextGame.sessionId == currentSessionId) {
      return null;
    }
    return nextGame;
  }

  LiveTopSectionVariant get _liveTopSectionVariant {
    if (_livePresentationPhase.isRegistrationLayout) {
      return LiveTopSectionVariant.registration;
    }

    return LiveTopSectionVariant.livePlay;
  }

  bool get _showsGameInfoShortcutOnCalledNumbersStrip {
    return _liveTopSectionVariant == LiveTopSectionVariant.livePlay &&
        !_gameInfoExpanded;
  }

  Widget? _buildGameInfoStripLeading(BuildContext context) {
    if (!_showsGameInfoShortcutOnCalledNumbersStrip) {
      return null;
    }

    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _gameInfoExpanded = true),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Game info',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  height: 1,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  int get _cartelaHoldSeconds => _effectiveTimingConfig.cartelaHoldSeconds;

  int get _bulkSelectionSeconds =>
      _effectiveTimingConfig.bulkSelectionHoldSeconds;

  Duration get _preparingPhaseCap =>
      _effectiveTimingConfig.preparingPhaseStaleAfter;

  DateTime _countdownNow({bool useServerClock = true}) {
    if (useServerClock && _serverClock.isSynced) {
      return _serverClock.nowLocal();
    }
    return DateTime.now();
  }

  void _syncServerClockFromUtc(
    DateTime serverNowUtc, {
    bool snap = false,
    bool ignoreOlder = false,
  }) {
    controllers.countdown.syncServerClockFromUtc(
      serverNowUtc,
      snap: snap,
      ignoreOlder: ignoreOlder,
    );
  }

  // ignore: unused_element
  Future<void> _persistManualMarks() async {
    throw UnimplementedError('_persistManualMarks must be provided by mixins');
  }

  // ignore: unused_element
  void _ensureManualMarksReadyForActiveSession() {
    throw UnimplementedError(
      '_ensureManualMarksReadyForActiveSession must be provided by mixins',
    );
  }

  // ignore: unused_element
  Set<String> _markedNumbersForCartela(GameCartelaModel cartela) {
    throw UnimplementedError(
      '_markedNumbersForCartela must be provided by mixins',
    );
  }

  // ignore: unused_element
  CartelaPatternUiResult? _sortResultForCartela(GameCartelaModel cartela) {
    throw UnimplementedError(
      '_sortResultForCartela must be provided by mixins',
    );
  }

  late final GamesRepository _gamesRepository = ref.read(
    gamesRepositoryProvider,
  );
  late final CartelasRepository _cartelasRepository = ref.read(
    cartelasRepositoryProvider,
  );
  late final SocketService _socketService = ref.read(socketServiceProvider);
  HasActiveRegisteredCartelasNotifier? _activeCartelasNotifier;
  // Session ID used for API calls and socket event filtering.
  // null when the current game is a NEXT slot (no session yet).
  String? get _activeSessionId => _game?.sessionId ?? _joinedGameId;

  @override
  bool get isGuest => _cachedMarksUserId == null;

  void _syncCachedAuthSession() {
    if (_hostTornDown) {
      return;
    }
    try {
      _cachedMarksUserId = ref.read(authControllerProvider).session?.user.id;
    } catch (_) {
      _cachedMarksUserId = null;
    }
  }

  void _warmCartelaMarksStorage() {
    if (_cartelaMarksStorage != null || _hostTornDown) {
      return;
    }
    unawaited(() async {
      try {
        final storage = await ref.read(cartelaMarksStorageProvider.future);
        if (_hostTornDown) {
          return;
        }
        _cartelaMarksStorage = storage;
      } catch (_) {}
    }());
  }

  Future<CartelaMarksStorage?> _marksStorageIfHostActive() async {
    if (!isLiveHostActive) {
      return null;
    }
    if (_cartelaMarksStorage != null) {
      return _cartelaMarksStorage;
    }
    try {
      final storage = await ref.read(cartelaMarksStorageProvider.future);
      if (_hostTornDown) {
        return null;
      }
      _cartelaMarksStorage = storage;
      return storage;
    } catch (_) {
      return null;
    }
  }

  @override
  GameModel? get game => _game;

  @override
  set game(GameModel? value) => _game = value;

  @override
  GameOperationsCurrentResponse? get lastOperations => _lastOperations;

  @override
  set lastOperations(GameOperationsCurrentResponse? value) =>
      _lastOperations = value;

  @override
  GameModel? get nextUpcomingGame => _nextUpcomingGame;

  @override
  set nextUpcomingGame(GameModel? value) => _nextUpcomingGame = value;

  @override
  bool get hasBlockingLiveGame => _hasBlockingLiveGame;

  @override
  set hasBlockingLiveGame(bool value) => _hasBlockingLiveGame = value;

  @override
  bool get isLoading => _isLoading;

  @override
  set isLoading(bool value) => _isLoading = value;

  @override
  String? get errorMessage => _errorMessage;

  @override
  set errorMessage(String? value) => _errorMessage = value;

  @override
  String? get emptyMessage => _emptyMessage;

  @override
  set emptyMessage(String? value) => _emptyMessage = value;

  @override
  bool get timingConfigLoaded => _timingConfigLoaded;

  @override
  GameTimingConfigModel get effectiveTimingConfig => _effectiveTimingConfig;

  @override
  bool get awaitingLiveRoom => _awaitingLiveRoom;

  @override
  set awaitingLiveRoom(bool value) => _awaitingLiveRoom = value;

  @override
  int get loadGeneration => _loadGeneration;

  @override
  set loadGeneration(int value) => _loadGeneration = value;

  @override
  DateTime countdownNow({bool useServerClock = true}) =>
      _countdownNow(useServerClock: useServerClock);

  @override
  bool get currentReadyCountdownDeferredByLiveGame =>
      _currentReadyCountdownDeferredByLiveGame;

  @override
  Duration get preparingPhaseCap => _preparingPhaseCap;

  @override
  bool get initialLoadComplete => _initialLoadComplete;

  @override
  bool get isTerminalTransitionActive {
    final review = _review;
    final realtime = controllers.realtime;
    return review.postGameSummaryReviewActive ||
        review.postGameSummaryAdvancing ||
        isTerminalCanonicalRefetchActive(
          canonicalRefetchInFlight: realtime.canonicalRefetchInFlight,
          pendingRefetchReason: realtime.pendingRefetchReason,
          lastTerminalCanonicalRefetchRequestedAt:
              realtime.lastTerminalCanonicalRefetchRequestedAt,
          now: countdownNow(),
        );
  }

  bool get _shouldCacheTimingConfigForLivePlay {
    final game = _game;
    if (game == null) {
      return false;
    }

    return game.status == GameStatus.playing ||
        game.status == GameStatus.checking ||
        game.status == GameStatus.winnerWindow;
  }

  void _markCalledNumbersPanelDirty() {
    final count = _cn.calledNumbers.length;
    final lastOrder =
        count == 0 ? null : _cn.calledNumbers.last.order;
    if (_lastCalledNumbersDirtyCount == count &&
        _lastCalledNumbersDirtyOrder == lastOrder) {
      LiveCartelaScrollDebug.log(
        'called_numbers_dirty_skipped_duplicate count=$count order=${lastOrder ?? '-'}',
      );
      return;
    }
    _lastCalledNumbersDirtyCount = count;
    _lastCalledNumbersDirtyOrder = lastOrder;

    _cn.markCalledNumbersPanelDirty();
    refreshCartelaSortAfterCalledNumbers();
    if (_myCartelas.isEmpty) {
      return;
    }
    final latest =
        _cn.calledNumbers.isEmpty ? null : _cn.calledNumbers.last.number;
    final fullGrid = latest == null || !_cn.effectiveAutoMark;
    LiveCartelaScrollDebug.calledNumbersDirty(
      calledCount: _cn.calledNumbers.length,
      latestBall: latest,
      autoMark: _cn.effectiveAutoMark,
      fullGrid: fullGrid,
    );
    refreshCartelaLivePresentation(
      committedBallNumber: latest,
      fullGrid: fullGrid,
    );
  }

  @override
  void refreshCartelaSortAfterCalledNumbers();

  @override
  void applyPendingCartelaSortDisplayOrder();

  @override
  void freezePlayCartelaDisplayOrderForScroll();

  @override
  void refreshCartelaLivePresentation({
    int? committedBallNumber,
    bool fullGrid = false,
  });

  @override
  void refreshCartelaLiveAfterManualMark(String gameCartelaId);

  void markCanonicalSocketStateApplied() {
    _lastSocketAppliedAt = DateTime.now();
  }

  /// Syncs live-game back-guard state for hardware/app-bar back handling.
  void _syncActiveCartelasToProvider() {
    final notifier = _activeCartelasNotifier;
    if (notifier == null) {
      return;
    }

    _runAfterBuild(() {
      if (!isLiveHostActive) {
        return;
      }
      final sessionId = _activeSessionId;
      final cartelaCount = _myCartelas.length;
      notifier.updateSessionState(
        sessionId,
        cartelaCount,
        requiresLeaveConfirmation: _shouldRequireLiveGameBackConfirm,
      );
    });
  }

  bool get _shouldRequireLiveGameBackConfirm {
    if (_myCartelas.isNotEmpty) {
      return true;
    }

    if (_review.postGameSummaryReviewActive ||
        _review.postGameSummaryAdvancing) {
      return true;
    }

    switch (_livePresentationPhase) {
      case LivePresentationPhase.liveWaitingFirstBall:
      case LivePresentationPhase.liveCalling:
      case LivePresentationPhase.winnerWindow:
      case LivePresentationPhase.interRoundPause:
      case LivePresentationPhase.checking:
      case LivePresentationPhase.review:
        return true;
      case LivePresentationPhase.registrationOpen:
      case LivePresentationPhase.preparingGame:
      case LivePresentationPhase.noActiveGame:
      case LivePresentationPhase.cancelled:
      case LivePresentationPhase.noPlayersJoined:
        break;
    }

    final status = _game?.status;
    if (status != null) {
      return _gameStatusRequiresLiveGameBackConfirm(status);
    }

    return false;
  }

  bool _gameStatusRequiresLiveGameBackConfirm(GameStatus status) {
    return switch (status) {
      GameStatus.playing ||
      GameStatus.checking ||
      GameStatus.winnerWindow ||
      GameStatus.finished ||
      GameStatus.noWinner => true,
      _ => false,
    };
  }

  LivePresentationPhase get _livePresentationPhase =>
      _liveUiMode.presentationPhase;

  List<GameCartelaModel> _orderedMyCartelas([
    CartelaSortMode? sortMode,
    int maxRemainsToSort =
        CartelaMarkedPatternEvaluator.defaultMaxRemainsToSort,
  ]) {
    final mode = sortMode ?? CartelaSortMode.manual;
    final baseOrder = applyCartelaDisplayOrder(
      cartelas: _myCartelas,
      orderIds: _myCartelaDisplayOrderIds,
    );
    if (mode.allowsManualReorder) {
      return baseOrder;
    }

    return CartelaMarkedPatternEvaluator.sortCartelas(
      cartelas: baseOrder,
      resultsByCartelaId: _cn.cartelaSortResults,
      sortMode: mode,
      maxRemainsToSort: maxRemainsToSort,
    );
  }

  void _clearMyCartelaDisplayOrder() {
    _myCartelaDisplayOrderIds = const [];
  }

  void _capturePreviousCartelasForAutoOpen() {
    _pendingAutoOpenCartelaNumbers = null;
  }

  void _reorderMyCartela(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) {
      return;
    }

    final ordered = _orderedMyCartelas(CartelaSortMode.manual);
    if (fromIndex < 0 ||
        toIndex < 0 ||
        fromIndex >= ordered.length ||
        toIndex >= ordered.length) {
      return;
    }

    setState(() {
      _myCartelaDisplayOrderIds = reorderCartelaDisplayOrderIds(
        cartelas: ordered,
        fromIndex: fromIndex,
        toIndex: toIndex,
      );
    });
  }

  Future<void> openNextGameRegistrationSheet();
}
