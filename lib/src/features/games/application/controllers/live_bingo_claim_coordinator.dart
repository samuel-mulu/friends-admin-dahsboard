/// Coordinates bingo claim validation, in-flight debouncing, and
/// auto-bingo attempt deduplication to prevent double-POSTs.
class LiveBingoClaimCoordinator {
  final Map<String, String> _inFlightByCartela = {};
  final Set<String> _autoBingoAttemptKeys = {};

  bool isClaimInFlight(String cartelaId) =>
      _inFlightByCartela.containsKey(cartelaId);

  void markClaimInFlight(String cartelaId, [String? attemptId]) {
    _inFlightByCartela[cartelaId] = attemptId ?? '';
  }

  void clearClaimInFlight(String cartelaId, [String? attemptId]) {
    if (attemptId == null || _inFlightByCartela[cartelaId] == attemptId) {
      _inFlightByCartela.remove(cartelaId);
    }
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
    _inFlightByCartela.clear();
    _autoBingoAttemptKeys.clear();
  }

  void dispose() {
    reset();
  }
}
