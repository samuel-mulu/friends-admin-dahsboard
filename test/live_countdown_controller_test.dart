import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/games_repository.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_timing_config_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/live_connection_status.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_countdown_tick_context.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_game_controllers.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_game_host.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_presentation_phase.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_ui_mode.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/next_ball_countdown.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/next_ball_stale_guard.dart';

GameModel _playingGame({DateTime? nextAutoCallAt}) {
  return GameModel.fromOperationJson({
    'slotId': 'slot-1',
    'sessionId': 'session-1',
    'staticCode': 'FULL_HOUSE-S1',
    'playCode': 'BINGO-1',
    'playerStatus': 'playing',
    'rawStatus': 'PLAYING',
    'operationMode': 'AUTO',
    'canRegister': false,
    'registrationOpen': false,
    'entryFee': '10',
    'prizePerCartela': '8',
    'prizeAmount': '100',
    'registeredCartelasCount': 1,
    'calledNumbersCount': 1,
    'nextAutoCallAt': nextAutoCallAt?.toIso8601String(),
    'autoCallIntervalMs': 18000,
    'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
  });
}

LiveCountdownTickContext _tickContext({
  required GameModel game,
  bool claimChecking = false,
  int highestKnownCalledOrder = 0,
}) {
  return LiveCountdownTickContext(
    game: game,
    presentationPhase: LivePresentationPhase.liveCalling,
    isAnyClaimChecking: claimChecking,
    isSyncingCalledNumbers: false,
    autoCallActive: true,
    allBallsDrawn: false,
    connectionStatus: LiveConnectionStatus.live,
    socketAutoCallEnabled: true,
    winnerWindowExpired: false,
    effectiveWinnerWindowEndsAt: null,
    shouldRunWinnerWindowTicker: false,
    highestKnownCalledOrder: highestKnownCalledOrder,
  );
}

class _CountdownHarness extends ConsumerStatefulWidget {
  const _CountdownHarness({required this.onReady, this.staleGuard});

  final void Function(_CountdownHarnessState state) onReady;
  final NextBallStaleGuard? staleGuard;

  @override
  ConsumerState<_CountdownHarness> createState() => _CountdownHarnessState();
}

class _CountdownHarnessState extends ConsumerState<_CountdownHarness>
    implements LiveGameHost {
  @override
  late final LiveGameControllers controllers;

  @override
  GameModel? game;

  @override
  void initState() {
    super.initState();
    controllers = LiveGameControllers(
      this,
      nextBallStaleGuard: widget.staleGuard,
    );
    game = _playingGame(
      nextAutoCallAt: DateTime.now().add(const Duration(seconds: 12)),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onReady(this);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  @override
  bool get mounted => context.mounted;

  @override
  bool get embedded => true;

  @override
  String? get gameId => game?.sessionId;

  @override
  GameModel? get initialGame => game;

  @override
  void markNeedsBuild([VoidCallback? fn]) {}

  GameOperationsCurrentResponse? _lastOperations;
  @override
  GameOperationsCurrentResponse? get lastOperations => _lastOperations;
  @override
  set lastOperations(GameOperationsCurrentResponse? value) =>
      _lastOperations = value;

  GameModel? _nextUpcomingGame;
  @override
  GameModel? get nextUpcomingGame => _nextUpcomingGame;
  @override
  set nextUpcomingGame(GameModel? value) => _nextUpcomingGame = value;

  bool _hasBlockingLiveGame = false;
  @override
  bool get hasBlockingLiveGame => _hasBlockingLiveGame;
  @override
  set hasBlockingLiveGame(bool value) => _hasBlockingLiveGame = value;

  bool _isLoading = false;
  @override
  bool get isLoading => _isLoading;
  @override
  set isLoading(bool value) => _isLoading = value;

  String? _errorMessage;
  @override
  String? get errorMessage => _errorMessage;
  @override
  set errorMessage(String? value) => _errorMessage = value;

  String? _emptyMessage;
  @override
  String? get emptyMessage => _emptyMessage;
  @override
  set emptyMessage(String? value) => _emptyMessage = value;

  @override
  bool timingConfigLoaded = true;

  @override
  GameTimingConfigModel get effectiveTimingConfig =>
      GameTimingConfigModel.fallback;

  bool _awaitingLiveRoom = false;
  @override
  bool get awaitingLiveRoom => _awaitingLiveRoom;
  @override
  set awaitingLiveRoom(bool value) => _awaitingLiveRoom = value;

  int _loadGeneration = 0;
  @override
  int get loadGeneration => _loadGeneration;
  @override
  set loadGeneration(int value) => _loadGeneration = value;

  @override
  bool get isGuest => false;

  @override
  GamesRepository get gamesRepository => throw UnimplementedError();

  @override
  List<GameCartelaModel> get myCartelas => const [];

  @override
  DateTime countdownNow({bool useServerClock = true}) => DateTime.now();

  @override
  LiveUiModeState get liveUiMode => throw UnimplementedError();

  @override
  bool get currentReadyCountdownDeferredByLiveGame => false;

  @override
  Duration get preparingPhaseCap => const Duration(seconds: 45);

  @override
  Future<void> runResumeSync() async {}

  @override
  Future<void> runInitialLoad({
    bool showLoading = true,
    bool includeCalledNumbers = true,
    bool includeMyCartelas = true,
    bool allowTerminalTransition = false,
    GameModel? advanceTarget,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_CountdownHarnessState> pumpHarness(WidgetTester tester) async {
    late _CountdownHarnessState state;
    await tester.pumpWidget(
      ProviderScope(
        child: _CountdownHarness(onReady: (ready) => state = ready),
      ),
    );
    await tester.pump();
    return state;
  }

  testWidgets('playing session starts one next-ball ticker', (tester) async {
    final host = await pumpHarness(tester);
    final countdown = host.controllers.countdown;
    final game = host.game!;

    countdown.syncNextBallTicker(
      () => _tickContext(game: game),
      onDisplayChanged: () {},
    );

    expect(countdown.nextBallCountdownTicker?.isActive, isTrue);
    expect(countdown.activeNextBallTickerCount, 1);

    host.controllers.dispose();
  });

  testWidgets('re-sync keeps a single active next-ball ticker', (tester) async {
    final host = await pumpHarness(tester);
    final countdown = host.controllers.countdown;
    final game = host.game!;

    countdown.syncNextBallTicker(
      () => _tickContext(game: game),
      onDisplayChanged: () {},
    );
    final first = countdown.nextBallCountdownTicker;

    countdown.syncNextBallTicker(
      () => _tickContext(game: game),
      onDisplayChanged: () {},
    );

    expect(countdown.nextBallCountdownTicker, same(first));
    expect(countdown.activeNextBallTickerCount, 1);

    host.controllers.dispose();
  });

  testWidgets('number_called schedule update retargets without extra tickers', (
    tester,
  ) async {
    final host = await pumpHarness(tester);
    final countdown = host.controllers.countdown;
    final game = host.game!;

    countdown.syncNextBallTicker(
      () => _tickContext(game: game),
      onDisplayChanged: () {},
    );
    final first = countdown.nextBallCountdownTicker;

    final nextTarget = DateTime.now().add(const Duration(seconds: 20));
    countdown.onNextBallScheduleChanged(
      game: game,
      nextAutoCallAt: nextTarget,
      scheduleChanged: true,
    );
    host.game = game.copyWith(nextAutoCallAt: nextTarget);
    countdown.syncNextBallTicker(
      () => _tickContext(game: host.game!),
      onDisplayChanged: () {},
    );

    expect(countdown.nextBallCountdownTicker, same(first));
    expect(countdown.activeNextBallTickerCount, 1);

    host.controllers.dispose();
  });

  testWidgets(
    'authoritative null target stops ticker and blocks stale target',
    (tester) async {
      final host = await pumpHarness(tester);
      final countdown = host.controllers.countdown;
      final game = host.game!;
      final staleTarget = game.nextAutoCallAt;

      countdown.syncNextBallTicker(
        () => _tickContext(game: game),
        onDisplayChanged: () {},
      );

      countdown.onNextBallScheduleChanged(
        game: game,
        nextAutoCallAt: null,
        scheduleChanged: true,
      );
      host.game = game.copyWith(nextAutoCallAt: staleTarget);
      countdown.syncNextBallTicker(
        () => _tickContext(game: host.game!),
        onDisplayChanged: () {},
      );

      expect(countdown.nextBallCountdownTicker?.isActive ?? false, isFalse);
      expect(countdown.activeNextBallTickerCount, 0);
      expect(countdown.nextBallCountdownSeconds, isNull);
      expect(countdown.effectiveNextAutoCallAt(host.game), isNull);

      host.controllers.dispose();
    },
  );

  testWidgets('nextBallPlayPhase tracks preCallLocked and calling', (
    tester,
  ) async {
    final host = await pumpHarness(tester);
    final countdown = host.controllers.countdown;
    var game = host.game!.copyWith(
      nextAutoCallAt: DateTime.now().add(const Duration(seconds: 1)),
    );
    host.game = game;

    countdown.syncNextBallTicker(
      () => _tickContext(game: game, highestKnownCalledOrder: 1),
      onDisplayChanged: () {},
    );
    await tester.pump();

    expect(countdown.nextBallPlayPhase, NextBallPlayPhase.preCallLocked);
    expect(countdown.callingPhaseBaselineOrder, isNull);

    game = game.copyWith(
      nextAutoCallAt: DateTime.now().subtract(const Duration(seconds: 1)),
    );
    host.game = game;
    countdown.onNextBallScheduleChanged(
      game: game,
      nextAutoCallAt: game.nextAutoCallAt,
      scheduleChanged: true,
    );
    countdown.syncNextBallTicker(
      () => _tickContext(game: game, highestKnownCalledOrder: 1),
      onDisplayChanged: () {},
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(countdown.nextBallPlayPhase, NextBallPlayPhase.calling);
    expect(countdown.callingPhaseBaselineOrder, 1);
    expect(countdown.nextBallCountdownSeconds, 0);

    host.controllers.dispose();
  });

  testWidgets('session reset disposes next-ball ticker', (tester) async {
    final host = await pumpHarness(tester);
    final countdown = host.controllers.countdown;
    final game = host.game!;

    countdown.syncNextBallTicker(
      () => _tickContext(game: game),
      onDisplayChanged: () {},
    );

    countdown.resetNextBallState();

    expect(countdown.nextBallCountdownTicker, isNull);
    expect(countdown.activeNextBallTickerCount, 0);

    host.controllers.dispose();
  });

  testWidgets('winner-window ticker is independent from next-ball ticker', (
    tester,
  ) async {
    final host = await pumpHarness(tester);
    final countdown = host.controllers.countdown;
    final game = host.game!;

    countdown.syncNextBallTicker(
      () => _tickContext(game: game),
      onDisplayChanged: () {},
    );

    host.game = game.copyWith(
      status: GameStatus.winnerWindow,
      winnerWindowEndsAt: DateTime.now().add(const Duration(seconds: 30)),
    );
    countdown.winnerWindowEndsAt = host.game!.winnerWindowEndsAt;

    countdown.syncWinnerWindowTicker(
      shouldRunWinnerWindowTicker: true,
      onExpired: () {},
    );

    expect(countdown.nextBallCountdownTicker?.isActive, isTrue);
    expect(countdown.winnerWindowTicker?.isActive, isTrue);
    expect(countdown.activeNextBallTickerCount, 1);

    host.controllers.dispose();
  });

  testWidgets('resume sync does not start second next-ball ticker', (
    tester,
  ) async {
    final host = await pumpHarness(tester);
    final countdown = host.controllers.countdown;
    final game = host.game!;

    countdown.syncNextBallTicker(
      () => _tickContext(game: game),
      onDisplayChanged: () {},
    );
    final first = countdown.nextBallCountdownTicker;

    countdown.onNextBallScheduleChanged(
      game: game,
      nextAutoCallAt: game.nextAutoCallAt,
      scheduleChanged: false,
    );
    countdown.syncNextBallTicker(
      () => _tickContext(game: game),
      onDisplayChanged: () {},
    );
    countdown.syncNextBallTicker(
      () => _tickContext(game: game),
      onDisplayChanged: () {},
    );

    expect(countdown.nextBallCountdownTicker, same(first));
    expect(countdown.activeNextBallTickerCount, 1);

    host.controllers.dispose();
  });

  testWidgets('socket reconnect keeps single next-ball ticker', (tester) async {
    final host = await pumpHarness(tester);
    final countdown = host.controllers.countdown;
    final game = host.game!;

    countdown.syncNextBallTicker(
      () => _tickContext(game: game),
      onDisplayChanged: () {},
    );
    final first = countdown.nextBallCountdownTicker;

    host.controllers.countdown.serverClockSnapOnNextSync = true;
    countdown.syncServerClockFromUtc(
      DateTime.now().toUtc().add(const Duration(milliseconds: 250)),
      snap: true,
    );
    countdown.syncNextBallTicker(
      () => _tickContext(game: game),
      onDisplayChanged: () {},
    );

    expect(countdown.nextBallCountdownTicker, same(first));
    expect(countdown.activeNextBallTickerCount, 1);

    host.controllers.dispose();
  });

  testWidgets('canonical refresh with same nextAutoCallAt keeps ticker', (
    tester,
  ) async {
    final host = await pumpHarness(tester);
    final countdown = host.controllers.countdown;
    final game = host.game!;
    final target = game.nextAutoCallAt!;

    countdown.syncNextBallTicker(
      () => _tickContext(game: game),
      onDisplayChanged: () {},
    );
    final first = countdown.nextBallCountdownTicker;
    final trackerBefore = countdown.nextBallCountdownTracker;

    countdown.onNextBallScheduleChanged(
      game: game,
      nextAutoCallAt: target,
      scheduleChanged: false,
    );
    countdown.syncNextBallTicker(
      () => _tickContext(game: game),
      onDisplayChanged: () {},
    );

    expect(countdown.nextBallCountdownTicker, same(first));
    expect(countdown.nextBallCountdownTracker, same(trackerBefore));
    expect(countdown.activeNextBallTickerCount, 1);

    host.controllers.dispose();
  });

  testWidgets('session change disposes old ticker and starts a new one', (
    tester,
  ) async {
    final host = await pumpHarness(tester);
    final countdown = host.controllers.countdown;
    final game = host.game!;

    countdown.syncNextBallTicker(
      () => _tickContext(game: game),
      onDisplayChanged: () {},
    );
    final first = countdown.nextBallCountdownTicker;

    countdown.resetNextBallState();
    expect(countdown.nextBallCountdownTicker, isNull);
    expect(countdown.activeNextBallTickerCount, 0);

    final nextSessionGame = game.copyWith(
      sessionId: 'session-2',
      nextAutoCallAt: DateTime.now().add(const Duration(seconds: 15)),
    );
    host.game = nextSessionGame;
    countdown.onNextBallScheduleChanged(
      game: nextSessionGame,
      nextAutoCallAt: nextSessionGame.nextAutoCallAt,
      scheduleChanged: true,
    );
    countdown.syncNextBallTicker(
      () => _tickContext(game: nextSessionGame),
      onDisplayChanged: () {},
    );

    expect(countdown.nextBallCountdownTicker, isNotNull);
    expect(countdown.nextBallCountdownTicker, isNot(same(first)));
    expect(countdown.activeNextBallTickerCount, 1);

    host.controllers.dispose();
  });

  testWidgets('stale recovery fires once per target episode', (tester) async {
    var now = DateTime(2026, 1, 1, 12);
    late _CountdownHarnessState host;
    await tester.pumpWidget(
      ProviderScope(
        child: _CountdownHarness(
          onReady: (ready) => host = ready,
          staleGuard: NextBallStaleGuard(now: () => now),
        ),
      ),
    );
    await tester.pump();
    final countdown = host.controllers.countdown;
    final game = host.game!.copyWith(
      nextAutoCallAt: now.subtract(const Duration(seconds: 1)),
    );
    host.game = game;

    var recoveryCount = 0;
    void onRecovery(NextBallStaleEvaluation evaluation) {
      recoveryCount++;
      if (evaluation.shouldSyncCalledNumbers) {
        countdown.nextBallStaleGuard.recordCalledNumbersSync(
          evaluation.sessionId,
        );
      } else if (evaluation.shouldRefetchCanonical) {
        countdown.nextBallStaleGuard.recordCanonicalRefetch(
          evaluation.sessionId,
        );
      }
    }

    countdown.syncNextBallTicker(
      () => _tickContext(game: game),
      onDisplayChanged: () {},
      onStaleRecovery: onRecovery,
    );

    now = now.add(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
    expect(recoveryCount, 1);

    now = now.add(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 300));
    expect(recoveryCount, 2);

    now = now.add(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 300));
    expect(recoveryCount, 2);

    host.controllers.dispose();
  });

  testWidgets('same nextAutoCallAt does not reset countdown tracker', (
    tester,
  ) async {
    final host = await pumpHarness(tester);
    final countdown = host.controllers.countdown;
    final game = host.game!;
    final target = game.nextAutoCallAt!;

    countdown.onNextBallScheduleChanged(
      game: game,
      nextAutoCallAt: target,
      scheduleChanged: true,
    );
    countdown.syncNextBallTicker(
      () => _tickContext(game: game),
      onDisplayChanged: () {},
    );
    await tester.pump();
    final secondsAfterFirst = countdown.nextBallCountdownSeconds;

    countdown.onNextBallScheduleChanged(
      game: game,
      nextAutoCallAt: target,
      scheduleChanged: false,
    );

    expect(countdown.nextBallCountdownSeconds, secondsAfterFirst);

    host.controllers.dispose();
  });

  testWidgets('claim pause stops ticker without authoritative null schedule', (
    tester,
  ) async {
    final host = await pumpHarness(tester);
    final countdown = host.controllers.countdown;
    final game = host.game!;

    countdown.syncNextBallTicker(
      () => _tickContext(game: game),
      onDisplayChanged: () {},
    );

    countdown.setClaimPause(true);
    expect(countdown.nextBallCountdownTicker?.isActive ?? false, isFalse);

    countdown.setClaimPause(false);
    countdown.syncNextBallTicker(
      () => _tickContext(game: game),
      onDisplayChanged: () {},
    );
    expect(countdown.nextBallCountdownTicker?.isActive, isTrue);
    expect(countdown.activeNextBallTickerCount, 1);

    host.controllers.dispose();
  });
}
