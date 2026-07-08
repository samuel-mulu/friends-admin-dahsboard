import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_terminal_enter_policy.dart';

void main() {
  group('shouldEnterTerminalSideEffects', () {
    test('skips second enter when summary active and room left', () {
      expect(
        shouldEnterTerminalSideEffects(
          alreadyInSummary: true,
          sessionRoomActive: false,
          shouldRunTransition: true,
        ),
        isFalse,
      );
    });

    test('runs when transition needed and not already settled', () {
      expect(
        shouldEnterTerminalSideEffects(
          alreadyInSummary: false,
          sessionRoomActive: true,
          shouldRunTransition: true,
        ),
        isTrue,
      );
    });

    test('skips when shouldRunTransition is false', () {
      expect(
        shouldEnterTerminalSideEffects(
          alreadyInSummary: false,
          sessionRoomActive: true,
          shouldRunTransition: false,
        ),
        isFalse,
      );
    });

    test('runs when summary active but room still joined', () {
      expect(
        shouldEnterTerminalSideEffects(
          alreadyInSummary: true,
          sessionRoomActive: true,
          shouldRunTransition: true,
        ),
        isTrue,
      );
    });
  });
}
