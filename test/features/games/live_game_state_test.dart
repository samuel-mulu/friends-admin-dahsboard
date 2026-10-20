import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/domain/live_game_state.dart';

void main() {
  group('LiveGameState Tests', () {
    test('initial state flags work as expected', () {
      const state = LiveGameState.initial();
      expect(state.isLoading, false);
      expect(state.isReady, false);
      expect(state.isPlaying, false);
      expect(state.isWinnerWindow, false);
      expect(state.isFinished, false);
      expect(state.isCancelled, false);
    });

    test('ready state exposes countdown and count', () {
      const ready = LiveGameState.ready(
        remainingSeconds: 120,
        registeredCount: 4,
      );
      expect(ready.isReady, true);
      expect(ready.isPlaying, false);
      expect((ready as LiveGameReadyState).remainingSeconds, 120);
      expect(ready.registeredCount, 4);
    });

    test('cancelled state exposes reason', () {
      const cancelled = LiveGameState.cancelled(reason: 'no_players');
      expect(cancelled.isCancelled, true);
      expect((cancelled as LiveGameCancelledState).reason, 'no_players');
    });
  });
}
