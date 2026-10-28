part of 'live_game_screen.dart';

mixin _LiveGameViews on
    _LiveGameScreenStateBase,
    _LiveGameOrchestration,
    _LiveGameRealtime,
    _LiveGameCalledNumbers,
    _LiveGameWinnerWindow,
    _LiveGameRegistration {
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
        if (_buildLiveStatusBanner() case final banner?) ...[VGap.xs, banner],
        if (_buildChainGameInfoStrip() case final chainStrip?) ...[
          VGap.xs,
          chainStrip,
        ],
        if (_buildChainInterRoundSummaryBanner() case final chainSummary?) ...[
          VGap.xs,
          chainSummary,
        ],
        if (_buildPostGameSummaryBanner() case final summaryBanner?) ...[
          VGap.xs,
          summaryBanner,
        ],
        if (_buildChainRoundWinnersBar() case final chainWinners?) ...[
          VGap.xs,
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
        if (_buildLiveStatusBanner() case final banner?) ...[banner, VGap.xs],
        if (_buildChainInterRoundSummaryBanner() case final chainSummary?) ...[
          chainSummary,
          VGap.xs,
        ],
        if (_buildPostGameSummaryBanner() case final summaryBanner?) ...[
          summaryBanner,
          VGap.xs,
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
