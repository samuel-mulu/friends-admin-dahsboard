/// Whether the player owns [sessionId] via cartela membership only.
///
/// Never treats "primary screen session == requested session" as ownership.
/// That shortcut falsely marked non-registered players as live owners after a
/// local READY→PLAYING patch and blocked missed-round entry.
bool ownsSessionByCartelas(
  String? sessionId,
  Iterable<String> cartelaSessionIds,
) {
  if (sessionId == null || sessionId.isEmpty) {
    return false;
  }
  return cartelaSessionIds.any((id) => id == sessionId);
}

/// Whether the player owns the given [sessionId].
///
/// Cartela membership is authoritative. [primarySessionId] is ignored for
/// ownership decisions (kept as an optional parameter for call-site compat).
bool ownsSession(
  String? sessionId,
  Iterable<String> cartelaSessionIds, {
  String? primarySessionId,
}) {
  return ownsSessionByCartelas(sessionId, cartelaSessionIds);
}

/// Whether the player owns cartelas in the live/checking session.
///
/// Cartela-backed only. [primarySessionId] is ignored so a patched primary
/// PLAYING session without cartelas cannot claim live ownership (Player 2
/// missed-round entry).
bool ownsLiveSessionCartelas({
  required String? liveSessionId,
  required String? primarySessionId,
  required Iterable<String> cartelaSessionIds,
}) {
  return ownsSessionByCartelas(liveSessionId, cartelaSessionIds);
}
