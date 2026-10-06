import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_timing_config_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_game_host.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_review_controller.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_game_finish_transition.dart';

class _FakeHost implements LiveGameHost {
  _FakeHost({required this.now});

  DateTime now;

  @override
  bool mounted = true;

  @override
  GameModel? game;

  @override
  GameTimingConfigModel get effectiveTimingConfig =>
      GameTimingConfigModel.fallback;

  @override
  DateTime countdownNow({bool useServerClock = true}) => now;

  @override
  void markNeedsBuild([void Function()? fn]) => fn?.call();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LiveReviewController.scheduleAdvanceToNextGame', () {
    test('T11/T12 post-hold retry uses non-zero floor and single timer', () async {
      final host = _FakeHost(now: DateTime.utc(2026, 10, 6, 12));
      final review = LiveReviewController(host);
      var runs = 0;

      review.postGameSummaryReviewActive = true;
      review.postGameSummaryHoldBypassed = true;
      review.postGameSummaryShownAt = host.now;

      review.scheduleAdvanceToNextGame(
        runFinishedAdvanceSequence: ({bool force = false}) async {
          runs++;
        },
        minimumDelay: kPostGameAdvanceRetryDelay,
      );

      expect(review.finishTransitionTimer, isNotNull);
      expect(review.finishTransitionTimer!.isActive, isTrue);

      // Replacing schedule must cancel prior timer (single owner).
      review.scheduleAdvanceToNextGame(
        runFinishedAdvanceSequence: ({bool force = false}) async {
          runs++;
        },
        minimumDelay: kPostGameAdvanceRetryDelay,
      );
      expect(review.finishTransitionTimer, isNotNull);
      expect(review.finishTransitionTimer!.isActive, isTrue);

      await Future<void>.delayed(
        kPostGameAdvanceRetryDelay + const Duration(milliseconds: 50),
      );
      expect(runs, 1);

      review.dispose();
    });

    test('T5 Continue begin cancels pending retry timer', () {
      final host = _FakeHost(now: DateTime.utc(2026, 10, 6, 12));
      final review = LiveReviewController(host);

      review.postGameSummaryReviewActive = true;
      review.postGameSummaryHoldBypassed = true;
      review.postGameSummaryShownAt = host.now;

      review.scheduleAdvanceToNextGame(
        runFinishedAdvanceSequence: ({bool force = false}) async {},
        minimumDelay: kPostGameAdvanceRetryDelay,
      );
      expect(review.finishTransitionTimer?.isActive, isTrue);

      review.beginPostGameSummaryAdvance();
      expect(review.finishTransitionTimer, isNull);
      expect(review.postGameSummaryHoldBypassed, isTrue);
      expect(review.postGameSummaryAdvancing, isTrue);

      review.dispose();
    });

    test('initial hold schedule does not force retry floor', () {
      final host = _FakeHost(now: DateTime.utc(2026, 10, 6, 12));
      final review = LiveReviewController(host);

      review.postGameSummaryReviewActive = true;
      review.postGameSummaryHoldBypassed = false;
      review.postGameSummaryShownAt = host.now;

      review.scheduleAdvanceToNextGame(
        runFinishedAdvanceSequence: ({bool force = false}) async {},
      );

      expect(review.finishTransitionTimer, isNotNull);
      expect(review.finishTransitionTimer!.isActive, isTrue);
      // Hold is ~60s from fallback timing; must not be the 1s retry floor.
      expect(
        review.postGameSummaryHold.inSeconds,
        greaterThan(kPostGameAdvanceRetryDelay.inSeconds),
      );

      review.dispose();
    });
  });
}
