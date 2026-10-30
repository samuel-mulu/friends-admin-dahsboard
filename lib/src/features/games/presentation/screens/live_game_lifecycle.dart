part of 'live_game_screen.dart';

/// App lifecycle observer and feature setting listener handlers.
mixin _LiveGameLifecycle on _LiveGameOrchestration, _LiveGameRealtime {
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
        refreshCartelaSortAfterCalledNumbers();
        if (nextAutoMark) {
          refreshCartelaLivePresentation(fullGrid: true);
        }
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
}
