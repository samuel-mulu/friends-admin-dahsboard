bool shouldEnterTerminalSideEffects({
  required bool alreadyInSummary,
  required bool sessionRoomActive,
  required bool shouldRunTransition,
}) {
  if (!shouldRunTransition) {
    return false;
  }
  // Enter at most once: if summary already active and room already left, skip.
  if (alreadyInSummary && !sessionRoomActive) {
    return false;
  }
  return true;
}
