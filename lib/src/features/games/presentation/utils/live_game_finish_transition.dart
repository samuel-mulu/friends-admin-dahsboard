import '../../data/models/game_model.dart';
import 'big_game_live_presentation.dart' as big_game_advance;

/// Whether a FINISHED or NO_WINNER transition should run terminal side effects.
bool shouldRunFinishTransition({
  required GameStatus? currentStatus,
  required bool sessionRoomActive,
  required bool summaryScheduled,
}) {
  if (currentStatus == null) {
    return false;
  }
  if (currentStatus != GameStatus.finished &&
      currentStatus != GameStatus.noWinner) {
    return true;
  }
  return sessionRoomActive || !summaryScheduled;
}

/// Whether a CANCELLED transition should run terminal side effects.
bool shouldRunCancelTransition({
  required GameStatus? currentStatus,
  required bool sessionRoomActive,
}) {
  if (currentStatus == null) {
    return false;
  }
  if (currentStatus != GameStatus.cancelled) {
    return true;
  }
  return sessionRoomActive;
}

bool isTerminalGameStatus(GameStatus status) {
  return status == GameStatus.finished ||
      status == GameStatus.noWinner ||
      status == GameStatus.cancelled;
}

bool isAdvanceRegistrationEligible({
  required GameModel next,
  required bool embeddedBigGame,
  required DateTime now,
}) {
  if (next.status != GameStatus.ready) {
    return false;
  }
  if (embeddedBigGame && next.isBigGame) {
    return big_game_advance.liveRegistrationEligible(
      game: next,
      now: now,
      embeddedBigGame: true,
    );
  }
  return next.canRegister;
}

/// True when ops exposes a different READY session the player can register for.
///
/// Embedded Big Game: also true while the slot has later rounds even if Round
/// N+1 is not READY yet — drives 60s summary + Continue like a normal finish.
bool hasPlayableAdvanceTarget({
  required GameOperationsCurrentResponse? operations,
  required GameModel terminalGame,
  bool embeddedBigGame = false,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  if (embeddedBigGame && terminalGame.isBigGame) {
    if (operations != null) {
      final resolved = operations.resolveAdvanceTargetFor(
        terminalGame: terminalGame,
      );
      if (resolved != null &&
          isAdvanceRegistrationEligible(
            next: resolved,
            embeddedBigGame: true,
            now: clock,
          )) {
        return true;
      }
    }
    return big_game_advance.bigGameSlotHasMoreRoundsAfterTerminal(terminalGame);
  }
  if (operations == null) {
    return false;
  }
  final next = operations.resolveAdvanceTargetFor(terminalGame: terminalGame);
  return next != null &&
      isAdvanceRegistrationEligible(
        next: next,
        embeddedBigGame: embeddedBigGame,
        now: clock,
      );
}

/// Keeps the current session on screen during finished review instead of
/// swapping to the next registration session from a canonical refetch.
bool shouldPinTerminalSession({
  required GameStatus? status,
  required bool postGameSummaryReviewActive,
}) {
  if (postGameSummaryReviewActive) {
    return true;
  }

  return switch (status) {
    GameStatus.finished => true,
    GameStatus.noWinner => true,
    // Cancelled has no post-game summary; pinning forever blocks empty Live.
    // Ready-transition lock covers brief no_players → next READY handoff.
    GameStatus.cancelled => false,
    GameStatus.winnerWindow => true,
    _ => false,
  };
}

/// Hold terminal/review paint until the backend opens the next READY registration
/// or a new live session appears in operations.
///
/// After post-game summary is dismissed with no next game, [releaseTerminalHold]
/// must be true so Live can show the real empty state instead of pinning forever.
/// While summary/advance is active, a brief ops null gap still holds paint.
bool shouldHoldTerminalPaint({
  required GameModel? priorGame,
  required GameOperationsCurrentResponse? operations,
  bool postGameSummaryActive = false,
  bool releaseTerminalHold = false,
}) {
  if (priorGame == null || releaseTerminalHold) {
    return false;
  }

  if (priorGame.status == GameStatus.winnerWindow) {
    final live = operations?.liveGame;
    if (live != null && live.sessionId == priorGame.sessionId) {
      if (live.status == GameStatus.winnerWindow ||
          live.status == GameStatus.finished ||
          live.status == GameStatus.noWinner) {
        return false;
      }
      // Chain Game: the same session goes PLAYING between rounds. Holding
      // winner-window paint here would keep the Game Finished card up.
      if (priorGame.isChainGame && live.status == GameStatus.playing) {
        return false;
      }
      return true;
    }

    final registration = operations?.registrationOpenGame;
    if (registration != null &&
        registration.sessionId != priorGame.sessionId &&
        registration.status == GameStatus.ready) {
      return false;
    }

    return true;
  }

  if (!isTerminalGameStatus(priorGame.status)) {
    return false;
  }

  if (operations?.registrationOpenGame != null) {
    return false;
  }

  final live = operations?.liveGame;
  if (live != null &&
      live.sessionId != priorGame.sessionId &&
      (live.status == GameStatus.playing ||
          live.status == GameStatus.checking ||
          live.status == GameStatus.winnerWindow)) {
    return false;
  }

  // Bridge only the transient ops gap while summary/advance is still active.
  // Idle after dismiss (no next READY) must fall through to empty Live.
  return postGameSummaryActive;
}
