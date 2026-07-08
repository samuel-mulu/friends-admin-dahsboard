import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/time/server_clock_service.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/live_connection_status.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/next_ball_countdown.dart';

void main() {
  final now = DateTime(2026, 6, 12, 12, 0, 0);

  group('resolveNextBallCountdownState', () {
    test('future nextAutoCallAt shows counting', () {
      final state = resolveNextBallCountdownState(
        showCountdown: true,
        hideForSync: false,
        connectionStatus: LiveConnectionStatus.live,
        nextAutoCallAt: now.add(const Duration(seconds: 5)),
        waitingForFirstBall: false,
        now: now,
      );

      expect(state, NextBallCountdownState.counting);
      expect(
        nextBallCountdownSeconds(now.add(const Duration(seconds: 5)), now: now),
        5,
      );
    });

    test('past nextAutoCallAt shows calling', () {
      final state = resolveNextBallCountdownState(
        showCountdown: true,
        hideForSync: false,
        connectionStatus: LiveConnectionStatus.live,
        nextAutoCallAt: now.subtract(const Duration(milliseconds: 200)),
        waitingForFirstBall: false,
        now: now,
      );

      expect(state, NextBallCountdownState.calling);
      expect(
        nextBallCountdownSeconds(
          now.subtract(const Duration(milliseconds: 200)),
          now: now,
        ),
        0,
      );
    });

    test('null nextAutoCallAt shows waiting', () {
      final state = resolveNextBallCountdownState(
        showCountdown: true,
        hideForSync: false,
        connectionStatus: LiveConnectionStatus.live,
        nextAutoCallAt: null,
        waitingForFirstBall: false,
        now: now,
      );

      expect(state, NextBallCountdownState.waiting);
    });

    test('waiting for first ball uses first-ball state', () {
      final state = resolveNextBallCountdownState(
        showCountdown: true,
        hideForSync: false,
        connectionStatus: LiveConnectionStatus.live,
        nextAutoCallAt: now.add(const Duration(seconds: 7)),
        waitingForFirstBall: true,
        now: now,
      );

      expect(state, NextBallCountdownState.waitingFirstBall);
    });

    test('catching up hides countdown', () {
      final state = resolveNextBallCountdownState(
        showCountdown: true,
        hideForSync: true,
        connectionStatus: LiveConnectionStatus.live,
        nextAutoCallAt: now.add(const Duration(seconds: 4)),
        waitingForFirstBall: false,
        now: now,
      );

      expect(state, NextBallCountdownState.hidden);
    });

    test('reconnecting hides countdown', () {
      final state = resolveNextBallCountdownState(
        showCountdown: true,
        hideForSync: false,
        connectionStatus: LiveConnectionStatus.reconnecting,
        nextAutoCallAt: now.add(const Duration(seconds: 4)),
        waitingForFirstBall: false,
        now: now,
      );

      expect(state, NextBallCountdownState.hidden);
    });

    test('all balls drawn overrides calling state', () {
      final state = resolveNextBallCountdownState(
        showCountdown: true,
        hideForSync: false,
        connectionStatus: LiveConnectionStatus.live,
        nextAutoCallAt: now.subtract(const Duration(seconds: 1)),
        waitingForFirstBall: false,
        allBallsDrawn: true,
        now: now,
      );

      expect(state, NextBallCountdownState.allBallsDrawn);
    });
  });

  group('isAllBallsDrawn', () {
    test('true when server count reaches 75', () {
      expect(
        isAllBallsDrawn(calledNumbersCount: 75, localCalledCount: 70),
        isTrue,
      );
    });

    test('true when local count reaches 75', () {
      expect(
        isAllBallsDrawn(calledNumbersCount: 70, localCalledCount: 75),
        isTrue,
      );
    });

    test('true when highest called order reaches 75', () {
      expect(
        isAllBallsDrawn(
          calledNumbersCount: 70,
          localCalledCount: 70,
          highestCalledOrder: 75,
        ),
        isTrue,
      );
    });
  });

  group('isNextBallCountdownInactive', () {
    test('true when auto-call off and no schedule', () {
      expect(
        isNextBallCountdownInactive(
          autoCallActive: false,
          nextAutoCallAt: null,
        ),
        isTrue,
      );
    });

    test('false when auto-call still active without schedule', () {
      expect(
        isNextBallCountdownInactive(
          autoCallActive: true,
          nextAutoCallAt: null,
        ),
        isFalse,
      );
    });
  });

  test('wrong device clock with synced offset matches server remaining', () {
    final clock = ServerClockService();
    final serverNow = DateTime.now().toUtc();
    final target = serverNow.add(const Duration(seconds: 12)).toLocal();

    clock.sync(serverNow, snap: true);

    expect(
      nextBallCountdownSeconds(
        target,
        clock: clock,
      ),
      12,
    );
  });

  group('resolveNextBallPlayPhase', () {
    test('counting at 3 seconds', () {
      expect(
        resolveNextBallPlayPhase(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          nextAutoCallAt: now.add(const Duration(seconds: 3)),
          now: now,
        ),
        NextBallPlayPhase.counting,
      );
    });

    test('preCallLocked at 2 seconds', () {
      expect(
        resolveNextBallPlayPhase(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          nextAutoCallAt: now.add(const Duration(seconds: 2)),
          now: now,
        ),
        NextBallPlayPhase.preCallLocked,
      );
    });

    test('preCallLocked at 1 second', () {
      expect(
        resolveNextBallPlayPhase(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          nextAutoCallAt: now.add(const Duration(seconds: 1)),
          now: now,
        ),
        NextBallPlayPhase.preCallLocked,
      );
    });

    test('calling at zero', () {
      expect(
        resolveNextBallPlayPhase(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          nextAutoCallAt: now.subtract(const Duration(milliseconds: 200)),
          now: now,
        ),
        NextBallPlayPhase.calling,
      );
    });
  });

  group('isBingoClaimCountdownLocked', () {
    test('unlocked at 3 seconds remaining', () {
      expect(
        isBingoClaimCountdownLocked(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          nextAutoCallAt: now.add(const Duration(seconds: 3)),
          now: now,
        ),
        isFalse,
      );
    });

    test('locked at 2 seconds remaining', () {
      expect(
        isBingoClaimCountdownLocked(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          nextAutoCallAt: now.add(const Duration(seconds: 2)),
          now: now,
        ),
        isTrue,
      );
    });

    test('locked at 1 second remaining', () {
      expect(
        isBingoClaimCountdownLocked(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          nextAutoCallAt: now.add(const Duration(seconds: 1)),
          now: now,
        ),
        isTrue,
      );
    });

    test('locked at 0 seconds / calling until ball arrives', () {
      expect(
        isBingoClaimCountdownLocked(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          nextAutoCallAt: now.subtract(const Duration(milliseconds: 200)),
          now: now,
          playPhase: NextBallPlayPhase.calling,
          highestKnownCalledOrder: 5,
          callingPhaseBaselineOrder: 5,
        ),
        isTrue,
      );
    });

    test('unlocked at calling after ball arrives in strip', () {
      expect(
        isBingoClaimCountdownLocked(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          nextAutoCallAt: now.subtract(const Duration(milliseconds: 200)),
          now: now,
          playPhase: NextBallPlayPhase.calling,
          highestKnownCalledOrder: 6,
          callingPhaseBaselineOrder: 5,
        ),
        isFalse,
      );
    });

    test('no lock in winner window', () {
      expect(
        isBingoClaimCountdownLocked(
          gameStatus: GameStatus.winnerWindow,
          autoCallActive: true,
          nextAutoCallAt: now.add(const Duration(seconds: 1)),
          now: now,
        ),
        isFalse,
      );
    });

    test('no lock when auto-call inactive', () {
      expect(
        isBingoClaimCountdownLocked(
          gameStatus: GameStatus.playing,
          autoCallActive: false,
          nextAutoCallAt: now.add(const Duration(seconds: 1)),
          now: now,
        ),
        isFalse,
      );
    });

    test('no lock when nextAutoCallAt is null', () {
      expect(
        isBingoClaimCountdownLocked(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          nextAutoCallAt: null,
          now: now,
        ),
        isFalse,
      );
    });
  });

  group('buildNextBallCountdownLabel', () {
    test('formats counting and first-ball labels with seconds', () {
      expect(
        buildNextBallCountdownLabel(
          state: NextBallCountdownState.counting,
          trackedSeconds: 8,
          waitingNextBallLabel: 'Waiting…',
          callingNextLabel: 'Calling…',
          syncingNextBallLabel: 'Syncing next ball…',
          allBallsDrawnLabel: 'All balls drawn',
          nextBallInLabel: (seconds) => 'Next ball · ${seconds}s',
          waitingFirstBallInLabel: (seconds) => 'First ball · ${seconds}s',
        ),
        'Next ball · 8s',
      );
      expect(
        buildNextBallCountdownLabel(
          state: NextBallCountdownState.waitingFirstBall,
          trackedSeconds: 5,
          waitingNextBallLabel: 'Waiting…',
          callingNextLabel: 'Calling…',
          syncingNextBallLabel: 'Syncing next ball…',
          allBallsDrawnLabel: 'All balls drawn',
          nextBallInLabel: (seconds) => 'Next ball · ${seconds}s',
          waitingFirstBallInLabel: (seconds) => 'First ball · ${seconds}s',
        ),
        'First ball · 5s',
      );
    });

    test('calling uses syncing label after stale threshold', () {
      expect(
        buildNextBallCountdownLabel(
          state: NextBallCountdownState.calling,
          trackedSeconds: 0,
          waitingNextBallLabel: 'Waiting…',
          callingNextLabel: 'Calling…',
          syncingNextBallLabel: 'Syncing next ball…',
          allBallsDrawnLabel: 'All balls drawn',
          nextBallInLabel: (seconds) => 'Next ball · ${seconds}s',
          waitingFirstBallInLabel: (seconds) => 'First ball · ${seconds}s',
          zeroForMs: 1999,
        ),
        'Calling…',
      );
      expect(
        buildNextBallCountdownLabel(
          state: NextBallCountdownState.calling,
          trackedSeconds: 0,
          waitingNextBallLabel: 'Waiting…',
          callingNextLabel: 'Calling…',
          syncingNextBallLabel: 'Syncing next ball…',
          allBallsDrawnLabel: 'All balls drawn',
          nextBallInLabel: (seconds) => 'Next ball · ${seconds}s',
          waitingFirstBallInLabel: (seconds) => 'First ball · ${seconds}s',
          zeroForMs: 2000,
        ),
        'Syncing next ball…',
      );
    });

    test('returns null when hidden', () {
      expect(
        buildNextBallCountdownLabel(
          state: NextBallCountdownState.hidden,
          trackedSeconds: 4,
          waitingNextBallLabel: 'Waiting…',
          callingNextLabel: 'Calling…',
          syncingNextBallLabel: 'Syncing next ball…',
          allBallsDrawnLabel: 'All balls drawn',
          nextBallInLabel: (seconds) => 'Next ball · ${seconds}s',
          waitingFirstBallInLabel: (seconds) => 'First ball · ${seconds}s',
        ),
        isNull,
      );
    });

    test('shows claim checking label while claim is in flight', () {
      expect(
        buildNextBallCountdownLabel(
          state: NextBallCountdownState.counting,
          trackedSeconds: 8,
          waitingNextBallLabel: 'Waiting…',
          callingNextLabel: 'Calling…',
          syncingNextBallLabel: 'Syncing next ball…',
          allBallsDrawnLabel: 'All balls drawn',
          nextBallInLabel: (seconds) => 'Next ball · ${seconds}s',
          waitingFirstBallInLabel: (seconds) => 'First ball · ${seconds}s',
          isClaimChecking: true,
          claimCheckingLabel: 'Checking bingo claim',
        ),
        'Checking bingo claim',
      );
    });
    test('shows all balls drawn label', () {
      expect(
        buildNextBallCountdownLabel(
          state: NextBallCountdownState.allBallsDrawn,
          trackedSeconds: null,
          waitingNextBallLabel: 'Waiting…',
          callingNextLabel: 'Calling…',
          syncingNextBallLabel: 'Syncing next ball…',
          allBallsDrawnLabel: 'All balls drawn',
          nextBallInLabel: (seconds) => 'Next ball · ${seconds}s',
          waitingFirstBallInLabel: (seconds) => 'First ball · ${seconds}s',
        ),
        'All balls drawn',
      );
    });
  });
}
