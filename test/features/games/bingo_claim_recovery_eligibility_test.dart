import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_called_numbers_controller.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_game_host.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/bingo_claim_eligibility.dart';

class _FakeHost implements LiveGameHost {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

GameCartelaModel _cartela({
  required String id,
  GameCartelaStatus status = GameCartelaStatus.registered,
  bool isWinner = false,
}) {
  final now = DateTime.parse('2026-09-14T10:00:00.000Z');
  return GameCartelaModel(
    id: id,
    gameId: 'session-1',
    userId: 'user-1',
    cartelaId: 'cartela-$id',
    status: status,
    isWinner: isWinner,
    blockedAt: status == GameCartelaStatus.blocked ? now : null,
    createdAt: now,
    updatedAt: now,
    cartela: CartelaModel(id: 'cartela-$id', number: 7, createdAt: now),
  );
}

GameModel _playingGame() {
  final now = DateTime.parse('2026-09-14T10:00:00.000Z');
  return GameModel(
    id: 'slot-1',
    sessionId: 'session-1',
    staticCode: 'N-1',
    playCode: 'PLAY-1',
    name: 'Test',
    gameRule: GameRuleModel(id: 'rule-1', key: 'ONE_LINE', name: 'One Line'),
    gameType: 'ONE_LINE',
    entryFee: '10',
    prizePerCartela: '0',
    companyFeePerCartela: '10',
    prizeAmount: '100',
    companyRevenue: '0',
    status: GameStatus.playing,
    playOrder: 1,
    startedAt: now,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 1,
    calledNumbersCount: 5,
    registrationOpen: false,
    canRegister: false,
    category: GameCategory.normal,
  );
}

void main() {
  group('claim recovery failed eligibility', () {
    test('blocks Bingo while recovery-failed id is set', () {
      final controller = LiveCalledNumbersController(_FakeHost());
      final cartela = _cartela(id: 'gc-1');
      controller.claimRecoveryFailedCartelaIds.add('gc-1');

      expect(
        controller.canClaimBingoForCartela(
          game: _playingGame(),
          gameCartela: cartela,
          winnerWindowExpired: false,
          isCountdownLocked: false,
        ),
        isFalse,
      );

      controller.claimRecoveryFailedCartelaIds.clear();
      expect(
        controller.canClaimBingoForCartela(
          game: _playingGame(),
          gameCartela: cartela,
          winnerWindowExpired: false,
          isCountdownLocked: false,
        ),
        isTrue,
      );
    });

    test('session clear resets recovery-failed locks', () {
      final controller = LiveCalledNumbersController(_FakeHost());
      controller.claimRecoveryFailedCartelaIds.add('gc-1');
      controller.clearSessionScopedState();
      expect(controller.claimRecoveryFailedCartelaIds, isEmpty);
    });
  });

  group('bingo claim eligibility unchanged for terminal statuses', () {
    test('blocked cartela cannot claim', () {
      expect(
        isCartelaEligibleForBingoClaim(
          game: _playingGame(),
          gameCartela: _cartela(
            id: 'gc-1',
            status: GameCartelaStatus.blocked,
          ),
          winnerWindowExpired: false,
          hasPendingClaim: false,
          isCountdownLocked: false,
          calledNumbersCount: 3,
        ),
        isFalse,
      );
    });

    test('winner cartela cannot claim', () {
      expect(
        isCartelaEligibleForBingoClaim(
          game: _playingGame(),
          gameCartela: _cartela(
            id: 'gc-1',
            status: GameCartelaStatus.winner,
            isWinner: true,
          ),
          winnerWindowExpired: false,
          hasPendingClaim: false,
          isCountdownLocked: false,
          calledNumbersCount: 3,
        ),
        isFalse,
      );
    });
  });
}
