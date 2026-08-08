part of 'live_game_screen.dart';

void _socketDebugLog(String message) {
  if (kDebugMode) {
    debugPrint('[bulk_debug] $message');
  }
}

mixin _LiveGameRealtime on _LiveGameOrchestration {
  void _registerSocketListeners() {
    if (_listenersRegistered) {
      return;
    }
    _socketService.on('connect', _onSocketConnected);
    _socketService.on('disconnect', _onSocketDisconnected);
    _socketService.on('connect_error', _onSocketConnectError);
    _socketService.on('game:status_changed', _onGameStatusChanged);
    _socketService.on('slot:created', _onSlotCreated);
    _socketService.on('slot:status_changed', _onSlotStatusChanged);
    _socketService.on('game:number_called', _onNumberCalled);
    _socketService.on('game:bingo_checking', _onBingoChecking);
    _socketService.on('game:bingo_claimed', _onBingoClaimed);
    _socketService.on('game:bingo_valid', _onBingoValid);
    _socketService.on('game:bingo_invalid', _onBingoInvalid);
    _socketService.on('game:winner_window_started', _onWinnerWindowEvent);
    _socketService.on('game:winner_window_joined', _onWinnerWindowEvent);
    _socketService.on('game:finished', _onGameFinished);
    _socketService.on('game:cancelled', _onGameCancelled);
    _socketService.on('session:prize_updated', _onSessionPrizeUpdated);
    _socketService.on('session:cartelas_updated', _onSessionCartelasUpdated);
    _socketService.on('my_cartela:registered', _onMyCartelaRegistered);
    _socketService.on('wallet:updated', _onWalletUpdated);
    _socketService.on('game:operation_updated', _onGameOperationUpdated);
    _socketService.on('slot:entry_fee_updated', _onSlotEntryFeeUpdated);
    _listenersRegistered = true;
  }

  void _removeSocketListeners() {
    if (!_listenersRegistered) {
      return;
    }
    _socketService.off('connect', _onSocketConnected);
    _socketService.off('disconnect', _onSocketDisconnected);
    _socketService.off('connect_error', _onSocketConnectError);
    _socketService.off('game:status_changed', _onGameStatusChanged);
    _socketService.off('slot:created', _onSlotCreated);
    _socketService.off('slot:status_changed', _onSlotStatusChanged);
    _socketService.off('game:number_called', _onNumberCalled);
    _socketService.off('game:bingo_checking', _onBingoChecking);
    _socketService.off('game:bingo_claimed', _onBingoClaimed);
    _socketService.off('game:bingo_valid', _onBingoValid);
    _socketService.off('game:bingo_invalid', _onBingoInvalid);
    _socketService.off('game:winner_window_started', _onWinnerWindowEvent);
    _socketService.off('game:winner_window_joined', _onWinnerWindowEvent);
    _socketService.off('game:finished', _onGameFinished);
    _socketService.off('game:cancelled', _onGameCancelled);
    _socketService.off('session:prize_updated', _onSessionPrizeUpdated);
    _socketService.off('session:cartelas_updated', _onSessionCartelasUpdated);
    _socketService.off('my_cartela:registered', _onMyCartelaRegistered);
    _socketService.off('wallet:updated', _onWalletUpdated);
    _socketService.off('game:operation_updated', _onGameOperationUpdated);
    _socketService.off('slot:entry_fee_updated', _onSlotEntryFeeUpdated);
    _listenersRegistered = false;
  }

  void _onSocketConnected(dynamic _) {
    if (!isLiveHostActive) {
      return;
    }

    LiveRealtimeDebug.socket('connect');

    _stopDisconnectedCalledNumbersPolling();

    final joinedGameId = _joinedGameId;
    if (joinedGameId != null) {
      _applySocketSessionMembership(joinedGameId);
    }

    _realtime.onSocketConnectivityChanged();
    unawaited(_realtime.syncLatest(reason: 'socket_reconnect'));
    _evaluateLiveRoomSplash();
  }

  Future<void> _recoverFromAppResume() async {
    if (!isLiveHostActive) {
      return;
    }

    final resumeDecision = AppBackgroundResumeGate.evaluateFullResumeSync(
      socketConnectedNow: _socketService.isConnected,
    );

    _countdown.resumeFromAppBackground();
    if (!isLiveHostActive) {
      return;
    }
    _syncWinnerWindowTicker();
    _syncNextBallCountdownTicker();

    if (!resumeDecision.shouldRunFullResumeSync) {
      LiveRealtimeDebug.resumeSyncIgnored(reason: resumeDecision.reason);
      return;
    }

    await _realtime.syncLatest(reason: 'app_resume');
  }

  Future<void> _refresh() async {
    await _realtime.syncLatest(reason: 'manual_refresh');
  }

  void _onSocketDisconnected(dynamic _) {
    LiveRealtimeDebug.socket('disconnect');
    AppBackgroundResumeGate.onSocketDisconnected();
    _realtime.onSocketConnectivityChanged();
    _startDisconnectedCalledNumbersPolling();
  }

  void _onSocketConnectError(dynamic error) {
    LiveRealtimeDebug.socket('connect_error', {
      if (error != null) 'error': error.toString(),
    });
    AppBackgroundResumeGate.onSocketDisconnected();
    _realtime.onSocketConnectivityChanged();
    _startDisconnectedCalledNumbersPolling();
  }

  void _startDisconnectedCalledNumbersPolling() {
    _cn.startDisconnectedPolling(
      isSocketConnected: () => _socketService.isConnected,
    );
  }

  void _stopDisconnectedCalledNumbersPolling() {
    _cn.stopDisconnectedPolling();
  }

  void _onGameStatusChanged(dynamic payload) {
    if (!isLiveHostActive) {
      return;
    }

    final normalizedPayload = _normalizeSocketPayloadForEvent(
      payload,
      eventName: 'game:status_changed',
      includeCalledNumbers: true,
    );
    if (normalizedPayload == null) {
      return;
    }

    if (shouldWakeEmptyLiveBoard(
      game: _game,
      trackedRegistrationSessionId: _trackedRegistrationSessionId,
    )) {
      _scheduleCanonicalRefetch(reason: 'empty_board_queue_wakeup');
      return;
    }

    final sessionId =
        normalizedPayload['sessionId'] as String? ??
        normalizedPayload['id'] as String?;
    final slotId =
        normalizedPayload['gameSlotId'] as String? ??
        normalizedPayload['slotId'] as String?;
    if (_shouldSyncMissedPreviewForForeignSession(sessionId)) {
      MissedPreviewDebug.foreignEvent(
        event: 'game:status_changed',
        eventSessionId: sessionId,
        primarySessionId: _game?.sessionId,
        willSync: true,
      );
      controllers.missedPreview.onForeignPhaseEvent(
        reason: 'missed_preview_status_changed',
      );
      return;
    }
    final affectsCurrent = _eventAffectsCurrentGame(
      sessionId: sessionId,
      slotId: slotId,
    );
    final affectsRegistration = _eventAffectsRegistrationSession(
      sessionId: sessionId,
      slotId: slotId,
    );
    if (!affectsCurrent && !affectsRegistration) {
      return;
    }

    LiveRealtimeDebug.socket('game:status_changed', normalizedPayload);

    if (affectsRegistration && !affectsCurrent) {
      _scheduleCanonicalRefetch(registrationSessionId: sessionId);
      return;
    }

    final status = normalizedPayload['status'] as String?;
    final isTerminal =
        status == 'FINISHED' || status == 'NO_WINNER' || status == 'CANCELLED';

    final action = resolveLiveSyncTriggerAction(
      LiveSyncTrigger.statusChanged,
      isTerminalStatus: isTerminal,
    );

    if (action == LiveSyncAction.terminalTransitionSnapshot) {
      _realtime.requestTerminalCanonicalRefetch(
        reason: 'status_changed_terminal',
        wallet: !isGuest,
        registrationSessionId: _game?.sessionId,
        includeCalledNumbers: true,
        includeMyCartelas: false,
      );
      return;
    }

    final priorStatus = _game?.status;
    final ownsEventSession = ownsSessionByCartelas(
      sessionId,
      _ownershipCartelaSessionIds,
    );
    if (shouldSkipOptimisticPlayingPatchForNonOwner(
      incomingStatus: status,
      priorPrimaryStatus: priorStatus,
      ownsEventSessionByCartelas: ownsEventSession,
    )) {
      MissedPreviewDebug.log(
        'skip_optimistic_playing session=${sessionId ?? '-'} '
        'prior=${priorStatus?.name ?? '-'} → canonical missed entry',
      );
      unawaited(
        _refetchCanonicalImmediate(
          reason: 'status_changed_non_owner_enter_missed',
          includeCalledNumbers: true,
          includeMyCartelas: !isGuest,
        ),
      );
      return;
    }

    final patched = applyStatusChangedSocketPatch(
      current: _game,
      payload: normalizedPayload,
    );
    if (patched != null) {
      markNeedsBuild(() {
        _game = patched;
        _countdown.onNextBallScheduleChanged(
          game: patched,
          nextAutoCallAt: patched.nextAutoCallAt,
          scheduleChanged: true,
        );
        if (patched.status == GameStatus.winnerWindow) {
          _countdown.winnerWindowEndsAt = patched.winnerWindowEndsAt;
        }
      });
      if (patched.status == GameStatus.playing &&
          (priorStatus == GameStatus.ready ||
              priorStatus == GameStatus.next)) {
        _playGameSound(SoundEvent.gameStart, sessionId: patched.sessionId);
      }
      if (patched.status == GameStatus.winnerWindow) {
        _playGameSound(SoundEvent.winnerWindow, sessionId: patched.sessionId);
      }
      if (patched.status == GameStatus.winnerWindow ||
          patched.status == GameStatus.finished ||
          patched.status == GameStatus.noWinner) {
        _refreshLocalOperationsSnapshotIfNeeded();
      }
      markCanonicalSocketStateApplied();
      _syncWinnerWindowTicker();
      _syncNextBallCountdownTicker();
    }

    _scheduleCanonicalRefetch(
      reason: 'status_changed_metrics',
      registrationSessionId: sessionId,
      includeCalledNumbers: false,
    );
  }

  void _onSlotCreated(dynamic payload) {
    if (!isLiveHostActive) {
      return;
    }

    final normalizedPayload = _normalizeSocketPayloadForEvent(
      payload,
      eventName: 'slot:created',
    );
    if (normalizedPayload == null) {
      return;
    }

    LiveRealtimeDebug.socket('slot:created', normalizedPayload);
    _scheduleCanonicalRefetch(reason: 'slot_created');
  }

  void _onSlotStatusChanged(dynamic payload) {
    if (!isLiveHostActive) {
      return;
    }

    final normalizedPayload = _normalizeSocketPayloadForEvent(
      payload,
      eventName: 'slot:status_changed',
    );
    if (normalizedPayload == null) {
      return;
    }

    final slotId =
        normalizedPayload['id'] as String? ??
        normalizedPayload['slotId'] as String?;
    final sessionId = normalizedPayload['sessionId'] as String?;
    if (!_eventAffectsCurrentGame(sessionId: sessionId, slotId: slotId)) {
      return;
    }

    _refetchRegistrationDeadlineImmediately();
  }

  void _onSessionPrizeUpdated(dynamic payload) {
    if (!isLiveHostActive) {
      return;
    }

    final normalizedPayload = _normalizeSocketPayloadForEvent(
      payload,
      eventName: 'session:prize_updated',
      preferRegistrationSessionRefetch: true,
    );
    if (normalizedPayload == null) {
      return;
    }

    final sessionId =
        normalizedPayload['sessionId'] as String? ??
        normalizedPayload['id'] as String?;
    if (!_eventAffectsRegistrationSession(sessionId: sessionId, slotId: null)) {
      return;
    }

    _applyRegistrationMetricsPayload(normalizedPayload, sessionId: sessionId);
  }

  void _onSessionCartelasUpdated(dynamic payload) {
    if (!isLiveHostActive) {
      return;
    }

    final normalizedPayload = _normalizeSocketPayloadForEvent(
      payload,
      eventName: 'session:cartelas_updated',
      preferRegistrationSessionRefetch: true,
    );
    if (normalizedPayload == null) {
      return;
    }

    final sessionId = normalizedPayload['sessionId'] as String?;
    final slotId = normalizedPayload['slotId'] as String?;
    if (!_eventAffectsRegistrationSession(
      sessionId: sessionId,
      slotId: slotId,
    )) {
      return;
    }

    final parsed = parseAndValidateRegistrationCartelaChanges(
      normalizedPayload['changes'],
      currentUserId: ref.read(authControllerProvider).session?.user.id,
    );

    // Debug log #10: Socket cartelas_updated
    if (parsed.valid.isNotEmpty) {
      for (final change in parsed.valid) {
        _socketDebugLog(
          'socket_cartelas_updated cartela=${change.cartelaNumber} state=${change.owner} session=$sessionId',
        );
      }
    }

    if (sessionId != null && parsed.valid.isNotEmpty) {
      ref
          .read(registrationStatePatchProvider.notifier)
          .applyConfirmedChanges(sessionId, parsed.valid);
      RegistrationUxMetrics.socketPatchApplied(
        changeCount: parsed.valid.length,
      );
    }

    _applyRegistrationMetricsPayload(normalizedPayload, sessionId: sessionId);

    if (parsed.valid.isEmpty || parsed.hasMalformed) {
      RegistrationUxMetrics.snapshotRefetchScheduled(
        reason: parsed.valid.isEmpty ? 'empty_changes' : 'malformed_changes',
      );
      _scheduleCanonicalRefetch(registrationSessionId: sessionId);
    }
  }

  void _onMyCartelaRegistered(dynamic payload) {
    if (!isLiveHostActive) {
      return;
    }

    final normalizedPayload = _normalizeSocketPayloadForEvent(
      payload,
      eventName: 'my_cartela:registered',
      wallet: !isGuest,
      preferRegistrationSessionRefetch: true,
    );
    if (normalizedPayload == null) {
      return;
    }

    final sessionId = normalizedPayload['sessionId'] as String?;
    if (!_eventAffectsRegistrationSession(sessionId: sessionId, slotId: null)) {
      return;
    }

    _applyRegistrationMetricsPayload(normalizedPayload, sessionId: sessionId);
    ref.invalidate(myWalletProvider);
    if (sessionId != null) {
      ref.invalidate(registrationStateProvider(sessionId));
    }
    if (sessionId != null && sessionId == _game?.sessionId) {
      unawaited(_refreshMyCartelasSilently());
    } else if (sessionId != null &&
        sessionId == _trackedRegistrationSessionId) {
      unawaited(_refreshNextRegistrationCartelasSilently());
    }
  }

  void _refetchRegistrationDeadlineImmediately({bool wallet = false}) {
    unawaited(
      _refetchCanonicalImmediate(
        wallet: wallet,
        registrationSessionId:
            _game?.sessionId ?? _trackedRegistrationSessionId,
      ),
    );
  }

  void _onGameOperationUpdated(dynamic payload) {
    if (!isLiveHostActive) {
      return;
    }

    final normalizedPayload = _normalizeSocketPayloadForEvent(
      payload,
      eventName: 'game:operation_updated',
    );
    if (normalizedPayload == null) {
      return;
    }

    final action = resolveLiveSyncTriggerAction(
      LiveSyncTrigger.operationUpdated,
      updatedReason: normalizedPayload['updatedReason'] as String?,
    );

    switch (action) {
      case LiveSyncAction.ignore:
        return;
      case LiveSyncAction.localPatchOnly:
        final sessionId = normalizedPayload['sessionId'] as String?;
        final slotId = normalizedPayload['slotId'] as String?;
        if (_eventAffectsCurrentGame(sessionId: sessionId, slotId: slotId)) {
          LiveRealtimeDebug.socket('game:operation_updated', normalizedPayload);
          _applyAutoCallScheduleFromPayload(normalizedPayload);
        }
        return;
      case LiveSyncAction.canonicalSnapshotFetch:
        if (shouldWakeEmptyLiveBoard(
          game: _game,
          trackedRegistrationSessionId: _trackedRegistrationSessionId,
        )) {
          _scheduleCanonicalRefetch(reason: 'empty_board_queue_wakeup');
          return;
        }
        final sessionId = normalizedPayload['sessionId'] as String?;
        final slotId = normalizedPayload['slotId'] as String?;
        final affectsCurrent = _eventAffectsCurrentGame(
          sessionId: sessionId,
          slotId: slotId,
        );
        final affectsRegistration = _eventAffectsRegistrationSession(
          sessionId: sessionId,
          slotId: slotId,
        );
        if (!affectsCurrent && !affectsRegistration) {
          if (_shouldSyncMissedPreviewForForeignSession(sessionId)) {
            controllers.missedPreview.onForeignPhaseEvent(
              reason: 'missed_preview_operation_updated',
            );
          }
          return;
        }
        if (affectsRegistration && !affectsCurrent) {
          _scheduleCanonicalRefetch(
            reason: 'operation_updated_registration',
            registrationSessionId: sessionId,
          );
          return;
        }
        _scheduleCanonicalRefetch(reason: 'operation_updated');
        return;
      case LiveSyncAction.calledNumbersFetchOnly:
      case LiveSyncAction.terminalTransitionSnapshot:
        // Not used for operation_updated in Plan 2 matrix.
        return;
    }
  }

  void _onSlotEntryFeeUpdated(dynamic payload) {
    if (!isLiveHostActive) {
      return;
    }

    final normalizedPayload = _normalizeSocketPayloadForEvent(
      payload,
      eventName: 'slot:entry_fee_updated',
    );
    if (normalizedPayload == null) {
      return;
    }

    final slotId = normalizedPayload['id'] as String?;
    if (!_eventAffectsCurrentGame(slotId: slotId)) {
      return;
    }

    _scheduleCanonicalRefetch();
  }

  /// Phase B2: Apply registration metrics from socket events for immediate UI feedback.
  ///
  /// IMPORTANT: These updates are TEMPORARY optimistic UI only.
  /// The next canonical refresh from operations/current will ALWAYS overwrite
  /// these values with the backend truth via mergeCanonicalSessionState.
  ///
  /// Architecture:
  /// - Socket patch → immediate visual update (this method)
  /// - operations/current → permanent truth (overwrites socket values)
  ///
  /// Session guard: Only updates the current visible session or the tracked
  /// READY registration session. This never mutates status, queue order, or
  /// registration target identity.
  bool _applyRegistrationMetricsPayload(
    Map<String, dynamic> payload, {
    String? sessionId,
  }) {
    final targetSessionId =
        sessionId ??
        payload['sessionId'] as String? ??
        payload['id'] as String?;

    if (_readyTransitionLockActive) {
      final lockSessionId = _transition.readyTransitionLock!.sessionId;
      if (targetSessionId != null &&
          targetSessionId != lockSessionId &&
          _game?.sessionId == lockSessionId) {
        final patchedTrackedRegistrationGame = applySocketRegistrationMetricsPatch(
          game: _nextUpcomingGame,
          targetSessionId: targetSessionId,
          prizeAmount: payload['prizeAmount'] as String?,
          registeredCartelasCount: _parsePayloadInt(
            payload['registeredCartelasCount'],
          ),
          requireReadyRegistrationTarget: true,
        );
        if (patchedTrackedRegistrationGame != _nextUpcomingGame) {
          setState(() {
            _nextUpcomingGame = patchedTrackedRegistrationGame;
          });
          markCanonicalSocketStateApplied();
          return true;
        }
        return false;
      }
    }

    final prizeAmount = payload['prizeAmount'] as String?;
    final registeredCartelasCount = _parsePayloadInt(
      payload['registeredCartelasCount'],
    );

    final patchedCurrentGame = applySocketRegistrationMetricsPatch(
      game: _game,
      targetSessionId: targetSessionId,
      prizeAmount: prizeAmount,
      registeredCartelasCount: registeredCartelasCount,
    );
    final patchedTrackedRegistrationGame = applySocketRegistrationMetricsPatch(
      game: _nextUpcomingGame,
      targetSessionId: targetSessionId,
      prizeAmount: prizeAmount,
      registeredCartelasCount: registeredCartelasCount,
      requireReadyRegistrationTarget: true,
    );

    if (patchedCurrentGame == _game &&
        patchedTrackedRegistrationGame == _nextUpcomingGame) {
      return false;
    }

    setState(() {
      _game = patchedCurrentGame;
      _nextUpcomingGame = patchedTrackedRegistrationGame;
    });
    markCanonicalSocketStateApplied();
    return true;
  }

  int? _parsePayloadInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw);
    }
    return null;
  }
}

({Color background, Color foreground}) _cartelaStatusColors(
  ThemeData theme,
  GameCartelaStatus status,
) {
  return switch (status) {
    GameCartelaStatus.registered => (
      background: theme.colorScheme.surfaceContainerHighest,
      foreground: theme.colorScheme.onSurface,
    ),
    GameCartelaStatus.winner => (
      background: Colors.amber.shade100,
      foreground: Colors.amber.shade900,
    ),
    GameCartelaStatus.blocked => (
      background: theme.colorScheme.errorContainer,
      foreground: theme.colorScheme.onErrorContainer,
    ),
    GameCartelaStatus.cancelled => (
      background: theme.colorScheme.surfaceContainerHighest,
      foreground: theme.colorScheme.onSurface,
    ),
  };
}
