/// Whether the full inline cartela registration panel should appear below
/// cartelas in the live-game scroll area.
bool shouldShowInlineRegistrationPanel({
  required bool shouldShowRegistrationPanel,
  required bool showsInlinePlayCartelas,
  required bool hasCartelas,
  required bool registrationTargetIsCurrentGame,
}) {
  if (!shouldShowRegistrationPanel) {
    return false;
  }

  if (showsInlinePlayCartelas &&
      hasCartelas &&
      !registrationTargetIsCurrentGame) {
    return false;
  }

  return true;
}
