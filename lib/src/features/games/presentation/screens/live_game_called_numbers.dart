part of 'live_game_screen.dart';

mixin _LiveGameCalledNumbers on _LiveGameOrchestration {
  bool get _usesSessionWideOutcomeChips {
    final phase = _livePresentationPhase;
    if (phase == LivePresentationPhase.winnerWindow ||
        phase == LivePresentationPhase.review ||
        (_game?.status == GameStatus.winnerWindow && _winnerWindowExpired)) {
      return true;
    }
    if (_review.sessionWinnerCartelaNumbers.isNotEmpty &&
        phase == LivePresentationPhase.checking) {
      return true;
    }
    return false;
  }

  List<int> get _winnerCartelaNumbers {
    return winnerCartelaNumbersForStrip(
      useSessionWideOutcomeChips: _usesSessionWideOutcomeChips,
      sessionWinnerCartelaNumbers: _review.sessionWinnerCartelaNumbers,
      myCartelas: _myCartelas,
    );
  }

  List<int> get _blockedCartelaNumbers {
    return blockedCartelaNumbersForStrip(myCartelas: _myCartelas);
  }

  List<int> get _checkingCartelaNumbers {
    return checkingCartelaNumbersForStrip(
      claimingCartelaIds: _cn.confirmingOrClaimingCartelaIds,
      myCartelas: _myCartelas,
    );
  }

  Widget _buildCalledNumbersPanel() {
    return ValueListenableBuilder<int>(
      valueListenable: _cn.calledNumbersPanelRevision,
      builder: (context, _, _) {
        final l10n = context.l10n;
        final isClaiming = _isAnyClaimChecking;
        final showWinnerOnly = _stripShowsWinnerOnly;
        final checkingCartelaNumbers = showWinnerOnly
            ? const <int>[]
            : _checkingCartelaNumbers;
        final blockedCartelaNumbers = showWinnerOnly
            ? const <int>[]
            : _blockedCartelaNumbers;
        final winnerCartelaNumbers = showWinnerOnly
            ? winnerCartelaNumbersForStrip(
                useSessionWideOutcomeChips: true,
                sessionWinnerCartelaNumbers:
                    _review.sessionWinnerCartelaNumbers,
                myCartelas: _myCartelas,
              )
            : _winnerCartelaNumbers;
        final canOpenWinnerDialog =
            winnerCartelaNumbers.isNotEmpty &&
            _winnerReviewEligibleViewer &&
            _showsPostGameSummary &&
            (_stripShowsWinnerOnly || _usesSessionWideOutcomeChips);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CalledNumbersStrip(
              calledNumbers: _cn.calledNumbers,
              checkingCartelaNumbers: checkingCartelaNumbers,
              winnerCartelaNumbers: winnerCartelaNumbers,
              blockedCartelaNumbers: blockedCartelaNumbers,
              isCheckingClaim: isClaiming,
              isRefreshing: _cn.isRefreshingCalledNumbersPanel,
              connectionState: _realtime.connectionState,
              lockExpanded: false,
              headerLeading: _buildGameInfoStripLeading(context),
              onRefreshCalledNumbers: () {
                _cn.reconcileClaimAttempts();
                unawaited(_realtime.syncLatest(reason: 'manual_refresh'));
              },
              onWinnerCartelaTapped: canOpenWinnerDialog
                  ? (cartelaNumber) =>
                        unawaited(_onWinnerCartelaChipTapped(cartelaNumber))
                  : null,
            ),
            if (isClaiming) ...[
              const SizedBox(height: 6),
              Text(
                l10n.calledNumbersClaimHoldNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (_cn.claimNeedingEscalation case final attempt?)
              _buildClaimEscalationBanner(context, attempt),
          ],
        );
      },
    );
  }

  /// Persistent, non-blocking escalation shown once automatic recovery has
  /// done everything it safely can (same-UUID retry budget exhausted, or no
  /// retry hook configured) and the claim is still unresolved. Unlike the
  /// one-shot SnackBar in [_claimBingo], this stays visible for as long as
  /// the condition holds, so a sustained outage is never silently invisible.
  Widget _buildClaimEscalationBanner(
    BuildContext context,
    BingoClaimAttempt attempt,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Still checking your bingo claim — this is taking longer than '
              'usual. Your claim was not rejected.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              BingoClaimDiagnostics.record(
                event: 'bingo.recovery.start',
                claimAttemptId: attempt.claimAttemptId,
                sessionId: attempt.sessionId,
                cartelaId: attempt.gameCartelaId,
                state: 'manual_recheck_banner',
                retryCount: attempt.sameUuidPostRetries,
              );
              _cn.reconcileClaimAttempts();
            },
            child: const Text('Recheck'),
          ),
          TextButton(
            onPressed: () => unawaited(
              BingoClaimDiagnostics.copyToClipboard(
                claimAttemptId: attempt.claimAttemptId,
              ),
            ),
            child: const Text('Copy log'),
          ),
        ],
      ),
    );
  }

  bool _canClaimBingoForCartela(GameCartelaModel gameCartela) {
    return _cn.canClaimBingoForCartela(
      game: _game,
      gameCartela: gameCartela,
      winnerWindowExpired: _winnerWindowExpired,
      // Lock is applied on the BINGO button via bingoClaimLocked listenable.
      isCountdownLocked: false,
      chainBingoArmedAfterCalledCount: _chainBingoArmedAfterCalledCount,
    );
  }

  String? _blockedReasonCodeForCartela(GameCartelaModel gameCartela) {
    return _cn.blockedReasonCodeFor(gameCartela.id);
  }

  String? _blockedServerReasonForCartela(GameCartelaModel gameCartela) {
    return _cn.blockedServerReasonFor(gameCartela.id);
  }

  Future<void> _claimBingo(GameCartelaModel gameCartela) async {
    final sessionId = _activeSessionId;
    if (sessionId == null || !_canClaimBingoForCartela(gameCartela)) return;
    final startedAt = DateTime.now();
    final attempt = _cn.beginClaimAttempt(
      gameCartelaId: gameCartela.id,
      claimAttemptId: const Uuid().v4(),
      roundIndex: _game?.displayRoundIndex ?? 1,
    );
    if (attempt == null) return;
    BingoClaimDiagnostics.record(
      event: 'bingo.tap',
      claimAttemptId: attempt.claimAttemptId,
      sessionId: sessionId,
      cartelaId: gameCartela.id,
      state: 'claiming',
    );
    final previousSchedule = _game?.nextAutoCallAt;
    _cn.preClaimNextAutoCallAt ??= previousSchedule;
    setState(() {
      if (_isAutoCallActiveForSession && previousSchedule != null) {
        _game = _game?.copyWith(nextAutoCallAt: null);
      }
    });

    // An identity must survive remount before a possibly ambiguous POST is sent.
    try {
      await _cn.persistClaimAttempt(attempt);
    } catch (_) {
      if (_cn.isCurrentClaimAttempt(attempt)) {
        _cn.cancelUnsentClaim(attempt);
        if (mounted && isLiveHostActive) {
          setState(() {
            if (_cn.confirmingOrClaimingCartelaIds.isEmpty) {
              _game = _game?.copyWith(nextAutoCallAt: previousSchedule);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not save your claim. Please try again.'),
          ));
        }
      }
      return;
    }
    if (!_claimCallbackIsCurrent(attempt)) {
      _cn.cancelUnsentClaim(attempt);
      return;
    }
    final requestStartedAt = DateTime.now();
    BingoClaimDiagnostics.record(
      event: 'bingo.post.start',
      claimAttemptId: attempt.claimAttemptId,
      sessionId: sessionId,
      cartelaId: gameCartela.id,
      elapsedMs: requestStartedAt.difference(startedAt).inMilliseconds,
      state: 'post_in_flight',
      retryCount: attempt.sameUuidPostRetries,
    );
    try {
      final result = await _gamesRepository.claimBingo(
        sessionId: sessionId,
        gameCartelaId: gameCartela.id,
        claimAttemptId: attempt.claimAttemptId,
        clientTapAt: startedAt,
      );
      BingoClaimDiagnostics.record(
        event: 'bingo.post.response',
        claimAttemptId: attempt.claimAttemptId,
        sessionId: sessionId,
        cartelaId: gameCartela.id,
        elapsedMs: DateTime.now().difference(requestStartedAt).inMilliseconds,
        claimStatus: result.claim.status.name,
        state: 'http_ok',
      );
      if (!isLiveHostActive) return;
      if (result.claim.claimAttemptId != attempt.claimAttemptId ||
          result.claim.gameCartelaId != attempt.gameCartelaId ||
          result.claim.gameId != attempt.sessionId ||
          result.claim.userId != attempt.userId) {
        throw StateError('Claim response does not match the submitted attempt');
      }
      if (!_claimCallbackIsCurrent(attempt)) {
        // A resolved token may still confirm deferred presentation identity.
        // It cannot reapply business state or change a newer attempt/round.
        if (attempt.terminalStatus == result.claim.status &&
            _cn.claimOutcomeMatchesView(attempt, _game)) {
          attempt.serverClaimId = result.claim.id;
          _flushPendingClaimSocketEvents();
        }
        return;
      }
      attempt.serverClaimId = result.claim.id;
      // A Chain round may have advanced while this HTTP response was in flight.
      if (attempt.roundIndex != _game?.displayRoundIndex) {
        setState(() {
          if (_cn.claimOutcomeMatchesView(attempt, _game)) {
            _cn.resolveTerminalClaim(
              attempt: attempt,
              status: result.claim.status,
              retryAllowed: result.retryAllowed,
              cartelas: _myCartelas,
              reportedCartelaStatus: result.gameCartelaStatus,
              applyCartelas: (next) => _myCartelas = next,
            );
          } else if (result.claim.status.isTerminal) {
            _cn.resolveHistoricalTerminalClaim(
              attempt: attempt,
              status: result.claim.status,
              retryAllowed: result.retryAllowed,
              cartelas: _myCartelas,
              reportedCartelaStatus: result.gameCartelaStatus,
              game: _game,
              applyCartelas: (next) {
                _myCartelas = next;
                for (final cartela in next) {
                  if (cartela.id == gameCartela.id &&
                      cartela.status == GameCartelaStatus.blocked) {
                    _freezeBlockedCartela(cartela);
                  }
                }
              },
            );
          }
        });
        BingoClaimDiagnostics.record(
          event: 'bingo.terminal',
          claimAttemptId: attempt.claimAttemptId,
          sessionId: sessionId,
          cartelaId: gameCartela.id,
          claimStatus: result.claim.status.name,
          state: 'applied_http',
        );
        if (result.claim.status.isTerminal) {
          _cn.processedResolvedClaimIds.add(result.claim.id);
        }
        _scheduleCanonicalRefetch(includeMyCartelas: true);
        return;
      }
      var resolved = const ClaimResolution(applied: false, cartelas: []);
      setState(() {
        resolved = _cn.resolveTerminalClaim(
          attempt: attempt,
          status: result.claim.status,
          retryAllowed: result.retryAllowed,
          cartelas: _myCartelas,
          reportedCartelaStatus: result.gameCartelaStatus,
          applyCartelas: (next) => _myCartelas = next,
        );
        if (!resolved.applied) return;
        if (result.claim.status == BingoClaimStatus.failed ||
            result.claim.status == BingoClaimStatus.alreadyResolved) {
          _applyRetryableClaimSnapshot(
            gameStatus: result.gameStatus,
            cartelaId: gameCartela.id,
            cartelaStatus: result.gameCartelaStatus,
            winnerWindowEndsAt: result.winnerWindowEndsAt,
          );
          _game = _applyNextAutoCallAtFromClaimResult(_game, result);
        } else {
          _applyClaimResultState(
            result: result,
            gameCartela: gameCartela,
            cartelaAlreadyPatched: true,
          );
        }
        if (result.claim.status.isTerminal) {
          _clearSessionCheckingCartelaNumber(gameCartela.cartela.number);
          if (resolved.cartelaStatus == GameCartelaStatus.blocked) {
            for (final cartela in _myCartelas) {
              if (cartela.id == gameCartela.id) {
                _freezeBlockedCartela(cartela);
                break;
              }
            }
          }
        }
      });
      if (!resolved.applied) return;
      BingoClaimDiagnostics.record(
        event: 'bingo.terminal',
        claimAttemptId: attempt.claimAttemptId,
        sessionId: sessionId,
        cartelaId: gameCartela.id,
        claimStatus: result.claim.status.name,
        state: 'applied_http',
      );
      if (result.claim.status.isTerminal) {
        _cn.processedResolvedClaimIds.add(result.claim.id);
      }
      if (result.isWinner && result.gameStatus == GameStatus.winnerWindow) {
        _playGameSound(SoundEvent.validBingo, dedupeKey: result.claim.id);
        _applyWinnerWindowState(winnerWindowEndsAt: result.winnerWindowEndsAt);
        _syncWinnerWindowTicker();
      }
      if (result.claim.status == BingoClaimStatus.failed && result.retryAllowed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.claim.reason ??
              'Bingo could not be checked. You can try again.'),
        ));
      }
      if (result.claim.status.isTerminal) {
        _scheduleCanonicalRefetch(includeMyCartelas: true);
      }
    } catch (error) {
      BingoClaimDiagnostics.record(
        event: 'bingo.post.error',
        claimAttemptId: attempt.claimAttemptId,
        sessionId: sessionId,
        cartelaId: gameCartela.id,
        elapsedMs: DateTime.now().difference(requestStartedAt).inMilliseconds,
        statusCode: error is ApiException ? error.statusCode : null,
        dioType: error is ApiException ? error.dioExceptionType : null,
        detail: error is ApiException ? error.message : error.runtimeType.toString(),
        state: 'ambiguous',
      );
      // Only a connectionTimeout structurally proves no request bytes could
      // have left the device. This alone never clears the claim — it is only
      // combined with an independent recovery-GET connection failure inside
      // _runClaimRecovery before anything is dropped.
      attempt.postConnectNeverCompleted =
          error is ApiException && error.dioExceptionType == 'connectionTimeout';
      if (!mounted || !_claimCallbackIsCurrent(attempt)) return;
      BingoClaimDiagnostics.record(
        event: 'bingo.recovery.start',
        claimAttemptId: attempt.claimAttemptId,
        sessionId: sessionId,
        cartelaId: gameCartela.id,
        state: 'confirming',
      );
      await _recoverClaimAttemptAfterAmbiguousFailure(attempt);
      if (mounted && _claimCallbackIsCurrent(attempt) &&
          _cn.claimRecoveryFailedCartelaIds.contains(gameCartela.id)) {
        // Ambiguous only — never treat timeout/404 as INVALID. Retain UUID;
        // CONFIRMING UI + manual recheck / same-UUID retry until authoritative.
        // Offline gets its own copy so a dropped connection never reads like
        // a rejected claim.
        final isOffline = error is ApiException && error.isConnectivityFailure;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            isOffline
                ? 'No connection. Your bingo claim was not rejected — '
                      'we will keep checking once you are back online.'
                : 'Could not confirm bingo result. Recheck looks it up; Copy log helps support.',
          ),
          action: SnackBarAction(
            label: 'Recheck',
            onPressed: () {
              BingoClaimDiagnostics.record(
                event: 'bingo.recovery.start',
                claimAttemptId: attempt.claimAttemptId,
                sessionId: attempt.sessionId,
                cartelaId: attempt.gameCartelaId,
                state: 'manual_recheck',
                retryCount: attempt.sameUuidPostRetries,
              );
              unawaited(BingoClaimDiagnostics.copyToClipboard(
                claimAttemptId: attempt.claimAttemptId,
              ));
              _cn.reconcileClaimAttempts();
            },
          ),
          duration: const Duration(seconds: 8),
        ));
      }
    } finally {
      // Cleanup cannot relock a resolved attempt or clear a newer UUID.
      _cn.finishClaimSubmission(attempt);
      if (isLiveHostActive && _cachedMarksUserId == attempt.userId &&
          _activeSessionId == attempt.sessionId) {
        _flushPendingClaimSocketEvents();
        if (_cn.confirmingOrClaimingCartelaIds.isEmpty) {
          _flushBufferedCalledNumbers();
        }
        _releaseCalledNumbersStripHoldIfIdle();
      }
      BingoClaimDiagnostics.record(
        event: 'bingo.state.transition',
        claimAttemptId: attempt.claimAttemptId,
        sessionId: attempt.sessionId,
        cartelaId: attempt.gameCartelaId,
        elapsedMs: DateTime.now().difference(startedAt).inMilliseconds,
        state: attempt.terminal
            ? 'terminal'
            : (attempt.postInFlight ? 'post_in_flight' : 'confirming'),
        retryCount: attempt.sameUuidPostRetries,
      );
    }
  }

  bool _claimCallbackIsCurrent(BingoClaimAttempt attempt) =>
      isLiveHostActive && _cachedMarksUserId == attempt.userId &&
      _activeSessionId == attempt.sessionId &&
      _cn.isCurrentClaimAttempt(attempt);

  Future<void> _recoverClaimAttemptAfterAmbiguousFailure(
    BingoClaimAttempt attempt,
  ) => _cn.recoverClaimAttempt(attempt);

  Future<void> _refreshChainClaimRecoveryContext(
    BingoClaimAttempt attempt,
    BingoClaimAttemptStatus result,
  ) async {
    if (!_claimCallbackIsCurrent(attempt) || _game?.isChainGame != true ||
        !result.status.isTerminal || result.gameStatus != GameStatus.playing) {
      return;
    }
    // Recovery GET has no round/pause fields. Refresh the existing canonical
    // flow before releasing an old round's UUID or calculating new eligibility.
    final current = await _gamesRepository.getSessionDetail(attempt.sessionId);
    if (!_claimCallbackIsCurrent(attempt)) return;
    await runResumeSync(allowCachedOperations: false);
    if (!_claimCallbackIsCurrent(attempt)) return;
    if (_game?.displayRoundIndex != current.displayRoundIndex ||
        _game?.roundPausedUntil != current.roundPausedUntil ||
        _game?.status != current.status) {
      throw StateError('Chain claim recovery awaits current round truth');
    }
  }

  void _applyRetryableClaimSnapshot({
    required GameStatus gameStatus,
    required String cartelaId,
    required GameCartelaStatus cartelaStatus,
    required DateTime? winnerWindowEndsAt,
  }) {
    final current = _game;
    if (current != null && !isTerminalGameStatus(current.status)) {
      // A claim response cannot reopen a window that this view already closed,
      // or downgrade WINNER_WINDOW to an older PLAYING snapshot.
      final expiredDeadline = _winnerWindowExpired
          ? _effectiveWinnerWindowEndsAt : null;
      if (gameStatus == GameStatus.winnerWindow) {
        final deadline = expiredDeadline ?? winnerWindowEndsAt ??
            _effectiveWinnerWindowEndsAt;
        _game = current.copyWith(status: gameStatus,
            winnerWindowEndsAt: deadline);
        _countdown.winnerWindowEndsAt = deadline;
      } else if (gameStatus != GameStatus.playing ||
          current.status != GameStatus.winnerWindow) {
        _game = current.copyWith(status: gameStatus);
      }
    }
    if (cartelaStatus == GameCartelaStatus.blocked ||
        cartelaStatus == GameCartelaStatus.winner ||
        cartelaStatus == GameCartelaStatus.cancelled) {
      _myCartelas = _cn.applyPresentedTerminalCartela(
        cartelas: _myCartelas,
        gameCartelaId: cartelaId,
        status: cartelaStatus,
      );
    }
  }

  void _applyRecoveredClaimAttempt(
    BingoClaimAttempt attempt,
    BingoClaimAttemptStatus result,
  ) {
    if (!isLiveHostActive || _cachedMarksUserId != attempt.userId ||
        _activeSessionId != attempt.sessionId) {
      return;
    }
    if (!_cn.claimOutcomeMatchesView(attempt, _game)) {
      if (result.status.isTerminal) {
        // Historical / cross-round: INVALID may safely paint BLOCKED on the
        // same session cartela; otherwise retain eligibility lock. VALID
        // clears the attempt without painting WINNER onto the newer round.
        setState(() {
          _cn.resolveHistoricalTerminalClaim(
            attempt: attempt,
            status: result.status,
            retryAllowed: result.retryAllowed,
            cartelas: _myCartelas,
            reportedCartelaStatus: result.gameCartelaStatus,
            game: _game,
            applyCartelas: (next) {
              _myCartelas = next;
              for (final cartela in next) {
                if (cartela.id == attempt.gameCartelaId &&
                    cartela.status == GameCartelaStatus.blocked) {
                  _cn.rememberBlockedCartelaReason(
                    gameCartelaId: cartela.id,
                    reasonCode: result.reasonCode,
                  );
                  _freezeBlockedCartela(cartela);
                }
              }
            },
          );
        });
        _scheduleCanonicalRefetch(includeMyCartelas: true);
      }
      return;
    }
    if (!result.status.isTerminal) return;
    var resolved = const ClaimResolution(applied: false, cartelas: []);
    setState(() {
      resolved = _cn.resolveTerminalClaim(
        attempt: attempt,
        status: result.status,
        retryAllowed: result.retryAllowed,
        cartelas: _myCartelas,
        reportedCartelaStatus: result.gameCartelaStatus,
        applyCartelas: (next) => _myCartelas = next,
      );
      if (!resolved.applied) return;
      _game = _game?.copyWith(nextAutoCallAt: result.nextAutoCallAt);
      _applyRetryableClaimSnapshot(
        gameStatus: result.gameStatus,
        cartelaId: attempt.gameCartelaId,
        cartelaStatus: result.gameCartelaStatus,
        winnerWindowEndsAt: result.winnerWindowEndsAt,
      );
      _myCartelas = normalizeChainPlayableCartelas(
        game: _game,
        cartelas: _myCartelas,
      );
      for (final cartela in _myCartelas) {
        if (cartela.id == attempt.gameCartelaId) {
          _clearSessionCheckingCartelaNumber(cartela.cartela.number);
          if (cartela.status == GameCartelaStatus.blocked) {
            _cn.rememberBlockedCartelaReason(
              gameCartelaId: cartela.id, reasonCode: result.reasonCode,
            );
            _freezeBlockedCartela(cartela);
          }
        }
      }
    });
    if (!resolved.applied) return;
    if (result.status == BingoClaimStatus.valid) {
      _playGameSound(SoundEvent.validBingo,
          dedupeKey: attempt.serverClaimId ?? attempt.claimAttemptId);
      if (_game?.status == GameStatus.winnerWindow && !_winnerWindowExpired) {
        _applyWinnerWindowState(winnerWindowEndsAt: _effectiveWinnerWindowEndsAt);
      }
      if (result.gameStatus == GameStatus.finished) {
        _awaitingPrizeWalletRefresh = true;
      }
    }
    _syncWinnerWindowTicker();
    _flushPendingClaimSocketEvents();
    if (_cn.confirmingOrClaimingCartelaIds.isEmpty) {
      _flushBufferedCalledNumbers();
    }
    _releaseCalledNumbersStripHoldIfIdle();
    _scheduleCanonicalRefetch(
      includeMyCartelas: true,
      wallet: result.status == BingoClaimStatus.valid &&
          result.gameStatus == GameStatus.finished,
    );
  }

  void _applyClaimResultState({
    required BingoClaimResult result,
    required GameCartelaModel gameCartela,
    bool cartelaAlreadyPatched = false,
  }) {
    if (result.claim.status.isTerminal) {
      _cn.processedResolvedClaimIds.add(result.claim.id);
    }
    _cn.claimRecoveryFailedCartelaIds.remove(gameCartela.id);

    if (result.claim.status == BingoClaimStatus.invalid ||
        result.gameCartelaStatus == GameCartelaStatus.blocked) {
      _cn.rememberBlockedCartelaReason(
        gameCartelaId: gameCartela.id,
        reasonCode: result.reasonCode ?? result.claim.reasonCode,
        serverReason: result.claim.reason,
      );
      _game = _applyNextAutoCallAtFromClaimResult(_game, result);
      if (!cartelaAlreadyPatched) {
        _myCartelas = _cn.applyPresentedTerminalCartela(
          cartelas: _myCartelas,
          gameCartelaId: gameCartela.id,
          status: GameCartelaStatus.blocked,
        );
      }
      for (final cartela in _myCartelas) {
        if (cartela.id == gameCartela.id) {
          _freezeBlockedCartela(cartela);
          break;
        }
      }
      return;
    }

    if (result.claim.status == BingoClaimStatus.valid || result.isWinner) {
      _game = _applyNextAutoCallAtFromClaimResult(
        result.gameStatus == GameStatus.winnerWindow &&
                _game?.status != GameStatus.finished &&
                _game?.status != GameStatus.noWinner
            ? _game?.copyWith(
                status: GameStatus.winnerWindow,
                winnerWindowEndsAt:
                    result.winnerWindowEndsAt ?? _game?.winnerWindowEndsAt,
              )
            : _game,
        result,
      );
      if (result.winnerWindowEndsAt != null) {
        _countdown.winnerWindowEndsAt = result.winnerWindowEndsAt;
      }
      _storeWinningPatternCells(
        gameCartelaId: gameCartela.id,
        patterns: result.completedPatterns,
        columns: gameCartela.cartela.columns,
        lastCalledNumber: result.lastCalledNumber,
      );
      if (!cartelaAlreadyPatched) {
        _myCartelas = _cn.applyPresentedTerminalCartela(
          cartelas: _myCartelas,
          gameCartelaId: gameCartela.id,
          status: GameCartelaStatus.winner,
        );
      }
      return;
    }

    _cn.processedClaimedIds.add(result.claim.id);
    _cn.pendingClaimCartelaIds.add(gameCartela.id);
    _game = _applyNextAutoCallAtFromClaimResult(_game, result);
  }

  GameModel? _applyNextAutoCallAtFromClaimResult(
    GameModel? game,
    BingoClaimResult result,
  ) {
    if (game == null || !result.hasNextAutoCallAt) {
      return game;
    }

    return game.copyWith(nextAutoCallAt: result.nextAutoCallAt);
  }

  void _toggleMarkedNumber(
    GameCartelaModel cartela,
    String header,
    String value,
  ) {
    if (_cartelaMarksFrozenForEvidence) {
      return;
    }

    setState(() {
      final toggledKey = manualMarkKey(header, value);
      final next = toggleManualMarkedNumber(
        manualMarkedNumbers: _cn.manualMarkedNumbers,
        header: header,
        value: value,
      );
      _cn.manualMarkedNumbers
        ..clear()
        ..addAll(next);
      _cn.lastManualMarkedKey = resolveLastManualMarkedKey(
        currentLastMarkedKey: _cn.lastManualMarkedKey,
        nextMarks: next,
        toggledKey: toggledKey,
      );
      _sortMyCartelas();
    });
    unawaited(_persistManualMarks());
  }
}

