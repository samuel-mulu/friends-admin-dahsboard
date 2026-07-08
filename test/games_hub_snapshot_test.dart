import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/routing/auth_route_guard.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/games_hub_snapshot.dart';

void main() {
  final now = DateTime.utc(2026, 7, 1, 12);

  GameModel game({
    required String id,
    GameCategory category = GameCategory.normal,
    GameStatus status = GameStatus.playing,
    String? sessionId,
  }) {
    return GameModel(
      id: id,
      sessionId: sessionId ?? id,
      staticCode: 'CODE',
      playCode: '123',
      name: 'Game $id',
      gameRule: null,
      gameType: 'FULL_HOUSE',
      entryFee: '10',
      prizePerCartela: '8',
      companyFeePerCartela: '1',
      prizeAmount: '100',
      companyRevenue: '0',
      status: status,
      playOrder: 1,
      startedAt: now,
      finishedAt: null,
      createdAt: now,
      updatedAt: now,
      registeredCartelasCount: 1,
      calledNumbersCount: 0,
      registrationOpen: false,
      canRegister: false,
      category: category,
    );
  }

  test('hub snapshot picks normal live game over bonus live game', () {
    final operations = GameOperationsCurrentResponse(
      liveGame: game(id: 'bonus-live', category: GameCategory.bonus),
      checkingGame: null,
      registrationOpenGame: game(
        id: 'normal-reg',
        category: GameCategory.normal,
        status: GameStatus.ready,
      ),
      queue: const [],
      timestamp: now,
      serverNow: now,
    );

    final snapshot = GamesHubSnapshot.from(
      operations: operations,
      bigGame: null,
    );

    expect(snapshot.liveNow?.id, 'normal-reg');
    expect(snapshot.bonusGame?.id, 'bonus-live');
  });

  test('hub snapshot treats Big GOTD as the side-game slot', () {
    final operations = GameOperationsCurrentResponse(
      liveGame: game(id: 'gotd-live', category: GameCategory.bigGotd),
      checkingGame: null,
      registrationOpenGame: game(
        id: 'normal-reg',
        category: GameCategory.normal,
        status: GameStatus.ready,
      ),
      queue: const [],
      timestamp: now,
      serverNow: now,
    );

    final snapshot = GamesHubSnapshot.from(
      operations: operations,
      bigGame: null,
    );

    expect(snapshot.liveNow?.id, 'normal-reg');
    expect(snapshot.bonusGame?.id, 'gotd-live');
  });

  test('PLAYING game stays primary live section', () {
    final operations = GameOperationsCurrentResponse(
      liveGame: game(id: 'live-playing', status: GameStatus.playing),
      checkingGame: game(id: 'checking', status: GameStatus.checking),
      registrationOpenGame: game(
        id: 'ready-reg',
        status: GameStatus.ready,
        category: GameCategory.normal,
      ),
      queue: const [],
      timestamp: now,
      serverNow: now,
    );

    final snapshot = GamesHubSnapshot.from(
      operations: operations,
      bigGame: null,
    );
    expect(snapshot.liveNow?.id, 'live-playing');
  });

  test('READY registration game renders as liveNow, not queue item', () {
    final operations = GameOperationsCurrentResponse(
      liveGame: null,
      checkingGame: null,
      registrationOpenGame: game(
        id: 'ready-reg',
        status: GameStatus.ready,
        category: GameCategory.normal,
      ),
      queue: [
        game(id: 'queue-next-1', status: GameStatus.next),
        game(id: 'queue-next-2', status: GameStatus.next),
      ],
      timestamp: now,
      serverNow: now,
    );

    final snapshot = GamesHubSnapshot.from(
      operations: operations,
      bigGame: null,
    );
    expect(snapshot.liveNow?.id, 'ready-reg');
    expect(snapshot.comingNext?.id, 'queue-next-1');
  });

  test('Big Game is excluded from normal upcoming queue', () {
    final operations = GameOperationsCurrentResponse(
      liveGame: game(id: 'live', status: GameStatus.playing),
      checkingGame: null,
      registrationOpenGame: game(
        id: 'big-ready',
        status: GameStatus.ready,
        category: GameCategory.bigGame,
      ),
      queue: [
        game(
          id: 'big-next',
          status: GameStatus.next,
          category: GameCategory.bigGame,
        ),
        game(id: 'normal-next', status: GameStatus.next),
      ],
      timestamp: now,
      serverNow: now,
    );

    final snapshot = GamesHubSnapshot.from(
      operations: operations,
      bigGame: game(id: 'big-external', category: GameCategory.bigGame),
    );

    expect(snapshot.comingNext?.id, 'normal-next');
    expect(snapshot.bigGame?.isBigGame, isTrue);
  });

  test('queue order remains stable for upcoming selection', () {
    final operations = GameOperationsCurrentResponse(
      liveGame: game(id: 'live', status: GameStatus.playing),
      checkingGame: null,
      registrationOpenGame: null,
      queue: [
        game(id: 'queue-1', status: GameStatus.next),
        game(id: 'queue-2', status: GameStatus.next),
      ],
      timestamp: now,
      serverNow: now,
    );

    final snapshot = GamesHubSnapshot.from(
      operations: operations,
      bigGame: null,
    );
    expect(snapshot.comingNext?.id, 'queue-1');
  });

  test('guest live route is allowed', () {
    expect(kGuestLocations.contains('/games'), isTrue);
  });

  test('hub snapshot reads bigGameLiveElsewhere from operations', () {
    final operations = GameOperationsCurrentResponse(
      liveGame: game(id: 'live', status: GameStatus.playing),
      checkingGame: null,
      registrationOpenGame: null,
      queue: const [],
      timestamp: now,
      serverNow: now,
      bigGameLiveElsewhere: const BigGameLiveElsewhere(
        sessionId: 'big-session-1',
        phase: 'held',
      ),
    );

    final snapshot = GamesHubSnapshot.from(
      operations: operations,
      bigGame: game(
        id: 'big-external',
        category: GameCategory.bigGame,
        status: GameStatus.ready,
      ),
    );

    expect(operations.bigGameLiveElsewhere?.sessionId, 'big-session-1');
    expect(operations.bigGameLiveElsewhere?.isHeld, isTrue);
    expect(snapshot.bigGame?.isBigGame, isTrue);
  });
}
