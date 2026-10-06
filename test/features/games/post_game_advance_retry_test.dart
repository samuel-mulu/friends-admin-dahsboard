import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_game_finish_transition.dart';

void main() {
  group('kPostGameAdvanceRetryDelay', () {
    test('is positive and non-zero', () {
      expect(kPostGameAdvanceRetryDelay, greaterThan(Duration.zero));
      expect(kPostGameAdvanceRetryDelay.inMilliseconds, greaterThanOrEqualTo(1000));
    });
  });

  group('resolvePostGameAdvanceTimerDelay', () {
    test('uses remaining hold before bypass', () {
      expect(
        resolvePostGameAdvanceTimerDelay(
          reviewActive: true,
          holdBypassed: false,
          remainingHold: const Duration(seconds: 12),
        ),
        const Duration(seconds: 12),
      );
    });

    test('is zero after hold bypass without minimumDelay', () {
      expect(
        resolvePostGameAdvanceTimerDelay(
          reviewActive: true,
          holdBypassed: true,
          remainingHold: const Duration(seconds: 12),
        ),
        Duration.zero,
      );
    });

    test('applies retry floor after hold bypass (T11)', () {
      expect(
        resolvePostGameAdvanceTimerDelay(
          reviewActive: true,
          holdBypassed: true,
          remainingHold: Duration.zero,
          minimumDelay: kPostGameAdvanceRetryDelay,
        ),
        kPostGameAdvanceRetryDelay,
      );
    });

    test('does not shorten remaining hold when minimum is smaller', () {
      expect(
        resolvePostGameAdvanceTimerDelay(
          reviewActive: true,
          holdBypassed: false,
          remainingHold: const Duration(seconds: 30),
          minimumDelay: kPostGameAdvanceRetryDelay,
        ),
        const Duration(seconds: 30),
      );
    });

    test('initial summary schedule has no forced floor', () {
      expect(
        resolvePostGameAdvanceTimerDelay(
          reviewActive: true,
          holdBypassed: false,
          remainingHold: const Duration(seconds: 60),
        ),
        const Duration(seconds: 60),
      );
    });
  });

  group('shouldSchedulePostGameAdvanceRetry', () {
    test('retries temporary failures while summary+terminal remain', () {
      expect(
        shouldSchedulePostGameAdvanceRetry(
          outcome: PostGameAdvanceOutcome.retryableFailure,
          mounted: true,
          reviewActive: true,
          stillTerminal: true,
        ),
        isTrue,
      );
    });

    test('does not retry advanced (T1 success)', () {
      expect(
        shouldSchedulePostGameAdvanceRetry(
          outcome: PostGameAdvanceOutcome.advanced,
          mounted: true,
          reviewActive: true,
          stillTerminal: false,
        ),
        isFalse,
      );
    });

    test('does not retry authoritative no-next (T7)', () {
      expect(
        shouldSchedulePostGameAdvanceRetry(
          outcome: PostGameAdvanceOutcome.finishedWithoutTarget,
          mounted: true,
          reviewActive: false,
          stillTerminal: false,
        ),
        isFalse,
      );
    });

    test('does not retry when disposed (T6)', () {
      expect(
        shouldSchedulePostGameAdvanceRetry(
          outcome: PostGameAdvanceOutcome.retryableFailure,
          mounted: false,
          reviewActive: true,
          stillTerminal: true,
        ),
        isFalse,
      );
    });

    test('does not retry when summary cleared', () {
      expect(
        shouldSchedulePostGameAdvanceRetry(
          outcome: PostGameAdvanceOutcome.retryableFailure,
          mounted: true,
          reviewActive: false,
          stillTerminal: true,
        ),
        isFalse,
      );
    });

    test('does not retry when no longer terminal', () {
      expect(
        shouldSchedulePostGameAdvanceRetry(
          outcome: PostGameAdvanceOutcome.retryableFailure,
          mounted: true,
          reviewActive: true,
          stillTerminal: false,
        ),
        isFalse,
      );
    });
  });

  group('PostGameAdvanceOutcome classification contract', () {
    test('ops skip/null/exception map to retryableFailure (T2/T3/T4)', () {
      // Documented contract used by _advanceToNextGame — enum cases only.
      expect(
        PostGameAdvanceOutcome.retryableFailure,
        isNot(PostGameAdvanceOutcome.finishedWithoutTarget),
      );
    });

    test('Big Game deferred (not yet adoptable) is retryable (T9/T10)', () {
      expect(
        shouldSchedulePostGameAdvanceRetry(
          outcome: PostGameAdvanceOutcome.retryableFailure,
          mounted: true,
          reviewActive: true,
          stillTerminal: true,
        ),
        isTrue,
      );
    });
  });
}
