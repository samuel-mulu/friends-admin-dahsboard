bool shouldSkipPreparingPollDuringSync({
  required bool resumeSyncInFlight,
  required bool canonicalRefetchInFlight,
}) {
  return resumeSyncInFlight || canonicalRefetchInFlight;
}
