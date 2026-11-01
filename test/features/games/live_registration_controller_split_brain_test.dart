import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/network/api_client.dart';
import 'package:friends_bingo_app/src/features/games/application/controllers/live_game_host.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/games_repository.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/registration/application/controllers/live_registration_controller.dart';

void main() {
  group('Controller & _LiveGameScreenStateBase single source of truth (BUG-01)', () {
    test(
      'live_game_state_base.dart delegates display order, auto-open, sync flag, and socket membership to controllers without duplicate fields',
      () {
        final source = File(
          'lib/src/features/games/presentation/screens/live_game_state_base.dart',
        ).readAsStringSync();

        expect(
          source.contains('List<String> _myCartelaDisplayOrderIds ='),
          isFalse,
          reason: '_myCartelaDisplayOrderIds must delegate to _registration',
        );
        expect(
          source.contains('List<int>? _pendingAutoOpenCartelaNumbers;'),
          isFalse,
          reason: '_pendingAutoOpenCartelaNumbers must delegate to _registration',
        );
        expect(
          source.contains('Timer? _myCartelasRefreshDebounceTimer;'),
          isFalse,
          reason: 'Debounce timer is owned by LiveRegistrationController',
        );
        expect(
          source.contains('Timer? _nextCartelasRefreshDebounceTimer;'),
          isFalse,
          reason: 'Debounce timer is owned by LiveRegistrationController',
        );
        expect(
          source.contains('final bool _isSyncingLiveGame = false;'),
          isFalse,
          reason: '_isSyncingLiveGame must delegate to _realtime.isSyncingLiveGame',
        );
        expect(
          source.contains(
            'final LiveSocketSessionMembership _socketMembership =',
          ),
          isFalse,
          reason: '_socketMembership must delegate to _realtime.socketMembership',
        );
        expect(
          source.contains('String? _joinedGameId;'),
          isFalse,
          reason: '_joinedGameId must delegate to _realtime.joinedGameId',
        );
      },
    );

    test(
      'LiveRegistrationController reorderMyCartela and clearMyCartelasForSessionTransition share myCartelaDisplayOrderIds',
      () {
        final host = _FakeLiveGameHost();
        final controller = LiveRegistrationController(host)
          ..myCartelas = _cartelas('session-1', [10, 20, 30]);

        controller.reorderMyCartela(2, 0);
        expect(
          controller.orderedMyCartelas.map((c) => c.cartela.number).toList(),
          <int>[30, 10, 20],
        );

        controller.clearMyCartelasForSessionTransition();
        expect(controller.myCartelaDisplayOrderIds, isEmpty);
        expect(controller.myCartelas, isEmpty);
      },
    );
  });
}

class _FakeLiveGameHost extends Fake implements LiveGameHost {
  @override
  bool mounted = true;

  @override
  bool isLiveHostActive = true;

  @override
  bool isGuest = false;

  @override
  final GamesRepository gamesRepository = GamesRepository(ApiClient(Dio()));

  @override
  GameModel? game;

  @override
  void markNeedsBuild([VoidCallback? fn]) {
    fn?.call();
  }
}

List<GameCartelaModel> _cartelas(String sessionId, List<int> numbers) {
  final now = DateTime.utc(2026, 8, 7, 12);
  return numbers
      .map(
        (number) => GameCartelaModel(
          id: 'gc-$sessionId-$number',
          gameId: sessionId,
          userId: 'user-1',
          cartelaId: 'c-$sessionId-$number',
          status: GameCartelaStatus.registered,
          isWinner: false,
          blockedAt: null,
          createdAt: now,
          updatedAt: now,
          cartela: CartelaModel(
            id: 'c-$sessionId-$number',
            number: number,
            createdAt: now,
          ),
        ),
      )
      .toList(growable: false);
}
