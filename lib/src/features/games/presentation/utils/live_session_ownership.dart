/// Whether the player owns cartelas in the live/checking session.
///
/// Prefers an explicit primary session match, but also accepts local cartelas
/// whose session id matches [liveSessionId] when primary is briefly stale
/// (READY snapshot while operations already reports PLAYING).
bool ownsLiveSessionCartelas({
  required String? liveSessionId,
  required String? primarySessionId,
  required Iterable<String> cartelaSessionIds,
}) {
  if (liveSessionId == null || liveSessionId.isEmpty) {
    return false;
  }
  if (primarySessionId == liveSessionId) {
    return true;
  }
  return cartelaSessionIds.any((id) => id == liveSessionId);
}
