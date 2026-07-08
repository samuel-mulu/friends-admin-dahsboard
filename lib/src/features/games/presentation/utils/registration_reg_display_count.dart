import '../../data/models/game_model.dart';

/// REG chip count during live / registration-open UI.
///
/// Normal (and big-game) sessions show total registrations in the round.
/// Bonus and big-GOTD sessions show only the current player's count.
int registrationRegDisplayCount({
  required GameModel game,
  required int myRegisteredCount,
  int? registrationStateCount,
}) {
  if (game.isBonusLike) {
    return myRegisteredCount;
  }

  return registrationStateCount ?? game.registeredCartelasCount;
}
