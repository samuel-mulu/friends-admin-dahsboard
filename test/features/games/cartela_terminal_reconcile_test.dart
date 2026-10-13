import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/bingo_claim_attempt_storage.dart';
import 'package:friends_bingo_app/src/features/games/data/models/bingo_claim_result.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_called_numbers_controller.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_game_host.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/bingo_claim_eligibility.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/chain_round_cartela_state.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/merge_registered_cartelas.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHost implements LiveGameHost {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

GameCartelaModel _cartela({
  required String id,
  required int number,
  GameCartelaStatus status = GameCartelaStatus.registered,
  bool isWinner = false,
  String gameId = 'session-1',
}) {
  final now = DateTime.utc(2026, 10, 13, 5, 53);
  return GameCartelaModel(
    id: id,
    gameId: gameId,
    userId: 'user-1',
    cartelaId: 'cartela-$id',
    status: status,
    isWinner: isWinner,
    blockedAt: status == GameCartelaStatus.blocked ? now : null,
    createdAt: now,
    updatedAt: now,
    cartela: CartelaModel(
      id: 'cartela-$id',
      number: number,
      createdAt: now,
    ),
  );
}

GameModel _game({
  required GameStatus status,
  required GameCategory category,
  int roundIndex = 1,
  int roundCount = 3,
  DateTime? roundPausedUntil,
  List<ChainRoundResultSummary> roundResults = const [],
}) {
  final now = DateTime.utc(2026, 10, 13, 5, 53);
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
    status: status,
    playOrder: 1,
    startedAt: now,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 2,
    calledNumbersCount: 10,
    registrationOpen: false,
    canRegister: false,
    category: category,
    roundIndex: roundIndex,
    roundCount: roundCount,
    roundPausedUntil: roundPausedUntil,
    roundResults: roundResults,
  );
}

ChainRoundResultSummary _decidedRound(int roundIndex) {
  return ChainRoundResultSummary(
    roundIndex: roundIndex,
    prizeAmount: '100',
    outcome: ChainRoundOutcome.won,
    winners: const [
      ChainRoundWinnerSummary(
        gameCartelaId: 'w1',
        cartelaNumber: 2,
        amount: '100',
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('preferAuthoritativeCartela / reconcile', () {
    test('stale REGISTERED cannot overwrite local BLOCKED', () {
      final current = _cartela(
        id: 'gc-1',
        number: 1,
        status: GameCartelaStatus.blocked,
      );
      final incoming = _cartela(
        id: 'gc-1',
        number: 1,
        status: GameCartelaStatus.registered,
      );
      expect(
        preferAuthoritativeCartela(current: current, incoming: incoming).status,
        GameCartelaStatus.blocked,
      );
    });

    test('stale REGISTERED cannot overwrite local WINNER', () {
      final current = _cartela(
        id: 'gc-1',
        number: 1,
        status: GameCartelaStatus.winner,
        isWinner: true,
      );
      final incoming = _cartela(
        id: 'gc-1',
        number: 1,
        status: GameCartelaStatus.registered,
      );
      expect(
        preferAuthoritativeCartela(current: current, incoming: incoming).status,
        GameCartelaStatus.winner,
      );
    });

    test('incoming BLOCKED overwrites local REGISTERED', () {
      final current = _cartela(id: 'gc-1', number: 1);
      final incoming = _cartela(
        id: 'gc-1',
        number: 1,
        status: GameCartelaStatus.blocked,
      );
      expect(
        preferAuthoritativeCartela(current: current, incoming: incoming).status,
        GameCartelaStatus.blocked,
      );
    });

    test('mergeRegisteredCartelas preserves BLOCKED against REGISTERED', () {
      final merged = mergeRegisteredCartelas(
        current: [
          _cartela(id: 'a', number: 1, status: GameCartelaStatus.blocked),
          _cartela(id: 'b', number: 2),
        ],
        incoming: [
          _cartela(id: 'a', number: 1),
          _cartela(id: 'b', number: 2),
          _cartela(id: 'c', number: 3),
        ],
        sessionId: 'session-1',
      );
      final byId = {for (final c in merged) c.id: c};
      expect(byId['a']!.status, GameCartelaStatus.blocked);
      expect(byId['b']!.status, GameCartelaStatus.registered);
      expect(byId['c']!.status, GameCartelaStatus.registered);
    });

    test('reconcileCartelaSnapshot keeps BLOCKED after delayed refresh', () {
      final current = [
        _cartela(id: 'blocked', number: 7, status: GameCartelaStatus.blocked),
        _cartela(id: 'other', number: 8),
      ];
      final incoming = [
        _cartela(id: 'blocked', number: 7),
        _cartela(id: 'other', number: 8),
      ];
      final next = reconcileCartelaSnapshot(
        current: current,
        incoming: incoming,
      );
      expect(
        next.firstWhere((c) => c.id == 'blocked').status,
        GameCartelaStatus.blocked,
      );
      expect(
        next.firstWhere((c) => c.id == 'other').status,
        GameCartelaStatus.registered,
      );
    });

    test('two cartelas: one BLOCKED is not affected by peer REGISTERED merge', () {
      final merged = mergeRegisteredCartelas(
        current: [
          _cartela(id: 'blocked', number: 1, status: GameCartelaStatus.blocked),
          _cartela(id: 'open', number: 2),
        ],
        incoming: [
          _cartela(id: 'blocked', number: 1),
          _cartela(id: 'open', number: 2, status: GameCartelaStatus.winner),
        ],
        sessionId: 'session-1',
      );
      final byId = {for (final c in merged) c.id: c};
      expect(byId['blocked']!.status, GameCartelaStatus.blocked);
      expect(byId['open']!.status, GameCartelaStatus.winner);
    });
  });

  group('chain round transitions', () {
    test('same-round stale PLAYING cannot demote WINNER', () {
      final staleSameRound = _game(
        status: GameStatus.playing,
        category: GameCategory.chainGame,
        roundIndex: 1,
      );
      expect(hasAuthoritativeChainRoundAdvance(staleSameRound), isFalse);
      final next = normalizeChainPlayableCartelas(
        game: staleSameRound,
        cartelas: [
          _cartela(
            id: 'w1',
            number: 2,
            status: GameCartelaStatus.winner,
            isWinner: true,
          ),
        ],
      );
      expect(next.single.status, GameCartelaStatus.winner);
      expect(next.single.isWinner, isTrue);
    });

    test('WINNER Round 1 → REGISTERED Round 2 with roundResults evidence', () {
      final game = _game(
        status: GameStatus.playing,
        category: GameCategory.chainGame,
        roundIndex: 2,
        roundResults: [_decidedRound(1)],
      );
      expect(hasAuthoritativeChainRoundAdvance(game), isTrue);
      final next = normalizeChainPlayableCartelas(
        game: game,
        cartelas: [
          _cartela(
            id: 'w1',
            number: 2,
            status: GameCartelaStatus.winner,
            isWinner: true,
          ),
        ],
      );
      expect(next.single.status, GameCartelaStatus.registered);
      expect(next.single.isWinner, isFalse);
    });

    test('WINNER Round 2 → REGISTERED Round 3 with pause evidence', () {
      final now = DateTime.utc(2026, 10, 13, 5, 53);
      final game = _game(
        status: GameStatus.playing,
        category: GameCategory.chainGame,
        roundIndex: 3,
        roundPausedUntil: now.add(const Duration(seconds: 20)),
        roundResults: [_decidedRound(1), _decidedRound(2)],
      );
      final next = normalizeChainPlayableCartelas(
        game: game,
        cartelas: [
          _cartela(
            id: 'w1',
            number: 2,
            status: GameCartelaStatus.winner,
            isWinner: true,
          ),
        ],
      );
      expect(next.single.status, GameCartelaStatus.registered);
    });

    test('BLOCKED persists across rounds', () {
      final game = _game(
        status: GameStatus.playing,
        category: GameCategory.chainGame,
        roundIndex: 3,
        roundResults: [_decidedRound(1), _decidedRound(2)],
      );
      final next = normalizeChainPlayableCartelas(
        game: game,
        cartelas: [
          _cartela(id: 'b1', number: 1, status: GameCartelaStatus.blocked),
          _cartela(
            id: 'w1',
            number: 2,
            status: GameCartelaStatus.winner,
            isWinner: true,
          ),
        ],
      );
      expect(next[0].status, GameCartelaStatus.blocked);
      expect(next[1].status, GameCartelaStatus.registered);
    });

    test('displayRoundIndex > 1 alone is not newer-round proof', () {
      final game = _game(
        status: GameStatus.playing,
        category: GameCategory.chainGame,
        roundIndex: 2,
      );
      expect(hasAuthoritativeChainRoundAdvance(game), isFalse);
      final next = normalizeChainPlayableCartelas(
        game: game,
        cartelas: [
          _cartela(
            id: 'w1',
            number: 2,
            status: GameCartelaStatus.winner,
            isWinner: true,
          ),
        ],
      );
      expect(next.single.status, GameCartelaStatus.winner);
    });
  });

  group('historical INVALID eligibility', () {
    test(
      'historical INVALID paints BLOCKED on same-session cartela before unlock',
      () async {
        final controller = LiveCalledNumbersController(
          _FakeHost(),
          claimStorage: BingoClaimAttemptStorage(),
        );
        await controller.bindClaimRecoveryScope('user-1', 'session-1');
        final cartela = _cartela(id: 'gc-1', number: 1);
        final attempt = controller.beginClaimAttempt(
          gameCartelaId: cartela.id,
          claimAttemptId: 'attempt-old',
          roundIndex: 1,
        )!;
        final newerPlayable = _game(
          status: GameStatus.playing,
          category: GameCategory.chainGame,
          roundIndex: 2,
          roundResults: [_decidedRound(1)],
        );
        late List<GameCartelaModel> applied;
        final resolution = controller.resolveHistoricalTerminalClaim(
          attempt: attempt,
          status: BingoClaimStatus.invalid,
          retryAllowed: false,
          cartelas: [cartela],
          game: newerPlayable,
          applyCartelas: (next) => applied = next,
        );
        expect(resolution.applied, isTrue);
        expect(applied.single.status, GameCartelaStatus.blocked);
        expect(controller.activeClaimAttemptIdByCartelaId, isEmpty);
        expect(controller.claimEligibilityLockedCartelaIds, isEmpty);
        expect(
          controller.canClaimBingoForCartela(
            game: newerPlayable,
            gameCartela: applied.single,
            winnerWindowExpired: false,
            isCountdownLocked: false,
          ),
          isFalse,
        );
      },
    );

    test(
      'historical INVALID without local cartela keeps lock after failed refetch',
      () async {
        final controller = LiveCalledNumbersController(
          _FakeHost(),
          claimStorage: BingoClaimAttemptStorage(),
        );
        await controller.bindClaimRecoveryScope('user-1', 'session-1');
        final attempt = controller.beginClaimAttempt(
          gameCartelaId: 'gc-missing',
          claimAttemptId: 'attempt-old',
          roundIndex: 1,
        )!;
        final newerPlayable = _game(
          status: GameStatus.playing,
          category: GameCategory.chainGame,
          roundIndex: 2,
          roundResults: [_decidedRound(1)],
        );
        // Simulate delayed/failed refetch: only an unrelated REGISTERED card.
        final visible = _cartela(id: 'other', number: 9);
        controller.resolveHistoricalTerminalClaim(
          attempt: attempt,
          status: BingoClaimStatus.invalid,
          retryAllowed: false,
          cartelas: [visible],
          game: newerPlayable,
          applyCartelas: (_) {},
        );
        expect(
          controller.claimEligibilityLockedCartelaIds,
          contains('gc-missing'),
        );
        // Failed refetch leaves peer REGISTERED playable; locked cartela stays off.
        final stillRegistered = _cartela(id: 'gc-missing', number: 3);
        expect(
          controller.canClaimBingoForCartela(
            game: newerPlayable,
            gameCartela: stillRegistered,
            winnerWindowExpired: false,
            isCountdownLocked: false,
          ),
          isFalse,
        );
        expect(
          controller.canClaimBingoForCartela(
            game: newerPlayable,
            gameCartela: visible,
            winnerWindowExpired: false,
            isCountdownLocked: false,
          ),
          isTrue,
        );
      },
    );

    test(
      'historical VALID clears attempt without painting WINNER on newer round',
      () async {
        final controller = LiveCalledNumbersController(
          _FakeHost(),
          claimStorage: BingoClaimAttemptStorage(),
        );
        await controller.bindClaimRecoveryScope('user-1', 'session-1');
        final cartela = _cartela(id: 'gc-1', number: 1);
        final attempt = controller.beginClaimAttempt(
          gameCartelaId: cartela.id,
          claimAttemptId: 'attempt-old',
          roundIndex: 1,
        )!;
        final newer = _game(
          status: GameStatus.playing,
          category: GameCategory.chainGame,
          roundIndex: 2,
          roundPausedUntil: DateTime.now().toUtc().add(
            const Duration(seconds: 45),
          ),
          roundResults: [_decidedRound(1)],
        );
        var applied = [cartela];
        controller.resolveHistoricalTerminalClaim(
          attempt: attempt,
          status: BingoClaimStatus.valid,
          retryAllowed: false,
          cartelas: [cartela],
          game: newer,
          applyCartelas: (next) => applied = next,
        );
        expect(applied.single.status, GameCartelaStatus.registered);
        expect(controller.activeClaimAttemptIdByCartelaId, isEmpty);
        expect(
          controller.canClaimBingoForCartela(
            game: newer,
            gameCartela: applied.single,
            winnerWindowExpired: false,
            isCountdownLocked: false,
          ),
          isFalse,
        );
      },
    );

    test('overlapping claims stay independent across cartelas', () async {
      final controller = LiveCalledNumbersController(
        _FakeHost(),
        claimStorage: BingoClaimAttemptStorage(),
      );
      await controller.bindClaimRecoveryScope('user-1', 'session-1');
      final a = _cartela(id: 'a', number: 1);
      final b = _cartela(id: 'b', number: 2);
      final attemptA = controller.beginClaimAttempt(
        gameCartelaId: a.id,
        claimAttemptId: 'ua',
        roundIndex: 1,
      )!;
      final attemptB = controller.beginClaimAttempt(
        gameCartelaId: b.id,
        claimAttemptId: 'ub',
        roundIndex: 1,
      )!;
      final newer = _game(
        status: GameStatus.playing,
        category: GameCategory.chainGame,
        roundIndex: 2,
        roundResults: [_decidedRound(1)],
      );
      late List<GameCartelaModel> afterA;
      controller.resolveHistoricalTerminalClaim(
        attempt: attemptA,
        status: BingoClaimStatus.invalid,
        retryAllowed: false,
        cartelas: [a, b],
        game: newer,
        applyCartelas: (next) => afterA = next,
      );
      expect(afterA.firstWhere((c) => c.id == 'a').status,
          GameCartelaStatus.blocked);
      expect(afterA.firstWhere((c) => c.id == 'b').status,
          GameCartelaStatus.registered);
      expect(controller.claimAttemptFor('b'), same(attemptB));
      expect(controller.claimEligibilityLockedCartelaIds, isEmpty);
    });
  });

  group('resolveTerminalClaim atomic pending + cartela', () {
    test('INVALID patches BLOCKED before pending is cleared', () async {
      final controller = LiveCalledNumbersController(
        _FakeHost(),
        claimStorage: BingoClaimAttemptStorage(),
      );
      await controller.bindClaimRecoveryScope('user-1', 'session-1');
      expect(controller.claimScopeLoading, isFalse);

      final cartela = _cartela(id: 'gc-1', number: 1);
      final attempt = controller.beginClaimAttempt(
        gameCartelaId: cartela.id,
        claimAttemptId: 'attempt-1',
        roundIndex: 1,
      );
      expect(attempt, isNotNull);
      expect(controller.pendingClaimCartelaIds.contains(cartela.id), isFalse);
      expect(controller.claimingCartelaIds.contains(cartela.id), isTrue);

      var observedEligibleWhileResolving = true;
      late List<GameCartelaModel> applied;
      final resolution = controller.resolveTerminalClaim(
        attempt: attempt!,
        status: BingoClaimStatus.invalid,
        retryAllowed: false,
        cartelas: [cartela],
        reportedCartelaStatus: GameCartelaStatus.blocked,
        applyCartelas: (next) {
          applied = next;
          // Pending is still held until applyAuthoritativeClaimStatus runs
          // after this callback — eligibility must already see BLOCKED.
          observedEligibleWhileResolving = isCartelaEligibleForBingoClaim(
            game: _game(
              status: GameStatus.playing,
              category: GameCategory.normal,
            ),
            gameCartela: next.single,
            winnerWindowExpired: false,
            hasPendingClaim: controller.pendingClaimCartelaIds.contains(
              cartela.id,
            ),
            isCountdownLocked: false,
            calledNumbersCount: 5,
          );
        },
      );

      expect(resolution.applied, isTrue);
      expect(applied.single.status, GameCartelaStatus.blocked);
      expect(observedEligibleWhileResolving, isFalse);
      expect(controller.pendingClaimCartelaIds.contains(cartela.id), isFalse);
      expect(controller.claimingCartelaIds.contains(cartela.id), isFalse);
      expect(
        controller.canClaimBingoForCartela(
          game: _game(
            status: GameStatus.playing,
            category: GameCategory.normal,
          ),
          gameCartela: applied.single,
          winnerWindowExpired: false,
          isCountdownLocked: false,
        ),
        isFalse,
      );
    });

    test('VALID patches WINNER; FAILED does not reopen BLOCKED', () async {
      final controller = LiveCalledNumbersController(
        _FakeHost(),
        claimStorage: BingoClaimAttemptStorage(),
      );
      await controller.bindClaimRecoveryScope('user-1', 'session-1');

      final winnerCard = _cartela(id: 'win', number: 1);
      final attempt = controller.beginClaimAttempt(
        gameCartelaId: winnerCard.id,
        claimAttemptId: 'attempt-win',
        roundIndex: 1,
      )!;
      late List<GameCartelaModel> afterValid;
      controller.resolveTerminalClaim(
        attempt: attempt,
        status: BingoClaimStatus.valid,
        retryAllowed: false,
        cartelas: [winnerCard],
        applyCartelas: (next) => afterValid = next,
      );
      expect(afterValid.single.status, GameCartelaStatus.winner);

      final blocked = _cartela(
        id: 'blocked',
        number: 2,
        status: GameCartelaStatus.blocked,
      );
      final failedAttempt = controller.beginClaimAttempt(
        gameCartelaId: blocked.id,
        claimAttemptId: 'attempt-fail',
        roundIndex: 1,
      )!;
      late List<GameCartelaModel> afterFailed;
      controller.resolveTerminalClaim(
        attempt: failedAttempt,
        status: BingoClaimStatus.failed,
        retryAllowed: true,
        cartelas: [blocked],
        reportedCartelaStatus: GameCartelaStatus.registered,
        applyCartelas: (next) => afterFailed = next,
      );
      expect(afterFailed.single.status, GameCartelaStatus.blocked);
    });

    test('simultaneous cartela claims stay independent', () async {
      final controller = LiveCalledNumbersController(
        _FakeHost(),
        claimStorage: BingoClaimAttemptStorage(),
      );
      await controller.bindClaimRecoveryScope('user-1', 'session-1');
      final a = _cartela(id: 'a', number: 1);
      final b = _cartela(id: 'b', number: 2);
      final attemptA = controller.beginClaimAttempt(
        gameCartelaId: a.id,
        claimAttemptId: 'ua',
        roundIndex: 1,
      )!;
      final attemptB = controller.beginClaimAttempt(
        gameCartelaId: b.id,
        claimAttemptId: 'ub',
        roundIndex: 1,
      )!;
      expect(attemptA.claimAttemptId, 'ua');
      expect(attemptB.claimAttemptId, 'ub');

      late List<GameCartelaModel> afterA;
      controller.resolveTerminalClaim(
        attempt: attemptA,
        status: BingoClaimStatus.invalid,
        retryAllowed: false,
        cartelas: [a, b],
        applyCartelas: (next) => afterA = next,
      );
      expect(afterA.firstWhere((c) => c.id == 'a').status,
          GameCartelaStatus.blocked);
      expect(afterA.firstWhere((c) => c.id == 'b').status,
          GameCartelaStatus.registered);
      expect(controller.claimAttemptFor('b'), same(attemptB));
    });
  });
}
