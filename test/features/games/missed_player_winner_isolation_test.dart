import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_primary_game_selection.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_session_ownership.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/missed_live_preview_resolver.dart';

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

/// Presentation decision: full winner UI only when primary is the WW session.
bool shouldShowFullWinnerUi({
  required GameModel? primaryGame,
  required MissedLivePreviewResolution preview,
}) {
  if (preview.showPreview) {
    return false;
  }
  return primaryGame?.status == GameStatus.winnerWindow;
}

void main() {
  group('missed player winner isolation', () {
    test('non-owner: preview winnerWindow, primary stays B, no full winner UI', () {
      final a = _game(sessionId: 'a', status: GameStatus.winnerWindow);
      final b = _game(
        sessionId: 'b',
        status: GameStatus.ready,
        canRegister: true,
      );
      final ops = _ops(live: a, registration: b);

      final ownsA = ownsSession('a', const ['b'], primarySessionId: 'b');
      expect(ownsA, isFalse);

      final primary = resolvePrimaryGameForOperations(
        operations: ops,
        ownsLiveCartelas: ownsA,
      );
      expect(primary?.sessionId, 'b');

      final preview = resolveMissedLivePreview(
        operations: ops,
        ownsSession: (id) => ownsSession(id, const ['b'], primarySessionId: 'b'),
      );
      expect(preview.phase, MissedPreviewPhase.winnerWindow);
      expect(preview.showPreview, isTrue);
      expect(
        shouldShowFullWinnerUi(primaryGame: primary, preview: preview),
        isFalse,
      );
    });

    test('owner: no preview, primary stays A winner window', () {
      final a = _game(sessionId: 'a', status: GameStatus.winnerWindow);
      final ops = _ops(live: a);

      final ownsA = ownsSession('a', const ['a'], primarySessionId: 'a');
      expect(ownsA, isTrue);

      final primary = resolvePrimaryGameForOperations(
        operations: ops,
        ownsLiveCartelas: ownsA,
      );
      expect(primary?.sessionId, 'a');
      expect(primary?.status, GameStatus.winnerWindow);

      final preview = resolveMissedLivePreview(
        operations: ops,
        ownsSession: (id) => ownsSession(id, const ['a'], primarySessionId: 'a'),
      );
      expect(preview.showPreview, isFalse);
      expect(
        shouldShowFullWinnerUi(primaryGame: primary, preview: preview),
        isTrue,
      );
    });
  });
}
