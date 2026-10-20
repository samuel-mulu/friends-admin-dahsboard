import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/called_balls_notifier.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/player_cartelas_notifier.dart';

void main() {
  group('CalledBallsNotifier Tests', () {
    test('adds balls in monotonic sequence and ignores duplicates', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(calledBallsNotifierProvider.notifier);
      expect(container.read(calledBallsNotifierProvider), isEmpty);

      final now = DateTime.now();
      notifier.addBall(CalledNumberModel(
        id: '1',
        sessionId: 's1',
        letter: 'B',
        number: 5,
        order: 1,
        createdAt: now,
      ));
      expect(container.read(calledBallsNotifierProvider).length, 1);

      // Duplicate order/number ignored
      notifier.addBall(CalledNumberModel(
        id: '2',
        sessionId: 's1',
        letter: 'B',
        number: 5,
        order: 1,
        createdAt: now,
      ));
      expect(container.read(calledBallsNotifierProvider).length, 1);

      // Next monotonic ball added
      notifier.addBall(CalledNumberModel(
        id: '3',
        sessionId: 's1',
        letter: 'I',
        number: 20,
        order: 2,
        createdAt: now,
      ));
      expect(container.read(calledBallsNotifierProvider).length, 2);
    });
  });

  group('PlayerCartelasNotifier Tests', () {
    test('toggles marked cell numbers per cartela', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(playerCartelasNotifierProvider.notifier);
      expect(container.read(playerCartelasNotifierProvider), isEmpty);

      notifier.toggleMark('cartela-1', 12);
      expect(container.read(playerCartelasNotifierProvider)['cartela-1'], contains(12));

      notifier.toggleMark('cartela-1', 12);
      expect(container.read(playerCartelasNotifierProvider)['cartela-1'], isNot(contains(12)));
    });
  });
}
