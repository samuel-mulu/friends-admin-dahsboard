import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/bulk_register_result.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/merge_registered_cartelas.dart';

void main() {
  final now = DateTime.now();

  GameCartelaModel createDummyCartela({
    required String id,
    required String gameId,
    required int number,
  }) {
    return GameCartelaModel(
      id: id,
      gameId: gameId,
      userId: 'user-1',
      cartelaId: 'c-$number',
      status: GameCartelaStatus.registered,
      isWinner: false,
      blockedAt: null,
      createdAt: now,
      updatedAt: now,
      cartela: CartelaModel(
        id: 'c-$number',
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

  group('Multi-Registration Card Retention Tests', () {
    test('mergeRegisteredCartelas retains both first and second registration batches', () {
      final batch1 = [
        createDummyCartela(id: 'gc-1', gameId: 'session-1', number: 10),
        createDummyCartela(id: 'gc-2', gameId: 'session-1', number: 20),
      ];

      final batch2 = [
        createDummyCartela(id: 'gc-3', gameId: 'session-1', number: 30),
        createDummyCartela(id: 'gc-4', gameId: 'session-1', number: 40),
      ];

      final merged = mergeRegisteredCartelas(
        current: batch1,
        incoming: batch2,
        sessionId: 'session-1',
      );

      expect(merged.length, 4);
      final numbers = merged.map((c) => c.cartela.number).toList();
      expect(numbers, containsAll([10, 20, 30, 40]));
    });

    test('mergeRegisteredCartelas does not duplicate already registered cartela', () {
      final batch1 = [
        createDummyCartela(id: 'gc-1', gameId: 'session-1', number: 10),
        createDummyCartela(id: 'gc-2', gameId: 'session-1', number: 20),
      ];

      final updatedBatch = [
        createDummyCartela(id: 'gc-1', gameId: 'session-1', number: 10),
        createDummyCartela(id: 'gc-3', gameId: 'session-1', number: 30),
      ];

      final merged = mergeRegisteredCartelas(
        current: batch1,
        incoming: updatedBatch,
        sessionId: 'session-1',
      );

      expect(merged.length, 3);
      final numbers = merged.map((c) => c.cartela.number).toList();
      expect(numbers, [10, 20, 30]);
    });

    test('BulkRegisterResult exposes cumulative myCartelas when provided by backend', () {
      final cumulative = [
        createDummyCartela(id: 'gc-1', gameId: 'session-1', number: 10),
        createDummyCartela(id: 'gc-2', gameId: 'session-1', number: 20),
      ];

      final result = BulkRegisterResult(
        successes: [cumulative[1]],
        failures: const [],
        myCartelas: cumulative,
      );

      expect(result.hasSuccesses, isTrue);
      expect(result.hasFailures, isFalse);
      expect(result.myCartelas, isNotNull);
      expect(result.myCartelas!.length, 2);
    });
  });
}
