import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/number_called_status_policy.dart';

void main() {
  test('number_called never promotes status from READY', () {
    expect(
      shouldPromoteToPlayingFromNumberCalled(
        currentStatus: GameStatus.ready,
      ),
      isFalse,
    );
  });

  test('number_called never promotes status from PLAYING', () {
    expect(
      shouldPromoteToPlayingFromNumberCalled(
        currentStatus: GameStatus.playing,
      ),
      isFalse,
    );
  });

  test('number_called never promotes when status is null', () {
    expect(
      shouldPromoteToPlayingFromNumberCalled(currentStatus: null),
      isFalse,
    );
  });
}
