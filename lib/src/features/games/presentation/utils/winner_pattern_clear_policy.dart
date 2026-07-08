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
