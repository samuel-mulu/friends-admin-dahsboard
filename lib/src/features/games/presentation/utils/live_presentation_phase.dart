import '../../data/models/called_number_model.dart';
import '../../data/models/game_model.dart';
import '../../../../core/utils/api_date_time.dart';

/// Derived UI-only phases for live game transitions. Backend game statuses are
/// unchanged; this layer only controls presentation and interaction gating.
enum LivePresentationPhase {
  /// No active or upcoming game in the operations snapshot.
  noActiveGame,

  registrationOpen,
  preparingGame,
  liveWaitingFirstBall,
  liveCalling,
  winnerWindow,
  /// Winner window countdown elapsed; waiting for in-flight claims before review.
  winnerWindowClosing,
  checking,
  review,
  cancelled,

  /// Cancelled specifically because nobody registered (AUTO skip). Presented
  /// as a calm "moving on" state instead of an error.
  noPlayersJoined,
}

extension LivePresentationPhaseX on LivePresentationPhase {
  bool get isRegistrationLayout =>
      this == LivePresentationPhase.registrationOpen ||
      this == LivePresentationPhase.preparingGame;

  bool get cartelaActionsEnabled =>
      this == LivePresentationPhase.registrationOpen;

  bool get isTerminalLayout =>
      this == LivePresentationPhase.review ||
      this == LivePresentationPhase.cancelled ||
      this == LivePresentationPhase.noPlayersJoined;

  bool get isCancelledTerminal =>
      this == LivePresentationPhase.cancelled ||
      this == LivePresentationPhase.noPlayersJoined;

  bool get keepsInlineCartelaLayout =>
      this == LivePresentationPhase.liveWaitingFirstBall ||
      this == LivePresentationPhase.liveCalling ||
      this == LivePresentationPhase.winnerWindow ||
      this == LivePresentationPhase.winnerWindowClosing ||
      this == LivePresentationPhase.checking ||
      isTerminalLayout;

  bool get isWinnerWindowLayout =>
      this == LivePresentationPhase.winnerWindow ||
      this == LivePresentationPhase.winnerWindowClosing;
}

bool registrationCountdownIsReopened({
  required GameModel game,
  required DateTime now,
  Duration futureThreshold = const Duration(seconds: 5),
}) {
  if (game.status != GameStatus.ready || !game.canRegister) {
    return false;
  }

  final scheduledStartAt = game.scheduledStartAt;
  return scheduledStartAt != null &&
      scheduledStartAt.isAfter(now.add(futureThreshold));
}

/// Backend registration deadline for the countdown banner, with stable display
/// after the local close latch fires (including during canonical refetch).
DateTime? resolveRegistrationCountdownDeadline({
  required GameModel game,
  required bool timingConfigLoaded,
  required bool isLoading,
  required bool registrationCountdownClosed,
  required bool canonicalRefetchInFlight,
  required String? countdownSessionId,
  required String sessionKey,
  required DateTime? countdownDeadline,
  bool postGameSummaryHoldActive = false,
  bool blockingLiveGameExists = false,
  DateTime? now,
}) {
  if (postGameSummaryHoldActive) {
    return null;
  }

  if (!timingConfigLoaded || isLoading || game.status != GameStatus.ready) {
    return null;
  }

  if (countdownSessionId != sessionKey) {
    return null;
  }

  if (blockingLiveGameExists && game.canRegister) {
    return null;
  }

  final clock = now ?? DateTime.now();

  if (canonicalRefetchInFlight && !registrationCountdownClosed) {
    return null;
  }

  if (registrationCountdownIsReopened(game: game, now: clock)) {
    return game.scheduledStartAt ?? countdownDeadline;
  }

  if (registrationCountdownClosed) {
    return countdownDeadline ?? clock;
  }

  if (canonicalRefetchInFlight) {
    return null;
  }

  return countdownDeadline;
}

/// Default post-game summary hold when timing config is unavailable (tests).
const int kPostGameSummaryHoldSeconds = 60;
const Duration kPostGameSummaryHold = Duration(
  seconds: kPostGameSummaryHoldSeconds,
);

Duration _phaseHoldRemaining({
  required DateTime shownAt,
  required DateTime now,
  required Duration minimumHold,
}) {
  final elapsed = now.difference(shownAt);
  final remaining = minimumHold - elapsed;
  return remaining.isNegative ? Duration.zero : remaining;
}

bool _phaseHoldElapsed({
  required DateTime? shownAt,
  required DateTime now,
  required Duration minimumHold,
}) {
  if (shownAt == null) {
    return true;
  }

  return now.difference(shownAt) >= minimumHold;
}

int _phaseHoldSecondsRemaining({
  required DateTime? shownAt,
  required DateTime now,
  required Duration minimumHold,
}) {
  if (shownAt == null) {
    return minimumHold.inSeconds;
  }

  final remaining = _phaseHoldRemaining(
    shownAt: shownAt,
    now: now,
    minimumHold: minimumHold,
  );
  return remaining.inSeconds.clamp(0, minimumHold.inSeconds);
}

Duration postGameSummaryRemainingHold({
  required DateTime shownAt,
  required DateTime now,
  Duration minimumHold = kPostGameSummaryHold,
}) {
  return _phaseHoldRemaining(
    shownAt: shownAt,
    now: now,
    minimumHold: minimumHold,
  );
}

bool postGameSummaryHoldElapsed({
  required DateTime? shownAt,
  required DateTime now,
  Duration minimumHold = kPostGameSummaryHold,
}) {
  return _phaseHoldElapsed(
    shownAt: shownAt,
    now: now,
    minimumHold: minimumHold,
  );
}

int postGameSummarySecondsRemaining({
  required DateTime? shownAt,
  required DateTime now,
  Duration minimumHold = kPostGameSummaryHold,
}) {
  return _phaseHoldSecondsRemaining(
    shownAt: shownAt,
    now: now,
    minimumHold: minimumHold,
  );
}

bool isWinnerWindowExpired({
  required GameStatus? status,
  required DateTime? windowEndsAt,
  DateTime? now,
}) {
  if (status != GameStatus.winnerWindow || windowEndsAt == null) {
    return false;
  }

  return !(now ?? DateTime.now()).isBefore(windowEndsAt);
}

/// True while the winner window countdown should be shown and claims are open.
bool isWinnerWindowActive({
  required GameStatus? status,
  required DateTime? windowEndsAt,
  DateTime? now,
}) {
  if (status != GameStatus.winnerWindow || windowEndsAt == null) {
    return false;
  }

  return (now ?? DateTime.now()).isBefore(windowEndsAt);
}

/// Post-game results banner (phase 2) only after winner window ends and game is
/// FINISHED — never during an active winner window.
bool canShowPostGameSummary({
  required GameStatus? status,
  required DateTime? windowEndsAt,
  required bool postGameSummaryReviewActive,
  DateTime? now,
}) {
  if (!postGameSummaryReviewActive) {
    return false;
  }

  if (isWinnerWindowActive(
    status: status,
    windowEndsAt: windowEndsAt,
    now: now,
  )) {
    return false;
  }

  return status == GameStatus.finished || status == GameStatus.noWinner;
}

/// Seconds left until registration closes from a backend [scheduledStartAt].
int registrationCountdownSecondsRemaining({
  required DateTime? scheduledStartAt,
  DateTime? now,
}) {
  return secondsUntilCeil(scheduledStartAt, now: now);
}

/// Seconds left in the winner window using ceiling rounding so the UI shows
/// 1s until the last millisecond before [windowEndsAt], then 0s.
int winnerWindowSecondsLeft(DateTime? windowEndsAt, {DateTime? now}) {
  return secondsUntilCeil(windowEndsAt, now: now);
}

/// How many seconds before the winner window closes to start preloading
/// canonical winner-results from the API.
const int winnerWindowWinnerResultsPreloadSeconds = 5;

/// Maximum wait after the winner window expires before forcing the finished UI.
const Duration kWinnerWindowClosingMaxWait = Duration(seconds: 8);

bool shouldPreloadWinnerResultsDuringWindow(
  DateTime? windowEndsAt, {
  DateTime? now,
}) {
  if (windowEndsAt == null) {
    return false;
  }

  final secondsLeft = winnerWindowSecondsLeft(windowEndsAt, now: now);
  return secondsLeft > 0 &&
      secondsLeft <= winnerWindowWinnerResultsPreloadSeconds;
}

bool canClaimDuringWinnerWindow(DateTime? windowEndsAt, {DateTime? now}) {
  return winnerWindowSecondsLeft(windowEndsAt, now: now) > 0;
}

class LivePresentationPhaseResolver {
  const LivePresentationPhaseResolver._();

  static bool registrationCountdownElapsed({
    required GameModel game,
    required bool registrationCountdownClosed,
    required Duration staleAfter,
    DateTime? now,
    bool blockingLiveGameExists = false,
  }) {
    final scheduledStartAt = game.scheduledStartAt;
    final currentTime = now ?? DateTime.now();

    // CRITICAL: If game already has balls called, registration countdown
    // is irrelevant - game is in play.
    if (game.calledNumbersCount > 0) {
      return true;
    }

    if (blockingLiveGameExists &&
        game.status == GameStatus.ready &&
        game.canRegister) {
      return false;
    }

    if (scheduledStartAt == null) {
      if (registrationCountdownClosed) {
        return true;
      }
      if (game.status == GameStatus.ready && !game.canRegister) {
        return true;
      }
      return false;
    }

    // A fresh registration window always wins over a stale local closed flag.
    // Only reopen if the new scheduledStartAt is significantly in the future.
    if (scheduledStartAt.isAfter(currentTime.add(const Duration(seconds: 5)))) {
      return false;
    }

    if (registrationCountdownClosed) {
      return true;
    }

    if (game.status == GameStatus.ready && !game.canRegister) {
      return true;
    }

    // Stale guard: a deadline that passed long ago belongs to a previous
    // round (e.g. right after advancing). Wait for the canonical refetch
    // instead of snapping into the preparing-game phase.
    if (currentTime.difference(scheduledStartAt) > staleAfter) {
      return false;
    }

    return game.status == GameStatus.ready &&
        game.canRegister &&
        !scheduledStartAt.isAfter(currentTime);
  }

  static LivePresentationPhase resolve({
    required GameModel? game,
    required bool registrationCountdownClosed,
    bool emptyRegistrationClosedNoPlayers = false,
    required bool canonicalRefetchInFlight,
    required List<CalledNumberModel> calledNumbers,
    required Duration staleAfter,
    bool blockingLiveGameExists = false,
    bool winnerWindowExpired = false,
    bool preparingTransitionActive = false,
  }) {
    if (game == null) {
      return LivePresentationPhase.noActiveGame;
    }

    if (game.status == GameStatus.winnerWindow) {
      return winnerWindowExpired
          ? LivePresentationPhase.winnerWindowClosing
          : LivePresentationPhase.winnerWindow;
    }

    if (game.status == GameStatus.checking) {
      return LivePresentationPhase.checking;
    }

    if (game.status == GameStatus.finished ||
        game.status == GameStatus.noWinner) {
      return LivePresentationPhase.review;
    }

    if (game.status == GameStatus.cancelled) {
      return game.cancelledReason == 'no_players'
          ? LivePresentationPhase.noPlayersJoined
          : LivePresentationPhase.cancelled;
    }

    if (emptyRegistrationClosedNoPlayers &&
        game.status == GameStatus.ready &&
        calledNumbers.isEmpty &&
        game.calledNumbersCount == 0) {
      return LivePresentationPhase.noPlayersJoined;
    }

    // Canonical refetch may already know the session is live while local
    // called-number state is still catching up.
    if (game.status == GameStatus.playing) {
      return calledNumbers.isEmpty && game.calledNumbersCount == 0
          ? LivePresentationPhase.liveWaitingFirstBall
          : LivePresentationPhase.liveCalling;
    }

    // Balls may arrive before status flips to PLAYING. Stay on preparing
    // while the closing-session lock is active so every device matches.
    if (game.status == GameStatus.ready &&
        (calledNumbers.isNotEmpty || game.calledNumbersCount > 0)) {
      if (preparingTransitionActive) {
        return LivePresentationPhase.preparingGame;
      }
      return LivePresentationPhase.liveCalling;
    }

    if (game.status == GameStatus.ready) {
      return _resolveRegistrationPhase(
        game: game,
        registrationCountdownClosed: registrationCountdownClosed,
        staleAfter: staleAfter,
        blockingLiveGameExists: blockingLiveGameExists,
      );
    }

    if (game.status == GameStatus.next) {
      return LivePresentationPhase.preparingGame;
    }

    return LivePresentationPhase.noActiveGame;
  }

  static LivePresentationPhase _resolveRegistrationPhase({
    required GameModel game,
    required bool registrationCountdownClosed,
    required Duration staleAfter,
    required bool blockingLiveGameExists,
  }) {
    if (!game.canRegister) {
      return LivePresentationPhase.preparingGame;
    }

    final countdownElapsed = registrationCountdownElapsed(
      game: game,
      registrationCountdownClosed: registrationCountdownClosed,
      staleAfter: staleAfter,
      blockingLiveGameExists: blockingLiveGameExists,
    );

    if (!countdownElapsed) {
      return LivePresentationPhase.registrationOpen;
    }

    return LivePresentationPhase.preparingGame;
  }
}
