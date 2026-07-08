import '../../data/models/called_number_model.dart';
import '../../data/models/game_model.dart';

/// Live/checking session that owns the called-numbers strip during resume sync.
///
/// When [primaryGame] is READY registration, operations may still expose an
/// in-flight PLAYING / WINNER_WINDOW / CHECKING round that must be reconciled.
GameModel? resolveCalledNumbersSyncGame({
  required GameOperationsCurrentResponse? operations,
  required GameModel? primaryGame,
}) {
  if (operations != null) {
    final live = operations.liveGame;
    if (live != null && shouldFetchCalledNumbersForResume(live)) {
      return live;
    }

    final checking = operations.checkingGame;
    if (checking != null && shouldFetchCalledNumbersForResume(checking)) {
      return checking;
    }
  }

  if (primaryGame != null && shouldFetchCalledNumbersForResume(primaryGame)) {
    return primaryGame;
  }

  return null;
}

/// Session id the local called-numbers strip currently represents.
String? priorCalledNumbersSessionIdFromLocal({
  required List<CalledNumberModel> localCalledNumbers,
  required String? fallback,
}) {
  if (localCalledNumbers.isEmpty) {
    return fallback;
  }

  return localCalledNumbers.first.sessionId;
}

/// Whether resume/reconnect should pull the full called-numbers snapshot.
bool shouldFetchCalledNumbersForResume(GameModel game) {
  switch (game.status) {
    case GameStatus.playing:
    case GameStatus.checking:
    case GameStatus.winnerWindow:
    case GameStatus.finished:
    case GameStatus.noWinner:
      return true;
    case GameStatus.next:
    case GameStatus.ready:
    case GameStatus.cancelled:
      return false;
  }
}

/// Animate missed balls on resume when the backend strip is ahead of local.
bool shouldStaggerResumeCalledNumbers({
  required int priorLocalCount,
  required int incomingCount,
}) {
  return incomingCount > 1 && incomingCount > priorLocalCount;
}
