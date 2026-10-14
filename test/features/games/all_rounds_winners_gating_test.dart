import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/round_winner_history_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/session_winner_result_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/round_winner_history_adapters.dart';

final _now = DateTime.parse('2026-10-14T09:00:00.000Z');

GameModel _game({
  required GameCategory category,
  required GameStatus status,
  int roundIndex = 1,
  int roundCount = 3,
  String? sessionId = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
  List<ChainRoundResultSummary> roundResults = const [],
  DateTime? roundPausedUntil,
}) {
  return GameModel(
    id: 'slot-1',
    sessionId: sessionId,
    staticCode: 'T-1',
    playCode: 'PLAY-T',
    name: 'Test',
    gameRule: null,
    gameType: 'ONE_LINE',
    entryFee: '10',
    prizePerCartela: '0',
    companyFeePerCartela: '10',
    prizeAmount: '100',
    companyRevenue: '0',
    status: status,
    playOrder: 1,
    startedAt: _now,
    finishedAt: status == GameStatus.finished || status == GameStatus.noWinner
        ? _now
        : null,
    createdAt: _now,
    updatedAt: _now,
    registeredCartelasCount: 4,
    calledNumbersCount: 12,
    registrationOpen: false,
    canRegister: false,
    category: category,
    roundCount: roundCount,
    roundIndex: roundIndex,
    roundPausedUntil: roundPausedUntil,
    roundResults: roundResults,
  );
}

ChainRoundResultSummary _round(int roundIndex) {
  return ChainRoundResultSummary(
    roundIndex: roundIndex,
    prizeAmount: '100',
    outcome: ChainRoundOutcome.won,
    winners: const [
      ChainRoundWinnerSummary(
        gameCartelaId: 'gc-1',
        cartelaNumber: 12,
        amount: '100',
      ),
    ],
  );
}

void main() {
  group('shouldShowAllRoundsWinnersHistory', () {
    test('hides for Normal / Bonus / GOTD', () {
      for (final category in [
        GameCategory.normal,
        GameCategory.bonus,
        GameCategory.bigGotd,
      ]) {
        expect(
          shouldShowAllRoundsWinnersHistory(
            game: _game(
              category: category,
              status: GameStatus.finished,
              roundCount: 1,
            ),
            postGameSummaryVisible: true,
          ),
          isFalse,
        );
      }
    });

    test('hides for Big Game intermediate finished round', () {
      expect(
        shouldShowAllRoundsWinnersHistory(
          game: _game(
            category: GameCategory.bigGame,
            status: GameStatus.finished,
            roundIndex: 2,
            roundCount: 3,
          ),
          postGameSummaryVisible: true,
        ),
        isFalse,
      );
    });

    test('shows for Big Game final finished round', () {
      expect(
        shouldShowAllRoundsWinnersHistory(
          game: _game(
            category: GameCategory.bigGame,
            status: GameStatus.finished,
            roundIndex: 3,
            roundCount: 3,
          ),
          postGameSummaryVisible: true,
        ),
        isTrue,
      );
    });

    test('hides for Chain inter-round (summary not final)', () {
      expect(
        shouldShowAllRoundsWinnersHistory(
          game: _game(
            category: GameCategory.chainGame,
            status: GameStatus.playing,
            roundIndex: 2,
            roundCount: 3,
            roundPausedUntil: DateTime.now().add(const Duration(seconds: 20)),
            roundResults: [_round(1)],
          ),
          postGameSummaryVisible: false,
        ),
        isFalse,
      );
    });

    test('shows for Chain final finished PIN summary', () {
      expect(
        shouldShowAllRoundsWinnersHistory(
          game: _game(
            category: GameCategory.chainGame,
            status: GameStatus.finished,
            roundIndex: 3,
            roundCount: 3,
            roundResults: [_round(1), _round(2), _round(3)],
          ),
          postGameSummaryVisible: true,
        ),
        isTrue,
      );
    });

    test('hides when post-game summary is not visible', () {
      expect(
        shouldShowAllRoundsWinnersHistory(
          game: _game(
            category: GameCategory.bigGame,
            status: GameStatus.finished,
            roundIndex: 3,
            roundCount: 3,
          ),
          postGameSummaryVisible: false,
        ),
        isFalse,
      );
    });
  });

  group('adaptRoundWinnerHistoryToCards', () {
    test('expands multiple winners and marks no-winner rounds', () {
      const history = RoundWinnerHistory(
        sessionId: 's1',
        roundCount: 2,
        rounds: [
          RoundWinnerHistoryRound(
            roundIndex: 1,
            sessionId: 's1',
            status: RoundWinnerHistoryStatus.finished,
            prizeAmount: '50',
            winnerResults: [
              SessionWinnerResultModel(
                gameCartelaId: 'a',
                cartelaId: 'c1',
                cartelaNumber: 7,
                amount: '25',
                columns: [[], [], [], [], []],
                completedPatterns: [],
              ),
              SessionWinnerResultModel(
                gameCartelaId: 'b',
                cartelaId: 'c2',
                cartelaNumber: 9,
                amount: '25',
                columns: [[], [], [], [], []],
                completedPatterns: [],
              ),
            ],
          ),
          RoundWinnerHistoryRound(
            roundIndex: 2,
            sessionId: 's1',
            status: RoundWinnerHistoryStatus.noWinner,
            prizeAmount: '50',
          ),
        ],
      );

      final cards = adaptRoundWinnerHistoryToCards(history);
      expect(cards, hasLength(3));
      expect(cards[0].cartelaNumber, 7);
      expect(cards[1].cartelaNumber, 9);
      expect(cards[2].isNoWinner, isTrue);
    });
  });
}
