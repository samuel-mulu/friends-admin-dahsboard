import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_resume_provider_policy.dart';

GameModel _game({
  required GameStatus status,
  bool registrationOpen = false,
  bool canRegister = false,
  String sessionId = 'session-1',
}) {
  final now = DateTime.utc(2026, 6, 30);
  return GameModel(
    id: 'game-1',
    sessionId: sessionId,
    staticCode: 'ABC',
    playCode: '111',
    name: 'Live game',
    gameRule: null,
    gameType: 'ONE_ROW',
    entryFee: '10.00',
    prizePerCartela: '20.00',
    companyFeePerCartela: '1.00',
    prizeAmount: '200.00',
    companyRevenue: '20.00',
    status: status,
    playOrder: 1,
    startedAt: now,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 1,
    calledNumbersCount: 0,
    registrationOpen: registrationOpen,
    canRegister: canRegister,
    nextAutoCallAt: null,
    operationMode: 'AUTO',
  );
}

GameOperationsCurrentResponse _operations({GameModel? registrationOpenGame}) {
  final now = DateTime.utc(2026, 6, 30);
  return GameOperationsCurrentResponse(
    serverNow: now,
    timestamp: now,
    queue: const [],
    liveGame: null,
    checkingGame: null,
    registrationOpenGame: registrationOpenGame,
  );
}

void main() {
  group('shouldInvalidateWalletOnResume', () {
    test('skips during live play', () {
      expect(
        shouldInvalidateWalletOnResume(
          game: _game(status: GameStatus.playing),
          operations: _operations(),
        ),
        isFalse,
      );
    });

    test('invalidates when current game registration is open', () {
      expect(
        shouldInvalidateWalletOnResume(
          game: _game(
            status: GameStatus.ready,
            registrationOpen: true,
            canRegister: true,
          ),
          operations: _operations(),
        ),
        isTrue,
      );
    });

    test('invalidates when operations expose open registration game', () {
      expect(
        shouldInvalidateWalletOnResume(
          game: _game(status: GameStatus.playing),
          operations: _operations(
            registrationOpenGame: _game(
              status: GameStatus.ready,
              registrationOpen: true,
              canRegister: true,
              sessionId: 'session-2',
            ),
          ),
        ),
        isTrue,
      );
    });
  });

  group('shouldInvalidateRegistrationStateOnResume', () {
    test('skips current session during live play', () {
      expect(
        shouldInvalidateRegistrationStateOnResume(
          sessionId: 'session-1',
          primaryGame: _game(status: GameStatus.playing),
        ),
        isFalse,
      );
    });

    test('keeps current session when registration is open', () {
      expect(
        shouldInvalidateRegistrationStateOnResume(
          sessionId: 'session-1',
          primaryGame: _game(
            status: GameStatus.ready,
            registrationOpen: true,
          ),
        ),
        isTrue,
      );
    });

    test('keeps tracked next-session invalidation', () {
      expect(
        shouldInvalidateRegistrationStateOnResume(
          sessionId: 'session-2',
          primaryGame: _game(status: GameStatus.playing, sessionId: 'session-1'),
        ),
        isTrue,
      );
    });
  });
}
