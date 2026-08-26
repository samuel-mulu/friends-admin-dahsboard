import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/network/api_client.dart';
import 'package:friends_bingo_app/src/features/games/data/games_repository.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_game_host.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_registration_controller.dart';

void main() {
  group('LiveRegistrationController current-session snapshot guard', () {
    testWidgets(
      'rejects stale same-session snapshot after confirmed registration bump',
      (tester) async {
        final repository = _FakeGamesRepository();
        final host = _FakeLiveGameHost(
          gamesRepository: repository,
          game: _game(sessionId: 'session-a', status: GameStatus.ready),
        );
        final controller = LiveRegistrationController(host)
          ..resetCurrentCartelaSession('session-a')
          ..myCartelas = _cartelas('session-a', [1, 2, 3, 4, 5, 6]);

        final staleResponse = Completer<List<GameCartelaModel>>();
        repository.onGetMyGameCartelas = (_) => staleResponse.future;

        unawaited(controller.refreshMyCartelasSilently());
        await tester.pump(const Duration(milliseconds: 400));

        controller.myCartelas = _cartelas('session-a', [
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
          11,
          12,
        ]);
        controller.noteConfirmedCurrentSessionRegistrationMutation('session-a');
        staleResponse.complete(_cartelas('session-a', [1, 2, 3, 4, 5, 6]));

        await tester.pump();

        expect(_numbers(controller.myCartelas), <int>[
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
          11,
          12,
        ]);
      },
    );

    testWidgets(
      'accepts newer same-revision remote snapshot reduction without registration bump',
      (tester) async {
        final repository = _FakeGamesRepository();
        final host = _FakeLiveGameHost(
          gamesRepository: repository,
          game: _game(sessionId: 'session-a', status: GameStatus.playing),
        );
        final controller = LiveRegistrationController(host)
          ..resetCurrentCartelaSession('session-a')
          ..myCartelas = _cartelas('session-a', [
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11,
            12,
          ]);

        final firstResponse = Completer<List<GameCartelaModel>>();
        final secondResponse = Completer<List<GameCartelaModel>>();
        var fetchCount = 0;
        repository.onGetMyGameCartelas = (_) {
          fetchCount += 1;
          return fetchCount == 1 ? firstResponse.future : secondResponse.future;
        };

        unawaited(controller.refreshMyCartelasSilently());
        await tester.pump(const Duration(milliseconds: 400));

        unawaited(controller.refreshMyCartelasSilently());
        await tester.pump(const Duration(milliseconds: 400));

        secondResponse.complete(
          _cartelas('session-a', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
        );
        await tester.pump();

        firstResponse.complete(
          _cartelas('session-a', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]),
        );
        await tester.pump();

        expect(_numbers(controller.myCartelas), <int>[
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
        ]);
      },
    );

    testWidgets('ignores prior-session snapshot after switching sessions', (
      tester,
    ) async {
      final repository = _FakeGamesRepository();
      final host = _FakeLiveGameHost(
        gamesRepository: repository,
        game: _game(sessionId: 'session-a', status: GameStatus.ready),
      );
      final controller = LiveRegistrationController(host)
        ..resetCurrentCartelaSession('session-a')
        ..myCartelas = _cartelas('session-a', [1, 2, 3, 4, 5, 6]);

      final sessionAResponse = Completer<List<GameCartelaModel>>();
      repository.onGetMyGameCartelas = (_) => sessionAResponse.future;

      unawaited(controller.refreshMyCartelasSilently());
      await tester.pump(const Duration(milliseconds: 400));

      host.game = _game(sessionId: 'session-b', status: GameStatus.ready);
      controller.resetCurrentCartelaSession('session-b');
      controller.myCartelas = _cartelas('session-b', [21, 22, 23]);
      sessionAResponse.complete(_cartelas('session-a', [1, 2, 3, 4, 5, 6]));

      await tester.pump();

      expect(_numbers(controller.myCartelas), <int>[21, 22, 23]);
    });

    testWidgets(
      'CS-11 READY to PLAYING stale snapshot cannot roll cartelas backward',
      (tester) async {
        final repository = _FakeGamesRepository();
        final host = _FakeLiveGameHost(
          gamesRepository: repository,
          game: _game(sessionId: 'session-a', status: GameStatus.ready),
        );
        final controller = LiveRegistrationController(host)
          ..resetCurrentCartelaSession('session-a')
          ..myCartelas = _cartelas('session-a', [1, 2, 3, 4, 5, 6]);

        final readyResponse = Completer<List<GameCartelaModel>>();
        repository.onGetMyGameCartelas = (_) => readyResponse.future;

        unawaited(controller.refreshMyCartelasSilently());
        await tester.pump(const Duration(milliseconds: 400));

        host.game = _game(sessionId: 'session-a', status: GameStatus.playing);
        controller.applyMyCartelasOptimisticMerge(
          sessionId: 'session-a',
          incoming: _cartelas('session-a', [7, 8, 9, 10, 11, 12]),
        );
        controller.noteConfirmedCurrentSessionRegistrationMutation('session-a');
        readyResponse.complete(_cartelas('session-a', [1, 2, 3, 4, 5, 6]));

        await tester.pump();

        expect(_numbers(controller.myCartelas), <int>[
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
          11,
          12,
        ]);
      },
    );
  });
}

class _FakeGamesRepository extends GamesRepository {
  _FakeGamesRepository() : super(ApiClient(Dio()));

  Future<List<GameCartelaModel>> Function(String sessionId)?
  onGetMyGameCartelas;

  @override
  Future<List<GameCartelaModel>> getMyGameCartelas(String sessionId) {
    final callback = onGetMyGameCartelas;
    if (callback != null) {
      return callback(sessionId);
    }
    return Future<List<GameCartelaModel>>.value(const <GameCartelaModel>[]);
  }
}

class _FakeLiveGameHost extends Fake implements LiveGameHost {
  _FakeLiveGameHost({required this.gamesRepository, required GameModel game})
    : _game = game;

  @override
  bool mounted = true;

  @override
  bool isLiveHostActive = true;

  @override
  bool isGuest = false;

  @override
  final GamesRepository gamesRepository;

  GameModel? _game;

  @override
  GameModel? get game => _game;

  @override
  set game(GameModel? value) {
    _game = value;
  }

  @override
  void markNeedsBuild([VoidCallback? fn]) {
    fn?.call();
  }

  @override
  List<GameCartelaModel> get myCartelas => const <GameCartelaModel>[];
}

GameModel _game({required String sessionId, required GameStatus status}) {
  final now = DateTime.utc(2026, 8, 7, 12);
  return GameModel(
    id: 'game-$sessionId',
    sessionId: sessionId,
    staticCode: 'static-$sessionId',
    playCode: 'play-$sessionId',
    name: 'Game $sessionId',
    gameRule: null,
    gameType: 'REGULAR',
    entryFee: '10',
    prizePerCartela: '100',
    companyFeePerCartela: '0',
    prizeAmount: '1000',
    companyRevenue: '0',
    status: status,
    playOrder: 1,
    startedAt: status == GameStatus.playing ? now : null,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
    registeredCartelasCount: 0,
    calledNumbersCount: 0,
    registrationOpen: status == GameStatus.ready,
    canRegister: status == GameStatus.ready,
    scheduledStartAt: now.add(const Duration(minutes: 1)),
    operationMode: 'MANUAL',
  );
}

List<GameCartelaModel> _cartelas(String sessionId, List<int> numbers) {
  final now = DateTime.utc(2026, 8, 7, 12);
  return numbers
      .map(
        (number) => GameCartelaModel(
          id: 'game-cartela-$sessionId-$number',
          gameId: sessionId,
          userId: 'user-1',
          cartelaId: 'cartela-$sessionId-$number',
          status: GameCartelaStatus.registered,
          isWinner: false,
          blockedAt: null,
          createdAt: now,
          updatedAt: now,
          cartela: CartelaModel(
            id: 'cartela-$sessionId-$number',
            number: number,
            createdAt: now,
          ),
        ),
      )
      .toList(growable: false);
}

List<int> _numbers(List<GameCartelaModel> cartelas) {
  return cartelas
      .map((cartela) => cartela.cartela.number)
      .toList(growable: false);
}
