import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/bingo_claim_eligibility.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_called_number_sync.dart';

GameCartelaModel _registeredCartela({required String id}) {
  final now = DateTime.utc(2026, 6, 12);
  return GameCartelaModel(
    id: id,
    gameId: 'session-1',
    userId: 'user-1',
    cartelaId: 'cartela-1',
    status: GameCartelaStatus.registered,
    isWinner: false,
    blockedAt: null,
    createdAt: now,
    updatedAt: now,
    cartela: CartelaModel(
      id: 'cartela-1',
      number: 12,
      createdAt: now,
      b: const ['1', '6', '11', '16', '21'],
      i: const ['2', '7', '12', '17', '22'],
      n: const ['3', '8', 'FREE', '18', '23'],
      g: const ['4', '9', '14', '19', '24'],
      o: const ['5', '10', '15', '20', '25'],
    ),
  );
}

GameModel _playingGame() {
  final now = DateTime.utc(2026, 6, 12);
  return GameModel(
    id: 'game-1',
    sessionId: 'session-1',
    staticCode: 'ABC',
    playCode: '111',
    name: 'Live game',
    gameRule: null,
    gameType: 'ONE_ROW',
    entryFee: '10.00',
    prizePerCartela: '20.00',
    companyFeePerCartela: '1.00',
    prizeAmount: '200.00',
    companyRevenue: '20.00',
    status: GameStatus.playing,
    playOrder: 1,
    startedAt: now,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 1,
    calledNumbersCount: 3,
    registrationOpen: false,
    canRegister: false,
    nextAutoCallAt: now.add(const Duration(seconds: 5)),
    operationMode: 'AUTO',
  );
}

GameModel _winnerWindowGame() {
  final now = DateTime.utc(2026, 6, 12);
  return _playingGame().copyWith(
    status: GameStatus.winnerWindow,
    winnerWindowEndsAt: now.add(const Duration(seconds: 20)),
    nextAutoCallAt: null,
  );
}

void main() {
  group('shouldPauseCalledNumbersStripForClaim', () {
    test('holds strip immediately when claim strip hold is active', () {
      expect(
        shouldPauseCalledNumbersStripForClaim(
          claimStripHoldActive: true,
          hasClaimingCartelaIds: false,
          hasSessionCheckingCartelaNumbers: false,
        ),
        isTrue,
      );
    });

    test('does not hold strip when no claim activity', () {
      expect(
        shouldPauseCalledNumbersStripForClaim(
          claimStripHoldActive: false,
          hasClaimingCartelaIds: false,
          hasSessionCheckingCartelaNumbers: false,
        ),
        isFalse,
      );
    });
  });

  group('isCartelaEligibleForBingoClaim', () {
    test('eligible during live play with open countdown', () {
      expect(
        isCartelaEligibleForBingoClaim(
          game: _playingGame(),
          gameCartela: _registeredCartela(id: 'gc-1'),
          winnerWindowExpired: false,
          hasPendingClaim: false,
          isCountdownLocked: false,
        ),
        isTrue,
      );
    });

    test('not eligible when countdown is locked at 1 second', () {
      expect(
        isCartelaEligibleForBingoClaim(
          game: _playingGame(),
          gameCartela: _registeredCartela(id: 'gc-1'),
          winnerWindowExpired: false,
          hasPendingClaim: false,
          isCountdownLocked: true,
        ),
        isFalse,
      );
    });

    test('eligible at 2 seconds when countdown is not locked', () {
      expect(
        isCartelaEligibleForBingoClaim(
          game: _playingGame(),
          gameCartela: _registeredCartela(id: 'gc-1'),
          winnerWindowExpired: false,
          hasPendingClaim: false,
          isCountdownLocked: false,
        ),
        isTrue,
      );
    });

    test('eligible during active winner window', () {
      expect(
        isCartelaEligibleForBingoClaim(
          game: _winnerWindowGame(),
          gameCartela: _registeredCartela(id: 'gc-1'),
          winnerWindowExpired: false,
          hasPendingClaim: false,
          isCountdownLocked: false,
        ),
        isTrue,
      );
    });

    test('not eligible after winner window expires', () {
      expect(
        isCartelaEligibleForBingoClaim(
          game: _winnerWindowGame(),
          gameCartela: _registeredCartela(id: 'gc-1'),
          winnerWindowExpired: true,
          hasPendingClaim: false,
          isCountdownLocked: false,
        ),
        isFalse,
      );
    });
  });
}
