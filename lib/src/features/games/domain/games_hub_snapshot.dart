import '../data/models/game_model.dart';

/// Hub-facing view of operations/current + big game.
class GamesHubSnapshot {
  const GamesHubSnapshot({
    required this.liveNow,
    required this.comingNext,
    required this.bonusGame,
    required this.bigGame,
  });

  final GameModel? liveNow;
  final GameModel? comingNext;
  final GameModel? bonusGame;
  final GameModel? bigGame;

  static GamesHubSnapshot from({
    required GameOperationsCurrentResponse? operations,
    required GameModel? bigGame,
  }) {
    if (operations == null) {
      return GamesHubSnapshot(
        liveNow: null,
        comingNext: null,
        bonusGame: null,
        bigGame: bigGame,
      );
    }

    final all = _allGames(operations);
    final liveNow = _primaryNormalGame(operations, all);
    final bonusGame = _findBonusGame(all, exclude: liveNow);
    final comingNext = _nextNormalUpcomingGame(operations, current: liveNow);

    return GamesHubSnapshot(
      liveNow: liveNow,
      comingNext: comingNext,
      bonusGame: bonusGame,
      bigGame: bigGame,
    );
  }

  static List<GameModel> _allGames(GameOperationsCurrentResponse operations) {
    return [
      ?operations.liveGame,
      ?operations.checkingGame,
      ?operations.registrationOpenGame,
      ...operations.queue,
    ];
  }

  static GameModel? _primaryNormalGame(
    GameOperationsCurrentResponse operations,
    List<GameModel> all,
  ) {
    for (final bucket in [
      operations.liveGame,
      operations.checkingGame,
      operations.registrationOpenGame,
    ]) {
      if (bucket != null && !bucket.isBonusLike && !bucket.isBigGame) {
        return bucket;
      }
    }

    for (final game in all) {
      if (!game.isBonusLike && !game.isBigGame) {
        return game;
      }
    }

    return operations.currentGameForPlayer;
  }

  static GameModel? _findBonusGame(List<GameModel> all, {GameModel? exclude}) {
    bool isExcluded(GameModel game) {
      if (exclude == null) {
        return false;
      }
      if (game.id == exclude.id) {
        return true;
      }
      final excludeSession = exclude.sessionId;
      final gameSession = game.sessionId;
      return excludeSession != null &&
          gameSession != null &&
          excludeSession == gameSession;
    }

    for (final game in all) {
      if (game.isBonusLike && !isExcluded(game)) {
        return game;
      }
    }
    return null;
  }

  static bool _isSameRound(GameModel candidate, GameModel? current) {
    if (current == null) {
      return false;
    }
    if (candidate.id == current.id) {
      return true;
    }
    final currentSession = current.sessionId;
    final candidateSession = candidate.sessionId;
    return currentSession != null &&
        candidateSession != null &&
        currentSession == candidateSession;
  }

  static GameModel? _nextNormalUpcomingGame(
    GameOperationsCurrentResponse operations, {
    required GameModel? current,
  }) {
    final primary = operations.nextUpcomingGameFor(current: current);
    if (primary != null && !primary.isBigGame) {
      return primary;
    }

    for (final candidate in [
      operations.registrationOpenGame,
      ...operations.queue,
    ]) {
      if (candidate == null) {
        continue;
      }
      if (candidate.isBigGame || _isSameRound(candidate, current)) {
        continue;
      }
      return candidate;
    }

    return null;
  }
}

extension GameOperationsIterable on GameOperationsCurrentResponse {
  Iterable<GameModel> get allGames sync* {
    if (liveGame != null) yield liveGame!;
    if (checkingGame != null) yield checkingGame!;
    if (registrationOpenGame != null) yield registrationOpenGame!;
    yield* queue;
  }
}
