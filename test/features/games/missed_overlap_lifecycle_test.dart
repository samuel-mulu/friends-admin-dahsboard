import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/missed_live_preview_resolver.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/missed_overlap_lifecycle.dart';

GameModel _game({
  required String sessionId,
  required GameStatus status,
  bool canRegister = false,
}) {
  final now = DateTime.utc(2026, 7, 22);
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
    prizeAmount: '0',
    companyRevenue: '0',
    status: status,
    playOrder: 1,
    startedAt: status == GameStatus.ready ? null : now,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
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
  final now = DateTime.utc(2026, 7, 22);
  return GameOperationsCurrentResponse(
    liveGame: live,
    checkingGame: checking,
    registrationOpenGame: registration,
    queue: const [],
    timestamp: now,
    serverNow: now,
  );
}

void main() {
  group('resolveMissedOverlapLifecycle', () {
    test('preview active → overlapping with Missed card', () {
      final live = _game(sessionId: 'a', status: GameStatus.playing);
      final next = resolveMissedOverlapLifecycle(
        previousPhase: MissedOverlapPhase.none,
        resolution: MissedLivePreviewResolution(
          previewSession: live,
          phase: MissedPreviewPhase.livePlaying,
          showPreview: true,
        ),
        operations: _ops(
          live: live,
          registration: _game(
            sessionId: 'b',
            status: GameStatus.ready,
            canRegister: true,
          ),
        ),
        isGuest: false,
      );

      expect(next.phase, MissedOverlapPhase.overlapping);
      expect(next.showMissedRoundWrapper, isTrue);
      expect(next.showHandoffHold, isFalse);
      expect(next.blockingLiveGame?.sessionId, 'a');
    });

    test('overlap ends → handoff hold, no Missed card', () {
      final next = resolveMissedOverlapLifecycle(
        previousPhase: MissedOverlapPhase.overlapping,
        resolution: MissedLivePreviewResolution.none,
        operations: _ops(
          registration: _game(
            sessionId: 'b',
            status: GameStatus.ready,
            canRegister: false,
          ),
        ),
        isGuest: false,
      );

      expect(next.phase, MissedOverlapPhase.handoff);
      expect(next.showMissedRoundWrapper, isFalse);
      expect(next.showHandoffHold, isTrue);
      expect(next.blockingLiveGame, isNull);
    });

    test('handoff releases when registration ready and live cleared', () {
      final next = resolveMissedOverlapLifecycle(
        previousPhase: MissedOverlapPhase.handoff,
        resolution: MissedLivePreviewResolution.none,
        operations: _ops(
          registration: _game(
            sessionId: 'b',
            status: GameStatus.ready,
            canRegister: true,
          ),
        ),
        isGuest: false,
      );

      expect(next.phase, MissedOverlapPhase.none);
      expect(next.showMissedRoundWrapper, isFalse);
      expect(next.showHandoffHold, isFalse);
    });

    test('handoff stays while blocking live still present', () {
      final next = resolveMissedOverlapLifecycle(
        previousPhase: MissedOverlapPhase.handoff,
        resolution: MissedLivePreviewResolution.none,
        operations: _ops(
          live: _game(sessionId: 'a', status: GameStatus.finished),
          registration: _game(
            sessionId: 'b',
            status: GameStatus.ready,
            canRegister: true,
          ),
        ),
        isGuest: false,
      );

      expect(next.phase, MissedOverlapPhase.handoff);
      expect(next.showHandoffHold, isTrue);
    });

    test('guest never shows Missed wrapper during overlap', () {
      final live = _game(sessionId: 'a', status: GameStatus.winnerWindow);
      final next = resolveMissedOverlapLifecycle(
        previousPhase: MissedOverlapPhase.none,
        resolution: MissedLivePreviewResolution(
          previewSession: live,
          phase: MissedPreviewPhase.winnerWindow,
          showPreview: true,
        ),
        operations: _ops(live: live),
        isGuest: true,
      );

      expect(next.phase, MissedOverlapPhase.overlapping);
      expect(next.showMissedRoundWrapper, isFalse);
    });
  });
}
