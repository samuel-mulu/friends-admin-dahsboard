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
/// started and play start is still in the future (or open-ended / null start).
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
    // Open-ended next-round registration while a prior round is still live.
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
      // Prefer next READY session from API; if client still sees FINISHED
      // with a pending next start, treat as registration/waiting handoff.
      if (_isBetweenRounds(game, now: now)) {
        return BigGamePhase.betweenRounds;
      }
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

bool _isBetweenRounds(GameModel game, {required DateTime now}) {
  final nextRoundStartsAt = game.nextRoundStartsAt;
  if (nextRoundStartsAt != null && now.isBefore(nextRoundStartsAt)) {
    return true;
  }

  final roundCount = game.roundCount ?? 1;
  final currentRound = game.currentRound ?? game.roundIndex ?? 1;
  return currentRound < roundCount;
}
