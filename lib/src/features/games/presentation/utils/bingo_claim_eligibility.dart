import '../../data/models/game_cartela_model.dart';
import '../../data/models/game_model.dart';
import 'chain_round_cartela_state.dart';
import 'live_presentation_phase.dart';

/// Pure eligibility check shared by live-game claim UI.
bool isCartelaEligibleForBingoClaim({
  required GameModel? game,
  required GameCartelaModel gameCartela,
  required bool winnerWindowExpired,
  required bool hasPendingClaim,
  required bool isCountdownLocked,
  int calledNumbersCount = 0,
  int? chainBingoArmedAfterCalledCount,
  DateTime? now,
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

  // Chain inter-round 20s reveal: session stays PLAYING but Bingo must stay off
  // until the pause ends and a new ball arms the next round.
  if (isChainRoundPauseActive(game, now: now)) {
    return false;
  }

  if (!isChainBingoArmedAfterNewBall(
    game: game,
    calledNumbersCount: calledNumbersCount,
    armedAfterCalledCount: chainBingoArmedAfterCalledCount,
  )) {
    return false;
  }

  return true;
}
