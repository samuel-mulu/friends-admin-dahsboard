import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/missed_live_preview_sync.dart';

CalledNumberModel _called({
  required String sessionId,
  required int order,
  required int number,
}) {
  return CalledNumberModel(
    id: 'id-$sessionId-$order',
    sessionId: sessionId,
    order: order,
    letter: 'B',
    number: number,
    createdAt: DateTime.utc(2026, 7, 22),
  );
}

GameModel _game({
  required String sessionId,
  required GameStatus status,
  int calledNumbersCount = 0,
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
    canRegister: status == GameStatus.ready,
  );
}

GameOperationsCurrentResponse _ops({
  GameModel? live,
  GameModel? checking,
}) {
  final now = DateTime.utc(2026, 7, 22);
  return GameOperationsCurrentResponse(
    liveGame: live,
    checkingGame: checking,
    registrationOpenGame: null,
    queue: const [],
    timestamp: now,
    serverNow: now,
  );
}

void main() {
  group('bumpMissedPreviewCalledCountInOperations', () {
    test('bumps liveGame count for matching session', () {
      final ops = _ops(
        live: _game(
          sessionId: 'session-a',
          status: GameStatus.playing,
          calledNumbersCount: 5,
        ),
      );

      final next = bumpMissedPreviewCalledCountInOperations(
        operations: ops,
        sessionId: 'session-a',
        incomingOrder: 6,
      );

      expect(next, isNot(same(ops)));
      expect(next!.liveGame!.calledNumbersCount, 6);
    });

    test('bumps checkingGame count for matching session', () {
      final ops = _ops(
        checking: _game(
          sessionId: 'session-a',
          status: GameStatus.checking,
          calledNumbersCount: 10,
        ),
      );

      final next = bumpMissedPreviewCalledCountInOperations(
        operations: ops,
        sessionId: 'session-a',
        incomingOrder: 11,
      );

      expect(next!.checkingGame!.calledNumbersCount, 11);
    });

    test('does not decrease count', () {
      final ops = _ops(
        live: _game(
          sessionId: 'session-a',
          status: GameStatus.playing,
          calledNumbersCount: 12,
        ),
      );

      final next = bumpMissedPreviewCalledCountInOperations(
        operations: ops,
        sessionId: 'session-a',
        incomingOrder: 8,
      );

      expect(identical(next, ops), isTrue);
    });

    test('ignores unrelated session', () {
      final ops = _ops(
        live: _game(
          sessionId: 'session-a',
          status: GameStatus.playing,
          calledNumbersCount: 3,
        ),
      );

      final next = bumpMissedPreviewCalledCountInOperations(
        operations: ops,
        sessionId: 'session-b',
        incomingOrder: 4,
      );

      expect(identical(next, ops), isTrue);
    });
  });

  group('mergeMissedPreviewSessionCalledNumber', () {
    test('appends out-of-order balls for the same session', () {
      final sessionA = 'session-a';
      final merged = mergeMissedPreviewSessionCalledNumber(
        sessionNumbers: [
          _called(sessionId: sessionA, order: 5, number: 12),
        ],
        incoming: _called(sessionId: sessionA, order: 9, number: 44),
      );

      expect(merged.map((item) => item.order), [5, 9]);
    });

    test('ignores duplicate draws for the same session', () {
      final sessionA = 'session-a';
      final first = _called(sessionId: sessionA, order: 3, number: 17);
      final merged = mergeMissedPreviewSessionCalledNumber(
        sessionNumbers: [first],
        incoming: first,
      );

      expect(merged.length, 1);
    });

    test('detects conflicting order within the same session', () {
      final sessionA = 'session-a';
      expect(
        isMissedPreviewSessionConflict(
          sessionNumbers: [
            _called(sessionId: sessionA, order: 3, number: 17),
          ],
          incoming: _called(sessionId: sessionA, order: 3, number: 22),
        ),
        isTrue,
      );
    });
  });
}
