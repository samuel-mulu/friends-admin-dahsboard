import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/realtime/socket_service.dart';
import '../../../../core/time/server_clock_service.dart';
import '../../../../core/sync/resume_sync_guard.dart';
import '../debug/live_realtime_debug.dart';
import '../../domain/live_connection_status.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../providers/current_game_operations_provider.dart';
import '../providers/games_providers.dart';
import '../utils/live_resume_provider_policy.dart';
import '../utils/live_resume_terminal_gate.dart';
import '../utils/live_sync_trigger_action.dart';
import '../utils/live_socket_session_membership.dart';
import 'live_game_host.dart';

/// Socket membership, canonical refetch scheduling, and event session guards.
class LiveRealtimeController {
  LiveRealtimeController(this.host);

  final LiveGameHost host;

  static const _terminalCanonicalRefetchCoalesceWindow = Duration(
    milliseconds: 900,
  );
  static const _resumeSyncDebounce = Duration(milliseconds: 700);
  // On mobile a flaky connection fires repeated socket `connect` events; each
  // one would otherwise run a full canonical fetch. If canonical truth was
  // applied very recently, skip the redundant reconnect fetch — the room
  // rejoin and live socket events (both handled before this runs) already keep
  // state current. This kills reconnect "sync storms" and the entry-time
  // double fetch (initial load immediately followed by the first connect).
  static const _reconnectSyncThrottle = Duration(seconds: 2);
  static const _syncOverlayDelayManual = Duration(milliseconds: 1500);
  static const _syncOverlayDelayBackground = Duration(seconds: 3);
  static const _recentSyncSkipWindow = Duration(seconds: 5);
  static const _currentBadgeDuration = Duration(seconds: 4);

  final LiveSocketSessionMembership socketMembership =
      LiveSocketSessionMembership();
  String? joinedGameId;
  Timer? canonicalRefetchDebounceTimer;
  Timer? resumeSyncDebounceTimer;
  bool scheduledIncludeWallet = false;
  bool scheduledIncludeRegistrationState = false;
  bool scheduledIncludeCalledNumbers = false;
  bool scheduledIncludeMyCartelas = false;
  String? scheduledRegistrationSessionId;
  String? scheduledRefetchReason;
  bool canonicalRefetchInFlight = false;
  bool pendingRefetchWallet = false;
  bool pendingRefetchIncludeCalledNumbers = false;
  bool pendingRefetchIncludeMyCartelas = false;
  String? pendingRefetchReason;
  Future<void>? refetchCanonicalLoop;
  Timer? disconnectedCalledNumbersPollTimer;
  bool isSyncingLiveGame = false;
  DateTime? lastTerminalCanonicalRefetchRequestedAt;
  bool resumeSyncInFlight = false;
  final Set<String> _collectedResumeReasons = {};
  Completer<void>? _resumeSyncCompleter;
  Timer? _syncOverlayTimer;
  Timer? _currentBadgeTimer;
  bool _syncOverlayVisible = false;
  bool _lastSyncFailed = false;
  DateTime? _lastSuccessfulSyncAt;
  String? _activeSyncReason;

  ServerClockService get serverClock => host.serverClock;
  SocketService get socketService => host.socketService;
  LiveConnectionState get connectionState => _resolveConnectionState();
  // Never paint the sync overlay on top of held terminal UI during a transition.
  // Ready-transition lock unknown outcome uses a dedicated loading overlay on the
  // screen instead of inventing a READY/registration shell.
  bool get showSyncOverlay =>
      _syncOverlayVisible &&
      !host.isTerminalTransitionActive &&
      !host.controllers.transition.readyTransitionLockActive;
  bool get showHeaderSyncSpinner =>
      (_syncScheduled || resumeSyncInFlight) &&
      (_activeSyncReason == 'manual_refresh' || _lastSyncFailed);
  bool get lastSyncFailed => _lastSyncFailed;
  String get syncOverlayTitle =>
      _isReconnectStyleSync ? 'Reconnecting...' : 'Syncing latest game...';
  String get syncOverlayMessage => _isReconnectStyleSync
      ? 'Reconnecting to the live round...'
      : 'Syncing latest game state...';

  void dispose() {
    cancelCanonicalRefetchDebounce();
    resumeSyncDebounceTimer?.cancel();
    resumeSyncDebounceTimer = null;
    _syncOverlayTimer?.cancel();
    _currentBadgeTimer?.cancel();
    disconnectedCalledNumbersPollTimer?.cancel();
    pendingRefetchWallet = false;
    pendingRefetchIncludeCalledNumbers = false;
    pendingRefetchIncludeMyCartelas = false;
    pendingRefetchReason = null;
  }

  void applySocketSessionMembership(
    String? sessionId, {
    required void Function(String sessionId) join,
    required void Function(String sessionId) leave,
    void Function()? onMembershipChanged,
  }) {
    socketMembership.apply(sessionId, join: join, leave: leave);
    joinedGameId = socketMembership.joinedSessionId;
    onMembershipChanged?.call();
  }

  void joinSessionRoomEarly(
    String? sessionId, {
    required bool Function(String value) looksLikeSessionId,
    required void Function(String? sessionId) applyMembership,
  }) {
    if (sessionId == null || !looksLikeSessionId(sessionId)) {
      return;
    }
    applyMembership(sessionId);
  }

  void cancelCanonicalRefetchDebounce() {
    canonicalRefetchDebounceTimer?.cancel();
    canonicalRefetchDebounceTimer = null;
    _clearScheduledRefetchFlags();
  }

  void scheduleCanonicalRefetch({
    required String reason,
    bool wallet = false,
    bool includeCalledNumbers = false,
    bool includeMyCartelas = false,
    String? registrationSessionId,
  }) {
    if (!host.isLiveHostActive) {
      return;
    }

    LiveRealtimeDebug.refreshRequested(reason: reason);

    if (wallet) {
      scheduledIncludeWallet = true;
    }
    if (registrationSessionId != null) {
      scheduledIncludeRegistrationState = true;
      scheduledRegistrationSessionId = registrationSessionId;
    }
    if (includeCalledNumbers) {
      scheduledIncludeCalledNumbers = true;
    }
    if (includeMyCartelas) {
      scheduledIncludeMyCartelas = true;
    }
    scheduledRefetchReason = reason;

    canonicalRefetchDebounceTimer?.cancel();
    canonicalRefetchDebounceTimer = Timer(
      host.effectiveTimingConfig.canonicalRefetchDebounce,
      () {
        canonicalRefetchDebounceTimer = null;
        if (!host.isLiveHostActive) {
          return;
        }

        final includeWallet = scheduledIncludeWallet;
        final includeRegistrationState = scheduledIncludeRegistrationState;
        final includeCalledNumbers = scheduledIncludeCalledNumbers;
        final includeMyCartelas = scheduledIncludeMyCartelas;
        final sessionId = scheduledRegistrationSessionId;
        final debounceReason = scheduledRefetchReason ?? reason;
        _clearScheduledRefetchFlags();

        if (includeRegistrationState && sessionId != null) {
          host.ref.invalidate(registrationStateProvider(sessionId));
        }

        unawaited(
          refetchCanonical(
            reason: debounceReason,
            wallet: includeWallet,
            includeCalledNumbers: includeCalledNumbers,
            includeMyCartelas: includeMyCartelas,
          ),
        );
      },
    );
  }

  void requestTerminalCanonicalRefetch({
    required String reason,
    bool wallet = false,
    String? registrationSessionId,
    bool includeCalledNumbers = true,
    bool includeMyCartelas = false,
  }) {
    if (!host.isLiveHostActive) {
      return;
    }

    final mergedWallet = wallet || scheduledIncludeWallet;
    final mergedIncludeCalledNumbers =
        includeCalledNumbers || scheduledIncludeCalledNumbers;
    final mergedIncludeMyCartelas =
        includeMyCartelas || scheduledIncludeMyCartelas;
    final mergedRegistrationSessionId =
        registrationSessionId ?? scheduledRegistrationSessionId;
    cancelCanonicalRefetchDebounce();

    final now = host.countdownNow();
    final inCoalesceWindow =
        lastTerminalCanonicalRefetchRequestedAt != null &&
        now.difference(lastTerminalCanonicalRefetchRequestedAt!) <
            _terminalCanonicalRefetchCoalesceWindow;
    final refetchActive =
        canonicalRefetchInFlight || refetchCanonicalLoop != null;

    if (inCoalesceWindow && refetchActive) {
      pendingRefetchWallet = pendingRefetchWallet || mergedWallet;
      pendingRefetchIncludeCalledNumbers =
          pendingRefetchIncludeCalledNumbers || mergedIncludeCalledNumbers;
      pendingRefetchIncludeMyCartelas =
          pendingRefetchIncludeMyCartelas || mergedIncludeMyCartelas;
      LiveRealtimeDebug.refreshCoalesced(reason: reason);
      return;
    }

    lastTerminalCanonicalRefetchRequestedAt = now;
    LiveRealtimeDebug.refreshRequested(reason: reason, terminal: true);
    unawaited(
      refetchCanonicalImmediate(
        reason: reason,
        wallet: mergedWallet,
        registrationSessionId: mergedRegistrationSessionId,
        includeCalledNumbers: mergedIncludeCalledNumbers,
        includeMyCartelas: mergedIncludeMyCartelas,
      ),
    );
  }

  Future<void> refetchCanonicalImmediate({
    required String reason,
    bool wallet = false,
    String? registrationSessionId,
    bool includeCalledNumbers = true,
    bool includeMyCartelas = false,
  }) async {
    cancelCanonicalRefetchDebounce();

    if (registrationSessionId != null) {
      host.ref.invalidate(registrationStateProvider(registrationSessionId));
    }

    await refetchCanonical(
      reason: reason,
      wallet: wallet,
      includeCalledNumbers: includeCalledNumbers,
      includeMyCartelas: includeMyCartelas,
    );
  }

  Future<void> refetchCanonical({
    required String reason,
    bool wallet = false,
    bool includeCalledNumbers = false,
    bool includeMyCartelas = false,
  }) async {
    if (!host.isLiveHostActive) {
      return;
    }

    pendingRefetchWallet = pendingRefetchWallet || wallet;
    pendingRefetchIncludeCalledNumbers =
        pendingRefetchIncludeCalledNumbers || includeCalledNumbers;
    pendingRefetchIncludeMyCartelas =
        pendingRefetchIncludeMyCartelas || includeMyCartelas;
    pendingRefetchReason = pendingRefetchReason ?? reason;

    if (refetchCanonicalLoop != null) {
      return refetchCanonicalLoop!;
    }

    refetchCanonicalLoop = drainRefetchCanonicalQueue();
    try {
      await refetchCanonicalLoop!;
    } finally {
      refetchCanonicalLoop = null;
    }
  }

  Future<void> syncLatest({required String reason}) async {
    if (!host.isLiveHostActive) {
      return;
    }

    final trigger = liveSyncTriggerFromResumeReason(reason);
    if (!shouldRunResumeSync(
      trigger: trigger,
      postGameSummaryReviewActive:
          host.controllers.review.postGameSummaryReviewActive,
      postGameSummaryAdvancing:
          host.controllers.review.postGameSummaryAdvancing,
      terminalCanonicalRefetchInFlight: host.isTerminalTransitionActive,
    )) {
      LiveRealtimeDebug.resumeSyncIgnored(reason: '${reason}_terminal_active');
      return;
    }

    // Flaky-mobile reconnect throttle: if the socket is already back and we
    // applied canonical truth in the last couple of seconds, a reconnect fetch
    // is redundant. Membership rejoin + live events (run before this) keep us
    // current. Manual refresh is never throttled here.
    if (trigger == LiveSyncTrigger.socketReconnect) {
      if (!host.initialLoadComplete) {
        LiveRealtimeDebug.resumeSyncIgnored(reason: '${reason}_initial_load');
        return;
      }
      if (socketService.isConnected &&
          !resumeSyncInFlight &&
          !ResumeSyncGuard.inFlight &&
          _lastSuccessfulSyncAt != null &&
          DateTime.now().difference(_lastSuccessfulSyncAt!) <
              _reconnectSyncThrottle) {
        LiveRealtimeDebug.resumeSyncIgnored(reason: '${reason}_recently_synced');
        return;
      }
    }

    if (trigger == LiveSyncTrigger.appResume &&
        host.initialLoadComplete &&
        host.game != null &&
        socketService.isConnected &&
        _lastSuccessfulSyncAt != null &&
        DateTime.now().difference(_lastSuccessfulSyncAt!) <
            _recentSyncSkipWindow) {
      LiveRealtimeDebug.resumeSyncIgnored(reason: '${reason}_recently_synced');
      return;
    }

    if (ResumeSyncGuard.inFlight || resumeSyncInFlight) {
      _collectedResumeReasons.add(reason);
      LiveRealtimeDebug.resumeSyncIgnored(
        reason: '${reason}_coalesced_in_flight',
      );
      return _resumeSyncCompleter?.future ?? Future<void>.value();
    }

    _collectedResumeReasons.add(reason);
    _resumeSyncCompleter ??= Completer<void>();
    _prepareSyncUi(reason: reason);

    if (_usesResumeDebounce(reason)) {
      resumeSyncDebounceTimer?.cancel();
      resumeSyncDebounceTimer = Timer(_resumeSyncDebounce, () {
        unawaited(_runCoalescedResumeSync());
      });
    } else {
      resumeSyncDebounceTimer?.cancel();
      resumeSyncDebounceTimer = null;
      unawaited(_runCoalescedResumeSync());
    }

    LiveRealtimeDebug.resumeSyncScheduled(
      reason: reason,
      collectedReasons: _collectedResumeReasons.toList(growable: false),
    );

    return _resumeSyncCompleter!.future;
  }

  /// Records that canonical backend truth was just applied to the UI. Feeds the
  /// reconnect throttle so a socket `connect` immediately after an initial load
  /// or refetch does not trigger a redundant full fetch.
  void markCanonicalApplied() {
    _lastSuccessfulSyncAt = DateTime.now();
  }

  Future<void> _runCoalescedResumeSync() async {
    resumeSyncDebounceTimer = null;
    if (!host.isLiveHostActive) {
      _clearSyncUi(showCurrent: false);
      _finishResumeSyncCompleter();
      return;
    }

    if (resumeSyncInFlight) {
      _clearSyncUi(showCurrent: false);
      _finishResumeSyncCompleter();
      return;
    }

    final reason = _formatCollectedSyncReasons();
    final requireNetworkOperations = _collectedResumeReasons.contains(
      'manual_refresh',
    );
    _collectedResumeReasons.clear();
    resumeSyncInFlight = true;
    ResumeSyncGuard.inFlight = true;

    LiveRealtimeDebug.resumeSyncStarted(reason: reason);
    host.controllers.countdown.serverClockSnapOnNextSync = true;

    host.ref
        .read(currentGameOperationsProvider.notifier)
        .suppressAutoRefreshUntil(
          DateTime.now().add(_resumeSyncDebounce + const Duration(seconds: 2)),
        );

    canonicalRefetchInFlight = true;

    try {
      await host.runResumeSync(
        allowCachedOperations: !requireNetworkOperations,
      );

      if (!host.isGuest &&
          shouldInvalidateWalletOnResume(
            game: host.game,
            operations: host.lastOperations,
          ) &&
          ResumeAuxiliaryRefreshGate.shouldRunWalletRegistration(
            syncReason: reason,
            force: requireNetworkOperations,
          )) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!host.isLiveHostActive) {
            return;
          }
          host.ref.invalidate(myWalletProvider);
          LiveRealtimeDebug.resumeSyncWalletLoaded();
          LiveRealtimeDebug.providerInvalidated(
            provider: 'myWallet',
            reason: 'resume_sync',
          );
        });
      } else if (!host.isGuest) {
        LiveRealtimeDebug.providerInvalidateSkipped(
          provider: 'myWallet',
          reason: 'resume_sync_not_registration',
        );
      }

      LiveRealtimeDebug.resumeSyncCompleted(
        reason: reason,
        primaryStatus: host.game?.status.name,
        liveStatus: host.lastOperations?.liveGame?.status.name,
        registrationStatus:
            host.lastOperations?.registrationOpenGame?.status.name,
      );
      _clearSyncUi(showCurrent: true);
    } catch (error) {
      LiveRealtimeDebug.resumeSyncFailed(reason: reason, error: error);
      _handleSyncFailure();
    } finally {
      resumeSyncInFlight = false;
      ResumeSyncGuard.inFlight = false;
      final refetchIndicatorWasVisible = canonicalRefetchInFlight;
      canonicalRefetchInFlight = false;
      if (refetchIndicatorWasVisible && host.isLiveHostActive) {
        host.markNeedsBuild();
      }
      _finishResumeSyncCompleter();
    }
  }

  void _finishResumeSyncCompleter() {
    final completer = _resumeSyncCompleter;
    _resumeSyncCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  String _formatCollectedSyncReasons() {
    if (_collectedResumeReasons.isEmpty) {
      return 'resume';
    }

    final reasons = _collectedResumeReasons.toList()..sort();
    return reasons.join('+');
  }

  void onSocketConnectivityChanged() {
    if (!host.isLiveHostActive) {
      return;
    }
    host.markNeedsBuild();
  }

  bool get _syncScheduled =>
      resumeSyncDebounceTimer != null ||
      (_resumeSyncCompleter != null && !resumeSyncInFlight);

  bool get _isReconnectStyleSync {
    final reason = _activeSyncReason;
    if (reason == null) {
      return !socketService.isConnected;
    }
    return reason.contains('socket_reconnect') || !socketService.isConnected;
  }

  bool _usesResumeDebounce(String reason) {
    return reason == 'app_resume' || reason == 'socket_reconnect';
  }

  void _prepareSyncUi({required String reason}) {
    _activeSyncReason = reason;
    _lastSyncFailed = false;
    _syncOverlayVisible = false;
    _currentBadgeTimer?.cancel();
    _syncOverlayTimer?.cancel();
    final overlayDelay = reason == 'manual_refresh'
        ? _syncOverlayDelayManual
        : _syncOverlayDelayBackground;
    _syncOverlayTimer = Timer(overlayDelay, () {
      if (!host.isLiveHostActive || !(_syncScheduled || resumeSyncInFlight)) {
        return;
      }
      // Skip overlay when painted game is already on screen for background sync.
      if (_usesResumeDebounce(reason) &&
          host.initialLoadComplete &&
          host.game != null) {
        return;
      }
      _syncOverlayVisible = true;
      host.markNeedsBuild();
    });
    host.markNeedsBuild();
  }

  void _clearSyncUi({required bool showCurrent}) {
    _syncOverlayTimer?.cancel();
    _syncOverlayVisible = false;
    _activeSyncReason = null;
    if (showCurrent) {
      _lastSyncFailed = false;
      _lastSuccessfulSyncAt = DateTime.now();
      _currentBadgeTimer?.cancel();
      _currentBadgeTimer = Timer(_currentBadgeDuration, () {
        if (host.isLiveHostActive) {
          host.markNeedsBuild();
        }
      });
    }
    if (host.isLiveHostActive) {
      host.markNeedsBuild();
    }
  }

  void _handleSyncFailure() {
    _syncOverlayTimer?.cancel();
    _syncOverlayVisible = true;
    _activeSyncReason = null;
    _lastSyncFailed = true;
    _currentBadgeTimer?.cancel();
    _showFailureSnackBar();
    if (host.isLiveHostActive) {
      host.markNeedsBuild();
    }
  }

  void _showFailureSnackBar() {
    if (!host.isLiveHostActive) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(host.context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Connection issue. Tap refresh.')),
      );
  }

  LiveConnectionState _resolveConnectionState() {
    final baseState = _resolveBaseSocketState();
    if (_syncScheduled || resumeSyncInFlight) {
      return _isReconnectStyleSync
          ? LiveConnectionState.reconnecting
          : LiveConnectionState.syncing;
    }
    if (baseState != LiveConnectionState.online) {
      return baseState;
    }
    if (_lastSyncFailed) {
      return LiveConnectionState.error;
    }
    final lastSuccessfulSyncAt = _lastSuccessfulSyncAt;
    if (lastSuccessfulSyncAt != null &&
        DateTime.now().difference(lastSuccessfulSyncAt) <
            _currentBadgeDuration) {
      return LiveConnectionState.current;
    }
    return LiveConnectionState.online;
  }

  LiveConnectionState _resolveBaseSocketState() {
    if (socketService.isConnected) {
      return LiveConnectionState.online;
    }
    if (socketService.hasActiveSocket) {
      return LiveConnectionState.reconnecting;
    }
    return LiveConnectionState.offline;
  }

  Future<void> drainRefetchCanonicalQueue() async {
    while (host.isLiveHostActive) {
      final wallet = pendingRefetchWallet;
      final includeCalledNumbers = pendingRefetchIncludeCalledNumbers;
      final includeMyCartelas = pendingRefetchIncludeMyCartelas;
      final reason = pendingRefetchReason ?? 'canonical';
      pendingRefetchWallet = false;
      pendingRefetchIncludeCalledNumbers = false;
      pendingRefetchIncludeMyCartelas = false;
      pendingRefetchReason = null;

      LiveRealtimeDebug.refreshStarted(
        reason: reason,
        status: host.game?.status.name,
        calledCount: host.game?.calledNumbersCount,
        includeCalledNumbers: includeCalledNumbers,
        includeMyCartelas: includeMyCartelas,
        wallet: wallet,
      );

      if (wallet) {
        host.ref.invalidate(myWalletProvider);
      }

      host.markNeedsBuild(() => canonicalRefetchInFlight = true);

      try {
        await host.runInitialLoad(
          showLoading: false,
          includeCalledNumbers: includeCalledNumbers,
          includeMyCartelas: includeMyCartelas,
        );
        LiveRealtimeDebug.refreshApplied(
          reason: reason,
          status: host.game?.status.name,
          calledCount: host.game?.calledNumbersCount,
        );
      } catch (error, stackTrace) {
        LiveRealtimeDebug.refreshFailed(reason: reason, error: error);
        Error.throwWithStackTrace(error, stackTrace);
      } finally {
        if (host.isLiveHostActive) {
          host.markNeedsBuild(() => canonicalRefetchInFlight = false);
        }
      }

      if (!pendingRefetchWallet &&
          !pendingRefetchIncludeCalledNumbers &&
          !pendingRefetchIncludeMyCartelas) {
        break;
      }
    }
  }

  void _clearScheduledRefetchFlags() {
    scheduledIncludeWallet = false;
    scheduledIncludeRegistrationState = false;
    scheduledIncludeCalledNumbers = false;
    scheduledIncludeMyCartelas = false;
    scheduledRegistrationSessionId = null;
    scheduledRefetchReason = null;
  }

  bool eventAffectsCurrentGame({String? sessionId, String? slotId}) {
    final game = host.game;
    if (game == null) {
      return false;
    }
    if (sessionId != null &&
        sessionId.isNotEmpty &&
        game.sessionId == sessionId) {
      return true;
    }
    if (slotId != null && slotId.isNotEmpty && game.id == slotId) {
      return true;
    }
    return false;
  }

  bool eventAffectsRegistrationSession({String? sessionId, String? slotId}) {
    final tracked = host.controllers.registration.trackedRegistrationSessionId;
    if (sessionId != null &&
        tracked != null &&
        sessionId.isNotEmpty &&
        tracked == sessionId) {
      return true;
    }
    final registration = host.lastOperations?.registrationOpenGame;
    if (sessionId != null &&
        registration?.sessionId != null &&
        registration!.sessionId == sessionId) {
      return true;
    }
    if (slotId != null && registration != null && registration.id == slotId) {
      return true;
    }
    return false;
  }
}
