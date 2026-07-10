import '../../data/models/game_model.dart';

/// Local operations snapshot derived from the current [game] session.
///
/// Used when socket-first UI advances before `operations/current` catches up.
/// Backend remains canonical when a real operations refetch runs later.
GameOperationsCurrentResponse localOperationsSnapshotForGame(
  GameModel game, {
  required DateTime serverNow,
}) {
  GameModel? liveGame;
  GameModel? checkingGame;
  GameModel? registrationOpenGame;

  switch (game.status) {
    case GameStatus.playing:
    case GameStatus.winnerWindow:
      liveGame = game;
    case GameStatus.checking:
      checkingGame = game;
    case GameStatus.ready:
      if (game.canRegister || game.registrationOpen) {
        registrationOpenGame = game;
      }
    case GameStatus.next:
    case GameStatus.finished:
    case GameStatus.noWinner:
    case GameStatus.cancelled:
      break;
  }

  return GameOperationsCurrentResponse(
    liveGame: liveGame,
    checkingGame: checkingGame,
    registrationOpenGame: registrationOpenGame,
    queue: const [],
    timestamp: serverNow,
    serverNow: serverNow,
  );
}

/// @deprecated Use [localOperationsSnapshotForGame].
GameOperationsCurrentResponse embeddedOperationsSnapshotForGame(
  GameModel game, {
  required DateTime serverNow,
}) {
  return localOperationsSnapshotForGame(game, serverNow: serverNow);
}
