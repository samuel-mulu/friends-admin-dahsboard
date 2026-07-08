import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/merge_registered_cartelas.dart';

GameCartelaModel _cartela({
  required String id,
  required String sessionId,
  int number = 5,
}) {
  final now = DateTime(2026, 6, 12);
  return GameCartelaModel(
    id: id,
    gameId: sessionId,
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
    ),
  );
}

void main() {
  group('mergeRegisteredCartelas', () {
    test('drops cartelas from a previous session', () {
      final merged = mergeRegisteredCartelas(
        current: [_cartela(id: 'gc-old', sessionId: 'session-old')],
        incoming: [_cartela(id: 'gc-new', sessionId: 'session-new')],
        sessionId: 'session-new',
      );

      expect(merged.map((item) => item.id), ['gc-new']);
    });

    test('rejects incoming cartelas with empty gameId when session is scoped', () {
      final incoming = _cartela(id: 'gc-new', sessionId: 'session-new');
      final stale = GameCartelaModel(
        id: 'gc-stale',
        gameId: '',
        userId: 'user-1',
        cartelaId: incoming.cartelaId,
        status: GameCartelaStatus.registered,
        isWinner: false,
        blockedAt: null,
        createdAt: incoming.createdAt,
        updatedAt: incoming.updatedAt,
        cartela: incoming.cartela,
      );

      final merged = mergeRegisteredCartelas(
        current: const [],
        incoming: [stale],
        sessionId: 'session-new',
      );

      expect(merged, isEmpty);
    });
  });
}
