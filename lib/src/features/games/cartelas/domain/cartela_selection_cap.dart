/// Caps how many cartelas a player may still pick: the tighter of the
/// remaining per-player max and what their wallet (or tickets) can pay for.
int? minCartelaSelectionCap(int? limitRemaining, int? paymentAffordable) {
  if (limitRemaining == null) {
    return paymentAffordable;
  }
  if (paymentAffordable == null) {
    return limitRemaining;
  }
  return paymentAffordable < limitRemaining
      ? paymentAffordable
      : limitRemaining;
}

int remainingCartelaLimit({
  required int maxPerPlayer,
  required int alreadyRegistered,
}) {
  final remaining = maxPerPlayer - alreadyRegistered;
  return remaining < 0 ? 0 : remaining;
}
