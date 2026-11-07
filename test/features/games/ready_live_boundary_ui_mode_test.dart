import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_presentation_phase.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_ui_mode.dart';

final _now = DateTime.utc(2026, 11, 6, 9, 0);

GameModel _game({
  required String sessionId,
  required GameStatus status,
  bool canRegister = false,
  int calledNumbersCount = 0,
  DateTime? scheduledStartAt,
  GameCategory category = GameCategory.normal,
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
    registrationOpen: status == GameStatus.ready && canRegister,
    canRegister: canRegister,
    scheduledStartAt: scheduledStartAt,
    category: category,
  );
}

GameOperationsCurrentResponse _ops({
  GameModel? live,
  GameModel? registration,
}) {
  return GameOperationsCurrentResponse(
    liveGame: live,
    checkingGame: null,
    registrationOpenGame: registration,
    queue: const [],
    timestamp: _now,
    serverNow: _now,
  );
}

CalledNumberModel _ball({required String sessionId, required int order}) {
  return CalledNumberModel(
    id: 'ball-$sessionId-$order',
    sessionId: sessionId,
    letter: 'B',
    number: order,
    order: order,
    createdAt: _now,
  );
}

LiveUiModeState _resolve({
  required GameOperationsCurrentResponse? operations,
  GameModel? ownedReadyGameFallback,
  GameModel? ownedLiveGameFallback,
  GameModel? pinnedPrimaryGame,
  bool hasPrimarySessionCartelas = false,
  bool ownsLiveSessionCartelas = false,
  List<CalledNumberModel> calledNumbers = const [],
  LiveSessionHolds holds = const LiveSessionHolds(),
}) {
  return resolveLiveUiMode(
    ResolveLiveUiModeInput(
      operations: operations,
      pinnedPrimaryGame: pinnedPrimaryGame,
      ownedLiveGameFallback: ownedLiveGameFallback,
      ownedReadyGameFallback: ownedReadyGameFallback,
      ownsLiveSessionCartelas: ownsLiveSessionCartelas,
      hasPrimarySessionCartelas: hasPrimarySessionCartelas,
      calledNumbers: calledNumbers,
      holds: holds,
      now: _now,
      preparingStaleAfter: const Duration(minutes: 2),
    ),
  );
}

void main() {
  group('mid-game: stale READY whose draw already started', () {
    test('owned READY with called balls paints the live grid', () {
      final stale = _game(
        sessionId: 's1',
        status: GameStatus.ready,
        calledNumbersCount: 7,
      );
      final state = _resolve(
        operations: _ops(registration: stale),
        hasPrimarySessionCartelas: true,
      );

      expect(state.mode, LiveUiMode.liveOwned);
      expect(state.presentationPhase, LivePresentationPhase.liveCalling);
      expect(state.showsInlinePlayCartelas, isTrue);
      expect(state.showCalledNumbersStrip, isTrue);
      expect(state.useRegistrationOpenLayout, isFalse);
      expect(state.primaryGame?.sessionId, 's1');
    });

    test('same-session local balls also promote (count not synced yet)', () {
      final stale = _game(sessionId: 's1', status: GameStatus.ready);
      final state = _resolve(
        operations: _ops(registration: stale),
        hasPrimarySessionCartelas: true,
        calledNumbers: [_ball(sessionId: 's1', order: 1)],
      );

      expect(state.mode, LiveUiMode.liveOwned);
      expect(state.showsInlinePlayCartelas, isTrue);
    });

    test('without own cartelas it is the spectator live view', () {
      final stale = _game(
        sessionId: 's1',
        status: GameStatus.ready,
        calledNumbersCount: 3,
      );
      final state = _resolve(operations: _ops(registration: stale));

      expect(state.mode, LiveUiMode.liveSpectator);
      expect(state.showsInlinePlayCartelas, isTrue);
    });

    test('Big Game READY with balls keeps its own handoff (not promoted)', () {
      final nextRound = _game(
        sessionId: 'b2',
        status: GameStatus.ready,
        calledNumbersCount: 30,
        category: GameCategory.bigGame,
      );
      final state = _resolve(
        operations: _ops(registration: nextRound),
        hasPrimarySessionCartelas: true,
      );

      expect(state.mode, isNot(LiveUiMode.liveOwned));
      expect(state.primaryGame?.status, GameStatus.ready);
    });

    test('foreign leftover balls never promote a READY game', () {
      final ready = _game(
        sessionId: 's2',
        status: GameStatus.ready,
        canRegister: true,
        scheduledStartAt: _now.add(const Duration(minutes: 2)),
      );
      final state = _resolve(
        operations: _ops(registration: ready),
        hasPrimarySessionCartelas: true,
        calledNumbers: [_ball(sessionId: 'previous-session', order: 1)],
      );

      expect(state.mode, LiveUiMode.registrationCountdown);
      expect(state.presentationPhase, LivePresentationPhase.registrationOpen);
      expect(state.showsInlinePlayCartelas, isFalse);
    });
  });

  group('READY → PLAYING gap: operations has no usable primary', () {
    test('owned READY fallback paints preparing, not the empty state', () {
      final owned = _game(sessionId: 's1', status: GameStatus.ready);
      final state = _resolve(
        operations: _ops(),
        ownedReadyGameFallback: owned,
        hasPrimarySessionCartelas: true,
      );

      expect(state.mode, LiveUiMode.registrationWaitingForCurrentGame);
      expect(state.presentationPhase, LivePresentationPhase.preparingGame);
      expect(state.useRegistrationOpenLayout, isTrue);
      expect(state.showsInlinePlayCartelas, isFalse);
      expect(state.registrationOpenBodyTarget?.sessionId, 's1');
    });

    test('also covers a missing operations snapshot', () {
      final owned = _game(sessionId: 's1', status: GameStatus.ready);
      final state = _resolve(
        operations: null,
        ownedReadyGameFallback: owned,
        hasPrimarySessionCartelas: true,
      );

      expect(state.presentationPhase, LivePresentationPhase.preparingGame);
      expect(state.useRegistrationOpenLayout, isTrue);
    });

    test('stale local canRegister never reopens registration', () {
      final owned = _game(
        sessionId: 's1',
        status: GameStatus.ready,
        canRegister: true,
        scheduledStartAt: _now.subtract(const Duration(minutes: 10)),
      );
      final state = _resolve(
        operations: _ops(),
        ownedReadyGameFallback: owned,
        hasPrimarySessionCartelas: true,
      );

      expect(state.presentationPhase, LivePresentationPhase.preparingGame);
      expect(state.registrationOpenBodyTarget?.canRegister, isFalse);
    });

    test('fallback whose draw already started goes straight to live', () {
      final owned = _game(
        sessionId: 's1',
        status: GameStatus.ready,
        calledNumbersCount: 2,
      );
      final state = _resolve(
        operations: _ops(),
        ownedReadyGameFallback: owned,
        hasPrimarySessionCartelas: true,
      );

      expect(state.mode, LiveUiMode.liveOwned);
      expect(state.showsInlinePlayCartelas, isTrue);
    });

    test('no fallback (guest / no own cartelas) keeps the empty state', () {
      final state = _resolve(operations: _ops());
      expect(state.mode, LiveUiMode.empty);
    });

    test('a real registration game from operations stays primary', () {
      final owned = _game(sessionId: 's1', status: GameStatus.ready);
      final other = _game(
        sessionId: 's2',
        status: GameStatus.ready,
        canRegister: true,
        scheduledStartAt: _now.add(const Duration(minutes: 2)),
      );
      final state = _resolve(
        operations: _ops(registration: other),
        ownedReadyGameFallback: owned,
      );

      expect(state.primaryGame?.sessionId, 's2');
    });

    test('owned live fallback wins over the READY fallback', () {
      final live = _game(
        sessionId: 's1',
        status: GameStatus.playing,
        calledNumbersCount: 4,
      );
      final state = _resolve(
        operations: _ops(),
        ownedLiveGameFallback: live,
        ownedReadyGameFallback: _game(sessionId: 's1', status: GameStatus.ready),
        hasPrimarySessionCartelas: true,
        ownsLiveSessionCartelas: true,
      );

      expect(state.mode, LiveUiMode.liveOwned);
      expect(state.primaryGame?.status, GameStatus.playing);
    });

    test('post-game summary pin wins over the READY fallback', () {
      final finished = _game(sessionId: 's0', status: GameStatus.finished);
      final state = _resolve(
        operations: _ops(),
        pinnedPrimaryGame: finished,
        ownedReadyGameFallback: _game(sessionId: 's1', status: GameStatus.ready),
        hasPrimarySessionCartelas: true,
        holds: const LiveSessionHolds(postGameSummaryReviewActive: true),
      );

      expect(state.mode, LiveUiMode.reviewFinished);
      expect(state.primaryGame?.sessionId, 's0');
    });

    test('Big Game READY fallback is ignored', () {
      final bigGame = _game(
        sessionId: 'b1',
        status: GameStatus.ready,
        category: GameCategory.bigGame,
      );
      final state = _resolve(
        operations: _ops(),
        ownedReadyGameFallback: bigGame,
        hasPrimarySessionCartelas: true,
      );

      expect(state.mode, LiveUiMode.empty);
    });
  });
}
