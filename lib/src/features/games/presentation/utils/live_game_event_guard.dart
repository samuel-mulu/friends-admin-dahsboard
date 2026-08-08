import '../../data/models/game_model.dart';

/// Whether a realtime payload should mutate the current live-game UI.
///
/// Session id wins when both sides have one — reused slots must not let old
/// terminal sessions affect the new session through [eventSlotId] alone.
bool eventAffectsCurrentGame({
  required GameModel? game,
  required String? activeSessionId,
  required String? eventSessionId,
  required String? eventSlotId,
  String? trackedRegistrationSessionId,
}) {
  if (game == null) {
    return false;
  }

  final currentSessionId = activeSessionId ?? game.sessionId;

  if (eventSessionId != null && currentSessionId != null) {
    if (eventSessionId == currentSessionId) {
      return true;
    }
    if (trackedRegistrationSessionId != null &&
        eventSessionId == trackedRegistrationSessionId) {
      return true;
    }
    return false;
  }

  if (eventSessionId != null && currentSessionId == null) {
    return false;
  }

  if (eventSlotId != null && eventSlotId == game.id) {
    if (currentSessionId == null || game.isRegistrationOpen) {
      return true;
    }
  }

  return false;
}

bool eventAffectsTrackedRegistrationSession({
  required String? trackedRegistrationSessionId,
  required String? eventSessionId,
}) {
  return trackedRegistrationSessionId != null &&
      eventSessionId != null &&
      trackedRegistrationSessionId == eventSessionId;
}

/// Empty live board with no tracked registration: wake on queue/create events
/// via primary canonical refetch (do not route to missed-preview).
bool shouldWakeEmptyLiveBoard({
  required GameModel? game,
  required String? trackedRegistrationSessionId,
}) {
  return game == null && trackedRegistrationSessionId == null;
}

bool isLivePlayGameStatus(GameStatus status) {
  return status == GameStatus.playing ||
      status == GameStatus.winnerWindow ||
      status == GameStatus.checking ||
      status == GameStatus.finished;
}
