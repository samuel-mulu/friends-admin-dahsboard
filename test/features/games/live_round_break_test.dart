import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_round_break.dart';

final _now = DateTime.parse('2026-09-14T10:00:00.000Z');

GameModel _chain({
  required GameStatus status,
  required int roundIndex,
  required int roundCount,
  DateTime? roundPausedUntil,
}) {
  return GameModel(
    id: 'slot-chain',
    sessionId: 'session-chain',
    staticCode: 'CH-1',
    playCode: 'PLAY-CH',
    name: 'Chain Game',
    gameRule: null,
    gameType: 'ONE_LINE',
    entryFee: '25',
    prizePerCartela: '0',
    companyFeePerCartela: '25',
    prizeAmount: '5000',
    companyRevenue: '0',
    status: status,
    playOrder: 1,
    startedAt: _now,
    finishedAt: null,
    createdAt: _now,
    updatedAt: _now,
    registeredCartelasCount: 4,
    calledNumbersCount: 12,
    registrationOpen: false,
    canRegister: false,
    category: GameCategory.chainGame,
    roundCount: roundCount,
    roundIndex: roundIndex,
    roundPausedUntil: roundPausedUntil,
  );
}

void main() {
  group('chainInterRoundBreakEligible', () {
    test('true after round 1 of 3 (index advanced to 2)', () {
      final game = _chain(
        status: GameStatus.playing,
        roundIndex: 2,
        roundCount: 3,
        roundPausedUntil: _now.add(const Duration(seconds: 18)),
      );
      expect(
        chainInterRoundBreakEligible(game, now: _now),
        isTrue,
      );
    });

    test('false when final chain round is already in roundResults', () {
      final game = _chain(
        status: GameStatus.playing,
        roundIndex: 3,
        roundCount: 3,
        roundPausedUntil: _now.add(const Duration(seconds: 18)),
      ).copyWith(
        roundResults: const [
          ChainRoundResultSummary(
            roundIndex: 3,
            prizeAmount: '1000',
            outcome: ChainRoundOutcome.won,
            winners: [
              ChainRoundWinnerSummary(
                gameCartelaId: 'gc-1',
                cartelaNumber: 7,
                amount: '1000',
              ),
            ],
          ),
        ],
      );
      expect(
        chainInterRoundBreakEligible(game, now: _now),
        isFalse,
      );
    });

    test('latch keeps break during refetch gap', () {
      final game = _chain(
        status: GameStatus.playing,
        roundIndex: 2,
        roundCount: 3,
        roundPausedUntil: null,
      );
      expect(
        chainInterRoundBreakEligible(
          game,
          now: _now,
          latchedPausedUntil: _now.add(const Duration(seconds: 10)),
          canonicalRefetchInFlight: true,
        ),
        isTrue,
      );
    });
  });

  group('resolveLiveRoundBreakOwner', () {
    test('terminal wins over stale chain summary flag', () {
      final game = _chain(
        status: GameStatus.finished,
        roundIndex: 3,
        roundCount: 3,
        roundPausedUntil: null,
      );
      expect(
        resolveLiveRoundBreakOwner(
          game: game,
          postGameSummaryReviewActive: true,
          chainInterRoundSummaryActive: true,
          chainInterRoundSummaryDismissed: false,
          now: _now,
        ),
        LiveRoundBreakOwner.postGameTerminal,
      );
    });
  });

  group('shouldSuppressBigGameAutoWinnerModalBetweenRounds', () {
    test('suppresses mid-slot embedded rounds', () {
      final game = GameModel(
        id: 'bg-1',
        sessionId: 's1',
        staticCode: 'BG',
        playCode: 'P',
        name: 'Big',
        gameRule: null,
        gameType: 'FULL_HOUSE',
        entryFee: '10',
        prizePerCartela: '8',
        companyFeePerCartela: '2',
        prizeAmount: '100',
        companyRevenue: '0',
        status: GameStatus.finished,
        playOrder: 1,
        startedAt: _now,
        finishedAt: _now,
        createdAt: _now,
        updatedAt: _now,
        registeredCartelasCount: 1,
        calledNumbersCount: 10,
        registrationOpen: false,
        canRegister: false,
        category: GameCategory.bigGame,
        roundCount: 3,
        roundIndex: 1,
      );
      expect(
        shouldSuppressBigGameAutoWinnerModalBetweenRounds(
          game: game,
          embeddedBigGame: true,
          postGameSummaryReviewActive: true,
        ),
        isTrue,
      );
    });
  });
}
