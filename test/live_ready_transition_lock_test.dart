import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_presentation_phase.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_ready_transition_lock.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_ui_mode.dart';

void main() {
  final now = DateTime.utc(2026, 6, 29, 12, 0, 0);
  const staleAfter = Duration(seconds: 45);

  group('ready transition lock helpers', () {
    test('activates preparing for closing READY session (all users)', () {
      final ready = _readyGame(sessionId: 'session-a');
      expect(shouldStartReadyTransitionLockPreparing(game: ready), isTrue);
      expect(
        shouldStartReadyTransitionLockPreparing(
          game: ready.copyWith(status: GameStatus.playing),
        ),
        isFalse,
      );
      expect(
        shouldStartReadyTransitionLockPreparing(
          game: ready.copyWith(calledNumbersCount: 2),
        ),
        isFalse,
      );
    });

    test('activates no-players handoff for zero-player READY', () {
      final ready = _readyGame(sessionId: 'session-a');
      expect(
        shouldStartReadyTransitionLockNoPlayers(
          game: ready,
          zeroPlayers: true,
        ),
        isTrue,
      );
      expect(
        shouldStartReadyTransitionLockNoPlayers(
          game: ready,
          zeroPlayers: false,
        ),
        isFalse,
      );
    });

    test('8. PLAYING A in operations clears lock', () {
      final lock = _lock(
        game: _readyGame(sessionId: 'session-a'),
        reason: ReadyTransitionReason.preparingToPlay,
      );
      expect(
        shouldClearReadyTransitionLock(
          lock: lock,
          operations: _operations(
            liveGame: _game(
              id: 'slot-a',
              sessionId: 'session-a',
              status: GameStatus.playing,
              canRegister: false,
            ),
          ),
          pinnedGame: _readyGame(sessionId: 'session-a'),
          now: now,
        ),
        isTrue,
      );
    });

    test('9. lock persists until PLAYING clears it', () {
      final lock = _lock(
        game: _readyGame(sessionId: 'session-a'),
        reason: ReadyTransitionReason.preparingToPlay,
      );
      expect(lock.isActiveAt(now), isTrue);
      expect(lock.isActiveAt(now.add(const Duration(minutes: 5))), isTrue);
      expect(
        shouldClearReadyTransitionLock(
          lock: lock,
          operations: _operations(
            registrationGame: _readyGame(sessionId: 'session-b'),
          ),
          pinnedGame: _readyGame(sessionId: 'session-a'),
          now: now.add(const Duration(minutes: 5)),
        ),
        isFalse,
      );
    });

    test('10. active lock pins primary until PLAYING arrives', () {
      final lock = _lock(
        game: _readyGame(sessionId: 'session-a'),
        reason: ReadyTransitionReason.preparingToPlay,
      );
      expect(lock.isActiveAt(now.add(const Duration(minutes: 5))), isTrue);

      final primary = resolvePrimaryGameForOperationsWithTransitionLock(
        operations: _operations(
          registrationGame: _readyGame(sessionId: 'session-b'),
        ),
        ownsLiveCartelas: false,
        lock: lock,
        now: now.add(const Duration(minutes: 5)),
      );
      expect(primary?.sessionId, 'session-a');
    });

    test('shouldKeepTransitionLockShell during null ops gap', () {
      final lock = _lock(
        game: _readyGame(sessionId: 'session-a').copyWith(canRegister: false),
        reason: ReadyTransitionReason.noPlayersHandoff,
      );
      expect(
        shouldKeepTransitionLockShell(
          lock: lock,
          currentGame: lock.snapshotGame,
          incomingGame: null,
          now: now,
        ),
        isTrue,
      );
      expect(
        shouldKeepTransitionLockShell(
          lock: lock,
          currentGame: lock.snapshotGame,
          incomingGame: null,
          now: now.add(const Duration(minutes: 5)),
        ),
        isTrue,
      );
    });
  });

  group('READY A with owned cartelas -> PLAYING', () {
    final readyA = _readyGame(sessionId: 'session-a');
    final readyB = _readyGame(
      sessionId: 'session-b',
      scheduledStartAt: now.add(const Duration(seconds: 108)),
    );
    final preparingLock = _lock(
      game: readyA.copyWith(canRegister: false),
      reason: ReadyTransitionReason.preparingToPlay,
    );

    test('1. countdown close -> preparing_to_play lock', () {
      expect(preparingLock.reason, ReadyTransitionReason.preparingToPlay);
      expect(preparingLock.sessionId, 'session-a');
    });

    test('2. lock active, ops only READY B -> still preparing A', () {
      final primary = resolvePrimaryGameForOperationsWithTransitionLock(
        operations: _operations(registrationGame: readyB),
        ownsLiveCartelas: true,
        lock: preparingLock,
        now: now,
      );

      expect(primary?.sessionId, 'session-a');

      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: _operations(registrationGame: readyB),
          ownsLiveSessionCartelas: true,
          hasPrimarySessionCartelas: true,
          holds: LiveSessionHolds(
            readyTransitionLock: preparingLock,
            registrationCountdownClosed: true,
          ),
          now: now,
          preparingStaleAfter: staleAfter,
        ),
      );

      expect(state.primaryGame?.sessionId, 'session-a');
      expect(state.mode, LiveUiMode.registrationWaitingForCurrentGame);
      expect(state.showsOwnedPreparingShell, isTrue);
      expect(state.useRegistrationOpenLayout, isFalse);
    });

    test('2b. lock active for spectator without cartelas stays on preparing A', () {
      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: _operations(registrationGame: readyB),
          ownsLiveSessionCartelas: false,
          hasPrimarySessionCartelas: false,
          holds: LiveSessionHolds(
            readyTransitionLock: preparingLock,
            registrationCountdownClosed: true,
          ),
          now: now,
          preparingStaleAfter: staleAfter,
        ),
      );

      expect(state.primaryGame?.sessionId, 'session-a');
      expect(state.mode, LiveUiMode.registrationWaitingForCurrentGame);
      expect(state.showsOwnedPreparingShell, isFalse);
      expect(state.useRegistrationOpenLayout, isTrue);
    });

    test('3. PLAYING A + READY B -> playing A, lock clearable', () {
      final playingA = _game(
        id: 'slot-a',
        sessionId: 'session-a',
        status: GameStatus.playing,
        canRegister: false,
      );

      expect(
        shouldClearReadyTransitionLock(
          lock: preparingLock,
          operations: _operations(
            liveGame: playingA,
            registrationGame: readyB,
          ),
          pinnedGame: playingA,
          now: now,
        ),
        isTrue,
      );

      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: _operations(
            liveGame: playingA,
            registrationGame: readyB,
          ),
          ownsLiveSessionCartelas: true,
          hasPrimarySessionCartelas: true,
          holds: const LiveSessionHolds(
            registrationCountdownClosed: true,
          ),
          now: now,
          preparingStaleAfter: staleAfter,
        ),
      );

      expect(state.mode, LiveUiMode.liveOwned);
      expect(state.primaryGame?.status, GameStatus.playing);
    });

    test('7. operation_updated equivalent keeps primary on A during lock', () {
      final primaryBefore = resolvePrimaryGameForOperationsWithTransitionLock(
        operations: _operations(registrationGame: readyB),
        ownsLiveCartelas: true,
        lock: preparingLock,
        now: now,
      );
      final primaryAfter = resolvePrimaryGameForOperationsWithTransitionLock(
        operations: _operations(registrationGame: readyB),
        ownsLiveCartelas: true,
        lock: preparingLock,
        now: now,
      );

      expect(primaryBefore?.sessionId, 'session-a');
      expect(primaryAfter?.sessionId, 'session-a');
    });
  });

  group('READY A zero players -> READY B', () {
    final staleA = _readyGame(sessionId: 'session-a').copyWith(
      canRegister: false,
      scheduledStartAt: now.subtract(const Duration(seconds: 2)),
    );
    final handoffLock = _lock(
      game: staleA,
      reason: ReadyTransitionReason.noPlayersHandoff,
    );
    final readyB = _readyGame(
      sessionId: 'session-b',
      scheduledStartAt: now.add(const Duration(seconds: 108)),
    );

    test('4. zero cartelas close -> no_players_handoff lock', () {
      expect(handoffLock.reason, ReadyTransitionReason.noPlayersHandoff);
    });

    test('5. lock active, ops null -> opening next round not empty', () {
      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: null,
          ownsLiveSessionCartelas: false,
          hasPrimarySessionCartelas: false,
          holds: LiveSessionHolds(
            readyTransitionLock: handoffLock,
            registrationCountdownClosed: true,
          ),
          now: now,
          preparingStaleAfter: staleAfter,
        ),
      );

      expect(state.mode, LiveUiMode.handoffOpeningNext);
      expect(state.mode, isNot(LiveUiMode.empty));
      expect(state.helperKey, LiveUiHelperKey.postGameSummaryOpeningNext);
    });

    test('6. READY B after handoff supersession -> registration countdown', () {
      expect(
        registrationOpenGameSupersedesTransitionLock(
          registrationOpenGame: readyB,
          lockedSessionId: handoffLock.sessionId,
          lockReason: handoffLock.reason,
          now: now,
        ),
        isTrue,
      );

      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: _operations(registrationGame: readyB),
          ownsLiveSessionCartelas: false,
          hasPrimarySessionCartelas: false,
          holds: const LiveSessionHolds(
            registrationCountdownClosed: false,
          ),
          now: now,
          preparingStaleAfter: staleAfter,
        ),
      );

      expect(state.mode, LiveUiMode.registrationCountdown);
      expect(state.primaryGame?.sessionId, 'session-b');
    });
  });
}

ReadyTransitionLock _lock({
  required GameModel game,
  required ReadyTransitionReason reason,
  DateTime? startedAt,
}) {
  return startReadyTransitionLock(
    game: game,
    reason: reason,
    startedAt: startedAt ?? DateTime.utc(2026, 6, 29, 12, 0, 0),
  );
}

GameOperationsCurrentResponse _operations({
  GameModel? liveGame,
  GameModel? checkingGame,
  GameModel? registrationGame,
}) {
  final now = DateTime.utc(2026, 6, 29);
  return GameOperationsCurrentResponse(
    liveGame: liveGame,
    checkingGame: checkingGame,
    registrationOpenGame: registrationGame,
    queue: const [],
    timestamp: now,
    serverNow: now,
  );
}

GameModel _readyGame({
  required String sessionId,
  DateTime? scheduledStartAt,
}) {
  return _game(
    id: 'slot-$sessionId',
    sessionId: sessionId,
    status: GameStatus.ready,
    canRegister: true,
  ).copyWith(scheduledStartAt: scheduledStartAt);
}

GameModel _game({
  required String id,
  required String sessionId,
  required GameStatus status,
  required bool canRegister,
  String? cancelledReason,
}) {
  final now = DateTime.utc(2026, 6, 29);
  return GameModel(
    id: id,
    sessionId: sessionId,
    staticCode: id,
    playCode: sessionId,
    name: 'Game $id',
    gameRule: null,
    gameType: 'FULL_HOUSE',
    entryFee: '10.00',
    prizePerCartela: '50.00',
    companyFeePerCartela: '1.00',
    prizeAmount: '200.00',
    companyRevenue: '20.00',
    status: status,
    playOrder: 1,
    startedAt: now,
    finishedAt: status == GameStatus.finished ? now : null,
    cancelledReason: cancelledReason,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 0,
    calledNumbersCount: status == GameStatus.playing ? 2 : 0,
    registrationOpen: canRegister,
    canRegister: canRegister,
  );
}
