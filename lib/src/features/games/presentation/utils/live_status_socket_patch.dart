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

/// Whether to skip painting primary as PLAYING for a player with no cartelas
/// on that session (Player 2 missed-round entry).
///
/// Applying the optimistic patch first causes a one-frame
/// liveWaitingFirstBall / spectator flash before ops reload selects the
/// registration game as primary.
bool shouldSkipOptimisticPlayingPatchForNonOwner({
  required String? incomingStatus,
  required GameStatus? priorPrimaryStatus,
  required bool ownsEventSessionByCartelas,
}) {
  if (ownsEventSessionByCartelas) {
    return false;
  }
  if (incomingStatus != 'PLAYING') {
    return false;
  }
  return priorPrimaryStatus == GameStatus.ready ||
      priorPrimaryStatus == GameStatus.next;
}
