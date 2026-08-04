import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/network/api_client.dart';
import 'package:friends_bingo_app/src/features/auth/domain/auth_session.dart';
import 'package:friends_bingo_app/src/features/auth/domain/user_profile.dart';
import 'package:friends_bingo_app/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:friends_bingo_app/src/features/games/data/games_repository.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/live_connection_status.dart';
import 'package:friends_bingo_app/src/features/games/presentation/providers/current_big_game_provider.dart';
import 'package:friends_bingo_app/src/features/games/presentation/providers/realtime_connection_provider.dart';

void main() {
  test('CurrentBigGameNotifier dedupes overlapping requests', () async {
    final repository = _FakeGamesRepository();
    final completer = Completer<GameModel?>();
    repository.onGetCurrentBigGame = () => completer.future;
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _TestAuthController(_signedInAuthState()),
        ),
        gamesRepositoryProvider.overrideWithValue(repository),
        realtimeConnectionProvider.overrideWith(
          () => _StaticRealtimeConnectionNotifier(
            LiveConnectionStatus.offline,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final initialFuture = container.read(currentBigGameProvider.future);
    unawaited(container.read(currentBigGameProvider.notifier).refresh());

    expect(repository.currentBigGameCalls, 1);

    completer.complete(_bigGame(sessionId: 'big-session'));

    final game = await initialFuture;
    expect(game?.sessionId, 'big-session');
    expect(repository.currentBigGameCalls, 1);
  });
}

class _FakeGamesRepository extends GamesRepository {
  _FakeGamesRepository() : super(ApiClient(Dio()));

  int currentBigGameCalls = 0;
  Future<GameModel?> Function()? onGetCurrentBigGame;

  @override
  Future<GameModel?> getCurrentBigGame() {
    currentBigGameCalls++;
    final callback = onGetCurrentBigGame;
    if (callback != null) {
      return callback();
    }
    return Future<GameModel?>.value(_bigGame(sessionId: 'big-session'));
  }
}

class _StaticRealtimeConnectionNotifier extends RealtimeConnectionNotifier {
  _StaticRealtimeConnectionNotifier(this._value);

  final LiveConnectionStatus _value;

  @override
  LiveConnectionStatus build() => _value;
}

class _TestAuthController extends AuthController {
  _TestAuthController(this._state);

  final AuthState _state;

  @override
  AuthState build() => _state;
}

AuthState _signedInAuthState() {
  return AuthState(
    session: AuthSession(
      accessToken: 'token',
      user: UserProfile(
        id: 'user-1',
        fullName: 'Test User',
        phoneNumber: '0911000000',
        role: UserRole.player,
        status: UserStatus.active,
        createdAt: DateTime.utc(2026, 8, 3, 12),
        updatedAt: DateTime.utc(2026, 8, 3, 12),
      ),
    ),
  );
}

GameModel _bigGame({required String sessionId}) {
  return GameModel.fromOperationJson({
    'id': 'big-slot',
    'slotId': 'big-slot',
    'sessionId': sessionId,
    'name': 'Big Game',
    'status': 'READY',
    'entryFee': '10',
    'prizePerCartela': '100',
    'prizeAmount': '1000',
    'companyRevenue': '0',
    'registeredCartelasCount': 3,
    'calledNumbersCount': 0,
    'canRegister': true,
    'registrationOpen': true,
    'scheduledStartAt': '2026-08-03T12:05:00.000Z',
    'operationMode': 'MANUAL',
    'isBigGame': true,
  });
}
