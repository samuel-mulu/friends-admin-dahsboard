import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_countdown_controller.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_game_host.dart';

class _FakeHost implements LiveGameHost {
  @override
  bool get isLiveHostActive => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('bingoClaimLocked unlock resumes Auto Bingo (A6.3)', () {
    test('onBingoClaimUnlocked fires only on true → false', () {
      final controller = LiveCountdownController(_FakeHost());
      var unlockCount = 0;
      controller.onBingoClaimUnlocked = () => unlockCount++;

      controller.updateBingoClaimLocked(false);
      expect(unlockCount, 0);

      controller.updateBingoClaimLocked(true);
      expect(unlockCount, 0);

      controller.updateBingoClaimLocked(true);
      expect(unlockCount, 0);

      controller.updateBingoClaimLocked(false);
      expect(unlockCount, 1);

      controller.updateBingoClaimLocked(false);
      expect(unlockCount, 1);

      controller.dispose();
    });
  });
}
