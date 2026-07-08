import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/time/countdown_target_tracker.dart';

void main() {
  test('stays at zero after latch until target moves forward', () {
    final tracker = CountdownTargetTracker();
    final target = DateTime(2026, 6, 18, 12, 0, 0);
    const scope = 'session-1';

    expect(
      tracker.apply(target: target, scopeKey: scope, rawRemaining: 0),
      0,
    );
    expect(
      tracker.apply(target: target, scopeKey: scope, rawRemaining: 256),
      0,
    );

    final newerTarget = target.add(const Duration(seconds: 30));
    expect(
      tracker.apply(target: newerTarget, scopeKey: scope, rawRemaining: 30),
      30,
    );
  });

  test('reset clears latch', () {
    final tracker = CountdownTargetTracker();
    final target = DateTime(2026, 6, 18, 12, 0, 0);

    tracker.apply(target: target, scopeKey: 'session-1', rawRemaining: 0);
    tracker.reset();

    expect(
      tracker.apply(target: target, scopeKey: 'session-1', rawRemaining: 12),
      12,
    );
  });

  test('reset then newer socket target resumes countdown', () {
    final tracker = CountdownTargetTracker();
    final expiredTarget = DateTime(2026, 6, 18, 12, 0, 0);
    const scope = 'session-1';

    tracker.apply(target: expiredTarget, scopeKey: scope, rawRemaining: 0);
    tracker.reset();

    final newerTarget = expiredTarget.add(const Duration(seconds: 7));
    expect(
      tracker.apply(
        target: newerTarget,
        scopeKey: scope,
        rawRemaining: 7,
      ),
      7,
    );
  });
}
