import '../../data/models/game_model.dart';

/// Whether resume should invalidate [myWalletProvider].
///
/// Wallet can change while backgrounded only during open registration.
bool shouldInvalidateWalletOnResume({
  required GameModel? game,
  required GameOperationsCurrentResponse? operations,
}) {
  final registrationGame = operations?.registrationOpenGame;
  if (registrationGame != null &&
      registrationGame.registrationOpen &&
      registrationGame.canRegister) {
    return true;
  }

  if (game != null &&
      game.status == GameStatus.ready &&
      game.registrationOpen &&
      game.canRegister) {
    return true;
  }

  return false;
}

/// Whether resume should refetch [registrationStateProvider] for [sessionId].
///
/// Skips the current live-play session while a round is in progress because the
/// registration grid is not shown for that session.
bool shouldInvalidateRegistrationStateOnResume({
  required String sessionId,
  required GameModel? primaryGame,
}) {
  if (primaryGame == null || primaryGame.sessionId != sessionId) {
    return true;
  }

  return primaryGame.status == GameStatus.ready && primaryGame.registrationOpen;
}
