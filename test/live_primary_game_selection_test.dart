import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_primary_game_selection.dart';

void main() {
  group('resolvePrimaryGameForOperations', () {
    test(
      'operations has PLAYING live + READY registration + owned live cartelas -> primary stays PLAYING',
      () {
        final operations = _operations(
          liveGame: _game(
            id: 'live-slot',
            sessionId: 'live-session',
            status: GameStatus.playing,
            canRegister: false,
          ),
          registrationGame: _game(
            id: 'ready-slot',
            sessionId: 'ready-session',
            status: GameStatus.ready,
            canRegister: true,
          ),
        );

        final primary = resolvePrimaryGameForOperations(
          operations: operations,
          ownsLiveCartelas: true,
        );

        expect(primary?.sessionId, equals('live-session'));
        expect(primary?.status, equals(GameStatus.playing));
      },
    );

    test(
      'operations has PLAYING live + READY registration + no live cartelas -> registration can become primary',
      () {
        final operations = _operations(
          liveGame: _game(
            id: 'live-slot',
            sessionId: 'live-session',
            status: GameStatus.playing,
            canRegister: false,
          ),
          registrationGame: _game(
            id: 'ready-slot',
            sessionId: 'ready-session',
            status: GameStatus.ready,
            canRegister: true,
          ),
        );

        final primary = resolvePrimaryGameForOperations(
          operations: operations,
          ownsLiveCartelas: false,
        );

        expect(primary?.sessionId, equals('ready-session'));
        expect(primary?.status, equals(GameStatus.ready));
      },
    );

    test('after live FINISHED -> registration can become primary', () {
      final operations = _operations(
        liveGame: _game(
          id: 'live-slot',
          sessionId: 'live-session',
          status: GameStatus.finished,
          canRegister: false,
        ),
        registrationGame: _game(
          id: 'ready-slot',
          sessionId: 'ready-session',
          status: GameStatus.ready,
          canRegister: true,
        ),
      );

      final primary = resolvePrimaryGameForOperations(
        operations: operations,
        ownsLiveCartelas: true,
      );

      expect(primary?.sessionId, equals('ready-session'));
      expect(primary?.status, equals(GameStatus.ready));
    });

    test(
      'reconnect during PLAYING with owned cartelas does not jump to READY',
      () {
        final operations = _operations(
          liveGame: _game(
            id: 'live-slot',
            sessionId: 'live-session',
            status: GameStatus.playing,
            canRegister: false,
          ),
          registrationGame: _game(
            id: 'ready-slot',
            sessionId: 'ready-session',
            status: GameStatus.ready,
            canRegister: true,
          ),
        );

        final primary = resolvePrimaryGameForOperations(
          operations: operations,
          ownsLiveCartelas: true,
        );

        expect(primary?.sessionId, isNot('ready-session'));
        expect(primary?.status, equals(GameStatus.playing));
      },
    );

    test(
      'socket/status refresh cannot move owned player from PLAYING to READY',
      () {
        final operations = _operations(
          liveGame: _game(
            id: 'live-slot',
            sessionId: 'live-session',
            status: GameStatus.playing,
            canRegister: false,
          ),
          registrationGame: _game(
            id: 'ready-slot',
            sessionId: 'ready-session',
            status: GameStatus.ready,
            canRegister: true,
          ),
        );

        final primary = resolvePrimaryGameForOperations(
          operations: operations,
          ownsLiveCartelas: true,
        );

        expect(primary?.sessionId, equals('live-session'));
        expect(primary?.status, isNot(GameStatus.ready));
      },
    );
  });
}

GameOperationsCurrentResponse _operations({
  GameModel? liveGame,
  GameModel? checkingGame,
  GameModel? registrationGame,
}) {
  final now = DateTime.utc(2026, 6, 29);
  return GameOperationsCurrentResponse(
    liveGame: liveGame,
    checkingGame: checkingGame,
    registrationOpenGame: registrationGame,
    queue: const [],
    timestamp: now,
    serverNow: now,
  );
}

GameModel _game({
  required String id,
  required String sessionId,
  required GameStatus status,
  required bool canRegister,
}) {
  final now = DateTime.utc(2026, 6, 29);
  return GameModel(
    id: id,
    sessionId: sessionId,
    staticCode: id,
    playCode: sessionId,
    name: 'Game $id',
    gameRule: null,
    gameType: 'FULL_HOUSE',
    entryFee: '10.00',
    prizePerCartela: '50.00',
    companyFeePerCartela: '1.00',
    prizeAmount: '200.00',
    companyRevenue: '20.00',
    status: status,
    playOrder: 1,
    startedAt: now,
    finishedAt: status == GameStatus.finished ? now : null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 0,
    calledNumbersCount: status == GameStatus.playing ? 3 : 0,
    registrationOpen: canRegister,
    canRegister: canRegister,
  );
}
