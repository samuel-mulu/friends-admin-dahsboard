import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/application/controllers/live_chain_game_coordinator.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/bingo_claim_eligibility.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/chain_round_cartela_state.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/next_ball_countdown.dart';

final _now = DateTime.parse('2026-11-05T10:00:00.000Z');

GameModel _game({
  required GameCategory category,
  GameStatus status = GameStatus.playing,
  int roundIndex = 1,
  int calledNumbersCount = 0,
  List<ChainRoundResultSummary> roundResults = const [],
  DateTime? roundPausedUntil,
}) {
  return GameModel(
    id: 'slot-1',
    sessionId: 'session-1',
    staticCode: 'CH-1',
    playCode: 'PLAY-1',
    name: 'Game',
    gameRule: GameRuleModel(id: 'rule-1', key: 'ONE_LINE', name: 'One Line'),
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
    calledNumbersCount: calledNumbersCount,
    registrationOpen: false,
    canRegister: false,
    category: category,
    roundCount: 3,
    roundIndex: roundIndex,
    roundPausedUntil: roundPausedUntil,
  ).copyWith(roundResults: roundResults);
}

ChainRoundResultSummary _round(int index, {int? winningBall}) =>
    ChainRoundResultSummary(
      roundIndex: index,
      prizeAmount: '1000',
      outcome: ChainRoundOutcome.won,
      winningBallNumber: winningBall,
    );

/// Balls with orders 1..n; numbers are given in call order.
List<CalledNumberModel> _balls(List<int> numbers) => [
  for (var i = 0; i < numbers.length; i++)
    CalledNumberModel(
      id: 'ball-$i',
      sessionId: 'session-1',
      letter: 'B',
      number: numbers[i],
      order: i + 1,
      createdAt: _now,
    ),
];

final _cartela = GameCartelaModel(
  id: 'gc-1',
  gameId: 'session-1',
  userId: 'user-1',
  cartelaId: 'cartela-1',
  status: GameCartelaStatus.registered,
  isWinner: false,
  blockedAt: null,
  createdAt: _now,
  updatedAt: _now,
  cartela: CartelaModel(id: 'cartela-1', number: 7, createdAt: _now),
);

bool _eligible(
  GameModel game, {
  List<CalledNumberModel> balls = const [],
  int? armedAfter,
}) => isCartelaEligibleForBingoClaim(
  game: game,
  gameCartela: _cartela,
  winnerWindowExpired: false,
  hasPendingClaim: false,
  calledNumbersCount: balls.length,
  calledNumbers: balls,
  chainBingoArmedAfterCalledCount: armedAfter,
  now: _now,
);

void main() {
  group('per-ball lock removed', () {
    test('play phase stays counting in the last second (no pre-call lock)', () {
      expect(
        resolveNextBallPlayPhase(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          nextAutoCallAt: _now.add(const Duration(milliseconds: 500)),
          now: _now,
        ),
        NextBallPlayPhase.counting,
      );
    });

    test('play phase is calling once the auto-call is due', () {
      expect(
        resolveNextBallPlayPhase(
          gameStatus: GameStatus.playing,
          autoCallActive: true,
          nextAutoCallAt: _now,
          now: _now,
        ),
        NextBallPlayPhase.calling,
      );
    });

    test('normal game Bingo is available right after a ball is called', () {
      final balls = _balls([5, 20, 33]);
      expect(
        _eligible(
          _game(category: GameCategory.normal, calledNumbersCount: 3),
          balls: balls,
        ),
        isTrue,
      );
    });
  });

  group('Chain Game round lock (from session data)', () {
    test('round 1 is never round-locked', () {
      expect(
        _eligible(
          _game(category: GameCategory.chainGame, roundIndex: 1),
          balls: _balls([5, 20]),
        ),
        isTrue,
      );
    });

    test('round 2 is locked while the round-1 winning ball is the latest', () {
      final game = _game(
        category: GameCategory.chainGame,
        roundIndex: 2,
        roundResults: [_round(1, winningBall: 33)],
      );
      expect(_eligible(game, balls: _balls([5, 20, 33])), isFalse);
    });

    test('round 2 unlocks as soon as the next ball is called', () {
      final game = _game(
        category: GameCategory.chainGame,
        roundIndex: 2,
        roundResults: [_round(1, winningBall: 33)],
      );
      expect(_eligible(game, balls: _balls([5, 20, 33, 41])), isTrue);
    });

    test('session data wins over a stale in-memory threshold', () {
      final game = _game(
        category: GameCategory.chainGame,
        roundIndex: 2,
        roundResults: [_round(1, winningBall: 33)],
      );
      // Threshold says "wait for ball 5", but ball 4 is already after the win.
      expect(
        _eligible(game, balls: _balls([5, 20, 33, 41]), armedAfter: 4),
        isTrue,
      );
    });

    test('round 3 uses the round-2 winning ball, not round 1', () {
      final game = _game(
        category: GameCategory.chainGame,
        roundIndex: 3,
        roundResults: [
          _round(1, winningBall: 20),
          _round(2, winningBall: 41),
        ],
      );
      expect(_eligible(game, balls: _balls([5, 20, 33, 41])), isFalse);
      expect(_eligible(game, balls: _balls([5, 20, 33, 41, 60])), isTrue);
    });
  });

  group('Chain Game round lock (fallback threshold)', () {
    test('locked until the strip grows past the recorded count', () {
      // Socket round_finished result has no winning ball yet.
      final game = _game(
        category: GameCategory.chainGame,
        roundIndex: 2,
        roundResults: [_round(1)],
      );
      expect(_eligible(game, balls: _balls([5, 20, 33]), armedAfter: 3), isFalse);
      expect(
        _eligible(game, balls: _balls([5, 20, 33, 41]), armedAfter: 3),
        isTrue,
      );
    });

    test('pause keeps round 2 locked regardless of balls', () {
      final game = _game(
        category: GameCategory.chainGame,
        roundIndex: 2,
        roundResults: [_round(1, winningBall: 33)],
        roundPausedUntil: _now.add(const Duration(seconds: 10)),
      );
      expect(_eligible(game, balls: _balls([5, 20, 33, 41])), isFalse);
    });

    test('threshold recorded at round finish is not moved by a late resume', () {
      final chain = LiveChainGameCoordinator();
      addTearDown(chain.dispose);

      chain.armBingoForRound(roundIndex: 2, calledCount: 3); // round finished
      chain.armBingoForRound(roundIndex: 2, calledCount: 4); // late resume
      expect(chain.chainBingoArmedAfterCalledCount, 3);

      chain.armBingoForRound(roundIndex: 3, calledCount: 9); // next round
      expect(chain.chainBingoArmedAfterCalledCount, 9);
      expect(chain.chainBingoArmedForRoundIndex, 3);

      chain.reset();
      expect(chain.chainBingoArmedAfterCalledCount, isNull);
      expect(chain.chainBingoArmedForRoundIndex, isNull);
    });
  });

  test('derived helper returns null when it cannot decide', () {
    final game = _game(
      category: GameCategory.chainGame,
      roundIndex: 2,
      roundResults: [_round(1, winningBall: 70)],
    );
    // Winning ball not in the local strip yet.
    expect(
      chainRoundHasNewBallSincePreviousWin(
        game: game,
        calledNumbers: _balls([5, 20]),
      ),
      isNull,
    );
  });
}
