import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/time/server_clock_service.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_timing_config_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_called_numbers_controller.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_game_controllers.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_game_host.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_called_number_sync.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/next_ball_stale_guard.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/number_called_schedule_patch.dart';

class _FakeHost implements LiveGameHost {
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
}

CalledNumberModel _called({
  required String id,
  required int order,
  required int number,
  String sessionId = 'session-1',
}) {
  return CalledNumberModel(
    id: id,
    sessionId: sessionId,
    slotId: 'slot-1',
    letter: 'B',
    number: number,
    order: order,
    createdAt: DateTime(2026, 6, 12, 12, 0, order),
    playerStatus: 'playing',
  );
}

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

void main() {
  group('number_called reconciliation flags', () {
    CalledNumberModel ball({required int order, int number = 7, String id = 'cn'}) {
      return _called(id: '$id-$order', order: order, number: number);
    }

    test('sequential draw appends locally without refresh flags', () {
      final result = applyLiveCalledNumberNotification(
        committed: [ball(order: 1), ball(order: 2, number: 12)],
        deferred: const [],
        incoming: ball(order: 3, number: 19),
      );

      expect(result.accepted.single.order, 3);
      expect(result.requiresCalledNumbersSync, isFalse);
      expect(result.requiresCanonicalSync, isFalse);
    });

    test('gap draw requests called-numbers-only sync', () {
      final result = applyLiveCalledNumberNotification(
        committed: [ball(order: 1), ball(order: 2, number: 12)],
        deferred: const [],
        incoming: ball(order: 4, number: 23),
      );

      expect(result.accepted, isEmpty);
      expect(result.requiresCalledNumbersSync, isTrue);
      expect(result.requiresCanonicalSync, isFalse);
      expect(result.expectedNextOrder, 3);
      expect(result.incomingOrder, 4);
    });

    test('conflicting order payload requests canonical sync', () {
      final result = applyLiveCalledNumberNotification(
        committed: [ball(order: 1), ball(order: 2, number: 12)],
        deferred: const [],
        incoming: ball(order: 2, number: 99, id: 'other'),
      );

      expect(result.requiresCalledNumbersSync, isFalse);
      expect(result.requiresCanonicalSync, isTrue);
    });
  });

  group('number_called dedup', () {
    test('duplicate sessionId+order+number is ignored completely', () {
      final controller = LiveCalledNumbersController(_FakeHost());
      final ball = _called(id: 'cn-1', order: 1, number: 7);

      final first = controller.applyNumberCalledSocket(
        calledNumber: ball,
        pauseStripForClaim: false,
      );
      final second = controller.applyNumberCalledSocket(
        calledNumber: _called(id: 'cn-1-dup', order: 1, number: 7),
        pauseStripForClaim: false,
      );

      expect(first?.applied, isTrue);
      expect(second, isNull);
      expect(controller.calledNumbers.length, 1);
      expect(controller.calledNumbers.first.number, 7);
    });

    test('draw dedup key matches session order and number', () {
      expect(
        calledDrawDedupKey(sessionId: 's1', order: 4, number: 23),
        's1|4|23',
      );
    });
  });

  group('called-number gap fill', () {
    test('canonical snapshot with already processed draw does not duplicate', () {
      final controller = LiveCalledNumbersController(_FakeHost());
      final first = _called(id: 'cn-1', order: 1, number: 7);
      controller.calledNumbers = [first];
      controller.rebuildCalledNumberTracking();

      controller.fillCalledNumberGaps([
        first,
        _called(id: 'cn-2', order: 2, number: 12),
      ]);

      expect(controller.calledNumbers.map((item) => item.order).toList(), [1, 2]);
      expect(controller.calledNumbers.length, 2);

      controller.fillCalledNumberGaps([
        first,
        _called(id: 'cn-2', order: 2, number: 12),
      ]);

      expect(controller.calledNumbers.length, 2);
      expect(controller.calledNumbers.last.number, 12);
    });

    test('gap fill adds only missing draws', () {
      final controller = LiveCalledNumbersController(_FakeHost());
      controller.calledNumbers = [_called(id: 'cn-1', order: 1, number: 7)];
      controller.rebuildCalledNumberTracking();

      controller.fillCalledNumberGaps([
        _called(id: 'cn-3', order: 3, number: 19),
      ]);

      expect(controller.calledNumbers.map((item) => item.order).toList(), [
        1,
        3,
      ]);
    });
  });

  group('nextAutoCallAt schedule dedup', () {
    test('same target is not treated as schedule change', () {
      final target = DateTime.utc(2026, 6, 10, 12);
      final game = _playingGame(nextAutoCallAt: target);
      final patch = patchGameFromNumberCalledPayload(game, {
        'nextAutoCallAt': target.toIso8601String(),
      });

      expect(patch.scheduleChanged, isFalse);
      expect(
        dateTimesEqualForSchedule(patch.game.nextAutoCallAt, target),
        isTrue,
      );
    });
  });

  group('stale recovery exclusivity', () {
    test('called-numbers and canonical do not fire together at 2s', () {
      var now = DateTime(2026, 1, 1, 12);
      final guard = NextBallStaleGuard(now: () => now);
      final game = _playingGame(
        nextAutoCallAt: now.subtract(const Duration(seconds: 1)),
      );

      guard.onScheduleOrBallEvent(
        target: game.nextAutoCallAt,
        sessionId: game.sessionId,
        rawRemaining: 0,
      );

      now = now.add(const Duration(seconds: 2));
      final atTwoSeconds = guard.evaluate(
        game: game,
        socketAutoCallEnabled: true,
        rawRemaining: 0,
      );

      expect(atTwoSeconds.shouldSyncCalledNumbers, isTrue);
      expect(atTwoSeconds.shouldRefetchCanonical, isFalse);
      expect(
        atTwoSeconds.shouldSyncCalledNumbers &&
            atTwoSeconds.shouldRefetchCanonical,
        isFalse,
      );

      guard.recordCalledNumbersSync(game.sessionId);
      now = now.add(const Duration(seconds: 4));
      final atFallback = guard.evaluate(
        game: game,
        socketAutoCallEnabled: true,
        rawRemaining: 0,
      );

      expect(atFallback.shouldRefetchCanonical, isTrue);
    });
  });

  group('server clock', () {
    test('ignoreOlder rejects stale serverNow samples', () {
      final clock = ServerClockService();
      final newer = DateTime.utc(2026, 6, 10, 12, 0, 10);
      final older = DateTime.utc(2026, 6, 10, 12, 0, 5);

      expect(clock.sync(newer, snap: true), isTrue);
      final offsetAfterNewer = clock.offsetMs;

      expect(
        clock.sync(older, snap: true, ignoreOlder: true),
        isFalse,
      );
      expect(clock.offsetMs, offsetAfterNewer);
      expect(clock.lastServerNowUtc, newer);
    });
  });
}
