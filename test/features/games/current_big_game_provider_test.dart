import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/network/api_client.dart';
import 'package:friends_bingo_app/src/features/auth/domain/auth_session.dart';
import 'package:friends_bingo_app/src/features/auth/domain/user_profile.dart';
import 'package:friends_bingo_app/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:friends_bingo_app/src/features/games/data/games_repository.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/live_connection_status.dart';
import 'package:friends_bingo_app/src/features/games/presentation/providers/big_game_summary_ledger_provider.dart';
import 'package:friends_bingo_app/src/features/games/presentation/providers/current_big_game_provider.dart';
import 'package:friends_bingo_app/src/features/games/presentation/providers/realtime_connection_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost.invalid');
  });

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

  test('Bug B: retains final FINISHED when API returns null until dismissed',
      () async {
    final repository = _FakeGamesRepository();
    final finalRound = _bigGame(
      sessionId: 'final-s2',
      status: 'FINISHED',
      roundIndex: 2,
      roundCount: 2,
      canRegister: false,
    );
    repository.onGetCurrentBigGame = () async => finalRound;

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

    await container.read(currentBigGameProvider.future);
    expect(container.read(currentBigGameProvider).value?.sessionId, 'final-s2');

    repository.onGetCurrentBigGame = () async => null;
    await container.read(currentBigGameProvider.notifier).refresh();
    expect(
      container.read(currentBigGameProvider).value?.sessionId,
      'final-s2',
      reason: 'null API must retain final finished card for summary hold',
    );

    container.read(bigGameSummaryLedgerProvider.notifier).markDismissed(
          slotId: 'big-slot',
          sessionId: 'final-s2',
        );
    // Allow listen to clear retention.
    await Future<void>.delayed(Duration.zero);
    await container.read(currentBigGameProvider.notifier).refresh();
    expect(container.read(currentBigGameProvider).value, isNull);
  });

  test(
    'Bug B: PLAYING final → API null retains FINISHED for PIN summary host',
    () async {
      final repository = _FakeGamesRepository();
      final playingFinal = _bigGame(
        sessionId: 'final-s2',
        status: 'PLAYING',
        roundIndex: 2,
        roundCount: 2,
        canRegister: false,
      );
      repository.onGetCurrentBigGame = () async => playingFinal;

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

      await container.read(currentBigGameProvider.future);
      expect(
        container.read(currentBigGameProvider).value?.status,
        GameStatus.playing,
      );

      // Backend tearDown: /big-game/current never returns FINISHED — only null.
      repository.onGetCurrentBigGame = () async => null;
      await container.read(currentBigGameProvider.notifier).refresh();
      final retained = container.read(currentBigGameProvider).value;
      expect(retained?.sessionId, 'final-s2');
      expect(
        retained?.status,
        GameStatus.finished,
        reason: 'shell needs finishedReview to keep LiveHost for PIN summary',
      );
    },
  );

  test('Bug B: newer Big Game event replaces retained finished card', () async {
    final repository = _FakeGamesRepository();
    final finalRound = _bigGame(
      sessionId: 'final-s2',
      status: 'FINISHED',
      roundIndex: 2,
      roundCount: 2,
      canRegister: false,
    );
    repository.onGetCurrentBigGame = () async => finalRound;

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

    await container.read(currentBigGameProvider.future);
    repository.onGetCurrentBigGame = () async => null;
    await container.read(currentBigGameProvider.notifier).refresh();
    expect(container.read(currentBigGameProvider).value?.sessionId, 'final-s2');

    final newer = _bigGame(
      sessionId: 'new-s1',
      slotId: 'other-slot',
      status: 'READY',
      roundIndex: 1,
      roundCount: 2,
      canRegister: true,
    );
    repository.onGetCurrentBigGame = () async => newer;
    await container.read(currentBigGameProvider.notifier).refresh();
    expect(container.read(currentBigGameProvider).value?.sessionId, 'new-s1');
    expect(container.read(currentBigGameProvider).value?.id, 'other-slot');
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

GameModel _bigGame({
  required String sessionId,
  String slotId = 'big-slot',
  String status = 'READY',
  int roundIndex = 1,
  int roundCount = 2,
  bool canRegister = true,
}) {
  return GameModel.fromOperationJson({
    'id': slotId,
    'slotId': slotId,
    'sessionId': sessionId,
    'name': 'Big Game',
    'status': status,
    'entryFee': '10',
    'prizePerCartela': '100',
    'prizeAmount': '1000',
    'companyRevenue': '0',
    'registeredCartelasCount': 3,
    'calledNumbersCount': 0,
    'canRegister': canRegister,
    'registrationOpen': canRegister,
    'scheduledStartAt': '2026-08-03T12:05:00.000Z',
    'operationMode': 'MANUAL',
    'isBigGame': true,
    'category': 'BIG_GAME',
    'roundIndex': roundIndex,
    'roundCount': roundCount,
    if (status == 'FINISHED') 'finishedAt': '2026-08-03T12:10:00.000Z',
  });
}
