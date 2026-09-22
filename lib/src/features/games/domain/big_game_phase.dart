import '../data/models/game_model.dart';

enum BigGamePhase {
  none,
  beforeRegistrationOpens,
  registrationOpen,
  waitingToPlay,
  live,
  betweenRounds,
  finishedReview,
  cancelled,
}

/// Mirrors backend [canRegisterForBigGameWindow]: open when registration has
/// started and play start is still in the future (or open-ended / null start
/// for stranded recovery). Option A opens Round N+1 only after Round N finishes.
bool isBigGameRegistrationWindowOpen(
  GameModel game, {
  required DateTime now,
}) {
  if (!game.isBigGame) {
    return false;
  }
  if (game.status != GameStatus.ready && game.status != GameStatus.next) {
    return false;
  }

  final registrationOpensAt = game.registrationOpensAt;
  if (registrationOpensAt != null && now.isBefore(registrationOpensAt)) {
    return false;
  }

  final scheduledStartAt = game.scheduledStartAt;
  if (scheduledStartAt == null) {
    // Stranded READY recovery (play start not armed yet).
    return registrationOpensAt != null || game.canRegister;
  }

  return now.isBefore(scheduledStartAt);
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

  // Registration open only when the play window is still open — keep banner
  // and LiveGameScreen body aligned (do not key off scheduledStartAt alone).
  if (isBigGameRegistrationWindowOpen(game, now: now) ||
      (game.canRegister && game.isRegistrationOpen)) {
    return BigGamePhase.registrationOpen;
  }

  if (scheduledStartAt != null &&
      !now.isBefore(scheduledStartAt) &&
      (game.status == GameStatus.ready || game.status == GameStatus.next)) {
    return BigGamePhase.waitingToPlay;
  }

  return BigGamePhase.waitingToPlay;
}
