import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/routing/auth_route_guard.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../../../core/sound/game_sound_service.dart';
import '../../../../core/sound/sound_event.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/time/server_clock_provider.dart';
import '../../../../core/time/server_clock_service.dart';
import '../../../../core/utils/api_date_time.dart';
import '../../../../core/storage/app_preferences_storage.dart';
import '../../../../core/widgets/friends_bingo_loader.dart';
import '../../domain/bulk_register_result.dart';
import '../../domain/cartela_availability.dart';
import '../../domain/cartela_payment_source.dart';
import '../../domain/game_rule_localized_name.dart';
import '../../domain/game_category_theme.dart';
import '../../domain/big_game_phase.dart';
import '../utils/big_game_live_presentation.dart';
import '../widgets/game_category_badge.dart';
import '../utils/registration_error_helpers.dart';
import '../utils/cartela_mark_helpers.dart';
import '../utils/cartela_selection_cap.dart';
import '../utils/cartela_marked_pattern_evaluator.dart';
import '../widgets/called_numbers_strip.dart';
import '../../domain/cartela_board_preview_cache.dart';
import '../widgets/bulk_cartela_review_sheet.dart';
import '../widgets/cartela_registration_sheet.dart';
import '../widgets/collapsible_live_top_section.dart';
import '../widgets/collapsible_registered_cartela_chips.dart';
import '../widgets/live_next_round_registration_section.dart';
import '../widgets/chain_game_info_strip.dart';
import '../widgets/chain_game_rounds_dialog.dart';
import '../widgets/chain_round_winners_bar.dart';
import '../widgets/round_finished_banner.dart';
import '../widgets/winner_cartela_dialog.dart';
import '../widgets/registration_action_dock.dart';
import '../widgets/registration_cartela_grid.dart';
import '../widgets/registration_grid_scroll_isolation.dart';
import '../widgets/registration_tap_hint.dart';
import '../widgets/realtime_branding_overlay.dart';
import '../widgets/big_game_live_prompt_banner.dart';
import '../widgets/guest_spectator_section.dart';
import '../widgets/live_game_status_widgets.dart';
import '../widgets/live_registered_cartela_list.dart';
import '../controllers/live_called_numbers_controller.dart';
import '../controllers/live_chain_game_coordinator.dart';
import '../controllers/live_countdown_controller.dart';
import '../controllers/live_countdown_tick_context.dart';
import '../controllers/live_game_controllers.dart';
import '../controllers/live_game_host.dart';
import '../controllers/live_registration_controller.dart';
import '../controllers/live_review_controller.dart';
import '../controllers/registration_action_result.dart';
import '../controllers/registration_panel_session.dart';
import '../controllers/live_realtime_controller.dart';
import '../controllers/live_resume_sync_coordinator.dart';
import '../controllers/live_transition_controller.dart';
import '../controllers/live_winner_celebration_coordinator.dart';
import '../utils/cartela_outcome_public_visibility.dart';
import '../utils/live_ready_transition_lock.dart';
import '../utils/live_presentation_phase.dart';
import '../utils/chain_round_cartela_state.dart';
import '../utils/round_winner_history_adapters.dart';
import '../utils/live_round_break.dart';
import '../../data/models/round_winner_history_model.dart';
import '../utils/live_terminal_apply.dart';
import '../utils/live_primary_game_selection.dart';
import '../utils/live_ui_mode.dart';
import '../utils/live_registration_target.dart';
import '../utils/live_registration_visibility.dart';
import '../utils/live_registration_metrics_patch.dart';
import '../utils/live_session_ownership.dart';
import '../utils/missed_live_preview_numbers.dart';
import '../utils/missed_preview_foreign_session_sync.dart';
import '../debug/missed_preview_debug.dart';
import '../debug/big_game_debug.dart';
import '../utils/registration_reg_display_count.dart';
import '../widgets/missed_live_game_preview.dart';
import '../utils/cartela_display_order.dart';
import '../utils/current_cartela_snapshot_guard.dart';
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
import '../utils/live_status_socket_patch.dart';
import '../utils/live_sync_trigger_action.dart';
import '../utils/socket_payload_normalizer.dart';
import '../../../../core/sync/resume_sync_guard.dart';
import '../utils/live_resume_sync.dart';
import '../utils/live_resume_terminal_gate.dart';
import '../debug/live_realtime_debug.dart';
import '../debug/chain_game_debug.dart';
import '../debug/bingo_claim_diagnostics.dart';
import '../widgets/registration_open_pulse.dart';
import '../widgets/winner_window_countdown.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/widgets/guest_auth_prompt_sheet.dart';
import '../../../wallet/data/models/wallet_model.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../data/games_repository.dart';
import '../../data/models/bingo_claim_result.dart';
import '../../data/models/called_number_model.dart';
import '../../data/models/cartela_model.dart';
import '../../data/models/chain_round_plan_model.dart';
import '../../data/models/game_cartela_model.dart';
import '../../data/models/game_model.dart';
import '../../data/models/completed_pattern_model.dart';
import '../../data/models/game_timing_config_model.dart';
import '../../data/models/session_winner_result_model.dart';
import '../../data/models/session_outcome_summary_model.dart';
import '../providers/games_providers.dart';
import '../providers/cartela_catalog_provider.dart';
import '../providers/cartela_sort_mode_provider.dart';
import '../../domain/cartela_catalog_state.dart';
import '../../data/cartela_marks_storage.dart';
import '../providers/cartela_marks_storage_provider.dart';
import '../providers/big_game_summary_ledger_provider.dart';
import '../providers/current_big_game_provider.dart';
import '../providers/current_game_operations_provider.dart';
import '../providers/game_operations_sync_coordinator.dart';
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
import '../../domain/bingo_claim_source.dart';
import '../utils/registration_ux_metrics.dart';
import '../utils/auto_bingo_runtime.dart';
import '../providers/live_game_state_provider.dart';
import '../controllers/called_balls_notifier.dart';
import '../controllers/player_cartelas_notifier.dart';
import '../../../settings/application/providers/feature_settings_provider.dart';
import '../../../settings/domain/entities/feature_settings.dart';

part 'live_game_orchestration.dart';
part 'live_game_realtime.dart';
part 'live_game_registration.dart';
part 'live_game_called_numbers.dart';
part 'live_game_winner_window.dart';

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

class LiveGameScreen extends ConsumerStatefulWidget {
  const LiveGameScreen({
    this.gameId,
    this.showAppBar = false,
    this.initialGame,
    this.embedded = false,
    this.showBigGameMissedRoundRegistration = false,
    super.key,
  });

  final String? gameId;
  final bool showAppBar;
  final GameModel? initialGame;
  final bool embedded;

  /// Embedded Big Game Round 2+: show missed-style next-round registration UI.
  final bool showBigGameMissedRoundRegistration;

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
  bool get isAppInForeground => _isAppInForeground;

  @override
  String? get gameId => widget.gameId;

  @override
  GameModel? get initialGame => widget.initialGame;

  @override
  GamesRepository get gamesRepository => _gamesRepository;

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
    _cn.markCalledNumbersPanelDirty();
  }

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
    _serverClock = ref.read(serverClockProvider);
    _syncCachedAuthSession();
    _cn.onClaimRecovered = _applyRecoveredClaimAttempt;
    _cn.beforeClaimRecovered = _refreshChainClaimRecoveryContext;
    _cn.onClaimResubmitResult = (attempt, result) {
      _applyRecoveredClaimAttempt(
        attempt,
        BingoClaimAttemptStatus(
          claimAttemptId: result.claim.claimAttemptId,
          status: result.claim.status,
          gameCartelaStatus: result.gameCartelaStatus,
          gameStatus: result.gameStatus,
          isWinner: result.isWinner,
          retryAllowed: result.retryAllowed,
          reasonCode: result.reasonCode ?? result.claim.reasonCode,
          failureCode: result.failureCode ?? result.claim.failureCode,
          nextAutoCallAt: result.hasNextAutoCallAt
              ? result.nextAutoCallAt
              : null,
          winnerWindowEndsAt: result.winnerWindowEndsAt,
        ),
      );
    };
    _cn.onClaimRecoveryChanged = () {
      if (isLiveHostActive) {
        setState(() {});
        _markCalledNumbersPanelDirty();
        _scheduleAutoBingoEvaluation(reason: 'claim_recovery_changed');
      }
    };
    _countdown.onBingoClaimUnlocked = () {
      _scheduleAutoBingoEvaluation(reason: 'bingo_claim_unlocked');
    };
    _warmCartelaMarksStorage();
    if (widget.initialGame != null) {
      _game = widget.initialGame;
      _nextUpcomingGame = widget.initialGame!.nextRoundRegistration;
      _awaitingLiveRoom = false;
      _hasCompletedInitialPaint = true;
      final embeddedBigGameSeed =
          widget.embedded && widget.initialGame!.isBigGame;
      if (embeddedBigGameSeed) {
        // Public card is seeded; wait for canonical + my-cartelas before empty UX.
        _isLoading = false;
        _initialLoadComplete = false;
      } else {
        _isLoading = false;
        _initialLoadComplete = true;
      }
    }
    unawaited(_cn.bindClaimRecoveryScope(_cachedMarksUserId, _activeSessionId));
    WidgetsBinding.instance.addObserver(this);
    LiveGameResumeOwnerRegistry.activate();
    LiveGameResumeOwnerRegistry.setMasterRefresh(_refresh);
    _activeCartelasNotifier = ref.read(
      hasActiveRegisteredCartelasProvider.notifier,
    );
    _authSessionSubscription = ref.listenManual(
      authControllerProvider,
      _onAuthSessionChanged,
    );
    final initialFeatureSettings = ref
        .read(featureSettingsControllerProvider)
        .asData
        ?.value
        .settings;
    _cn.setEffectiveAutoMark(
      initialFeatureSettings?.effectiveAutoMark ?? false,
    );
    _cn.setEffectiveAutoBingo(
      initialFeatureSettings?.effectiveAutoBingo ?? false,
    );
    _featureSettingsSubscription = ref.listenManual(
      featureSettingsControllerProvider,
      _onFeatureSettingsChanged,
    );
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

  void _onFeatureSettingsChanged(
    AsyncValue<FeatureSettingsUiState>? previous,
    AsyncValue<FeatureSettingsUiState> next,
  ) {
    final settings = next.asData?.value.settings;
    final nextAutoMark = settings?.effectiveAutoMark ?? false;
    final nextAutoBingo = settings?.effectiveAutoBingo ?? false;
    final autoMarkChanged = _cn.effectiveAutoMark != nextAutoMark;
    final autoBingoChanged = _cn.effectiveAutoBingo != nextAutoBingo;
    if (!autoMarkChanged && !autoBingoChanged) {
      return;
    }

    if (!mounted || !isLiveHostActive) {
      if (autoMarkChanged) {
        _cn.setEffectiveAutoMark(nextAutoMark);
      }
      if (autoBingoChanged) {
        _cn.setEffectiveAutoBingo(nextAutoBingo);
      }
      return;
    }

    setState(() {
      if (autoMarkChanged) {
        _cn.setEffectiveAutoMark(nextAutoMark);
        _sortMyCartelas();
      }
      if (autoBingoChanged) {
        _cn.setEffectiveAutoBingo(nextAutoBingo);
      }
    });
    if (autoBingoChanged && nextAutoBingo) {
      _scheduleAutoBingoEvaluation(reason: 'feature_settings_enabled');
    }
  }

  @override
  void dispose() {
    _hostTornDown = true;
    _removeSocketListeners();
    _loadGeneration++;
    _authSessionSubscription?.close();
    _authSessionSubscription = null;
    _featureSettingsSubscription?.close();
    _featureSettingsSubscription = null;
    _countdown.onBingoClaimUnlocked = null;
    // Riverpod forbids provider writes during widget-tree finalization; defer clear.
    final cartelasNotifier = _activeCartelasNotifier;
    _activeCartelasNotifier = null;
    if (cartelasNotifier != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          cartelasNotifier.clear();
        } catch (_) {}
      });
    }
    WidgetsBinding.instance.removeObserver(this);
    _stopChainRoundPauseTicker();
    _disposeChainPauseEndsAtListenable();
    _liveRoomSplashTicker?.cancel();
    _liveCartelaScrollIdle.dispose();
    _review.stopSessionWinnerResultsPolling();
    controllers.transition.preparingPhasePollTimer?.cancel();
    controllers.transition.readyTransitionLockTimeoutTimer?.cancel();
    _stopPreparingPhasePolling();
    controllers.transition.clearReadyTransitionLock();
    _cancelCanonicalRefetchDebounce();
    controllers.dispose();
    _stopDisconnectedCalledNumbersPolling();
    _invalidSocketPayloadRefetchTimer?.cancel();
    _myCartelasRefreshDebounceTimer?.cancel();
    _nextCartelasRefreshDebounceTimer?.cancel();
    _applySocketSessionMembership(null);
    _socketMembership.dispose();
    LiveGameResumeOwnerRegistry.setMasterRefresh(null);
    LiveGameResumeOwnerRegistry.deactivate();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isLiveHostActive) {
      return;
    }

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _isAppInForeground = false;
        _cn.setClaimRecoveryForeground(false);
        _socketMembership.setForeground(false);
        _pauseLiveTimersForBackground();
        unawaited(_persistManualMarks());
        break;
      case AppLifecycleState.hidden:
        _isAppInForeground = false;
        _cn.setClaimRecoveryForeground(false);
        _socketMembership.setForeground(false);
        _pauseLiveTimersForBackground();
        break;
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        _cn.setClaimRecoveryForeground(true);
        unawaited(_recoverFromAppResume());
        break;
    }
  }

  void _pauseLiveTimersForBackground() {
    _countdown.pauseForAppBackground();
    _transition.stopPreparingPhasePolling();
    _cn.stopDisconnectedPolling();
    controllers.missedPreview.stopPollingForBackground();
  }

  void _onAuthSessionChanged(AuthState? previous, AuthState next) {
    final hadSession = previous?.session != null;
    final hasSession = next.session != null;
    if (previous?.session?.user.id == next.session?.user.id) {
      return;
    }

    // Invalidate old-user callbacks immediately, before deferred UI work.
    _applySocketSessionMembership(null);
    _syncCachedAuthSession();
    // Stop Auto Mark/Bingo scheduling for the prior user; do not cancel
    // SharedPreferences claim identities (scoped by userId/sessionId).
    _cn.setEffectiveAutoMark(false);
    _cn.setEffectiveAutoBingo(false);
    _cn.ensureAutoBingoScope(sessionId: null, roundIndex: 0);
    unawaited(_cn.bindClaimRecoveryScope(_cachedMarksUserId, _activeSessionId));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.microtask(() async {
        _syncCachedAuthSession();
        if (!isLiveHostActive) {
          return;
        }

        if (!hadSession && hasSession) {
          await _loadInitialState(
            showLoading: false,
            operationsSyncReason: OperationsSyncReason.sessionRestore,
          );
          if (!isLiveHostActive) {
            return;
          }
          _ensureManualMarksReadyForActiveSession();
          return;
        }

        if (_cn.manualMarkedNumbers.isNotEmpty ||
            _cn.lastManualMarkedKey != null ||
            _cn.marksOwnerUserId != null ||
            _cn.restoredMarksSessionId != null) {
          if (!isLiveHostActive) {
            return;
          }
          setState(() {
            _cn.manualMarkedNumbers.clear();
            _cn.lastManualMarkedKey = null;
            _cn.marksSessionId = null;
            _cn.marksOwnerUserId = null;
            _cn.restoredMarksSessionId = null;
            _cn.notifyManualMarksChanged();
          });
        }

        if (!isLiveHostActive) {
          return;
        }
        await _loadInitialState(
          showLoading: false,
          operationsSyncReason: OperationsSyncReason.sessionRestore,
        );
      });
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
              // Transition handoff uses inline "Opening next round…" — never a
              // modal/dim overlay. Keep this overlay for realtime sync only.
              visible: _realtime.showSyncOverlay,
              title: _realtime.syncOverlayTitle,
              message: _realtime.syncOverlayMessage,
              dimContent: false,
              showRetry: _realtime.lastSyncFailed,
              onRetry: () => unawaited(_refresh()),
            ),
        ],
      ),
    );
  }

  String get _bodyTransitionKey {
    final game = _game;
    if (game != null) {
      final sessionKey = game.sessionId ?? game.id;
      final phase = _livePresentationPhase;
      if (phase == LivePresentationPhase.winnerWindow ||
          phase == LivePresentationPhase.review ||
          phase == LivePresentationPhase.liveCalling ||
          phase == LivePresentationPhase.liveWaitingFirstBall ||
          phase == LivePresentationPhase.checking ||
          _resolverPinsTerminalSession) {
        return 'live-$sessionKey';
      }
    }

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
      isGuest: isGuest,
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
    // Initial load with no content yet: cover the whole screen with the branded
    // loader instead of a tiny spinner on a dark surface (which reads as a
    // black gap). Background reloads (game already present) keep their content.
    if (_isLoading && _game == null) {
      return const FriendsBingoLoader.fullscreen();
    }

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

      // Live play cartela list: no pull-to-refresh — swipe-down must only scroll.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppSpacing.screenPadding.copyWith(top: 0, bottom: 0),
            child: _buildStickyLiveHeader(),
          ),
          Expanded(child: _buildStickyLiveScrollView()),
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
              padding: AppSpacing.screenPadding.copyWith(
                top: 0,
                bottom:
                    AppSpacing.screenPadding.bottom +
                    MediaQuery.viewPaddingOf(context).bottom,
              ),
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
    final game = _withSocketRegistrationMetrics(_registrationOpenBodyTarget!);
    final isCurrentRound = _isCurrentGameTarget(game);
    final phase = isCurrentRound
        ? _livePresentationPhase
        : LivePresentationPhase.registrationOpen;
    final cartelaActionsEnabled = isCurrentRound
        ? phase.cartelaActionsEnabled
        : game.canRegister;
    // Embedded Big Game: keep the selection grid while the play-start window
    // is still open, even if a stale canRegister/preparing latch would hide it.
    final allowEmbeddedBigGameRegistration =
        widget.embedded &&
        game.isBigGame &&
        (game.canRegister ||
            isBigGameRegistrationWindowOpen(game, now: _countdownNow()));
    final showRegistrationActions =
        cartelaActionsEnabled || allowEmbeddedBigGameRegistration;
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
        showRegistrationActions &&
        ((widget.showBigGameMissedRoundRegistration &&
                widget.embedded &&
                game.isBigGame) ||
            (!widget.embedded &&
                controllers.missedPreview.showMissedRoundWrapper &&
                (uiMode.showMissedRoundWrapper ||
                    uiMode.useRegistrationOpenLayout)));
    final showRegistrationHandoffPreparing =
        !widget.embedded &&
        (uiMode.mode == LiveUiMode.handoffOpeningNext ||
            controllers.missedPreview.showHandoffHold);
    final isMissedRoundRegistration =
        (widget.showBigGameMissedRoundRegistration &&
            widget.embedded &&
            game.isBigGame) ||
        (!widget.embedded && controllers.missedPreview.showMissedRoundWrapper);
    // Handoff keeps the registration pulse header so "Opening next round…" is
    // inline — never a modal overlay.
    final showRegistrationPulseHeader =
        phase == LivePresentationPhase.registrationOpen ||
        showRegistrationHandoffPreparing;
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
          if (showRegistrationPulseHeader)
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
                isGuest: isGuest,
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
          if (!showRegistrationPulseHeader && statusBanner != null) ...[
            VGap.sm,
            statusBanner,
          ],
          _buildMissedLivePreviewSection(),
          VGap.sm,
          Expanded(
            child: !uiMode.showRegistrationGrid
                ? (isGuest
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          children: [
                            _GuestSpectatorHint(
                              onSignUp: () => context.go('/register'),
                              onSignIn: () =>
                                  context.go(loginPathWithRedirect('/games')),
                            ),
                          ],
                        )
                      : const Center(
                          child: FriendsBingoLoader.inline(compact: true),
                        ))
                : showRegistrationActions
                ? registrationBody
                : widget.embedded && game.isBigGame
                ? _BigGameEmbeddedWaitingPanel(isRefetching: _isLoading)
                : _PreparingGamePanel(
                    registeredCartelas: registeredCartelas,
                    isRefetching: showRegistrationHandoffPreparing,
                    // Title is on the pulse banner during handoff.
                    messageOverride: showRegistrationHandoffPreparing
                        ? context.l10n.gameOpeningNextRoundMessage
                        : null,
                  ),
          ),
        ],
      ),
    );
  }

  GameModel? get _registrationOpenBodyTarget =>
      _liveUiMode.registrationOpenBodyTarget;

  /// Registration-open UI reads [GameModel] from the operations snapshot, which
  /// is not updated by socket prize/reg events. Overlay those metrics from the
  /// socket-patched [_game] / [_nextUpcomingGame] for the same session.
  GameModel _withSocketRegistrationMetrics(GameModel target) {
    final sessionId = target.sessionId;
    if (sessionId == null) {
      return target;
    }

    final GameModel? liveSource;
    if (_game?.sessionId == sessionId) {
      liveSource = _game;
    } else if (_nextUpcomingGame?.sessionId == sessionId) {
      liveSource = _nextUpcomingGame;
    } else {
      liveSource = null;
    }

    if (liveSource == null) {
      return target;
    }

    final nextPrize = liveSource.prizeAmount;
    final nextRegCount = liveSource.registeredCartelasCount;
    if (nextPrize == target.prizeAmount &&
        nextRegCount == target.registeredCartelasCount) {
      return target;
    }

    return target.copyWith(
      prizeAmount: nextPrize,
      registeredCartelasCount: nextRegCount,
    );
  }

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
    if (isGuest) {
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
        SizedBox.expand(child: FriendsBingoLoader.inline(compact: true)),
      ];
    }
    if (_errorMessage != null) {
      return [_LiveErrorState(message: _errorMessage!, onRetry: _refresh)];
    }
    if (_game == null) {
      if (isGuest) {
        return [
          _GuestSpectatorHint(
            onSignUp: () => context.go('/register'),
            onSignIn: () => context.go(loginPathWithRedirect('/games')),
          ),
        ];
      }
      return [
        _LiveInfoCard(
          title: context.l10n.liveNoGameTitle,
          message: _emptyMessage ?? context.l10n.liveNoGameMessage,
        ),
      ];
    }

    return [_buildActiveGameContent(includeCalledNumbersStrip: true)];
  }

  /// Primary live-play scroller: sticky header stays outside; cartelas use a
  /// real 2-col [SliverGrid] (no shrinkWrap) so only on-screen cards build.
  Widget _buildStickyLiveScrollView() {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final padding = AppSpacing.screenPadding.copyWith(
      top: AppSpacing.sm,
      bottom: AppSpacing.screenPadding.bottom + bottomInset,
    );

    if (_showsGuestSpectator) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          _GuestSpectatorHint(
            onSignUp: () => context.go('/register'),
            onSignIn: () => context.go(loginPathWithRedirect('/games')),
          ),
        ],
      );
    }

    if (!_hasVisibleCurrentSessionCartelas) {
      final l10n = context.l10n;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          _MissedNoNextCard(
            title: l10n.liveMissedNoNextTitle,
            message: l10n.liveMissedNoNextMessage,
            tipWatch: l10n.liveMissedNoNextTipWatch,
            tipRefresh: l10n.liveMissedNoNextTipRefresh,
          ),
        ],
      );
    }

    final cartelaSortMode = ref.watch(cartelaSortModeProvider);
    final cartelaSortMaxRemains = ref.watch(cartelaSortMaxRemainsProvider);
    final cartelaList = _buildPlayCartelaList(
      cartelaSortMode: cartelaSortMode,
      cartelaSortMaxRemains: cartelaSortMaxRemains,
      decorativeMotionAllowedListenable: _liveCartelaScrollIdle,
    );

    final showRegistrationFooter =
        _shouldShowInlineRegistrationPanel && !_blocksRegistrationPromotion;

    return LayoutBuilder(
      builder: (context, constraints) {
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.depth != 0) {
              return false;
            }
            // Pause decorative pulses only for the whole gesture — keep scroll continuous.
            if (notification is ScrollStartNotification) {
              if (_liveCartelaScrollIdle.value) {
                _liveCartelaScrollIdle.value = false;
              }
            } else if (notification is ScrollEndNotification) {
              if (!_liveCartelaScrollIdle.value) {
                _liveCartelaScrollIdle.value = true;
              }
            }
            return false;
          },
          child: CustomScrollView(
            // Whole cartela pane scrolls continuously (not row/column snap).
            // ignore: deprecated_member_use
            cacheExtent: 900,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: padding,
                sliver: cartelaList.asSliver(
                  crossAxisExtent: constraints.maxWidth - padding.horizontal,
                ),
              ),
              if (showRegistrationFooter)
                SliverPadding(
                  padding: padding.copyWith(top: AppSpacing.md),
                  sliver: SliverToBoxAdapter(
                    child: _buildRegistrationTargetSection(),
                  ),
                ),
            ],
          ),
        );
      },
    );
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

    // Missed-round overlap: dual Missed + Next card only while observer says so.
    // After Game A ends (handoff / none), do not keep the stale Missed card.
    // Embedded Big Game uses [showBigGameMissedRoundRegistration] instead of
    // the standard missed-preview observer.
    if (!isCurrentRound &&
        (controllers.missedPreview.showMissedRoundWrapper ||
            (widget.showBigGameMissedRoundRegistration && target.isBigGame))) {
      return _buildMissedRoundRegistrationSection(target: target, panel: panel);
    }

    final l10n = context.l10n;

    if (!isCurrentRound) {
      return LiveNextRoundRegistrationSection(
        gameName: target.localizedRuleName(ref),
        nextGame: target,
        sectionTitle: l10n.liveNextRoundRegistrationTitle,
        helperText: controllers.missedPreview.showHandoffHold
            ? l10n.postGameSummaryOpeningNextRound
            : l10n.liveMissedRoundHelper,
        registeredCartelaNumbers: _nextRegisteredCartelaNumbers,
        panel: panel,
        variant: LiveNextRoundSectionVariant.nextQueued,
      );
    }

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
    final previous = target.previousRound;
    final isBigGameMissed =
        widget.showBigGameMissedRoundRegistration && target.isBigGame;
    final previousRoundLabel = previous == null
        ? null
        : l10n.bigGameMissedPreviousRoundLabel(previous.roundIndex);
    final nextRoundLabel = l10n.bigGameMissedNextRoundLabel(
      target.displayRoundIndex,
    );

    return LiveNextRoundRegistrationSection(
      gameName: isBigGameMissed
          ? nextRoundLabel
          : target.localizedRuleName(ref),
      currentRoundGameName: isBigGameMissed
          ? previousRoundLabel
          : controllers.missedPreview.blockingLiveGame?.localizedRuleName(ref),
      currentRoundGame: isBigGameMissed
          ? null
          : controllers.missedPreview.blockingLiveGame,
      nextGame: target,
      sectionTitle: isBigGameMissed
          ? l10n.bigGameMissedRoundRegistrationTitle(target.displayRoundIndex)
          : l10n.liveNextRoundRegistrationTitle,
      helperText: isBigGameMissed
          ? l10n.bigGameMissedRoundHelper(
              previous?.roundIndex ?? (target.displayRoundIndex - 1),
              target.displayRoundIndex,
            )
          : l10n.liveMissedRoundHelper,
      registeredCartelaNumbers: isBigGameMissed
          ? _myCartelas.map((c) => c.cartela.number).toList(growable: false)
          : _nextRegisteredCartelaNumbers,
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
        if (_buildChainGameInfoStrip() case final chainStrip?) ...[
          VGap.sm,
          chainStrip,
        ],
        if (_buildChainInterRoundSummaryBanner() case final chainSummary?) ...[
          VGap.sm,
          chainSummary,
        ],
        if (_buildPostGameSummaryBanner() case final summaryBanner?) ...[
          VGap.sm,
          summaryBanner,
        ],
        if (_buildChainRoundWinnersBar() case final chainWinners?) ...[
          VGap.sm,
          chainWinners,
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
        if (_buildChainInterRoundSummaryBanner() case final chainSummary?) ...[
          chainSummary,
          VGap.sm,
        ],
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
        if (_buildChainGameInfoStrip() case final chainStrip?) ...[
          VGap.sm,
          chainStrip,
        ],
        if (_buildChainInterRoundSummaryBanner() case final chainSummary?) ...[
          VGap.sm,
          chainSummary,
        ],
        if (_buildPostGameSummaryBanner() case final summaryBanner?) ...[
          VGap.sm,
          summaryBanner,
        ],
        if (_buildChainRoundWinnersBar() case final chainWinners?) ...[
          VGap.sm,
          chainWinners,
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
          _suppressEmbeddedBigGameEmptyCartelaState
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: const Center(
                    child: FriendsBingoLoader.inline(compact: true),
                  ),
                )
              : isGuest
              ? _GuestSpectatorHint(
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
          Builder(
            builder: (context) {
              final cartelaSortMode = ref.watch(cartelaSortModeProvider);
              final cartelaSortMaxRemains = ref.watch(
                cartelaSortMaxRemainsProvider,
              );
              return _buildPlayCartelaList(
                cartelaSortMode: cartelaSortMode,
                cartelaSortMaxRemains: cartelaSortMaxRemains,
              );
            },
          ),
          if (_shouldShowInlineRegistrationPanel &&
              !_review.postGameSummaryReviewActive) ...[
            VGap.xl,
            _buildRegistrationTargetSection(),
          ],
        ] else if (_hasVisibleCurrentSessionCartelas)
          widget.embedded && (_game?.isBigGame ?? false)
              ? _BigGameEmbeddedWaitingPanel(isRefetching: _isLoading)
              : _RegisteredCartelaList(cartelas: _myCartelas),
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
    if (isGuest || !_hasVisibleCurrentSessionCartelas) {
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
      fixedPrizeAmount: target.isBigGame
          ? (target.effectiveRoundPrizeAmount ?? target.fixedPrizeAmount)
          : target.fixedPrizeAmount,
      maxCartelasPerPlayer: target.maxCartelasPerPlayer,
      roundPrizes: target.isChainGame ? target.roundPrizes : null,
      registeredCartelas: registeredCartelas,
      cartelaHoldSeconds: _cartelaHoldSeconds,
      bulkSelectionSeconds: _effectiveBulkSelectionSeconds,
      isGuest: isGuest,
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

    if (isGuest) {
      await showGuestAuthPromptSheet(context);
      return;
    }

    setState(_capturePreviousCartelasForAutoOpen);

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

  bool get _showsGuestSpectator => isGuest && _showsInlinePlayCartelas;

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
    if (isGuest) {
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

typedef _RegisteredCartelaList = RegisteredCartelaList;
typedef _InlineRegisteredCartelaList = InlineRegisteredCartelaList;
typedef _LiveErrorState = LiveErrorState;
typedef _GuestSpectatorHint = GuestSpectatorSection;
typedef _PreparingGamePanel = PreparingGamePanel;
typedef _BigGameEmbeddedWaitingPanel = BigGameEmbeddedWaitingPanel;
typedef _MissedNoNextCard = MissedNoNextCard;
typedef _LiveInfoCard = LiveInfoCard;
typedef _LiveStatusBanner = LiveStatusBanner;
typedef _LiveSyncOverlay = LiveSyncOverlay;

