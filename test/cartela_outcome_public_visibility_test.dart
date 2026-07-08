import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/cartela_outcome_public_visibility.dart';

final _now = DateTime.utc(2026, 1, 1);

GameCartelaModel _cartela({
  required int number,
  required GameCartelaStatus status,
}) {
  return GameCartelaModel(
    id: 'gc-$number',
    gameId: 'game-1',
    userId: 'user-1',
    cartelaId: 'c-$number',
    status: status,
    isWinner: status == GameCartelaStatus.winner,
    blockedAt: status == GameCartelaStatus.blocked ? _now : null,
    createdAt: _now,
    updatedAt: _now,
    cartela: CartelaModel(
      id: 'c-$number',
      number: number,
      createdAt: _now,
    ),
  );
}

void main() {
  group('blockedCartelaNumbersForStrip', () {
    test('returns only own blocked cartelas', () {
      final numbers = blockedCartelaNumbersForStrip(
        myCartelas: [
          _cartela(number: 7, status: GameCartelaStatus.blocked),
          _cartela(number: 12, status: GameCartelaStatus.registered),
        ],
      );

      expect(numbers, [7]);
    });
  });

  group('winnerCartelaNumbersForStrip', () {
    test('shows public session winners during session-wide phases', () {
      final numbers = winnerCartelaNumbersForStrip(
        useSessionWideOutcomeChips: true,
        sessionWinnerCartelaNumbers: const [15, 42],
        myCartelas: [
          _cartela(number: 9, status: GameCartelaStatus.winner),
        ],
      );

      expect(numbers, [9, 15, 42]);
    });

    test('shows own winner chips outside session-wide phases', () {
      final numbers = winnerCartelaNumbersForStrip(
        useSessionWideOutcomeChips: false,
        sessionWinnerCartelaNumbers: const [15, 42],
        myCartelas: [
          _cartela(number: 9, status: GameCartelaStatus.winner),
          _cartela(number: 4, status: GameCartelaStatus.registered),
        ],
      );

      expect(numbers, [9]);
    });
  });

  group('checkingCartelaNumbersForStrip', () {
    test('returns only own checking cartelas', () {
      final numbers = checkingCartelaNumbersForStrip(
        claimingCartelaIds: {'gc-3'},
        myCartelas: [
          _cartela(number: 3, status: GameCartelaStatus.registered),
          _cartela(number: 8, status: GameCartelaStatus.registered),
        ],
      );

      expect(numbers, [3]);
    });
  });
}
