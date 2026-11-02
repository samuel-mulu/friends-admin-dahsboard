import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_timing_config_model.dart';
import 'package:friends_bingo_app/src/features/games/application/controllers/live_game_host.dart';
import 'package:friends_bingo_app/src/features/games/application/controllers/live_review_controller.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_game_finish_transition.dart';

class _TimingHost implements LiveGameHost {
  _TimingHost({
    required this.now,
    required this.timingConfig,
  });

  DateTime now;
  final GameTimingConfigModel timingConfig;

  @override
  bool mounted = true;

  @override
  GameModel? game;

  @override
  GameTimingConfigModel get effectiveTimingConfig => timingConfig;

  @override
  DateTime countdownNow({bool useServerClock = true}) => now;

  @override
  void markNeedsBuild([void Function()? fn]) => fn?.call();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('post-game summary hold vs winner dialog', () {
    test('shouldPausePostGameSummaryHoldForWinnerDialog', () {
      expect(
        shouldPausePostGameSummaryHoldForWinnerDialog(
          postGameSummaryReviewActive: true,
          holdBypassed: false,
          advancing: false,
          chainInterRoundDialog: false,
        ),
        isTrue,
      );
      expect(
        shouldPausePostGameSummaryHoldForWinnerDialog(
          postGameSummaryReviewActive: true,
          holdBypassed: false,
          advancing: false,
          chainInterRoundDialog: true,
        ),
        isFalse,
      );
      expect(
        shouldPausePostGameSummaryHoldForWinnerDialog(
          postGameSummaryReviewActive: false,
          holdBypassed: false,
          advancing: false,
          chainInterRoundDialog: false,
        ),
        isFalse,
      );
      expect(
        shouldPausePostGameSummaryHoldForWinnerDialog(
          postGameSummaryReviewActive: true,
          holdBypassed: true,
          advancing: false,
          chainInterRoundDialog: false,
        ),
        isFalse,
      );
    });

    test('shouldRestartPostGameSummaryHoldAfterWinnerDialog', () {
      expect(
        shouldRestartPostGameSummaryHoldAfterWinnerDialog(
          pauseWasActive: true,
          postGameSummaryReviewActive: true,
          holdBypassed: false,
          advancing: false,
        ),
        isTrue,
      );
      expect(
        shouldRestartPostGameSummaryHoldAfterWinnerDialog(
          pauseWasActive: false,
          postGameSummaryReviewActive: true,
          holdBypassed: false,
          advancing: false,
        ),
        isFalse,
      );
    });

    test('hold restart reschedules full finishedResultDisplaySeconds', () {
      const finishedSeconds = 40;
      const patternSeconds = 8;
      final timingConfig = GameTimingConfigModel(
        registrationDurationSeconds: 180,
        autoCallIntervalSeconds: 18,
        winnerWindowSeconds: 25,
        cartelaHoldSeconds: 10,
        bulkSelectionHoldSeconds: 120,
        finishedResultDisplaySeconds: finishedSeconds,
        winningPatternDisplaySeconds: patternSeconds,
        preparingDisplayMaxSeconds: null,
        missedNumberAnimationMs: 150,
        missedNumberStaggerMaxBalls: 10,
        flutterRefetchDebounceMs: 400,
      );

      final host = _TimingHost(
        now: DateTime.utc(2026, 10, 31, 12),
        timingConfig: timingConfig,
      );
      final review = LiveReviewController(host);

      review.postGameSummaryReviewActive = true;
      review.postGameSummaryHoldBypassed = false;
      review.postGameSummaryShownAt = host.now.subtract(const Duration(seconds: 5));

      var advanceRuns = 0;
      review.scheduleAdvanceToNextGame(
        runFinishedAdvanceSequence: ({bool force = false}) async {
          advanceRuns++;
          expect(force, isFalse);
        },
      );
      expect(review.finishTransitionTimer?.isActive, isTrue);

      // Simulate dialog close: full hold restart (orchestration does this).
      review.postGameSummaryShownAt = host.now;
      review.scheduleAdvanceToNextGame(
        runFinishedAdvanceSequence: ({bool force = false}) async {
          advanceRuns++;
        },
      );

      expect(review.postGameSummaryHoldBypassed, isFalse);
      expect(review.postGameSummaryAdvancing, isFalse);
      expect(review.postGameSummaryHold.inSeconds, finishedSeconds);
      expect(
        review.postGameSummaryHold.inSeconds,
        greaterThan(patternSeconds),
      );

      review.dispose();
    });

    test('winningPatternDisplayHold comes from timing config', () {
      const patternSeconds = 10;
      final config = GameTimingConfigModel(
        registrationDurationSeconds: 180,
        autoCallIntervalSeconds: 18,
        winnerWindowSeconds: 25,
        cartelaHoldSeconds: 10,
        bulkSelectionHoldSeconds: 120,
        finishedResultDisplaySeconds: 40,
        winningPatternDisplaySeconds: patternSeconds,
        preparingDisplayMaxSeconds: null,
        missedNumberAnimationMs: 150,
        missedNumberStaggerMaxBalls: 10,
        flutterRefetchDebounceMs: 400,
      );
      expect(config.winningPatternDisplayHold.inSeconds, patternSeconds);
    });
  });
}
