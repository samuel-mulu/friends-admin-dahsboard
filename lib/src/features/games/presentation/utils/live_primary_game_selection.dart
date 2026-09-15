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

GameModel? _nonBigGame(GameModel? game, {required bool excludeBigGame}) {
  if (game == null) {
    return null;
  }
  if (excludeBigGame && game.isBigGame) {
    return null;
  }
  return game;
}

GameModel? resolvePrimaryGameForOperations({
  required GameOperationsCurrentResponse operations,
  required bool ownsLiveCartelas,
  bool excludeBigGame = false,
}) {
  final liveCandidate = _nonBigGame(
    operations.liveGame ?? operations.checkingGame,
    excludeBigGame: excludeBigGame,
  );
  final registrationGame = _nonBigGame(
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
