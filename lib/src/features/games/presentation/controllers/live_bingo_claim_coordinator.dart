/// Coordinates bingo claim validation, in-flight debouncing, and
/// auto-bingo attempt deduplication to prevent double-POSTs.
class LiveBingoClaimCoordinator {
  final Set<String> _inFlightCartelaIds = {};
  final Set<String> _autoBingoAttemptKeys = {};

  bool isClaimInFlight(String cartelaId) =>
      _inFlightCartelaIds.contains(cartelaId);

  void markClaimInFlight(String cartelaId) {
    _inFlightCartelaIds.add(cartelaId);
  }

  void clearClaimInFlight(String cartelaId) {
    _inFlightCartelaIds.remove(cartelaId);
  }

  bool hasAttemptedAutoBingo(String attemptKey) =>
      _autoBingoAttemptKeys.contains(attemptKey);

  bool recordAutoBingoAttempt(String attemptKey) {
    if (_autoBingoAttemptKeys.contains(attemptKey)) {
      return false;
    }
    _autoBingoAttemptKeys.add(attemptKey);
    return true;
  }

  void clearAutoBingoAttempts() {
    _autoBingoAttemptKeys.clear();
  }

  void reset() {
    _inFlightCartelaIds.clear();
    _autoBingoAttemptKeys.clear();
  }

  void dispose() {
    reset();
  }
}
