import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/game_operations_resume_cache.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_resume_conditional_fetch.dart';

GameModel _game({
  required GameStatus status,
  int calledNumbersCount = 0,
  String sessionId = 'session-1',
  bool registrationOpen = false,
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
    finishedAt: status == GameStatus.finished ? now : null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 1,
    calledNumbersCount: calledNumbersCount,
    registrationOpen: registrationOpen,
    canRegister: registrationOpen,
    nextAutoCallAt: null,
    operationMode: 'AUTO',
  );
}

GameOperationsCurrentResponse _operations() {
  final now = DateTime.utc(2026, 6, 30);
  return GameOperationsCurrentResponse(
    serverNow: now,
    timestamp: now,
    queue: const [],
    liveGame: null,
    checkingGame: null,
    registrationOpenGame: null,
  );
}

CalledNumberModel _called(int order, {String letter = 'B', int number = 0}) {
  final resolvedNumber = number == 0 ? 6 + order : number;
  return CalledNumberModel(
    id: 'cn-$order',
    sessionId: 'session-1',
    letter: letter,
    number: resolvedNumber,
    order: order,
    createdAt: DateTime.utc(2026, 6, 30),
  );
}

GameModel _gameWithLatestBall({
  required GameStatus status,
  required int calledNumbersCount,
  required String letter,
  required int number,
  String sessionId = 'session-1',
  bool registrationOpen = false,
}) {
  return GameModel.fromOperationJson({
    'slotId': 'slot-1',
    'sessionId': sessionId,
    'staticCode': 'ABC',
    'playCode': '111',
    'playerStatus': status == GameStatus.playing ? 'playing' : 'ready',
    'rawStatus': status.name.toUpperCase(),
    'operationMode': 'AUTO',
    'canRegister': registrationOpen,
    'registrationOpen': registrationOpen,
    'entryFee': '10',
    'prizePerCartela': '8',
    'prizeAmount': '200',
    'registeredCartelasCount': 1,
    'calledNumbersCount': calledNumbersCount,
    'latestCalledNumber': {
      'order': calledNumbersCount,
      'letter': letter,
      'number': number,
    },
    'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
  });
}

void main() {
  tearDown(GameOperationsResumeCache.shared.resetForTest);

  group('resolveResumeCalledNumbersFetch', () {
    test('same session + same called count skips called-number fetch', () {
      final game = _game(status: GameStatus.playing, calledNumbersCount: 5);
      final local = List.generate(5, (index) => _called(index + 1));

      final decision = resolveResumeCalledNumbersFetch(
        game: game,
        priorSessionId: 'session-1',
        localCalledNumbers: local,
        reconnectGapDetected: false,
      );

      expect(decision.shouldFetch, isFalse);
      expect(decision.reason, 'same_count');
    });

    test('backend count higher fetches called numbers', () {
      final game = _game(status: GameStatus.playing, calledNumbersCount: 8);
      final local = List.generate(5, (index) => _called(index + 1));

      final decision = resolveResumeCalledNumbersFetch(
        game: game,
        priorSessionId: 'session-1',
        localCalledNumbers: local,
        reconnectGapDetected: false,
      );

      expect(decision.shouldFetch, isTrue);
      expect(decision.reason, 'backend_ahead');
    });

    test('session changed fetches called numbers', () {
      final game = _game(
        status: GameStatus.playing,
        calledNumbersCount: 5,
        sessionId: 'session-2',
      );

      final decision = resolveResumeCalledNumbersFetch(
        game: game,
        priorSessionId: 'session-1',
        localCalledNumbers: List.generate(5, (index) => _called(index + 1)),
        reconnectGapDetected: false,
      );

      expect(decision.shouldFetch, isTrue);
      expect(decision.reason, 'session_changed');
    });

    test('reconnect gap fetches called numbers', () {
      final game = _game(status: GameStatus.playing, calledNumbersCount: 5);

      final decision = resolveResumeCalledNumbersFetch(
        game: game,
        priorSessionId: 'session-1',
        localCalledNumbers: List.generate(5, (index) => _called(index + 1)),
        reconnectGapDetected: true,
      );

      expect(decision.shouldFetch, isTrue);
      expect(decision.reason, 'reconnect_gap');
    });

    test('same count and order but different last ball identity fetches', () {
      final game = _gameWithLatestBall(
        status: GameStatus.playing,
        calledNumbersCount: 5,
        letter: 'I',
        number: 22,
      );
      final local = [
        for (var index = 1; index < 5; index++) _called(index),
        _called(5, letter: 'B', number: 11),
      ];

      final decision = resolveResumeCalledNumbersFetch(
        game: game,
        priorSessionId: 'session-1',
        localCalledNumbers: local,
        reconnectGapDetected: false,
      );

      expect(decision.shouldFetch, isTrue);
      expect(decision.reason, 'strip_mismatch');
    });
  });

  group('resolveResumeMyCartelasFetch', () {
    test('playing + local myCartelas loaded skips my-cartelas', () {
      final decision = resolveResumeMyCartelasFetch(
        game: _game(status: GameStatus.playing),
        priorSessionId: 'session-1',
        localMyCartelasCount: 3,
        sessionChanged: false,
      );

      expect(decision.shouldFetch, isFalse);
      expect(decision.reason, 'same_session_loaded');
    });

    test('playing + local myCartelas empty fetches my-cartelas', () {
      final decision = resolveResumeMyCartelasFetch(
        game: _game(status: GameStatus.playing),
        priorSessionId: 'session-1',
        localMyCartelasCount: 0,
        sessionChanged: false,
      );

      expect(decision.shouldFetch, isTrue);
      expect(decision.reason, 'playing_empty');
    });

    test('ready registration fetches my-cartelas', () {
      final decision = resolveResumeMyCartelasFetch(
        game: _game(status: GameStatus.ready, registrationOpen: true),
        priorSessionId: 'session-1',
        localMyCartelasCount: 2,
        sessionChanged: false,
      );

      expect(decision.shouldFetch, isTrue);
      expect(decision.reason, 'ready_registration');
    });
  });

  group('GameOperationsResumeCache', () {
    test('operations/current cache hit avoids second fetch', () {
      final cache = GameOperationsResumeCache.shared;
      final now = DateTime.utc(2026, 7, 2, 12);

      cache.put(_operations(), capturedAt: now);

      expect(cache.getIfFresh(now: now.add(const Duration(seconds: 1))), isNotNull);
    });

    test('cache expires after TTL', () {
      final cache = GameOperationsResumeCache.shared;
      final now = DateTime.utc(2026, 7, 2, 12);

      cache.put(_operations(), capturedAt: now);

      expect(
        cache.getIfFresh(now: now.add(const Duration(seconds: 3))),
        isNull,
      );
    });
  });
}
