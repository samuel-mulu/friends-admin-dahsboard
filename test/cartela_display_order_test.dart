import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/cartela_display_order.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1);

  GameCartelaModel cartela({required String id, required int number}) {
    return GameCartelaModel(
      id: id,
      gameId: 'game-1',
      userId: 'user-1',
      cartelaId: 'cartela-$number',
      status: GameCartelaStatus.registered,
      isWinner: false,
      blockedAt: null,
      createdAt: now,
      updatedAt: now,
      cartela: CartelaModel(
        id: 'cartela-$number',
        number: number,
        createdAt: now,
        b: const ['1', '2', '3', '4', '5'],
        i: const ['16', '17', '18', '19', '20'],
        n: const ['31', '32', 'FREE', '34', '35'],
        g: const ['46', '47', '48', '49', '50'],
        o: const ['61', '62', '63', '64', '65'],
      ),
    );
  }

  group('applyCartelaDisplayOrder', () {
    test('returns original list when order is empty', () {
      final cartelas = [cartela(id: 'a', number: 10), cartela(id: 'b', number: 20)];

      final ordered = applyCartelaDisplayOrder(cartelas: cartelas, orderIds: const []);

      expect(ordered, cartelas);
    });

    test('applies saved order and appends new cartelas by number', () {
      final cartelas = [
        cartela(id: 'a', number: 10),
        cartela(id: 'b', number: 20),
        cartela(id: 'c', number: 30),
      ];

      final ordered = applyCartelaDisplayOrder(
        cartelas: cartelas,
        orderIds: const ['c', 'a'],
      );

      expect(ordered.map((item) => item.id).toList(), ['c', 'a', 'b']);
    });

    test('ignores stale ids in saved order', () {
      final cartelas = [cartela(id: 'a', number: 10), cartela(id: 'b', number: 20)];

      final ordered = applyCartelaDisplayOrder(
        cartelas: cartelas,
        orderIds: const ['missing', 'b', 'a'],
      );

      expect(ordered.map((item) => item.id).toList(), ['b', 'a']);
    });
  });

  group('reorderCartelaDisplayOrderIds', () {
    test('moves cartela from one index to another', () {
      final cartelas = [
        cartela(id: 'a', number: 10),
        cartela(id: 'b', number: 20),
        cartela(id: 'c', number: 30),
      ];

      final ids = reorderCartelaDisplayOrderIds(
        cartelas: cartelas,
        fromIndex: 0,
        toIndex: 2,
      );

      expect(ids, ['b', 'c', 'a']);
    });
  });
}
