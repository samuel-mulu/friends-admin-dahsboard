/// Whether a socket event targets a live session the player does not own
/// while primary/registration remain on another game (Player 2 overlap).
///
/// Such events must refresh canonical operations only — never mutate [_game]
/// or enter owner winner/checking presentation.
bool shouldSyncMissedPreviewForForeignSession({
  required String? eventSessionId,
  required String? primarySessionId,
  required String? trackedRegistrationSessionId,
  required bool Function(String? sessionId) ownsSession,
}) {
  if (eventSessionId == null || eventSessionId.isEmpty) {
    return false;
  }
  if (primarySessionId != null &&
      primarySessionId.isNotEmpty &&
      eventSessionId == primarySessionId) {
    return false;
  }
  if (trackedRegistrationSessionId != null &&
      trackedRegistrationSessionId.isNotEmpty &&
      eventSessionId == trackedRegistrationSessionId) {
    return false;
  }
  if (ownsSession(eventSessionId)) {
    return false;
  }
  return true;
}

String? eventSessionIdFromPayload(Map<String, dynamic> payload) {
  final sessionId = payload['sessionId'] as String? ??
      payload['gameSessionId'] as String? ??
      payload['id'] as String?;
  if (sessionId == null || sessionId.isEmpty) {
    return null;
  }
  return sessionId;
}
