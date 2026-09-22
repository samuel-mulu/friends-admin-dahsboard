import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/big_game_phase.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/big_game_live_presentation.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_game_finish_transition.dart';

final _now = DateTime.parse('2026-09-08T12:00:00.000Z');

GameModel _bigGame({
  required GameStatus status,
  required String sessionId,
  int roundIndex = 1,
  int roundCount = 3,
  bool canRegister = false,
  DateTime? registrationOpensAt,
  DateTime? scheduledStartAt,
  GameModel? nextRoundRegistration,
}) {
  return GameModel(
    id: 'slot-bg',
    sessionId: sessionId,
    staticCode: 'BG-1',
    playCode: 'PLAY-1',
    name: 'Big Game',
    gameRule: null,
    gameType: 'FULL_HOUSE',
    entryFee: '50',
    prizePerCartela: '40',
    companyFeePerCartela: '10',
    prizeAmount: '1000',
    companyRevenue: '0',
    status: status,
    playOrder: 1,
    startedAt: _now,
    finishedAt: status == GameStatus.finished ? _now : null,
    createdAt: _now,
    updatedAt: _now,
    registeredCartelasCount: 1,
    calledNumbersCount: 10,
    registrationOpen: canRegister,
    canRegister: canRegister,
    category: GameCategory.bigGame,
    roundCount: roundCount,
    roundIndex: roundIndex,
    registrationOpensAt: registrationOpensAt,
    scheduledStartAt: scheduledStartAt,
    nextRoundRegistration: nextRoundRegistration,
  );
}

GameOperationsCurrentResponse _ops({GameModel? registration}) {
  return GameOperationsCurrentResponse(
    liveGame: null,
    checkingGame: null,
    registrationOpenGame: registration,
    queue: const [],
    timestamp: _now,
    serverNow: _now,
  );
}

void main() {
  group('embedded Big Game terminal host', () {
    test('finishedReview keeps live host for FINISHED session', () {
      final game = _bigGame(
        status: GameStatus.finished,
        sessionId: 's1',
        roundIndex: 1,
        roundCount: 3,
      );
      expect(
        shouldEmbedBigGameTerminalReviewHost(
          game: game,
          phase: BigGamePhase.finishedReview,
        ),
        isTrue,
      );
    });

    test('slot has more rounds after round 1 finish', () {
      final game = _bigGame(
        status: GameStatus.finished,
        sessionId: 's1',
        roundIndex: 1,
        roundCount: 3,
      );
      expect(bigGameSlotHasMoreRoundsAfterTerminal(game), isTrue);
    });

    test('post-game summary has next before Round 2 is READY in ops', () {
      final finished = _bigGame(
        status: GameStatus.finished,
        sessionId: 's1',
        roundIndex: 1,
        roundCount: 3,
      );
      expect(
        hasPlayableAdvanceTarget(
          operations: null,
          terminalGame: finished,
          embeddedBigGame: true,
          now: _now,
        ),
        isTrue,
      );
      expect(
        hasPlayableAdvanceTarget(
          operations: _ops(),
          terminalGame: finished,
          embeddedBigGame: true,
          now: _now,
        ),
        isTrue,
      );
    });

    test('last slot round has no summary handoff', () {
      final finished = _bigGame(
        status: GameStatus.finished,
        sessionId: 's3',
        roundIndex: 3,
        roundCount: 3,
      );
      expect(bigGameSlotHasMoreRoundsAfterTerminal(finished), isFalse);
      expect(
        hasPlayableAdvanceTarget(
          operations: _ops(),
          terminalGame: finished,
          embeddedBigGame: true,
          now: _now,
        ),
        isFalse,
      );
    });
  });

  group('embedded Big Game terminal handoff merge', () {
    test('merges queued upcoming onto finished round', () {
      final finished = _bigGame(
        status: GameStatus.finished,
        sessionId: 's1',
        roundIndex: 1,
        roundCount: 3,
      );
      final next = _bigGame(
        status: GameStatus.ready,
        sessionId: 's2',
        roundIndex: 2,
        roundCount: 3,
      );
      final merged = mergeEmbeddedBigGameTerminalHandoff(
        terminalGame: finished,
        queuedUpcoming: next,
      );
      expect(merged.nextRoundRegistration?.sessionId, 's2');
    });
  });

  group('embedded Big Game advance target', () {
    test('finds next round via card when window open but canRegister false',
        () {
      final finished = _bigGame(
        status: GameStatus.finished,
        sessionId: 's1',
        roundIndex: 1,
        roundCount: 3,
      );
      final next = _bigGame(
        status: GameStatus.ready,
        sessionId: 's2',
        roundIndex: 2,
        roundCount: 3,
        canRegister: false,
        registrationOpensAt: _now.subtract(const Duration(minutes: 1)),
        scheduledStartAt: _now.add(const Duration(minutes: 5)),
      );
      final target = resolveEmbeddedBigGameAdvanceTarget(
        terminalGame: finished.copyWith(nextRoundRegistration: next),
        operations: _ops(),
        now: _now,
      );
      expect(target?.sessionId, 's2');
      expect(
        hasPlayableAdvanceTarget(
          operations: _ops(),
          terminalGame: finished.copyWith(nextRoundRegistration: next),
          embeddedBigGame: true,
          now: _now,
        ),
        isTrue,
      );
    });
  });
}
