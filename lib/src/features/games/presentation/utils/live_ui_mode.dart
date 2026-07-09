import '../../data/models/called_number_model.dart';
import '../../data/models/game_model.dart';
import 'live_presentation_phase.dart';
import 'live_ready_atomic_visibility.dart';
import 'live_ready_transition_lock.dart';

/// Flutter-only presentation modes. These are not backend statuses.
enum LiveUiMode {
  empty,
  registrationCountdown,
  registrationWaitingForCurrentGame,
  liveOwned,
  liveSpectator,
  missedRoundRegistration,
  checking,
  winnerWindow,
  reviewFinished,
  reviewNoWinner,
  cancelled,
  handoffOpeningNext,
}

/// Keys for centralized helper copy (mapped to l10n at the widget boundary).
enum LiveUiHelperKey {
  none,
  liveNoGame,
  liveMissedRound,
  registrationStartsAfterCurrentGame,
  liveJoinCurrentRound,
  liveAddMoreCartelas,
  preparingGameNoCartelas,
  postGameSummaryOpeningNext,
  gameNoPlayers,
  gameCancelled,
}

enum LiveUiCountdownKind {
  none,
  registration,
  nextBall,
  winnerWindow,
  postGameReview,
}

/// Explicit local holds that may affect presentation but never invent backend status.
class LiveSessionHolds {
  const LiveSessionHolds({
    this.postGameSummaryReviewActive = false,
    this.pinTerminalSession = false,
    this.registrationCountdownClosed = false,
    this.readyTransitionLock,
    this.canonicalRefetchInFlight = false,
    this.postGameSummaryAdvancing = false,
    this.registrationGridReady = true,
  });

  final bool postGameSummaryReviewActive;
  final bool pinTerminalSession;
  final bool registrationCountdownClosed;
  final ReadyTransitionLock? readyTransitionLock;
  final bool canonicalRefetchInFlight;
  final bool postGameSummaryAdvancing;
  final bool registrationGridReady;
}

class ResolveLiveUiModeInput {
  const ResolveLiveUiModeInput({
    this.operations,
    this.pinnedPrimaryGame,
    required this.ownsLiveSessionCartelas,
    required this.hasPrimarySessionCartelas,
    this.calledNumbers = const [],
    this.holds = const LiveSessionHolds(),
    required this.now,
    this.preparingStaleAfter = const Duration(seconds: 45),
    this.isGuest = false,
    this.isLoading = false,
    this.awaitingLiveRoom = false,
    this.hasError = false,
    this.winnerWindowExpired = false,
  });

  final GameOperationsCurrentResponse? operations;
  final GameModel? pinnedPrimaryGame;
  final bool ownsLiveSessionCartelas;
  final bool hasPrimarySessionCartelas;
  final List<CalledNumberModel> calledNumbers;
  final LiveSessionHolds holds;
  final DateTime now;
  final Duration preparingStaleAfter;
  final bool isGuest;
  final bool isLoading;
  final bool awaitingLiveRoom;
  final bool hasError;
  final bool winnerWindowExpired;
}

class LiveUiModeState {
  const LiveUiModeState({
    required this.mode,
    this.primaryGame,
    this.secondaryRegistrationGame,
    this.registrationTarget,
    required this.presentationPhase,
    required this.useRegistrationOpenLayout,
    required this.showsInlinePlayCartelas,
    required this.showCalledNumbersStrip,
    required this.showRegistrationGrid,
    required this.showReview,
    required this.hideRegistrationCountdown,
    required this.deferNextRoundRegistrationCountdown,
    required this.helperKey,
    required this.blocksRegistrationPromotion,
    required this.usesExpandedNoCartelaRegistrationLayout,
    required this.showMissedRoundWrapper,
    required this.countdownKind,
    required this.registrationOpenBodyTarget,
    required this.hasBlockingLiveGame,
    this.showsOwnedPreparingShell = false,
  });

  final LiveUiMode mode;
  final GameModel? primaryGame;
  final GameModel? secondaryRegistrationGame;
  final GameModel? registrationTarget;
  final LivePresentationPhase presentationPhase;
  final bool useRegistrationOpenLayout;
  final bool showsInlinePlayCartelas;
  final bool showCalledNumbersStrip;
  final bool showRegistrationGrid;
  final bool showReview;
  final bool hideRegistrationCountdown;
  final bool deferNextRoundRegistrationCountdown;
  final LiveUiHelperKey helperKey;
  final bool blocksRegistrationPromotion;
  final bool usesExpandedNoCartelaRegistrationLayout;
  final bool showMissedRoundWrapper;
  final LiveUiCountdownKind countdownKind;
  final GameModel? registrationOpenBodyTarget;
  final bool hasBlockingLiveGame;
  final bool showsOwnedPreparingShell;
}

class LiveUiModeResolver {
  const LiveUiModeResolver._();

  static LiveUiModeState resolve(ResolveLiveUiModeInput input) {
    final holds = input.holds;
    final operations = input.operations;
    final hasBlockingLiveGame =
        operations?.liveGame != null || operations?.checkingGame != null;
    final activeLock = _activeTransitionLock(input);

    if (activeLock != null) {
      return _buildForTransitionLock(
        input: input,
        lock: activeLock,
        hasBlockingLiveGame: hasBlockingLiveGame,
      );
    }

    final pinned = input.pinnedPrimaryGame;
    if (pinned != null &&
        (holds.pinTerminalSession || holds.postGameSummaryReviewActive)) {
      return _buildForPinnedTerminal(
        input: input,
        game: pinned,
        hasBlockingLiveGame: hasBlockingLiveGame,
      );
    }

    if (operations == null || !operations.hasActiveGame) {
      return _emptyState(input);
    }

    final ownsLiveCartelas = input.ownsLiveSessionCartelas;
    final primaryFromOps = resolvePrimaryGameForOperationsWithTransitionLock(
      operations: operations,
      ownsLiveCartelas: ownsLiveCartelas,
      lock: null,
      now: input.now,
    );

    if (primaryFromOps == null) {
      return _emptyState(input);
    }

    final liveGame = operations.liveGame;
    final registrationGame = operations.registrationOpenGame;

    if (_isMissedRoundRegistration(
      liveGame: liveGame,
      registrationGame: registrationGame,
      primary: primaryFromOps,
      ownsLiveSessionCartelas: ownsLiveCartelas,
    )) {
      return _buildMissedRoundRegistration(
        input: input,
        primary: primaryFromOps,
        hasBlockingLiveGame: hasBlockingLiveGame,
      );
    }

    return _buildForPrimaryGame(
      input: input,
      primary: primaryFromOps,
      operations: operations,
      hasBlockingLiveGame: hasBlockingLiveGame,
      ownsLiveCartelas: ownsLiveCartelas,
    );
  }

  static ReadyTransitionLock? _activeTransitionLock(
    ResolveLiveUiModeInput input,
  ) {
    return input.holds.readyTransitionLock;
  }

  static bool _preparingTransitionActive(ResolveLiveUiModeInput input) {
    final lock = input.holds.readyTransitionLock;
    return lock != null && lock.isPreparingToPlay;
  }

  static LivePresentationPhase _resolvePresentationPhase(
    ResolveLiveUiModeInput input, {
    required GameModel game,
    required bool registrationCountdownClosed,
    required bool hasBlockingLiveGame,
  }) {
    return LivePresentationPhaseResolver.resolve(
      game: game,
      registrationCountdownClosed: registrationCountdownClosed,
      canonicalRefetchInFlight: input.holds.canonicalRefetchInFlight,
      calledNumbers: input.calledNumbers,
      staleAfter: input.preparingStaleAfter,
      blockingLiveGameExists: hasBlockingLiveGame,
      winnerWindowExpired: input.winnerWindowExpired,
      preparingTransitionActive: _preparingTransitionActive(input),
    );
  }

  static bool _showsOwnedPreparingShell({
    required LiveUiMode mode,
    required LivePresentationPhase presentationPhase,
    required bool hasPrimarySessionCartelas,
  }) {
    return hasPrimarySessionCartelas &&
        mode == LiveUiMode.registrationWaitingForCurrentGame &&
        presentationPhase == LivePresentationPhase.preparingGame;
  }

  static bool _registrationOpenGameBeatsTransitionLock(
    ResolveLiveUiModeInput input,
  ) {
    final lock = input.holds.readyTransitionLock;
    if (lock != null && lock.isActiveAt(input.now)) {
      return false;
    }
    return registrationOpenGameSupersedesTransitionLock(
      registrationOpenGame: input.operations?.registrationOpenGame,
      lockedSessionId: lock?.sessionId,
      lockReason: lock?.reason,
      now: input.now,
    );
  }

  static bool _effectiveRegistrationCountdownClosed(
    ResolveLiveUiModeInput input,
  ) {
    if (_registrationOpenGameBeatsTransitionLock(input)) {
      return false;
    }

    final registration = input.operations?.registrationOpenGame;
    final activeLock = _activeTransitionLock(input);
    if (activeLock == null &&
        registration != null &&
        registrationCountdownIsReopened(game: registration, now: input.now)) {
      return false;
    }

    final snapshot = activeLock?.snapshotGame;
    if (snapshot != null &&
        registrationCountdownIsReopened(game: snapshot, now: input.now)) {
      return false;
    }

    return input.holds.registrationCountdownClosed;
  }

  static LiveUiModeState _buildForTransitionLock({
    required ResolveLiveUiModeInput input,
    required ReadyTransitionLock lock,
    required bool hasBlockingLiveGame,
  }) {
    final operations = input.operations;
    final ownsLiveCartelas = input.ownsLiveSessionCartelas;

    if (lock.isNoPlayersHandoff &&
        operations != null &&
        registrationOpenGameSupersedesTransitionLock(
          registrationOpenGame: operations.registrationOpenGame,
          lockedSessionId: lock.sessionId,
          lockReason: lock.reason,
          now: input.now,
        )) {
      final primary = resolvePrimaryGameForOperationsWithTransitionLock(
        operations: operations,
        ownsLiveCartelas: ownsLiveCartelas,
        lock: null,
        now: input.now,
      );
      if (primary != null) {
        return _buildForPrimaryGame(
          input: input,
          primary: primary,
          operations: operations,
          hasBlockingLiveGame: hasBlockingLiveGame,
          ownsLiveCartelas: ownsLiveCartelas,
        );
      }
    }

    final snapshot = lock.snapshotGame;
    if (lock.isNoPlayersHandoff) {
      return _buildForHandoff(
        input: input,
        game: snapshot,
        hasBlockingLiveGame: hasBlockingLiveGame,
      );
    }

    final primary = operations == null
        ? snapshot
        : resolvePrimaryGameForOperationsWithTransitionLock(
            operations: operations,
            ownsLiveCartelas: ownsLiveCartelas,
            lock: lock,
            now: input.now,
          ) ??
            snapshot;

    if (operations == null) {
      final presentationPhase = _resolvePresentationPhase(
        input,
        game: primary,
        registrationCountdownClosed: true,
        hasBlockingLiveGame: hasBlockingLiveGame,
      );
      final mode =
          presentationPhase == LivePresentationPhase.preparingGame
              ? LiveUiMode.registrationWaitingForCurrentGame
              : LiveUiMode.registrationCountdown;
      final showsOwnedPreparingShell = _showsOwnedPreparingShell(
        mode: mode,
        presentationPhase: presentationPhase,
        hasPrimarySessionCartelas: input.hasPrimarySessionCartelas,
      );
      final useRegistrationOpenLayoutBase =
          !showsOwnedPreparingShell && !_screenBlocked(input);
      final wantsRegistrationSurfaces =
          useRegistrationOpenLayoutBase && !input.isGuest;
      final readyAtomic = resolveReadyAtomicVisibility(
        hasReadyGame: wantsRegistrationSurfaces && primary != null,
        gridReady: input.holds.registrationGridReady &&
            !input.holds.canonicalRefetchInFlight,
        holdingPreviousReady: input.holds.postGameSummaryAdvancing &&
            input.holds.canonicalRefetchInFlight,
      );
      final showRegistrationSurfaces =
          readyAtomic.showBanner && readyAtomic.showGrid;

      return LiveUiModeState(
        mode: mode,
        primaryGame: primary,
        secondaryRegistrationGame: null,
        registrationTarget: primary,
        presentationPhase: presentationPhase,
        useRegistrationOpenLayout:
            useRegistrationOpenLayoutBase && showRegistrationSurfaces,
        showsInlinePlayCartelas: false,
        showCalledNumbersStrip: false,
        showRegistrationGrid: showRegistrationSurfaces,
        showReview: false,
        hideRegistrationCountdown: true,
        deferNextRoundRegistrationCountdown: false,
        helperKey: mode == LiveUiMode.registrationWaitingForCurrentGame
            ? LiveUiHelperKey.preparingGameNoCartelas
            : LiveUiHelperKey.none,
        blocksRegistrationPromotion: false,
        usesExpandedNoCartelaRegistrationLayout: false,
        showMissedRoundWrapper: false,
        countdownKind: LiveUiCountdownKind.none,
        registrationOpenBodyTarget: useRegistrationOpenLayoutBase &&
                showRegistrationSurfaces
            ? primary
            : null,
        hasBlockingLiveGame: hasBlockingLiveGame,
        showsOwnedPreparingShell: showsOwnedPreparingShell,
      );
    }

    return _buildForPrimaryGame(
      input: input,
      primary: primary,
      operations: operations,
      hasBlockingLiveGame: hasBlockingLiveGame,
      ownsLiveCartelas: ownsLiveCartelas,
    );
  }

  static bool _isMissedRoundRegistration({
    required GameModel? liveGame,
    required GameModel? registrationGame,
    required GameModel primary,
    required bool ownsLiveSessionCartelas,
  }) {
    if (liveGame == null || registrationGame == null || ownsLiveSessionCartelas) {
      return false;
    }
    return primary.status == GameStatus.ready &&
        primary.sessionId == registrationGame.sessionId &&
        liveGame.status == GameStatus.playing;
  }

  static LiveUiModeState _emptyState(ResolveLiveUiModeInput input) {
    return LiveUiModeState(
      mode: LiveUiMode.empty,
      primaryGame: null,
      secondaryRegistrationGame: null,
      registrationTarget: null,
      presentationPhase: LivePresentationPhase.noActiveGame,
      useRegistrationOpenLayout: false,
      showsInlinePlayCartelas: false,
      showCalledNumbersStrip: false,
      showRegistrationGrid: false,
      showReview: false,
      hideRegistrationCountdown: true,
      deferNextRoundRegistrationCountdown: false,
      helperKey: LiveUiHelperKey.liveNoGame,
      blocksRegistrationPromotion: false,
      usesExpandedNoCartelaRegistrationLayout: false,
      showMissedRoundWrapper: false,
      countdownKind: LiveUiCountdownKind.none,
      registrationOpenBodyTarget: null,
      hasBlockingLiveGame: false,
    );
  }

  static LiveUiModeState _buildForHandoff({
    required ResolveLiveUiModeInput input,
    required GameModel? game,
    required bool hasBlockingLiveGame,
  }) {
    final presentationPhase = game == null
        ? LivePresentationPhase.preparingGame
        : _resolvePresentationPhase(
            input,
            game: game,
            registrationCountdownClosed: true,
            hasBlockingLiveGame: hasBlockingLiveGame,
          );

    return LiveUiModeState(
      mode: LiveUiMode.handoffOpeningNext,
      primaryGame: game,
      secondaryRegistrationGame: null,
      registrationTarget: game,
      presentationPhase: presentationPhase,
      useRegistrationOpenLayout: game != null && !_screenBlocked(input),
      showsInlinePlayCartelas: false,
      showCalledNumbersStrip: false,
      showRegistrationGrid: game != null,
      showReview: false,
      hideRegistrationCountdown: true,
      deferNextRoundRegistrationCountdown: false,
      helperKey: LiveUiHelperKey.postGameSummaryOpeningNext,
      blocksRegistrationPromotion: false,
      usesExpandedNoCartelaRegistrationLayout: false,
      showMissedRoundWrapper: false,
      countdownKind: LiveUiCountdownKind.none,
      registrationOpenBodyTarget: game,
      hasBlockingLiveGame: hasBlockingLiveGame,
    );
  }

  static LiveUiModeState _buildForPinnedTerminal({
    required ResolveLiveUiModeInput input,
    required GameModel game,
    required bool hasBlockingLiveGame,
  }) {
    final mode = game.status == GameStatus.noWinner
        ? LiveUiMode.reviewNoWinner
        : LiveUiMode.reviewFinished;
    final presentationPhase = _resolvePresentationPhase(
      input,
      game: game,
      registrationCountdownClosed: input.holds.registrationCountdownClosed,
      hasBlockingLiveGame: hasBlockingLiveGame,
    );
    final blocksPromotion = _blocksRegistrationPromotion(
      input: input,
      game: game,
      presentationPhase: presentationPhase,
    );

    return LiveUiModeState(
      mode: mode,
      primaryGame: game,
      secondaryRegistrationGame: input.operations?.registrationOpenGame,
      registrationTarget: null,
      presentationPhase: presentationPhase,
      useRegistrationOpenLayout: false,
      showsInlinePlayCartelas: presentationPhase.keepsInlineCartelaLayout &&
          !presentationPhase.isCancelledTerminal,
      showCalledNumbersStrip: presentationPhase.keepsInlineCartelaLayout,
      showRegistrationGrid: false,
      showReview: input.holds.postGameSummaryReviewActive,
      hideRegistrationCountdown: true,
      deferNextRoundRegistrationCountdown: true,
      helperKey: LiveUiHelperKey.none,
      blocksRegistrationPromotion: blocksPromotion,
      usesExpandedNoCartelaRegistrationLayout: false,
      showMissedRoundWrapper: false,
      countdownKind: input.holds.postGameSummaryReviewActive
          ? LiveUiCountdownKind.postGameReview
          : LiveUiCountdownKind.none,
      registrationOpenBodyTarget: null,
      hasBlockingLiveGame: hasBlockingLiveGame,
    );
  }

  static LiveUiModeState _buildMissedRoundRegistration({
    required ResolveLiveUiModeInput input,
    required GameModel primary,
    required bool hasBlockingLiveGame,
  }) {
    final presentationPhase = LivePresentationPhase.registrationOpen;
    return LiveUiModeState(
      mode: LiveUiMode.missedRoundRegistration,
      primaryGame: primary,
      secondaryRegistrationGame: null,
      registrationTarget: primary,
      presentationPhase: presentationPhase,
      useRegistrationOpenLayout: !_screenBlocked(input),
      showsInlinePlayCartelas: false,
      showCalledNumbersStrip: false,
      showRegistrationGrid: !input.isGuest,
      showReview: false,
      hideRegistrationCountdown: true,
      deferNextRoundRegistrationCountdown: true,
      helperKey: LiveUiHelperKey.liveMissedRound,
      blocksRegistrationPromotion: false,
      usesExpandedNoCartelaRegistrationLayout: false,
      showMissedRoundWrapper: !input.isGuest,
      countdownKind: LiveUiCountdownKind.none,
      registrationOpenBodyTarget: primary,
      hasBlockingLiveGame: hasBlockingLiveGame,
    );
  }

  static LiveUiModeState _buildForPrimaryGame({
    required ResolveLiveUiModeInput input,
    required GameModel primary,
    required GameOperationsCurrentResponse operations,
    required bool hasBlockingLiveGame,
    required bool ownsLiveCartelas,
  }) {
    final nextUpcoming = operations.nextUpcomingGameFor(current: primary);
    final presentationPhase = _resolvePresentationPhase(
      input,
      game: primary,
      registrationCountdownClosed: _effectiveRegistrationCountdownClosed(input),
      hasBlockingLiveGame: hasBlockingLiveGame,
    );

    final mode = _modeForPrimary(
      primary: primary,
      presentationPhase: presentationPhase,
      ownsLiveCartelas: ownsLiveCartelas,
      hasPrimarySessionCartelas: input.hasPrimarySessionCartelas,
    );

    final secondaryRegistration =
        _secondaryRegistrationGame(
          mode: mode,
          operations: operations,
          primary: primary,
        );

    final registrationTarget = _registrationTarget(
      primary: primary,
      nextUpcoming: nextUpcoming,
      hasPrimarySessionCartelas: input.hasPrimarySessionCartelas,
      mode: mode,
      secondaryRegistration: secondaryRegistration,
    );

    final blocksPromotion = _blocksRegistrationPromotion(
      input: input,
      game: primary,
      presentationPhase: presentationPhase,
    );

    final registrationTargetIsCurrent = _isSameRound(
      registrationTarget,
      primary,
    );

    final hideRegistrationCountdown = _hideRegistrationCountdown(
      mode: mode,
      hasBlockingLiveGame: hasBlockingLiveGame,
      primary: primary,
      registrationTargetIsCurrent: registrationTargetIsCurrent,
      hasSecondaryRegistration: secondaryRegistration != null,
    );

    final deferNextRoundCountdown = _deferNextRoundCountdown(
      mode: mode,
      registrationTargetIsCurrent: registrationTargetIsCurrent,
    );

    final useRegistrationOpenLayoutBase = _useRegistrationOpenLayout(
      input: input,
      mode: mode,
      primary: primary,
      registrationTarget: registrationTarget,
      blocksPromotion: blocksPromotion,
      registrationTargetIsCurrent: registrationTargetIsCurrent,
      presentationPhase: presentationPhase,
    );
    final showsOwnedPreparingShell = _showsOwnedPreparingShell(
      mode: mode,
      presentationPhase: presentationPhase,
      hasPrimarySessionCartelas: input.hasPrimarySessionCartelas,
    );
    final useRegistrationOpenLayout = showsOwnedPreparingShell
        ? false
        : useRegistrationOpenLayoutBase;

    final showsInlinePlay = _showsInlinePlayCartelas(mode, presentationPhase);
    final registrationOpenBodyTarget = useRegistrationOpenLayout
        ? (mode == LiveUiMode.missedRoundRegistration
              ? primary
              : (registrationTarget ?? primary))
        : null;

    final wantsRegistrationSurfaces =
        useRegistrationOpenLayout && _showRegistrationGrid(mode, input.isGuest);
    final readyAtomic = resolveReadyAtomicVisibility(
      hasReadyGame: wantsRegistrationSurfaces,
      gridReady: input.holds.registrationGridReady &&
          !input.holds.canonicalRefetchInFlight,
      holdingPreviousReady: input.holds.postGameSummaryAdvancing &&
          input.holds.canonicalRefetchInFlight,
    );
    final showRegistrationSurfaces = readyAtomic.showBanner && readyAtomic.showGrid;

    return LiveUiModeState(
      mode: mode,
      primaryGame: primary,
      secondaryRegistrationGame: secondaryRegistration,
      registrationTarget: registrationTarget,
      presentationPhase: presentationPhase,
      useRegistrationOpenLayout:
          useRegistrationOpenLayout && showRegistrationSurfaces,
      showsInlinePlayCartelas: showsInlinePlay,
      showCalledNumbersStrip: showsInlinePlay && !primary.isRegistrationOpen,
      showRegistrationGrid: showRegistrationSurfaces,
      showReview: mode == LiveUiMode.reviewFinished ||
          mode == LiveUiMode.reviewNoWinner,
      hideRegistrationCountdown: hideRegistrationCountdown,
      deferNextRoundRegistrationCountdown: deferNextRoundCountdown,
      helperKey: _helperKey(
        mode: mode,
        primary: primary,
        hasSecondaryRegistration: secondaryRegistration != null,
        hasPrimarySessionCartelas: input.hasPrimarySessionCartelas,
        registrationTargetIsCurrent: registrationTargetIsCurrent,
        presentationPhase: presentationPhase,
        hideRegistrationCountdown: hideRegistrationCountdown,
      ),
      blocksRegistrationPromotion: blocksPromotion,
      usesExpandedNoCartelaRegistrationLayout: false,
      showMissedRoundWrapper:
          mode == LiveUiMode.missedRoundRegistration && showRegistrationSurfaces,
      countdownKind: _countdownKind(mode, presentationPhase, input.holds),
      registrationOpenBodyTarget:
          showRegistrationSurfaces ? registrationOpenBodyTarget : null,
      hasBlockingLiveGame: hasBlockingLiveGame,
      showsOwnedPreparingShell: showsOwnedPreparingShell,
    );
  }

  static LiveUiMode _modeForPrimary({
    required GameModel primary,
    required LivePresentationPhase presentationPhase,
    required bool ownsLiveCartelas,
    required bool hasPrimarySessionCartelas,
  }) {
    return switch (primary.status) {
      GameStatus.ready =>
        presentationPhase == LivePresentationPhase.preparingGame
            ? LiveUiMode.registrationWaitingForCurrentGame
            : LiveUiMode.registrationCountdown,
      GameStatus.playing =>
        hasPrimarySessionCartelas || ownsLiveCartelas
            ? LiveUiMode.liveOwned
            : LiveUiMode.liveSpectator,
      GameStatus.checking => LiveUiMode.checking,
      GameStatus.winnerWindow => LiveUiMode.winnerWindow,
      GameStatus.finished => LiveUiMode.reviewFinished,
      GameStatus.noWinner => LiveUiMode.reviewNoWinner,
      GameStatus.cancelled =>
        primary.cancelledReason == 'no_players'
            ? LiveUiMode.handoffOpeningNext
            : LiveUiMode.cancelled,
      _ => LiveUiMode.empty,
    };
  }

  static GameModel? _secondaryRegistrationGame({
    required LiveUiMode mode,
    required GameOperationsCurrentResponse operations,
    required GameModel primary,
  }) {
    final registration = operations.registrationOpenGame;
    if (registration == null) {
      return null;
    }
    if (mode == LiveUiMode.liveOwned &&
        primary.status == GameStatus.playing &&
        !_isSameRound(registration, primary)) {
      return registration;
    }
    return null;
  }

  static GameModel? _registrationTarget({
    required GameModel primary,
    required GameModel? nextUpcoming,
    required bool hasPrimarySessionCartelas,
    required LiveUiMode mode,
    required GameModel? secondaryRegistration,
  }) {
    if (mode == LiveUiMode.missedRoundRegistration) {
      return primary;
    }
    if (primary.status == GameStatus.playing && hasPrimarySessionCartelas) {
      return primary;
    }
    if (primary.status == GameStatus.ready && primary.canRegister) {
      return primary;
    }
    if (!hasPrimarySessionCartelas &&
        secondaryRegistration != null &&
        secondaryRegistration.canRegister) {
      return secondaryRegistration;
    }
    if (!hasPrimarySessionCartelas &&
        nextUpcoming != null &&
        nextUpcoming.status == GameStatus.ready &&
        nextUpcoming.canRegister) {
      return nextUpcoming;
    }
    return null;
  }

  static bool _blocksRegistrationPromotion({
    required ResolveLiveUiModeInput input,
    required GameModel game,
    required LivePresentationPhase presentationPhase,
  }) {
    if (presentationPhase.isCancelledTerminal) {
      return false;
    }
    if (input.holds.postGameSummaryReviewActive) {
      return true;
    }
    if (presentationPhase == LivePresentationPhase.review) {
      return true;
    }
    if (game.status == GameStatus.finished ||
        game.status == GameStatus.noWinner) {
      return true;
    }
    if (game.status == GameStatus.winnerWindow && input.winnerWindowExpired) {
      return true;
    }
    return false;
  }

  static bool _hideRegistrationCountdown({
    required LiveUiMode mode,
    required bool hasBlockingLiveGame,
    required GameModel primary,
    required bool registrationTargetIsCurrent,
    required bool hasSecondaryRegistration,
  }) {
    if (mode == LiveUiMode.missedRoundRegistration) {
      return true;
    }
    if (mode == LiveUiMode.liveOwned && hasSecondaryRegistration) {
      return true;
    }
    if (hasBlockingLiveGame &&
        primary.status == GameStatus.ready &&
        primary.canRegister) {
      return true;
    }
    if (!registrationTargetIsCurrent &&
        (mode == LiveUiMode.liveOwned ||
            mode == LiveUiMode.checking ||
            mode == LiveUiMode.winnerWindow)) {
      return true;
    }
    return false;
  }

  static bool _deferNextRoundCountdown({
    required LiveUiMode mode,
    required bool registrationTargetIsCurrent,
  }) {
    if (registrationTargetIsCurrent) {
      return false;
    }
    return switch (mode) {
      LiveUiMode.liveOwned ||
      LiveUiMode.liveSpectator ||
      LiveUiMode.checking ||
      LiveUiMode.winnerWindow => true,
      _ => false,
    };
  }

  static bool _useRegistrationOpenLayout({
    required ResolveLiveUiModeInput input,
    required LiveUiMode mode,
    required GameModel primary,
    required GameModel? registrationTarget,
    required bool blocksPromotion,
    required bool registrationTargetIsCurrent,
    required LivePresentationPhase presentationPhase,
  }) {
    if (_screenBlocked(input)) {
      return false;
    }
    if (input.holds.pinTerminalSession ||
        input.holds.postGameSummaryReviewActive) {
      return false;
    }

    if (mode == LiveUiMode.missedRoundRegistration ||
        mode == LiveUiMode.handoffOpeningNext) {
      return true;
    }

    if (mode == LiveUiMode.registrationCountdown ||
        mode == LiveUiMode.registrationWaitingForCurrentGame) {
      if (mode == LiveUiMode.registrationWaitingForCurrentGame &&
          input.hasPrimarySessionCartelas &&
          presentationPhase == LivePresentationPhase.preparingGame) {
        return false;
      }
      return presentationPhase.isRegistrationLayout;
    }

    if (!input.isGuest &&
        !input.hasPrimarySessionCartelas &&
        presentationPhase.isTerminalLayout &&
        !blocksPromotion &&
        !registrationTargetIsCurrent &&
        registrationTarget != null &&
        registrationTarget.status == GameStatus.ready &&
        registrationTarget.canRegister) {
      return true;
    }

    return false;
  }

  static bool _showsInlinePlayCartelas(
    LiveUiMode mode,
    LivePresentationPhase presentationPhase,
  ) {
    if (presentationPhase.isCancelledTerminal) {
      return false;
    }
    return switch (mode) {
      LiveUiMode.liveOwned ||
      LiveUiMode.liveSpectator ||
      LiveUiMode.checking ||
      LiveUiMode.winnerWindow ||
      LiveUiMode.reviewFinished ||
      LiveUiMode.reviewNoWinner => presentationPhase.keepsInlineCartelaLayout,
      _ => false,
    };
  }

  static bool _showRegistrationGrid(LiveUiMode mode, bool isGuest) {
    if (isGuest) {
      return false;
    }
    return switch (mode) {
      LiveUiMode.registrationCountdown ||
      LiveUiMode.registrationWaitingForCurrentGame ||
      LiveUiMode.missedRoundRegistration ||
      LiveUiMode.handoffOpeningNext => true,
      _ => false,
    };
  }

  static LiveUiHelperKey _helperKey({
    required LiveUiMode mode,
    required GameModel primary,
    required bool hasSecondaryRegistration,
    required bool hasPrimarySessionCartelas,
    required bool registrationTargetIsCurrent,
    required LivePresentationPhase presentationPhase,
    required bool hideRegistrationCountdown,
  }) {
    if (primary.status == GameStatus.cancelled &&
        primary.cancelledReason == 'no_players') {
      return LiveUiHelperKey.gameNoPlayers;
    }
    if (mode == LiveUiMode.liveOwned && hasSecondaryRegistration) {
      return LiveUiHelperKey.registrationStartsAfterCurrentGame;
    }
    return switch (mode) {
      LiveUiMode.empty => LiveUiHelperKey.liveNoGame,
      LiveUiMode.missedRoundRegistration => LiveUiHelperKey.liveMissedRound,
      LiveUiMode.handoffOpeningNext =>
        LiveUiHelperKey.postGameSummaryOpeningNext,
      LiveUiMode.registrationWaitingForCurrentGame =>
        LiveUiHelperKey.preparingGameNoCartelas,
      LiveUiMode.registrationCountdown when hideRegistrationCountdown =>
        LiveUiHelperKey.registrationStartsAfterCurrentGame,
      LiveUiMode.liveOwned when registrationTargetIsCurrent &&
              !hasPrimarySessionCartelas =>
        LiveUiHelperKey.liveJoinCurrentRound,
      LiveUiMode.liveOwned when registrationTargetIsCurrent &&
              hasPrimarySessionCartelas =>
        LiveUiHelperKey.liveAddMoreCartelas,
      LiveUiMode.cancelled => LiveUiHelperKey.gameCancelled,
      _ => LiveUiHelperKey.none,
    };
  }

  static LiveUiCountdownKind _countdownKind(
    LiveUiMode mode,
    LivePresentationPhase presentationPhase,
    LiveSessionHolds holds,
  ) {
    if (holds.postGameSummaryReviewActive) {
      return LiveUiCountdownKind.postGameReview;
    }
    return switch (mode) {
      LiveUiMode.registrationCountdown when presentationPhase ==
              LivePresentationPhase.registrationOpen =>
        LiveUiCountdownKind.registration,
      LiveUiMode.winnerWindow
          when presentationPhase == LivePresentationPhase.winnerWindow =>
        LiveUiCountdownKind.winnerWindow,
      LiveUiMode.liveOwned || LiveUiMode.liveSpectator =>
        LiveUiCountdownKind.nextBall,
      _ => LiveUiCountdownKind.none,
    };
  }

  static bool _screenBlocked(ResolveLiveUiModeInput input) {
    return input.awaitingLiveRoom || input.isLoading || input.hasError;
  }

  static bool _isSameRound(GameModel? a, GameModel? b) {
    if (a == null || b == null) {
      return false;
    }
    if (a.id == b.id) {
      return true;
    }
    final aSession = a.sessionId;
    final bSession = b.sessionId;
    return aSession != null && bSession != null && aSession == bSession;
  }
}

/// Maps resolver helper keys to localized copy.
String liveUiHelperText({
  required LiveUiHelperKey key,
  required String liveNoGameMessage,
  required String liveMissedRoundHelper,
  required String registrationStartsAfterCurrentGame,
  required String liveJoinCurrentRoundHelper,
  required String liveAddMoreCartelasHelper,
  required String preparingGameNoCartelas,
  required String postGameSummaryOpeningNextRound,
  required String gameNoPlayersMessage,
  required String gameCancelledMessage,
}) {
  return switch (key) {
    LiveUiHelperKey.none => '',
    LiveUiHelperKey.liveNoGame => liveNoGameMessage,
    LiveUiHelperKey.liveMissedRound => liveMissedRoundHelper,
    LiveUiHelperKey.registrationStartsAfterCurrentGame =>
      registrationStartsAfterCurrentGame,
    LiveUiHelperKey.liveJoinCurrentRound => liveJoinCurrentRoundHelper,
    LiveUiHelperKey.liveAddMoreCartelas => liveAddMoreCartelasHelper,
    LiveUiHelperKey.preparingGameNoCartelas => preparingGameNoCartelas,
    LiveUiHelperKey.postGameSummaryOpeningNext =>
      postGameSummaryOpeningNextRound,
    LiveUiHelperKey.gameNoPlayers => gameNoPlayersMessage,
    LiveUiHelperKey.gameCancelled => gameCancelledMessage,
  };
}

/// Top-level alias for screen wiring.
LiveUiModeState resolveLiveUiMode(ResolveLiveUiModeInput input) {
  return LiveUiModeResolver.resolve(input);
}
