import '../../data/models/game_model.dart';

/// REG chip count during live / registration-open UI.
///
/// Normal sessions show total registrations in the round.
/// Bonus, Big GOTD, Big Game, and Chain Game show only the current player's count.
int registrationRegDisplayCount({
  required GameModel game,
  required int myRegisteredCount,
  int? registrationStateCount,
}) {
  if (game.isBonusLike || game.isBigGame || game.isChainGame) {
    return myRegisteredCount;
  }

  return registrationStateCount ?? game.registeredCartelasCount;
}
