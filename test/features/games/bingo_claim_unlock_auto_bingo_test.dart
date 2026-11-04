import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/application/controllers/live_countdown_controller.dart';
import 'package:friends_bingo_app/src/features/games/application/controllers/live_game_host.dart';

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

    test('last-second lock defaults off and turning it off clears the lock', () {
      final controller = LiveCountdownController(_FakeHost());
      expect(controller.bingoClaimLastSecondLockEnabled, isFalse);

      controller.bingoClaimLastSecondLockEnabled = true;
      controller.updateBingoClaimLocked(true);
      controller.syncBingoClaimLastSecondLockEnabled(
        enabled: false,
        game: null,
        autoCallActive: true,
        highestKnownCalledOrder: 4,
      );

      expect(controller.bingoClaimLocked.value, isFalse);
      expect(controller.bingoClaimLastSecondLockEnabled, isFalse);

      controller.dispose();
    });
  });
}
