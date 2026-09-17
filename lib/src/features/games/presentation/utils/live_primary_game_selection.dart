import '../../data/models/game_model.dart';

bool keepsOwnedLiveGamePrimary(GameStatus status) {
  return status == GameStatus.playing ||
      status == GameStatus.checking ||
      status == GameStatus.winnerWindow;
}

/// Terminal live sessions must stay primary for the post-game summary hold,
/// even after the next READY registration has already opened.
bool keepsTerminalLiveGamePrimary(GameStatus status) {
  return status == GameStatus.finished || status == GameStatus.noWinner;
}

GameModel? nonBigGame(GameModel? game, {required bool excludeBigGame}) {
  if (game == null) {
    return null;
  }
  if (excludeBigGame && game.isBigGame) {
    return null;
  }
  return game;
}

/// Player-facing current game, optionally stripping Big Game for `/games`.
GameModel? currentGameForPlayer({
  required GameOperationsCurrentResponse operations,
  bool excludeBigGame = false,
}) {
  return nonBigGame(
    operations.currentGameForPlayer,
    excludeBigGame: excludeBigGame,
  );
}

/// True when operations still has a non–Big Game live/checking/registration
/// surface or a non–Big Game upcoming queue item.
///
/// Used by `/games` idle clear: Big Game alone must not block emptying the
/// standard live screen (banner-only on `/games`).
bool operationsHasStandardGameSurface(
  GameOperationsCurrentResponse? operations, {
  GameModel? current,
}) {
  if (operations == null) {
    return false;
  }

  if (nonBigGame(operations.liveGame, excludeBigGame: true) != null ||
      nonBigGame(operations.checkingGame, excludeBigGame: true) != null ||
      nonBigGame(operations.registrationOpenGame, excludeBigGame: true) !=
          null) {
    return true;
  }

  final upcoming = operations.nextUpcomingGameFor(current: current);
  if (upcoming != null && !upcoming.isBigGame) {
    return true;
  }

  for (final item in operations.queue) {
    if (!item.isBigGame) {
      return true;
    }
  }

  return false;
}

GameModel? resolvePrimaryGameForOperations({
  required GameOperationsCurrentResponse operations,
  required bool ownsLiveCartelas,
  bool excludeBigGame = false,
}) {
  final liveCandidate = nonBigGame(
    operations.liveGame ?? operations.checkingGame,
    excludeBigGame: excludeBigGame,
  );
  final registrationGame = nonBigGame(
    operations.registrationOpenGame,
    excludeBigGame: excludeBigGame,
  );

  if (liveCandidate == null) {
    return registrationGame;
  }

  if (registrationGame == null) {
    return liveCandidate;
  }

  // FINISHED / NO_WINNER: keep the just-finished session on screen for the
  // shared 60s Continue summary. Without this, next READY wins and Chain
  // last-round (which never invents local FINISHED) never starts the banner.
  if (keepsTerminalLiveGamePrimary(liveCandidate.status)) {
    return liveCandidate;
  }

  if (ownsLiveCartelas && keepsOwnedLiveGamePrimary(liveCandidate.status)) {
    return liveCandidate;
  }

  return registrationGame;
}
