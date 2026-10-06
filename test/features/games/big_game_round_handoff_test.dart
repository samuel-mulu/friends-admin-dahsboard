import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/big_game_phase.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/big_game_live_presentation.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_game_finish_transition.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_status_socket_patch.dart';

final _now = DateTime.parse('2026-09-08T12:00:00.000Z');

GameModel _bigGame({
  required GameStatus status,
  required String sessionId,
  String slotId = 'slot-bg',
  int roundIndex = 1,
  int roundCount = 3,
  bool canRegister = false,
  DateTime? registrationOpensAt,
  DateTime? scheduledStartAt,
}) {
  return GameModel(
    id: slotId,
    sessionId: sessionId,
    staticCode: 'BG-1',
    playCode: 'PLAY-1',
    name: 'Big Game',
    gameRule: null,
    gameType: 'FULL_HOUSE',
    entryFee: '50',
    prizePerCartela: '40',
    companyFeePerCartela: '10',
    prizeAmount: '1000',
    companyRevenue: '0',
    status: status,
    playOrder: 1,
    startedAt: _now,
    finishedAt: status == GameStatus.finished ? _now : null,
    createdAt: _now,
    updatedAt: _now,
    registeredCartelasCount: 1,
    calledNumbersCount: 10,
    registrationOpen: canRegister,
    canRegister: canRegister,
    category: GameCategory.bigGame,
    roundCount: roundCount,
    roundIndex: roundIndex,
    registrationOpensAt: registrationOpensAt,
    scheduledStartAt: scheduledStartAt,
  );
}

GameModel _normalGame({
  required GameStatus status,
  required String sessionId,
  bool canRegister = false,
}) {
  return GameModel(
    id: 'id-$sessionId',
    sessionId: sessionId,
    staticCode: 'CODE-$sessionId',
    playCode: 'P-$sessionId',
    name: 'Game $sessionId',
    gameRule: null,
    gameType: 'NORMAL',
    entryFee: '10',
    prizePerCartela: '8',
    companyFeePerCartela: '2',
    prizeAmount: '0',
    companyRevenue: '0',
    status: status,
    playOrder: 1,
    startedAt: status == GameStatus.ready ? null : _now,
    finishedAt: status == GameStatus.finished ? _now : null,
    createdAt: _now,
    updatedAt: _now,
    registeredCartelasCount: 1,
    calledNumbersCount: 0,
    registrationOpen: status == GameStatus.ready,
    canRegister: canRegister,
    category: GameCategory.normal,
  );
}

GameOperationsCurrentResponse _ops({
  GameModel? live,
  GameModel? checking,
  GameModel? registration,
  List<GameModel> queue = const [],
}) {
  return GameOperationsCurrentResponse(
    liveGame: live,
    checkingGame: checking,
    registrationOpenGame: registration,
    queue: queue,
    timestamp: _now,
    serverNow: _now,
  );
}

void main() {
  group('resolveBigGamePresentationSeed — pin R1 when ops primary is R2', () {
    test('BG3: R2 READY + previousRound R1 FINISHED → presentation primary is R1',
        () {
      final round2 = _bigGame(
        status: GameStatus.ready,
        sessionId: 's2',
        roundIndex: 2,
        canRegister: true,
        registrationOpensAt: _now.subtract(const Duration(minutes: 1)),
        scheduledStartAt: _now.add(const Duration(minutes: 2)),
      );
      final operational = round2.copyWith(
        previousRound: BigGamePreviousRoundSummary(
          sessionId: 's1',
          roundIndex: 1,
          status: GameStatus.finished,
          finishedAt: _now,
          registeredCartelasCount: 4,
          playerOwnedPreviousRound: true,
        ),
      );
      final presentation = resolveBigGamePresentationSeed(operational);
      expect(presentation.sessionId, 's1');
      expect(presentation.status, GameStatus.finished);
      expect(presentation.displayRoundIndex, 1);
      expect(presentation.nextRoundRegistration?.sessionId, 's2');
      expect(presentation.nextRoundRegistration?.status, GameStatus.ready);
      expect(
        shouldEmbedBigGameTerminalReviewHost(
          game: presentation,
          phase: resolveBigGamePhase(presentation, now: _now),
        ),
        isTrue,
      );
      expect(
        shouldPinTerminalSession(
          status: presentation.status,
          postGameSummaryReviewActive: true,
        ),
        isTrue,
      );
      // BG4/BG5/BG6: advance target is R2 READY with countdown deadline from R2.
      expect(
        hasPlayableAdvanceTarget(
          operations: _ops(registration: round2),
          terminalGame: presentation,
          embeddedBigGame: true,
          now: _now,
        ),
        isTrue,
      );
      expect(
        resolveNextBigGameRound(
          operations: _ops(registration: round2),
          terminalRound: presentation,
        )?.scheduledStartAt,
        round2.scheduledStartAt,
      );
    });

    test('BG1: R1 PLAYING stays presentation primary (no pin rewrite)', () {
      final round1 = _bigGame(
        status: GameStatus.playing,
        sessionId: 's1',
        roundIndex: 1,
      );
      expect(resolveBigGamePresentationSeed(round1).sessionId, 's1');
    });

    test('BG2: R1 WINNER_WINDOW stays presentation primary', () {
      final round1 = _bigGame(
        status: GameStatus.winnerWindow,
        sessionId: 's1',
        roundIndex: 1,
      );
      expect(resolveBigGamePresentationSeed(round1).sessionId, 's1');
      expect(resolveBigGamePresentationSeed(round1).status, GameStatus.winnerWindow);
    });

    test('BG12: final round FINISHED stays presentation primary', () {
      final finalRound = _bigGame(
        status: GameStatus.finished,
        sessionId: 's3',
        roundIndex: 3,
        roundCount: 3,
      );
      final presentation = resolveBigGamePresentationSeed(finalRound);
      expect(presentation.sessionId, 's3');
      expect(presentation.status, GameStatus.finished);
      expect(presentation.nextRoundRegistration, isNull);
    });

    test('BG9/BG10: wrong previous roundIndex does not synthesize pin', () {
      final round3 = _bigGame(
        status: GameStatus.ready,
        sessionId: 's3',
        roundIndex: 3,
      );
      final operational = round3.copyWith(
        previousRound: const BigGamePreviousRoundSummary(
          sessionId: 's1',
          roundIndex: 1,
          status: GameStatus.finished,
        ),
      );
      expect(resolveBigGamePresentationSeed(operational).sessionId, 's3');
    });
  });

  group('isBigGameIncomingNextRoundAfterMounted', () {
    test('READY N+1 with previousRound matches mounted R1', () {
      final mounted = _bigGame(
        status: GameStatus.finished,
        sessionId: 's1',
        roundIndex: 1,
      );
      final incoming = _bigGame(
        status: GameStatus.ready,
        sessionId: 's2',
        roundIndex: 2,
      ).copyWith(
        previousRound: const BigGamePreviousRoundSummary(
          sessionId: 's1',
          roundIndex: 1,
          status: GameStatus.finished,
        ),
      );
      expect(
        isBigGameIncomingNextRoundAfterMounted(
          incoming: incoming,
          mountedSessionId: 's1',
          mountedGame: mounted,
        ),
        isTrue,
      );
    });

    test('BG7: already-PLAYING N+1 matches via roundIndex without previousRound',
        () {
      final mounted = _bigGame(
        status: GameStatus.finished,
        sessionId: 's1',
        roundIndex: 1,
      );
      final incoming = _bigGame(
        status: GameStatus.playing,
        sessionId: 's2',
        roundIndex: 2,
      );
      expect(
        isBigGameIncomingNextRoundAfterMounted(
          incoming: incoming,
          mountedSessionId: 's1',
          mountedGame: mounted,
        ),
        isTrue,
      );
    });

    test('BG9: different slot is rejected', () {
      final mounted = _bigGame(
        status: GameStatus.finished,
        sessionId: 's1',
        roundIndex: 1,
      );
      final incoming = _bigGame(
        status: GameStatus.ready,
        sessionId: 's2',
        slotId: 'other-slot',
        roundIndex: 2,
      );
      expect(
        isBigGameIncomingNextRoundAfterMounted(
          incoming: incoming,
          mountedSessionId: 's1',
          mountedGame: mounted,
        ),
        isFalse,
      );
    });
  });

  group('resolveNextBigGameRound (F6, F7: slot + sequence verified)', () {
    test('finds expected Round 2 already PLAYING via operations.liveGame', () {
      final round1Finished = _bigGame(
        status: GameStatus.finished,
        sessionId: 's1',
        roundIndex: 1,
      );
      final round2Playing = _bigGame(
        status: GameStatus.playing,
        sessionId: 's2',
        roundIndex: 2,
      );
      final resolved = resolveNextBigGameRound(
        operations: _ops(live: round2Playing),
        terminalRound: round1Finished,
      );
      expect(resolved?.sessionId, 's2');
    });

    test('finds expected Round 2 READY via operations.registrationOpenGame',
        () {
      final round1Finished = _bigGame(
        status: GameStatus.finished,
        sessionId: 's1',
        roundIndex: 1,
      );
      final round2Ready = _bigGame(
        status: GameStatus.ready,
        sessionId: 's2',
        roundIndex: 2,
        registrationOpensAt: _now.subtract(const Duration(minutes: 1)),
      );
      final resolved = resolveNextBigGameRound(
        operations: _ops(registration: round2Ready),
        terminalRound: round1Finished,
      );
      expect(resolved?.sessionId, 's2');
    });

    test('ignores an unrelated live game from a different slot', () {
      final round1Finished = _bigGame(
        status: GameStatus.finished,
        sessionId: 's1',
        roundIndex: 1,
      );
      final unrelated = _normalGame(status: GameStatus.playing, sessionId: 'other');
      final resolved = resolveNextBigGameRound(
        operations: _ops(live: unrelated),
        terminalRound: round1Finished,
      );
      expect(resolved, isNull);
    });

    test('ignores a same-slot session that is not roundIndex + 1', () {
      final round1Finished = _bigGame(
        status: GameStatus.finished,
        sessionId: 's1',
        roundIndex: 1,
      );
      final round3 = _bigGame(
        status: GameStatus.ready,
        sessionId: 's3',
        roundIndex: 3,
      );
      final resolved = resolveNextBigGameRound(
        operations: _ops(registration: round3),
        terminalRound: round1Finished,
      );
      expect(resolved, isNull);
    });

    test('returns null when operations has nothing for the slot', () {
      final round1Finished = _bigGame(
        status: GameStatus.finished,
        sessionId: 's1',
        roundIndex: 1,
      );
      final resolved = resolveNextBigGameRound(
        operations: _ops(),
        terminalRound: round1Finished,
      );
      expect(resolved, isNull);
    });
  });

  group('isBigGameNextRoundAdoptable', () {
    test('READY and already-live statuses are adoptable', () {
      for (final status in [
        GameStatus.ready,
        GameStatus.playing,
        GameStatus.checking,
        GameStatus.winnerWindow,
      ]) {
        final game = _bigGame(status: status, sessionId: 's2', roundIndex: 2);
        expect(isBigGameNextRoundAdoptable(game), isTrue, reason: '$status');
      }
    });

    test('terminal statuses are not adoptable', () {
      for (final status in [GameStatus.finished, GameStatus.cancelled]) {
        final game = _bigGame(status: status, sessionId: 's2', roundIndex: 2);
        expect(isBigGameNextRoundAdoptable(game), isFalse, reason: '$status');
      }
    });
  });

  group('isAdvanceRegistrationEligible — Big Game (F4, F5, F6)', () {
    test('READY Round 2 open-ended (next while live) is eligible', () {
      final round2 = _bigGame(
        status: GameStatus.ready,
        sessionId: 's2',
        roundIndex: 2,
        registrationOpensAt: _now,
        scheduledStartAt: null,
      );
      expect(
        isAdvanceRegistrationEligible(
          next: round2,
          embeddedBigGame: true,
          now: _now,
        ),
        isTrue,
      );
    });

    test(
        'already-PLAYING Round 2 is eligible without waiting for READY '
        '(advance_deferred fix)', () {
      final round2 = _bigGame(
        status: GameStatus.playing,
        sessionId: 's2',
        roundIndex: 2,
      );
      expect(
        isAdvanceRegistrationEligible(
          next: round2,
          embeddedBigGame: true,
          now: _now,
        ),
        isTrue,
      );
    });

    test('already-WINNER_WINDOW Round 2 is eligible (switch straight to live)',
        () {
      final round2 = _bigGame(
        status: GameStatus.winnerWindow,
        sessionId: 's2',
        roundIndex: 2,
      );
      expect(
        isAdvanceRegistrationEligible(
          next: round2,
          embeddedBigGame: true,
          now: _now,
        ),
        isTrue,
      );
    });

    test('READY Round 2 with closed registration window is not eligible', () {
      final round2 = _bigGame(
        status: GameStatus.ready,
        sessionId: 's2',
        roundIndex: 2,
        registrationOpensAt: _now.add(const Duration(minutes: 5)),
      );
      expect(
        isAdvanceRegistrationEligible(
          next: round2,
          embeddedBigGame: true,
          now: _now,
        ),
        isFalse,
      );
    });
  });

  group('isAdvanceRegistrationEligible — normal game regression (F12)', () {
    test('READY + canRegister is eligible', () {
      final next = _normalGame(
        status: GameStatus.ready,
        sessionId: 'b',
        canRegister: true,
      );
      expect(
        isAdvanceRegistrationEligible(
          next: next,
          embeddedBigGame: false,
          now: _now,
        ),
        isTrue,
      );
    });

    test('PLAYING is never eligible for a normal-game advance target', () {
      final next = _normalGame(status: GameStatus.playing, sessionId: 'b');
      expect(
        isAdvanceRegistrationEligible(
          next: next,
          embeddedBigGame: false,
          now: _now,
        ),
        isFalse,
      );
    });
  });

  group('hasPlayableAdvanceTarget — Big Game already-PLAYING (F6)', () {
    test('true when Round 2 is already PLAYING in operations.liveGame', () {
      final round1Finished = _bigGame(
        status: GameStatus.finished,
        sessionId: 's1',
        roundIndex: 1,
      );
      final round2Playing = _bigGame(
        status: GameStatus.playing,
        sessionId: 's2',
        roundIndex: 2,
      );
      expect(
        hasPlayableAdvanceTarget(
          operations: _ops(live: round2Playing),
          terminalGame: round1Finished,
          embeddedBigGame: true,
          now: _now,
        ),
        isTrue,
      );
    });

    test(
        'does not treat an unrelated live game as the next Big Game round '
        '(falls back to slot-has-more-rounds instead)', () {
      final round1Finished = _bigGame(
        status: GameStatus.finished,
        sessionId: 's1',
        roundIndex: 1,
      );
      final unrelated = _normalGame(status: GameStatus.playing, sessionId: 'other');
      expect(
        hasPlayableAdvanceTarget(
          operations: _ops(live: unrelated),
          terminalGame: round1Finished,
          embeddedBigGame: true,
          now: _now,
        ),
        isTrue, // still true via bigGameSlotHasMoreRoundsAfterTerminal fallback
      );
      // But the resolved advance target itself must not be the unrelated game.
      expect(
        resolveNextBigGameRound(
          operations: _ops(live: unrelated),
          terminalRound: round1Finished,
        ),
        isNull,
      );
    });
  });

  group('stale event protection (F10)', () {
    test(
        'stale Round 1 FINISHED socket payload is ignored once current '
        'session has moved to Round 2', () {
      final round2 = _bigGame(
        status: GameStatus.playing,
        sessionId: 's2',
        roundIndex: 2,
      );
      final stalePayload = {
        'sessionId': 's1',
        'id': 's1',
        'status': 'FINISHED',
      };
      final patched = applyStatusChangedSocketPatch(
        current: round2,
        payload: stalePayload,
      );
      expect(patched, isNull);
    });
  });
}
