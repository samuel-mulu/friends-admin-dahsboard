import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_game_finish_transition.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_primary_game_selection.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_ui_mode.dart';

GameModel _game({
  required String sessionId,
  required GameStatus status,
  bool canRegister = false,
  GameCategory category = GameCategory.normal,
  String? cancelledReason,
}) {
  final now = DateTime.utc(2026, 9, 15);
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
    finishedAt: status == GameStatus.finished || status == GameStatus.cancelled
        ? now
        : null,
    cancelledReason: cancelledReason,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 1,
    calledNumbersCount: 0,
    registrationOpen: status == GameStatus.ready,
    canRegister: canRegister,
    category: category,
  );
}

GameOperationsCurrentResponse _ops({
  GameModel? live,
  GameModel? registration,
  List<GameModel> queue = const [],
}) {
  final now = DateTime.utc(2026, 9, 15);
  return GameOperationsCurrentResponse(
    liveGame: live,
    checkingGame: null,
    registrationOpenGame: registration,
    queue: queue,
    timestamp: now,
    serverNow: now,
  );
}

void main() {
  group('shouldHoldTerminalPaint idle release', () {
    test('holds during post-game summary when ops has no next READY', () {
      final finished = _game(sessionId: 'a', status: GameStatus.finished);
      expect(
        shouldHoldTerminalPaint(
          priorGame: finished,
          operations: _ops(live: finished),
          postGameSummaryActive: true,
        ),
        isTrue,
      );
    });

    test('does not hold after summary when no next READY', () {
      final finished = _game(sessionId: 'a', status: GameStatus.finished);
      expect(
        shouldHoldTerminalPaint(
          priorGame: finished,
          operations: _ops(live: finished),
          postGameSummaryActive: false,
        ),
        isFalse,
      );
    });

    test('releaseTerminalHold always clears hold', () {
      final finished = _game(sessionId: 'a', status: GameStatus.finished);
      expect(
        shouldHoldTerminalPaint(
          priorGame: finished,
          operations: _ops(),
          postGameSummaryActive: true,
          releaseTerminalHold: true,
        ),
        isFalse,
      );
    });

    test('releases when next READY registration exists', () {
      final finished = _game(sessionId: 'a', status: GameStatus.finished);
      final next = _game(
        sessionId: 'b',
        status: GameStatus.ready,
        canRegister: true,
      );
      expect(
        shouldHoldTerminalPaint(
          priorGame: finished,
          operations: _ops(live: finished, registration: next),
          postGameSummaryActive: true,
        ),
        isFalse,
      );
    });
  });

  group('hasPlayableAdvanceTarget', () {
    test('true for different READY canRegister', () {
      final finished = _game(sessionId: 'a', status: GameStatus.finished);
      final next = _game(
        sessionId: 'b',
        status: GameStatus.ready,
        canRegister: true,
      );
      expect(
        hasPlayableAdvanceTarget(
          operations: _ops(registration: next),
          terminalGame: finished,
        ),
        isTrue,
      );
    });

    test('false when only terminal fallback remains', () {
      final finished = _game(sessionId: 'a', status: GameStatus.finished);
      expect(
        hasPlayableAdvanceTarget(
          operations: _ops(live: finished),
          terminalGame: finished,
        ),
        isFalse,
      );
    });
  });

  group('shouldPinTerminalSession cancelled', () {
    test('does not pin cancelled without post-game summary', () {
      expect(
        shouldPinTerminalSession(
          status: GameStatus.cancelled,
          postGameSummaryReviewActive: false,
        ),
        isFalse,
      );
    });
  });

  group('no_players cancelled UI mode', () {
    test('uses cancelled when no next READY', () {
      final cancelled = _game(
        sessionId: 'a',
        status: GameStatus.cancelled,
        cancelledReason: 'no_players',
      );
      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: _ops(live: cancelled),
          ownsLiveSessionCartelas: false,
          hasPrimarySessionCartelas: false,
          now: DateTime.utc(2026, 9, 15),
        ),
      );
      expect(state.mode, LiveUiMode.cancelled);
      expect(state.helperKey, LiveUiHelperKey.gameNoPlayers);
    });

    test('uses handoffOpeningNext when next READY exists in queue', () {
      final cancelled = _game(
        sessionId: 'a',
        status: GameStatus.cancelled,
        cancelledReason: 'no_players',
      );
      final next = _game(
        sessionId: 'b',
        status: GameStatus.ready,
        canRegister: true,
      );
      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: _ops(live: cancelled, queue: [next]),
          ownsLiveSessionCartelas: false,
          hasPrimarySessionCartelas: false,
          now: DateTime.utc(2026, 9, 15),
        ),
      );
      expect(state.mode, LiveUiMode.handoffOpeningNext);
    });
  });

  group('excludeBigGame primary selection', () {
    test('skips Big Game live candidate on /games', () {
      final big = _game(
        sessionId: 'bg',
        status: GameStatus.playing,
        category: GameCategory.bigGame,
      );
      final normal = _game(
        sessionId: 'n1',
        status: GameStatus.ready,
        canRegister: true,
      );
      final primary = resolvePrimaryGameForOperations(
        operations: _ops(live: big, registration: normal),
        ownsLiveCartelas: false,
        excludeBigGame: true,
      );
      expect(primary?.sessionId, 'n1');
      expect(primary?.isBigGame, isFalse);
    });

    test('returns null when only Big Game is active', () {
      final big = _game(
        sessionId: 'bg',
        status: GameStatus.playing,
        category: GameCategory.bigGame,
      );
      final primary = resolvePrimaryGameForOperations(
        operations: _ops(live: big),
        ownsLiveCartelas: false,
        excludeBigGame: true,
      );
      expect(primary, isNull);
    });

    test('currentGameForPlayer strips Big Game when excludeBigGame', () {
      final big = _game(
        sessionId: 'bg',
        status: GameStatus.playing,
        category: GameCategory.bigGame,
      );
      expect(
        currentGameForPlayer(
          operations: _ops(live: big),
          excludeBigGame: true,
        ),
        isNull,
      );
      expect(
        currentGameForPlayer(
          operations: _ops(live: big),
          excludeBigGame: false,
        )?.sessionId,
        'bg',
      );
    });

    test('operationsHasStandardGameSurface is false for Big Game only', () {
      final big = _game(
        sessionId: 'bg',
        status: GameStatus.playing,
        category: GameCategory.bigGame,
      );
      expect(
        operationsHasStandardGameSurface(_ops(live: big)),
        isFalse,
      );
    });

    test('operationsHasStandardGameSurface is true with standard registration',
        () {
      final big = _game(
        sessionId: 'bg',
        status: GameStatus.playing,
        category: GameCategory.bigGame,
      );
      final normal = _game(
        sessionId: 'n1',
        status: GameStatus.ready,
        canRegister: true,
      );
      expect(
        operationsHasStandardGameSurface(
          _ops(live: big, registration: normal),
        ),
        isTrue,
      );
    });

    test('LiveUiMode is empty when only Big Game with excludeBigGame', () {
      final big = _game(
        sessionId: 'bg',
        status: GameStatus.playing,
        category: GameCategory.bigGame,
      );
      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: _ops(live: big),
          ownsLiveSessionCartelas: true,
          hasPrimarySessionCartelas: true,
          now: DateTime.utc(2026, 9, 15),
          excludeBigGame: true,
        ),
      );
      expect(state.mode, LiveUiMode.empty);
      expect(state.primaryGame, isNull);
    });
  });
}
