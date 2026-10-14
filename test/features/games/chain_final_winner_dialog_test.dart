import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/chain_round_cartela_state.dart';

final _now = DateTime.parse('2026-10-14T09:00:00.000Z');

ChainRoundResultSummary _round({
  required int roundIndex,
  List<ChainRoundWinnerSummary> winners = const [],
}) {
  return ChainRoundResultSummary(
    roundIndex: roundIndex,
    prizeAmount: '100',
    outcome: winners.isEmpty
        ? ChainRoundOutcome.forfeited
        : ChainRoundOutcome.won,
    winners: winners,
  );
}

ChainRoundWinnerSummary _winner({
  required String gameCartelaId,
  required int cartelaNumber,
}) {
  return ChainRoundWinnerSummary(
    gameCartelaId: gameCartelaId,
    cartelaNumber: cartelaNumber,
    amount: '100',
  );
}

GameModel _chain({
  required GameStatus status,
  required int roundIndex,
  required int roundCount,
  DateTime? roundPausedUntil,
  List<ChainRoundResultSummary> roundResults = const [],
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
    finishedAt: status == GameStatus.finished ? _now : null,
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
    roundResults: roundResults,
  );
}

GameModel _normalFinished() {
  return GameModel(
    id: 'slot-n',
    sessionId: 'session-n',
    staticCode: 'N-1',
    playCode: 'PLAY-N',
    name: 'Normal',
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
    registeredCartelasCount: 2,
    calledNumbersCount: 20,
    registrationOpen: false,
    canRegister: false,
    category: GameCategory.normal,
  );
}

void main() {
  group('shouldShowChainFinalWinnerCartelaDialog', () {
    test('true for Chain FINISHED final with last-round result', () {
      final game = _chain(
        status: GameStatus.finished,
        roundIndex: 3,
        roundCount: 3,
        roundResults: [
          _round(
            roundIndex: 1,
            winners: [_winner(gameCartelaId: 'gc1', cartelaNumber: 1)],
          ),
          _round(
            roundIndex: 3,
            winners: [_winner(gameCartelaId: 'gc3', cartelaNumber: 7)],
          ),
        ],
      );
      expect(
        shouldShowChainFinalWinnerCartelaDialog(
          game: game,
          postGameSummaryVisible: true,
        ),
        isTrue,
      );
    });

    test('true for Chain NO_WINNER final without remaining rounds', () {
      final game = _chain(
        status: GameStatus.noWinner,
        roundIndex: 2,
        roundCount: 2,
      );
      expect(
        shouldShowChainFinalWinnerCartelaDialog(
          game: game,
          postGameSummaryVisible: true,
        ),
        isTrue,
      );
    });

    test('false while post-game summary not visible', () {
      final game = _chain(
        status: GameStatus.finished,
        roundIndex: 2,
        roundCount: 2,
      );
      expect(
        shouldShowChainFinalWinnerCartelaDialog(
          game: game,
          postGameSummaryVisible: false,
        ),
        isFalse,
      );
    });

    test('false during inter-round PLAYING + pause', () {
      final game = _chain(
        status: GameStatus.playing,
        roundIndex: 2,
        roundCount: 3,
        roundPausedUntil: _now.add(const Duration(seconds: 20)),
      );
      expect(
        shouldShowChainFinalWinnerCartelaDialog(
          game: game,
          postGameSummaryVisible: true,
        ),
        isFalse,
      );
    });

    test('false when remaining chain rounds exist', () {
      final game = _chain(
        status: GameStatus.finished,
        roundIndex: 1,
        roundCount: 3,
      );
      expect(game.hasRemainingChainRounds, isTrue);
      expect(
        shouldShowChainFinalWinnerCartelaDialog(
          game: game,
          postGameSummaryVisible: true,
        ),
        isFalse,
      );
    });

    test('false when roundResults omit the last round row', () {
      final game = _chain(
        status: GameStatus.finished,
        roundIndex: 3,
        roundCount: 3,
        roundResults: [
          _round(
            roundIndex: 1,
            winners: [_winner(gameCartelaId: 'gc1', cartelaNumber: 1)],
          ),
          _round(
            roundIndex: 2,
            winners: [_winner(gameCartelaId: 'gc2', cartelaNumber: 2)],
          ),
        ],
      );
      expect(
        shouldShowChainFinalWinnerCartelaDialog(
          game: game,
          postGameSummaryVisible: true,
        ),
        isFalse,
      );
    });

    test('false for non-Chain finished game', () {
      expect(
        shouldShowChainFinalWinnerCartelaDialog(
          game: _normalFinished(),
          postGameSummaryVisible: true,
        ),
        isFalse,
      );
    });
  });
}
