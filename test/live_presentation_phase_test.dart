import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_presentation_phase.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_ready_transition_lock.dart';

const _testStaleAfter = Duration(seconds: 45);
GameModel _registrationGame({
  DateTime? scheduledStartAt,
  bool canRegister = true,
}) {
  return GameModel.fromOperationJson({
    'slotId': 'slot-auto-1',
    'sessionId': 'session-auto-1',
    'staticCode': 'FULL_HOUSE-S1',
    'playCode': 'BINGO-AUTO1',
    'playerStatus': 'registrationOpen',
    'rawStatus': 'READY',
    'operationMode': 'AUTO',
    'scheduledStartAt': scheduledStartAt?.toIso8601String(),
    'canRegister': canRegister,
    'registrationOpen': true,
    'entryFee': '10',
    'prizePerCartela': '8',
    'prizeAmount': '0',
    'registeredCartelasCount': 0,
    'calledNumbersCount': 0,
    'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
  });
}

GameModel _playingGame({DateTime? nextAutoCallAt}) {
  return GameModel.fromOperationJson({
    'slotId': 'slot-auto-1',
    'sessionId': 'session-auto-1',
    'staticCode': 'FULL_HOUSE-S1',
    'playCode': 'BINGO-AUTO1',
    'playerStatus': 'playing',
    'rawStatus': 'PLAYING',
    'operationMode': 'AUTO',
    'canRegister': false,
    'registrationOpen': false,
    'nextAutoCallAt': nextAutoCallAt?.toIso8601String(),
    'entryFee': '10',
    'prizePerCartela': '8',
    'prizeAmount': '16',
    'registeredCartelasCount': 2,
    'calledNumbersCount': 0,
    'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
  });
}

GameModel _nextQueueGame({bool canRegister = true}) {
  return GameModel.fromOperationJson({
    'slotId': 'slot-queue-1',
    'sessionId': 'session-queue-1',
    'staticCode': 'FULL_HOUSE-Q1',
    'playCode': 'BINGO-QUEUE1',
    'playerStatus': 'registrationOpen',
    'rawStatus': 'NEXT',
    'operationMode': 'AUTO',
    'canRegister': canRegister,
    'registrationOpen': canRegister,
    'entryFee': '10',
    'prizePerCartela': '8',
    'prizeAmount': '0',
    'registeredCartelasCount': 0,
    'calledNumbersCount': 0,
    'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
  });
}

void main() {
  group('resolveRegistrationCountdownDeadline', () {
    test('returns null while post-game summary hold is active', () {
      final deadline = DateTime.utc(2026, 6, 10, 12, 3, 0);
      expect(
        resolveRegistrationCountdownDeadline(
          game: _registrationGame(scheduledStartAt: deadline),
          timingConfigLoaded: true,
          isLoading: false,
          registrationCountdownClosed: false,
          canonicalRefetchInFlight: false,
          countdownSessionId: 'session-auto-1',
          sessionKey: 'session-auto-1',
          countdownDeadline: deadline,
          postGameSummaryHoldActive: true,
        ),
        isNull,
      );
    });
    test('returns null during refetch before local close', () {
      final game = _registrationGame(
        scheduledStartAt: DateTime.now().add(const Duration(seconds: 10)),
      );
      final deadline = DateTime.now().add(const Duration(seconds: 10));

      expect(
        resolveRegistrationCountdownDeadline(
          game: game,
          timingConfigLoaded: true,
          isLoading: false,
          registrationCountdownClosed: false,
          canonicalRefetchInFlight: true,
          countdownSessionId: 'session-auto-1',
          sessionKey: 'session-auto-1',
          countdownDeadline: deadline,
        ),
        isNull,
      );
    });

    test('keeps deadline after local close during refetch', () {
      final game = _registrationGame(
        scheduledStartAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      final deadline = DateTime.now().subtract(const Duration(seconds: 1));

      expect(
        resolveRegistrationCountdownDeadline(
          game: game,
          timingConfigLoaded: true,
          isLoading: false,
          registrationCountdownClosed: true,
          canonicalRefetchInFlight: true,
          countdownSessionId: 'session-auto-1',
          sessionKey: 'session-auto-1',
          countdownDeadline: deadline,
        ),
        deadline,
      );
    });

    test('hides countdown while another live game is still active', () {
      final deadline = DateTime.now().add(const Duration(seconds: 20));

      expect(
        resolveRegistrationCountdownDeadline(
          game: _registrationGame(scheduledStartAt: deadline),
          timingConfigLoaded: true,
          isLoading: false,
          registrationCountdownClosed: false,
          canonicalRefetchInFlight: false,
          countdownSessionId: 'session-auto-1',
          sessionKey: 'session-auto-1',
          countdownDeadline: deadline,
          blockingLiveGameExists: true,
        ),
        isNull,
      );
    });

    test('reopened backend countdown beats stale local close latch', () {
      final now = DateTime.utc(2026, 6, 29, 12, 0, 0);
      final staleDeadline = now.subtract(const Duration(seconds: 30));
      final freshDeadline = now.add(const Duration(seconds: 115));
      final game = _registrationGame(scheduledStartAt: freshDeadline);

      expect(
        resolveRegistrationCountdownDeadline(
          game: game,
          timingConfigLoaded: true,
          isLoading: false,
          registrationCountdownClosed: true,
          canonicalRefetchInFlight: false,
          countdownSessionId: 'session-auto-1',
          sessionKey: 'session-auto-1',
          countdownDeadline: staleDeadline,
          now: now,
        ),
        game.scheduledStartAt,
      );
    });
  });

  group('ready transition lock helpers', () {
    test(
      'canonical null during lock keeps transition shell before timeout',
      () {
        final startedAt = DateTime.utc(2026, 6, 29, 12, 0, 0);
        final current = _registrationGame(
          scheduledStartAt: startedAt.subtract(const Duration(seconds: 2)),
        ).copyWith(canRegister: false);
        final lock = startReadyTransitionLock(
          game: current,
          reason: ReadyTransitionReason.noPlayersHandoff,
          startedAt: startedAt,
        );

        expect(
          shouldKeepTransitionLockShell(
            lock: lock,
            currentGame: current,
            incomingGame: null,
            now: startedAt.add(const Duration(seconds: 3)),
          ),
          isTrue,
        );
      },
    );

    test('lock stays active without TTL timeout', () {
      final startedAt = DateTime.utc(2026, 6, 29, 12, 0, 0);
      final current = _registrationGame().copyWith(canRegister: false);
      final lock = startReadyTransitionLock(
        game: current,
        reason: ReadyTransitionReason.noPlayersHandoff,
        startedAt: startedAt,
      );

      expect(
        shouldKeepTransitionLockShell(
          lock: lock,
          currentGame: current,
          incomingGame: null,
          now: startedAt.add(const Duration(minutes: 5)),
        ),
        isTrue,
      );
    });

    test('next READY session supersedes no-players lock', () {
      final now = DateTime.utc(2026, 6, 29, 12, 0, 0);
      final nextReady = _registrationGame(
        scheduledStartAt: now.add(const Duration(seconds: 108)),
      ).copyWith(sessionId: 'session-auto-2');

      expect(
        registrationOpenGameSupersedesTransitionLock(
          registrationOpenGame: nextReady,
          lockedSessionId: 'session-auto-1',
          lockReason: ReadyTransitionReason.noPlayersHandoff,
          now: now,
        ),
        isTrue,
      );
    });

    test('same READY session supersedes once countdown reopens', () {
      final now = DateTime.utc(2026, 6, 29, 12, 0, 0);
      expect(
        registrationOpenGameSupersedesTransitionLock(
          registrationOpenGame: _registrationGame(
            scheduledStartAt: now.add(const Duration(seconds: 20)),
          ),
          lockedSessionId: 'session-auto-1',
          lockReason: ReadyTransitionReason.noPlayersHandoff,
          now: now,
        ),
        isTrue,
      );
    });

    test('preparing lock is not superseded by READY B', () {
      final now = DateTime.utc(2026, 6, 29, 12, 0, 0);
      final nextReady = _registrationGame(
        scheduledStartAt: now.add(const Duration(seconds: 108)),
      ).copyWith(sessionId: 'session-auto-2');

      expect(
        registrationOpenGameSupersedesTransitionLock(
          registrationOpenGame: nextReady,
          lockedSessionId: 'session-auto-1',
          lockReason: ReadyTransitionReason.preparingToPlay,
          now: now,
        ),
        isFalse,
      );
    });

    test('lock continues while waiting for next READY session', () {
      final startedAt = DateTime.utc(2026, 6, 29, 12, 0, 0);
      final staleReady = _registrationGame(
        scheduledStartAt: startedAt.subtract(const Duration(seconds: 2)),
        canRegister: false,
      );
      final lock = startReadyTransitionLock(
        game: staleReady,
        reason: ReadyTransitionReason.noPlayersHandoff,
        startedAt: startedAt,
      );

      expect(
        shouldClearReadyTransitionLock(
          lock: lock,
          operations: null,
          pinnedGame: staleReady,
          now: startedAt,
        ),
        isFalse,
      );
    });
  });

  group('LivePresentationPhaseResolver', () {
    test('no active game when operations snapshot is empty', () {
      final phase = LivePresentationPhaseResolver.resolve(
        game: null,
        registrationCountdownClosed: false,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: _testStaleAfter,
      );

      expect(phase, LivePresentationPhase.noActiveGame);
    });

    test('registration open while countdown is active', () {
      final game = _registrationGame(
        scheduledStartAt: DateTime.now().add(const Duration(seconds: 30)),
      );

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: false,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: _testStaleAfter,
      );

      expect(phase, LivePresentationPhase.registrationOpen);
      expect(phase.cartelaActionsEnabled, isTrue);
    });

    test('READY stays registration-open while another live game is active', () {
      final game = _registrationGame(
        scheduledStartAt: DateTime.now().subtract(const Duration(seconds: 2)),
      );

      expect(
        LivePresentationPhaseResolver.registrationCountdownElapsed(
          game: game,
          registrationCountdownClosed: false,
          staleAfter: _testStaleAfter,
          blockingLiveGameExists: true,
        ),
        isFalse,
      );

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: false,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: _testStaleAfter,
        blockingLiveGameExists: true,
      );

      expect(phase, LivePresentationPhase.registrationOpen);
    });

    test(
      'registration reopens when a fresh countdown starts after local close',
      () {
        final game = _registrationGame(
          scheduledStartAt: DateTime.now().add(const Duration(seconds: 45)),
        );

        final phase = LivePresentationPhaseResolver.resolve(
          game: game,
          registrationCountdownClosed: true,
          canonicalRefetchInFlight: false,
          calledNumbers: const [],
          staleAfter: _testStaleAfter,
        );

        expect(phase, LivePresentationPhase.registrationOpen);
        expect(phase.cartelaActionsEnabled, isTrue);
        expect(
          LivePresentationPhaseResolver.registrationCountdownElapsed(
            game: game,
            registrationCountdownClosed: true,
            staleAfter: _testStaleAfter,
          ),
          isFalse,
        );
      },
    );

    test('preparing game when countdown reaches zero locally', () {
      final game = _registrationGame(
        scheduledStartAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: true,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: _testStaleAfter,
      );

      expect(phase, LivePresentationPhase.preparingGame);
      expect(phase.cartelaActionsEnabled, isFalse);
    });

    test('empty local registration close shows no players phase', () {
      final game = _registrationGame(
        scheduledStartAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: true,
        emptyRegistrationClosedNoPlayers: true,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: _testStaleAfter,
      );

      expect(phase, LivePresentationPhase.noPlayersJoined);
      expect(phase.isRegistrationLayout, isFalse);
    });

    test('registered countdown close still shows preparing game', () {
      final game = _registrationGame(
        scheduledStartAt: DateTime.now().subtract(const Duration(seconds: 1)),
      ).copyWith(registeredCartelasCount: 1);

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: true,
        emptyRegistrationClosedNoPlayers: false,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: _testStaleAfter,
      );

      expect(phase, LivePresentationPhase.preparingGame);
    });

    test('preparing game while canonical refetch is in flight', () {
      final game = _registrationGame(
        scheduledStartAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: true,
        canonicalRefetchInFlight: true,
        calledNumbers: const [],
        staleAfter: _testStaleAfter,
      );

      expect(phase, LivePresentationPhase.preparingGame);
    });

    test('stale past scheduledStartAt does not lock preparing game', () {
      final game = _registrationGame(
        scheduledStartAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      expect(
        LivePresentationPhaseResolver.registrationCountdownElapsed(
          game: game,
          registrationCountdownClosed: false,
          staleAfter: _testStaleAfter,
        ),
        isFalse,
      );

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: false,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: _testStaleAfter,
      );

      expect(phase, LivePresentationPhase.registrationOpen);
    });

    test('configured preparing cap overrides the default stale guard', () {
      final game = _registrationGame(
        scheduledStartAt: DateTime.now().subtract(const Duration(seconds: 20)),
      );

      expect(
        LivePresentationPhaseResolver.registrationCountdownElapsed(
          game: game,
          registrationCountdownClosed: false,
          staleAfter: const Duration(seconds: 10),
        ),
        isFalse,
      );

      expect(
        LivePresentationPhaseResolver.registrationCountdownElapsed(
          game: game,
          registrationCountdownClosed: false,
          staleAfter: const Duration(seconds: 30),
        ),
        isTrue,
      );
    });

    test('recently elapsed scheduledStartAt still closes the countdown', () {
      final game = _registrationGame(
        scheduledStartAt: DateTime.now().subtract(const Duration(seconds: 2)),
      );

      expect(
        LivePresentationPhaseResolver.registrationCountdownElapsed(
          game: game,
          registrationCountdownClosed: false,
          staleAfter: _testStaleAfter,
        ),
        isTrue,
      );
    });

    test('registration closed when canRegister is false', () {
      final game = _registrationGame(canRegister: false);

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: false,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: _testStaleAfter,
      );

      expect(phase, LivePresentationPhase.preparingGame);
      expect(phase.cartelaActionsEnabled, isFalse);
      expect(
        LivePresentationPhaseResolver.registrationCountdownElapsed(
          game: game,
          registrationCountdownClosed: false,
          staleAfter: _testStaleAfter,
        ),
        isTrue,
      );
    });

    test(
      'missed-player READY primary routes to registration layout, not live sticky',
      () {
        final game = _registrationGame(
          scheduledStartAt: DateTime.now().add(const Duration(seconds: 30)),
        );

        final phase = LivePresentationPhaseResolver.resolve(
          game: game,
          registrationCountdownClosed: false,
          canonicalRefetchInFlight: false,
          calledNumbers: const [],
          staleAfter: _testStaleAfter,
          blockingLiveGameExists: true,
        );

        expect(
          phase,
          LivePresentationPhase.registrationOpen,
          reason: '_game=READY+canRegister+blockingLive → registrationOpen',
        );
        expect(
          phase.isRegistrationLayout,
          isTrue,
          reason:
              'isRegistrationLayout=true routes _shouldUseRegistrationOpenLayout=true',
        );
        expect(
          phase.keepsInlineCartelaLayout,
          isFalse,
          reason:
              'keepsInlineCartelaLayout=false → showsInlinePlayCartelas=false '
              '→ _usesStickyLivePlayHeader=false, never builds called-number strip',
        );
        expect(
          phase.cartelaActionsEnabled,
          isTrue,
          reason: 'Registration actions are enabled; player can pick cartelas',
        );
      },
    );

    test('NEXT queue item is never treated as registerable UI', () {
      final game = _nextQueueGame(canRegister: true);

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: false,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: _testStaleAfter,
      );

      expect(phase, LivePresentationPhase.preparingGame);
      expect(phase.cartelaActionsEnabled, isFalse);
    });

    test('registrationCountdownElapsed returns true when balls called', () {
      final game = _registrationGame(
        canRegister: true,
      ).copyWith(calledNumbersCount: 3);

      expect(
        LivePresentationPhaseResolver.registrationCountdownElapsed(
          game: game,
          registrationCountdownClosed: false,
          staleAfter: _testStaleAfter,
        ),
        isTrue,
      );
    });

    test('registration open with called numbers switches to live calling', () {
      final game = _registrationGame(canRegister: false);

      final phase = LivePresentationPhaseResolver.resolve(
        game: game.copyWith(calledNumbersCount: 2),
        registrationCountdownClosed: true,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: _testStaleAfter,
      );

      expect(phase, LivePresentationPhase.liveCalling);
      expect(phase.isRegistrationLayout, isFalse);
    });

    test('playing with no balls shows waiting for first ball', () {
      final game = _playingGame(
        nextAutoCallAt: DateTime.now().add(const Duration(seconds: 5)),
      );

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: false,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: _testStaleAfter,
      );

      expect(phase, LivePresentationPhase.liveWaitingFirstBall);
      expect(phase.isRegistrationLayout, isFalse);
    });

    test('playing status wins over stale registration countdown latch', () {
      final game = _playingGame(
        nextAutoCallAt: DateTime.now().add(const Duration(seconds: 5)),
      );

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: true,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: _testStaleAfter,
      );

      expect(phase, LivePresentationPhase.liveWaitingFirstBall);
      expect(phase.isRegistrationLayout, isFalse);
    });

    test('server called count during preparing switches to live calling', () {
      final game = _registrationGame(canRegister: false);

      final phase = LivePresentationPhaseResolver.resolve(
        game: game.copyWith(status: GameStatus.ready, calledNumbersCount: 3),
        registrationCountdownClosed: true,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: _testStaleAfter,
      );

      expect(phase, LivePresentationPhase.liveCalling);
      expect(phase.isRegistrationLayout, isFalse);
    });

    test('server called count stays preparing while transition lock active', () {
      final game = _registrationGame(canRegister: false);

      final phase = LivePresentationPhaseResolver.resolve(
        game: game.copyWith(status: GameStatus.ready, calledNumbersCount: 3),
        registrationCountdownClosed: true,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: _testStaleAfter,
        preparingTransitionActive: true,
      );

      expect(phase, LivePresentationPhase.preparingGame);
      expect(phase.isRegistrationLayout, isTrue);
    });

    test('post-game summary hold blocks advance for configured duration', () {
      const hold = Duration(seconds: 30);
      final shownAt = DateTime(2026, 6, 10, 12, 0, 0);
      final now = shownAt.add(const Duration(seconds: 12));

      expect(
        postGameSummaryHoldElapsed(
          shownAt: shownAt,
          now: now,
          minimumHold: hold,
        ),
        isFalse,
      );
      expect(
        postGameSummaryRemainingHold(
          shownAt: shownAt,
          now: now,
          minimumHold: hold,
        ),
        const Duration(seconds: 18),
      );
      expect(
        postGameSummarySecondsRemaining(
          shownAt: shownAt,
          now: now,
          minimumHold: hold,
        ),
        18,
      );
      expect(kPostGameSummaryHoldSeconds, 60);
    });

    test('post-game summary hold elapsed after default duration', () {
      final shownAt = DateTime(2026, 6, 10, 12, 0, 0);
      final hold = kPostGameSummaryHold;
      final now = shownAt.add(hold);

      expect(
        postGameSummaryHoldElapsed(
          shownAt: shownAt,
          now: now,
          minimumHold: hold,
        ),
        isTrue,
      );
      expect(
        postGameSummaryRemainingHold(
          shownAt: shownAt,
          now: now,
          minimumHold: hold,
        ),
        Duration.zero,
      );
    });

    test(
      'post-game summary hold respects custom duration from timing config',
      () {
        final shownAt = DateTime(2026, 6, 10, 12, 0, 0);
        const customHold = Duration(seconds: 45);
        final now = shownAt.add(const Duration(seconds: 30));

        expect(
          postGameSummaryHoldElapsed(
            shownAt: shownAt,
            now: now,
            minimumHold: customHold,
          ),
          isFalse,
        );
        expect(
          postGameSummarySecondsRemaining(
            shownAt: shownAt,
            now: now,
            minimumHold: customHold,
          ),
          15,
        );
      },
    );

    test('playing with balls shows live calling', () {
      final game = _playingGame();

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: false,
        canonicalRefetchInFlight: false,
        calledNumbers: [
          CalledNumberModel(
            id: 'cn-1',
            sessionId: 'session-auto-1',
            letter: 'B',
            number: 7,
            order: 1,
            createdAt: DateTime.now(),
          ),
        ],
        staleAfter: _testStaleAfter,
      );

      expect(phase, LivePresentationPhase.liveCalling);
    });

    test('winner window shows winner window phase not registration', () {
      final game = GameModel.fromOperationJson({
        'slotId': 'slot-auto-1',
        'sessionId': 'session-auto-1',
        'staticCode': 'FULL_HOUSE-S1',
        'playCode': 'BINGO-AUTO1',
        'playerStatus': 'winnerWindow',
        'rawStatus': 'WINNER_WINDOW',
        'operationMode': 'AUTO',
        'canRegister': true,
        'registrationOpen': true,
        'entryFee': '10',
        'prizePerCartela': '8',
        'prizeAmount': '16',
        'registeredCartelasCount': 2,
        'calledNumbersCount': 12,
        'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
      });

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: false,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: _testStaleAfter,
      );

      expect(phase, LivePresentationPhase.winnerWindow);
      expect(phase.isRegistrationLayout, isFalse);
    });

    test('expired winner window resolves to winnerWindowClosing phase', () {
      final game = GameModel.fromOperationJson({
        'slotId': 'slot-auto-1',
        'sessionId': 'session-auto-1',
        'staticCode': 'FULL_HOUSE-S1',
        'playCode': 'BINGO-AUTO1',
        'playerStatus': 'winnerWindow',
        'rawStatus': 'WINNER_WINDOW',
        'operationMode': 'AUTO',
        'canRegister': false,
        'registrationOpen': false,
        'entryFee': '10',
        'prizePerCartela': '8',
        'prizeAmount': '16',
        'registeredCartelasCount': 2,
        'calledNumbersCount': 12,
        'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
      });

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: false,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: _testStaleAfter,
        winnerWindowExpired: true,
      );

      expect(phase, LivePresentationPhase.winnerWindowClosing);
      expect(phase.keepsInlineCartelaLayout, isTrue);
      expect(phase.isWinnerWindowLayout, isTrue);
    });

    test('FINISHED never shows registration UI even with balls', () {
      final game = GameModel.fromOperationJson({
        'slotId': 'slot-auto-1',
        'sessionId': 'session-auto-1',
        'staticCode': 'FULL_HOUSE-S1',
        'playCode': 'BINGO-AUTO1',
        'playerStatus': 'finished',
        'rawStatus': 'FINISHED',
        'operationMode': 'AUTO',
        'canRegister': true,
        'registrationOpen': true,
        'entryFee': '10',
        'prizePerCartela': '8',
        'prizeAmount': '16',
        'registeredCartelasCount': 2,
        'calledNumbersCount': 12,
        'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
      });

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: false,
        canonicalRefetchInFlight: false,
        calledNumbers: [],
        staleAfter: _testStaleAfter,
      );

      expect(phase, LivePresentationPhase.review);
      expect(phase.isRegistrationLayout, isFalse);
    });

    test('NO_WINNER always resolves to review terminal UI', () {
      final game = GameModel.fromOperationJson({
        'slotId': 'slot-auto-1',
        'sessionId': 'session-auto-1',
        'staticCode': 'FULL_HOUSE-S1',
        'playCode': 'BINGO-AUTO1',
        'playerStatus': 'finished',
        'rawStatus': 'NO_WINNER',
        'operationMode': 'AUTO',
        'canRegister': false,
        'registrationOpen': false,
        'entryFee': '10',
        'prizePerCartela': '8',
        'prizeAmount': '0',
        'registeredCartelasCount': 2,
        'calledNumbersCount': 75,
        'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
      });

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: false,
        canonicalRefetchInFlight: false,
        calledNumbers: const [],
        staleAfter: _testStaleAfter,
      );

      expect(phase, LivePresentationPhase.review);
      expect(phase.isTerminalLayout, isTrue);
    });

    test('CANCELLED never shows registration UI even with balls', () {
      final game = GameModel.fromOperationJson({
        'slotId': 'slot-auto-1',
        'sessionId': 'session-auto-1',
        'staticCode': 'FULL_HOUSE-S1',
        'playCode': 'BINGO-AUTO1',
        'playerStatus': 'cancelled',
        'rawStatus': 'CANCELLED',
        'cancelledReason': 'other',
        'operationMode': 'AUTO',
        'canRegister': true,
        'registrationOpen': true,
        'entryFee': '10',
        'prizePerCartela': '8',
        'prizeAmount': '16',
        'registeredCartelasCount': 2,
        'calledNumbersCount': 5,
        'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
      });

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: false,
        canonicalRefetchInFlight: false,
        calledNumbers: [],
        staleAfter: _testStaleAfter,
      );

      expect(phase, LivePresentationPhase.cancelled);
      expect(phase.isRegistrationLayout, isFalse);
    });

    test('no players cancellation shows no players phase', () {
      final game = GameModel.fromOperationJson({
        'slotId': 'slot-auto-1',
        'sessionId': 'session-auto-1',
        'staticCode': 'FULL_HOUSE-S1',
        'playCode': 'BINGO-AUTO1',
        'playerStatus': 'cancelled',
        'rawStatus': 'CANCELLED',
        'cancelledReason': 'no_players',
        'operationMode': 'AUTO',
        'canRegister': false,
        'registrationOpen': false,
        'entryFee': '10',
        'prizePerCartela': '8',
        'prizeAmount': '0',
        'registeredCartelasCount': 0,
        'calledNumbersCount': 0,
        'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
      });

      final phase = LivePresentationPhaseResolver.resolve(
        game: game,
        registrationCountdownClosed: false,
        canonicalRefetchInFlight: false,
        calledNumbers: [],
        staleAfter: _testStaleAfter,
      );

      expect(phase, LivePresentationPhase.noPlayersJoined);
      expect(phase.isRegistrationLayout, isFalse);
    });
  });

  group('winnerWindowSecondsLeft', () {
    final now = DateTime(2026, 6, 15, 12, 0, 0);

    test('uses ceiling rounding so 1s remains until the deadline', () {
      expect(
        winnerWindowSecondsLeft(
          now.add(const Duration(milliseconds: 500)),
          now: now,
        ),
        1,
      );
    });

    test('returns 0 once the deadline has passed', () {
      expect(
        winnerWindowSecondsLeft(
          now.subtract(const Duration(milliseconds: 1)),
          now: now,
        ),
        0,
      );
    });

    test(
      'canClaimDuringWinnerWindow stays true while seconds left is positive',
      () {
        expect(
          canClaimDuringWinnerWindow(
            now.add(const Duration(milliseconds: 200)),
            now: now,
          ),
          isTrue,
        );
        expect(
          canClaimDuringWinnerWindow(
            now.subtract(const Duration(milliseconds: 1)),
            now: now,
          ),
          isFalse,
        );
      },
    );
  });

  group('isWinnerWindowExpired', () {
    final now = DateTime(2026, 6, 15, 12, 0, 0);

    test('returns false while window is still open', () {
      expect(
        isWinnerWindowExpired(
          status: GameStatus.winnerWindow,
          windowEndsAt: now.add(const Duration(seconds: 5)),
          now: now,
        ),
        isFalse,
      );
    });

    test('returns true when window deadline has passed', () {
      expect(
        isWinnerWindowExpired(
          status: GameStatus.winnerWindow,
          windowEndsAt: now.subtract(const Duration(seconds: 1)),
          now: now,
        ),
        isTrue,
      );
    });

    test('returns false for non-winner-window statuses', () {
      expect(
        isWinnerWindowExpired(
          status: GameStatus.playing,
          windowEndsAt: now.subtract(const Duration(seconds: 1)),
          now: now,
        ),
        isFalse,
      );
    });
  });

  group('isWinnerWindowActive', () {
    final now = DateTime(2026, 6, 15, 12, 0, 0);
    final windowEndsAt = now.add(const Duration(seconds: 25));

    test('true during the 25s winner window', () {
      expect(
        isWinnerWindowActive(
          status: GameStatus.winnerWindow,
          windowEndsAt: windowEndsAt,
          now: now,
        ),
        isTrue,
      );
      expect(winnerWindowSecondsLeft(windowEndsAt, now: now), 25);
    });

    test('false once the window deadline has passed', () {
      expect(
        isWinnerWindowActive(
          status: GameStatus.winnerWindow,
          windowEndsAt: windowEndsAt,
          now: windowEndsAt,
        ),
        isFalse,
      );
    });

    test('false when status is not winner window', () {
      expect(
        isWinnerWindowActive(
          status: GameStatus.finished,
          windowEndsAt: windowEndsAt,
          now: now,
        ),
        isFalse,
      );
    });
  });

  group('canShowPostGameSummary', () {
    final now = DateTime(2026, 6, 15, 12, 0, 0);
    final windowEndsAt = now.add(const Duration(seconds: 25));

    test('hidden during active winner window even if review flag is set', () {
      expect(
        canShowPostGameSummary(
          status: GameStatus.winnerWindow,
          windowEndsAt: windowEndsAt,
          postGameSummaryReviewActive: true,
          now: now,
        ),
        isFalse,
      );
    });

    test('hidden when winner window expired but game not finished yet', () {
      expect(
        canShowPostGameSummary(
          status: GameStatus.winnerWindow,
          windowEndsAt: windowEndsAt,
          postGameSummaryReviewActive: true,
          now: windowEndsAt,
        ),
        isFalse,
      );
    });

    test('hidden during winnerWindowClosing presentation phase', () {
      final game = GameModel.fromOperationJson({
        'slotId': 'slot-auto-1',
        'sessionId': 'session-auto-1',
        'staticCode': 'FULL_HOUSE-S1',
        'playCode': 'BINGO-AUTO1',
        'playerStatus': 'winnerWindow',
        'rawStatus': 'WINNER_WINDOW',
        'operationMode': 'AUTO',
        'canRegister': false,
        'registrationOpen': false,
        'entryFee': '10',
        'prizePerCartela': '8',
        'prizeAmount': '16',
        'registeredCartelasCount': 2,
        'calledNumbersCount': 12,
        'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
      });

      expect(
        LivePresentationPhaseResolver.resolve(
          game: game,
          registrationCountdownClosed: false,
          canonicalRefetchInFlight: false,
          calledNumbers: const [],
          staleAfter: _testStaleAfter,
          winnerWindowExpired: true,
        ),
        LivePresentationPhase.winnerWindowClosing,
      );
    });

    test('shown after FINISHED when review hold is active', () {
      expect(
        canShowPostGameSummary(
          status: GameStatus.finished,
          windowEndsAt: null,
          postGameSummaryReviewActive: true,
          now: now,
        ),
        isTrue,
      );
    });

    test('still shown while hold bypassed and advancing to next round', () {
      expect(
        canShowPostGameSummary(
          status: GameStatus.finished,
          windowEndsAt: null,
          postGameSummaryReviewActive: true,
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('countdown phase sequence', () {
    final finishedAt = DateTime(2026, 6, 15, 12, 0, 25);
    final windowEndsAt = finishedAt;
    final registrationDeadline = finishedAt.add(const Duration(seconds: 180));

    test(
      'phase 1 winner window then phase 2 summary then phase 3 registration',
      () {
        final phase1Now = finishedAt.subtract(const Duration(seconds: 10));
        expect(
          isWinnerWindowActive(
            status: GameStatus.winnerWindow,
            windowEndsAt: windowEndsAt,
            now: phase1Now,
          ),
          isTrue,
        );
        expect(
          canShowPostGameSummary(
            status: GameStatus.winnerWindow,
            windowEndsAt: windowEndsAt,
            postGameSummaryReviewActive: true,
            now: phase1Now,
          ),
          isFalse,
        );

        final phase2Start = finishedAt;
        expect(
          canShowPostGameSummary(
            status: GameStatus.finished,
            windowEndsAt: null,
            postGameSummaryReviewActive: true,
            now: phase2Start,
          ),
          isTrue,
        );
        expect(
          postGameSummarySecondsRemaining(
            shownAt: phase2Start,
            now: phase2Start,
          ),
          60,
        );

        final continueAt = phase2Start.add(const Duration(seconds: 30));
        expect(
          registrationCountdownSecondsRemaining(
            scheduledStartAt: registrationDeadline,
            now: continueAt,
          ),
          150,
        );

        final autoAdvanceAt = phase2Start.add(const Duration(seconds: 60));
        expect(
          postGameSummaryHoldElapsed(shownAt: phase2Start, now: autoAdvanceAt),
          isTrue,
        );
        expect(
          registrationCountdownSecondsRemaining(
            scheduledStartAt: registrationDeadline,
            now: autoAdvanceAt,
          ),
          120,
        );
      },
    );

    test(
      'registration countdown hidden while post-game summary hold is active',
      () {
        final game = _registrationGame(scheduledStartAt: registrationDeadline);

        expect(
          resolveRegistrationCountdownDeadline(
            game: game,
            timingConfigLoaded: true,
            isLoading: false,
            registrationCountdownClosed: false,
            canonicalRefetchInFlight: false,
            countdownSessionId: 'session-auto-1',
            sessionKey: 'session-auto-1',
            countdownDeadline: registrationDeadline,
            postGameSummaryHoldActive: true,
          ),
          isNull,
        );

        expect(
          resolveRegistrationCountdownDeadline(
            game: game,
            timingConfigLoaded: true,
            isLoading: false,
            registrationCountdownClosed: false,
            canonicalRefetchInFlight: false,
            countdownSessionId: 'session-auto-1',
            sessionKey: 'session-auto-1',
            countdownDeadline: registrationDeadline,
            postGameSummaryHoldActive: false,
          ),
          registrationDeadline,
        );
      },
    );
  });
}
