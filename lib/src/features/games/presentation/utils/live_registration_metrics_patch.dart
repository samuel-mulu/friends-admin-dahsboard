import '../../data/models/game_model.dart';

GameModel? applySocketRegistrationMetricsPatch({
  required GameModel? game,
  required String? targetSessionId,
  required String? prizeAmount,
  required int? registeredCartelasCount,
  bool requireReadyRegistrationTarget = false,
}) {
  if (game == null || targetSessionId == null || game.sessionId != targetSessionId) {
    return game;
  }

  if (game.status == GameStatus.finished ||
      game.status == GameStatus.noWinner ||
      game.status == GameStatus.cancelled) {
    return game;
  }

  if (requireReadyRegistrationTarget &&
      (game.status != GameStatus.ready || !game.canRegister)) {
    return game;
  }

  if (prizeAmount == null && registeredCartelasCount == null) {
    return game;
  }

  final nextPrizeAmount = prizeAmount ?? game.prizeAmount;
  final nextRegisteredCount =
      registeredCartelasCount ?? game.registeredCartelasCount;

  if (nextPrizeAmount == game.prizeAmount &&
      nextRegisteredCount == game.registeredCartelasCount) {
    return game;
  }

  return game.copyWith(
    prizeAmount: nextPrizeAmount,
    registeredCartelasCount: nextRegisteredCount,
  );
}
