import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/chain_round_plan_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/cartela_selection_cap.dart';

void main() {
  group('minCartelaSelectionCap', () {
    test('Chain Game bulk is min(balance, max remaining)', () {
      expect(minCartelaSelectionCap(5, 10), 5);
      expect(minCartelaSelectionCap(5, 3), 3);
      expect(minCartelaSelectionCap(0, 10), 0);
    });

    test('falls back to the non-null cap', () {
      expect(minCartelaSelectionCap(null, 4), 4);
      expect(minCartelaSelectionCap(5, null), 5);
      expect(minCartelaSelectionCap(null, null), isNull);
    });
  });

  group('remainingCartelaLimit', () {
    test('does not go below zero', () {
      expect(
        remainingCartelaLimit(maxPerPlayer: 5, alreadyRegistered: 2),
        3,
      );
      expect(
        remainingCartelaLimit(maxPerPlayer: 5, alreadyRegistered: 5),
        0,
      );
      expect(
        remainingCartelaLimit(maxPerPlayer: 5, alreadyRegistered: 8),
        0,
      );
    });
  });

  group('ChainRoundPlan.fromGame', () {
    test('lists every round prize during registration', () {
      final now = DateTime.parse('2026-09-14T10:00:00.000Z');
      final plan = ChainRoundPlan.fromGame(
        GameModel(
          id: 'slot-chain',
          sessionId: 'session-chain',
          staticCode: 'CH-1',
          playCode: 'PLAY-CH',
          name: 'Chain Game',
          gameRule: GameRuleModel(
            id: 'rule-1',
            key: 'ONE_LINE',
            name: 'One Line',
          ),
          gameType: 'ONE_LINE',
          entryFee: '25',
          prizePerCartela: '0',
          companyFeePerCartela: '25',
          prizeAmount: '5000',
          companyRevenue: '0',
          status: GameStatus.ready,
          playOrder: 1,
          startedAt: now,
          finishedAt: null,
          createdAt: now,
          updatedAt: now,
          registeredCartelasCount: 0,
          calledNumbersCount: 0,
          registrationOpen: true,
          canRegister: true,
          category: GameCategory.chainGame,
          roundCount: 2,
          roundIndex: 1,
          roundPrizes: const ['3000', '2000'],
          roundPrizeAmount: '3000',
        ),
      );

      expect(plan.roundCount, 2);
      expect(plan.rounds.map((round) => round.prizeAmount).toList(), [
        '3000',
        '2000',
      ]);
      expect(plan.rounds.first.state, ChainRoundState.current);
      expect(plan.rounds.last.state, ChainRoundState.upcoming);
    });
  });
}
