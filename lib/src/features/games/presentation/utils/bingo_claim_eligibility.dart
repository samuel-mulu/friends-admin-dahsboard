import '../../data/models/game_cartela_model.dart';
import '../../data/models/game_model.dart';

/// Pure eligibility check shared by live-game claim UI.
bool isCartelaEligibleForBingoClaim({
  required GameModel? game,
  required GameCartelaModel gameCartela,
  required bool winnerWindowExpired,
  required bool hasPendingClaim,
  required bool isCountdownLocked,
}) {
  if (game == null ||
      (game.status != GameStatus.playing &&
          game.status != GameStatus.winnerWindow)) {
    return false;
  }

  if (gameCartela.status == GameCartelaStatus.blocked ||
      gameCartela.status == GameCartelaStatus.cancelled) {
    return false;
  }

  // Chain Game winners are reset to REGISTERED between rounds. A stale local
  // isWinner flag from the previous round must not keep Bingo locked.
  final staleChainWinner = game.isChainGame &&
      game.status == GameStatus.playing &&
      gameCartela.status == GameCartelaStatus.registered;
  if (gameCartela.isWinner && !staleChainWinner) {
    return false;
  }

  if (winnerWindowExpired || hasPendingClaim || isCountdownLocked) {
    return false;
  }

  return true;
}
