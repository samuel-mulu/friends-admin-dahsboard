import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_display_order.dart';

void main() {
  final now = DateTime.utc(2026, 8, 7, 12);

  GameCartelaModel cartela(String id, int number) {
    return GameCartelaModel(
      id: id,
      gameId: 'session-1',
      userId: 'user-1',
      cartelaId: 'c-$id',
      status: GameCartelaStatus.registered,
      isWinner: false,
      blockedAt: null,
      createdAt: now,
      updatedAt: now,
      cartela: CartelaModel(id: 'c-$id', number: number, createdAt: now),
    );
  }

  group('Cartela auto-sort display order resolution (BUG-02)', () {
    test('detects when sorted cartela order changes while scroll is idle', () {
      final a = cartela('a', 1);
      final b = cartela('b', 2);

      final unchanged = hasCartelaDisplayOrderChanged(
        previousOrder: [a, b],
        nextOrder: [a, b],
      );
      expect(unchanged, isFalse);

      final reordered = hasCartelaDisplayOrderChanged(
        previousOrder: [a, b],
        nextOrder: [b, a],
      );
      expect(reordered, isTrue);
    });
  });
}

