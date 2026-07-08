import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_ready_atomic_visibility.dart';

void main() {
  group('resolveReadyAtomicVisibility', () {
    test('incomplete grid hides both banner and grid', () {
      final v = resolveReadyAtomicVisibility(
        hasReadyGame: true,
        gridReady: false,
        holdingPreviousReady: false,
      );
      expect(v.showBanner, isFalse);
      expect(v.showGrid, isFalse);
    });

    test('complete ready shows both', () {
      final v = resolveReadyAtomicVisibility(
        hasReadyGame: true,
        gridReady: true,
        holdingPreviousReady: false,
      );
      expect(v.showBanner, isTrue);
      expect(v.showGrid, isTrue);
    });

    test('holding previous ready keeps both until snapshot arrives', () {
      final v = resolveReadyAtomicVisibility(
        hasReadyGame: false,
        gridReady: false,
        holdingPreviousReady: true,
      );
      expect(v.showBanner, isTrue);
      expect(v.showGrid, isTrue);
    });

    test('empty state hides both when not holding', () {
      final v = resolveReadyAtomicVisibility(
        hasReadyGame: false,
        gridReady: false,
        holdingPreviousReady: false,
      );
      expect(v.showBanner, isFalse);
      expect(v.showGrid, isFalse);
    });
  });
}
