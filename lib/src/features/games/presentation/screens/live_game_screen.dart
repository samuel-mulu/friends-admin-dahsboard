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
import 'package:friends_bingo_app/src/features/games/registration/domain/bulk_register_result.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_availability.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_payment_source.dart';
import 'package:friends_bingo_app/src/features/games/patterns/domain/game_rule_localized_name.dart';
import '../../domain/game_category_theme.dart';
import '../../domain/big_game_phase.dart';
import '../utils/big_game_live_presentation.dart';
import '../widgets/game_category_badge.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/registration_error_helpers.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_mark_helpers.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_selection_cap.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_marked_pattern_evaluator.dart';
import '../widgets/called_numbers_strip.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_board_preview_cache.dart';
import 'package:friends_bingo_app/src/features/games/registration/presentation/widgets/bulk_cartela_review_sheet.dart';
import 'package:friends_bingo_app/src/features/games/registration/presentation/widgets/cartela_registration_sheet.dart';
import '../widgets/collapsible_live_top_section.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/collapsible_registered_cartela_chips.dart';
import 'package:friends_bingo_app/src/features/games/registration/presentation/widgets/live_next_round_registration_section.dart';
import '../widgets/chain_game_info_strip.dart';
import '../widgets/chain_game_rounds_dialog.dart';
import '../widgets/chain_round_winners_bar.dart';
import '../widgets/round_finished_banner.dart';
import '../widgets/winner_cartela_dialog.dart';
import 'package:friends_bingo_app/src/features/games/registration/presentation/widgets/registration_action_dock.dart';
import 'package:friends_bingo_app/src/features/games/registration/presentation/widgets/registration_cartela_grid.dart';
import 'package:friends_bingo_app/src/features/games/registration/presentation/widgets/registration_grid_scroll_isolation.dart';
import 'package:friends_bingo_app/src/features/games/registration/presentation/widgets/registration_tap_hint.dart';
import '../widgets/realtime_branding_overlay.dart';
import '../widgets/big_game_live_prompt_banner.dart';
import '../widgets/guest_spectator_section.dart';
import '../widgets/live_game_status_widgets.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/live_registered_cartela_list.dart';
import '../../application/controllers/live_called_numbers_controller.dart';
import '../../application/controllers/live_chain_game_coordinator.dart';
import '../../application/controllers/live_countdown_controller.dart';
import '../../application/controllers/live_countdown_tick_context.dart';
import '../../application/controllers/live_game_controllers.dart';
import '../../application/controllers/live_game_host.dart';
import 'package:friends_bingo_app/src/features/games/registration/application/controllers/live_registration_controller.dart';
import '../../application/controllers/live_review_controller.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/registration_action_result.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/registration_panel_session.dart';
import '../../application/controllers/live_realtime_controller.dart';
import '../../application/controllers/live_resume_sync_coordinator.dart';
import '../../application/controllers/live_transition_controller.dart';
import '../../application/controllers/live_winner_celebration_coordinator.dart';
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
import 'package:friends_bingo_app/src/features/games/registration/domain/live_registration_target.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/live_registration_visibility.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/live_registration_metrics_patch.dart';
import '../utils/live_session_ownership.dart';
import '../utils/missed_live_preview_numbers.dart';
import '../utils/missed_preview_foreign_session_sync.dart';
import '../debug/missed_preview_debug.dart';
import '../debug/big_game_debug.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/registration_reg_display_count.dart';
import '../widgets/missed_live_game_preview.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_display_order.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/current_cartela_snapshot_guard.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/merge_registered_cartelas.dart';
import '../utils/live_game_event_guard.dart';
import '../utils/live_game_finish_transition.dart';
import '../utils/live_terminal_enter_policy.dart';
import '../utils/winner_pattern_clear_policy.dart';
import '../utils/live_socket_session_membership.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/registration_cartela_grid_index.dart';
import '../utils/called_numbers_strip_heal.dart';
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
import 'package:friends_bingo_app/src/features/games/registration/presentation/widgets/registration_open_pulse.dart';
import '../widgets/winner_window_countdown.dart';
import '../../../auth/application/controllers/auth_controller.dart';
import '../../../auth/presentation/widgets/guest_auth_prompt_sheet.dart';
import '../../../wallet/overview/data/models/wallet_model.dart';
import '../../../wallet/overview/application/providers/wallet_provider.dart';
import '../../cartelas/data/repositories/cartelas_repository.dart';
import '../../data/games_repository.dart';
import 'package:friends_bingo_app/src/features/games/claims/data/models/bingo_claim_result.dart';
import '../../data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import '../../data/models/chain_round_plan_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import '../../data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/patterns/data/models/completed_pattern_model.dart';
import '../../data/models/game_timing_config_model.dart';
import '../../data/models/session_winner_result_model.dart';
import '../../data/models/session_outcome_summary_model.dart';
import '../../application/providers/games_providers.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/application/providers/cartela_catalog_provider.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/application/providers/cartela_sort_mode_provider.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_catalog_state.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/storage/cartela_marks_storage.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/application/providers/cartela_marks_storage_provider.dart';
import '../../application/providers/big_game_summary_ledger_provider.dart';
import '../../application/providers/current_big_game_provider.dart';
import '../../application/providers/current_game_operations_provider.dart';
import '../../application/providers/game_operations_sync_coordinator.dart';
import 'package:friends_bingo_app/src/features/games/registration/application/providers/has_active_registered_cartelas_provider.dart';
import '../utils/live_game_resume_owner_registry.dart';
import '../utils/game_operations_resume_cache.dart';
import '../utils/live_resume_conditional_fetch.dart';
import '../../application/providers/realtime_connection_provider.dart';
import 'package:friends_bingo_app/src/features/games/registration/application/providers/registration_state_patch_provider.dart';
import '../utils/live_embedded_operations_snapshot.dart';
import '../utils/live_resume_provider_policy.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/registration_state_patch.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/resolved_cartela_availability.dart';
import 'package:friends_bingo_app/src/features/games/claims/domain/bingo_claim_source.dart';
import 'package:friends_bingo_app/src/features/games/claims/domain/bingo_claim_attempt.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/registration_ux_metrics.dart';
import '../utils/auto_bingo_runtime.dart';
import '../../application/providers/live_game_state_provider.dart';
import '../../application/controllers/called_balls_notifier.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/application/providers/player_cartelas_notifier.dart';
import '../../../settings/application/providers/feature_settings_provider.dart';
import '../../../settings/domain/entities/feature_settings.dart';

import '../widgets/live_game_app_bar_section.dart';
import '../widgets/live_game_content_switcher.dart';

part 'live_game_state_base.dart';
part 'live_game_views.dart';
part 'live_game_orchestration.dart';
part 'live_game_realtime.dart';
part 'live_game_registration.dart';
part 'live_game_called_numbers.dart';
part 'live_game_winner_window.dart';
part 'live_game_lifecycle.dart';

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

class _LiveGameScreenState extends _LiveGameScreenStateBase
    with
        _LiveGameOrchestration,
        _LiveGameRealtime,
        _LiveGameCalledNumbers,
        _LiveGameWinnerWindow,
        _LiveGameRegistration,
        _LiveGameLifecycle,
        _LiveGameViews {
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
  @override
  Widget build(BuildContext context) {
    final body = LiveGameContentSwitcher(
      transitionKey: _bodyTransitionKey,
      hasCompletedInitialPaint: _hasCompletedInitialPaint,
      child: _buildBody(),
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
            appBar: const LiveGameAppBarSection(),
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
              dimContent: false,
              showRetry: _realtime.lastSyncFailed,
              onRetry: () => unawaited(_refresh()),
            ),
        ],
      ),
    );
  }
}
