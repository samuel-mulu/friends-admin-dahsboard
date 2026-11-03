import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/next_ball_stale_guard.dart';

void main() {
  group('NextBallStaleGuard strip-behind schedule reset', () {
    test('preserves overdue timer when schedule jumps but strip is behind', () {
      final clock = _FakeClock(DateTime.utc(2026, 10, 27, 12, 0, 0));
      final guard = NextBallStaleGuard(now: clock.now);

      guard.onScheduleOrBallEvent(
        target: DateTime.utc(2026, 10, 27, 12, 0, 0),
        sessionId: 'session-1',
        rawRemaining: 0,
        committedMaxOrder: 40,
        authoritativeCalledCount: 41,
      );

      clock.advance(const Duration(milliseconds: 1500));

      guard.onScheduleOrBallEvent(
        target: DateTime.utc(2026, 10, 27, 12, 0, 3),
        sessionId: 'session-1',
        rawRemaining: 3,
        committedMaxOrder: 40,
        authoritativeCalledCount: 41,
      );

      final evaluation = guard.evaluate(
        game: null,
        socketAutoCallEnabled: true,
        rawRemaining: 0,
        effectiveTarget: DateTime.utc(2026, 10, 27, 12, 0, 0),
        useEffectiveTarget: true,
      );

      expect(evaluation.zeroForMs, greaterThanOrEqualTo(1500));
    });

    test('resets overdue timer when strip is in sync', () {
      final clock = _FakeClock(DateTime.utc(2026, 10, 27, 12, 0, 0));
      final guard = NextBallStaleGuard(now: clock.now);

      guard.onScheduleOrBallEvent(
        target: DateTime.utc(2026, 10, 27, 12, 0, 0),
        sessionId: 'session-1',
        rawRemaining: 0,
        committedMaxOrder: 41,
        authoritativeCalledCount: 41,
      );

      clock.advance(const Duration(milliseconds: 500));

      guard.onScheduleOrBallEvent(
        target: DateTime.utc(2026, 10, 27, 12, 0, 3),
        sessionId: 'session-1',
        rawRemaining: 3,
        committedMaxOrder: 41,
        authoritativeCalledCount: 41,
      );

      final evaluation = guard.evaluate(
        game: null,
        socketAutoCallEnabled: true,
        rawRemaining: 3,
        effectiveTarget: DateTime.utc(2026, 10, 27, 12, 0, 3),
        useEffectiveTarget: true,
      );

      expect(evaluation.zeroForMs, 0);
    });
  });
}

class _FakeClock {
  _FakeClock(this._now);

  DateTime _now;

  DateTime now() => _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }
}
