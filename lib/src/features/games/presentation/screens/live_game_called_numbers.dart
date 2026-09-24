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
      claimingCartelaIds: _cn.claimingCartelaIds,
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
              onRefreshCalledNumbers: () =>
                  unawaited(_realtime.syncLatest(reason: 'manual_refresh')),
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
          ],
        );
      },
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
    if (sessionId == null || _cn.claimingCartelaIds.contains(gameCartela.id)) {
      return;
    }

    // Once pressed: commit to claiming and always submit. Do not abort for the
    // countdown lock race — the button gate already disables presses; a fired
    // press must get a real winner / blocked / error answer, not gold-ready again.
    final claimStartedAt = DateTime.now();
    final preClaimNextAutoCallAt = _game?.nextAutoCallAt;
    final shouldOptimisticPause =
        _isAutoCallActiveForSession && preClaimNextAutoCallAt != null;

    _cn.claimStripHoldActive = true;
    _cn.preClaimNextAutoCallAt = preClaimNextAutoCallAt;
    _cn.claimingCartelaIds.add(gameCartela.id);
    _cn.claimRecoveryFailedCartelaIds.remove(gameCartela.id);

    setState(() {
      if (shouldOptimisticPause) {
        _game = _game?.copyWith(nextAutoCallAt: null);
      }
    });

    BingoClaimResult? claimResult;
    String? outcomeSnackbarMessage;
    var claimFailed = false;
    var claimStateAppliedEarly = false;
    var recoveryResolvedTerminal = false;
    var recoveryFailed = false;
    String appliedBranch = 'none';
    int? statusCode;
    String? errorType;
    var recoveryMs = 0;

    final requestStartedAt = DateTime.now();
    BingoClaimClientDebug.log(
      'tapToRequestMs=${requestStartedAt.difference(claimStartedAt).inMilliseconds} '
      'cartela=${gameCartela.id}',
    );

    try {
      final result = await _gamesRepository.claimBingo(
        sessionId: sessionId,
        gameCartelaId: gameCartela.id,
      );

      if (!mounted) {
        return;
      }

      claimResult = result;

      if (result.gameCartelaStatus == GameCartelaStatus.blocked) {
        _cn.rememberBlockedCartelaReason(
          gameCartelaId: gameCartela.id,
          reasonCode: result.reasonCode ?? result.claim.reasonCode,
          serverReason: result.claim.reason,
        );
        appliedBranch = 'blocked';
        return;
      }

      if (result.isWinner && result.gameStatus == GameStatus.winnerWindow) {
        _playGameSound(SoundEvent.validBingo, dedupeKey: result.claim.id);
        setState(() {
          _applyClaimResultState(result: result, gameCartela: gameCartela);
          claimStateAppliedEarly = true;
          _cn.claimStripHoldActive = false;
          _cn.claimingCartelaIds.remove(gameCartela.id);
          _cn.preClaimNextAutoCallAt = null;
          final cartelaNumber = gameCartela.cartela.number;
          _clearSessionCheckingCartelaNumber(cartelaNumber);
        });
        _applyWinnerWindowState(winnerWindowEndsAt: result.winnerWindowEndsAt);
        _flushPendingClaimSocketEvents();
        if (_cn.claimingCartelaIds.isEmpty) {
          _flushBufferedCalledNumbers();
        }
        _syncWinnerWindowTicker();
        // Late bingo during Finalizing: continue to finished once checks are idle.
        _releaseCalledNumbersStripHoldIfIdle();
        appliedBranch = 'winner';
        return;
      }

      appliedBranch = 'pending';
      outcomeSnackbarMessage =
          result.claim.reason ?? context.l10n.gameCheckingMessage;
    } catch (error) {
      if (!mounted) {
        return;
      }

      statusCode = error is ApiException ? error.statusCode : null;
      errorType = error is ApiException
          ? (error.isConnectivityFailure
                ? 'connectivity'
                : 'api_${error.statusCode ?? 'unknown'}')
          : error.runtimeType.toString();

      final recoveryStartedAt = DateTime.now();
      final recovery = await _recoverClaimAfterAmbiguousFailure(
        sessionId: sessionId,
        gameCartela: gameCartela,
      );
      recoveryMs = DateTime.now().difference(recoveryStartedAt).inMilliseconds;

      if (!mounted) {
        return;
      }

      if (recovery == _ClaimRecoveryOutcome.winner ||
          recovery == _ClaimRecoveryOutcome.blocked) {
        recoveryResolvedTerminal = true;
        claimResult = null;
        appliedBranch = recovery == _ClaimRecoveryOutcome.winner
            ? 'recovery_winner'
            : 'recovery_blocked';
        return;
      }

      if (recovery == _ClaimRecoveryOutcome.registered) {
        claimFailed = true;
        appliedBranch = 'recovery_registered';
        outcomeSnackbarMessage = error is ApiException
            ? error.displayMessage
            : 'Could not submit bingo claim.';
      } else {
        // recovery == failed — do not silently restore Bingo.
        recoveryFailed = true;
        claimFailed = true;
        appliedBranch = 'recovery_failed';
        outcomeSnackbarMessage =
            'Could not confirm bingo result. Check your connection and try again.';
      }
    } finally {
      final requestDurationMs = DateTime.now()
          .difference(requestStartedAt)
          .inMilliseconds;
      final isWinnerWindowSuccess =
          claimResult?.isWinner == true &&
          claimResult?.gameStatus == GameStatus.winnerWindow;

      if (mounted && !claimStateAppliedEarly) {
        setState(() {
          if (claimFailed) {
            if (shouldOptimisticPause) {
              _game = _game?.copyWith(
                nextAutoCallAt: _cn.preClaimNextAutoCallAt,
              );
            }
          } else if (claimResult != null) {
            _applyClaimResultState(
              result: claimResult,
              gameCartela: gameCartela,
            );
          }

          if (recoveryFailed) {
            _cn.claimRecoveryFailedCartelaIds.add(gameCartela.id);
            // Keep strip hold clear but do not treat as a successful claim end
            // that re-arms Bingo — eligibility checks recovery-failed set.
            _cn.claimStripHoldActive = false;
            _cn.claimingCartelaIds.remove(gameCartela.id);
            _cn.preClaimNextAutoCallAt = null;
            _clearSessionCheckingCartelaNumber(gameCartela.cartela.number);
          } else if (recoveryResolvedTerminal) {
            _cn.claimStripHoldActive = false;
            _cn.claimingCartelaIds.remove(gameCartela.id);
            _cn.preClaimNextAutoCallAt = null;
            _cn.claimRecoveryFailedCartelaIds.remove(gameCartela.id);
            _clearSessionCheckingCartelaNumber(gameCartela.cartela.number);
          } else {
            _cn.claimStripHoldActive = false;
            _cn.claimingCartelaIds.remove(gameCartela.id);
            _cn.preClaimNextAutoCallAt = null;
            _cn.claimRecoveryFailedCartelaIds.remove(gameCartela.id);
            _clearSessionCheckingCartelaNumber(gameCartela.cartela.number);
          }

          if (_cn.claimingCartelaIds.isEmpty) {
            _flushBufferedCalledNumbers();
          }
        });

        _flushPendingClaimSocketEvents();

        if (outcomeSnackbarMessage != null &&
            !isWinnerWindowSuccess &&
            claimResult?.gameCartelaStatus != GameCartelaStatus.blocked) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(outcomeSnackbarMessage)));
        }

        if (claimResult?.gameCartelaStatus == GameCartelaStatus.blocked) {
          _scheduleCanonicalRefetch();
        }

        // Claim resolved (valid/invalid/failed) — unblock Finalizing if WW expired.
        _releaseCalledNumbersStripHoldIfIdle();
      }

      BingoClaimClientDebug.log(
        'requestDurationMs=$requestDurationMs recoveryMs=$recoveryMs '
        'totalTapToResultMs=${DateTime.now().difference(claimStartedAt).inMilliseconds} '
        'statusCode=${statusCode ?? '-'} errorType=${errorType ?? '-'} '
        'appliedBranch=$appliedBranch',
      );
    }
  }

  Future<_ClaimRecoveryOutcome> _recoverClaimAfterAmbiguousFailure({
    required String sessionId,
    required GameCartelaModel gameCartela,
  }) async {
    try {
      final myCartelas = await _gamesRepository.getMyGameCartelas(sessionId);
      if (!mounted) {
        return _ClaimRecoveryOutcome.failed;
      }

      GameCartelaModel? refreshed;
      for (final cartela in myCartelas) {
        if (cartela.id == gameCartela.id) {
          refreshed = cartela;
          break;
        }
      }

      if (refreshed == null) {
        return _ClaimRecoveryOutcome.registered;
      }

      final resolvedCartela = refreshed;

      if (resolvedCartela.isWinner ||
          resolvedCartela.status == GameCartelaStatus.winner) {
        final chainPlaying =
            _game?.isChainGame == true && _game?.status == GameStatus.playing;
        setState(() {
          if (!chainPlaying) {
            _game = _game?.copyWith(status: GameStatus.winnerWindow);
          }
          _myCartelas = normalizeChainPlayableCartelas(
            game: _game,
            cartelas: _myCartelas
                .map((cartela) {
                  if (cartela.id != gameCartela.id) {
                    return cartela;
                  }

                  if (chainPlaying) {
                    return resolvedCartela;
                  }

                  return resolvedCartela.copyWith(
                    status: GameCartelaStatus.winner,
                    isWinner: true,
                    blockedAt: null,
                  );
                })
                .toList(growable: false),
          );
          _cn.claimRecoveryFailedCartelaIds.remove(gameCartela.id);
        });

        _syncWinnerWindowTicker();
        return _ClaimRecoveryOutcome.winner;
      }

      if (resolvedCartela.status == GameCartelaStatus.blocked) {
        setState(() {
          _myCartelas = _myCartelas
              .map((cartela) {
                if (cartela.id != gameCartela.id) {
                  return cartela;
                }

                return resolvedCartela;
              })
              .toList(growable: false);
          for (final cartela in _myCartelas) {
            if (cartela.id == gameCartela.id) {
              _freezeBlockedCartela(cartela);
              break;
            }
          }
          _cn.claimRecoveryFailedCartelaIds.remove(gameCartela.id);
        });

        return _ClaimRecoveryOutcome.blocked;
      }

      return _ClaimRecoveryOutcome.registered;
    } catch (_) {
      return _ClaimRecoveryOutcome.failed;
    }
  }

  void _applyClaimResultState({
    required BingoClaimResult result,
    required GameCartelaModel gameCartela,
  }) {
    _cn.processedResolvedClaimIds.add(result.claim.id);
    _cn.claimRecoveryFailedCartelaIds.remove(gameCartela.id);

    if (result.gameCartelaStatus == GameCartelaStatus.blocked) {
      _cn.rememberBlockedCartelaReason(
        gameCartelaId: gameCartela.id,
        reasonCode: result.reasonCode ?? result.claim.reasonCode,
        serverReason: result.claim.reason,
      );
      _game = _applyNextAutoCallAtFromClaimResult(_game, result);
      _myCartelas = _myCartelas
          .map((cartela) {
            if (cartela.id != gameCartela.id) {
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
        if (cartela.id == gameCartela.id) {
          _freezeBlockedCartela(cartela);
          break;
        }
      }
      return;
    }

    if (result.isWinner && result.gameStatus == GameStatus.winnerWindow) {
      _game = _applyNextAutoCallAtFromClaimResult(
        _game?.copyWith(
          status: GameStatus.winnerWindow,
          winnerWindowEndsAt:
              result.winnerWindowEndsAt ?? _game?.winnerWindowEndsAt,
        ),
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
      _myCartelas = _myCartelas
          .map((cartela) {
            if (cartela.id != gameCartela.id) {
              return cartela;
            }

            return cartela.copyWith(
              status: GameCartelaStatus.winner,
              isWinner: true,
              blockedAt: null,
            );
          })
          .toList(growable: false);
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

enum _ClaimRecoveryOutcome { winner, blocked, registered, failed }

