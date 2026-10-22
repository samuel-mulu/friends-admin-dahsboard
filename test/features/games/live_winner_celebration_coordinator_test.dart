import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/application/controllers/live_winner_celebration_coordinator.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/round_winner_history_adapters.dart';

void main() {
  group('LiveWinnerCelebrationCoordinator Tests', () {
    test('tracks winner cartela numbers without duplicates', () {
      final coordinator = LiveWinnerCelebrationCoordinator();
      coordinator.recordWinnerCartela(42);
      coordinator.recordWinnerCartela(42);
      coordinator.recordWinnerCartela(17);

      expect(coordinator.winnerCartelaNumbers, equals([42, 17]));
    });

    test('calculates auto dismiss duration based on winnerWindowEndsAt', () {
      final coordinator = LiveWinnerCelebrationCoordinator();
      final now = DateTime(2026, 10, 22, 12, 0, 0);

      // 1. Future winnerWindowEndsAt with 10s remaining -> 10 + 4 = 14s
      final futureEndsAt = now.add(const Duration(seconds: 10));
      expect(
        coordinator.calculateAutoDismissDuration(futureEndsAt, now: now),
        equals(const Duration(seconds: 14)),
      );

      // 2. Past winnerWindowEndsAt -> fallback 8s
      final pastEndsAt = now.subtract(const Duration(seconds: 5));
      expect(
        coordinator.calculateAutoDismissDuration(pastEndsAt, now: now),
        equals(const Duration(seconds: 8)),
      );

      // 3. Null winnerWindowEndsAt -> fallback 8s
      expect(
        coordinator.calculateAutoDismissDuration(null, now: now),
        equals(const Duration(seconds: 8)),
      );
    });

    test('manages all-rounds winner history caching and state transitions', () {
      final coordinator = LiveWinnerCelebrationCoordinator();
      const cacheKey = 'session-123:3:3';

      expect(coordinator.allRoundsWinnerHistoryLoading, isFalse);
      expect(coordinator.allRoundsWinnerHistoryKey, isNull);

      coordinator.startAllRoundsHistoryLoading(cacheKey);
      expect(coordinator.allRoundsWinnerHistoryLoading, isTrue);
      expect(coordinator.allRoundsWinnerHistoryKey, equals(cacheKey));
      expect(coordinator.allRoundsWinnerHistoryError, isNull);

      const dummyCards = <AllRoundsWinnerCardData>[
        AllRoundsWinnerCardData(
          roundIndex: 1,
          roundCount: 3,
          cartelaNumber: 42,
          amount: '100',
          prizeAmount: '100 ETB',
          isNoWinner: false,
          winnerResults: [],
        ),
      ];

      coordinator.setAllRoundsHistory(
        null,
        dummyCards,
        key: cacheKey,
      );

      expect(coordinator.allRoundsWinnerHistoryLoading, isFalse);
      expect(coordinator.allRoundsWinnerCards.length, equals(1));
      expect(coordinator.allRoundsWinnerHistoryError, isNull);

      // Reset
      coordinator.reset();
      expect(coordinator.winnerCartelaNumbers, isEmpty);
      expect(coordinator.allRoundsWinnerCards, isEmpty);
      expect(coordinator.allRoundsWinnerHistoryLoading, isFalse);
      expect(coordinator.allRoundsWinnerHistoryKey, isNull);
    });
  });
}
