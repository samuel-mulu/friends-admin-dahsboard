import '../../data/models/game_model.dart';

enum WinnerPatternClearReason {
  postGameAdvanceBegin,
  sessionChanged,
  canonicalMissingPatterns,
  completePatternReplacement,
  clearSessionScopedReview,
}

bool shouldClearWinnerPatterns(WinnerPatternClearReason reason) {
  return switch (reason) {
    WinnerPatternClearReason.postGameAdvanceBegin => false,
    WinnerPatternClearReason.canonicalMissingPatterns => false,
    WinnerPatternClearReason.sessionChanged => true,
    WinnerPatternClearReason.completePatternReplacement => true,
    WinnerPatternClearReason.clearSessionScopedReview => true,
  };
}

bool shouldClearWinnerPatternsOnSessionApply({
  required bool sessionChanged,
  required bool postGameSummaryAdvancing,
  required GameStatus incomingStatus,
}) {
  if (!sessionChanged) {
    return false;
  }
  if (!postGameSummaryAdvancing) {
    return shouldClearWinnerPatterns(WinnerPatternClearReason.sessionChanged);
  }
  // During post-game advance, keep patterns until the next READY snapshot lands.
  return incomingStatus == GameStatus.ready &&
      shouldClearWinnerPatterns(WinnerPatternClearReason.sessionChanged);
}
