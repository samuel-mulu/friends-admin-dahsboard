import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/auth_route_guard.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/time/countdown_target_tracker.dart';
import '../../../../core/time/server_clock_provider.dart';
import '../../../../core/time/server_clock_service.dart';
import '../../../../core/utils/api_date_time.dart';
import '../../../../core/widgets/friends_bingo_loading.dart';
import '../../domain/bulk_register_result.dart';
import '../../domain/cartela_availability.dart';
import '../../domain/game_rule_localized_name.dart';
import '../../domain/game_category_theme.dart';
import '../utils/registration_error_helpers.dart';
import '../utils/cartela_mark_helpers.dart';
import '../utils/cartela_marked_pattern_evaluator.dart';
import '../utils/cartela_pattern_progress_overlay.dart';
import '../widgets/called_numbers_strip.dart';
import '../widgets/cartela_number_chip.dart';
import '../../domain/cartela_board_preview_cache.dart';
import '../widgets/bulk_cartela_review_sheet.dart';
import '../widgets/cartela_registration_sheet.dart';
import '../widgets/collapsible_live_top_section.dart';
import '../widgets/live_next_round_registration_section.dart';
import '../widgets/live_cartela_card.dart';
import '../widgets/round_finished_banner.dart';
import '../widgets/winner_cartela_dialog.dart';
import '../widgets/registration_action_dock.dart';
import '../widgets/registration_cartela_grid.dart';
import '../widgets/registration_grid_scroll_isolation.dart';
import '../widgets/registration_tap_hint.dart';
import '../widgets/realtime_branding_overlay.dart';
import '../widgets/big_game_live_prompt_banner.dart';
import '../controllers/live_called_numbers_controller.dart';
import '../controllers/live_countdown_controller.dart';
import '../controllers/live_countdown_tick_context.dart';
import '../controllers/live_game_controllers.dart';
import '../controllers/live_game_host.dart';
import '../controllers/live_registration_controller.dart';
import '../controllers/live_review_controller.dart';
import '../controllers/registration_action_result.dart';
import '../controllers/registration_panel_session.dart';
import '../controllers/live_realtime_controller.dart';
import '../controllers/live_transition_controller.dart';
import '../utils/cartela_outcome_public_visibility.dart';
import '../utils/live_ready_transition_lock.dart';
import '../utils/live_presentation_phase.dart';
import '../utils/live_ui_mode.dart';
import '../utils/live_primary_game_selection.dart';
import '../utils/live_registration_target.dart';
import '../utils/live_registration_visibility.dart';
import '../utils/live_registration_metrics_patch.dart';
import '../utils/registration_reg_display_count.dart';
import '../utils/cartela_display_order.dart';
import '../utils/merge_registered_cartelas.dart';
import '../utils/live_game_event_guard.dart';
import '../utils/live_game_finish_transition.dart';
import '../utils/live_terminal_enter_policy.dart';
import '../utils/winner_pattern_clear_policy.dart';
import '../utils/live_socket_session_membership.dart';
import '../utils/registration_cartela_grid_index.dart';
import '../utils/next_ball_countdown.dart';
import '../utils/next_ball_stale_guard.dart';
import '../utils/number_called_schedule_patch.dart';
import '../utils/number_called_status_policy.dart';
import '../utils/live_status_socket_patch.dart';
import '../utils/live_sync_trigger_action.dart';
import '../utils/socket_payload_normalizer.dart';
import '../../../../core/sync/resume_sync_guard.dart';
import '../utils/live_resume_sync.dart';
import '../utils/live_resume_terminal_gate.dart';
import '../debug/live_realtime_debug.dart';
import '../widgets/registration_open_pulse.dart';
import '../widgets/winner_window_countdown.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/widgets/guest_auth_prompt_sheet.dart';
import '../../../settings/presentation/providers/theme_mode_provider.dart';
import '../../../wallet/data/models/wallet_model.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../data/games_repository.dart';
import '../../data/models/bingo_claim_result.dart';
import '../../data/models/called_number_model.dart';
import '../../data/models/cartela_model.dart';
import '../../data/models/game_cartela_model.dart';
import '../../data/models/game_model.dart';
import '../../data/models/completed_pattern_model.dart';
import '../../data/models/game_timing_config_model.dart';
import '../../data/models/session_winner_result_model.dart';
import '../../data/models/session_outcome_summary_model.dart';
import '../providers/games_providers.dart';
import '../providers/cartela_catalog_provider.dart';
import '../../domain/cartela_catalog_state.dart';
import '../providers/cartela_marks_storage_provider.dart';
import '../providers/current_game_operations_provider.dart';
import '../providers/has_active_registered_cartelas_provider.dart';
import '../utils/live_game_resume_owner_registry.dart';
import '../utils/game_operations_resume_cache.dart';
import '../utils/live_resume_conditional_fetch.dart';
import '../providers/realtime_connection_provider.dart';
import '../providers/registration_state_patch_provider.dart';
import '../utils/live_embedded_operations_snapshot.dart';
import '../utils/live_resume_provider_policy.dart';
import '../../domain/registration_state_patch.dart';
import '../../domain/resolved_cartela_availability.dart';
import '../utils/registration_ux_metrics.dart';

part 'live_game_orchestration.dart';
part 'live_game_realtime.dart';
part 'live_game_registration.dart';
part 'live_game_called_numbers.dart';
part 'live_game_winner_window.dart';

class LiveGameScreen extends ConsumerStatefulWidget {
  const LiveGameScreen({
    this.gameId,
    this.showAppBar = false,
    this.initialGame,
    this.embedded = false,
    super.key,
  });

  final String? gameId;
  final bool showAppBar;
  final GameModel? initialGame;
  final bool embedded;

  @override
  ConsumerState<LiveGameScreen> createState() => _LiveGameScreenState();
}

abstract class _LiveGameScreenStateBase extends ConsumerState<LiveGameScreen>
    implements LiveGameHost {
  @override
  late LiveGameControllers controllers;

  @override
  bool get embedded => widget.embedded;

  @override
  String? get gameId => widget.gameId;

  @override
  GameModel? get initialGame => widget.initialGame;

  @override
  GamesRepository get gamesRepository => _gamesRepository;

  @override
  void markNeedsBuild([VoidCallback? fn]) {
    if (!mounted) {
      return;
    }

    void apply() {
      if (!mounted) {
        return;
      }
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
  Map<String, dynamic>? _pendingWinnerWindowPayload;
  Map<String, dynamic>? _pendingBingoInvalidPayload;
  bool _awaitingPrizeWalletRefresh = false;
  Timer? _liveRoomSplashTicker;
  bool _awaitingLiveRoom = true;
  bool _initialLoadComplete = false;
  bool _hasCompletedInitialPaint = false;
  DateTime? _liveRoomSplashStartedAt;
  int _loadGeneration = 0;
  LivePresentationPhase? _lastDebugPhase;
  bool _isSyncingLiveGame = false;
  Timer? _invalidSocketPayloadRefetchTimer;
  String? _lastInvalidSocketPayloadLogKey;
  DateTime? _lastInvalidSocketPayloadLogAt;
  GameTimingConfigModel? _timingConfig;
  bool _timingConfigLoaded = false;
  GameModel? _nextUpcomingGame;
  GameOperationsCurrentResponse? _lastOperations;
  bool _hasBlockingLiveGame = false;
  List<int>? _pendingAutoOpenCartelaNumbers;
  Timer? _myCartelasRefreshDebounceTimer;
  Timer? _nextCartelasRefreshDebounceTimer;
  final LiveSocketSessionMembership _socketMembership =
      LiveSocketSessionMembership();
  bool _gameInfoExpanded = false;
  String? _autoExpandedForNextGameSessionId;

  static const _liveRoomSplashMinimum = Duration(milliseconds: 1500);
  static const _liveRoomSplashMaximum = Duration(seconds: 15);
  static const _checkingCartelaMinimumDisplay = Duration(milliseconds: 800);

  GameTimingConfigModel get _effectiveTimingConfig =>
      _timingConfig ?? GameTimingConfigModel.fallback;

  Duration get _postGameSummaryHold => _review.postGameSummaryHold;

  Duration get _snackbarDuration => const Duration(seconds: 4);

  bool get _hasVisibleCurrentSessionCartelas => _myCartelas.isNotEmpty;

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
    final ops = _lastOperations;
    final liveSessionId =
        ops?.liveGame?.sessionId ?? ops?.checkingGame?.sessionId;
    if (liveSessionId == null || !_hasVisibleCurrentSessionCartelas) {
      return false;
    }
    return _game?.sessionId == liveSessionId;
  }

  /// The session currently in play (PLAYING / CHECKING), not the READY queue game.
  GameModel? get _blockingLiveSessionGame =>
      _lastOperations?.liveGame ?? _lastOperations?.checkingGame;

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

  LiveUiModeState get _liveUiMode {
    return resolveLiveUiMode(
      ResolveLiveUiModeInput(
        operations: _lastOperations,
        pinnedPrimaryGame: _resolverPinsTerminalSession ? _game : null,
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
          registrationGridReady:
              _isRegistrationGridReady(_registrationGridSessionId),
        ),
        now: _countdownNow(),
        preparingStaleAfter: _preparingPhaseCap,
        isGuest: _isGuest,
        isLoading: _isLoading,
        awaitingLiveRoom: _awaitingLiveRoom,
        hasError: _errorMessage != null,
        winnerWindowExpired: _resolverWinnerWindowExpired,
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

  ServerClockService get _serverClock => ref.read(serverClockProvider);

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
  late final SocketService _socketService = ref.read(socketServiceProvider);
  // Session ID used for API calls and socket event filtering.
  // null when the current game is a NEXT slot (no session yet).
  String? get _activeSessionId => _game?.sessionId ?? _joinedGameId;

  bool get _isGuest => ref.read(authControllerProvider).session == null;

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
  bool get isGuest => _isGuest;

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
    _cn.markCalledNumbersPanelDirty();
  }

  /// Syncs current session and cartela count to the back navigation provider.
  /// Call this whenever _myCartelas or _joinedGameId changes.
  void _syncActiveCartelasToProvider() {
    _runAfterBuild(() {
      final sessionId = _activeSessionId;
      final cartelaCount = _myCartelas.length;
      ref
          .read(hasActiveRegisteredCartelasProvider.notifier)
          .updateSessionState(sessionId, cartelaCount);
    });
  }

  LivePresentationPhase get _livePresentationPhase =>
      _liveUiMode.presentationPhase;

  List<GameCartelaModel> get _orderedMyCartelas => applyCartelaDisplayOrder(
    cartelas: _myCartelas,
    orderIds: _myCartelaDisplayOrderIds,
  );

  void _clearMyCartelaDisplayOrder() {
    _myCartelaDisplayOrderIds = const [];
  }

  void _reorderMyCartela(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) {
      return;
    }

    final ordered = _orderedMyCartelas;
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

class _LiveGameScreenState extends _LiveGameScreenStateBase
    with
        WidgetsBindingObserver,
        _LiveGameOrchestration,
        _LiveGameRealtime,
        _LiveGameCalledNumbers,
        _LiveGameWinnerWindow,
        _LiveGameRegistration {
  @override
  void initState() {
    controllers = LiveGameControllers(this);
    super.initState();
    if (widget.initialGame != null) {
      _game = widget.initialGame;
      _isLoading = false;
      _awaitingLiveRoom = false;
      _hasCompletedInitialPaint = true;
      _initialLoadComplete = true;
    }
    WidgetsBinding.instance.addObserver(this);
    LiveGameResumeOwnerRegistry.activate();
    ref.listenManual(authControllerProvider, _onAuthSessionChanged);
    unawaited(_bootstrapLiveRoomSplash());
    _registerSocketListeners();
    _joinSessionRoomEarly(widget.gameId ?? widget.initialGame?.sessionId);
    unawaited(_loadInitialState(showLoading: widget.initialGame == null));
    if (LiveRealtimeDebug.isEnabled) {
      LiveRealtimeDebug.log(
        'REALTIME_DEBUG enabled — watch console for [AutoCall] lines',
      );
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    _liveRoomSplashTicker?.cancel();
    _review.stopSessionWinnerResultsPolling();
    controllers.transition.preparingPhasePollTimer?.cancel();
    controllers.transition.readyTransitionLockTimeoutTimer?.cancel();
    _stopPreparingPhasePolling();
    controllers.transition.clearReadyTransitionLock();
    _cancelCanonicalRefetchDebounce();
    controllers.dispose();
    _stopDisconnectedCalledNumbersPolling();
    _invalidSocketPayloadRefetchTimer?.cancel();
    _removeSocketListeners();
    _applySocketSessionMembership(null);
    LiveGameResumeOwnerRegistry.deactivate();
    // Clear the active cartelas provider when leaving the screen
    _syncActiveCartelasToProvider();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _pauseLiveTimersForBackground();
        unawaited(_persistManualMarks());
      case AppLifecycleState.hidden:
        _pauseLiveTimersForBackground();
      case AppLifecycleState.resumed:
        unawaited(_recoverFromAppResume());
    }
  }

  void _pauseLiveTimersForBackground() {
    _countdown.pauseForAppBackground();
    _transition.stopPreparingPhasePolling();
    _cn.stopDisconnectedPolling();
  }

  void _onAuthSessionChanged(AuthState? previous, AuthState next) {
    final hadSession = previous?.session != null;
    final hasSession = next.session != null;
    if (hadSession == hasSession) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (!hadSession && hasSession) {
        unawaited(() async {
          await _loadInitialState(showLoading: false);
          if (!mounted) {
            return;
          }
          _ensureManualMarksReadyForActiveSession();
        }());
        return;
      }

      if (_cn.manualMarkedNumbers.isNotEmpty ||
          _cn.lastManualMarkedKey != null ||
          _cn.marksOwnerUserId != null ||
          _cn.restoredMarksSessionId != null) {
        setState(() {
          _cn.manualMarkedNumbers.clear();
          _cn.lastManualMarkedKey = null;
          _cn.marksSessionId = null;
          _cn.marksOwnerUserId = null;
          _cn.restoredMarksSessionId = null;
        });
      }

      unawaited(_loadInitialState(showLoading: false));
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = AnimatedSwitcher(
      duration: _hasCompletedInitialPaint
          ? const Duration(milliseconds: 450)
          : Duration.zero,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        if (!_hasCompletedInitialPaint) {
          return child;
        }
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<String>(_bodyTransitionKey),
        child: _buildBody(),
      ),
    );

    final framedBody = widget.embedded
        ? body
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BigGameLivePromptBanner(
                embedded: widget.embedded,
                currentGame: _game,
              ),
              Expanded(child: body),
            ],
          );

    final content = widget.showAppBar
        ? Scaffold(
            appBar: AppBar(title: const Text('Live game')),
            body: framedBody,
          )
        : framedBody;

    return RealtimeBrandingOverlay(
      visible: _awaitingLiveRoom,
      child: Stack(
        children: [
          Positioned.fill(
            child: _awaitingLiveRoom ? const SizedBox.shrink() : content,
          ),
          if (!_awaitingLiveRoom)
            _LiveSyncOverlay(
              visible: _realtime.showSyncOverlay,
              title: _realtime.syncOverlayTitle,
              message: _realtime.syncOverlayMessage,
              showRetry: _realtime.lastSyncFailed,
              onRetry: () => unawaited(_refresh()),
            ),
        ],
      ),
    );
  }

  String get _bodyTransitionKey {
    final game = _game;
    final registrationBodyTarget = _registrationOpenBodyTarget;
    if (registrationBodyTarget != null) {
      return 'registration-${registrationBodyTarget.sessionId ?? registrationBodyTarget.id}';
    }

    if (game == null ||
        _livePresentationPhase == LivePresentationPhase.noActiveGame) {
      return 'empty';
    }

    if (_livePresentationPhase == LivePresentationPhase.cancelled ||
        _livePresentationPhase == LivePresentationPhase.noPlayersJoined) {
      return 'terminal-${game.sessionId ?? game.id}';
    }

    return 'live-${game.sessionId ?? game.id}';
  }

  bool get _usesStickyLivePlayHeader {
    if (_game == null) {
      return false;
    }

    return _showsInlinePlayCartelas;
  }

  bool get _usesExpandedNoCartelaRegistrationLayout {
    return usesExpandedNoCartelaRegistrationLayout(
      isGuest: _isGuest,
      hasCurrentCartelas: _hasVisibleCurrentSessionCartelas,
      showsInlinePlayCartelas: _showsInlinePlayCartelas,
      registrationTarget: _primaryRegistrationTarget,
    );
  }

  bool get _showsMissedRoundQueuedRegistrationLayout {
    return _usesExpandedNoCartelaRegistrationLayout &&
        !_registrationTargetIsCurrentGame;
  }

  Widget _buildBody() {
    if (_shouldUseRegistrationOpenLayout) {
      return _buildRegistrationOpenBody();
    }

    if (_usesStickyLivePlayHeader) {
      if (_usesExpandedNoCartelaRegistrationLayout) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: AppSpacing.screenPadding.copyWith(top: 0, bottom: 0),
              child: _showsMissedRoundQueuedRegistrationLayout
                  ? _buildStickyMissedRoundHeader()
                  : _buildStickyLiveHeader(),
            ),
            Expanded(
              child: Padding(
                padding: AppSpacing.screenPadding.copyWith(top: 0),
                child: _buildStickyNoCartelaRegistrationBody(),
              ),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppSpacing.screenPadding.copyWith(top: 0, bottom: 0),
            child: _buildStickyLiveHeader(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.screenPadding.copyWith(top: AppSpacing.sm),
                children: _buildStickyLiveScrollContent(),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.screenPadding.copyWith(top: 0),
              children: _buildFullScrollContent(),
            ),
          ),
        ),
      ],
    );
  }

  bool get _shouldUseRegistrationOpenLayout =>
      _liveUiMode.useRegistrationOpenLayout;

  Widget _buildRegistrationOpenBody() {
    final game = _registrationOpenBodyTarget!;
    final isCurrentRound = _isCurrentGameTarget(game);
    final phase = isCurrentRound
        ? _livePresentationPhase
        : LivePresentationPhase.registrationOpen;
    final cartelaActionsEnabled = isCurrentRound
        ? phase.cartelaActionsEnabled
        : game.canRegister;
    final registeredCartelas = isCurrentRound
        ? _myCartelas
        : _nextRegistrationCartelas;
    final statusBanner = isCurrentRound ? _buildLiveStatusBanner() : null;
    final uiMode = _liveUiMode;
    final hideCountdown = isCurrentRound
        ? uiMode.hideRegistrationCountdown
        : uiMode.deferNextRoundRegistrationCountdown;
    final registrationPanel = _buildRegistrationPanelForTarget(
      target: game,
      registeredCartelas: registeredCartelas,
      isCurrentRound: isCurrentRound,
    );
    final showMissedRoundWrapper =
        cartelaActionsEnabled && uiMode.showMissedRoundWrapper;
    final showRegistrationHandoffPreparing =
        uiMode.mode == LiveUiMode.handoffOpeningNext;
    final isMissedRoundRegistration =
        uiMode.mode == LiveUiMode.missedRoundRegistration;
    final registrationBody = showMissedRoundWrapper
        ? _buildMissedRoundRegistrationSection(
            target: game,
            panel: registrationPanel,
          )
        : registrationPanel;

    return Padding(
      padding: AppSpacing.screenPadding.copyWith(top: 0, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (phase == LivePresentationPhase.registrationOpen)
            CollapsibleRegistrationOpenCluster(
              game: game,
              myRegisteredCartelasCount: _regDisplayCountForGame(game),
              expanded: _gameInfoExpanded,
              onExpandedChanged: (expanded) {
                setState(() => _gameInfoExpanded = expanded);
              },
              statusBanner: statusBanner,
              banner: RegistrationOpenPulse(
                key: ValueKey(
                  'registration-pulse-${game.sessionId ?? game.id}',
                ),
                isGuest: _isGuest,
                ruleName: game.localizedRuleName(ref),
                titleOverride: showRegistrationHandoffPreparing
                    ? game.localizedRuleName(ref)
                    : null,
                animateMemberMessages: !showRegistrationHandoffPreparing,
                rotatingTitleMessages: isMissedRoundRegistration
                    ? [
                        game.localizedRuleName(ref),
                        context.l10n.liveNextGameBannerTitle,
                      ]
                    : null,
                rotatingSubtitleMessages: isMissedRoundRegistration
                    ? [
                        context.l10n.liveMissedRoundBannerSubtitle,
                        context.l10n.liveNextGameLabel,
                      ]
                    : null,
                scheduledStartAt: hideCountdown
                    ? null
                    : isCurrentRound
                    ? _effectiveRegistrationDeadline
                    : game.scheduledStartAt,
                countdownOverrideLabel: showRegistrationHandoffPreparing
                    ? context.l10n.postGameSummaryOpeningNextRound
                    : hideCountdown &&
                          uiMode.helperKey ==
                              LiveUiHelperKey.registrationStartsAfterCurrentGame
                    ? context.l10n.registrationStartsAfterCurrentGame
                    : null,
                serverClock: _serverClock,
                countdownTracker:
                    controllers.countdown.registrationCountdownTracker,
                scopeKey: game.sessionId ?? game.id,
                embedded: true,
                showFlair: false,
                useBigGameCountdownFormat: game.isBigGame,
                onRegistrationClosed: isCurrentRound
                    ? hideCountdown
                          ? null
                          : _handleRegistrationCountdownClosed
                    : hideCountdown
                    ? null
                    : () => _scheduleCanonicalRefetch(
                        registrationSessionId: game.sessionId,
                      ),
              ),
            )
          else
            CollapsibleLiveTopSection(
              game: game,
              nextGame: isCurrentRound && !_suppressNextGameQueueHint
                  ? _queueUpcomingGameForDisplay
                  : null,
              variant: LiveTopSectionVariant.livePlay,
              expanded: _gameInfoExpanded,
              onExpandedChanged: (expanded) {
                setState(() => _gameInfoExpanded = expanded);
              },
              nextRegisteredCartelaNumbers: _nextRegisteredCartelaNumbers,
              myRegisteredCartelasCount: _regDisplayCountForGame(game),
            ),
          if (phase != LivePresentationPhase.registrationOpen &&
              statusBanner != null) ...[
            VGap.sm,
            statusBanner,
          ],
          VGap.sm,
          Expanded(
            child: cartelaActionsEnabled
                ? registrationBody
                : _PreparingGamePanel(
                    registeredCartelas: registeredCartelas,
                    isRefetching: false,
                    titleOverride: showRegistrationHandoffPreparing
                        ? context.l10n.postGameSummaryOpeningNextRound
                        : null,
                    messageOverride: showRegistrationHandoffPreparing
                        ? context.l10n.preparingGameNoCartelas
                        : null,
                  ),
          ),
        ],
      ),
    );
  }

  GameModel? get _registrationOpenBodyTarget =>
      _liveUiMode.registrationOpenBodyTarget;

  bool _isCurrentGameTarget(GameModel target) {
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

  int _myRegisteredCountForGame(GameModel game) {
    if (_isGuest) {
      return 0;
    }
    if (_isCurrentGameTarget(game)) {
      return _myCartelas.length;
    }

    final targetSessionId = game.sessionId;
    return _nextRegistrationCartelas
        .where(
          (cartela) =>
              targetSessionId == null || cartela.gameId == targetSessionId,
        )
        .length;
  }

  int _regDisplayCountForGame(GameModel game) {
    final sessionId = game.sessionId;
    final registrationStateCount = sessionId == null
        ? null
        : ref
              .watch(registrationStateProvider(sessionId))
              .asData
              ?.value
              .registeredCartelasCount;

    return registrationRegDisplayCount(
      game: game,
      myRegisteredCount: _myRegisteredCountForGame(game),
      registrationStateCount: registrationStateCount,
    );
  }

  List<Widget> _buildFullScrollContent() {
    if (_awaitingLiveRoom) {
      return const [SizedBox.expand()];
    }
    if (_isLoading) {
      return const [
        SizedBox.expand(
          child: Center(
            child: FriendsBingoLoading(compact: true),
          ),
        ),
      ];
    }
    if (_errorMessage != null) {
      return [_LiveErrorState(message: _errorMessage!, onRetry: _refresh)];
    }
    if (_game == null) {
      return [
        _LiveInfoCard(
          title: context.l10n.liveNoGameTitle,
          message: _emptyMessage ?? context.l10n.liveNoGameMessage,
        ),
      ];
    }

    return [_buildActiveGameContent(includeCalledNumbersStrip: true)];
  }

  List<Widget> _buildStickyLiveScrollContent() {
    if (_showsGuestSpectator) {
      return [
        _GuestSpectatorHint(
          onSignUp: () => context.go('/register'),
          onSignIn: () => context.go(loginPathWithRedirect('/games')),
        ),
      ];
    }

    return [
      if (_hasVisibleCurrentSessionCartelas) ...[
        _InlineRegisteredCartelaList(
          cartelas: _orderedMyCartelas,
          sortResultsByCartelaId: _cn.cartelaSortResults,
          canClaimBingoFor: _canClaimBingoForCartela,
          claimingCartelaIds: _cn.claimingCartelaIds,
          pendingClaimCartelaIds: _cn.pendingClaimCartelaIds,
          showPendingClaimState: !_showsPostGameSummary,
          showFinishedOutcome: _showFinishedCartelaOutcome,
          freezeCartelaMarks: _cartelaMarksFrozenForEvidence,
          manualMarkedNumbers: _cn.effectiveMarkedNumbers,
          lastManualMarkedKey: _cn.lastManualMarkedKey,
          markedNumbersFor: _markedNumbersForCartela,
          sortResultFor: _sortResultForCartela,
          winningPatternCellsByGameCartelaId:
              _review.winnerCartelaDisplay.patternCellsByGameCartelaId,
          winningPatternOverlayByGameCartelaId:
              _review.winnerCartelaDisplay.overlayByGameCartelaId,
          winningBallCellIndexByGameCartelaId:
              _review.winnerCartelaDisplay.winningBallCellIndexByGameCartelaId,
          prizeAmountFor: _prizeAmountForGameCartela,
          onMarkedNumberToggled: _toggleMarkedNumber,
          onClaimBingo: _claimBingo,
          onClearMarksForCartela: _clearMarksForCartela,
          blockedReasonCodeFor: _blockedReasonCodeForCartela,
          blockedServerReasonFor: _blockedServerReasonForCartela,
          onReorder: _myCartelas.length > 1 ? _reorderMyCartela : null,
          bingoLockListenable: _countdown.bingoClaimLocked,
        ),
        if (_shouldShowInlineRegistrationPanel &&
            !_blocksRegistrationPromotion) ...[
          VGap.md,
          _buildRegistrationTargetSection(),
        ],
      ],
    ];
  }

  Widget _buildStickyNoCartelaRegistrationBody() {
    final target = _primaryRegistrationTarget;
    if (target == null) {
      return const SizedBox.shrink();
    }

    final isCurrentRound = _registrationTargetIsCurrentGame;
    final panel = _buildRegistrationPanelForTarget(
      target: target,
      registeredCartelas: _registrationTargetCartelas,
      isCurrentRound: isCurrentRound,
    );

    // Missed-round players get the same full registration grid used in the
    // next-game sheet (toolbar + numbers + Taken chips), not a separate flow.
    if (!isCurrentRound) {
      return _buildMissedRoundRegistrationSection(target: target, panel: panel);
    }

    final l10n = context.l10n;

    return LiveNextRoundRegistrationSection(
      gameName: target.localizedRuleName(ref),
      nextGame: target,
      sectionTitle: l10n.liveJoinCurrentRoundSectionTitle,
      helperText: l10n.liveJoinCurrentRoundHelper,
      registeredCartelaNumbers: _myCartelas
          .map((c) => c.cartela.number)
          .toList(growable: false),
      panel: panel,
      variant: LiveNextRoundSectionVariant.joinCurrentRound,
    );
  }

  Widget _buildMissedRoundRegistrationSection({
    required GameModel target,
    required Widget panel,
  }) {
    final l10n = context.l10n;

    return LiveNextRoundRegistrationSection(
      gameName: target.localizedRuleName(ref),
      currentRoundGame: _blockingLiveSessionGame,
      nextGame: target,
      sectionTitle: l10n.liveNextRoundRegistrationTitle,
      helperText: l10n.liveMissedRoundHelper,
      registeredCartelaNumbers: _nextRegisteredCartelaNumbers,
      panel: panel,
      variant: LiveNextRoundSectionVariant.missedCurrentRound,
    );
  }

  Widget _buildCollapsibleLiveTopSection({
    required GameModel game,
    GameModel? nextGame,
    bool showRule = true,
    LiveTopSectionVariant? variant,
  }) {
    final resolvedVariant = variant ?? _liveTopSectionVariant;
    final isLivePlay = resolvedVariant == LiveTopSectionVariant.livePlay;

    if (isLivePlay && !_gameInfoExpanded) {
      return const SizedBox.shrink();
    }

    return CollapsibleLiveTopSection(
      game: game,
      nextGame: nextGame,
      showRule: showRule,
      variant: resolvedVariant,
      expanded: isLivePlay ? _gameInfoExpanded : null,
      initiallyExpanded: isLivePlay ? false : _gameInfoExpanded,
      onExpandedChanged: isLivePlay
          ? (expanded) {
              if (_gameInfoExpanded == expanded) {
                return;
              }
              setState(() => _gameInfoExpanded = expanded);
            }
          : null,
      nextRegisteredCartelaNumbers: _nextRegisteredCartelaNumbers,
      myRegisteredCartelasCount: _regDisplayCountForGame(game),
    );
  }

  Widget _buildStickyLiveHeader() {
    final game = _game!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCollapsibleLiveTopSection(
          game: game,
          nextGame: _suppressNextGameQueueHint
              ? null
              : _queueUpcomingGameForDisplay,
        ),
        if (_buildLiveStatusBanner() case final banner?) ...[VGap.sm, banner],
        if (_buildPostGameSummaryBanner() case final summaryBanner?) ...[
          VGap.sm,
          summaryBanner,
        ],
        VGap.sm,
        _buildCalledNumbersPanel(),
      ],
    );
  }

  Widget _buildStickyMissedRoundHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_buildLiveStatusBanner() case final banner?) ...[banner, VGap.sm],
        if (_buildPostGameSummaryBanner() case final summaryBanner?) ...[
          summaryBanner,
          VGap.sm,
        ],
        _buildCalledNumbersPanel(),
      ],
    );
  }

  Widget _buildActiveGameContent({required bool includeCalledNumbersStrip}) {
    final game = _game!;
    final registrationTarget = _primaryRegistrationTarget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCollapsibleLiveTopSection(
          game: game,
          nextGame: _showsInlinePlayCartelas && !_suppressNextGameQueueHint
              ? _queueUpcomingGameForDisplay
              : null,
          showRule: !game.isRegistrationOpen,
        ),
        if (_buildLiveStatusBanner() case final banner?) ...[VGap.sm, banner],
        if (_buildPostGameSummaryBanner() case final summaryBanner?) ...[
          VGap.sm,
          summaryBanner,
        ],
        if (!game.isRegistrationOpen &&
            !_showsInlinePlayCartelas &&
            !_review.postGameSummaryReviewActive &&
            _subtitleForRegisteredCartelas().isNotEmpty) ...[
          VGap.sm,
          Text(
            _subtitleForRegisteredCartelas(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        if (_shouldShowPublicCalledNumbersPanel &&
            includeCalledNumbersStrip) ...[
          VGap.sm,
          _buildCalledNumbersPanel(),
          VGap.sm,
        ],
        if (_showsGuestSpectator) ...[
          _GuestSpectatorHint(
            onSignUp: () => context.go('/register'),
            onSignIn: () => context.go(loginPathWithRedirect('/games')),
          ),
        ] else if (!_hasVisibleCurrentSessionCartelas &&
            !_review.postGameSummaryReviewActive)
          _isGuest
              ? _GuestSignupCard(
                  title: 'Join the game',
                  message: _canRegisterCartelas
                      ? 'Sign up to register cartelas and join this round.'
                      : 'Registration is closed. Sign up to be ready for the next round.',
                  onSignUp: () => context.go('/register'),
                  onSignIn: () => context.go(loginPathWithRedirect('/games')),
                )
              : registrationTarget != null
              ? _registrationTargetIsCurrentGame
                    ? RegistrationGridScrollIsolation(
                        child: SizedBox(
                          height: 520,
                          child: _buildRegistrationPanelForTarget(
                            target: registrationTarget,
                            registeredCartelas: _registrationTargetCartelas,
                            isCurrentRound: true,
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 640,
                        child: _buildMissedRoundRegistrationSection(
                          target: registrationTarget,
                          panel: _buildRegistrationPanelForTarget(
                            target: registrationTarget,
                            registeredCartelas: _registrationTargetCartelas,
                            isCurrentRound: false,
                          ),
                        ),
                      )
              : _LiveInfoCard(
                  title: 'No registered cartelas',
                  message: _canRegisterCartelas
                      ? (game.hasFreeEntry
                            ? 'Select cartela numbers above. Bonus registration is free, with up to ${game.maxCartelasPerPlayer ?? 5} cartelas per player.'
                            : game.isBigGotd
                            ? 'Select cartela numbers above. Big GOTD has a fixed prize and paid entry, with up to ${game.maxCartelasPerPlayer ?? 5} cartelas per player.'
                            : 'Select cartela numbers above. You can register more than one as long as your wallet balance is enough.')
                      : (_nextUpcomingGame?.status == GameStatus.ready &&
                            (_nextUpcomingGame?.canRegister ?? false))
                      ? 'Registration for this round is closed. The next round is opening in queue.'
                      : 'Registration is closed for this live game right now.',
                )
        else if (_showsInlinePlayCartelas) ...[
          _InlineRegisteredCartelaList(
            cartelas: _orderedMyCartelas,
            sortResultsByCartelaId: _cn.cartelaSortResults,
            canClaimBingoFor: _canClaimBingoForCartela,
            claimingCartelaIds: _cn.claimingCartelaIds,
            pendingClaimCartelaIds: _cn.pendingClaimCartelaIds,
            showPendingClaimState: !_showsPostGameSummary,
            showFinishedOutcome: _showFinishedCartelaOutcome,
            freezeCartelaMarks: _cartelaMarksFrozenForEvidence,
            manualMarkedNumbers: _cn.effectiveMarkedNumbers,
            lastManualMarkedKey: _cn.lastManualMarkedKey,
            markedNumbersFor: _markedNumbersForCartela,
            sortResultFor: _sortResultForCartela,
            winningPatternCellsByGameCartelaId:
                _review.winnerCartelaDisplay.patternCellsByGameCartelaId,
            winningPatternOverlayByGameCartelaId:
                _review.winnerCartelaDisplay.overlayByGameCartelaId,
            winningBallCellIndexByGameCartelaId: _review
                .winnerCartelaDisplay
                .winningBallCellIndexByGameCartelaId,
            prizeAmountFor: _prizeAmountForGameCartela,
            onMarkedNumberToggled: _toggleMarkedNumber,
            onClaimBingo: _claimBingo,
            onClearMarksForCartela: _clearMarksForCartela,
            blockedReasonCodeFor: _blockedReasonCodeForCartela,
            blockedServerReasonFor: _blockedServerReasonForCartela,
            onReorder: _myCartelas.length > 1 ? _reorderMyCartela : null,
            bingoLockListenable: _countdown.bingoClaimLocked,
          ),
          if (_shouldShowInlineRegistrationPanel &&
              !_review.postGameSummaryReviewActive) ...[
            VGap.xl,
            _buildRegistrationTargetSection(),
          ],
        ] else if (_hasVisibleCurrentSessionCartelas)
          _RegisteredCartelaList(cartelas: _myCartelas),
      ],
    );
  }

  Widget _buildRegistrationTargetSection() {
    final target = _primaryRegistrationTarget;
    if (target == null) {
      return const SizedBox.shrink();
    }

    final isCurrentRound = _registrationTargetIsCurrentGame;
    final registeredCartelas = _registrationTargetCartelas;
    final l10n = context.l10n;
    final title = isCurrentRound
        ? (!_hasVisibleCurrentSessionCartelas
              ? l10n.liveJoinCurrentRoundSectionTitle
              : l10n.liveAddMoreCartelasTitle)
        : l10n.liveNextRoundRegistrationTitle;
    final message = isCurrentRound
        ? (!_hasVisibleCurrentSessionCartelas
              ? l10n.liveJoinCurrentRoundHelper
              : l10n.liveAddMoreCartelasHelper)
        : l10n.liveMissedRoundHelper;

    final panel = _buildRegistrationPanelForTarget(
      target: target,
      registeredCartelas: registeredCartelas,
      isCurrentRound: isCurrentRound,
    );

    if (!isCurrentRound && !_hasVisibleCurrentSessionCartelas) {
      return _buildMissedRoundRegistrationSection(target: target, panel: panel);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        VGap.xs,
        Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        VGap.md,
        RegistrationGridScrollIsolation(
          child: SizedBox(height: 520, child: panel),
        ),
      ],
    );
  }

  Set<String> get _liveLockedCartelaIds {
    if (_isGuest || !_hasVisibleCurrentSessionCartelas) {
      return const {};
    }

    return {for (final cartela in _myCartelas) cartela.cartelaId};
  }

  Widget _buildRegistrationPanelForTarget({
    required GameModel target,
    required List<GameCartelaModel> registeredCartelas,
    required bool isCurrentRound,
  }) {
    return _CartelaRegistrationPanel(
      registration: _registration,
      slotId: target.id,
      sessionId: target.sessionId,
      gameStatus: target.status,
      entryFee: target.entryFee,
      prizePerCartela: target.prizePerCartela,
      category: target.category,
      fixedPrizeAmount: target.fixedPrizeAmount,
      maxCartelasPerPlayer: target.maxCartelasPerPlayer,
      registeredCartelas: registeredCartelas,
      cartelaHoldSeconds: _cartelaHoldSeconds,
      bulkSelectionSeconds: _effectiveBulkSelectionSeconds,
      isGuest: _isGuest,
      autoOpenCartelaNumbers: _pendingAutoOpenCartelaNumbers,
      onAutoOpenConsumed: _clearPendingAutoOpenCartelaNumbers,
      onRegistered: _handleCartelasRegistered,
      onSessionIdResolved: isCurrentRound
          ? _handleRegistrationSessionResolved
          : _handleQueuedRegistrationSessionResolved,
      lockedCartelaIds: isCurrentRound ? const {} : _liveLockedCartelaIds,
    );
  }

  void _clearPendingAutoOpenCartelaNumbers() {
    if (_pendingAutoOpenCartelaNumbers == null) {
      return;
    }

    setState(() {
      _pendingAutoOpenCartelaNumbers = null;
    });
  }

  @override
  Future<void> openNextGameRegistrationSheet() async {
    final target = _nextUpcomingGame;
    if (target == null ||
        target.status != GameStatus.ready ||
        !target.canRegister) {
      return;
    }

    if (_isGuest) {
      await showGuestAuthPromptSheet(context);
      return;
    }

    if (_myCartelas.isNotEmpty) {
      setState(() {
        _pendingAutoOpenCartelaNumbers =
            _myCartelas
                .map((cartela) => cartela.cartela.number)
                .toList(growable: false)
              ..sort();
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              bottom: mediaQuery.viewInsets.bottom + AppSpacing.xl,
            ),
            child: SizedBox(
              height: mediaQuery.size.height * 0.84,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Register for ${target.name}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  Text(
                    'Cartelas already active in the current live round are locked for the next game. Other cartelas are open.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  VGap.md,
                  Expanded(
                    child: _buildRegistrationPanelForTarget(
                      target: target,
                      registeredCartelas: _nextRegistrationCartelas,
                      isCurrentRound: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool get _canRegisterCartelas {
    final game = _game;
    return game != null && game.canRegister;
  }

  bool get _showsInlinePlayCartelas => _liveUiMode.showsInlinePlayCartelas;

  bool get _showsGuestSpectator => _isGuest && _showsInlinePlayCartelas;

  List<int> get _nextRegisteredCartelaNumbers {
    final numbers =
        _nextRegistrationCartelas
            .map((cartela) => cartela.cartela.number)
            .toList(growable: false)
          ..sort();
    return numbers;
  }

  GameModel? get _primaryRegistrationTarget => _liveUiMode.registrationTarget;

  bool get _blocksRegistrationPromotion =>
      _liveUiMode.blocksRegistrationPromotion;

  bool get _registrationTargetIsCurrentGame =>
      _registrationTargetIsCurrentGameFor(_primaryRegistrationTarget);

  List<GameCartelaModel> get _registrationTargetCartelas {
    if (_registrationTargetIsCurrentGame) {
      return _myCartelas;
    }

    return _nextRegistrationCartelas;
  }

  bool get _shouldShowPublicCalledNumbersPanel {
    return shouldShowPublicCalledNumbersPanel(
      game: _game,
      showsInlinePlayCartelas: _showsInlinePlayCartelas,
    );
  }

  bool get _shouldShowRegistrationPanel {
    if (_isGuest) {
      return false;
    }

    final target = _primaryRegistrationTarget;
    return target != null && target.canRegister;
  }

  bool get _shouldShowInlineRegistrationPanel {
    return shouldShowInlineRegistrationPanel(
      shouldShowRegistrationPanel: _shouldShowRegistrationPanel,
      showsInlinePlayCartelas: _showsInlinePlayCartelas,
      hasCartelas: _hasVisibleCurrentSessionCartelas,
      registrationTargetIsCurrentGame: _registrationTargetIsCurrentGame,
    );
  }

  String _subtitleForRegisteredCartelas() {
    final game = _game;
    if (game == null) {
      return '';
    }

    return switch (_livePresentationPhase) {
      LivePresentationPhase.registrationOpen =>
        !_hasVisibleCurrentSessionCartelas
            ? 'Tap a cartela number below to register it. The round starts when the admin confirms.'
            : '${_myCartelas.length} cartela${_myCartelas.length == 1 ? '' : 's'} registered. Tap more numbers below to add.',
      LivePresentationPhase.liveWaitingFirstBall ||
      LivePresentationPhase.liveCalling =>
        !_hasVisibleCurrentSessionCartelas
            ? 'Registration is open - you can still join!'
            : 'Mark numbers on your cartelas below as they are called live. You can still register more.',
      LivePresentationPhase.winnerWindow =>
        context.l10n.gameWinnerWindowMessage,
      LivePresentationPhase.review => '',
      LivePresentationPhase.noPlayersJoined =>
        context.l10n.gameNoPlayersMessage,
      LivePresentationPhase.cancelled => context.l10n.gameCancelledMessage,
      _ => '',
    };
  }
}

class _RegisteredCartelaList extends StatelessWidget {
  const _RegisteredCartelaList({required this.cartelas});

  final List<GameCartelaModel> cartelas;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: cartelas
          .map(
            (gameCartela) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: _RegisteredCartelaListTile(gameCartela: gameCartela),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _InlineRegisteredCartelaList extends StatelessWidget {
  const _InlineRegisteredCartelaList({
    required this.cartelas,
    required this.sortResultsByCartelaId,
    required this.canClaimBingoFor,
    required this.claimingCartelaIds,
    required this.pendingClaimCartelaIds,
    required this.showPendingClaimState,
    required this.showFinishedOutcome,
    required this.freezeCartelaMarks,
    required this.manualMarkedNumbers,
    this.lastManualMarkedKey,
    required this.markedNumbersFor,
    required this.sortResultFor,
    required this.winningPatternCellsByGameCartelaId,
    required this.winningPatternOverlayByGameCartelaId,
    required this.winningBallCellIndexByGameCartelaId,
    required this.prizeAmountFor,
    required this.onMarkedNumberToggled,
    required this.onClaimBingo,
    required this.onClearMarksForCartela,
    required this.blockedReasonCodeFor,
    required this.blockedServerReasonFor,
    this.onReorder,
    this.bingoLockListenable,
  });

  final List<GameCartelaModel> cartelas;
  final Map<String, CartelaPatternUiResult> sortResultsByCartelaId;
  final bool Function(GameCartelaModel) canClaimBingoFor;
  final Set<String> claimingCartelaIds;
  final Set<String> pendingClaimCartelaIds;
  final bool showPendingClaimState;
  final bool showFinishedOutcome;
  final bool freezeCartelaMarks;
  final Set<String> manualMarkedNumbers;
  final String? lastManualMarkedKey;
  final Set<String> Function(GameCartelaModel) markedNumbersFor;
  final CartelaPatternUiResult? Function(GameCartelaModel) sortResultFor;
  final Map<String, Set<int>> winningPatternCellsByGameCartelaId;
  final Map<String, CartelaPatternProgressOverlay>
  winningPatternOverlayByGameCartelaId;
  final Map<String, int> winningBallCellIndexByGameCartelaId;
  final String? Function(GameCartelaModel cartela) prizeAmountFor;
  final void Function(GameCartelaModel cartela, String header, String value)
  onMarkedNumberToggled;
  final Future<void> Function(GameCartelaModel) onClaimBingo;
  final void Function(GameCartelaModel) onClearMarksForCartela;
  final String? Function(GameCartelaModel) blockedReasonCodeFor;
  final String? Function(GameCartelaModel) blockedServerReasonFor;
  final void Function(int fromIndex, int toIndex)? onReorder;
  final ValueListenable<bool>? bingoLockListenable;

  Widget _buildCartelaCard({
    required GameCartelaModel gameCartela,
    required CartelaPatternUiResult? sortResult,
    required CartelaPatternProgressOverlay storedWinnerOverlay,
    required bool useStoredWinnerOverlay,
    required Set<int> storedWinnerHighlights,
    required Set<int> winningHighlightCells,
  }) {
    return LiveCartelaCard(
      key: ValueKey(gameCartela.id),
      gameCartela: gameCartela,
      canClaimBingo: canClaimBingoFor(gameCartela),
      isClaiming: claimingCartelaIds.contains(gameCartela.id),
      pendingReview:
          showPendingClaimState &&
          (pendingClaimCartelaIds.contains(gameCartela.id) ||
              claimingCartelaIds.contains(gameCartela.id)),
      showFinishedOutcome: showFinishedOutcome,
      freezeCartelaMarks: freezeCartelaMarks,
      isOneAwayFromWin: sortResult?.isOneAway ?? false,
      hasLocalPatternComplete: sortResult?.hasLocalPatternComplete ?? false,
      oneAwayCellIndexes: sortResult?.oneAwayCellIndexes ?? const {},
      winningPatternOverlay: useStoredWinnerOverlay
          ? storedWinnerOverlay
          : sortResult?.completedPatternOverlay ??
                const CartelaPatternProgressOverlay(),
      winningHighlightCells: winningHighlightCells,
      winningBallCellIndex: gameCartela.isWinner
          ? winningBallCellIndexByGameCartelaId[gameCartela.id]
          : null,
      prizeAmount: prizeAmountFor(gameCartela),
      manualMarkedNumbers: markedNumbersFor(gameCartela),
      lastManualMarkedKey: gameCartela.status == GameCartelaStatus.blocked
          ? null
          : lastManualMarkedKeyForCartela(
              lastManualMarkedKey: lastManualMarkedKey,
              cartela: gameCartela,
            ),
      onMarkedNumberToggled: onMarkedNumberToggled,
      onClaimBingo: () => onClaimBingo(gameCartela),
      onClearMarks: () => onClearMarksForCartela(gameCartela),
      blockedReasonCode: blockedReasonCodeFor(gameCartela),
      blockedServerReason: blockedServerReasonFor(gameCartela),
      bingoLockListenable: bingoLockListenable,
    );
  }

  Widget _wrapReorderableCell({
    required BuildContext context,
    required int index,
    required double cellWidth,
    required double cellHeight,
    required Widget card,
  }) {
    final onReorder = this.onReorder;
    if (onReorder == null) {
      return card;
    }

    final theme = Theme.of(context);
    return LongPressDraggable<int>(
      data: index,
      delay: const Duration(milliseconds: 400),
      hapticFeedbackOnStart: true,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: cellWidth,
          height: cellHeight,
          child: Opacity(opacity: 0.92, child: card),
        ),
      ),
      childWhenDragging: SizedBox(width: cellWidth, height: cellHeight),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) => details.data != index,
        onAcceptWithDetails: (details) => onReorder(details.data, index),
        builder: (context, candidateData, rejectedData) {
          final isTarget = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: isTarget
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  )
                : null,
            child: card,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisSpacing = 6.0;
        const childAspectRatio = 0.72;
        final cellWidth = (constraints.maxWidth - crossAxisSpacing) / 2;
        final cellHeight = cellWidth / childAspectRatio;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 6,
                crossAxisSpacing: crossAxisSpacing,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: cartelas.length,
              itemBuilder: (context, index) {
                final gameCartela = cartelas[index];
                final sortResult =
                    sortResultFor(gameCartela) ??
                    sortResultsByCartelaId[gameCartela.id];
                final rawStoredWinnerOverlay =
                    winningPatternOverlayByGameCartelaId[gameCartela.id];
                final storedWinnerOverlay =
                    rawStoredWinnerOverlay ??
                    const CartelaPatternProgressOverlay();
                final storedWinnerHighlights =
                    rawStoredWinnerOverlay != null &&
                        !rawStoredWinnerOverlay.isEmpty
                    ? rawStoredWinnerOverlay.allOverlayCellIndexes
                    : winningPatternCellsByGameCartelaId[gameCartela.id] ??
                          const <int>{};
                final winningHighlightCells = {
                  ...?sortResult?.completedPatternCells,
                  ...storedWinnerHighlights,
                };
                final card = _buildCartelaCard(
                  gameCartela: gameCartela,
                  sortResult: sortResult,
                  storedWinnerOverlay: storedWinnerOverlay,
                  useStoredWinnerOverlay:
                      rawStoredWinnerOverlay != null &&
                      !rawStoredWinnerOverlay.isEmpty,
                  storedWinnerHighlights: storedWinnerHighlights,
                  winningHighlightCells: winningHighlightCells,
                );

                return _wrapReorderableCell(
                  context: context,
                  index: index,
                  cellWidth: cellWidth,
                  cellHeight: cellHeight,
                  card: card,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _RegisteredCartelaListTile extends StatelessWidget {
  const _RegisteredCartelaListTile({required this.gameCartela});

  final GameCartelaModel gameCartela;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = _cartelaStatusColors(theme, gameCartela.status);
    final statusLabel = gameCartela.isWinner
        ? 'Winner'
        : gameCartela.status == GameCartelaStatus.blocked
        ? 'Blocked / Invalid Bingo'
        : gameCartela.status.label;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                '#${gameCartela.cartela.number}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cartela ${gameCartela.cartela.number}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColors.background,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: statusColors.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveErrorState extends StatelessWidget {
  const _LiveErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPaddingDense,
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            VGap.xl,
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestSpectatorHint extends StatelessWidget {
  const _GuestSpectatorHint({required this.onSignUp, required this.onSignIn});

  final VoidCallback onSignUp;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1C1230), const Color(0xFF120D1F)]
                  : [
                      theme.colorScheme.surface,
                      theme.colorScheme.surfaceContainerLow,
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppBranding.panelBorder(context)),
            boxShadow: [
              BoxShadow(
                color: AppBranding.elevationShadow(
                  context,
                ).withValues(alpha: isDark ? 0.24 : 0.1),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppBranding.brandChipBackground(context),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppBranding.brandChipBorder(context),
                        ),
                      ),
                      child: Text(
                        l10n.guestPromoModeLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppBranding.brandHighlightText(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Expanded(
                      flex: 3,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: onSignIn,
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            child: Text(l10n.signIn),
                          ),
                          FilledButton(
                            onPressed: onSignUp,
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            child: Text(l10n.signUp),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                VGap.md,
                Text(
                  l10n.guestPromoTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                VGap.sm,
                Text(
                  l10n.guestPromoMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                VGap.xl,
                const _GuestCartelaPromoPreview(),
                VGap.sm,
                Text(
                  l10n.guestPromoFooter,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuestCartelaPromoPreview extends StatefulWidget {
  const _GuestCartelaPromoPreview();

  @override
  State<_GuestCartelaPromoPreview> createState() =>
      _GuestCartelaPromoPreviewState();
}

class _GuestCartelaPromoPreviewState extends State<_GuestCartelaPromoPreview>
    with SingleTickerProviderStateMixin {
  static const double _stageSpan = 0.23;
  static const double _congratsStart = 0.69;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  static const List<String> _headers = ['B', 'I', 'N', 'G', 'O'];
  static const List<String> _cells = [
    '7',
    '18',
    '34',
    '48',
    '67',
    '11',
    '20',
    '39',
    '57',
    '71',
    '13',
    '29',
    'FREE',
    '60',
    '73',
    '14',
    '25',
    '42',
    '53',
    '74',
    '15',
    '30',
    '45',
    '58',
    '75',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final stages = _buildStages(l10n);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final activeStageIndex = _activeStageIndex(t);
          final activeStage = stages[activeStageIndex];
          final showCongrats = t >= _congratsStart;
          final stageProgress = _stageProgressFor(t, activeStageIndex);
          final lineProgresses = List<double>.generate(
            stages.length,
            (index) => _lineProgressForStage(t, index),
          );
          final statusLabel = showCongrats
              ? l10n.guestPromoWinnerLabel
              : activeStage.label;
          final helperText = showCongrats
              ? l10n.guestPromoCongratsReceived('10,000 Birr')
              : activeStage.helperText;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppBranding.cartelaBoardBackground(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppBranding.panelBorder(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (final header in _headers)
                      Expanded(
                        child: Center(
                          child: Text(
                            header,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppBranding.bingoColumnColor(header),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                VGap.md,
                SizedBox(
                  height: 208,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 520),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.96,
                            end: 1,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: showCongrats
                        ? _GuestPromoCongratsCard(
                            key: const ValueKey('guest-promo-congrats'),
                            amountLabel: '10,000 Birr',
                          )
                        : Stack(
                            key: const ValueKey('guest-promo-board'),
                            children: [
                              Column(
                                children: List.generate(5, (row) {
                                  return Expanded(
                                    child: Row(
                                      children: List.generate(5, (column) {
                                        final index = (row * 5) + column;
                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: _GuestPromoCell(
                                              label: _cells[index],
                                              marked: _isMarked(
                                                index,
                                                stages: stages,
                                                progress: t,
                                                showCongrats: showCongrats,
                                              ),
                                              emphasized: _isEmphasized(
                                                index,
                                                stages: stages,
                                                stage: activeStage,
                                                progress: stageProgress,
                                                showCongrats: showCongrats,
                                              ),
                                              free: index == 12,
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  );
                                }),
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _GuestPromoWinningLinesPainter(
                                      stages: stages,
                                      progressByStage: lineProgresses,
                                      color: AppBranding.latestCallBorder,
                                      glowColor:
                                          AppBranding.latestCallGlowForTheme(
                                            context,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                VGap.md,
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        helperText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppBranding.brandChipBackground(context),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppBranding.brandChipBorder(context),
                        ),
                      ),
                      child: Text(
                        statusLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppBranding.brandAccentValue(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _activeStageIndex(double progress) {
    if (progress >= _congratsStart) {
      return 2;
    }

    final index = (progress / _stageSpan).floor();
    return index.clamp(0, 2);
  }

  double _stageProgressFor(double progress, int stageIndex) {
    final stageStart = stageIndex * _stageSpan;
    final stageEnd = stageStart + _stageSpan;
    if (progress <= stageStart) {
      return 0;
    }
    if (progress >= stageEnd || progress >= _congratsStart) {
      return 1;
    }
    return ((progress - stageStart) / _stageSpan).clamp(0.0, 1.0);
  }

  double _lineProgressForStage(double progress, int stageIndex) {
    final stageProgress = _stageProgressFor(progress, stageIndex);
    return ((stageProgress - 0.28) / 0.56).clamp(0.0, 1.0);
  }

  bool _isMarked(
    int index, {
    required List<_GuestPromoStage> stages,
    required double progress,
    required bool showCongrats,
  }) {
    if (index == 12) {
      return true;
    }

    for (var stageIndex = 0; stageIndex < stages.length; stageIndex++) {
      final stage = stages[stageIndex];
      final stageProgress = _stageProgressFor(progress, stageIndex);
      final winningPosition = stage.winningIndexes.indexOf(index);
      if (winningPosition >= 0 &&
          (showCongrats ||
              stageProgress >=
                  ((winningPosition + 1) / stage.winningIndexes.length))) {
        return true;
      }

      final accentPosition = stage.accentIndexes.indexOf(index);
      if (accentPosition >= 0 &&
          stageProgress >= (0.14 + (accentPosition * 0.16))) {
        return true;
      }
    }

    return false;
  }

  bool _isEmphasized(
    int index, {
    required List<_GuestPromoStage> stages,
    required _GuestPromoStage stage,
    required double progress,
    required bool showCongrats,
  }) {
    if (!_isMarked(
      index,
      stages: stages,
      progress: progress,
      showCongrats: showCongrats,
    )) {
      return false;
    }

    final pulse = ((progress * 10) % 1.0);
    return pulse > 0.58 && stage.winningIndexes.contains(index);
  }

  List<_GuestPromoStage> _buildStages(AppLocalizations l10n) {
    return [
      _GuestPromoStage(
        label: l10n.guestPromoRowLabel,
        helperText: l10n.guestPromoRowHelper,
        winningIndexes: const [10, 11, 12, 13, 14],
        accentIndexes: const [6, 8],
        lineKind: _GuestPromoLineKind.row,
      ),
      _GuestPromoStage(
        label: l10n.guestPromoColumnLabel,
        helperText: l10n.guestPromoColumnHelper,
        winningIndexes: const [2, 7, 12, 17, 22],
        accentIndexes: const [1, 3, 21],
        lineKind: _GuestPromoLineKind.column,
      ),
      _GuestPromoStage(
        label: l10n.guestPromoDiagonalLabel,
        helperText: l10n.guestPromoDiagonalHelper,
        winningIndexes: const [0, 6, 12, 18, 24],
        accentIndexes: const [4, 20],
        lineKind: _GuestPromoLineKind.diagonal,
      ),
    ];
  }
}

class _GuestPromoCell extends StatelessWidget {
  const _GuestPromoCell({
    required this.label,
    required this.marked,
    required this.emphasized,
    required this.free,
  });

  final String label;
  final bool marked;
  final bool emphasized;
  final bool free;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = free
        ? AppBranding.brandAccentValue(context)
        : marked
        ? AppBranding.bingoFreeGreen.withValues(alpha: 0.9)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.82);
    final foreground = free
        ? AppBranding.brandPurple
        : marked
        ? Colors.white
        : theme.colorScheme.onSurface;

    return Transform.scale(
      scale: emphasized ? 1.04 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: marked || free
                ? Colors.white.withValues(alpha: 0.16)
                : AppBranding.panelBorder(context).withValues(alpha: 0.75),
          ),
          boxShadow: emphasized
              ? [
                  BoxShadow(
                    color: AppBranding.bingoFreeGreen.withValues(alpha: 0.3),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _GuestPromoCongratsCard extends StatelessWidget {
  const _GuestPromoCongratsCard({required this.amountLabel, super.key});

  final String amountLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.94, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppBranding.gold.withValues(alpha: 0.2),
                  AppBranding.latestCallBorder.withValues(alpha: 0.16),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppBranding.gold.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppBranding.gold.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth - 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.celebration_rounded,
                          size: 26,
                          color: AppBranding.brandAccentValue(context),
                        ),
                      ),
                      VGap.sm,
                      Text(
                        l10n.guestPromoCongratsTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      VGap.xs,
                      Text(
                        l10n.guestPromoCongratsAmountWon(amountLabel),
                        textAlign: TextAlign.center,
                        style: AppBranding.wordmarkBrandAccent(size: 24),
                      ),
                      VGap.sm,
                      Text(
                        l10n.guestPromoCongratsReceived(amountLabel),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      VGap.xs,
                      Text(
                        l10n.guestPromoCongratsWithdraw,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GuestPromoWinningLinesPainter extends CustomPainter {
  const _GuestPromoWinningLinesPainter({
    required this.stages,
    required this.progressByStage,
    required this.color,
    required this.glowColor,
  });

  final List<_GuestPromoStage> stages;
  final List<double> progressByStage;
  final Color color;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < stages.length; index++) {
      final progress = progressByStage[index];
      if (progress <= 0) {
        continue;
      }

      final stage = stages[index];
      final start = _cellCenter(size, stage.winningIndexes.first);
      final end = _cellCenter(size, stage.winningIndexes.last);
      final current = Offset.lerp(start, end, progress) ?? end;

      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.32 * progress)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      final linePaint = Paint()
        ..color = color.withValues(alpha: 0.95)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, current, glowPaint);
      canvas.drawLine(start, current, linePaint);
    }
  }

  Offset _cellCenter(Size size, int index) {
    final column = index % 5;
    final row = index ~/ 5;
    final cellWidth = size.width / 5;
    final cellHeight = size.height / 5;
    return Offset(
      (column * cellWidth) + (cellWidth / 2),
      (row * cellHeight) + (cellHeight / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _GuestPromoWinningLinesPainter oldDelegate) {
    return oldDelegate.stages != stages ||
        oldDelegate.progressByStage.length != progressByStage.length ||
        !_sameDoubleList(oldDelegate.progressByStage, progressByStage) ||
        oldDelegate.color != color ||
        oldDelegate.glowColor != glowColor;
  }

  bool _sameDoubleList(List<double> left, List<double> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }

    return true;
  }
}

enum _GuestPromoLineKind { row, column, diagonal }

class _GuestPromoStage {
  const _GuestPromoStage({
    required this.label,
    required this.helperText,
    required this.winningIndexes,
    required this.accentIndexes,
    required this.lineKind,
  });

  final String label;
  final String helperText;
  final List<int> winningIndexes;
  final List<int> accentIndexes;
  final _GuestPromoLineKind lineKind;
}

class _GuestSignupCard extends StatelessWidget {
  const _GuestSignupCard({
    required this.title,
    required this.message,
    required this.onSignUp,
    required this.onSignIn,
  });

  final String title;
  final String message;
  final VoidCallback onSignUp;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPaddingDense,
        child: Column(
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            VGap.md,
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            VGap.xl,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSignIn,
                    child: Text(context.l10n.signIn),
                  ),
                ),
                HGap.md,
                Expanded(
                  child: FilledButton(
                    onPressed: onSignUp,
                    child: Text(context.l10n.signUp),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreparingGamePanel extends StatelessWidget {
  const _PreparingGamePanel({
    required this.registeredCartelas,
    required this.isRefetching,
    this.titleOverride,
    this.messageOverride,
  });

  final List<GameCartelaModel> registeredCartelas;
  final bool isRefetching;
  final String? titleOverride;
  final String? messageOverride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final registeredCount = registeredCartelas.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: AppSpacing.cardPaddingDense,
            child: Column(
              children: [
                if (isRefetching) ...[
                  const FriendsBingoLoading(compact: true),
                  VGap.xl,
                ],
                Text(
                  titleOverride ?? l10n.registrationClosedPreparing,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                VGap.md,
                Text(
                  messageOverride ??
                      (registeredCount == 0
                          ? l10n.preparingGameNoCartelas
                          : l10n.preparingGameCartelasRegistered(
                              registeredCount,
                            )),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (registeredCount > 0) ...[
          VGap.xl,
          Expanded(child: _RegisteredCartelaList(cartelas: registeredCartelas)),
        ],
      ],
    );
  }
}

class _LiveInfoCard extends StatelessWidget {
  const _LiveInfoCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPaddingDense,
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            VGap.md,
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _LiveStatusBanner extends StatelessWidget {
  const _LiveStatusBanner({
    required this.color,
    required this.foregroundColor,
    required this.title,
    required this.message,
  });

  final Color color;
  final Color foregroundColor;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: foregroundColor),
          ),
        ],
      ),
    );
  }
}

class _LiveSyncOverlay extends StatelessWidget {
  const _LiveSyncOverlay({
    required this.visible,
    required this.title,
    required this.message,
    required this.showRetry,
    required this.onRetry,
  });

  final bool visible;
  final String title;
  final String message;
  final bool showRetry;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: visible ? 1 : 0,
        child: Container(
          color: Colors.black.withValues(alpha: 0.12),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.fromLTRB(20, 88, 20, 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Material(
              elevation: 10,
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (showRetry) ...[
                      TextButton(onPressed: onRetry, child: const Text('Retry')),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
