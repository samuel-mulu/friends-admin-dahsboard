import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/bingo_claim_result.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/bingo_claim_source.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/auto_bingo_runtime.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_mark_helpers.dart';

final _now = DateTime.utc(2026, 10, 15);

CalledNumberModel _call({
  required String letter,
  required int number,
  required int order,
  String sessionId = 'session-a',
}) {
  return CalledNumberModel(
    id: 'call-$order',
    sessionId: sessionId,
    letter: letter,
    number: number,
    order: order,
    createdAt: _now.add(Duration(seconds: order)),
  );
}

String _cellValue(int row, int col) {
  if (row == 2 && col == 2) {
    return 'FREE';
  }
  return '${col * 15 + row + 1}';
}

GameCartelaModel _cartela({
  required String id,
  required int number,
  GameCartelaStatus status = GameCartelaStatus.registered,
}) {
  List<String> column(int col) => [
    for (var row = 0; row < 5; row++) _cellValue(row, col),
  ];

  return GameCartelaModel(
    id: id,
    gameId: 'game-1',
    userId: 'user-1',
    cartelaId: 'cartela-$id',
    status: status,
    isWinner: status == GameCartelaStatus.winner,
    blockedAt: null,
    createdAt: _now,
    updatedAt: _now,
    cartela: CartelaModel(
      id: 'cartela-$id',
      number: number,
      createdAt: _now,
      b: column(0),
      i: column(1),
      n: column(2),
      g: column(3),
      o: column(4),
    ),
  );
}

/// Calls that complete top row for the deterministic cartela grid above.
List<CalledNumberModel> _topRowCompleteCalls() {
  // Row 0 cells: B:1, I:16, N:31, G:46, O:61
  return [
    _call(letter: 'B', number: 1, order: 1),
    _call(letter: 'I', number: 16, order: 2),
    _call(letter: 'N', number: 31, order: 3),
    _call(letter: 'G', number: 46, order: 4),
    _call(letter: 'O', number: 61, order: 5),
  ];
}

GameModel _game({
  GameStatus status = GameStatus.playing,
  String ruleKey = 'ONE_LINE',
}) {
  return GameModel(
    id: 'slot-1',
    sessionId: 'session-a',
    staticCode: 'N-1',
    playCode: 'PLAY-1',
    name: 'Test',
    gameRule: GameRuleModel(id: 'rule-1', key: ruleKey, name: ruleKey),
    gameType: ruleKey,
    entryFee: '10',
    prizePerCartela: '0',
    companyFeePerCartela: '10',
    prizeAmount: '100',
    companyRevenue: '0',
    status: status,
    playOrder: 1,
    startedAt: _now,
    finishedAt: null,
    createdAt: _now,
    updatedAt: _now,
    registeredCartelasCount: 1,
    calledNumbersCount: 5,
    registrationOpen: false,
    canRegister: false,
    category: GameCategory.normal,
  );
}

void main() {
  group('Auto Bingo runtime helpers', () {
    test('completingCalledOrderOf uses max order', () {
      final calls = [
        _call(letter: 'B', number: 1, order: 2),
        _call(letter: 'I', number: 16, order: 5),
        _call(letter: 'N', number: 31, order: 3),
      ];
      expect(completingCalledOrderOf(calls), 5);
      expect(completingCalledOrderOf(const []), 0);
    });

    test('attempt and terminal keys are stable', () {
      expect(
        autoBingoAttemptDedupeKey(
          sessionId: 's',
          roundIndex: 2,
          gameCartelaId: 'c1',
          completingCalledOrder: 7,
        ),
        's|2|c1|7',
      );
      expect(
        autoBingoTerminalSuppressKey(
          sessionId: 's',
          roundIndex: 2,
          gameCartelaId: 'c1',
        ),
        's|2|c1',
      );
    });

    test('gameAllowsAutoBingoClaims requires automatic rule + live status', () {
      expect(gameAllowsAutoBingoClaims(_game()), isTrue);
      expect(
        gameAllowsAutoBingoClaims(_game(status: GameStatus.winnerWindow)),
        isTrue,
      );
      expect(
        gameAllowsAutoBingoClaims(_game(status: GameStatus.finished)),
        isFalse,
      );
      expect(gameAllowsAutoBingoClaims(_game(ruleKey: 'MANUAL')), isFalse);
      expect(gameAllowsAutoBingoClaims(null), isFalse);
    });

    test('select detects pattern-complete cartelas from called keys only', () {
      final calls = _topRowCompleteCalls();
      final cartelas = [
        _cartela(id: 'a', number: 3),
        _cartela(id: 'b', number: 1),
        _cartela(id: 'c', number: 2),
      ];

      final eligible = selectAutoBingoPatternCompleteCartelas(
        cartelas: cartelas,
        calledNumbers: calls,
        ruleKey: 'ONE_LINE',
        terminalSuppressKeys: const {},
        attemptDedupeKeys: const {},
        sessionId: 'session-a',
        roundIndex: 1,
        completingCalledOrder: completingCalledOrderOf(calls),
      );

      expect(eligible.map((c) => c.id).toList(), ['b', 'c', 'a']);
    });

    test('manual marks are ignored — only calledNumberMarkKeys matter', () {
      final incompleteCalls = [
        _call(letter: 'B', number: 1, order: 1),
        _call(letter: 'I', number: 16, order: 2),
        _call(letter: 'N', number: 31, order: 3),
        _call(letter: 'G', number: 46, order: 4),
        // Missing O:61 — top row incomplete via called keys.
      ];
      final cartela = _cartela(id: 'a', number: 1);

      // Even if a caller had O:61 in a manual set, selector never sees it.
      expect(calledNumberMarkKeys(incompleteCalls).contains('O:61'), isFalse);

      final eligible = selectAutoBingoPatternCompleteCartelas(
        cartelas: [cartela],
        calledNumbers: incompleteCalls,
        ruleKey: 'ONE_LINE',
        terminalSuppressKeys: const {},
        attemptDedupeKeys: const {},
        sessionId: 'session-a',
        roundIndex: 1,
        completingCalledOrder: 4,
      );

      expect(eligible, isEmpty);
    });

    test('uncalled / empty strip yields no eligible cartelas', () {
      expect(
        selectAutoBingoPatternCompleteCartelas(
          cartelas: [_cartela(id: 'a', number: 1)],
          calledNumbers: const [],
          ruleKey: 'ONE_LINE',
          terminalSuppressKeys: const {},
          attemptDedupeKeys: const {},
          sessionId: 'session-a',
          roundIndex: 1,
          completingCalledOrder: 0,
        ),
        isEmpty,
      );
    });

    test('attempt dedupe and terminal suppress skip cartelas', () {
      final calls = _topRowCompleteCalls();
      final cartela = _cartela(id: 'a', number: 1);
      final attemptKey = autoBingoAttemptDedupeKey(
        sessionId: 'session-a',
        roundIndex: 1,
        gameCartelaId: 'a',
        completingCalledOrder: 5,
      );
      final suppressKey = autoBingoTerminalSuppressKey(
        sessionId: 'session-a',
        roundIndex: 1,
        gameCartelaId: 'a',
      );

      expect(
        selectAutoBingoPatternCompleteCartelas(
          cartelas: [cartela],
          calledNumbers: calls,
          ruleKey: 'ONE_LINE',
          terminalSuppressKeys: const {},
          attemptDedupeKeys: {attemptKey},
          sessionId: 'session-a',
          roundIndex: 1,
          completingCalledOrder: 5,
        ),
        isEmpty,
      );
      expect(
        selectAutoBingoPatternCompleteCartelas(
          cartelas: [cartela],
          calledNumbers: calls,
          ruleKey: 'ONE_LINE',
          terminalSuppressKeys: {suppressKey},
          attemptDedupeKeys: const {},
          sessionId: 'session-a',
          roundIndex: 1,
          completingCalledOrder: 5,
        ),
        isEmpty,
      );
    });

    test('non-registered cartelas are never selected', () {
      final calls = _topRowCompleteCalls();
      expect(
        selectAutoBingoPatternCompleteCartelas(
          cartelas: [
            _cartela(id: 'w', number: 1, status: GameCartelaStatus.winner),
            _cartela(id: 'b', number: 2, status: GameCartelaStatus.blocked),
          ],
          calledNumbers: calls,
          ruleKey: 'ONE_LINE',
          terminalSuppressKeys: const {},
          attemptDedupeKeys: const {},
          sessionId: 'session-a',
          roundIndex: 1,
          completingCalledOrder: 5,
        ),
        isEmpty,
      );
    });

    test('enqueue preserves order and skips duplicates', () {
      expect(
        enqueueAutoBingoCartelas(
          queue: ['a', 'b'],
          incomingIds: ['b', 'c', 'a', 'd'],
        ),
        ['a', 'b', 'c', 'd'],
      );
    });

    test('classify temporary vs permanent (R1)', () {
      final registered = _cartela(id: 'a', number: 1);

      expect(
        classifyAutoBingoQueueHead(
          effectiveAutoBingo: true,
          gameAllowsClaims: true,
          winnerWindowExpired: false,
          cartela: registered,
          sessionRoundMatches: true,
          isConfirmingOrClaimingAny: true,
          claimStripHoldActive: false,
          hasUnresolvedAttemptForCartela: false,
          bingoClaimLocked: false,
          claimScopeLoading: false,
          autoSubmitInFlight: false,
          terminalSuppressed: false,
        ),
        AutoBingoBlockKind.temporary,
      );

      expect(
        classifyAutoBingoQueueHead(
          effectiveAutoBingo: false,
          gameAllowsClaims: true,
          winnerWindowExpired: false,
          cartela: registered,
          sessionRoundMatches: true,
          isConfirmingOrClaimingAny: false,
          claimStripHoldActive: false,
          hasUnresolvedAttemptForCartela: false,
          bingoClaimLocked: false,
          claimScopeLoading: false,
          autoSubmitInFlight: false,
          terminalSuppressed: false,
        ),
        AutoBingoBlockKind.permanent,
      );

      expect(
        classifyAutoBingoQueueHead(
          effectiveAutoBingo: true,
          gameAllowsClaims: true,
          winnerWindowExpired: true,
          cartela: registered,
          sessionRoundMatches: true,
          isConfirmingOrClaimingAny: false,
          claimStripHoldActive: false,
          hasUnresolvedAttemptForCartela: false,
          bingoClaimLocked: false,
          claimScopeLoading: false,
          autoSubmitInFlight: false,
          terminalSuppressed: false,
        ),
        AutoBingoBlockKind.permanent,
      );

      expect(
        classifyAutoBingoQueueHead(
          effectiveAutoBingo: true,
          gameAllowsClaims: true,
          winnerWindowExpired: false,
          cartela: registered,
          sessionRoundMatches: true,
          isConfirmingOrClaimingAny: false,
          claimStripHoldActive: false,
          hasUnresolvedAttemptForCartela: false,
          bingoClaimLocked: false,
          claimScopeLoading: false,
          autoSubmitInFlight: false,
          terminalSuppressed: false,
        ),
        AutoBingoBlockKind.none,
      );
    });

    test('terminal suppress covers VALID/INVALID/AUTO_BINGO_NOT_ALLOWED (R2/R3)', () {
      expect(
        shouldTerminalSuppressAutoBingo(
          status: BingoClaimStatus.valid,
          retryAllowed: false,
          failureCode: null,
          cartelaStatus: GameCartelaStatus.winner,
        ),
        isTrue,
      );
      expect(
        shouldTerminalSuppressAutoBingo(
          status: BingoClaimStatus.invalid,
          retryAllowed: false,
          failureCode: null,
          cartelaStatus: GameCartelaStatus.blocked,
        ),
        isTrue,
      );
      expect(
        shouldTerminalSuppressAutoBingo(
          status: BingoClaimStatus.failed,
          retryAllowed: false,
          failureCode: 'AUTO_BINGO_NOT_ALLOWED',
          cartelaStatus: GameCartelaStatus.registered,
        ),
        isTrue,
      );
      expect(
        isQuietAutoBingoFailureCode('AUTO_BINGO_NOT_ALLOWED'),
        isTrue,
      );
      expect(isQuietAutoBingoFailureCode('CLAIM_NOT_ELIGIBLE'), isFalse);
      expect(
        shouldTerminalSuppressAutoBingo(
          status: BingoClaimStatus.checking,
          retryAllowed: false,
          failureCode: null,
          cartelaStatus: GameCartelaStatus.registered,
        ),
        isFalse,
      );
    });

    test('BingoClaimSource identity round-trip', () {
      expect(BingoClaimSource.fromIdentity('AUTO'), BingoClaimSource.auto);
      expect(BingoClaimSource.fromIdentity('MANUAL'), BingoClaimSource.manual);
      expect(BingoClaimSource.fromIdentity(null), BingoClaimSource.manual);
      expect(BingoClaimSource.auto.apiValue, 'AUTO');
    });

    test('three simultaneous eligible cartelas stay ordered (R1)', () {
      final calls = _topRowCompleteCalls();
      final eligible = selectAutoBingoPatternCompleteCartelas(
        cartelas: [
          _cartela(id: 'z', number: 30),
          _cartela(id: 'y', number: 10),
          _cartela(id: 'x', number: 20),
        ],
        calledNumbers: calls,
        ruleKey: 'ONE_LINE',
        terminalSuppressKeys: const {},
        attemptDedupeKeys: const {},
        sessionId: 'session-a',
        roundIndex: 1,
        completingCalledOrder: 5,
      );
      final queue = enqueueAutoBingoCartelas(
        queue: const [],
        incomingIds: eligible.map((c) => c.id),
      );

      expect(queue, ['y', 'x', 'z']);
      // Head temporary (CHECKING) must not drop siblings.
      expect(
        classifyAutoBingoQueueHead(
          effectiveAutoBingo: true,
          gameAllowsClaims: true,
          winnerWindowExpired: false,
          cartela: eligible.first,
          sessionRoundMatches: true,
          isConfirmingOrClaimingAny: true,
          claimStripHoldActive: true,
          hasUnresolvedAttemptForCartela: false,
          bingoClaimLocked: false,
          claimScopeLoading: false,
          autoSubmitInFlight: false,
          terminalSuppressed: false,
        ),
        AutoBingoBlockKind.temporary,
      );
      expect(queue.skip(1).toList(), ['x', 'z']);
    });

    test('extra balls do not reselect terminal-suppressed cartela (R2)', () {
      final first = _topRowCompleteCalls();
      final later = [
        ...first,
        _call(letter: 'B', number: 2, order: 6),
      ];
      final suppressKey = autoBingoTerminalSuppressKey(
        sessionId: 'session-a',
        roundIndex: 1,
        gameCartelaId: 'a',
      );

      expect(
        selectAutoBingoPatternCompleteCartelas(
          cartelas: [_cartela(id: 'a', number: 1)],
          calledNumbers: later,
          ruleKey: 'ONE_LINE',
          terminalSuppressKeys: {suppressKey},
          attemptDedupeKeys: const {},
          sessionId: 'session-a',
          roundIndex: 1,
          completingCalledOrder: 6,
        ),
        isEmpty,
      );
    });

    test('duplicate completing order shares one attempt key (R2)', () {
      final keyA = autoBingoAttemptDedupeKey(
        sessionId: 'session-a',
        roundIndex: 1,
        gameCartelaId: 'a',
        completingCalledOrder: 5,
      );
      final keyB = autoBingoAttemptDedupeKey(
        sessionId: 'session-a',
        roundIndex: 1,
        gameCartelaId: 'a',
        completingCalledOrder: 5,
      );
      expect(keyA, keyB);
      final keys = <String>{};
      expect(keys.add(keyA), isTrue);
      expect(keys.add(keyB), isFalse);
    });

    test('WW close permanently drops remaining queue head (R1)', () {
      expect(
        classifyAutoBingoQueueHead(
          effectiveAutoBingo: true,
          gameAllowsClaims: gameAllowsAutoBingoClaims(
            _game(status: GameStatus.finished),
          ),
          winnerWindowExpired: true,
          cartela: _cartela(id: 'a', number: 1),
          sessionRoundMatches: true,
          isConfirmingOrClaimingAny: false,
          claimStripHoldActive: false,
          hasUnresolvedAttemptForCartela: false,
          bingoClaimLocked: false,
          claimScopeLoading: false,
          autoSubmitInFlight: false,
          terminalSuppressed: false,
        ),
        AutoBingoBlockKind.permanent,
      );
    });

    test('bingoClaimLocked is temporary so unlock can resume (A6.3)', () {
      expect(
        classifyAutoBingoQueueHead(
          effectiveAutoBingo: true,
          gameAllowsClaims: true,
          winnerWindowExpired: false,
          cartela: _cartela(id: 'a', number: 1),
          sessionRoundMatches: true,
          isConfirmingOrClaimingAny: false,
          claimStripHoldActive: false,
          hasUnresolvedAttemptForCartela: false,
          bingoClaimLocked: true,
          claimScopeLoading: false,
          autoSubmitInFlight: false,
          terminalSuppressed: false,
        ),
        AutoBingoBlockKind.temporary,
      );
    });

    test('skipped AUTO submit releases attempt key and requeues front (A6.3)', () {
      expect(
        shouldReleaseAutoBingoAttemptAfterSkip(
          cartelaStatus: GameCartelaStatus.registered,
          alreadyTerminalSuppressed: false,
        ),
        isTrue,
      );
      expect(
        shouldReleaseAutoBingoAttemptAfterSkip(
          cartelaStatus: GameCartelaStatus.blocked,
          alreadyTerminalSuppressed: false,
        ),
        isFalse,
      );
      expect(
        shouldReleaseAutoBingoAttemptAfterSkip(
          cartelaStatus: GameCartelaStatus.registered,
          alreadyTerminalSuppressed: true,
        ),
        isFalse,
      );

      final keys = <String>{
        autoBingoAttemptDedupeKey(
          sessionId: 'session-a',
          roundIndex: 1,
          gameCartelaId: 'a',
          completingCalledOrder: 5,
        ),
      };
      final attemptKey = keys.single;
      // Simulate skip recovery: release key + requeue front.
      keys.remove(attemptKey);
      final queue = requeueAutoBingoCartelaFront(
        queue: const ['b', 'c'],
        cartelaId: 'a',
      );
      expect(keys, isEmpty);
      expect(queue, ['a', 'b', 'c']);
      expect(
        selectAutoBingoPatternCompleteCartelas(
          cartelas: [_cartela(id: 'a', number: 1)],
          calledNumbers: _topRowCompleteCalls(),
          ruleKey: 'ONE_LINE',
          terminalSuppressKeys: const {},
          attemptDedupeKeys: keys,
          sessionId: 'session-a',
          roundIndex: 1,
          completingCalledOrder: 5,
        ).map((c) => c.id),
        ['a'],
      );
    });
  });
}
