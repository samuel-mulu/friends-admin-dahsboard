class ReadyAtomicVisibility {
  const ReadyAtomicVisibility({
    required this.showBanner,
    required this.showGrid,
  });

  final bool showBanner;
  final bool showGrid;
}

/// READY registration banner vs cartela grid visibility.
///
/// The banner must stay visible as soon as a READY game exists. Gating the
/// banner on [gridReady] previously cut REGISTRATION OPEN during READY→READY
/// transitions and fell through to a grid-only layout without the pulse.
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
  return ReadyAtomicVisibility(
    showBanner: true,
    showGrid: gridReady,
  );
}
