import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_presentation_phase.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_ready_transition_lock.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_ui_mode.dart';

final _now = DateTime.utc(2026, 7, 31);

GameModel _game({
  required String sessionId,
  required GameStatus status,
  bool canRegister = false,
  int calledNumbersCount = 0,
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
    calledNumbersCount: calledNumbersCount,
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

LiveUiModeState _resolve({
  required GameOperationsCurrentResponse? operations,
  GameModel? ownedLiveGameFallback,
  GameModel? pinnedPrimaryGame,
  bool ownsLiveSessionCartelas = false,
  bool hasPrimarySessionCartelas = false,
  LiveSessionHolds holds = const LiveSessionHolds(),
}) {
  return resolveLiveUiMode(
    ResolveLiveUiModeInput(
      operations: operations,
      pinnedPrimaryGame: pinnedPrimaryGame,
      ownedLiveGameFallback: ownedLiveGameFallback,
      ownsLiveSessionCartelas: ownsLiveSessionCartelas,
      hasPrimarySessionCartelas: hasPrimarySessionCartelas,
      calledNumbers: const [],
      holds: holds,
      now: _now,
      preparingStaleAfter: const Duration(minutes: 2),
    ),
  );
}

void main() {
  group('owned live round survives an operations snapshot that lags', () {
    test('stale READY operations no longer paints the preparing panel', () {
      final live = _game(
        sessionId: 'a',
        status: GameStatus.playing,
        calledNumbersCount: 3,
      );
      final state = _resolve(
        // Backend still reports the same round as READY registration.
        operations: _ops(
          registration: _game(
            sessionId: 'a',
            status: GameStatus.ready,
            canRegister: true,
          ),
        ),
        ownedLiveGameFallback: live,
        hasPrimarySessionCartelas: true,
        holds: const LiveSessionHolds(registrationCountdownClosed: true),
      );

      expect(state.mode, LiveUiMode.liveOwned);
      expect(state.primaryGame?.sessionId, 'a');
      expect(state.presentationPhase, LivePresentationPhase.liveCalling);
      expect(state.showsInlinePlayCartelas, isTrue);
      expect(state.useRegistrationOpenLayout, isFalse);
    });

    test('preparing pin from the ready transition lock cannot win', () {
      final ready = _game(
        sessionId: 'a',
        status: GameStatus.ready,
        canRegister: true,
      );
      final live = _game(sessionId: 'a', status: GameStatus.playing);
      final lock = startReadyTransitionLock(
        game: ready,
        reason: ReadyTransitionReason.preparingToPlay,
        startedAt: _now,
      );

      final state = _resolve(
        operations: _ops(registration: ready),
        ownedLiveGameFallback: live,
        hasPrimarySessionCartelas: true,
        holds: LiveSessionHolds(
          readyTransitionLock: lock,
          registrationCountdownClosed: true,
        ),
      );

      expect(state.mode, LiveUiMode.liveOwned);
      expect(state.showsInlinePlayCartelas, isTrue);
    });
  });

  group('untouched behaviour', () {
    test('missed player without cartelas still gets next-round registration', () {
      final state = _resolve(
        operations: _ops(
          live: _game(sessionId: 'a', status: GameStatus.playing),
          registration: _game(
            sessionId: 'b',
            status: GameStatus.ready,
            canRegister: true,
          ),
        ),
      );

      expect(state.mode, LiveUiMode.missedRoundRegistration);
      expect(state.primaryGame?.sessionId, 'b');
    });

    test('genuine preparing phase is preserved while no round is live', () {
      // Backend already closed registration but has not started the round yet.
      final ready = _game(sessionId: 'a', status: GameStatus.ready);

      final state = _resolve(
        operations: _ops(registration: ready),
        hasPrimarySessionCartelas: true,
        holds: const LiveSessionHolds(registrationCountdownClosed: true),
      );

      expect(state.presentationPhase, LivePresentationPhase.preparingGame);
      expect(state.mode, LiveUiMode.registrationWaitingForCurrentGame);
    });

    test('terminal review is not hijacked by a stale live fallback', () {
      final finished = _game(sessionId: 'a', status: GameStatus.finished);
      final state = _resolve(
        operations: _ops(
          registration: _game(
            sessionId: 'b',
            status: GameStatus.ready,
            canRegister: true,
          ),
        ),
        pinnedPrimaryGame: finished,
        // A stale local snapshot still reporting the round as playing.
        ownedLiveGameFallback: _game(
          sessionId: 'a',
          status: GameStatus.playing,
        ),
        hasPrimarySessionCartelas: true,
        holds: const LiveSessionHolds(pinTerminalSession: true),
      );

      expect(state.mode, LiveUiMode.reviewFinished);
      expect(state.primaryGame?.sessionId, 'a');
    });
  });
}
