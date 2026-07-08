import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/core/network/api_exception.dart';
import 'package:friends_bingo_app/src/core/config/app_config.dart';
import 'package:friends_bingo_app/src/core/network/api_client.dart';
import 'package:friends_bingo_app/src/core/realtime/socket_service.dart';
import 'package:friends_bingo_app/src/core/sync/resume_sync_guard.dart';
import 'package:friends_bingo_app/src/features/auth/domain/auth_session.dart';
import 'package:friends_bingo_app/src/features/auth/domain/user_profile.dart';
import 'package:friends_bingo_app/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/game_operations_resume_cache.dart';
import 'package:friends_bingo_app/src/features/games/data/games_repository.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_numbers_snapshot.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_timing_config_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/screens/live_game_screen.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/live_cartela_card.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/winner_window_countdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sessionId = '11111111-1111-4111-8111-111111111111';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'realtime_branding_splash_seen': true,
    });
    GameOperationsResumeCache.shared.resetForTest();
    ResumeSyncGuard.resetForTest();
  });

  testWidgets(
    'number_called updates immediately without operations/current and does not rebuild cartela cards',
    (tester) async {
      final repository = _TestGamesRepository()
        ..calledNumbersBySession[_sessionId] = const []
        ..myCartelasBySession[_sessionId] = [_gameCartela()];
      final socket = _TestSocketService();

      await _pumpLiveScreen(
        tester,
        repository: repository,
        socket: socket,
        game: _playingGame(),
        authSession: _playerSession(),
      );

      final before = tester.widget<LiveCartelaCard>(
        find.byType(LiveCartelaCard),
      );
      expect(repository.operationsCalls, 0);

      socket.emitEvent('game:number_called', _calledNumberPayload(order: 1));
      await tester.pump();

      expect(find.text('B-7'), findsOneWidget);
      expect(repository.operationsCalls, 0);

      final after = tester.widget<LiveCartelaCard>(
        find.byType(LiveCartelaCard),
      );
      expect(identical(before, after), isTrue);
    },
  );

  testWidgets('sequential number_called does not request canonical refresh', (
    tester,
  ) async {
    final repository = _TestGamesRepository()
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _TestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      game: _playingGame(calledNumbersCount: 1),
      authSession: _playerSession(),
    );

    final operationsBefore = repository.operationsCalls;
    final calledNumbersBefore = repository.calledNumbersCalls;

    socket.emitEvent(
      'game:number_called',
      _calledNumberPayload(order: 2, letter: 'I', number: 18),
    );
    await tester.pump();

    expect(find.text('I-18'), findsOneWidget);
    expect(repository.operationsCalls, operationsBefore);
    expect(repository.calledNumbersCalls, calledNumbersBefore);
  });

  testWidgets('missing order gap triggers called-numbers refetch only', (
    tester,
  ) async {
    final repository = _TestGamesRepository()
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _TestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      game: _playingGame(calledNumbersCount: 1),
      authSession: _playerSession(),
    );

    final initialCalledNumbersCalls = repository.calledNumbersCalls;
    repository.calledNumbersBySession[_sessionId] = [
      _calledNumber(order: 1),
      _calledNumber(order: 2, letter: 'I', number: 18),
      _calledNumber(order: 3, letter: 'N', number: 33),
    ];

    socket.emitEvent(
      'game:number_called',
      _calledNumberPayload(order: 3, letter: 'N', number: 33),
    );

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(
      repository.calledNumbersCalls,
      greaterThan(initialCalledNumbersCalls),
    );
    expect(repository.operationsCalls, 0);
    expect(find.text('N-33'), findsOneWidget);
  });

  testWidgets('duplicate number_called is ignored', (tester) async {
    final repository = _TestGamesRepository()
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _TestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      game: _playingGame(calledNumbersCount: 1),
      authSession: _playerSession(),
    );

    final calledNumbersBefore = repository.calledNumbersCalls;

    socket.emitEvent('game:number_called', _calledNumberPayload(order: 1));
    await tester.pump();

    expect(find.text('B-7'), findsOneWidget);
    expect(repository.calledNumbersCalls, calledNumbersBefore);
    expect(repository.operationsCalls, 0);
  });

  testWidgets('reconnect triggers canonical called-number sync', (
    tester,
  ) async {
    final repository = _TestGamesRepository()
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()]
      ..sessionDetailGame = _playingGame(calledNumbersCount: 2);
    final socket = _TestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      game: _playingGame(calledNumbersCount: 2),
      authSession: _playerSession(),
    );

    final initialCalledNumbersCalls = repository.calledNumbersCalls;

    repository.calledNumbersBySession[_sessionId] = [
      _calledNumber(order: 1),
      _calledNumber(order: 2, letter: 'I', number: 18),
    ];
    repository.sessionDetailGame = _playingGame(calledNumbersCount: 2);
    GameOperationsResumeCache.shared.resetForTest();

    socket.simulateDisconnect();
    await tester.pump();
    socket.simulateReconnect();
    for (var index = 0; index < 15; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(
      repository.calledNumbersCalls,
      greaterThan(initialCalledNumbersCalls),
    );
  });

  testWidgets(
    'auto_call_changed stays socket-first without operations/current',
    (tester) async {
      final repository = _TestGamesRepository()
        ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
        ..myCartelasBySession[_sessionId] = [_gameCartela()];
      final socket = _TestSocketService();

      await _pumpLiveScreen(
        tester,
        repository: repository,
        socket: socket,
        game: _playingGame(
          calledNumbersCount: 1,
          nextAutoCallAt: DateTime.now().add(const Duration(seconds: 6)),
        ),
        authSession: _playerSession(),
      );

      socket.emitEvent('game:operation_updated', {
        'updatedReason': 'auto_call_changed',
        'sessionId': _sessionId,
        'slotId': 'slot-1',
        'autoCallEnabled': true,
        'autoCallIntervalMs': 12000,
        'nextAutoCallAt': DateTime.now()
            .add(const Duration(seconds: 12))
            .toIso8601String(),
      });
      await tester.pump();

      expect(repository.operationsCalls, 0);

      socket.emitEvent(
        'game:number_called',
        _calledNumberPayload(order: 2, letter: 'I', number: 18),
      );
      await tester.pump();

      expect(find.text('I-18'), findsOneWidget);
      expect(repository.operationsCalls, 0);
    },
  );

  testWidgets('bingo_invalid blocks cartela immediately', (tester) async {
    final repository = _TestGamesRepository()
      ..calledNumbersBySession[_sessionId] = const []
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _TestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      game: _playingGame(),
      authSession: _playerSession(),
    );

    socket.emitEvent('game:bingo_invalid', {
      'claimId': 'claim-1',
      'sessionId': _sessionId,
      'gameCartelaId': 'gc-1',
      'cartelaNumber': 42,
      'userId': 'user-1',
    });
    await tester.pump();

    expect(find.text('BLOCKED'), findsOneWidget);
  });

  testWidgets('winner_window_started starts countdown immediately', (
    tester,
  ) async {
    final repository = _TestGamesRepository()
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _TestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      game: _playingGame(calledNumbersCount: 1),
      authSession: _playerSession(),
    );

    socket.emitEvent('game:winner_window_started', {
      'claimId': 'claim-1',
      'sessionId': _sessionId,
      'gameCartelaId': 'gc-1',
      'cartelaNumber': 42,
      'userId': 'user-1',
      'winnerWindowEndsAt': DateTime.now()
          .add(const Duration(seconds: 20))
          .toIso8601String(),
      'completedPatterns': const [],
    });
    await tester.pump();

    expect(find.byType(WinnerWindowCountdown), findsOneWidget);
    expect(find.textContaining('Winner window closes in'), findsOneWidget);
  });

  testWidgets('finished triggers canonical refresh', (tester) async {
    final repository = _TestGamesRepository()
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _TestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      game: _playingGame(calledNumbersCount: 1),
      authSession: _playerSession(),
    );

    final initialCalledNumbersCalls = repository.calledNumbersCalls;
    socket.emitEvent('game:finished', {
      'sessionId': _sessionId,
      'slotId': 'slot-1',
    });
    await tester.pump();

    expect(
      repository.calledNumbersCalls,
      greaterThan(initialCalledNumbersCalls),
    );
  });

  testWidgets('countdown tick does not rebuild cartela cards', (tester) async {
    final repository = _TestGamesRepository()
      ..calledNumbersBySession[_sessionId] = const []
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _TestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      game: _playingGame(
        nextAutoCallAt: DateTime.now().add(const Duration(seconds: 5)),
      ),
      authSession: _playerSession(),
    );

    final before = tester.widget<LiveCartelaCard>(find.byType(LiveCartelaCard));
    await tester.pump(const Duration(seconds: 2));
    final after = tester.widget<LiveCartelaCard>(find.byType(LiveCartelaCard));

    expect(identical(before, after), isTrue);
  });

  testWidgets('LegacyJavaScriptObject-like status_changed does not crash', (
    tester,
  ) async {
    final repository = _TestGamesRepository()
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _TestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      game: _playingGame(calledNumbersCount: 1),
      authSession: _playerSession(),
    );

    socket.emitEvent(
      'game:status_changed',
      _JsonEncodableLegacySim({
        'sessionId': _sessionId,
        'slotId': 'slot-1',
        'status': 'PLAYING',
      }),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('wallet:updated accepts json-decoded map payload', (
    tester,
  ) async {
    final repository = _TestGamesRepository()
      ..calledNumbersBySession[_sessionId] = const []
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _TestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      game: _playingGame(),
      authSession: _playerSession(),
    );

    final payload = jsonDecode(
      '{"userId":"user-1","balance":"120.00"}',
    );

    socket.emitEvent('wallet:updated', payload);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('game:finished invalid payload does not crash', (tester) async {
    final repository = _TestGamesRepository()
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _TestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      game: _playingGame(calledNumbersCount: 1),
      authSession: _playerSession(),
    );

    socket.emitEvent('game:finished', 'not-a-map');
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Dio 400 on called-numbers refetch is handled safely', (
    tester,
  ) async {
    final repository = _TestGamesRepository()
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()]
      ..throw400OnCalledNumbersAfter = 1;
    final socket = _TestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      game: _playingGame(calledNumbersCount: 1),
      authSession: _playerSession(),
    );

    expect(find.text('B-7'), findsOneWidget);

    socket.emitEvent('game:finished', {
      'sessionId': _sessionId,
      'slotId': 'slot-1',
    });
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('B-7'), findsOneWidget);
  });

  testWidgets('winnerWindow to review coalesces terminal canonical refetches', (
    tester,
  ) async {
    final repository = _TestGamesRepository()
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _TestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      game: _playingGame(calledNumbersCount: 1),
      authSession: _playerSession(),
    );
    final callsAfterMount = repository.calledNumbersCalls;

    socket.emitEvent('game:winner_window_started', {
      'claimId': 'claim-1',
      'sessionId': _sessionId,
      'gameCartelaId': 'gc-1',
      'cartelaNumber': 42,
      'userId': 'user-1',
      'winnerWindowEndsAt': DateTime.now()
          .add(const Duration(seconds: 20))
          .toIso8601String(),
      'completedPatterns': const [],
    });
    await tester.pump();
    socket.emitEvent('game:finished', {
      'sessionId': _sessionId,
      'slotId': 'slot-1',
    });
    socket.emitEvent('game:status_changed', {
      'sessionId': _sessionId,
      'slotId': 'slot-1',
      'status': 'FINISHED',
    });

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(
      repository.calledNumbersCalls - callsAfterMount,
      lessThanOrEqualTo(2),
    );
  });

  testWidgets('review refetch keeps called numbers when API returns 400', (
    tester,
  ) async {
    final repository = _TestGamesRepository()
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()]
      ..throw400OnCalledNumbersAfter = 1;
    final socket = _TestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      game: _playingGame(calledNumbersCount: 1),
      authSession: _playerSession(),
    );

    expect(find.text('B-7'), findsOneWidget);

    socket.emitEvent('game:finished', {
      'sessionId': _sessionId,
      'slotId': 'slot-1',
    });
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('B-7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpLiveScreen(
  WidgetTester tester, {
  required _TestGamesRepository repository,
  required _TestSocketService socket,
  required GameModel game,
  AuthSession? authSession,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gamesRepositoryProvider.overrideWithValue(repository),
        socketServiceProvider.overrideWithValue(socket),
        authControllerProvider.overrideWith(
          authSession == null
              ? _GuestAuthController.new
              : () => _PlayerAuthController(authSession),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LiveGameScreen(
          gameId: game.sessionId,
          initialGame: game,
          embedded: true,
        ),
      ),
    ),
  );

  for (var index = 0; index < 10; index++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

GameModel _playingGame({int calledNumbersCount = 0, DateTime? nextAutoCallAt}) {
  return GameModel.fromOperationJson({
    'slotId': 'slot-1',
    'sessionId': _sessionId,
    'staticCode': 'FULL_HOUSE-S1',
    'playCode': 'BINGO-1',
    'playerStatus': 'playing',
    'rawStatus': 'PLAYING',
    'operationMode': 'AUTO',
    'canRegister': false,
    'registrationOpen': false,
    'entryFee': '10',
    'prizePerCartela': '8',
    'prizeAmount': '100',
    'registeredCartelasCount': 1,
    'calledNumbersCount': calledNumbersCount,
    'nextAutoCallAt': nextAutoCallAt?.toIso8601String(),
    'autoCallIntervalMs': 18000,
    'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
  });
}

GameCartelaModel _gameCartela() {
  return GameCartelaModel(
    id: 'gc-1',
    gameId: _sessionId,
    userId: 'user-1',
    cartelaId: 'cartela-42',
    status: GameCartelaStatus.registered,
    isWinner: false,
    blockedAt: null,
    createdAt: DateTime.utc(2026, 6, 1),
    updatedAt: DateTime.utc(2026, 6, 1),
    cartela: CartelaModel(
      id: 'cartela-42',
      number: 42,
      createdAt: DateTime.utc(2026, 6, 1),
      b: const ['1', '2', '3', '4', '5'],
      i: const ['16', '17', '18', '19', '20'],
      n: const ['31', '32', 'FREE', '34', '35'],
      g: const ['46', '47', '48', '49', '50'],
      o: const ['61', '62', '63', '64', '65'],
    ),
  );
}

CalledNumberModel _calledNumber({
  required int order,
  String letter = 'B',
  int number = 7,
}) {
  return CalledNumberModel(
    id: 'cn-$order',
    sessionId: _sessionId,
    slotId: 'slot-1',
    letter: letter,
    number: number,
    order: order,
    createdAt: DateTime.utc(2026, 6, 1, 12, 0, order),
    playerStatus: 'playing',
  );
}

Map<String, dynamic> _calledNumberPayload({
  required int order,
  String letter = 'B',
  int number = 7,
}) {
  return {
    'id': 'cn-$order',
    'sessionId': _sessionId,
    'gameSessionId': _sessionId,
    'slotId': 'slot-1',
    'gameSlotId': 'slot-1',
    'letter': letter,
    'number': number,
    'order': order,
    'createdAt': DateTime.now().toIso8601String(),
  };
}

AuthSession _playerSession() {
  return AuthSession(
    accessToken: 'token-1',
    user: UserProfile(
      id: 'user-1',
      fullName: 'Player One',
      phoneNumber: '251900000000',
      role: UserRole.player,
      status: UserStatus.active,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
  );
}

class _GuestAuthController extends AuthController {
  @override
  AuthState build() => const AuthState();
}

class _PlayerAuthController extends AuthController {
  _PlayerAuthController(this.session);

  final AuthSession session;

  @override
  AuthState build() => AuthState(session: session);
}

class _TestSocketService extends SocketService {
  _TestSocketService()
    : super(
        AppConfig(
          apiBaseUrl: 'http://localhost:3002',
          socketBaseUrl: 'http://localhost:3002',
        ),
      );

  final Map<String, List<void Function(dynamic data)>> _listeners = {};
  bool _connected = true;

  @override
  bool get isConnected => _connected;

  @override
  bool get hasActiveSocket => true;

  @override
  void connect(String token) {
    _connected = true;
  }

  @override
  void connectAsGuest() {
    _connected = true;
  }

  @override
  void disconnect() {
    _connected = false;
    emitEvent('disconnect', null);
  }

  @override
  void on(String event, void Function(dynamic data) listener) {
    _listeners
        .putIfAbsent(event, () => <void Function(dynamic data)>[])
        .add(listener);
  }

  @override
  void off(String event, [void Function(dynamic data)? listener]) {
    final listeners = _listeners[event];
    if (listeners == null) {
      return;
    }
    if (listener == null) {
      _listeners.remove(event);
      return;
    }
    listeners.remove(listener);
    if (listeners.isEmpty) {
      _listeners.remove(event);
    }
  }

  void emitEvent(String event, dynamic payload) {
    final listeners = List<void Function(dynamic data)>.from(
      _listeners[event] ?? const <void Function(dynamic data)>[],
    );
    for (final listener in listeners) {
      listener(payload);
    }
  }

  void simulateDisconnect() {
    _connected = false;
    emitEvent('disconnect', null);
  }

  void simulateReconnect() {
    _connected = true;
    emitEvent('connect', null);
  }
}

class _TestGamesRepository extends GamesRepository {
  _TestGamesRepository() : super(ApiClient(Dio()));

  int timeConfigCalls = 0;
  int operationsCalls = 0;
  int calledNumbersCalls = 0;
  int myCartelasCalls = 0;
  bool throw400OnCalledNumbers = false;
  int? throw400OnCalledNumbersAfter;
  GameModel? sessionDetailGame;

  final Map<String, List<CalledNumberModel>> calledNumbersBySession =
      <String, List<CalledNumberModel>>{};
  final Map<String, List<GameCartelaModel>> myCartelasBySession =
      <String, List<GameCartelaModel>>{};

  @override
  Future<GameTimingConfigModel> getTimeConfig() async {
    timeConfigCalls += 1;
    return GameTimingConfigModel(
      registrationDurationSeconds:
          GameTimingConfigModel.defaultRegistrationDurationSeconds,
      autoCallIntervalSeconds:
          GameTimingConfigModel.defaultAutoCallIntervalSeconds,
      winnerWindowSeconds: GameTimingConfigModel.defaultWinnerWindowSeconds,
      cartelaHoldSeconds: GameTimingConfigModel.defaultCartelaHoldSeconds,
      bulkSelectionHoldSeconds:
          GameTimingConfigModel.defaultBulkSelectionHoldSeconds,
      finishedResultDisplaySeconds:
          GameTimingConfigModel.defaultFinishedResultDisplaySeconds,
      winningPatternDisplaySeconds:
          GameTimingConfigModel.defaultWinningPatternDisplaySeconds,
      preparingDisplayMaxSeconds: null,
      missedNumberAnimationMs:
          GameTimingConfigModel.defaultMissedNumberAnimationMs,
      missedNumberStaggerMaxBalls:
          GameTimingConfigModel.defaultMissedNumberStaggerMaxBalls,
      flutterRefetchDebounceMs:
          GameTimingConfigModel.defaultFlutterRefetchDebounceMs,
      serverNow: DateTime.now().toUtc(),
    );
  }

  @override
  Future<GameOperationsCurrentResponse> getCurrentGameOperations() async {
    operationsCalls += 1;
    throw UnimplementedError(
      'operations/current should not be used in this harness',
    );
  }

  @override
  Future<GameModel> getSessionDetail(String sessionId) async {
    return sessionDetailGame ?? _playingGame();
  }

  @override
  Future<CalledNumbersSnapshot> getCalledNumbers(String sessionId) async {
    calledNumbersCalls += 1;
    if (throw400OnCalledNumbers ||
        (throw400OnCalledNumbersAfter != null &&
            calledNumbersCalls > throw400OnCalledNumbersAfter!)) {
      throw ApiException.fromDioException(
        DioException(
          requestOptions: RequestOptions(
            path: '/games/sessions/$sessionId/called-numbers',
            method: 'GET',
          ),
          response: Response(
            requestOptions: RequestOptions(path: '/games/sessions/$sessionId/called-numbers'),
            statusCode: 400,
            data: {
              'error': {
                'statusCode': 400,
                'message': 'Session not ready for called numbers',
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );
    }
    final calledNumbers = List<CalledNumberModel>.from(
      calledNumbersBySession[sessionId] ?? const <CalledNumberModel>[],
    );
    return CalledNumbersSnapshot(
      totalCount: calledNumbers.length,
      calledNumbers: calledNumbers,
    );
  }

  @override
  Future<List<GameCartelaModel>> getMyGameCartelas(String sessionId) async {
    myCartelasCalls += 1;
    return List<GameCartelaModel>.from(
      myCartelasBySession[sessionId] ?? const <GameCartelaModel>[],
    );
  }
}

class _JsonEncodableLegacySim {
  _JsonEncodableLegacySim(this.data);

  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => data;
}
