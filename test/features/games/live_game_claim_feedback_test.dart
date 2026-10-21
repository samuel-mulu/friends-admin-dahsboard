import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_called_numbers_controller.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_game_host.dart';

class _FakeLiveGameHost extends Fake implements LiveGameHost {}

void main() {
  group('LiveCalledNumbersController Claim Lock & Freeze Prevention', () {
    test('clearing claimingCartelaIds unlocks claim for subsequent attempts', () {
      final host = _FakeLiveGameHost();
      final controller = LiveCalledNumbersController(host);
      const cartelaId = 'cartela-123';

      controller.claimingCartelaIds.add(cartelaId);
      controller.claimStripHoldActive = true;
      expect(controller.claimingCartelaIds.contains(cartelaId), isTrue);
      expect(controller.claimStripHoldActive, isTrue);

      // Unconditional clear in finally block
      controller.claimStripHoldActive = false;
      controller.claimingCartelaIds.remove(cartelaId);
      controller.preClaimNextAutoCallAt = null;

      expect(controller.claimingCartelaIds.contains(cartelaId), isFalse);
      expect(controller.claimStripHoldActive, isFalse);
    });

    test('rememberBlockedCartelaReason captures code and message', () {
      final host = _FakeLiveGameHost();
      final controller = LiveCalledNumbersController(host);
      const cartelaId = 'cartela-456';

      controller.rememberBlockedCartelaReason(
        gameCartelaId: cartelaId,
        reasonCode: 'INVALID_LATE_CLAIM',
        serverReason: 'Pattern was completed on ball 22',
      );

      expect(controller.blockedReasonCodeFor(cartelaId), equals('INVALID_LATE_CLAIM'));
      expect(controller.blockedServerReasonFor(cartelaId), equals('Pattern was completed on ball 22'));
    });
  });
}
