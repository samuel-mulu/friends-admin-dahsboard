import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_presentation_phase.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_ready_transition_lock.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_ui_mode.dart';

void main() {
  final now = DateTime.utc(2026, 6, 29, 12, 0, 0);
  const staleAfter = Duration(seconds: 45);

  group('resolveLiveUiMode', () {
    test('1. READY only -> registrationCountdown', () {
      final ready = _readyGame(
        scheduledStartAt: now.add(const Duration(minutes: 1)),
      );
      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: _operations(registrationGame: ready),
          ownsLiveSessionCartelas: false,
          hasPrimarySessionCartelas: false,
          now: now,
          preparingStaleAfter: staleAfter,
        ),
      );

      expect(state.mode, LiveUiMode.registrationCountdown);
      expect(state.primaryGame?.status, GameStatus.ready);
      expect(state.useRegistrationOpenLayout, isTrue);
      expect(state.showRegistrationGrid, isTrue);
      expect(state.countdownKind, LiveUiCountdownKind.registration);
      expect(state.hideRegistrationCountdown, isFalse);
    });

    test('2. PLAYING only + owns cartelas -> liveOwned', () {
      final playing = _playingGame();
      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: _operations(liveGame: playing),
          ownsLiveSessionCartelas: true,
          hasPrimarySessionCartelas: true,
          now: now,
          preparingStaleAfter: staleAfter,
        ),
      );

      expect(state.mode, LiveUiMode.liveOwned);
      expect(state.showsInlinePlayCartelas, isTrue);
      expect(state.showCalledNumbersStrip, isTrue);
      expect(state.useRegistrationOpenLayout, isFalse);
    });

    test('3. PLAYING only + no cartelas -> liveSpectator', () {
      final playing = _playingGame();
      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: _operations(liveGame: playing),
          ownsLiveSessionCartelas: false,
          hasPrimarySessionCartelas: false,
          now: now,
          preparingStaleAfter: staleAfter,
        ),
      );

      expect(state.mode, LiveUiMode.liveSpectator);
      expect(state.showCalledNumbersStrip, isTrue);
      expect(state.showRegistrationGrid, isFalse);
      expect(state.useRegistrationOpenLayout, isFalse);
    });

    test(
      '4. PLAYING + READY + owns cartelas -> liveOwned with secondary registration',
      () {
        final playing = _playingGame(sessionId: 'live-session');
        final ready = _readyGame(sessionId: 'ready-session');
        final state = resolveLiveUiMode(
          ResolveLiveUiModeInput(
            operations: _operations(liveGame: playing, registrationGame: ready),
            ownsLiveSessionCartelas: true,
            hasPrimarySessionCartelas: true,
            now: now,
            preparingStaleAfter: staleAfter,
          ),
        );

        expect(state.mode, LiveUiMode.liveOwned);
        expect(state.primaryGame?.sessionId, 'live-session');
        expect(state.secondaryRegistrationGame?.sessionId, 'ready-session');
        expect(state.hideRegistrationCountdown, isTrue);
        expect(state.helperKey, isNot(LiveUiHelperKey.liveMissedRound));
        expect(state.useRegistrationOpenLayout, isFalse);
      },
    );

    test('5. PLAYING + READY + no cartelas -> missedRoundRegistration', () {
      final playing = _playingGame(sessionId: 'live-session');
      final ready = _readyGame(sessionId: 'ready-session');
      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: _operations(liveGame: playing, registrationGame: ready),
          ownsLiveSessionCartelas: false,
          hasPrimarySessionCartelas: false,
          now: now,
          preparingStaleAfter: staleAfter,
        ),
      );

      expect(state.mode, LiveUiMode.missedRoundRegistration);
      expect(state.primaryGame?.sessionId, 'ready-session');
      expect(state.secondaryRegistrationGame, isNull);
      expect(state.helperKey, LiveUiHelperKey.liveMissedRound);
      expect(state.hideRegistrationCountdown, isTrue);
      expect(state.useRegistrationOpenLayout, isTrue);
      expect(state.showsInlinePlayCartelas, isFalse);
    });

    test('6. CHECKING + READY -> checking', () {
      final checking = _game(
        sessionId: 'checking-session',
        status: GameStatus.checking,
      );
      final ready = _readyGame(sessionId: 'ready-session');
      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: _operations(
            checkingGame: checking,
            registrationGame: ready,
          ),
          ownsLiveSessionCartelas: true,
          hasPrimarySessionCartelas: true,
          now: now,
          preparingStaleAfter: staleAfter,
        ),
      );

      expect(state.mode, LiveUiMode.checking);
      expect(state.presentationPhase, LivePresentationPhase.checking);
    });

    test('7. WINNER_WINDOW + READY -> winnerWindow', () {
      final winnerWindow = _game(
        sessionId: 'ww-session',
        status: GameStatus.winnerWindow,
      );
      final ready = _readyGame(sessionId: 'ready-session');
      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: _operations(
            liveGame: winnerWindow,
            registrationGame: ready,
          ),
          ownsLiveSessionCartelas: true,
          hasPrimarySessionCartelas: true,
          now: now,
          preparingStaleAfter: staleAfter,
        ),
      );

      expect(state.mode, LiveUiMode.winnerWindow);
      expect(state.countdownKind, LiveUiCountdownKind.winnerWindow);
    });

    test('8. FINISHED + READY + review hold -> reviewFinished', () {
      final finished = _game(
        sessionId: 'finished-session',
        status: GameStatus.finished,
      );
      final ready = _readyGame(sessionId: 'ready-session');
      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: _operations(registrationGame: ready),
          pinnedPrimaryGame: finished,
          ownsLiveSessionCartelas: true,
          hasPrimarySessionCartelas: true,
          holds: const LiveSessionHolds(
            postGameSummaryReviewActive: true,
            pinTerminalSession: true,
          ),
          now: now,
          preparingStaleAfter: staleAfter,
        ),
      );

      expect(state.mode, LiveUiMode.reviewFinished);
      expect(state.showReview, isTrue);
      expect(state.useRegistrationOpenLayout, isFalse);
      expect(state.blocksRegistrationPromotion, isTrue);
    });

    test('9. NO_WINNER + READY + review hold -> reviewNoWinner', () {
      final noWinner = _game(
        sessionId: 'nw-session',
        status: GameStatus.noWinner,
      );
      final ready = _readyGame(sessionId: 'ready-session');
      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: _operations(registrationGame: ready),
          pinnedPrimaryGame: noWinner,
          ownsLiveSessionCartelas: false,
          hasPrimarySessionCartelas: false,
          holds: const LiveSessionHolds(
            postGameSummaryReviewActive: true,
            pinTerminalSession: true,
          ),
          now: now,
          preparingStaleAfter: staleAfter,
        ),
      );

      expect(state.mode, LiveUiMode.reviewNoWinner);
      expect(state.showReview, isTrue);
      expect(state.blocksRegistrationPromotion, isTrue);
    });

    test('10. terminal review blocks registration takeover', () {
      final finished = _game(
        sessionId: 'finished-session',
        status: GameStatus.finished,
      );
      final ready = _readyGame(sessionId: 'ready-session');
      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: _operations(registrationGame: ready),
          pinnedPrimaryGame: finished,
          ownsLiveSessionCartelas: false,
          hasPrimarySessionCartelas: false,
          holds: const LiveSessionHolds(
            postGameSummaryReviewActive: true,
            pinTerminalSession: true,
          ),
          now: now,
          preparingStaleAfter: staleAfter,
        ),
      );

      expect(state.registrationOpenBodyTarget, isNull);
      expect(state.useRegistrationOpenLayout, isFalse);
      expect(state.blocksRegistrationPromotion, isTrue);
    });

    test('11. NEXT queue item never becomes registration mode', () {
      final nextOnly = _nextQueueGame();
      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: GameOperationsCurrentResponse(
            liveGame: null,
            checkingGame: null,
            registrationOpenGame: null,
            queue: [nextOnly],
            timestamp: now,
            serverNow: now,
          ),
          ownsLiveSessionCartelas: false,
          hasPrimarySessionCartelas: false,
          now: now,
          preparingStaleAfter: staleAfter,
        ),
      );

      expect(state.mode, LiveUiMode.empty);
      expect(state.useRegistrationOpenLayout, isFalse);
    });
  });

  group('registration handoff regression', () {
    ReadyTransitionLock handoffLock(GameModel game) {
      return startReadyTransitionLock(
        game: game,
        reason: ReadyTransitionReason.noPlayersHandoff,
        startedAt: now,
      );
    }

    test('new READY registrationOpenGame beats active handoff lock', () {
      final ready = _readyGame(
        sessionId: 'ready-session',
        scheduledStartAt: now.add(const Duration(seconds: 108)),
      );
      final closed = _readyGame(
        sessionId: 'closed-session',
      ).copyWith(canRegister: false);
      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: _operations(registrationGame: ready),
          ownsLiveSessionCartelas: false,
          hasPrimarySessionCartelas: false,
          holds: LiveSessionHolds(readyTransitionLock: handoffLock(closed)),
          now: now,
          preparingStaleAfter: staleAfter,
        ),
      );

      expect(state.mode, LiveUiMode.registrationCountdown);
      expect(state.primaryGame?.sessionId, 'ready-session');
      expect(state.hideRegistrationCountdown, isFalse);
      expect(state.countdownKind, LiveUiCountdownKind.registration);
      expect(
        state.helperKey,
        isNot(LiveUiHelperKey.postGameSummaryOpeningNext),
      );
    });

    test(
      'same session reopened with future scheduledStartAt beats handoff',
      () {
        final reopened = _readyGame(
          sessionId: 'closed-session',
          scheduledStartAt: now.add(const Duration(seconds: 108)),
        );
        final state = resolveLiveUiMode(
          ResolveLiveUiModeInput(
            operations: _operations(registrationGame: reopened),
            ownsLiveSessionCartelas: false,
            hasPrimarySessionCartelas: false,
            holds: LiveSessionHolds(
              readyTransitionLock: handoffLock(reopened),
              registrationCountdownClosed: true,
            ),
            now: now,
            preparingStaleAfter: staleAfter,
          ),
        );

        expect(state.mode, LiveUiMode.registrationCountdown);
        expect(state.presentationPhase, LivePresentationPhase.registrationOpen);
        expect(state.hideRegistrationCountdown, isFalse);
      },
    );

    test('no registrationOpenGame keeps handoffOpeningNext', () {
      final staleReady = _readyGame(sessionId: 'closed-session').copyWith(
        canRegister: false,
        scheduledStartAt: now.subtract(const Duration(seconds: 2)),
      );
      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: null,
          ownsLiveSessionCartelas: false,
          hasPrimarySessionCartelas: false,
          holds: LiveSessionHolds(
            readyTransitionLock: handoffLock(staleReady),
            registrationCountdownClosed: true,
          ),
          now: now,
          preparingStaleAfter: staleAfter,
        ),
      );

      expect(state.mode, LiveUiMode.handoffOpeningNext);
      expect(state.helperKey, LiveUiHelperKey.postGameSummaryOpeningNext);
    });

    test('handoff lock timeout allows empty state', () {
      final staleReady = _readyGame(
        sessionId: 'closed-session',
      ).copyWith(canRegister: false);
      final expiredLock = startReadyTransitionLock(
        game: staleReady,
        reason: ReadyTransitionReason.noPlayersHandoff,
        startedAt: now.subtract(kReadyTransitionLockTimeout),
      );
      final state = resolveLiveUiMode(
        ResolveLiveUiModeInput(
          operations: null,
          ownsLiveSessionCartelas: false,
          hasPrimarySessionCartelas: false,
          holds: LiveSessionHolds(readyTransitionLock: expiredLock),
          now: now,
          preparingStaleAfter: staleAfter,
        ),
      );

      expect(state.mode, LiveUiMode.empty);
    });
  });
}

GameOperationsCurrentResponse _operations({
  GameModel? liveGame,
  GameModel? checkingGame,
  GameModel? registrationGame,
  List<GameModel> queue = const [],
}) {
  final now = DateTime.utc(2026, 6, 29);
  return GameOperationsCurrentResponse(
    liveGame: liveGame,
    checkingGame: checkingGame,
    registrationOpenGame: registrationGame,
    queue: queue,
    timestamp: now,
    serverNow: now,
  );
}

GameModel _game({
  required String sessionId,
  required GameStatus status,
  String? cancelledReason,
}) {
  final now = DateTime.utc(2026, 6, 29);
  return GameModel(
    id: 'slot-$sessionId',
    sessionId: sessionId,
    staticCode: 'CODE',
    playCode: sessionId,
    name: 'Game',
    gameRule: null,
    gameType: 'FULL_HOUSE',
    entryFee: '10',
    prizePerCartela: '8',
    companyFeePerCartela: '1',
    prizeAmount: '0',
    companyRevenue: '0',
    status: status,
    playOrder: 1,
    startedAt: now,
    finishedAt: status == GameStatus.finished ? now : null,
    cancelledReason: cancelledReason,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 0,
    calledNumbersCount: 0,
    registrationOpen: status == GameStatus.ready,
    canRegister: status == GameStatus.ready,
  );
}

GameModel _readyGame({
  String sessionId = 'ready-session',
  DateTime? scheduledStartAt,
}) {
  return _game(sessionId: sessionId, status: GameStatus.ready).copyWith(
    scheduledStartAt: scheduledStartAt,
    canRegister: true,
    registrationOpen: true,
  );
}

GameModel _playingGame({String sessionId = 'live-session'}) {
  return _game(sessionId: sessionId, status: GameStatus.playing).copyWith(
    canRegister: false,
    registrationOpen: false,
    calledNumbersCount: 2,
  );
}

GameModel _nextQueueGame() {
  final now = DateTime.utc(2026, 6, 29);
  return GameModel(
    id: 'slot-next',
    sessionId: null,
    staticCode: 'NEXT',
    playCode: null,
    name: 'Queue',
    gameRule: null,
    gameType: 'FULL_HOUSE',
    entryFee: '10',
    prizePerCartela: '8',
    companyFeePerCartela: '1',
    prizeAmount: '0',
    companyRevenue: '0',
    status: GameStatus.next,
    playOrder: 2,
    startedAt: null,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 0,
    calledNumbersCount: 0,
    registrationOpen: false,
    canRegister: false,
  );
}
