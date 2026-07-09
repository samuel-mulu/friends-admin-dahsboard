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
        final canOpenWinnerDialog = winnerCartelaNumbers.isNotEmpty &&
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

    if (_isBingoClaimCountdownLocked) {
      return;
    }

    final claimStartedAt = DateTime.now();
    final preClaimNextAutoCallAt = _game?.nextAutoCallAt;
    final shouldOptimisticPause =
        _isAutoCallActiveForSession && preClaimNextAutoCallAt != null;

    _cn.claimStripHoldActive = true;
    _cn.preClaimNextAutoCallAt = preClaimNextAutoCallAt;
    _cn.claimingCartelaIds.add(gameCartela.id);

    setState(() {
      if (shouldOptimisticPause) {
        _game = _game?.copyWith(nextAutoCallAt: null);
      }
    });

    BingoClaimResult? claimResult;
    String? outcomeSnackbarMessage;
    var claimFailed = false;

    try {
      if (_isBingoClaimCountdownLocked) {
        claimFailed = true;
        return;
      }

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
        return;
      }

      if (result.isWinner && result.gameStatus == GameStatus.winnerWindow) {
        return;
      }

      outcomeSnackbarMessage =
          result.claim.reason ?? context.l10n.gameCheckingMessage;
    } catch (error) {
      if (!mounted) {
        return;
      }

      if (error is ApiException && error.isConnectivityFailure) {
        final recovered = await _recoverClaimAfterConnectivityFailure(
          sessionId: sessionId,
          gameCartela: gameCartela,
        );
        if (recovered) {
          claimResult = null;
          return;
        }
      }

      claimFailed = true;

      if (!mounted) {
        return;
      }

      outcomeSnackbarMessage = error is ApiException
          ? error.displayMessage
          : 'Could not submit bingo claim.';
    } finally {
      final elapsed = DateTime.now().difference(claimStartedAt);
      final remaining =
          _LiveGameScreenStateBase._checkingCartelaMinimumDisplay - elapsed;
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }

      if (mounted) {
        setState(() {
          if (claimFailed) {
            if (shouldOptimisticPause) {
              _game = _game?.copyWith(nextAutoCallAt: _cn.preClaimNextAutoCallAt);
            }
          } else if (claimResult != null) {
            _applyClaimResultState(
              result: claimResult,
              gameCartela: gameCartela,
            );
          }

          _cn.claimStripHoldActive = false;
          _cn.claimingCartelaIds.remove(gameCartela.id);
          _cn.preClaimNextAutoCallAt = null;

          if (_cn.claimingCartelaIds.isEmpty) {
            _flushBufferedCalledNumbers();
          }
        });

        _flushPendingClaimSocketEvents();

        if (outcomeSnackbarMessage != null &&
            !(claimResult?.isWinner == true &&
                claimResult?.gameStatus == GameStatus.winnerWindow) &&
            claimResult?.gameCartelaStatus != GameCartelaStatus.blocked) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(outcomeSnackbarMessage)));
        }

        if (claimResult?.gameCartelaStatus == GameCartelaStatus.blocked) {
          _scheduleCanonicalRefetch();
        } else if (claimResult?.isWinner == true &&
            claimResult?.gameStatus == GameStatus.winnerWindow) {
          _syncWinnerWindowTicker();
        }
      }
    }
  }

  void _applyClaimResultState({
    required BingoClaimResult result,
    required GameCartelaModel gameCartela,
  }) {
    _cn.processedResolvedClaimIds.add(result.claim.id);

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

  Future<bool> _recoverClaimAfterConnectivityFailure({
    required String sessionId,
    required GameCartelaModel gameCartela,
  }) async {
    try {
      final myCartelas = await _gamesRepository.getMyGameCartelas(sessionId);
      if (!mounted) {
        return true;
      }

      GameCartelaModel? refreshed;
      for (final cartela in myCartelas) {
        if (cartela.id == gameCartela.id) {
          refreshed = cartela;
          break;
        }
      }

      if (refreshed == null) {
        return false;
      }

      final resolvedCartela = refreshed;

      if (resolvedCartela.isWinner ||
          resolvedCartela.status == GameCartelaStatus.winner) {
        setState(() {
          _game = _game?.copyWith(status: GameStatus.winnerWindow);
          _myCartelas = _myCartelas
              .map((cartela) {
                if (cartela.id != gameCartela.id) {
                  return cartela;
                }

                return resolvedCartela.copyWith(
                  status: GameCartelaStatus.winner,
                  isWinner: true,
                  blockedAt: null,
                );
              })
              .toList(growable: false);
        });

        _syncWinnerWindowTicker();
        return true;
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
        });

        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
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

  void _clearMarksForCartela(GameCartelaModel cartela) {
    if (_cartelaMarksFrozenForEvidence) {
      return;
    }

    setState(() {
      final next = clearManualMarksForCartela(
        manualMarkedNumbers: _cn.manualMarkedNumbers,
        cartela: cartela,
      );
      _cn.manualMarkedNumbers
        ..clear()
        ..addAll(next);
      if (_cn.lastManualMarkedKey != null) {
        if (!next.contains(_cn.lastManualMarkedKey)) {
          _cn.lastManualMarkedKey = null;
        }
      }
      _sortMyCartelas();
    });
    unawaited(_persistManualMarks());
  }
}
