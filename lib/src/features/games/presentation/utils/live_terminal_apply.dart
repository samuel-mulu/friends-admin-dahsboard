import '../../data/models/game_model.dart';

/// Stale ops/sockets must not reopen winner-window UI after terminal summary
/// started or after chain FINISHED was applied locally.
bool shouldClampStaleWinnerWindowOnCanonicalApply({
  required bool resumeSync,
  required GameModel? previousGame,
  required GameModel incoming,
  required bool postGameSummaryReviewActive,
}) {
  if (resumeSync || previousGame == null) {
    return false;
  }
  final sessionId = previousGame.sessionId;
  if (sessionId == null ||
      sessionId.isEmpty ||
      sessionId != incoming.sessionId) {
    return false;
  }
  if (incoming.status != GameStatus.winnerWindow &&
      incoming.status != GameStatus.checking) {
    return false;
  }

  if (postGameSummaryReviewActive) {
    return true;
  }

  if (previousGame.isChainGame &&
      (previousGame.status == GameStatus.finished ||
          previousGame.status == GameStatus.noWinner)) {
    return true;
  }

  return false;
}

GameStatus terminalStatusForStaleWinnerWindowClamp({
  required GameModel previousGame,
  required bool postGameSummaryReviewActive,
}) {
  if (previousGame.status == GameStatus.noWinner) {
    return GameStatus.noWinner;
  }
  if (previousGame.status == GameStatus.finished ||
      previousGame.status == GameStatus.noWinner) {
    return previousGame.status;
  }
  if (postGameSummaryReviewActive) {
    return GameStatus.finished;
  }
  return previousGame.status;
}

GameModel clampStaleWinnerWindowIncoming({
  required GameModel previousGame,
  required GameModel incoming,
  required bool postGameSummaryReviewActive,
}) {
  final status = terminalStatusForStaleWinnerWindowClamp(
    previousGame: previousGame,
    postGameSummaryReviewActive: postGameSummaryReviewActive,
  );
  return incoming.copyWith(
    status: status,
    finishedAt: previousGame.finishedAt ?? incoming.finishedAt,
    winnerWindowEndsAt: null,
    roundPausedUntil: null,
  );
}
