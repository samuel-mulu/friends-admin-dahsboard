import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_ready_transition_lock.dart';

final _now = DateTime.utc(2026, 8, 5, 12);

GameModel _game({
  required String sessionId,
  required GameStatus status,
  bool canRegister = false,
}) {
  return GameModel(
    id: 'id-$sessionId',
    sessionId: sessionId,
    staticCode: 'CODE-$sessionId',
    playCode: 'P-$sessionId',
    name: 'Game $sessionId',
    gameRule: null,
    gameType: 'NORMAL',
    entryFee: '10',
    prizePerCartela: '8',
    companyFeePerCartela: '2',
    prizeAmount: '80',
    companyRevenue: '0',
    status: status,
    playOrder: 1,
    startedAt: status == GameStatus.ready ? null : _now,
    finishedAt: null,
    createdAt: _now,
    updatedAt: _now,
    registeredCartelasCount: 1,
    calledNumbersCount: 0,
    registrationOpen: status == GameStatus.ready,
    canRegister: canRegister,
  );
}

GameOperationsCurrentResponse _ops({
  GameModel? live,
  GameModel? checking,
  GameModel? registration,
}) {
  return GameOperationsCurrentResponse(
    liveGame: live,
    checkingGame: checking,
    registrationOpenGame: registration,
    queue: const [],
    timestamp: _now,
    serverNow: _now,
  );
}

ReadyTransitionLock _lock({
  String sessionId = 'a',
  ReadyTransitionReason reason = ReadyTransitionReason.preparingToPlay,
}) {
  return startReadyTransitionLock(
    game: _game(
      sessionId: sessionId,
      status: GameStatus.ready,
      canRegister: true,
    ),
    reason: reason,
    startedAt: _now,
  );
}

void main() {
  group('preparingToPlay transition lock', () {
    test('clears when canonical registration moved to READY B', () {
      final lock = _lock();
      final registration = _game(
        sessionId: 'b',
        status: GameStatus.ready,
        canRegister: true,
      );

      expect(
        isPreparingTransitionLockCanonicallyObsolete(
          lock: lock,
          operations: _ops(registration: registration),
        ),
        isTrue,
      );
      expect(
        shouldClearReadyTransitionLock(
          lock: lock,
          operations: _ops(registration: registration),
          pinnedGame: null,
          now: _now,
        ),
        isTrue,
      );
      expect(
        resolvePrimaryGameForOperationsWithTransitionLock(
          operations: _ops(registration: registration),
          ownsLiveCartelas: false,
          lock: lock,
          now: _now,
        )?.sessionId,
        'b',
      );
    });

    test('resume-shaped stale lock yields READY B immediately', () {
      final lock = _lock();
      final registration = _game(
        sessionId: 'b',
        status: GameStatus.ready,
        canRegister: true,
      );

      expect(
        shouldClearReadyTransitionLock(
          lock: lock,
          operations: _ops(registration: registration),
          pinnedGame: null,
          now: _now,
        ),
        isTrue,
      );
      expect(
        resolvePrimaryGameForOperationsWithTransitionLock(
          operations: _ops(registration: registration),
          ownsLiveCartelas: false,
          lock: lock,
          now: _now,
        )?.sessionId,
        'b',
      );
    });

    test('clears when canonical live/checking moved away from A', () {
      final lock = _lock();
      final registration = _game(
        sessionId: 'b',
        status: GameStatus.ready,
        canRegister: true,
      );

      expect(
        isPreparingTransitionLockCanonicallyObsolete(
          lock: lock,
          operations: _ops(
            live: _game(sessionId: 'c', status: GameStatus.playing),
            registration: registration,
          ),
        ),
        isTrue,
      );
      expect(
        isPreparingTransitionLockCanonicallyObsolete(
          lock: lock,
          operations: _ops(
            checking: _game(sessionId: 'c', status: GameStatus.checking),
            registration: registration,
          ),
        ),
        isTrue,
      );
    });

    test('keeps same-session PLAYING A unchanged', () {
      final lock = _lock();
      final live = _game(sessionId: 'a', status: GameStatus.playing);

      expect(
        shouldClearReadyTransitionLock(
          lock: lock,
          operations: _ops(live: live),
          pinnedGame: null,
          now: _now,
        ),
        isTrue,
      );
      expect(
        resolvePrimaryGameForOperationsWithTransitionLock(
          operations: _ops(live: live),
          ownsLiveCartelas: true,
          lock: lock,
          now: _now,
        )?.sessionId,
        'a',
      );
    });

    test('keeps same-session CHECKING A unchanged', () {
      final lock = _lock();
      final checking = _game(sessionId: 'a', status: GameStatus.checking);

      expect(
        shouldClearReadyTransitionLock(
          lock: lock,
          operations: _ops(checking: checking),
          pinnedGame: null,
          now: _now,
        ),
        isTrue,
      );
      expect(
        resolvePrimaryGameForOperationsWithTransitionLock(
          operations: _ops(checking: checking),
          ownsLiveCartelas: true,
          lock: lock,
          now: _now,
        )?.sessionId,
        'a',
      );
    });
  });

  group('noPlayersHandoff remains unchanged', () {
    test('READY B still supersedes only the no-players lock path', () {
      final lock = _lock(reason: ReadyTransitionReason.noPlayersHandoff);
      final registration = _game(
        sessionId: 'b',
        status: GameStatus.ready,
        canRegister: true,
      );

      expect(
        isPreparingTransitionLockCanonicallyObsolete(
          lock: lock,
          operations: _ops(registration: registration),
        ),
        isFalse,
      );
      expect(
        shouldClearReadyTransitionLock(
          lock: lock,
          operations: _ops(registration: registration),
          pinnedGame: null,
          now: _now,
        ),
        isTrue,
      );
      expect(
        resolvePrimaryGameForOperationsWithTransitionLock(
          operations: _ops(registration: registration),
          ownsLiveCartelas: false,
          lock: lock,
          now: _now,
        )?.sessionId,
        'b',
      );
    });
  });
}
