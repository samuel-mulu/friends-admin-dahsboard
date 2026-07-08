import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_game_finish_transition.dart';

void main() {
  group('shouldRunFinishTransition', () {
    test('runs when game is not finished yet', () {
      expect(
        shouldRunFinishTransition(
          currentStatus: GameStatus.playing,
          sessionRoomActive: true,
          summaryScheduled: false,
        ),
        isTrue,
      );
    });

    test('runs when finished but session room is still active', () {
      expect(
        shouldRunFinishTransition(
          currentStatus: GameStatus.finished,
          sessionRoomActive: true,
          summaryScheduled: false,
        ),
        isTrue,
      );
    });

    test('runs when finished but summary has not been scheduled', () {
      expect(
        shouldRunFinishTransition(
          currentStatus: GameStatus.finished,
          sessionRoomActive: false,
          summaryScheduled: false,
        ),
        isTrue,
      );
    });

    test('skips when finished, room left, and summary already scheduled', () {
      expect(
        shouldRunFinishTransition(
          currentStatus: GameStatus.finished,
          sessionRoomActive: false,
          summaryScheduled: true,
        ),
        isFalse,
      );
    });
  });

  group('shouldRunCancelTransition', () {
    test('runs when game is not cancelled yet', () {
      expect(
        shouldRunCancelTransition(
          currentStatus: GameStatus.playing,
          sessionRoomActive: false,
        ),
        isTrue,
      );
    });

    test('runs when cancelled but room is still active', () {
      expect(
        shouldRunCancelTransition(
          currentStatus: GameStatus.cancelled,
          sessionRoomActive: true,
        ),
        isTrue,
      );
    });

    test('skips when cancelled transition already released the room', () {
      expect(
        shouldRunCancelTransition(
          currentStatus: GameStatus.cancelled,
          sessionRoomActive: false,
        ),
        isFalse,
      );
    });
  });

  group('isTerminalGameStatus', () {
    test('recognizes finished and cancelled', () {
      expect(isTerminalGameStatus(GameStatus.finished), isTrue);
      expect(isTerminalGameStatus(GameStatus.cancelled), isTrue);
      expect(isTerminalGameStatus(GameStatus.playing), isFalse);
    });
  });
}
