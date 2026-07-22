import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/missed_live_preview_resolver.dart';

GameModel _game({
  required String sessionId,
  required GameStatus status,
  int calledNumbersCount = 0,
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
  group('resolveMissedLivePreview', () {
    test('Player 1 owns A PLAYING → no preview', () {
      final a = _game(sessionId: 'a', status: GameStatus.playing);
      final resolution = resolveMissedLivePreview(
        operations: _ops(live: a),
        ownsSession: (id) => id == 'a',
      );
      expect(resolution.showPreview, isFalse);
      expect(resolution.phase, MissedPreviewPhase.none);
      expect(resolution.previewSession, isNull);
    });

    test('Player 2 overlap A PLAYING B READY → preview livePlaying', () {
      final a = _game(sessionId: 'a', status: GameStatus.playing);
      final b = _game(
        sessionId: 'b',
        status: GameStatus.ready,
        canRegister: true,
      );
      final resolution = resolveMissedLivePreview(
        operations: _ops(live: a, registration: b),
        ownsSession: (id) => id == 'b',
      );
      expect(resolution.showPreview, isTrue);
      expect(resolution.phase, MissedPreviewPhase.livePlaying);
      expect(resolution.previewSession?.sessionId, 'a');
    });

    test('Checking overlap → preview checking', () {
      final a = _game(sessionId: 'a', status: GameStatus.checking);
      final b = _game(
        sessionId: 'b',
        status: GameStatus.ready,
        canRegister: true,
      );
      final resolution = resolveMissedLivePreview(
        operations: _ops(checking: a, registration: b),
        ownsSession: (id) => id == 'b',
      );
      expect(resolution.showPreview, isTrue);
      expect(resolution.phase, MissedPreviewPhase.checking);
      expect(resolution.previewSession?.sessionId, 'a');
    });

    test('Winner-window overlap → preview winnerWindow', () {
      final a = _game(sessionId: 'a', status: GameStatus.winnerWindow);
      final b = _game(
        sessionId: 'b',
        status: GameStatus.ready,
        canRegister: true,
      );
      final resolution = resolveMissedLivePreview(
        operations: _ops(live: a, registration: b),
        ownsSession: (id) => id == 'b',
      );
      expect(resolution.showPreview, isTrue);
      expect(resolution.phase, MissedPreviewPhase.winnerWindow);
      expect(resolution.previewSession?.sessionId, 'a');
    });

    test('winnerWindow takes priority over checking', () {
      final ww = _game(sessionId: 'a', status: GameStatus.winnerWindow);
      final checking = _game(sessionId: 'c', status: GameStatus.checking);
      final resolution = resolveMissedLivePreview(
        operations: _ops(live: ww, checking: checking),
        ownsSession: (_) => false,
      );
      expect(resolution.phase, MissedPreviewPhase.winnerWindow);
      expect(resolution.previewSession?.sessionId, 'a');
    });

    test('checking takes priority over playing', () {
      final playing = _game(sessionId: 'a', status: GameStatus.playing);
      final checking = _game(sessionId: 'c', status: GameStatus.checking);
      final resolution = resolveMissedLivePreview(
        operations: _ops(live: playing, checking: checking),
        ownsSession: (_) => false,
      );
      expect(resolution.phase, MissedPreviewPhase.checking);
      expect(resolution.previewSession?.sessionId, 'c');
    });

    test('cleared ops → no preview', () {
      final b = _game(
        sessionId: 'b',
        status: GameStatus.ready,
        canRegister: true,
      );
      final resolution = resolveMissedLivePreview(
        operations: _ops(registration: b),
        ownsSession: (id) => id == 'b',
      );
      expect(resolution.showPreview, isFalse);
      expect(resolution.phase, MissedPreviewPhase.none);
      expect(resolution.previewSession, isNull);
    });
  });
}
