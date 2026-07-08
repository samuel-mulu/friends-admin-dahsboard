import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/core/config/app_config.dart';
import 'package:friends_bingo_app/src/core/network/api_client.dart';
import 'package:friends_bingo_app/src/core/network/api_exception.dart';
import 'package:friends_bingo_app/src/core/realtime/socket_service.dart';
import 'package:friends_bingo_app/src/features/auth/domain/auth_session.dart';
import 'package:friends_bingo_app/src/features/auth/domain/user_profile.dart';
import 'package:friends_bingo_app/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:friends_bingo_app/src/core/sync/resume_sync_guard.dart';
import 'package:friends_bingo_app/src/features/games/data/games_repository.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_numbers_snapshot.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_timing_config_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/screens/live_game_screen.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/game_operations_resume_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _liveSessionId = '22222222-2222-4222-8222-222222222222';
const _readySessionId = '33333333-3333-4333-8333-333333333333';
const _sessionId = _liveSessionId;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'realtime_branding_splash_seen': true,
    });
  });

  tearDown(() {
    GameOperationsResumeCache.shared.resetForTest();
    ResumeSyncGuard.resetForTest();
  });

  testWidgets('quick background return skips full resume sync', (tester) async {
    final repository = _SyncTestGamesRepository()
      ..operationsResponse = _operations(
        liveGame: _playingGame(calledNumbersCount: 1),
      )
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _SyncTestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      initialGame: _playingGame(calledNumbersCount: 1),
    );

    final operationsCallsBefore = repository.operationsCalls;

    await _simulateBackgroundReturn(
      tester,
      away: const Duration(milliseconds: 900),
      socket: socket,
    );
    for (var index = 0; index < 8; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(repository.operationsCalls, operationsCallsBefore);
    expect(find.text('Syncing...'), findsNothing);
    expect(find.text('B-7'), findsOneWidget);
  });

  testWidgets('long background return runs full resume sync', (tester) async {
    final repository = _SyncTestGamesRepository()
      ..operationsResponse = _operations(
        liveGame: _playingGame(calledNumbersCount: 1),
      )
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _SyncTestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      initialGame: _playingGame(calledNumbersCount: 1),
    );

    repository.operationsResponse = _operations(
      liveGame: _playingGame(calledNumbersCount: 2),
    );
    repository.calledNumbersBySession[_sessionId] = [
      _calledNumber(order: 1),
      _calledNumber(order: 2, letter: 'I', number: 18),
    ];
    GameOperationsResumeCache.shared.resetForTest();

    final operationsCallsBefore = repository.operationsCalls;

    await _simulateBackgroundReturn(
      tester,
      away: const Duration(seconds: 5),
      socket: socket,
    );
    for (var index = 0; index < 12; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(repository.operationsCalls, greaterThan(operationsCallsBefore));
    expect(find.text('I-18'), findsOneWidget);
  });

  testWidgets('quick background with socket disconnect still syncs', (
    tester,
  ) async {
    final repository = _SyncTestGamesRepository()
      ..operationsResponse = _operations(
        liveGame: _playingGame(calledNumbersCount: 1),
      )
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _SyncTestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      initialGame: _playingGame(calledNumbersCount: 1),
    );

    repository.operationsResponse = _operations(
      liveGame: _playingGame(calledNumbersCount: 2),
    );
    repository.calledNumbersBySession[_sessionId] = [
      _calledNumber(order: 1),
      _calledNumber(order: 2, letter: 'I', number: 18),
    ];
    GameOperationsResumeCache.shared.resetForTest();

    final operationsCallsBefore = repository.operationsCalls;

    await _simulateBackgroundReturn(
      tester,
      away: const Duration(milliseconds: 900),
      socket: socket,
      disconnectSocket: true,
    );
    for (var index = 0; index < 20; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(repository.operationsCalls, greaterThan(operationsCallsBefore));
    expect(find.text('I-18'), findsOneWidget);
  });

  testWidgets('app_resume and socket reconnect coalesce into one sync', (
    tester,
  ) async {
    final repository = _SyncTestGamesRepository()
      ..operationsResponse = _operations(
        liveGame: _playingGame(calledNumbersCount: 1),
      )
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _SyncTestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      initialGame: _playingGame(calledNumbersCount: 1),
    );

    repository.operationsResponse = _operations(
      liveGame: _playingGame(calledNumbersCount: 2),
    );
    repository.calledNumbersBySession[_sessionId] = [
      _calledNumber(order: 1),
      _calledNumber(order: 2, letter: 'I', number: 18),
    ];
    GameOperationsResumeCache.shared.resetForTest();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    AppBackgroundResumeGate.setBackgroundedAtForTest(
      DateTime.now().subtract(const Duration(seconds: 3)),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    socket.simulateReconnect();
    final operationsCallsBeforeCoalescedSync = repository.operationsCalls;
    final calledNumbersCallsBeforeCoalescedSync = repository.calledNumbersCalls;
    await tester.pump(const Duration(milliseconds: 900));
    for (var index = 0; index < 12; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(
      repository.calledNumbersCalls - calledNumbersCallsBeforeCoalescedSync,
      1,
    );
    expect(
      repository.operationsCalls - operationsCallsBeforeCoalescedSync,
      lessThanOrEqualTo(2),
    );
    expect(find.text('I-18'), findsOneWidget);
  });

  testWidgets('resume syncs live called numbers while primary stays READY', (
    tester,
  ) async {
    final repository = _SyncTestGamesRepository()
      ..operationsResponse = _operations(
        liveGame: _playingGame(calledNumbersCount: 1),
        registrationGame: _readyGame(),
      )
      ..calledNumbersBySession[_liveSessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_readySessionId] = const [];
    final socket = _SyncTestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      initialGame: _readyGame(),
    );

    expect(find.text('B-7'), findsNothing);

    repository.operationsResponse = _operations(
      liveGame: _playingGame(calledNumbersCount: 2),
      registrationGame: _readyGame(),
    );
    repository.calledNumbersBySession[_liveSessionId] = [
      _calledNumber(order: 1),
      _calledNumber(order: 2, letter: 'I', number: 18),
    ];
    GameOperationsResumeCache.shared.resetForTest();

    final calledNumbersCallsBeforeResume = repository.calledNumbersCalls;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    for (var index = 0; index < 12; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(
      repository.calledNumbersCalls,
      greaterThan(calledNumbersCallsBeforeResume),
    );
    expect(repository.calledNumbersSessionIds, contains(_liveSessionId));
    expect(
      repository.calledNumbersSessionIds,
      isNot(contains(_readySessionId)),
    );
    expect(find.text('I-18'), findsNothing);
  });

  testWidgets('resume keeps old PLAYING visible while sync runs', (
    tester,
  ) async {
    final repository = _SyncTestGamesRepository()
      ..operationsResponse = _operations(
        liveGame: _playingGame(calledNumbersCount: 1),
      )
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _SyncTestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      initialGame: _playingGame(calledNumbersCount: 1),
    );

    expect(find.text('B-7'), findsOneWidget);

    repository.operationsDelay = const Duration(seconds: 2);
    repository.operationsResponse = _operations(
      liveGame: _playingGame(
        calledNumbersCount: 2,
        nextAutoCallAt: DateTime.now().add(const Duration(seconds: 8)),
      ),
    );
    repository.calledNumbersBySession[_sessionId] = [
      _calledNumber(order: 1),
      _calledNumber(order: 2, letter: 'I', number: 18),
    ];

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('B-7'), findsOneWidget);
    expect(find.text('Syncing...'), findsOneWidget);
    expect(find.text('No games in queue'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text('Syncing latest game...'), findsOneWidget);

    for (var index = 0; index < 30; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('I-18'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
  });

  testWidgets('reconnect during PLAYING catches up called numbers', (
    tester,
  ) async {
    final repository = _SyncTestGamesRepository()
      ..operationsResponse = _operations(
        liveGame: _playingGame(calledNumbersCount: 1),
      )
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _SyncTestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      initialGame: _playingGame(calledNumbersCount: 1),
    );

    repository.operationsResponse = _operations(
      liveGame: _playingGame(
        calledNumbersCount: 2,
        nextAutoCallAt: DateTime.now().add(const Duration(seconds: 10)),
      ),
    );
    repository.calledNumbersBySession[_sessionId] = [
      _calledNumber(order: 1),
      _calledNumber(order: 2, letter: 'I', number: 18),
    ];

    socket.emitEvent('connect', null);
    await tester.pump();

    expect(find.text('Reconnecting...'), findsWidgets);

    for (var index = 0; index < 20; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('I-18'), findsOneWidget);
    expect(repository.calledNumbersCalls, greaterThanOrEqualTo(2));
  });

  testWidgets('reconnect keeps cartelas when my-cartelas fetch fails', (
    tester,
  ) async {
    final repository = _SyncTestGamesRepository()
      ..operationsResponse = _operations(
        liveGame: _playingGame(calledNumbersCount: 1),
      )
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _SyncTestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      initialGame: _playingGame(calledNumbersCount: 1),
    );

    expect(find.text('42'), findsWidgets);

    repository.throwMyCartelasError = true;
    repository.operationsResponse = _operations(
      liveGame: _playingGame(
        calledNumbersCount: 2,
        nextAutoCallAt: DateTime.now().add(const Duration(seconds: 10)),
      ),
    );
    repository.calledNumbersBySession[_sessionId] = [
      _calledNumber(order: 1),
      _calledNumber(order: 2, letter: 'I', number: 18),
    ];
    GameOperationsResumeCache.shared.resetForTest();

    socket.simulateReconnect();
    await tester.pump();
    for (var index = 0; index < 12; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('42'), findsWidgets);
  });

  testWidgets('failed sync keeps old UI and does not show No Game', (
    tester,
  ) async {
    final repository = _SyncTestGamesRepository()
      ..operationsResponse = _operations(
        liveGame: _playingGame(calledNumbersCount: 1),
      )
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _SyncTestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      initialGame: _playingGame(calledNumbersCount: 1),
    );

    repository.throwOperationsError = true;

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('B-7'), findsOneWidget);
    expect(find.text('No games in queue'), findsNothing);
  });

  testWidgets('true empty backend shows No Game after successful sync', (
    tester,
  ) async {
    final repository = _SyncTestGamesRepository()
      ..operationsResponse = _operations(
        liveGame: _playingGame(calledNumbersCount: 1),
      )
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _SyncTestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      initialGame: _playingGame(calledNumbersCount: 1),
    );

    repository.operationsResponse = _operations();
    repository.calledNumbersBySession[_sessionId] = const [];
    repository.myCartelasBySession[_sessionId] = const [];

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('No games in queue'), findsOneWidget);
    expect(find.text('B-7'), findsNothing);
  });

  testWidgets('manual refresh triggers same full sync path', (tester) async {
    final repository = _SyncTestGamesRepository()
      ..operationsResponse = _operations(
        liveGame: _playingGame(calledNumbersCount: 1),
      )
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _SyncTestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      initialGame: _playingGame(calledNumbersCount: 1),
    );

    final operationsCallsBeforeRefresh = repository.operationsCalls;
    final calledNumbersCallsBeforeRefresh = repository.calledNumbersCalls;

    repository.operationsResponse = _operations(
      liveGame: _playingGame(calledNumbersCount: 2),
    );
    repository.calledNumbersBySession[_sessionId] = [
      _calledNumber(order: 1),
      _calledNumber(order: 2, letter: 'I', number: 18),
    ];

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(
      repository.operationsCalls,
      greaterThan(operationsCallsBeforeRefresh),
    );
    expect(
      repository.calledNumbersCalls,
      greaterThan(calledNumbersCallsBeforeRefresh),
    );
    expect(find.text('I-18'), findsOneWidget);
  });

  testWidgets('long sync shows delayed overlay and hides after success', (
    tester,
  ) async {
    final repository = _SyncTestGamesRepository()
      ..operationsResponse = _operations(
        liveGame: _playingGame(calledNumbersCount: 1),
      )
      ..calledNumbersBySession[_sessionId] = [_calledNumber(order: 1)]
      ..myCartelasBySession[_sessionId] = [_gameCartela()];
    final socket = _SyncTestSocketService();

    await _pumpLiveScreen(
      tester,
      repository: repository,
      socket: socket,
      initialGame: _playingGame(calledNumbersCount: 1),
    );

    repository.operationsDelay = const Duration(seconds: 2);
    repository.operationsResponse = _operations(
      liveGame: _playingGame(calledNumbersCount: 2),
    );
    repository.calledNumbersBySession[_sessionId] = [
      _calledNumber(order: 1),
      _calledNumber(order: 2, letter: 'I', number: 18),
    ];

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Syncing latest game...'), findsOneWidget);

    for (var index = 0; index < 40; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('I-18'), findsOneWidget);
  });
}

Future<void> _simulateBackgroundReturn(
  WidgetTester tester, {
  required Duration away,
  required _SyncTestSocketService socket,
  bool disconnectSocket = false,
}) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  await tester.pump();
  AppBackgroundResumeGate.setBackgroundedAtForTest(
    DateTime.now().subtract(away),
    socketDisconnectedWhileBackgrounded: disconnectSocket,
  );
  if (disconnectSocket) {
    socket.simulateDisconnect();
  }
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pump();
}

Future<void> _pumpLiveScreen(
  WidgetTester tester, {
  required _SyncTestGamesRepository repository,
  required _SyncTestSocketService socket,
  required GameModel initialGame,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gamesRepositoryProvider.overrideWithValue(repository),
        socketServiceProvider.overrideWithValue(socket),
        authControllerProvider.overrideWith(
          () => _PlayerAuthController(_playerSession()),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LiveGameScreen(initialGame: initialGame, embedded: true),
        ),
      ),
    ),
  );
  for (var index = 0; index < 12; index++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

GameOperationsCurrentResponse _operations({
  GameModel? liveGame,
  GameModel? checkingGame,
  GameModel? registrationGame,
  List<GameModel> queue = const [],
}) {
  final now = DateTime.now().toUtc();
  return GameOperationsCurrentResponse(
    liveGame: liveGame,
    checkingGame: checkingGame,
    registrationOpenGame: registrationGame,
    queue: queue,
    timestamp: now,
    serverNow: now,
  );
}

GameModel _readyGame() {
  return GameModel.fromOperationJson({
    'slotId': 'slot-ready',
    'sessionId': _readySessionId,
    'staticCode': 'FULL_HOUSE-S3',
    'playCode': 'BINGO-3',
    'playerStatus': 'ready',
    'rawStatus': 'READY',
    'operationMode': 'AUTO',
    'canRegister': true,
    'registrationOpen': true,
    'entryFee': '10',
    'prizePerCartela': '8',
    'prizeAmount': '100',
    'registeredCartelasCount': 0,
    'calledNumbersCount': 0,
    'gameRule': {'id': 'rule-1', 'key': 'FULL_HOUSE', 'name': 'Full House'},
  });
}

GameModel _playingGame({int calledNumbersCount = 0, DateTime? nextAutoCallAt}) {
  return GameModel.fromOperationJson({
    'slotId': 'slot-2',
    'sessionId': _sessionId,
    'staticCode': 'FULL_HOUSE-S2',
    'playCode': 'BINGO-2',
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

CalledNumberModel _calledNumber({
  required int order,
  String letter = 'B',
  int number = 7,
}) {
  return CalledNumberModel(
    id: 'cn-$order',
    sessionId: _sessionId,
    slotId: 'slot-2',
    letter: letter,
    number: number,
    order: order,
    createdAt: DateTime.utc(2026, 7, 3, 12, 0, order),
    playerStatus: 'playing',
  );
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
    createdAt: DateTime.utc(2026, 7, 3),
    updatedAt: DateTime.utc(2026, 7, 3),
    cartela: CartelaModel(
      id: 'cartela-42',
      number: 42,
      createdAt: DateTime.utc(2026, 7, 3),
      b: const ['1', '2', '3', '4', '5'],
      i: const ['16', '17', '18', '19', '20'],
      n: const ['31', '32', 'FREE', '34', '35'],
      g: const ['46', '47', '48', '49', '50'],
      o: const ['61', '62', '63', '64', '65'],
    ),
  );
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

class _PlayerAuthController extends AuthController {
  _PlayerAuthController(this.session);

  final AuthSession session;

  @override
  AuthState build() => AuthState(session: session);
}

class _SyncTestSocketService extends SocketService {
  _SyncTestSocketService()
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

class _SyncTestGamesRepository extends GamesRepository {
  _SyncTestGamesRepository() : super(ApiClient(Dio()));

  int operationsCalls = 0;
  int calledNumbersCalls = 0;
  final List<String> calledNumbersSessionIds = <String>[];
  int myCartelasCalls = 0;
  bool throwOperationsError = false;
  bool throwMyCartelasError = false;
  Duration operationsDelay = Duration.zero;
  GameOperationsCurrentResponse? operationsResponse;
  final Map<String, List<CalledNumberModel>> calledNumbersBySession =
      <String, List<CalledNumberModel>>{};
  final Map<String, List<GameCartelaModel>> myCartelasBySession =
      <String, List<GameCartelaModel>>{};

  @override
  Future<GameTimingConfigModel> getTimeConfig() async {
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
    if (operationsDelay > Duration.zero) {
      await Future<void>.delayed(operationsDelay);
    }
    if (throwOperationsError) {
      throw ApiException(message: 'Connection issue. Tap refresh.');
    }
    final response = operationsResponse;
    if (response == null) {
      throw StateError('operationsResponse was not configured');
    }
    return response;
  }

  @override
  Future<CalledNumbersSnapshot> getCalledNumbers(String sessionId) async {
    calledNumbersCalls += 1;
    calledNumbersSessionIds.add(sessionId);
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
    if (throwMyCartelasError) {
      throw ApiException(message: 'Connection issue. Tap refresh.');
    }
    return List<GameCartelaModel>.from(
      myCartelasBySession[sessionId] ?? const <GameCartelaModel>[],
    );
  }
}
