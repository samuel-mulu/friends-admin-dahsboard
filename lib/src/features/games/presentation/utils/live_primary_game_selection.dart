import '../../data/models/game_model.dart';

bool keepsOwnedLiveGamePrimary(GameStatus status) {
  return status == GameStatus.playing ||
      status == GameStatus.checking ||
      status == GameStatus.winnerWindow;
}

GameModel? resolvePrimaryGameForOperations({
  required GameOperationsCurrentResponse operations,
  required bool ownsLiveCartelas,
}) {
  final liveCandidate = operations.liveGame ?? operations.checkingGame;
  final registrationGame = operations.registrationOpenGame;

  if (liveCandidate == null) {
    return registrationGame;
  }

  if (registrationGame == null) {
    return liveCandidate;
  }

  if (ownsLiveCartelas && keepsOwnedLiveGamePrimary(liveCandidate.status)) {
    return liveCandidate;
  }

  return registrationGame;
}
