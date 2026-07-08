import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/sync/resume_sync_guard.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_timing_config_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_called_numbers_controller.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_game_controllers.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_game_host.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_resume_sync.dart';

class _FakeResumeHost implements LiveGameHost {
  _FakeResumeHost();

  @override
  bool mounted = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  LiveGameControllers get controllers => LiveGameControllers(this);

  @override
  GameTimingConfigModel get effectiveTimingConfig =>
      GameTimingConfigModel.fallback;

  @override
  GameModel? get game => null;

  @override
  Future<void> runResumeSync({bool allowCachedOperations = true}) async {}

  @override
  Future<void> runInitialLoad({
    bool showLoading = true,
    bool includeCalledNumbers = true,
    bool includeMyCartelas = true,
    bool allowTerminalTransition = false,
    GameModel? advanceTarget,
  }) async {}
}

GameModel _gameWithStatus(
  GameStatus status, {
  int calledNumbersCount = 0,
  String sessionId = 'session-1',
  bool registrationOpen = false,
}) {
  final now = DateTime.utc(2026, 6, 30);
  return GameModel(
    id: 'game-1',
    sessionId: sessionId,
    staticCode: 'ABC',
    playCode: '111',
    name: 'Live game',
    gameRule: null,
    gameType: 'ONE_ROW',
    entryFee: '10.00',
    prizePerCartela: '20.00',
    companyFeePerCartela: '1.00',
    prizeAmount: '200.00',
    companyRevenue: '20.00',
    status: status,
    playOrder: 1,
    startedAt: now,
    finishedAt: status == GameStatus.finished ? now : null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 1,
    calledNumbersCount: calledNumbersCount,
    registrationOpen: registrationOpen,
    canRegister: registrationOpen,
    nextAutoCallAt: null,
    operationMode: 'AUTO',
  );
}

CalledNumberModel _called(int order) {
  return CalledNumberModel(
    id: 'cn-$order',
    sessionId: 'session-1',
    letter: 'B',
    number: 6 + order,
    order: order,
    createdAt: DateTime.utc(2026, 6, 30),
  );
}

void main() {
  tearDown(ResumeSyncGuard.resetForTest);

  group('AppBackgroundResumeGate', () {
    final now = DateTime.utc(2026, 7, 3, 12, 0);

    test('quick return with connected socket skips full resume sync', () {
      AppBackgroundResumeGate.setBackgroundedAtForTest(
        now.subtract(const Duration(milliseconds: 900)),
      );

      final decision = AppBackgroundResumeGate.evaluateFullResumeSync(
        socketConnectedNow: true,
        now: now,
      );

      expect(decision.shouldRunFullResumeSync, isFalse);
      expect(decision.reason, contains('quick_return'));
    });

    test('away threshold runs full resume sync', () {
      AppBackgroundResumeGate.setBackgroundedAtForTest(
        now.subtract(const Duration(seconds: 5)),
      );

      final decision = AppBackgroundResumeGate.evaluateFullResumeSync(
        socketConnectedNow: true,
        now: now,
      );

      expect(decision.shouldRunFullResumeSync, isTrue);
      expect(decision.reason, contains('away_'));
    });

    test('socket disconnected while away runs full resume sync', () {
      AppBackgroundResumeGate.setBackgroundedAtForTest(
        now.subtract(const Duration(milliseconds: 500)),
        socketDisconnectedWhileBackgrounded: true,
      );

      final decision = AppBackgroundResumeGate.evaluateFullResumeSync(
        socketConnectedNow: true,
        now: now,
      );

      expect(decision.shouldRunFullResumeSync, isTrue);
      expect(decision.reason, 'socket_disconnected_while_away');
    });

    test('socket disconnected on resume runs full resume sync', () {
      AppBackgroundResumeGate.setBackgroundedAtForTest(
        now.subtract(const Duration(milliseconds: 500)),
      );

      final decision = AppBackgroundResumeGate.evaluateFullResumeSync(
        socketConnectedNow: false,
        now: now,
      );

      expect(decision.shouldRunFullResumeSync, isTrue);
      expect(decision.reason, 'socket_disconnected_on_resume');
    });
  });

  group('resolveCalledNumbersSyncGame', () {
    final now = DateTime.utc(2026, 7, 3);

    GameModel readyGame(String sessionId) {
      return _gameWithStatus(
        GameStatus.ready,
        sessionId: sessionId,
        registrationOpen: true,
      );
    }

    GameModel liveGame(String sessionId, GameStatus status) {
      return _gameWithStatus(
        status,
        sessionId: sessionId,
        calledNumbersCount: 4,
      );
    }

    GameOperationsCurrentResponse ops({
      GameModel? live,
      GameModel? checking,
      GameModel? registration,
    }) {
      return GameOperationsCurrentResponse(
        liveGame: live,
        checkingGame: checking,
        registrationOpenGame: registration,
        queue: const [],
        timestamp: now,
        serverNow: now,
      );
    }

    test('prefers live playing over ready primary', () {
      final syncGame = resolveCalledNumbersSyncGame(
        operations: ops(
          live: liveGame('live-session', GameStatus.playing),
          registration: readyGame('ready-session'),
        ),
        primaryGame: readyGame('ready-session'),
      );

      expect(syncGame?.sessionId, 'live-session');
      expect(syncGame?.status, GameStatus.playing);
    });

    test('uses checking game when live is absent', () {
      final syncGame = resolveCalledNumbersSyncGame(
        operations: ops(
          checking: liveGame('checking-session', GameStatus.checking),
          registration: readyGame('ready-session'),
        ),
        primaryGame: readyGame('ready-session'),
      );

      expect(syncGame?.sessionId, 'checking-session');
    });

    test('falls back to primary when operations have no live session', () {
      final primary = _gameWithStatus(GameStatus.playing);
      final syncGame = resolveCalledNumbersSyncGame(
        operations: ops(),
        primaryGame: primary,
      );

      expect(syncGame, primary);
    });
  });

  group('ResumeAuxiliaryRefreshGate', () {
    test('debounces wallet/registration on rapid app_resume', () {
      expect(
        ResumeAuxiliaryRefreshGate.shouldRunWalletRegistration(
          syncReason: 'app_resume',
          force: false,
        ),
        isTrue,
      );
      expect(
        ResumeAuxiliaryRefreshGate.shouldRunWalletRegistration(
          syncReason: 'app_resume',
          force: false,
        ),
        isFalse,
      );
    });

    test('manual refresh bypasses debounce', () {
      ResumeAuxiliaryRefreshGate.shouldRunWalletRegistration(
        syncReason: 'app_resume',
        force: false,
      );
      expect(
        ResumeAuxiliaryRefreshGate.shouldRunWalletRegistration(
          syncReason: 'manual_refresh',
          force: true,
        ),
        isTrue,
      );
    });
  });

  group('shouldFetchCalledNumbersForResume', () {
    test('fetches for live, checking, winner window, and review', () {
      expect(
        shouldFetchCalledNumbersForResume(_gameWithStatus(GameStatus.playing)),
        isTrue,
      );
      expect(
        shouldFetchCalledNumbersForResume(_gameWithStatus(GameStatus.checking)),
        isTrue,
      );
      expect(
        shouldFetchCalledNumbersForResume(
          _gameWithStatus(GameStatus.winnerWindow),
        ),
        isTrue,
      );
      expect(
        shouldFetchCalledNumbersForResume(_gameWithStatus(GameStatus.finished)),
        isTrue,
      );
      expect(
        shouldFetchCalledNumbersForResume(_gameWithStatus(GameStatus.noWinner)),
        isTrue,
      );
    });

    test('skips READY registration-only sessions', () {
      expect(
        shouldFetchCalledNumbersForResume(_gameWithStatus(GameStatus.ready)),
        isFalse,
      );
    });
  });

  group('shouldStaggerResumeCalledNumbers', () {
    test('staggers when backend is ahead by multiple balls', () {
      expect(
        shouldStaggerResumeCalledNumbers(priorLocalCount: 0, incomingCount: 5),
        isTrue,
      );
      expect(
        shouldStaggerResumeCalledNumbers(priorLocalCount: 3, incomingCount: 10),
        isTrue,
      );
    });

    test('does not stagger when backend matches local', () {
      expect(
        shouldStaggerResumeCalledNumbers(priorLocalCount: 5, incomingCount: 5),
        isFalse,
      );
      expect(
        shouldStaggerResumeCalledNumbers(priorLocalCount: 0, incomingCount: 1),
        isFalse,
      );
    });
  });

  group('replaceFromResumeSnapshot', () {
    test('replaces strip and clears reconcile buffers', () {
      final host = _FakeResumeHost();
      final controller = LiveCalledNumbersController(host);
      controller.calledNumbers = [_called(1)];
      controller.bufferedCalledNumbers = [_called(99)];
      controller.deferredCalledNumbers = [_called(98)];
      controller.processedCalledNumberIds.add('stale');

      controller.replaceFromResumeSnapshot([_called(1), _called(2), _called(3)]);

      expect(controller.calledNumbers.length, 3);
      expect(controller.bufferedCalledNumbers, isEmpty);
      expect(controller.deferredCalledNumbers, isEmpty);
      expect(controller.processedCalledNumberIds, contains('cn-1'));
      expect(controller.processedCalledNumberIds, contains('cn-3'));
      expect(controller.isSyncingCalledNumbers, isFalse);
    });
  });
}
