import '../../data/models/game_model.dart';

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

/// Keeps the current session on screen during finished review instead of
/// swapping to the next registration session from a canonical refetch.
bool shouldPinTerminalSession({
  required GameStatus? status,
  required bool postGameSummaryReviewActive,
  required bool winnerWindowExpired,
}) {
  if (postGameSummaryReviewActive) {
    return true;
  }

  return switch (status) {
    GameStatus.finished => true,
    GameStatus.noWinner => true,
    GameStatus.cancelled => true,
    GameStatus.winnerWindow => winnerWindowExpired,
    _ => false,
  };
}

/// Hold terminal/review paint until the backend opens the next READY registration
/// or a new live session appears in operations.
bool shouldHoldTerminalPaint({
  required GameModel? priorGame,
  required GameOperationsCurrentResponse? operations,
}) {
  if (priorGame == null || !isTerminalGameStatus(priorGame.status)) {
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

  return true;
}
