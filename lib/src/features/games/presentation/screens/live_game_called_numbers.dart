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

  Future<void> _claimBingo(GameCartelaModel gameCartela) =>
      _submitBingoClaim(gameCartela, source: BingoClaimSource.manual);

  /// Shared MANUAL/AUTO claim path. Nest remains authority; AUTO only changes
  /// `claimSource` and quiets expected business rejections (R3).
  Future<_BingoClaimSubmitOutcome> _submitBingoClaim(
    GameCartelaModel gameCartela, {
    BingoClaimSource source = BingoClaimSource.manual,
    String? autoBingoAttemptKey,
  }) async {
    final sessionId = _activeSessionId;
    if (sessionId == null ||
        !_canClaimBingoForCartela(gameCartela) ||
        controllers.claim.isClaimInFlight(gameCartela.id)) {
      return const _BingoClaimSubmitOutcome(skipped: true);
    }
    controllers.claim.markClaimInFlight(gameCartela.id);
    final isAuto = source == BingoClaimSource.auto;
    final startedAt = DateTime.now();
    final attempt = _cn.beginClaimAttempt(
      gameCartelaId: gameCartela.id,
      claimAttemptId: const Uuid().v4(),
      roundIndex: _game?.displayRoundIndex ?? 1,
      claimSource: source,
      autoBingoAttemptKey: autoBingoAttemptKey,
    );
    if (attempt == null) {
      controllers.claim.clearClaimInFlight(gameCartela.id);
      return const _BingoClaimSubmitOutcome(skipped: true);
    }
    controllers.claim.markClaimInFlight(gameCartela.id, attempt.claimAttemptId);
    BingoClaimDiagnostics.record(
      event: isAuto ? 'bingo.auto' : 'bingo.tap',
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
        controllers.claim.clearClaimInFlight(gameCartela.id, attempt.claimAttemptId);
        if (mounted && isLiveHostActive) {
          setState(() {
            if (_cn.confirmingOrClaimingCartelaIds.isEmpty) {
              _game = _game?.copyWith(nextAutoCallAt: previousSchedule);
            }
          });
          if (!isAuto) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Could not save your claim. Please try again.'),
            ));
          }
        }
      }
      return const _BingoClaimSubmitOutcome(skipped: true);
    }
    if (!_claimCallbackIsCurrent(attempt)) {
      _cn.cancelUnsentClaim(attempt);
      controllers.claim.clearClaimInFlight(gameCartela.id, attempt.claimAttemptId);
      return const _BingoClaimSubmitOutcome(skipped: true);
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
    var outcome = const _BingoClaimSubmitOutcome();
    try {
      final result = await _gamesRepository.claimBingo(
        sessionId: sessionId,
        gameCartelaId: gameCartela.id,
        claimAttemptId: attempt.claimAttemptId,
        clientTapAt: startedAt,
        claimSource: source,
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
      if (!isLiveHostActive) {
        return outcome;
      }
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
        return outcome;
      }
      attempt.serverClaimId = result.claim.id;
      outcome = _BingoClaimSubmitOutcome(
        status: result.claim.status,
        retryAllowed: result.retryAllowed,
        failureCode: result.failureCode ?? result.claim.failureCode,
        cartelaStatus: result.gameCartelaStatus,
      );
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
        return outcome;
      }
      var resolved = const ClaimResolution(applied: false, cartelas: []);
      _releaseRetryableAutoBingoAttempt(attempt,
        status: result.claim.status, retryAllowed: result.retryAllowed,
        failureCode: result.failureCode ?? result.claim.failureCode,
        cartelaStatus: result.gameCartelaStatus,
      );
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
      if (!resolved.applied) return outcome;
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
        final quietAuto = isAuto &&
            isQuietAutoBingoFailureCode(
              result.failureCode ?? result.claim.failureCode,
            );
        if (!quietAuto && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result.claim.reason ??
                'Bingo could not be checked. You can try again.'),
          ));
        }
      } else if (isAuto &&
          result.claim.status == BingoClaimStatus.failed &&
          isQuietAutoBingoFailureCode(
            result.failureCode ?? result.claim.failureCode,
          )) {
        // Quiet expected AUTO business rejection (R3).
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
      if (!mounted || !_claimCallbackIsCurrent(attempt)) return outcome;
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
        // a rejected claim. Manual snackbars unchanged; AUTO keeps same recovery.
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
      controllers.claim.clearClaimInFlight(gameCartela.id, attempt.claimAttemptId);
      // Cleanup cannot relock a resolved attempt or clear a newer UUID.
      _cn.finishClaimSubmission(attempt);
      if (mounted) {
        setState(() {});
      }
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
    return outcome;
  }

  @override
  void _scheduleAutoBingoEvaluation({String reason = 'trigger'}) {
    if (!isLiveHostActive || !_cn.effectiveAutoBingo) {
      return;
    }
    unawaited(_runAutoBingoScheduler(reason: reason));
  }

  Future<void> _runAutoBingoScheduler({required String reason}) async {
    if (!isLiveHostActive || !_cn.effectiveAutoBingo) {
      return;
    }
    final sessionId = _activeSessionId;
    final game = _game;
    if (sessionId == null || game == null) {
      return;
    }
    final roundIndex = game.displayRoundIndex;
    _cn.ensureAutoBingoScope(sessionId: sessionId, roundIndex: roundIndex);
    if (!gameAllowsAutoBingoClaims(game) || _winnerWindowExpired) {
      _cn.clearAutoBingoQueue();
      return;
    }
    // Do not scan while strip is paused — only committed strip numbers.
    if (_cn.claimStripHoldActive ||
        _cn.confirmingOrClaimingCartelaIds.isNotEmpty ||
        _cn.bufferedCalledNumbers.isNotEmpty) {
      if (_cn.autoBingoQueue.isNotEmpty) {
        await _drainAutoBingoQueue();
      }
      return;
    }

    final completingOrder = completingCalledOrderOf(_cn.calledNumbers);
    final eligible = selectAutoBingoPatternCompleteCartelas(
      cartelas: _myCartelas,
      calledNumbers: _cn.calledNumbers,
      ruleKey: game.ruleKey,
      terminalSuppressKeys: _cn.autoBingoTerminalSuppressKeys,
      attemptDedupeKeys: _cn.autoBingoAttemptDedupeKeys,
      sessionId: sessionId,
      roundIndex: roundIndex,
      completingCalledOrder: completingOrder,
    );
    if (eligible.isNotEmpty) {
      _cn.autoBingoQueue = enqueueAutoBingoCartelas(
        queue: _cn.autoBingoQueue,
        incomingIds: eligible.map((c) => c.id),
      );
    }
    await _drainAutoBingoQueue();
  }

  Future<void> _drainAutoBingoQueue() async {
    if (_cn.autoBingoDrainActive) {
      return;
    }
    _cn.autoBingoDrainActive = true;
    final drainGeneration = _cn.autoBingoGeneration;
    // Terminal callbacks may scan/requeue while this drain awaits HTTP.
    // Reconsider the same key only through a later existing trigger.
    final submittedKeys = _cn.autoBingoDrainAttemptKeys;
    try {
      while (isLiveHostActive &&
          _cn.effectiveAutoBingo &&
          _cn.autoBingoQueue.isNotEmpty &&
          drainGeneration == _cn.autoBingoGeneration) {
        final sessionId = _activeSessionId;
        final game = _game;
        if (sessionId == null || game == null) {
          _cn.clearAutoBingoQueue();
          return;
        }
        final roundIndex = game.displayRoundIndex;
        _cn.ensureAutoBingoScope(sessionId: sessionId, roundIndex: roundIndex);
        if (drainGeneration != _cn.autoBingoGeneration) {
          return;
        }

        final completingOrder = completingCalledOrderOf(_cn.calledNumbers);
        final headIndex = _cn.autoBingoQueue.indexWhere((id) =>
            !submittedKeys.contains(autoBingoAttemptDedupeKey(
              sessionId: sessionId, roundIndex: roundIndex,
              gameCartelaId: id, completingCalledOrder: completingOrder,
            )));
        if (headIndex < 0) return;
        final headId = _cn.autoBingoQueue[headIndex];
        GameCartelaModel? cartela;
        for (final candidate in _myCartelas) {
          if (candidate.id == headId) {
            cartela = candidate;
            break;
          }
        }
        final suppressKey = autoBingoTerminalSuppressKey(
          sessionId: sessionId,
          roundIndex: roundIndex,
          gameCartelaId: headId,
        );
        final block = classifyAutoBingoQueueHead(
          effectiveAutoBingo: _cn.effectiveAutoBingo,
          gameAllowsClaims: gameAllowsAutoBingoClaims(game),
          winnerWindowExpired: _winnerWindowExpired,
          cartela: cartela,
          sessionRoundMatches: true,
          isConfirmingOrClaimingAny:
              _cn.confirmingOrClaimingCartelaIds.isNotEmpty,
          claimStripHoldActive: _cn.claimStripHoldActive,
          hasUnresolvedAttemptForCartela: _cn.claimAttemptFor(headId) != null,
          bingoClaimLocked: _countdown.bingoClaimLocked.value,
          claimScopeLoading: _cn.claimScopeLoading,
          autoSubmitInFlight: _cn.autoBingoSubmitInFlight,
          terminalSuppressed:
              _cn.autoBingoTerminalSuppressKeys.contains(suppressKey),
        );

        if (block == AutoBingoBlockKind.temporary) {
          // Keep head queued; resume via claim/strip/recovery triggers (R1).
          return;
        }
        if (block == AutoBingoBlockKind.permanent) {
          _cn.autoBingoQueue = _cn.autoBingoQueue.where((id) => id != headId).toList(growable: false);
          continue;
        }

        final attemptKey = autoBingoAttemptDedupeKey(
          sessionId: sessionId,
          roundIndex: roundIndex,
          gameCartelaId: headId,
          completingCalledOrder: completingOrder,
        );
        if (_cn.autoBingoAttemptDedupeKeys.contains(attemptKey)) {
          _cn.autoBingoQueue = _cn.autoBingoQueue.where((id) => id != headId).toList(growable: false);
          continue;
        }
        // Mark attempt dedupe before await so parallel scans cannot double-mint.
        _cn.autoBingoAttemptDedupeKeys.add(attemptKey);
        submittedKeys.add(attemptKey);
        _cn.autoBingoQueue = _cn.autoBingoQueue.where((id) => id != headId).toList(growable: false);

        final submitCartela = cartela!;
        _cn.autoBingoSubmitInFlight = true;
        late final _BingoClaimSubmitOutcome outcome;
        try {
          outcome = await _submitBingoClaim(
            submitCartela,
            source: BingoClaimSource.auto,
            autoBingoAttemptKey: attemptKey,
          );
        } finally {
          _cn.autoBingoSubmitInFlight = false;
        }

        if (drainGeneration != _cn.autoBingoGeneration || !isLiveHostActive) {
          return;
        }

        if (outcome.skipped) {
          // beginClaim / persist / eligibility race: do not burn attempt dedupe
          // for this completing ball; re-queue and wait for a resume trigger.
          final alreadySuppressed =
              _cn.autoBingoTerminalSuppressKeys.contains(suppressKey);
          if (!shouldReleaseAutoBingoAttemptAfterSkip(
            cartelaStatus: submitCartela.status,
            alreadyTerminalSuppressed: alreadySuppressed,
          )) {
            _cn.autoBingoTerminalSuppressKeys.add(suppressKey);
            continue;
          }
          _cn.autoBingoAttemptDedupeKeys.remove(attemptKey);
          _cn.autoBingoQueue = requeueAutoBingoCartelaFront(
            queue: _cn.autoBingoQueue,
            cartelaId: headId,
          );
          return;
        }

        if (shouldTerminalSuppressAutoBingo(
          status: outcome.status,
          retryAllowed: outcome.retryAllowed,
          failureCode: outcome.failureCode,
          cartelaStatus: outcome.cartelaStatus,
        )) {
          _cn.autoBingoTerminalSuppressKeys.add(suppressKey);
        }
      }
    } finally {
      submittedKeys.clear();
      if (drainGeneration == _cn.autoBingoGeneration) {
        _cn.autoBingoDrainActive = false;
      } else {
        _cn.autoBingoDrainActive = false;
      }
    }
  }

  bool _claimCallbackIsCurrent(BingoClaimAttempt attempt) =>
      isLiveHostActive && _cachedMarksUserId == attempt.userId &&
      _activeSessionId == attempt.sessionId &&
      _cn.isCurrentClaimAttempt(attempt);

  void _releaseRetryableAutoBingoAttempt(BingoClaimAttempt attempt, {
    required BingoClaimStatus status,
    required bool retryAllowed,
    required String? failureCode,
    required GameCartelaStatus cartelaStatus,
  }) {
    final key = attempt.autoBingoAttemptKey;
    if (key == null || attempt.claimSource != BingoClaimSource.auto ||
        !_claimCallbackIsCurrent(attempt) ||
        !_cn.claimOutcomeMatchesView(attempt, _game) ||
        status != BingoClaimStatus.failed || !retryAllowed ||
        cartelaStatus != GameCartelaStatus.registered ||
        shouldTerminalSuppressAutoBingo(status: status, retryAllowed: retryAllowed,
          failureCode: failureCode, cartelaStatus: cartelaStatus)) {
      return;
    }
    _cn.autoBingoAttemptDedupeKeys.remove(key);
    // Recovery may itself start a drain for siblings. Defer this key until
    // that pass has finished, just as for a direct HTTP terminal callback.
    if (_cn.effectiveAutoBingo) {
      _cn.autoBingoDrainAttemptKeys.add(key);
    }
  }

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
    _releaseRetryableAutoBingoAttempt(attempt,
      status: result.status, retryAllowed: result.retryAllowed,
      failureCode: result.failureCode, cartelaStatus: result.gameCartelaStatus,
    );
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
      controllers.claim.clearClaimInFlight(
        attempt.gameCartelaId,
        attempt.claimAttemptId,
      );
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

  /// Builds the play cartela grid. When Auto Mark is on, refreshes pattern
  /// sort from derived visual marks before paint.
  _InlineRegisteredCartelaList _buildPlayCartelaList({
    required CartelaSortMode cartelaSortMode,
    required int cartelaSortMaxRemains,
    ValueListenable<bool>? decorativeMotionAllowedListenable,
  }) {
    if (_cn.effectiveAutoMark) {
      _sortMyCartelas();
    }

    return _InlineRegisteredCartelaList(
      cartelas: _orderedMyCartelas(
        cartelaSortMode,
        cartelaSortMaxRemains,
      ),
      sortResultsByCartelaId: _cn.cartelaSortResults,
      canClaimBingoFor: _canClaimBingoForCartela,
      claimingCartelaIds: _cn.confirmingOrClaimingCartelaIds,
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
      blockedReasonCodeFor: _blockedReasonCodeForCartela,
      blockedServerReasonFor: _blockedServerReasonForCartela,
      onReorder: cartelaSortMode.allowsManualReorder && _myCartelas.length > 1
          ? _reorderMyCartela
          : null,
      bingoLockListenable: _countdown.bingoClaimLocked,
      decorativeMotionAllowedListenable: decorativeMotionAllowedListenable,
    );
  }

  void _toggleMarkedNumber(
    GameCartelaModel cartela,
    String header,
    String value,
  ) {
    if (_cartelaMarksFrozenForEvidence) {
      return;
    }

    // Auto-marked called numbers stay visually marked; do not pollute manual
    // storage or fight the derived mark while effectiveAutoMark is on.
    final toggledKey = manualMarkKey(header, value);
    if (_cn.effectiveAutoMark && _cn.isCalledMarkKey(toggledKey)) {
      return;
    }

    setState(() {
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
      _cn.notifyManualMarksChanged();
      _sortMyCartelas();
    });
    unawaited(_persistManualMarks());
  }
}

/// Result of [_LiveGameCalledNumbers._submitBingoClaim] for Auto Bingo drain.
class _BingoClaimSubmitOutcome {
  const _BingoClaimSubmitOutcome({
    this.skipped = false,
    this.status,
    this.retryAllowed = false,
    this.failureCode,
    this.cartelaStatus,
  });

  final bool skipped;
  final BingoClaimStatus? status;
  final bool retryAllowed;
  final String? failureCode;
  final GameCartelaStatus? cartelaStatus;
}

