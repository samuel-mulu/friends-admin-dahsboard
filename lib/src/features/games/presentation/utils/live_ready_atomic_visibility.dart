class ReadyAtomicVisibility {
  const ReadyAtomicVisibility({
    required this.showBanner,
    required this.showGrid,
  });

  final bool showBanner;
  final bool showGrid;
}

/// Keeps READY registration banner and cartela grid in lockstep.
/// Never show one without the other when the READY snapshot is incomplete.
ReadyAtomicVisibility resolveReadyAtomicVisibility({
  required bool hasReadyGame,
  required bool gridReady,
  required bool holdingPreviousReady,
}) {
  if (holdingPreviousReady && !hasReadyGame) {
    // Keep previous paint — callers should not flip mode yet.
    return const ReadyAtomicVisibility(showBanner: true, showGrid: true);
  }
  if (!hasReadyGame) {
    return const ReadyAtomicVisibility(showBanner: false, showGrid: false);
  }
  final both = gridReady;
  return ReadyAtomicVisibility(showBanner: both, showGrid: both);
}
