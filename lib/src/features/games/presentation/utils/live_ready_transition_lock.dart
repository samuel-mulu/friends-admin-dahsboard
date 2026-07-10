import '../../data/models/game_model.dart';
import 'live_primary_game_selection.dart';

/// Max wait for READY session close outcome (PLAYING or next READY).
const Duration kReadyTransitionLockTimeout = Duration(seconds: 9);

/// Alias for callers that referenced the preparing-pin timeout constant.
const Duration kPreparingStartTransitionTimeout = kReadyTransitionLockTimeout;

enum ReadyTransitionReason {
  preparingToPlay,
  noPlayersHandoff,
}

/// Local hold while a closing READY session's outcome is unknown.
class ReadyTransitionLock {
  const ReadyTransitionLock({
    required this.sessionId,
    required this.reason,
    required this.startedAt,
    required this.snapshotGame,
  });

  final String sessionId;
  final ReadyTransitionReason reason;
  final DateTime startedAt;
  final GameModel snapshotGame;

  static const maxTtl = kReadyTransitionLockTimeout;

  bool isActiveAt(DateTime now) => !readyTransitionLockExpired(this, now);

  bool get isPreparingToPlay => reason == ReadyTransitionReason.preparingToPlay;

  bool get isNoPlayersHandoff =>
      reason == ReadyTransitionReason.noPlayersHandoff;
}

bool readyTransitionLockExpired(
  ReadyTransitionLock lock,
  DateTime now, {
  Duration timeout = kReadyTransitionLockTimeout,
}) {
  return now.difference(lock.startedAt) >= timeout;
}

bool isTransitionLockTerminalStatus(GameStatus status) {
  return status == GameStatus.cancelled ||
      status == GameStatus.finished ||
      status == GameStatus.noWinner;
}

bool shouldStartReadyTransitionLockPreparing({
  required GameModel game,
  required bool hasOwnedCartelas,
}) {
  return hasOwnedCartelas &&
      game.status == GameStatus.ready &&
      game.calledNumbersCount == 0;
}

bool shouldStartReadyTransitionLockNoPlayers({
  required GameModel game,
  required bool zeroPlayers,
}) {
  return zeroPlayers &&
      game.status == GameStatus.ready &&
      game.calledNumbersCount == 0;
}

ReadyTransitionLock startReadyTransitionLock({
  required GameModel game,
  required ReadyTransitionReason reason,
  required DateTime startedAt,
}) {
  final sessionId = game.sessionId;
  if (sessionId == null || sessionId.isEmpty) {
    throw ArgumentError('ReadyTransitionLock requires a sessionId');
  }

  return ReadyTransitionLock(
    sessionId: sessionId,
    reason: reason,
    startedAt: startedAt,
    snapshotGame: game,
  );
}

/// Backend [registrationOpenGame] READY + open registration supersedes
/// no-players handoff once confirmed (not while preparing-to-play lock).
bool registrationOpenGameSupersedesTransitionLock({
  required GameModel? registrationOpenGame,
  required String? lockedSessionId,
  required ReadyTransitionReason? lockReason,
  required DateTime now,
}) {
  if (lockReason == ReadyTransitionReason.preparingToPlay) {
    return false;
  }

  if (registrationOpenGame == null) {
    return false;
  }
  if (registrationOpenGame.status != GameStatus.ready ||
      !registrationOpenGame.canRegister) {
    return false;
  }

  if (registrationOpenGame.sessionId != lockedSessionId) {
    return true;
  }

  final scheduledStartAt = registrationOpenGame.scheduledStartAt;
  return scheduledStartAt != null &&
      scheduledStartAt.isAfter(now.add(const Duration(seconds: 5)));
}

bool shouldClearReadyTransitionLock({
  required ReadyTransitionLock? lock,
  required GameOperationsCurrentResponse? operations,
  required GameModel? pinnedGame,
  required DateTime now,
}) {
  if (lock == null) {
    return true;
  }

  if (readyTransitionLockExpired(lock, now)) {
    return true;
  }

  final lockSessionId = lock.sessionId;
  final live = operations?.liveGame ?? operations?.checkingGame;
  if (live != null && live.sessionId == lockSessionId) {
    return true;
  }

  if (pinnedGame != null &&
      pinnedGame.sessionId == lockSessionId &&
      isTransitionLockTerminalStatus(pinnedGame.status)) {
    return true;
  }

  if (lock.isNoPlayersHandoff &&
      registrationOpenGameSupersedesTransitionLock(
        registrationOpenGame: operations?.registrationOpenGame,
        lockedSessionId: lockSessionId,
        lockReason: lock.reason,
        now: now,
      )) {
    return true;
  }

  return false;
}

bool shouldKeepTransitionLockShell({
  required ReadyTransitionLock? lock,
  required GameModel? currentGame,
  required GameModel? incomingGame,
  required DateTime now,
}) {
  if (lock == null || !lock.isActiveAt(now)) {
    return false;
  }
  if (currentGame == null || incomingGame != null) {
    return false;
  }

  return currentGame.sessionId == lock.sessionId ||
      currentGame.sessionId == lock.snapshotGame.sessionId;
}

/// True once operations confirms the lock's outcome (live advance or next READY).
/// Until then the UI must show loading — not a guessed registration shell.
bool isReadyTransitionLockOutcomeKnown({
  required ReadyTransitionLock lock,
  required GameOperationsCurrentResponse? operations,
  required DateTime now,
}) {
  if (!lock.isActiveAt(now) || operations == null) {
    return false;
  }

  final lockSessionId = lock.sessionId;
  final live = operations.liveGame ?? operations.checkingGame;
  if (live != null && live.sessionId == lockSessionId) {
    return live.status == GameStatus.playing ||
        live.status == GameStatus.checking ||
        live.status == GameStatus.winnerWindow ||
        isTransitionLockTerminalStatus(live.status);
  }

  if (live != null && live.sessionId != lockSessionId) {
    return true;
  }

  if (lock.isNoPlayersHandoff &&
      registrationOpenGameSupersedesTransitionLock(
        registrationOpenGame: operations.registrationOpenGame,
        lockedSessionId: lockSessionId,
        lockReason: lock.reason,
        now: now,
      )) {
    return true;
  }

  return false;
}

/// Keeps the closing READY session primary while its outcome is unknown.
GameModel? resolvePrimaryGameForOperationsWithTransitionLock({
  required GameOperationsCurrentResponse operations,
  required bool ownsLiveCartelas,
  required ReadyTransitionLock? lock,
  required DateTime now,
}) {
  if (lock == null || !lock.isActiveAt(now)) {
    return resolvePrimaryGameForOperations(
      operations: operations,
      ownsLiveCartelas: ownsLiveCartelas,
    );
  }

  final lockSessionId = lock.sessionId;
  final snapshot = lock.snapshotGame;

  if (isTransitionLockTerminalStatus(snapshot.status)) {
    return resolvePrimaryGameForOperations(
      operations: operations,
      ownsLiveCartelas: ownsLiveCartelas,
    );
  }

  final live = operations.liveGame ?? operations.checkingGame;
  if (live != null && live.sessionId == lockSessionId) {
    return live;
  }

  if (lock.isNoPlayersHandoff &&
      registrationOpenGameSupersedesTransitionLock(
        registrationOpenGame: operations.registrationOpenGame,
        lockedSessionId: lockSessionId,
        lockReason: lock.reason,
        now: now,
      )) {
    return resolvePrimaryGameForOperations(
      operations: operations,
      ownsLiveCartelas: ownsLiveCartelas,
    );
  }

  final registration = operations.registrationOpenGame;
  if (registration != null &&
      registration.sessionId != lockSessionId &&
      live == null) {
    return snapshot;
  }

  final normal = resolvePrimaryGameForOperations(
    operations: operations,
    ownsLiveCartelas: ownsLiveCartelas,
  );
  if (normal != null &&
      normal.sessionId != lockSessionId &&
      normal.status == GameStatus.ready &&
      snapshot.status == GameStatus.ready) {
    return snapshot;
  }

  return normal;
}
