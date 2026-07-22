import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_status_socket_patch.dart';

void main() {
  group('shouldSkipOptimisticPlayingPatchForNonOwner', () {
    test('Player 2 READY→PLAYING without cartelas → skip', () {
      expect(
        shouldSkipOptimisticPlayingPatchForNonOwner(
          incomingStatus: 'PLAYING',
          priorPrimaryStatus: GameStatus.ready,
          ownsEventSessionByCartelas: false,
        ),
        isTrue,
      );
    });

    test('Player 1 READY→PLAYING with cartelas → do not skip', () {
      expect(
        shouldSkipOptimisticPlayingPatchForNonOwner(
          incomingStatus: 'PLAYING',
          priorPrimaryStatus: GameStatus.ready,
          ownsEventSessionByCartelas: true,
        ),
        isFalse,
      );
    });

    test('non-PLAYING status → do not skip', () {
      expect(
        shouldSkipOptimisticPlayingPatchForNonOwner(
          incomingStatus: 'WINNER_WINDOW',
          priorPrimaryStatus: GameStatus.ready,
          ownsEventSessionByCartelas: false,
        ),
        isFalse,
      );
    });

    test('already playing primary → do not skip via this gate', () {
      expect(
        shouldSkipOptimisticPlayingPatchForNonOwner(
          incomingStatus: 'PLAYING',
          priorPrimaryStatus: GameStatus.playing,
          ownsEventSessionByCartelas: false,
        ),
        isFalse,
      );
    });
  });
}
