import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/cartela_marks_storage.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/bingo_claim_eligibility.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/chain_round_cartela_state.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_game_finish_transition.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_presentation_phase.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_primary_game_selection.dart';

GameModel _chainGame({
  required GameStatus status,
  DateTime? roundPausedUntil,
  int roundIndex = 1,
  int roundCount = 2,
  int calledNumbersCount = 12,
}) {
  final now = DateTime.parse('2026-09-14T10:00:00.000Z');
  return GameModel(
    id: 'slot-chain',
    sessionId: 'session-chain',
    staticCode: 'CH-1',
    playCode: 'PLAY-CH',
    name: 'Chain Game',
    gameRule: GameRuleModel(id: 'rule-1', key: 'ONE_LINE', name: 'One Line'),
    gameType: 'ONE_LINE',
    entryFee: '25',
    prizePerCartela: '0',
    companyFeePerCartela: '25',
    prizeAmount: '5000',
    companyRevenue: '0',
    status: status,
    playOrder: 1,
    startedAt: now,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 4,
    calledNumbersCount: calledNumbersCount,
    registrationOpen: false,
    canRegister: false,
    category: GameCategory.chainGame,
    roundCount: roundCount,
    roundIndex: roundIndex,
    roundPrizeAmount: roundIndex == 1 ? '3000' : '2000',
    roundPausedUntil: roundPausedUntil,
  );
}

GameModel _normalGame({required GameStatus status}) {
  final now = DateTime.parse('2026-09-14T10:00:00.000Z');
  return GameModel(
    id: 'slot-normal',
    sessionId: 'session-normal',
    staticCode: 'N-1',
    playCode: 'PLAY-N',
    name: 'Normal Game',
    gameRule: GameRuleModel(id: 'rule-1', key: 'ONE_LINE', name: 'One Line'),
    gameType: 'ONE_LINE',
    entryFee: '10',
    prizePerCartela: '8',
    companyFeePerCartela: '2',
    prizeAmount: '80',
    companyRevenue: '20',
    status: status,
    playOrder: 1,
    startedAt: now,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 4,
    calledNumbersCount: 12,
    registrationOpen: false,
    canRegister: false,
    category: GameCategory.normal,
  );
}

GameCartelaModel _cartela({
  required String id,
  required GameCartelaStatus status,
  required bool isWinner,
}) {
  final now = DateTime.parse('2026-09-14T10:00:00.000Z');
  return GameCartelaModel(
    id: id,
    gameId: 'session-chain',
    userId: 'user-1',
    cartelaId: 'cartela-$id',
    status: status,
    isWinner: isWinner,
    blockedAt: status == GameCartelaStatus.blocked ? now : null,
    createdAt: now,
    updatedAt: now,
    cartela: CartelaModel(id: 'cartela-$id', number: 12, createdAt: now),
  );
}

void main() {
  final now = DateTime.parse('2026-09-14T10:00:00.000Z');

  group('Chain Game live presentation', () {
    test('PLAYING with a future roundPausedUntil is interRoundPause', () {
      final game = _chainGame(
        status: GameStatus.playing,
        roundIndex: 2,
        roundPausedUntil: now.add(const Duration(seconds: 20)),
      );

      expect(isChainRoundPauseActive(game, now: now), isTrue);
      expect(
        LivePresentationPhaseResolver.resolve(
          game: game,
          registrationCountdownClosed: true,
          canonicalRefetchInFlight: false,
          calledNumbers: const <CalledNumberModel>[],
          staleAfter: const Duration(seconds: 30),
          now: now,
        ),
        LivePresentationPhase.interRoundPause,
      );
      expect(chainRevealedRoundIndex(game, now: now), 1);
      expect(chainRoundPauseSecondsLeft(game, now: now), 20);
      expect(
        shouldHoldTerminalPaint(
          priorGame: _chainGame(status: GameStatus.winnerWindow, roundIndex: 1),
          operations: GameOperationsCurrentResponse(
            liveGame: game,
            checkingGame: null,
            registrationOpenGame: null,
            queue: const [],
            timestamp: now,
            serverNow: now,
          ),
        ),
        isFalse,
      );
    });

    test('PLAYING without a pause is liveCalling, not the summary', () {
      final game = _chainGame(status: GameStatus.playing);

      expect(isChainRoundPauseActive(game, now: now), isFalse);
      expect(
        LivePresentationPhaseResolver.resolve(
          game: game,
          registrationCountdownClosed: true,
          canonicalRefetchInFlight: false,
          calledNumbers: const <CalledNumberModel>[],
          staleAfter: const Duration(seconds: 30),
          now: now,
        ),
        LivePresentationPhase.liveCalling,
      );
    });

    test('FINISHED last round is review so the 60s post-game summary can run', () {
      final game = _chainGame(status: GameStatus.finished, roundIndex: 2);

      expect(
        LivePresentationPhaseResolver.resolve(
          game: game,
          registrationCountdownClosed: true,
          canonicalRefetchInFlight: false,
          calledNumbers: const <CalledNumberModel>[],
          staleAfter: const Duration(seconds: 30),
          now: now,
        ),
        LivePresentationPhase.review,
      );
      expect(
        canShowPostGameSummary(
          status: game.status,
          windowEndsAt: null,
          postGameSummaryReviewActive: true,
          now: now,
        ),
        isTrue,
      );
      expect(
        canShowChainInterRoundSummary(
          game: game,
          summaryActive: true,
          summaryDismissed: false,
          now: now,
        ),
        isFalse,
      );
    });

    test('inter-round 20s summary is visible only while the pause is active', () {
      final game = _chainGame(
        status: GameStatus.playing,
        roundIndex: 2,
        roundPausedUntil: now.add(const Duration(seconds: 20)),
      );

      expect(
        canShowChainInterRoundSummary(
          game: game,
          summaryActive: true,
          summaryDismissed: false,
          now: now,
        ),
        isTrue,
      );
      expect(
        canShowChainInterRoundSummary(
          game: game,
          summaryActive: true,
          summaryDismissed: false,
          now: now.add(const Duration(seconds: 21)),
        ),
        isFalse,
      );
      expect(
        canShowPostGameSummary(
          status: game.status,
          windowEndsAt: null,
          postGameSummaryReviewActive: false,
          now: now,
        ),
        isFalse,
      );
      expect(
        canShowPostGameSummary(
          status: game.status,
          windowEndsAt: null,
          postGameSummaryReviewActive: true,
          now: now,
        ),
        isFalse,
      );
    });

    test('winner window stays winnerWindow, not the 20s or 60s summary', () {
      final game = _chainGame(
        status: GameStatus.winnerWindow,
        roundIndex: 1,
      );

      expect(
        LivePresentationPhaseResolver.resolve(
          game: game,
          registrationCountdownClosed: true,
          canonicalRefetchInFlight: false,
          calledNumbers: const <CalledNumberModel>[],
          staleAfter: const Duration(seconds: 30),
          now: now,
        ),
        LivePresentationPhase.winnerWindow,
      );
      expect(
        canShowChainInterRoundSummary(
          game: game,
          summaryActive: true,
          summaryDismissed: false,
          now: now,
        ),
        isFalse,
      );
      expect(
        canShowPostGameSummary(
          status: game.status,
          windowEndsAt: now.add(const Duration(seconds: 8)),
          postGameSummaryReviewActive: true,
          now: now,
        ),
        isFalse,
      );
    });

    test('Normal FINISHED is review and never an inter-round pause', () {
      final game = _normalGame(status: GameStatus.finished);

      expect(
        LivePresentationPhaseResolver.resolve(
          game: game,
          registrationCountdownClosed: true,
          canonicalRefetchInFlight: false,
          calledNumbers: const <CalledNumberModel>[],
          staleAfter: const Duration(seconds: 30),
          now: now,
        ),
        LivePresentationPhase.review,
      );
      expect(isChainRoundPauseActive(game, now: now), isFalse);
      expect(
        canShowChainInterRoundSummary(
          game: game,
          summaryActive: true,
          summaryDismissed: false,
          now: now,
        ),
        isFalse,
      );
    });

    test(
      'last-round FINISHED stays primary over next READY so 60s summary can run',
      () {
        final finishedChain = _chainGame(
          status: GameStatus.finished,
          roundIndex: 2,
        );
        final nextReady = _normalGame(status: GameStatus.ready).copyWith(
          sessionId: 'session-next',
          canRegister: true,
          registrationOpen: true,
        );
        final ops = GameOperationsCurrentResponse(
          liveGame: finishedChain,
          checkingGame: null,
          registrationOpenGame: nextReady,
          queue: const [],
          timestamp: now,
          serverNow: now,
        );

        // Even without cartela ownership — same as guests watching finish.
        final primary = resolvePrimaryGameForOperations(
          operations: ops,
          ownsLiveCartelas: false,
        );
        expect(primary?.sessionId, finishedChain.sessionId);
        expect(primary?.status, GameStatus.finished);
        expect(
          canShowPostGameSummary(
            status: primary!.status,
            windowEndsAt: null,
            postGameSummaryReviewActive: true,
            now: now,
          ),
          isTrue,
        );
        expect(
          canShowChainInterRoundSummary(
            game: primary,
            summaryActive: true,
            summaryDismissed: false,
            now: now,
          ),
          isFalse,
        );
      },
    );

    test(
      'mid-chain PLAYING pause does not use post-game summary when next READY exists',
      () {
        final pausedChain = _chainGame(
          status: GameStatus.playing,
          roundIndex: 2,
          roundPausedUntil: now.add(const Duration(seconds: 20)),
        );
        final nextReady = _normalGame(status: GameStatus.ready).copyWith(
          sessionId: 'session-next',
          canRegister: true,
          registrationOpen: true,
        );
        final ops = GameOperationsCurrentResponse(
          liveGame: pausedChain,
          checkingGame: null,
          registrationOpenGame: nextReady,
          queue: const [],
          timestamp: now,
          serverNow: now,
        );

        // Mid-chain is still PLAYING: without ownership, registration can win —
        // but Chain queue does not open next mid-pause in production. Assert
        // the finished preference is not applied to PLAYING.
        final primary = resolvePrimaryGameForOperations(
          operations: ops,
          ownsLiveCartelas: false,
        );
        expect(primary?.status, isNot(GameStatus.finished));
        expect(
          canShowPostGameSummary(
            status: pausedChain.status,
            windowEndsAt: null,
            postGameSummaryReviewActive: true,
            now: now,
          ),
          isFalse,
        );
        expect(
          canShowChainInterRoundSummary(
            game: pausedChain,
            summaryActive: true,
            summaryDismissed: false,
            now: now,
          ),
          isTrue,
        );
      },
    );
  });

  group('Chain Game cartela reset', () {
    test('clears stale winners and keeps blocked cartelas', () {
      final game = _chainGame(
        status: GameStatus.playing,
        roundIndex: 2,
        roundPausedUntil: now.add(const Duration(seconds: 12)),
      );
      final winner = _cartela(
        id: 'w1',
        status: GameCartelaStatus.winner,
        isWinner: true,
      );
      final blocked = _cartela(
        id: 'b1',
        status: GameCartelaStatus.blocked,
        isWinner: false,
      );

      final next = normalizeChainPlayableCartelas(
        game: game,
        cartelas: [winner, blocked],
      );

      expect(next[0].status, GameCartelaStatus.registered);
      expect(next[0].isWinner, isFalse);
      expect(next[1].status, GameCartelaStatus.blocked);
      expect(next[1].id, 'b1');
    });

    test('does not rewrite cartelas for Normal games', () {
      final game = _normalGame(status: GameStatus.playing);
      final winner = _cartela(
        id: 'w1',
        status: GameCartelaStatus.winner,
        isWinner: true,
      );
      final next = normalizeChainPlayableCartelas(
        game: game,
        cartelas: [winner],
      );
      expect(next.single.status, GameCartelaStatus.winner);
      expect(next.single.isWinner, isTrue);
    });

    test('Bingo is ready for a stale chain winner that is REGISTERED', () {
      final game = _chainGame(
        status: GameStatus.playing,
        roundIndex: 2,
        roundPausedUntil: now.add(const Duration(seconds: 8)),
      );
      final cartela = _cartela(
        id: 'w1',
        status: GameCartelaStatus.registered,
        isWinner: true,
      );

      expect(
        isCartelaEligibleForBingoClaim(
          game: game,
          gameCartela: cartela,
          winnerWindowExpired: false,
          hasPendingClaim: false,
          isCountdownLocked: false,
        ),
        isTrue,
      );
    });

    test('Bingo stays off for blocked chain cartelas', () {
      final game = _chainGame(status: GameStatus.playing, roundIndex: 2);
      final cartela = _cartela(
        id: 'b1',
        status: GameCartelaStatus.blocked,
        isWinner: false,
      );

      expect(
        isCartelaEligibleForBingoClaim(
          game: game,
          gameCartela: cartela,
          winnerWindowExpired: false,
          hasPendingClaim: false,
          isCountdownLocked: false,
        ),
        isFalse,
      );
    });

    test('skips local FINISHED only while later chain rounds remain', () {
      expect(
        shouldSkipLocalChainWinnerWindowFinish(
          _chainGame(status: GameStatus.winnerWindow, roundIndex: 1),
        ),
        isTrue,
      );
      // Last round WW: same local FINISHED → 60s Continue path as Normal.
      expect(
        shouldSkipLocalChainWinnerWindowFinish(
          _chainGame(status: GameStatus.winnerWindow, roundIndex: 2),
        ),
        isFalse,
      );
      expect(
        shouldSkipLocalChainWinnerWindowFinish(
          _chainGame(
            status: GameStatus.winnerWindow,
            roundIndex: 2,
            roundPausedUntil: now.add(const Duration(seconds: 5)),
          ),
        ),
        isTrue,
      );
      expect(
        shouldSkipLocalChainWinnerWindowFinish(
          _normalGame(status: GameStatus.winnerWindow),
        ),
        isFalse,
      );
    });

    test(
      'merge keeps Chain PLAYING+pause over stale winnerWindow snapshot',
      () {
        final pausedUntil = DateTime.now().add(const Duration(seconds: 18));
        final current = _chainGame(
          status: GameStatus.playing,
          roundIndex: 2,
          roundPausedUntil: pausedUntil,
        );
        final incoming = _chainGame(
          status: GameStatus.winnerWindow,
          roundIndex: 1,
        );

        final merged = GameModel.mergeCanonicalSessionState(
          current: current,
          incoming: incoming,
        );

        expect(merged.status, GameStatus.playing);
        expect(merged.roundPausedUntil, pausedUntil);
        expect(merged.roundIndex, 2);
        expect(merged.winnerWindowEndsAt, isNull);
      },
    );

    test(
      'merge keeps Chain FINISHED over stale winnerWindow snapshot',
      () {
        final finished = _chainGame(
          status: GameStatus.finished,
          roundIndex: 2,
        ).copyWith(finishedAt: now);
        final incoming = _chainGame(
          status: GameStatus.winnerWindow,
          roundIndex: 2,
        );

        final merged = GameModel.mergeCanonicalSessionState(
          current: finished,
          incoming: incoming,
        );

        expect(merged.status, GameStatus.finished);
      },
    );

    test('Bingo stays disarmed until a new ball after chain round resume', () {
      final game = _chainGame(status: GameStatus.playing, roundIndex: 2);
      final cartela = _cartela(
        id: 'w1',
        status: GameCartelaStatus.registered,
        isWinner: false,
      );

      expect(
        isChainBingoArmedAfterNewBall(
          game: game,
          calledNumbersCount: 18,
          armedAfterCalledCount: 18,
        ),
        isFalse,
      );
      expect(
        isChainBingoArmedAfterNewBall(
          game: game,
          calledNumbersCount: 19,
          armedAfterCalledCount: 18,
        ),
        isTrue,
      );
      expect(
        isCartelaEligibleForBingoClaim(
          game: game,
          gameCartela: cartela,
          winnerWindowExpired: false,
          hasPendingClaim: false,
          isCountdownLocked: false,
          calledNumbersCount: 18,
          chainBingoArmedAfterCalledCount: 18,
        ),
        isFalse,
      );
      expect(
        isCartelaEligibleForBingoClaim(
          game: game,
          gameCartela: cartela,
          winnerWindowExpired: false,
          hasPendingClaim: false,
          isCountdownLocked: false,
          calledNumbersCount: 19,
          chainBingoArmedAfterCalledCount: 18,
        ),
        isTrue,
      );
      expect(
        isChainBingoArmedAfterNewBall(
          game: _normalGame(status: GameStatus.playing),
          calledNumbersCount: 18,
          armedAfterCalledCount: 18,
        ),
        isTrue,
      );
    });

    test('round_finished payload leaves PLAYING with pause, not FINISHED', () {
      final pausedUntil = now.add(const Duration(seconds: 20));
      final next = applyChainRoundFinishedToGame(
        game: _chainGame(status: GameStatus.winnerWindow, roundIndex: 1),
        payload: {
          'finishedRoundIndex': 1,
          'nextRoundIndex': 2,
          'pausedUntil': pausedUntil.toIso8601String(),
          'nextRoundPrizeAmount': '2000',
        },
      );

      expect(next.status, GameStatus.playing);
      expect(next.roundIndex, 2);
      expect(next.roundPrizeAmount, '2000');
      expect(next.roundPausedUntil, isNotNull);
      expect(
        LivePresentationPhaseResolver.resolve(
          game: next,
          registrationCountdownClosed: true,
          canonicalRefetchInFlight: false,
          calledNumbers: const <CalledNumberModel>[],
          staleAfter: const Duration(seconds: 30),
          now: now,
        ),
        LivePresentationPhase.interRoundPause,
      );
      expect(
        canShowPostGameSummary(
          status: next.status,
          windowEndsAt: null,
          postGameSummaryReviewActive: true,
          now: now,
        ),
        isFalse,
      );
    });

    test('20s summary reads winners from roundResults, not cartela status', () {
      final now = DateTime.parse('2026-09-14T10:00:00.000Z');
      final game = GameModel(
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
        status: GameStatus.playing,
        playOrder: 1,
        startedAt: now,
        finishedAt: null,
        createdAt: now,
        updatedAt: now,
        registeredCartelasCount: 4,
        calledNumbersCount: 12,
        registrationOpen: false,
        canRegister: false,
        category: GameCategory.chainGame,
        roundCount: 2,
        roundIndex: 2,
        roundPrizeAmount: '2000',
        roundPausedUntil: now.add(const Duration(seconds: 20)),
        roundResults: const [
          ChainRoundResultSummary(
            roundIndex: 1,
            prizeAmount: '3000',
            outcome: ChainRoundOutcome.won,
            winners: [
              ChainRoundWinnerSummary(
                gameCartelaId: 'gc-1',
                cartelaNumber: 12,
                amount: '3000',
              ),
            ],
          ),
        ],
      );

      expect(
        winnerCartelaNumbersFromChainRoundResults(
          roundResults: game.roundResults,
          roundIndex: 1,
        ),
        [12],
      );
      expect(
        winnerCartelaNumbersFromChainRoundResults(
          roundResults: game.roundResults,
          roundIndex: 2,
        ),
        isEmpty,
      );
    });

    test('round_finished socket payload supplies winner numbers immediately', () {
      expect(
        winnerCartelaNumbersFromChainRoundFinishedPayload({
          'finishedRoundIndex': 1,
          'winners': [
            {'gameCartelaId': 'gc-1', 'cartelaNumber': 12, 'amount': '3000'},
            {'gameCartelaId': 'gc-2', 'cartelaNumber': 7, 'amount': '0'},
          ],
        }),
        [7, 12],
      );
      expect(
        winnerCartelaNumbersFromChainRoundFinishedPayload({
          'finishedRoundIndex': 1,
        }),
        isEmpty,
      );
    });
  });

  group('Chain Game marks persist on the same session', () {
    test('storage key is scoped to session id, not round index', () {
      const userId = 'user-1';
      const sessionId = 'session-chain';
      expect(
        CartelaMarksStorage.sessionKey(userId, sessionId),
        CartelaMarksStorage.sessionKey(userId, sessionId),
      );
      expect(
        CartelaMarksStorage.sessionKey(userId, sessionId),
        isNot(CartelaMarksStorage.sessionKey(userId, 'session-other')),
      );
    });
  });
}
