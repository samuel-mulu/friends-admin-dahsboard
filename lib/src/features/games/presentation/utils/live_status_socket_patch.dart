import '../../data/models/game_model.dart';

/// Optimistic status/schedule patch from `game:status_changed` before HTTP catches up.
GameModel? applyStatusChangedSocketPatch({
  required GameModel? current,
  required Map<String, dynamic> payload,
}) {
  if (current == null) {
    return null;
  }

  final sessionId =
      payload['sessionId'] as String? ?? payload['id'] as String?;
  if (sessionId != null &&
      sessionId.isNotEmpty &&
      current.sessionId != sessionId &&
      current.id != sessionId) {
    return null;
  }

  try {
    final incoming = GameModel.fromLiveJson(payload);
    return GameModel.mergeCanonicalSessionState(
      current: current,
      incoming: incoming,
    );
  } catch (_) {
    return null;
  }
}
