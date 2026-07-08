import '../data/models/game_model.dart';

enum BigGamePhase {
  none,
  beforeRegistrationOpens,
  registrationOpen,
  waitingToPlay,
  live,
  finishedReview,
  cancelled,
}

BigGamePhase resolveBigGamePhase(
  GameModel game, {
  required DateTime now,
}) {
  switch (game.status) {
    case GameStatus.cancelled:
      return BigGamePhase.cancelled;
    case GameStatus.finished:
    case GameStatus.noWinner:
      return BigGamePhase.finishedReview;
    case GameStatus.playing:
    case GameStatus.checking:
    case GameStatus.winnerWindow:
      return BigGamePhase.live;
    case GameStatus.next:
    case GameStatus.ready:
      break;
  }

  final registrationOpensAt = game.registrationOpensAt;
  final scheduledStartAt = game.scheduledStartAt;

  if (registrationOpensAt != null && now.isBefore(registrationOpensAt)) {
    return BigGamePhase.beforeRegistrationOpens;
  }

  if (scheduledStartAt != null && now.isBefore(scheduledStartAt)) {
    return BigGamePhase.registrationOpen;
  }

  if (scheduledStartAt != null &&
      !now.isBefore(scheduledStartAt) &&
      (game.status == GameStatus.ready || game.status == GameStatus.next)) {
    return BigGamePhase.waitingToPlay;
  }

  if (game.canRegister && game.isRegistrationOpen) {
    return BigGamePhase.registrationOpen;
  }

  return BigGamePhase.waitingToPlay;
}
