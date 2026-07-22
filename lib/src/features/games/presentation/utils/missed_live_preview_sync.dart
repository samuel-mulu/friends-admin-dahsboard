import '../../data/models/called_number_model.dart';
import '../../data/models/game_model.dart';
import 'live_called_number_sync.dart';

/// Session-scoped called numbers for the missed-player preview strip.
///
/// The shared [_cn] strip uses global order dedup (one order per strip), which
/// breaks multi-session overlap. Preview balls live in a separate per-session
/// list instead.
List<CalledNumberModel> normalizeMissedPreviewSessionNumbers(
  Iterable<CalledNumberModel> numbers,
) {
  final seenIds = <String>{};
  final seenOrders = <int>{};
  final unique = <CalledNumberModel>[];

  for (final number in numbers) {
    if (!seenIds.add(number.id)) {
      continue;
    }
    if (!seenOrders.add(number.order)) {
      continue;
    }
    unique.add(number);
  }

  unique.sort((left, right) => left.order.compareTo(right.order));
  return unique;
}

List<CalledNumberModel> missedPreviewSessionNumbersFromSnapshot({
  required Iterable<CalledNumberModel> snapshot,
  required String sessionId,
}) {
  if (sessionId.isEmpty) {
    return const [];
  }
  return normalizeMissedPreviewSessionNumbers(
    snapshot.where((entry) => entry.sessionId == sessionId),
  );
}

bool isMissedPreviewSessionDuplicate({
  required List<CalledNumberModel> sessionNumbers,
  required CalledNumberModel incoming,
}) {
  final incomingKey = calledDrawDedupKeyFor(incoming);
  for (final existing in sessionNumbers) {
    if (existing.id == incoming.id) {
      return true;
    }
    if (calledDrawDedupKeyFor(existing) == incomingKey) {
      return true;
    }
  }
  return false;
}

bool isMissedPreviewSessionConflict({
  required List<CalledNumberModel> sessionNumbers,
  required CalledNumberModel incoming,
}) {
  final incomingKey = calledDrawDedupKeyFor(incoming);
  for (final existing in sessionNumbers) {
    if (existing.order == incoming.order &&
        calledDrawDedupKeyFor(existing) != incomingKey) {
      return true;
    }
  }
  return false;
}

/// Appends [incoming] to the preview session list (out-of-order safe).
List<CalledNumberModel> mergeMissedPreviewSessionCalledNumber({
  required List<CalledNumberModel> sessionNumbers,
  required CalledNumberModel incoming,
}) {
  return normalizeMissedPreviewSessionNumbers([
    ...sessionNumbers,
    incoming,
  ]);
}

/// Bumps [calledNumbersCount] on the foreign live/checking session inside
/// operations so the missed-player preview remaining count stays in sync
/// between canonical refetches.
GameOperationsCurrentResponse? bumpMissedPreviewCalledCountInOperations({
  required GameOperationsCurrentResponse? operations,
  required String sessionId,
  required int incomingOrder,
}) {
  if (operations == null || sessionId.isEmpty || incomingOrder <= 0) {
    return operations;
  }

  GameModel? bumpGame(GameModel? game) {
    if (game == null || game.sessionId != sessionId) {
      return game;
    }
    final nextCount = incomingOrder > game.calledNumbersCount
        ? incomingOrder
        : game.calledNumbersCount;
    if (nextCount == game.calledNumbersCount) {
      return game;
    }
    return game.copyWith(calledNumbersCount: nextCount);
  }

  final nextLive = bumpGame(operations.liveGame);
  final nextChecking = bumpGame(operations.checkingGame);
  if (identical(nextLive, operations.liveGame) &&
      identical(nextChecking, operations.checkingGame)) {
    return operations;
  }

  return GameOperationsCurrentResponse(
    liveGame: nextLive,
    checkingGame: nextChecking,
    registrationOpenGame: operations.registrationOpenGame,
    queue: operations.queue,
    timestamp: operations.timestamp,
    serverNow: operations.serverNow,
    bigGameLiveElsewhere: operations.bigGameLiveElsewhere,
  );
}
