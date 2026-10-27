import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/called_numbers_strip_heal.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/next_ball_countdown.dart';

void main() {
  group('shouldHealAfterAutoCallSchedulePatch', () {
    test('does not heal when authoritative count matches committed strip', () {
      expect(
        shouldHealAfterAutoCallSchedulePatch(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          scheduleChanged: true,
          committedMax: 40,
          gameCalledNumbersCount: 40,
          payloadCalledNumbersCount: 40,
          wasInCallingPhase: true,
          callingBaselineOrder: 40,
        ),
        isFalse,
      );
    });

    test('heals when payload count is ahead of committed strip', () {
      expect(
        shouldHealAfterAutoCallSchedulePatch(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          scheduleChanged: true,
          committedMax: 40,
          gameCalledNumbersCount: 40,
          payloadCalledNumbersCount: 41,
          wasInCallingPhase: false,
          callingBaselineOrder: null,
        ),
        isTrue,
      );
    });

    test('does not heal on schedule-only change without count advance', () {
      expect(
        shouldHealAfterAutoCallSchedulePatch(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          scheduleChanged: true,
          committedMax: 40,
          gameCalledNumbersCount: 40,
          payloadCalledNumbersCount: 40,
          wasInCallingPhase: false,
          callingBaselineOrder: null,
        ),
        isFalse,
      );
    });

    test('fallback heal after calling when payload count absent', () {
      expect(
        shouldHealAfterAutoCallSchedulePatch(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          scheduleChanged: true,
          committedMax: 40,
          gameCalledNumbersCount: 40,
          payloadCalledNumbersCount: null,
          wasInCallingPhase: true,
          callingBaselineOrder: 40,
        ),
        isTrue,
      );
    });
  });

  group('wasInCallingPlayPhase', () {
    test('detects calling phase', () {
      expect(
        wasInCallingPlayPhase(NextBallPlayPhase.calling),
        isTrue,
      );
      expect(
        wasInCallingPlayPhase(NextBallPlayPhase.counting),
        isFalse,
      );
    });
  });
}
