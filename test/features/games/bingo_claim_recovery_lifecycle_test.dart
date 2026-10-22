import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/core/network/api_client.dart';
import 'package:friends_bingo_app/src/core/sync/resume_sync_guard.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/game_operations_resume_cache.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_game_resume_owner_registry.dart';
import 'package:friends_bingo_app/src/core/realtime/socket_service.dart';
import 'package:friends_bingo_app/src/core/sound/game_sound_service.dart';
import 'package:friends_bingo_app/src/core/sound/sound_event.dart';
import 'package:friends_bingo_app/src/features/auth/domain/auth_session.dart';
import 'package:friends_bingo_app/src/features/auth/domain/user_profile.dart';
import 'package:friends_bingo_app/src/features/auth/application/controllers/auth_controller.dart';
import 'package:friends_bingo_app/src/features/games/data/games_repository.dart';
import 'package:friends_bingo_app/src/features/games/claims/domain/bingo_claim_source.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_numbers_snapshot.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/settings/domain/entities/feature_settings.dart';
import 'package:friends_bingo_app/src/features/settings/application/providers/feature_settings_provider.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_timing_config_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/session_winner_result_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/screens/live_game_screen.dart';
import 'package:friends_bingo_app/src/features/games/presentation/screens/big_game_screen.dart';
import 'package:friends_bingo_app/src/features/games/application/providers/current_big_game_provider.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/live_cartela_card.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/called_numbers_strip.dart';
import 'package:friends_bingo_app/src/features/games/patterns/data/models/completed_pattern_model.dart';
import 'package:friends_bingo_app/src/core/network/api_exception.dart';
import 'package:friends_bingo_app/src/features/games/claims/data/storage/bingo_claim_attempt_storage.dart';
import 'package:friends_bingo_app/src/features/games/claims/data/models/bingo_claim_result.dart';
import 'package:friends_bingo_app/src/features/games/claims/domain/bingo_claim_attempt.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/application/controllers/live_called_numbers_controller.dart';
import 'package:friends_bingo_app/src/features/games/application/controllers/live_game_host.dart';
import 'package:friends_bingo_app/src/features/games/presentation/debug/bingo_claim_diagnostics.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_socket_session_membership.dart';

class _Host implements LiveGameHost {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Storage extends BingoClaimAttemptStorage {
  final Map<String, Map<String, dynamic>> records = {};
  @override
  Future<List<Map<String, dynamic>>> load(String user, String session) async =>
      records.values
          .where((v) => v['userId'] == user && v['sessionId'] == session)
          .toList();
  @override
  Future<void> save(Map<String, dynamic> identity) async {
    records[identity['gameCartelaId'] as String] = Map.of(identity);
  }

  @override
  Future<void> remove(Map<String, dynamic> identity) async {
    final key = identity['gameCartelaId'] as String;
    if (records[key]?['claimAttemptId'] == identity['claimAttemptId']) {
      records.remove(key);
    }
  }
}

/// Simulates a connection/disk failure before the claim is ever dispatched.
class _FailSaveStorage extends BingoClaimAttemptStorage {
  @override
  Future<List<Map<String, dynamic>>> load(String user, String session) async =>
      [];
  @override
  Future<void> save(Map<String, dynamic> identity) async {
    throw StateError('Could not persist Bingo claim identity');
  }

  @override
  Future<void> remove(Map<String, dynamic> identity) async {}
}

class _Auth extends AuthController {
  @override
  AuthState build() => AuthState(
    session: AuthSession(
      accessToken: 'test-only',
      user: UserProfile(
        id: 'user-1',
        fullName: 'Test',
        phoneNumber: '000000',
        role: UserRole.player,
        status: UserStatus.active,
        createdAt: _now,
        updatedAt: _now,
      ),
    ),
  );
}

class _Socket extends Fake implements SocketService {
  final Map<String, List<SocketEventListener>> listeners = {};
  final List<String> joined = [];
  @override
  bool get isConnected => true;
  @override
  bool get hasActiveSocket => true;
  @override
  void on(String event, SocketEventListener listener) =>
      (listeners[event] ??= []).add(listener);
  @override
  void off(String event, [SocketEventListener? listener]) =>
      listeners[event]?.remove(listener);
  @override
  Future<bool> joinGame(String sessionId) async {
    joined.add(sessionId);
    return true;
  }

  @override
  void leaveGame(String sessionId) {}
  void emit(String event, dynamic payload) {
    for (final listener in List<SocketEventListener>.of(
      listeners[event] ?? [],
    )) {
      listener(payload);
    }
  }
}

class _AutoSettings extends FeatureSettingsController {
  @override
  Future<FeatureSettingsUiState> build() async => const FeatureSettingsUiState(
    settings: FeatureSettings(autoBingoGranted: true, autoBingoEnabled: true,
        effectiveAutoBingo: true),
  );
}

/// Real scheduler/drain, with only HTTP and socket transport replaced.
class _AutoRepo extends _Repo {
  _AutoRepo() {
    cards = [for (var index = 1; index <= 3; index++)
      GameCartelaModel(id: 'gc-$index', gameId: 'session-1', userId: 'user-1',
        cartelaId: 'card-gc-$index', status: GameCartelaStatus.registered,
        isWinner: false, blockedAt: null, createdAt: _now, updatedAt: _now,
        cartela: CartelaModel(
        id: 'card-gc-$index', number: 5204 + index, createdAt: _now,
        b: const ['1', '2', '3', '4', '5'],
        i: const ['16', '17', '18', '19', '20'],
        n: const ['31', '32', 'FREE', '34', '35'],
        g: const ['46', '47', '48', '49', '50'],
        o: const ['61', '62', '63', '64', '65'],
      )),
    ];
  }
  final submissions = <({String uuid, String card, BingoClaimSource source})>[];
  final pending = <String, Completer<BingoClaimResult>>{};
  bool recoveryRetryAllowed = true;
  int recoveryNotFoundResponses = 0;
  @override
  Future<CalledNumbersSnapshot> getCalledNumbers(String sessionId) async =>
      CalledNumbersSnapshot(totalCount: 5, calledNumbers: [
        for (var index = 0; index < 5; index++) CalledNumberModel(
          id: 'draw-$index', sessionId: sessionId,
          letter: ['B', 'I', 'N', 'G', 'O'][index],
          number: [1, 16, 31, 46, 61][index], order: index + 1, createdAt: _now,
        ),
      ]);
  @override
  Future<BingoClaimResult> claimBingo({required String sessionId,
    required String gameCartelaId, required String claimAttemptId,
    DateTime? clientTapAt, BingoClaimSource claimSource = BingoClaimSource.manual,
  }) {
    submissions.add((uuid: claimAttemptId, card: gameCartelaId, source: claimSource));
    claimCards[claimAttemptId] = gameCartelaId;
    if (pending[claimAttemptId]?.isCompleted == true) {
      pending[claimAttemptId] = Completer<BingoClaimResult>();
    }
    return (pending[claimAttemptId] ??= Completer<BingoClaimResult>()).future;
  }
  void finish(String uuid, BingoClaimStatus status, {bool retry = true}) {
    final cardId = claimCards[uuid]!;
    if (status == BingoClaimStatus.invalid || status == BingoClaimStatus.valid) {
      cards = cards.map((card) => card.id != cardId ? card : card.copyWith(
        status: status == BingoClaimStatus.valid ? GameCartelaStatus.winner
            : GameCartelaStatus.blocked,
        isWinner: status == BingoClaimStatus.valid,
      )).toList();
    }
    pending[uuid]!.complete(_httpResult(uuid, status, cartelaId: cardId,
        retryAllowed: retry));
  }
  @override
  Future<BingoClaimAttemptStatus> getBingoClaimAttempt({required String sessionId,
    required String claimAttemptId}) async {
    recoveryGets++;
    if (recoveryNotFoundResponses > 0) {
      recoveryNotFoundResponses--;
      throw ApiException(message: 'not yet persisted', statusCode: 404);
    }
    return _result(claimAttemptId, recoveryStatus, retry: recoveryRetryAllowed);
  }
}

class _Sound extends Fake implements GameSoundService {
  final events = <SoundEvent>[];
  @override
  Future<void> play(
    SoundEvent event, {
    String? sessionId,
    String? dedupeKey,
    Object? roundKey,
  }) async {
    events.add(event);
  }
}

class _Repo extends Fake implements GamesRepository {
  final post = Completer<BingoClaimResult>();
  int recoveryGets = 0;
  String? submittedUuid;
  final Map<String, String> claimCards = {};
  BingoClaimStatus Function(String)? recoveryResponse;
  bool failFirstGet = true;
  bool separatePosts = false;
  final Map<String, Completer<BingoClaimResult>> laterPosts = {};
  BingoClaimStatus recoveryStatus = BingoClaimStatus.failed;
  GameStatus recoveryGameStatus = GameStatus.playing;
  DateTime? recoveryWindowEndsAt;
  String? recoveryReasonCode;
  int winnerResultsGets = 0;
  List<SessionWinnerResultModel> winnerResults = [];
  Completer<List<SessionWinnerResultModel>>? pendingWinnerResults;
  GameModel currentGame = _game();
  GameModel? bigGameSnapshot;
  final Map<String, GameModel> sessionSnapshots = {};
  final Map<String, List<GameCartelaModel>> sessionCards = {};
  List<GameCartelaModel> cards = [_cartela()];
  @override
  Future<GameTimingConfigModel> getTimeConfig() async =>
      GameTimingConfigModel.fallback;
  @override
  Future<GameModel> getSessionDetail(String sessionId) async =>
      sessionSnapshots[sessionId] ?? currentGame;
  @override
  Future<GameModel?> getCurrentBigGame() async {
    return bigGameSnapshot;
  }

  @override
  Future<GameOperationsCurrentResponse> getCurrentGameOperations() async =>
      GameOperationsCurrentResponse(
        liveGame: currentGame,
        checkingGame: null,
        registrationOpenGame: null,
        queue: const [],
        timestamp: _now,
        serverNow: _now,
      );
  @override
  Future<List<GameCartelaModel>> getMyGameCartelas(String sessionId) async =>
      sessionCards[sessionId] ?? cards;
  @override
  Future<CalledNumbersSnapshot> getCalledNumbers(String sessionId) async =>
      CalledNumbersSnapshot(totalCount: 0, calledNumbers: const []);
  @override
  Future<List<SessionWinnerResultModel>> getSessionWinnerResults({
    required String sessionId,
  }) async {
    winnerResultsGets++;
    return pendingWinnerResults?.future ?? winnerResults;
  }

  @override
  Future<BingoClaimResult> claimBingo({
    required String sessionId,
    required String gameCartelaId,
    required String claimAttemptId,
    DateTime? clientTapAt,
    BingoClaimSource claimSource = BingoClaimSource.manual,
  }) {
    submittedUuid = claimAttemptId;
    claimCards[claimAttemptId] = gameCartelaId;
    if (separatePosts && claimCards.length > 1) {
      return (laterPosts[claimAttemptId] ??= Completer<BingoClaimResult>())
          .future;
    }
    return post.future;
  }

  @override
  Future<BingoClaimAttemptStatus> getBingoClaimAttempt({
    required String sessionId,
    required String claimAttemptId,
  }) async {
    recoveryGets++;
    if (failFirstGet && recoveryGets == 1) {
      throw ApiException(message: 'offline');
    }
    final result = _result(
      claimAttemptId,
      recoveryResponse?.call(claimAttemptId) ?? recoveryStatus,
      retry: true,
      gameStatus: recoveryGameStatus,
      windowEndsAt: recoveryWindowEndsAt,
      reasonCode: recoveryReasonCode,
    );
    currentGame = currentGame.copyWith(
      status: result.gameStatus,
      winnerWindowEndsAt: result.winnerWindowEndsAt,
    );
    if (result.status.isTerminal) {
      cards = cards
          .map(
            (card) => card.id != claimCards[claimAttemptId]
                ? card
                : card.copyWith(
                    status: result.gameCartelaStatus,
                    isWinner: result.isWinner,
                  ),
          )
          .toList();
    }
    return result;
  }
}

Future<ProviderContainer> _pumpLive(
  WidgetTester tester,
  _Repo repo,
  _Socket socket, {
  _Sound? sound,
  bool realBigGameParent = false,
  bool autoBingo = false,
}) async {
  ResumeSyncGuard.resetForTest();
  GameOperationsResumeCache.shared.resetForTest();
  LiveGameResumeOwnerRegistry.resetForTest();
  SharedPreferences.setMockInitialValues({});
  dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost.invalid');
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) => handler.reject(
        DioException(
          requestOptions: request,
          error: 'No network permitted in this test',
        ),
      ),
    ),
  );
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(_Auth.new),
      if (autoBingo) featureSettingsControllerProvider.overrideWith(_AutoSettings.new),
      gamesRepositoryProvider.overrideWithValue(repo),
      apiClientProvider.overrideWithValue(ApiClient(dio)),
      socketServiceProvider.overrideWithValue(socket),
      gameSoundServiceProvider.overrideWithValue(sound ?? _Sound()),
    ],
  );
  addTearDown(() async {
    // Settle preference writes in this test's fake-async zone before the next
    // mounted-screen test restores another persisted scope.
    if (!realBigGameParent) {
      await BingoClaimAttemptStorage().load('user-1', 'session-1');
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    container.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: realBigGameParent
              ? const BigGameScreen()
              : LiveGameScreen(
                  gameId: 'session-1',
                  initialGame: repo.currentGame,
                  embedded: true,
                ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  return container;
}

final _now = DateTime.utc(2026, 10, 8);
GameModel _game({
  GameCategory category = GameCategory.normal,
  GameStatus status = GameStatus.playing,
  int round = 1,
  String session = 'session-1',
}) => GameModel(
  id: 'slot-1',
  sessionId: session,
  staticCode: 'N-1',
  playCode: 'PLAY-1',
  name: 'Test',
  gameRule: GameRuleModel(id: 'r1', key: 'ONE_LINE', name: 'Line'),
  gameType: 'ONE_LINE',
  entryFee: '10',
  prizePerCartela: '0',
  companyFeePerCartela: '10',
  prizeAmount: '100',
  companyRevenue: '0',
  status: status,
  playOrder: 1,
  startedAt: _now,
  finishedAt: null,
  createdAt: _now,
  updatedAt: _now,
  registeredCartelasCount: 1,
  calledNumbersCount: 5,
  registrationOpen: false,
  canRegister: false,
  category: category,
  roundIndex: round,
  roundCount: 3,
);
GameCartelaModel _cartela([String id = 'gc-1']) => GameCartelaModel(
  id: id,
  gameId: 'session-1',
  userId: 'user-1',
  cartelaId: 'card-$id',
  status: GameCartelaStatus.registered,
  isWinner: false,
  blockedAt: null,
  createdAt: _now,
  updatedAt: _now,
  cartela: CartelaModel(id: 'card-$id', number: 5205, createdAt: _now),
);
BingoClaimAttemptStatus _result(
  String uuid,
  BingoClaimStatus status, {
  bool retry = false,
  GameStatus gameStatus = GameStatus.playing,
  DateTime? windowEndsAt,
  String? reasonCode,
}) => BingoClaimAttemptStatus(
  claimAttemptId: uuid,
  status: status,
  gameCartelaStatus: status == BingoClaimStatus.valid
      ? GameCartelaStatus.winner
      : status == BingoClaimStatus.invalid
      ? GameCartelaStatus.blocked
      : GameCartelaStatus.registered,
  gameStatus: gameStatus,
  isWinner: status == BingoClaimStatus.valid,
  retryAllowed: retry,
  winnerWindowEndsAt: windowEndsAt,
  reasonCode: reasonCode,
);
bool _can(
  LiveCalledNumbersController c, {
  GameModel? game,
  GameCartelaModel? cartela,
  bool countdown = false,
}) => c.canClaimBingoForCartela(
  game: game ?? _game(),
  gameCartela: cartela ?? _cartela(),
  winnerWindowExpired: false,
  isCountdownLocked: countdown,
);
BingoClaimAttempt _begin(
  LiveCalledNumbersController c, [
  String uuid = 'attempt-original',
  String card = 'gc-1',
]) => c.beginClaimAttempt(
  gameCartelaId: card,
  claimAttemptId: uuid,
  roundIndex: 1,
)!;

BingoClaimResult _httpResult(
  String uuid,
  BingoClaimStatus status, {
  GameStatus gameStatus = GameStatus.playing,
  DateTime? windowEndsAt,
  String claimId = 'server-claim',
  String cartelaId = 'gc-1',
  bool? retryAllowed,
}) => BingoClaimResult(
  claim: BingoClaimModel(
    id: claimId,
    claimAttemptId: uuid,
    gameId: 'session-1',
    userId: 'user-1',
    gameCartelaId: cartelaId,
    status: status,
    checkedPattern: null,
    reason: null,
    createdAt: _now,
    checkedAt: _now,
  ),
  progress: null,
  isWinner: status == BingoClaimStatus.valid,
  gameStatus: gameStatus,
  gameCartelaStatus: status == BingoClaimStatus.valid
      ? GameCartelaStatus.winner
      : status == BingoClaimStatus.invalid
      ? GameCartelaStatus.blocked
      : GameCartelaStatus.registered,
  retryAllowed: retryAllowed ?? status == BingoClaimStatus.failed,
  winnerWindowEndsAt: windowEndsAt,
  hasNextAutoCallAt: true,
);

void _expectBingoAvailable(WidgetTester tester, bool enabled) {
  final buttons = find.widgetWithText(FilledButton, 'BINGO');
  if (buttons.evaluate().isEmpty) {
    expect(
      enabled,
      isFalse,
      reason: 'BINGO is unavailable in terminal presentation',
    );
  } else {
    expect(
      tester.widget<FilledButton>(buttons.first).onPressed,
      enabled ? isNotNull : isNull,
    );
  }
}

Map<String, dynamic> _terminalPayload(
  String uuid, {
  bool includeAttemptId = true,
}) => {
  'sessionId': 'session-1',
  'gameCartelaId': 'gc-1',
  'userId': 'user-1',
  if (includeAttemptId) 'claimAttemptId': uuid,
  'roundIndex': 1,
  'claimId': 'server-claim',
  'cartelaNumber': 5205,
  'winnerWindowEndsAt': DateTime.now()
      .add(const Duration(minutes: 5))
      .toIso8601String(),
  'completedPatterns': [
    {
      'type': 'ROW',
      'numbers': [1, 2, 3, 4, 5],
      'cells': [
        [0, 0],
        [0, 1],
        [0, 2],
        [0, 3],
        [0, 4],
      ],
    },
  ],
  'reasonCode': 'PATTERN_INCOMPLETE',
  'reason': 'Incomplete called pattern',
  'nextAutoCallAt': null,
};

SessionWinnerResultModel _canonicalWinner() => SessionWinnerResultModel(
  gameCartelaId: 'gc-1',
  cartelaId: 'card-gc-1',
  cartelaNumber: 5205,
  amount: '100',
  columns: const [],
  completedPatterns: const [
    CompletedPatternModel(
      type: 'COLUMN',
      numbers: [7],
      highlightCellIndexes: {7},
    ),
  ],
);

void main() {
  for (final recovery in ['HTTP', 'GET recovery', 'same-UUID recovery POST']) {
    final sameUuidPost = recovery == 'same-UUID recovery POST';
    final extraPost = sameUuidPost ? 1 : 0;
    testWidgets('AUTO retryable FAILED $recovery releases same-ball key, preserves siblings and UUID fencing', (tester) async {
      final repo = _AutoRepo()..recoveryStatus = BingoClaimStatus.checking;
      final socket = _Socket();
      await _pumpLive(tester, repo, socket, autoBingo: true);
      final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await host.runResumeSync(allowCachedOperations: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(repo.submissions, hasLength(1));
      final first = repo.submissions.first;
      expect(first.source, BingoClaimSource.auto);
      if (recovery != 'HTTP') {
        if (sameUuidPost) repo.recoveryNotFoundResponses = 2;
        repo.pending[first.uuid]!.completeError(ApiException(message: 'ambiguous timeout'));
        await tester.pump(const Duration(milliseconds: 100));
        expect(repo.submissions, hasLength(1), reason: 'Ambiguous UUID stays pending');
        expect(host.controllers.calledNumbers.claimAttemptFor(first.card)?.claimAttemptId, first.uuid);
        socket.emit('connect', null);
        await tester.pump(const Duration(milliseconds: 100));
        if (sameUuidPost) {
          expect(repo.submissions, hasLength(2));
          expect(repo.submissions.last.uuid, first.uuid);
          expect(repo.submissions.last.source, BingoClaimSource.auto);
          repo.finish(first.uuid, BingoClaimStatus.failed);
        } else {
          repo.recoveryStatus = BingoClaimStatus.failed;
          socket.emit('game:bingo_claim_failed', {
            'sessionId': 'session-1', 'gameCartelaId': first.card,
            'claimAttemptId': first.uuid, 'roundIndex': 1,
          });
        }
      } else {
        repo.finish(first.uuid, BingoClaimStatus.failed);
      }
      await tester.pump(const Duration(milliseconds: 100));
      for (var i = 1; i <= 2; i++) {
        expect(repo.submissions, hasLength(i + 1 + extraPost));
        final sibling = repo.submissions[i + extraPost];
        expect(sibling.card, isNot(first.card));
        repo.finish(sibling.uuid, BingoClaimStatus.invalid);
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(repo.submissions, hasLength(3 + extraPost), reason: 'No retry loop in the current drain');
      expect(host.controllers.calledNumbers.calledNumbers.last.order, 5);
      repo.recoveryStatus = BingoClaimStatus.checking;
      // Independent, existing reconnect reconciliation; no additional draw.
      socket.emit('connect', null);
      await host.runResumeSync(allowCachedOperations: false);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(repo.submissions, hasLength(4 + extraPost));
      final retry = repo.submissions.last;
      expect(retry.card, first.card);
      expect(retry.uuid, isNot(first.uuid));
      expect(host.controllers.calledNumbers.calledNumbers.last.order, 5);
      socket.emit('connect', null);
      socket.emit('connect', null);
      await tester.pump(const Duration(milliseconds: 100));
      expect(repo.submissions, hasLength(4 + extraPost));
      repo.finish(retry.uuid, BingoClaimStatus.invalid);
      await tester.pump(const Duration(milliseconds: 100));
    });
  }
  for (final boundary in ['retry denied', 'terminal cartela', 'expired window', 'disabled']) {
    testWidgets('AUTO same-ball retry respects $boundary', (tester) async {
      final repo = _AutoRepo();
      repo.cards = repo.cards.take(1).toList();
      final socket = _Socket();
      final container = await _pumpLive(tester, repo, socket, autoBingo: true);
      final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await host.runResumeSync(allowCachedOperations: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(repo.submissions, hasLength(1));
      repo.finish(repo.submissions.single.uuid,
        boundary == 'terminal cartela' ? BingoClaimStatus.invalid : BingoClaimStatus.failed,
        retry: boundary != 'retry denied');
      await tester.pump(const Duration(milliseconds: 100));
      expect(repo.submissions, hasLength(1), reason: 'Terminal callback cannot retry itself');
      if (boundary == 'expired window') {
        host.game = repo.currentGame.copyWith(status: GameStatus.winnerWindow,
          winnerWindowEndsAt: DateTime.utc(2020));
        host.controllers.countdown.winnerWindowEndsAt = DateTime.utc(2020);
        final settings = container.read(featureSettingsControllerProvider.notifier);
        settings.applySocketSettings(const FeatureSettings(featureSettingsVersion: 1));
        settings.applySocketSettings(const FeatureSettings(autoBingoGranted: true,
          autoBingoEnabled: true, effectiveAutoBingo: true, featureSettingsVersion: 2));
        expect(repo.submissions, hasLength(1));
        expect(host.controllers.calledNumbers.autoBingoQueue, isEmpty);
        // Keep this test on the scheduling boundary, before review navigation.
        host.game = repo.currentGame;
        host.controllers.countdown.winnerWindowEndsAt = null;
        return;
      }
      if (boundary == 'disabled') {
        container.read(featureSettingsControllerProvider.notifier).applySocketSettings(
          const FeatureSettings(autoBingoGranted: true, featureSettingsVersion: 1));
        await tester.pump();
      }
      unawaited(host.runResumeSync(allowCachedOperations: false));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      socket.emit('connect', null);
      await tester.pump(const Duration(milliseconds: 100));
      expect(repo.submissions, hasLength(1));
    });
  }
  Map<String, dynamic> foreignClaim(String attempt, {
    String cartela = 'foreign-1', int number = 9001,
    String session = 'session-1', int round = 1,
  }) => {
    'sessionId': session,
    'gameCartelaId': cartela,
    'claimAttemptId': attempt,
    'cartelaNumber': number,
    'roundIndex': round,
    'nextAutoCallAt': null,
  };

  testWidgets('foreign FAILED clears only its matching marker and releases balls', (tester) async {
    final repo = _Repo();
    final socket = _Socket();
    await _pumpLive(tester, repo, socket);
    final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
    final payload = foreignClaim('foreign-a');
    socket.emit('game:bingo_checking', payload);
    socket.emit('game:number_called', {
      'id': 'foreign-held-ball', 'sessionId': 'session-1',
      'gameSessionId': 'session-1', 'letter': 'B', 'number': 4,
      'order': 1, 'createdAt': _now.toIso8601String(),
    });
    await tester.pump();
    expect(host.controllers.review.sessionCheckingCartelaNumbers, [9001]);
    expect(host.controllers.calledNumbers.bufferedCalledNumbers, hasLength(1));
    socket.emit('game:bingo_claim_failed', payload);
    await tester.pump();
    expect(host.controllers.review.sessionCheckingCartelaNumbers, isEmpty);
    expect(host.controllers.calledNumbers.bufferedCalledNumbers, isEmpty);
    expect(host.controllers.calledNumbers.calledNumbers.map((n) => n.number), [4]);
    expect(repo.recoveryGets, 0, reason: 'Foreign claims must not use the private recovery GET');
    socket.emit('game:bingo_claim_failed', payload);
    socket.emit('game:bingo_checking', payload);
    await tester.pump();
    expect(host.controllers.review.sessionCheckingCartelaNumbers, isEmpty);
  });

  testWidgets('foreign FAILED cannot clear newer, unrelated, or owned attempts', (tester) async {
    final socket = _Socket();
    await _pumpLive(tester, _Repo(), socket);
    final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
    final c = host.controllers.calledNumbers;
    final owned = _begin(c, 'owned-pending');
    final old = foreignClaim('foreign-a');
    final newer = foreignClaim('foreign-b');
    final other = foreignClaim('foreign-c', cartela: 'foreign-2', number: 9002);
    socket.emit('game:bingo_checking', old);
    socket.emit('game:bingo_checking', newer);
    socket.emit('game:bingo_checking', other);
    socket.emit('game:bingo_claim_failed', old);
    socket.emit('game:bingo_claim_failed', {...newer}..remove('claimAttemptId'));
    await tester.pump();
    expect(host.controllers.review.sessionCheckingCartelaNumbers, [9001, 9002]);
    socket.emit('game:bingo_claim_failed', newer);
    await tester.pump();
    expect(host.controllers.review.sessionCheckingCartelaNumbers, [9002]);
    expect(c.claimAttemptFor('gc-1'), same(owned));
    expect(c.claimStripHoldActive, isTrue);
    socket.emit('game:bingo_checking', old);
    await tester.pump();
    expect(host.controllers.review.sessionCheckingCartelaNumbers, [9002]);
  });

  testWidgets('foreign checking events reject old sessions and rounds', (tester) async {
    final socket = _Socket();
    final repo = _Repo()..currentGame = _game(category: GameCategory.chainGame, round: 2);
    await _pumpLive(tester, repo, socket);
    final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
    final current = foreignClaim('round-two', round: 2);
    socket.emit('game:bingo_checking', current);
    socket.emit('game:bingo_claim_failed', {...current, 'sessionId': 'old-session'});
    socket.emit('game:bingo_claim_failed', {...current, 'roundIndex': 1});
    socket.emit('game:bingo_checking', foreignClaim('round-one', round: 1, number: 9002));
    await tester.pump();
    expect(host.controllers.review.sessionCheckingCartelaNumbers, [9001]);
    socket.emit('game:bingo_claim_failed', current);
    await tester.pump();
    expect(host.controllers.review.sessionCheckingCartelaNumbers, isEmpty);
  });

  testWidgets('stage3a: Unauthorized join is not successful membership', (
    tester,
  ) async {
    final membership = LiveSocketSessionMembership();
    var joins = 0;
    Future<bool> unauthorized(String _) async {
      joins++;
      return joins > 1;
    }

    membership.apply('session-1', join: unauthorized, leave: (_) {});
    await tester.pump();
    expect(membership.joinedSessionId, isNull);
    await tester.pump(const Duration(seconds: 1));
    expect(joins, 2);
    expect(membership.joinedSessionId, 'session-1');
    membership.dispose();
  });

  testWidgets(
    'stage3a: real BigGameScreen explicit round handoff beats terminal seed',
    (tester) async {
      final next =
          _game(
            category: GameCategory.bigGame,
            status: GameStatus.ready,
            round: 2,
            session: 'session-2',
          ).copyWith(
            canRegister: true,
            registrationOpen: true,
            scheduledStartAt: DateTime.now().add(const Duration(minutes: 3)),
            previousRound: BigGamePreviousRoundSummary(
              sessionId: 'session-1',
              roundIndex: 1,
              status: GameStatus.finished,
              finishedAt: DateTime.now(),
              registeredCartelasCount: 1,
              playerOwnedPreviousRound: true,
            ),
          );
      final finished =
          _game(
            category: GameCategory.bigGame,
            status: GameStatus.finished,
          ).copyWith(
            finishedAt: next.previousRound!.finishedAt,
            nextRoundRegistration: next,
          );
      final playing = _game(category: GameCategory.bigGame);
      final repo = _Repo()
        ..currentGame = playing
        ..bigGameSnapshot = playing;
      repo.sessionSnapshots.addAll({'session-1': playing, 'session-2': next});
      final carried = _cartela();
      repo.sessionCards['session-2'] = [
        GameCartelaModel(
          id: 'gc-next',
          gameId: 'session-2',
          userId: carried.userId,
          cartelaId: carried.cartelaId,
          status: GameCartelaStatus.registered,
          isWinner: false,
          blockedAt: null,
          createdAt: _now,
          updatedAt: _now,
          cartela: carried.cartela,
        ),
      ];
      final socket = _Socket();
      final container = await _pumpLive(
        tester,
        repo,
        socket,
        realBigGameParent: true,
      );
      expect(find.byType(BigGameScreen), findsOneWidget);
      final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
      repo.currentGame = finished;
      repo.sessionSnapshots['session-1'] = finished;
      repo.bigGameSnapshot = next;
      expect(host.initialGame!.sessionId, 'session-1');
      expect(repo.bigGameSnapshot!.sessionId, 'session-2');
      var completed = false;
      unawaited(
        host
            .runInitialLoad(
              showLoading: false,
              allowTerminalTransition: true,
              advanceTarget: next,
            )
            .then((_) => completed = true),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(completed, isTrue);
      expect(host.game!.sessionId, 'session-2');
      expect(host.game!.status, GameStatus.ready);
      expect(host.game!.displayRoundIndex, 2);
      expect(host.myCartelas.single.gameId, 'session-2');
      expect(host.myCartelas.single.status, GameCartelaStatus.registered);
      repo.currentGame = next;
      completed = false;
      unawaited(
        host.runInitialLoad(showLoading: false).then((_) => completed = true),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(completed, isTrue);
      expect(
        host.game!.sessionId,
        'session-2',
        reason: 'refresh must follow the adopted round',
      );
      unawaited(container.read(currentBigGameProvider.notifier).refresh());
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(
        identical(tester.state(find.byType(LiveGameScreen)), host),
        isTrue,
      );
      expect(host.game!.sessionId, 'session-2');
      expect(
        container.read(currentBigGameProvider).value!.sessionId,
        'session-2',
      );
      socket.emit('game:finished', {
        'sessionId': 'session-1',
        'category': 'BIG_GAME',
        'status': 'FINISHED',
        'roundIndex': 1,
      });
      socket.emit('game:bingo_invalid', _terminalPayload('old-round-attempt'));
      await tester.pump();
      expect(host.game!.sessionId, 'session-2');
      expect(host.game!.status, GameStatus.ready);
      completed = false;
      unawaited(
        host
            .runResumeSync(allowCachedOperations: false)
            .then((_) => completed = true),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(completed, isTrue);
      expect(
        host.game!.sessionId,
        'session-2',
        reason: 'resume must fetch the adopted session',
      );
    },
  );

  TestWidgetsFlutterBinding.ensureInitialized();

  for (final category in GameCategory.values) {
    for (final viaGet in [false, true]) {
      for (final expired in [false, true]) {
        testWidgets('corrective: $category ${viaGet ? "GET" : "HTTP"} FAILED '
            '${expired ? "expired" : "eligible"} winner-window button', (
          tester,
        ) async {
          final repo = _Repo()
            ..failFirstGet = false
            ..currentGame = _game(category: category)
            ..recoveryGameStatus = GameStatus.winnerWindow;
          await _pumpLive(tester, repo, _Socket());
          final host =
              tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
          _expectBingoAvailable(tester, true);
          await tester.tap(find.widgetWithText(FilledButton, 'BINGO').first);
          await tester.pump();
          final deadline = host.countdownNow().add(
            Duration(seconds: expired ? -10 : 300),
          );
          if (expired) {
            // Expiry may enter the existing finished-review flow. Keep its
            // winner-results request in flight while testing the button.
            repo.pendingWinnerResults =
                Completer<List<SessionWinnerResultModel>>();
          }
          repo.recoveryWindowEndsAt = deadline;
          repo.currentGame = repo.currentGame.copyWith(
            status: GameStatus.winnerWindow,
            winnerWindowEndsAt: deadline,
          );
          if (viaGet) {
            repo.post.completeError(ApiException(message: 'ambiguous POST'));
          } else {
            repo.post.complete(
              _httpResult(
                repo.submittedUuid!,
                BingoClaimStatus.failed,
                gameStatus: GameStatus.winnerWindow,
                windowEndsAt: deadline,
              ),
            );
          }
          await tester.pump();
          await tester.pump();
          expect(
            host.game?.status,
            expired
                ? anyOf(GameStatus.winnerWindow, GameStatus.finished)
                : GameStatus.winnerWindow,
          );
          if (host.game?.status == GameStatus.winnerWindow) {
            expect(host.game?.winnerWindowEndsAt, deadline);
            expect(host.controllers.countdown.winnerWindowEndsAt, deadline);
          } else if (host.controllers.countdown.winnerWindowEndsAt != null) {
            // Big Game may retain the expired deadline during final handoff.
            expect(host.controllers.countdown.winnerWindowEndsAt, deadline);
          }
          _expectBingoAvailable(tester, !expired);
          expect(repo.recoveryGets, viaGet ? 1 : 0);
        });
      }
    }
  }

  for (final viaGet in [false, true]) {
    for (final protected in [
      GameStatus.finished,
      GameStatus.noWinner,
      GameStatus.winnerWindow,
    ]) {
      testWidgets(
        'corrective: ${viaGet ? "GET" : "HTTP"} cannot reopen $protected',
        (tester) async {
          final repo = _Repo()
            ..failFirstGet = false
            ..recoveryGameStatus = GameStatus.winnerWindow;
          await _pumpLive(tester, repo, _Socket());
          final host =
              tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
          tester
              .widget<LiveCartelaCard>(find.byType(LiveCartelaCard).first)
              .onClaimBingo();
          await tester.pump();
          if (protected == GameStatus.winnerWindow) {
            repo.pendingWinnerResults =
                Completer<List<SessionWinnerResultModel>>();
          }
          final oldDeadline = host.countdownNow().subtract(
            const Duration(seconds: 10),
          );
          host.markNeedsBuild(
            () => host.game = host.game?.copyWith(
              status: protected,
              winnerWindowEndsAt: oldDeadline,
            ),
          );
          final incoming = host.countdownNow().add(const Duration(minutes: 5));
          repo.recoveryWindowEndsAt = incoming;
          if (viaGet) {
            repo.post.completeError(ApiException(message: 'ambiguous POST'));
          } else {
            repo.post.complete(
              _httpResult(
                repo.submittedUuid!,
                BingoClaimStatus.failed,
                gameStatus: GameStatus.winnerWindow,
                windowEndsAt: incoming,
              ),
            );
          }
          await tester.pump();
          await tester.pump();
          expect(
            host.game?.status,
            protected == GameStatus.winnerWindow
                ? anyOf(GameStatus.winnerWindow, GameStatus.finished)
                : protected,
          );
          if (host.game?.status == GameStatus.winnerWindow) {
            expect(host.game?.winnerWindowEndsAt, oldDeadline);
          }
          _expectBingoAvailable(tester, false);
        },
      );
    }
  }

  for (final status in [BingoClaimStatus.valid, BingoClaimStatus.invalid]) {
    testWidgets(
      'corrective: GET $status enriches deferred presentation once; late HTTP is inert',
      (tester) async {
        final repo = _Repo()
          ..failFirstGet = false
          ..recoveryStatus = status
          ..recoveryGameStatus = status == BingoClaimStatus.valid
              ? GameStatus.winnerWindow
              : GameStatus.playing
          ..recoveryWindowEndsAt = DateTime.now().add(
            const Duration(minutes: 5),
          )
          ..recoveryReasonCode = 'PATTERN_INCOMPLETE';
        final socket = _Socket();
        final sound = _Sound();
        await _pumpLive(tester, repo, socket, sound: sound);
        sound.events.clear();
        final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
        tester
            .widget<LiveCartelaCard>(find.byType(LiveCartelaCard).first)
            .onClaimBingo();
        await tester.pump();
        final uuid = repo.submittedUuid!;
        final event = status == BingoClaimStatus.valid
            ? 'game:winner_window_started'
            : 'game:bingo_invalid';
        final payload = _terminalPayload(uuid);
        socket.emit(event, payload);
        socket.emit('game:bingo_claim_failed', {
          'sessionId': 'session-1',
          'gameCartelaId': 'gc-1',
          'claimAttemptId': uuid,
        });
        await tester.pump();
        expect(repo.post.isCompleted, isFalse);
        expect(
          host.myCartelas.single.status,
          status == BingoClaimStatus.valid
              ? GameCartelaStatus.winner
              : GameCartelaStatus.blocked,
        );
        if (status == BingoClaimStatus.valid) {
          expect(
            sound.events.where((e) => e == SoundEvent.validBingo).length,
            1,
          );
          expect(
            sound.events.where((e) => e == SoundEvent.winnerWindow).length,
            1,
          );
          expect(
            host.controllers.review.winnerCartelaDisplay.hasPatternsFor('gc-1'),
            isTrue,
          );
          expect(
            host
                .controllers
                .review
                .winnerCartelaDisplay
                .patternCellsByGameCartelaId['gc-1'],
            {0, 1, 2, 3, 4},
          );
        } else {
          expect(
            host.controllers.calledNumbers.blockedReasonCodeFor('gc-1'),
            'PATTERN_INCOMPLETE',
          );
          expect(
            host.controllers.calledNumbers.blockedServerReasonFor('gc-1'),
            'Incomplete called pattern',
          );
          expect(sound.events, isNot(contains(SoundEvent.validBingo)));
        }
        final beforeSounds = List<SoundEvent>.of(sound.events);
        final beforeGets = repo.recoveryGets;
        repo.post.complete(
          _httpResult(
            uuid,
            status,
            gameStatus: repo.recoveryGameStatus,
            windowEndsAt: repo.recoveryWindowEndsAt,
          ),
        );
        await tester.pump();
        socket.emit(event, payload);
        await tester.pump();
        expect(sound.events, beforeSounds);
        expect(repo.recoveryGets, beforeGets);
      },
    );
  }

  testWidgets(
    'corrective: UUID-less deferred event waits for late HTTP claim-id proof',
    (tester) async {
      final repo = _Repo()
        ..failFirstGet = false
        ..recoveryStatus = BingoClaimStatus.valid
        ..recoveryGameStatus = GameStatus.winnerWindow
        ..recoveryWindowEndsAt = DateTime.now().add(const Duration(minutes: 5));
      final socket = _Socket();
      final sound = _Sound();
      await _pumpLive(tester, repo, socket, sound: sound);
      final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
      tester
          .widget<LiveCartelaCard>(find.byType(LiveCartelaCard).first)
          .onClaimBingo();
      await tester.pump();
      final uuid = repo.submittedUuid!;
      socket.emit(
        'game:winner_window_started',
        _terminalPayload(uuid, includeAttemptId: false),
      );
      socket.emit('game:bingo_claim_failed', {
        'sessionId': 'session-1',
        'gameCartelaId': 'gc-1',
        'claimAttemptId': uuid,
      });
      await tester.pump();
      expect(
        host.controllers.review.winnerCartelaDisplay.hasPatternsFor('gc-1'),
        isFalse,
      );
      final sounds = List<SoundEvent>.of(sound.events);
      repo.post.complete(
        _httpResult(
          uuid,
          BingoClaimStatus.valid,
          gameStatus: GameStatus.winnerWindow,
          windowEndsAt: repo.recoveryWindowEndsAt,
        ),
      );
      await tester.pump();
      expect(
        host
            .controllers
            .review
            .winnerCartelaDisplay
            .patternCellsByGameCartelaId['gc-1'],
        {0, 1, 2, 3, 4},
      );
      expect(sound.events, sounds);
      expect(repo.winnerResultsGets, 0);
    },
  );

  testWidgets(
    'corrective: uncertain event uses canonical patterns, not socket data',
    (tester) async {
      final repo = _Repo()
        ..failFirstGet = false
        ..recoveryStatus = BingoClaimStatus.valid
        ..recoveryGameStatus = GameStatus.winnerWindow
        ..recoveryWindowEndsAt = DateTime.now().add(const Duration(minutes: 5))
        ..winnerResults = [_canonicalWinner()];
      final socket = _Socket();
      await _pumpLive(tester, repo, socket);
      final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
      tester
          .widget<LiveCartelaCard>(find.byType(LiveCartelaCard).first)
          .onClaimBingo();
      await tester.pump();
      socket.emit(
        'game:winner_window_started',
        _terminalPayload(repo.submittedUuid!, includeAttemptId: false),
      );
      repo.post.completeError(ApiException(message: 'HTTP lost'));
      await tester.pump();
      expect(
        host
            .controllers
            .review
            .winnerCartelaDisplay
            .patternCellsByGameCartelaId['gc-1'],
        {7},
      );
      expect(repo.winnerResultsGets, 1);
      final gets = repo.recoveryGets;
      socket.emit(
        'game:winner_window_started',
        _terminalPayload(repo.submittedUuid!, includeAttemptId: false),
      );
      await tester.pump();
      expect(repo.recoveryGets, gets);
    },
  );

  for (final mismatch in ['claimAttemptId', 'userId', 'roundIndex']) {
    testWidgets(
      'corrective: wrong $mismatch cannot overwrite deferred terminal',
      (tester) async {
        final repo = _Repo()
          ..failFirstGet = false
          ..recoveryStatus = BingoClaimStatus.valid
          ..recoveryGameStatus = GameStatus.winnerWindow
          ..recoveryWindowEndsAt = DateTime.now().add(
            const Duration(minutes: 5),
          );
        final socket = _Socket();
        await _pumpLive(tester, repo, socket);
        final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
        tester
            .widget<LiveCartelaCard>(find.byType(LiveCartelaCard).first)
            .onClaimBingo();
        await tester.pump();
        final payload = _terminalPayload(repo.submittedUuid!);
        socket.emit('game:winner_window_started', payload);
        socket.emit('game:winner_window_started', {
          ...payload,
          mismatch: mismatch == 'roundIndex' ? 99 : 'another-identity',
          'completedPatterns': [],
        });
        repo.post.completeError(ApiException(message: 'HTTP lost'));
        await tester.pump();
        expect(
          host
              .controllers
              .review
              .winnerCartelaDisplay
              .patternCellsByGameCartelaId['gc-1'],
          {0, 1, 2, 3, 4},
        );
      },
    );
  }

  for (final category in [GameCategory.chainGame, GameCategory.bigGame]) {
    testWidgets(
      'corrective: deferred $category historical outcome cannot enrich newer round',
      (tester) async {
        final repo = _Repo()..currentGame = _game(category: category);
        final socket = _Socket();
        final sound = _Sound();
        await _pumpLive(tester, repo, socket, sound: sound);
        final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
        tester
            .widget<LiveCartelaCard>(find.byType(LiveCartelaCard).first)
            .onClaimBingo();
        await tester.pump();
        socket.emit(
          'game:winner_window_started',
          _terminalPayload(repo.submittedUuid!),
        );
        final sounds = List<SoundEvent>.of(sound.events);
        host.markNeedsBuild(
          () => host.game = _game(
            category: category,
            round: 2,
            session: category == GameCategory.bigGame
                ? 'session-next'
                : 'session-1',
          ),
        );
        repo.currentGame = host.game!;
        repo.post.complete(
          _httpResult(
            repo.submittedUuid!,
            BingoClaimStatus.valid,
            gameStatus: GameStatus.winnerWindow,
          ),
        );
        await tester.pump();
        expect(host.game?.status, GameStatus.playing);
        expect(host.game?.displayRoundIndex, 2);
        expect(
          host.controllers.review.winnerCartelaDisplay.hasPatternsFor('gc-1'),
          isFalse,
        );
        expect(sound.events, sounds);
      },
    );
  }

  testWidgets(
    'corrective: canonical presentation cannot cross a Big Game session change',
    (tester) async {
      final pending = Completer<List<SessionWinnerResultModel>>();
      final repo = _Repo()
        ..failFirstGet = false
        ..recoveryStatus = BingoClaimStatus.valid
        ..currentGame = _game(category: GameCategory.bigGame)
        ..recoveryGameStatus = GameStatus.winnerWindow
        ..recoveryWindowEndsAt = DateTime.now().add(const Duration(minutes: 5))
        ..pendingWinnerResults = pending;
      final socket = _Socket();
      await _pumpLive(tester, repo, socket);
      final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
      tester
          .widget<LiveCartelaCard>(find.byType(LiveCartelaCard).first)
          .onClaimBingo();
      await tester.pump();
      socket.emit(
        'game:winner_window_started',
        _terminalPayload(repo.submittedUuid!, includeAttemptId: false),
      );
      repo.post.completeError(ApiException(message: 'HTTP lost'));
      await tester.pump();
      expect(repo.winnerResultsGets, 1);
      host.markNeedsBuild(
        () => host.game = _game(
          category: GameCategory.bigGame,
          round: 2,
          session: 'session-next',
        ),
      );
      pending.complete([_canonicalWinner()]);
      await tester.pump();
      expect(
        host.controllers.review.winnerCartelaDisplay.hasPatternsFor('gc-1'),
        isFalse,
      );
    },
  );

  testWidgets(
    'corrective: called-number strip refresh reconciles without waiting for retry timer',
    (tester) async {
      final repo = _Repo();
      await _pumpLive(tester, repo, _Socket());
      tester
          .widget<LiveCartelaCard>(find.byType(LiveCartelaCard).first)
          .onClaimBingo();
      await tester.pump();
      repo.post.completeError(ApiException(message: 'ambiguous POST'));
      await tester.pump();
      expect(repo.recoveryGets, 1);
      tester
          .widget<CalledNumbersStrip>(find.byType(CalledNumbersStrip).first)
          .onRefreshCalledNumbers!();
      await tester.pump();
      expect(repo.recoveryGets, 2);
      _expectBingoAvailable(tester, true);
    },
  );

  testWidgets(
    'live screen: historical Chain VALID refreshes the new round before unlocking',
    (tester) async {
      final repo = _Repo()
        ..failFirstGet = false
        ..recoveryStatus = BingoClaimStatus.valid
        ..currentGame = _game(category: GameCategory.chainGame);
      await _pumpLive(tester, repo, _Socket());
      final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
      tester
          .widget<LiveCartelaCard>(find.byType(LiveCartelaCard).first)
          .onClaimBingo();
      await tester.pump();
      repo.currentGame = _game(category: GameCategory.chainGame, round: 2)
          .copyWith(
            roundPausedUntil: DateTime.now().add(const Duration(seconds: 30)),
          );
      repo.post.completeError(ApiException(message: 'lost old round response'));
      await tester.pump();
      await tester.pump();
      expect(host.game!.displayRoundIndex, 2);
      expect(host.myCartelas.single.status, GameCartelaStatus.registered);
      expect(
        host.controllers.calledNumbers.activeClaimAttemptIdByCartelaId,
        isEmpty,
      );
      expect(
        host.controllers.calledNumbers.canClaimBingoForCartela(
          game: host.game,
          gameCartela: host.myCartelas.single,
          winnerWindowExpired: false,
          isCountdownLocked: false,
        ),
        isFalse,
      );
      await BingoClaimAttemptStorage().load('user-1', 'session-1');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  for (final status in [BingoClaimStatus.valid, BingoClaimStatus.invalid]) {
    testWidgets('live screen: successful HTTP $status adds no recovery GET', (
      tester,
    ) async {
      final repo = _Repo();
      final socket = _Socket();
      await _pumpLive(tester, repo, socket);
      final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
      tester
          .widget<LiveCartelaCard>(find.byType(LiveCartelaCard).first)
          .onClaimBingo();
      await tester.pump();
      final uuid = repo.submittedUuid!;
      final winner = status == BingoClaimStatus.valid;
      final cartelaStatus = winner
          ? GameCartelaStatus.winner
          : GameCartelaStatus.blocked;
      final gameStatus = winner ? GameStatus.winnerWindow : GameStatus.playing;
      socket.emit('game:bingo_checking', {
        'sessionId': 'session-1',
        'gameCartelaId': 'gc-1',
        'claimAttemptId': uuid,
        'cartelaNumber': 5205,
        'nextAutoCallAt': null,
      });
      socket
          .emit(winner ? 'game:winner_window_started' : 'game:bingo_invalid', {
            'sessionId': 'session-1',
            'gameCartelaId': 'gc-1',
            'claimId': 'claim-1',
            'cartelaNumber': 5205,
            'nextAutoCallAt': null,
            'winnerWindowEndsAt': DateTime.now()
                .add(const Duration(minutes: 5))
                .toIso8601String(),
          });
      repo.currentGame = _game(status: gameStatus);
      repo.cards = [
        _cartela().copyWith(status: cartelaStatus, isWinner: winner),
      ];
      repo.post.complete(
        BingoClaimResult(
          claim: BingoClaimModel(
            id: 'claim-1',
            claimAttemptId: uuid,
            gameId: 'session-1',
            userId: 'user-1',
            gameCartelaId: 'gc-1',
            status: status,
            checkedPattern: 'ONE_LINE',
            reason: null,
            createdAt: _now,
            checkedAt: _now,
          ),
          progress: null,
          isWinner: winner,
          gameStatus: gameStatus,
          gameCartelaStatus: cartelaStatus,
          hasNextAutoCallAt: true,
          winnerWindowEndsAt: DateTime.now().add(const Duration(minutes: 5)),
        ),
      );
      await tester.pump();
      expect(host.myCartelas.single.status, cartelaStatus);
      expect(repo.recoveryGets, 0);
      expect(
        host.controllers.calledNumbers.activeClaimAttemptIdByCartelaId,
        isEmpty,
      );
      await BingoClaimAttemptStorage().load('user-1', 'session-1');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  testWidgets(
    'live screen: stale HTTP cannot clear or relock a newer submitted UUID',
    (tester) async {
      final repo = _Repo()
        ..failFirstGet = false
        ..separatePosts = true;
      final socket = _Socket();
      await _pumpLive(tester, repo, socket);
      final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
      tester
          .widget<LiveCartelaCard>(find.byType(LiveCartelaCard).first)
          .onClaimBingo();
      await tester.pump();
      final original = repo.submittedUuid;
      socket.emit('game:bingo_claim_failed', {
        'sessionId': 'session-1',
        'gameCartelaId': 'gc-1',
        'claimAttemptId': original,
        'retryAllowed': true,
      });
      await tester.pump(const Duration(milliseconds: 100));
      tester
          .widget<LiveCartelaCard>(find.byType(LiveCartelaCard).first)
          .onClaimBingo();
      await tester.pump();
      final newer = repo.submittedUuid;
      expect(newer, isNot(original));
      repo.post.completeError(ApiException(message: 'old HTTP timeout'));
      await tester.pump();
      final c = host.controllers.calledNumbers;
      expect(c.activeClaimAttemptIdByCartelaId['gc-1'], newer);
      expect(c.claimingCartelaIds, contains('gc-1'));
      expect(c.claimRecoveryFailedCartelaIds, isEmpty);
      expect(repo.recoveryGets, 1);
      await BingoClaimAttemptStorage().load('user-1', 'session-1');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  for (final allowed in [true, false]) {
    testWidgets(
      'ALREADY_RESOLVED retryAllowed=$allowed respects explicit permission',
      (tester) async {
        final c = LiveCalledNumbersController(
          _Host(),
          claimStorage: _Storage(),
          claimNow: tester.binding.clock.now,
          recoverClaim: (_, uuid) async =>
              _result(uuid, BingoClaimStatus.alreadyResolved, retry: allowed),
        );
        await c.bindClaimRecoveryScope('user-1', 'session-1');
        final attempt = _begin(c);
        await c.recoverClaimAttempt(attempt);
        expect(_can(c), allowed);
        expect(_can(c, game: _game(status: GameStatus.finished)), isFalse);
        c.dispose();
      },
    );
  }

  testWidgets(
    'a GET returning a different UUID cannot resolve the active claim',
    (tester) async {
      final c = LiveCalledNumbersController(
        _Host(),
        claimStorage: _Storage(),
        claimNow: tester.binding.clock.now,
        recoverClaim: (_, uuid) async =>
            _result('different-uuid', BingoClaimStatus.failed, retry: true),
      );
      await c.bindClaimRecoveryScope('user-1', 'session-1');
      final attempt = _begin(c);
      await c.recoverClaimAttempt(attempt);
      expect(c.activeClaimAttemptIdByCartelaId['gc-1'], attempt.claimAttemptId);
      expect(_can(c), isFalse);
      c.dispose();
    },
  );

  testWidgets(
    'live screen: reconnect rejoins and resume/refresh reconcile independently',
    (tester) async {
      final repo = _Repo()
        ..failFirstGet = false
        ..recoveryStatus = BingoClaimStatus.checking;
      final socket = _Socket();
      await _pumpLive(tester, repo, socket);
      tester
          .widget<LiveCartelaCard>(find.byType(LiveCartelaCard).first)
          .onClaimBingo();
      await tester.pump();
      repo.post.completeError(ApiException(message: 'timeout'));
      await tester.pump();
      final before = repo.recoveryGets;
      final joins = socket.joined.length;
      socket.emit('disconnect', null);
      socket.emit('connect', null);
      await tester.pump();
      expect(socket.joined.length, joins + 1);
      expect(repo.recoveryGets, greaterThan(before));
      socket.emit('connect', null);
      await tester.pump();
      expect(socket.joined.length, joins + 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final paused = repo.recoveryGets;
      await tester.pump(const Duration(seconds: 30));
      expect(repo.recoveryGets, paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(repo.recoveryGets, greaterThan(paused));
      final resumed = repo.recoveryGets;
      unawaited(LiveGameResumeOwnerRegistry.runMasterRefreshIfActive());
      await tester.pump();
      expect(repo.recoveryGets, greaterThan(resumed));
      await BingoClaimAttemptStorage().load('user-1', 'session-1');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'live screen: deferred terminals for two cards flush after recovered CHECKING',
    (tester) async {
      final calls = <String, int>{};
      final repo = _Repo()
        ..failFirstGet = false
        ..cards = [_cartela(), _cartela('gc-2')];
      repo.recoveryResponse = (uuid) {
        calls[uuid] = (calls[uuid] ?? 0) + 1;
        return calls[uuid] == 1
            ? BingoClaimStatus.checking
            : BingoClaimStatus.invalid;
      };
      final socket = _Socket();
      await _pumpLive(tester, repo, socket);
      final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
      final rendered = tester
          .widgetList<LiveCartelaCard>(find.byType(LiveCartelaCard))
          .toList();
      for (final card in rendered) {
        card.onClaimBingo();
      }
      await tester.pump();
      for (final card in rendered) {
        socket.emit('game:bingo_invalid', {
          'sessionId': 'session-1',
          'gameCartelaId': card.gameCartela.id,
          'claimId': 'claim-${card.gameCartela.id}',
          'reasonCode': 'INVALID_PATTERN',
        });
      }
      expect(host.controllers.calledNumbers.claimingCartelaIds.length, 2);
      repo.post.completeError(ApiException(message: 'timeout'));
      await tester.pump();
      await tester.pump();
      expect(calls.length, 2);
      expect(calls.values, everyElement(2));
      expect(
        host.myCartelas.map((card) => card.status),
        everyElement(GameCartelaStatus.blocked),
      );
      expect(
        host.controllers.calledNumbers.activeClaimAttemptIdByCartelaId,
        isEmpty,
      );
      await BingoClaimAttemptStorage().load('user-1', 'session-1');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  for (final status in [BingoClaimStatus.valid, BingoClaimStatus.invalid]) {
    testWidgets(
      'live screen: recovery $status preserves terminal cartela flow',
      (tester) async {
        final repo = _Repo()
          ..failFirstGet = false
          ..recoveryStatus = status;
        if (status == BingoClaimStatus.valid) {
          repo.recoveryGameStatus = GameStatus.winnerWindow;
        }
        await _pumpLive(tester, repo, _Socket());
        final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
        tester
            .widget<LiveCartelaCard>(find.byType(LiveCartelaCard).first)
            .onClaimBingo();
        await tester.pump();
        repo.post.completeError(ApiException(message: 'lost HTTP response'));
        await tester.pump();
        expect(
          host.myCartelas.single.status,
          status == BingoClaimStatus.valid
              ? GameCartelaStatus.winner
              : GameCartelaStatus.blocked,
        );
        expect(
          host.controllers.calledNumbers.canClaimBingoForCartela(
            game: host.game,
            gameCartela: host.myCartelas.single,
            winnerWindowExpired: false,
            isCountdownLocked: false,
          ),
          isFalse,
        );
        await BingoClaimAttemptStorage().load('user-1', 'session-1');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }

  testWidgets(
    'live screen: FAILED retryAllowed with finished server game never enables Bingo',
    (tester) async {
      final repo = _Repo()
        ..failFirstGet = false
        ..recoveryGameStatus = GameStatus.finished;
      await _pumpLive(tester, repo, _Socket());
      final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
      tester
          .widget<LiveCartelaCard>(find.byType(LiveCartelaCard).first)
          .onClaimBingo();
      await tester.pump();
      repo.post.completeError(ApiException(message: 'timeout'));
      await tester.pump();
      expect(host.game!.status, GameStatus.finished);
      expect(
        host.controllers.calledNumbers.activeClaimAttemptIdByCartelaId,
        isEmpty,
      );
      expect(
        host.controllers.calledNumbers.canClaimBingoForCartela(
          game: host.game,
          gameCartela: host.myCartelas.single,
          winnerWindowExpired: false,
          isCountdownLocked: false,
        ),
        isFalse,
      );
      await BingoClaimAttemptStorage().load('user-1', 'session-1');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'live screen regression: POST timeout and failed GET recover original UUID',
    (tester) async {
      final repo = _Repo();
      await _pumpLive(tester, repo, _Socket());
      final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
      final controller = host.controllers.calledNumbers;
      expect(
        controller.canClaimBingoForCartela(
          game: host.game,
          gameCartela: host.myCartelas.single,
          winnerWindowExpired: false,
          isCountdownLocked: false,
        ),
        isTrue,
      );
      final bingoButton = find.widgetWithText(FilledButton, 'BINGO').first;
      expect(tester.widget<FilledButton>(bingoButton).onPressed, isNotNull);
      await tester.ensureVisible(bingoButton);
      await tester.tap(bingoButton);
      await tester.pump();
      expect(repo.submittedUuid, isNotNull);
      final original = repo.submittedUuid;
      repo.post.completeError(ApiException(message: 'HTTP timeout'));
      await tester.pump();
      expect(repo.recoveryGets, 1);
      expect(controller.claimRecoveryFailedCartelaIds, contains('gc-1'));
      expect(controller.activeClaimAttemptIdByCartelaId['gc-1'], original);
      expect(controller.isConfirmingClaim('gc-1'), isTrue);
      await tester.pump();
      // CONFIRMING shows checking label — not a silent gray BINGO.
      expect(find.text('Checking bingo claim'), findsWidgets);
      expect(find.widgetWithText(FilledButton, 'BINGO'), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(repo.recoveryGets, 2);
      await tester.pump();
      expect(find.widgetWithText(FilledButton, 'BINGO'), findsWidgets);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'BINGO').first)
            .onPressed,
        isNotNull,
      );
      expect(controller.claimRecoveryFailedCartelaIds, isEmpty);
      expect(controller.activeClaimAttemptIdByCartelaId, isEmpty);
      expect(
        controller.canClaimBingoForCartela(
          game: host.game,
          gameCartela: host.myCartelas.single,
          winnerWindowExpired: false,
          isCountdownLocked: false,
        ),
        isTrue,
      );
      await BingoClaimAttemptStorage().load('user-1', 'session-1');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'live screen: FAILED socket GET resolves before late HTTP error without relock',
    (tester) async {
      final repo = _Repo()..failFirstGet = false;
      final socket = _Socket();
      await _pumpLive(tester, repo, socket);
      final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
      final c = host.controllers.calledNumbers;
      expect(
        c.canClaimBingoForCartela(
          game: host.game,
          gameCartela: host.myCartelas.single,
          winnerWindowExpired: false,
          isCountdownLocked: false,
        ),
        isTrue,
        reason:
            'scopeLoading=${c.claimScopeLoading} active=${c.activeClaimAttemptIdByCartelaId} '
            'pending=${c.pendingClaimCartelaIds} game=${host.game?.status} count=${host.game?.calledNumbersCount} error=${c.claimRecoveryStorageError}',
      );
      tester
          .widget<LiveCartelaCard>(find.byType(LiveCartelaCard).first)
          .onClaimBingo();
      await tester.pump();
      expect(repo.submittedUuid, isNotNull);
      expect(socket.listeners['game:bingo_claim_failed'], isNotEmpty);
      socket.emit('game:bingo_claim_failed', {
        'sessionId': 'session-1',
        'gameCartelaId': 'gc-1',
        'claimAttemptId': repo.submittedUuid,
        'retryAllowed': true,
      });
      await tester.pump();
      expect(
        host.controllers.calledNumbers.activeClaimAttemptIdByCartelaId,
        isEmpty,
      );
      repo.post.completeError(ApiException(message: 'late HTTP timeout'));
      await tester.pump();
      expect(repo.recoveryGets, 1);
      expect(
        host.controllers.calledNumbers.claimRecoveryFailedCartelaIds,
        isEmpty,
      );
      expect(host.controllers.calledNumbers.pendingClaimCartelaIds, isEmpty);
      expect(
        host.controllers.calledNumbers.canClaimBingoForCartela(
          game: host.game,
          gameCartela: host.myCartelas.single,
          winnerWindowExpired: false,
          isCountdownLocked: false,
        ),
        isTrue,
      );
      await BingoClaimAttemptStorage().load('user-1', 'session-1');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'regression: ambiguous POST, failed GET, later FAILED unlocks only eligible Bingo',
    (tester) async {
      var gets = 0;
      final uuids = <String>[];
      final c = LiveCalledNumbersController(
        _Host(),
        claimStorage: _Storage(),
        claimNow: tester.binding.clock.now,
        recoverClaim: (session, uuid) async {
          gets++;
          uuids.add(uuid);
          if (gets == 1) throw ApiException(message: 'offline');
          return _result(uuid, BingoClaimStatus.failed, retry: true);
        },
      );
      await c.bindClaimRecoveryScope('user-1', 'session-1');
      final attempt = _begin(c);
      await c.persistClaimAttempt(attempt);
      expect(_can(c), isFalse);
      // The production HTTP catch uses this same recovery entry point.
      await c.recoverClaimAttempt(attempt);
      c.finishClaimSubmission(attempt);
      expect(c.claimRecoveryFailedCartelaIds, contains('gc-1'));
      expect(_can(c), isFalse);
      await tester.pump(const Duration(milliseconds: 999));
      expect(gets, 1);
      expect(_can(c), isFalse);
      await tester.pump(const Duration(milliseconds: 1));
      expect(gets, 2);
      expect(uuids, ['attempt-original', 'attempt-original']);
      expect(c.activeClaimAttemptIdByCartelaId, isEmpty);
      expect(c.claimRecoveryFailedCartelaIds, isEmpty);
      expect(c.pendingClaimCartelaIds, isEmpty);
      expect(_can(c), isTrue);
      expect(_can(c, game: _game(status: GameStatus.finished)), isFalse);
      expect(_can(c, countdown: true), isFalse);
      final next = _begin(c, 'attempt-new');
      expect(next.claimAttemptId, isNot(attempt.claimAttemptId));
      c.dispose();
    },
  );

  testWidgets(
    'FAILED socket before HTTP error cannot relock or touch a newer attempt',
    (tester) async {
      var gets = 0;
      final c = LiveCalledNumbersController(
        _Host(),
        claimStorage: _Storage(),
        recoverClaim: (_, uuid) async {
          gets++;
          throw ApiException(message: 'late HTTP recovery');
        },
      );
      await c.bindClaimRecoveryScope('user-1', 'session-1');
      final old = _begin(c);
      expect(
        c.applyAuthoritativeClaimStatus(
          old,
          BingoClaimStatus.failed,
          retryAllowed: true,
        ),
        isTrue,
      );
      await c.recoverClaimAttempt(old); // Late HTTP catch.
      c.finishClaimSubmission(old); // Late HTTP finally.
      expect(gets, 0);
      expect(_can(c), isTrue);
      final next = _begin(c, 'attempt-new');
      expect(
        c.applyAuthoritativeClaimStatus(
          old,
          BingoClaimStatus.failed,
          retryAllowed: true,
        ),
        isFalse,
      );
      c.finishClaimSubmission(old);
      expect(c.activeClaimAttemptIdByCartelaId['gc-1'], next.claimAttemptId);
      expect(c.claimingCartelaIds, contains('gc-1'));
      expect(_can(c), isFalse);
      c.dispose();
    },
  );

  for (final status in [BingoClaimStatus.checking, BingoClaimStatus.pending]) {
    testWidgets('$status never becomes READY from elapsed time', (
      tester,
    ) async {
      var gets = 0;
      final c = LiveCalledNumbersController(
        _Host(),
        claimStorage: _Storage(),
        claimNow: tester.binding.clock.now,
        recoverClaim: (_, uuid) async {
          gets++;
          return _result(uuid, status);
        },
      );
      await c.bindClaimRecoveryScope('user-1', 'session-1');
      final attempt = _begin(c);
      await c.recoverClaimAttempt(attempt);
      c.finishClaimSubmission(attempt);
      await tester.pump(const Duration(seconds: 30));
      expect(gets, greaterThan(1));
      expect(_can(c), isFalse);
      expect(c.activeClaimAttemptIdByCartelaId['gc-1'], attempt.claimAttemptId);
      c.dispose();
    });
  }

  testWidgets('404 retries GET with bounded backoff, never POST or READY', (
    tester,
  ) async {
    var gets = 0;
    final c = LiveCalledNumbersController(
      _Host(),
      claimStorage: _Storage(),
      claimNow: tester.binding.clock.now,
      recoverClaim: (_, uuid) async {
        gets++;
        throw ApiException(
          message: 'Bingo claim attempt not found',
          statusCode: 404,
        );
      },
    );
    await c.bindClaimRecoveryScope('user-1', 'session-1');
    final attempt = _begin(c);
    await c.recoverClaimAttempt(attempt);
    c.finishClaimSubmission(attempt);
    expect(c.isConfirmingClaim('gc-1'), isTrue);
    expect(c.confirmingOrClaimingCartelaIds, contains('gc-1'));
    expect(c.pendingClaimCartelaIds, contains('gc-1'));
    for (final delay in [1, 2, 4, 8, 15, 15]) {
      final previous = gets;
      await tester.pump(Duration(seconds: delay - 1));
      expect(gets, previous);
      await tester.pump(const Duration(seconds: 1));
      expect(gets, previous + 1);
      expect(_can(c), isFalse);
      expect(c.isConfirmingClaim('gc-1'), isTrue);
    }
    expect(c.activeClaimAttemptIdByCartelaId['gc-1'], attempt.claimAttemptId);
    // Without a resubmit hook, UUID is retained — never auto READY on 404.
    expect(attempt.sameUuidPostRetries, 0);
    c.dispose();
  });

  testWidgets(
    'GET 404 then same-UUID POST VALID unlocks without minting a new attempt',
    (tester) async {
      var gets = 0;
      var posts = 0;
      String? postedUuid;
      final c = LiveCalledNumbersController(
        _Host(),
        claimStorage: _Storage(),
        claimNow: tester.binding.clock.now,
        recoverClaim: (_, uuid) async {
          gets++;
          throw ApiException(
            message: 'Bingo claim attempt not found',
            statusCode: 404,
          );
        },
        resubmitClaim: (attempt) async {
          posts++;
          postedUuid = attempt.claimAttemptId;
          return _httpResult(
            attempt.claimAttemptId,
            BingoClaimStatus.valid,
            gameStatus: GameStatus.winnerWindow,
            windowEndsAt: DateTime.now().add(const Duration(minutes: 1)),
          );
        },
      );
      await c.bindClaimRecoveryScope('user-1', 'session-1');
      final attempt = _begin(c);
      c.finishClaimSubmission(attempt);
      await c.recoverClaimAttempt(attempt);
      expect(posts, 1);
      expect(postedUuid, attempt.claimAttemptId);
      expect(gets, 1);
      expect(attempt.sameUuidPostRetries, 1);
      expect(c.activeClaimAttemptIdByCartelaId, isEmpty);
      expect(c.isConfirmingClaim('gc-1'), isFalse);
      expect(c.claimAttemptFor('gc-1'), isNull);
      c.dispose();
    },
  );

  testWidgets(
    'only one GET in flight; background pauses; foreground reconciles',
    (tester) async {
      var gets = 0;
      var response = Completer<BingoClaimAttemptStatus>();
      final c = LiveCalledNumbersController(
        _Host(),
        claimStorage: _Storage(),
        claimNow: tester.binding.clock.now,
        recoverClaim: (_, uuid) {
          gets++;
          return response.future;
        },
      );
      await c.bindClaimRecoveryScope('user-1', 'session-1');
      final attempt = _begin(c);
      final first = c.recoverClaimAttempt(attempt);
      expect(identical(c.recoverClaimAttempt(attempt), first), isTrue);
      c.reconcileClaimAttempts(); // Reconnect / refresh while GET is pending.
      expect(gets, 1);
      c.setClaimRecoveryForeground(false);
      response.complete(
        _result(attempt.claimAttemptId, BingoClaimStatus.checking),
      );
      await first;
      await tester.pump(const Duration(minutes: 1));
      expect(gets, 1);
      response = Completer<BingoClaimAttemptStatus>();
      c.setClaimRecoveryForeground(true);
      expect(gets, 2);
      response.complete(
        _result(attempt.claimAttemptId, BingoClaimStatus.failed, retry: true),
      );
      await tester.pump();
      expect(_can(c), isTrue);
      c.dispose();
    },
  );

  testWidgets('old GET and timer cannot mutate new attempt', (tester) async {
    final oldGet = Completer<BingoClaimAttemptStatus>();
    var gets = 0;
    final c = LiveCalledNumbersController(
      _Host(),
      claimStorage: _Storage(),
      claimNow: tester.binding.clock.now,
      recoverClaim: (_, uuid) {
        gets++;
        return oldGet.future;
      },
    );
    await c.bindClaimRecoveryScope('user-1', 'session-1');
    final old = _begin(c);
    final pending = c.recoverClaimAttempt(old);
    c.applyAuthoritativeClaimStatus(
      old,
      BingoClaimStatus.failed,
      retryAllowed: true,
    );
    final next = _begin(c, 'new-uuid');
    oldGet.completeError(ApiException(message: 'old network error'));
    await pending;
    await tester.pump(const Duration(minutes: 2));
    expect(gets, 1);
    expect(c.activeClaimAttemptIdByCartelaId['gc-1'], next.claimAttemptId);
    expect(c.claimRecoveryFailedCartelaIds, isEmpty);
    expect(c.claimingCartelaIds, contains('gc-1'));
    c.dispose();
  });

  testWidgets('simultaneous claims keep separate locks and shared holds', (
    tester,
  ) async {
    final c = LiveCalledNumbersController(_Host(), claimStorage: _Storage());
    await c.bindClaimRecoveryScope('user-1', 'session-1');
    final one = _begin(c, 'one', 'gc-1');
    final two = _begin(c, 'two', 'gc-2');
    c.applyAuthoritativeClaimStatus(
      one,
      BingoClaimStatus.failed,
      retryAllowed: true,
    );
    expect(c.claimStripHoldActive, isTrue);
    expect(c.claimingCartelaIds, {'gc-2'});
    expect(_can(c, cartela: _cartela('gc-2')), isFalse);
    c.finishClaimSubmission(one);
    expect(c.claimStripHoldActive, isTrue);
    c.applyAuthoritativeClaimStatus(
      two,
      BingoClaimStatus.invalid,
      retryAllowed: false,
    );
    expect(c.claimStripHoldActive, isFalse);
    c.dispose();
  });

  testWidgets('FAILED retry denied remains unavailable across remount', (
    tester,
  ) async {
    final storage = _Storage();
    final c = LiveCalledNumbersController(_Host(), claimStorage: storage);
    await c.bindClaimRecoveryScope('user-1', 'session-1');
    final attempt = _begin(c);
    await c.persistClaimAttempt(attempt);
    c.applyAuthoritativeClaimStatus(
      attempt,
      BingoClaimStatus.failed,
      retryAllowed: false,
    );
    await tester.pump();
    expect(_can(c), isFalse);
    c.dispose();
    final remount = LiveCalledNumbersController(_Host(), claimStorage: storage);
    await remount.bindClaimRecoveryScope('user-1', 'session-1');
    expect(_can(remount), isFalse);
    expect(remount.claimAttemptFor('gc-1')!.terminal, isTrue);
    remount.dispose();
  });

  testWidgets(
    'real persistence restores UUID; late cleanup cannot erase a newer UUID',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = BingoClaimAttemptStorage();
      final c = LiveCalledNumbersController(_Host(), claimStorage: storage);
      await c.bindClaimRecoveryScope('user-1', 'session-1');
      final old = _begin(c);
      await c.persistClaimAttempt(old);
      c.dispose();
      final remount = LiveCalledNumbersController(
        _Host(),
        claimStorage: storage,
        recoverClaim: (_, uuid) async =>
            _result(uuid, BingoClaimStatus.checking),
      );
      await remount.bindClaimRecoveryScope('user-1', 'session-1');
      expect(
        remount.activeClaimAttemptIdByCartelaId['gc-1'],
        old.claimAttemptId,
      );
      expect(_can(remount), isFalse);
      final restored = remount.claimAttemptFor('gc-1')!;
      remount.applyAuthoritativeClaimStatus(
        restored,
        BingoClaimStatus.failed,
        retryAllowed: true,
      );
      final next = _begin(remount, 'new-uuid');
      await remount.persistClaimAttempt(next);
      await storage.remove(old.identity);
      expect(
        (await storage.load('user-1', 'session-1')).single['claimAttemptId'],
        'new-uuid',
      );
      expect(await storage.load('user-2', 'session-1'), isEmpty);
      expect(await storage.load('user-1', 'session-2'), isEmpty);
      remount.dispose();
    },
  );

  testWidgets(
    'account switch invalidates old GET and does not recover another user',
    (tester) async {
      final response = Completer<BingoClaimAttemptStatus>();
      final c = LiveCalledNumbersController(
        _Host(),
        claimStorage: _Storage(),
        recoverClaim: (_, uuid) => response.future,
      );
      await c.bindClaimRecoveryScope('user-1', 'session-1');
      final old = _begin(c);
      await c.persistClaimAttempt(old);
      final pending = c.recoverClaimAttempt(old);
      await c.bindClaimRecoveryScope('user-2', 'session-1');
      final next = _begin(c, 'user-2-uuid');
      response.complete(_result(old.claimAttemptId, BingoClaimStatus.invalid));
      await pending;
      expect(c.activeClaimAttemptIdByCartelaId['gc-1'], next.claimAttemptId);
      expect(c.claimOutcomeMatchesView(old, _game()), isFalse);
      await c.bindClaimRecoveryScope(null, null);
      expect(
        c.beginClaimAttempt(
          gameCartelaId: 'gc-1',
          claimAttemptId: 'guest',
          roundIndex: 1,
        ),
        isNull,
      );
      c.dispose();
    },
  );

  for (final category in GameCategory.values) {
    testWidgets(
      '$category preserves winner, BLOCKED and eligible retry outcomes',
      (tester) async {
        final c = LiveCalledNumbersController(
          _Host(),
          claimStorage: _Storage(),
        );
        await c.bindClaimRecoveryScope('user-1', 'session-1');
        final attempt = _begin(c);
        for (final status in [
          BingoClaimStatus.valid,
          BingoClaimStatus.invalid,
        ]) {
          final cards = c.cartelasAfterClaimRecovery(
            attempt: attempt,
            result: _result(attempt.claimAttemptId, status),
            game: _game(category: category),
            cartelas: [_cartela()],
          );
          expect(
            cards.single.status,
            status == BingoClaimStatus.valid
                ? GameCartelaStatus.winner
                : GameCartelaStatus.blocked,
          );
          expect(
            _can(
              c,
              game: _game(category: category),
              cartela: cards.single,
            ),
            isFalse,
          );
        }
        c.applyAuthoritativeClaimStatus(
          attempt,
          BingoClaimStatus.failed,
          retryAllowed: true,
        );
        expect(_can(c, game: _game(category: category)), isTrue);
        expect(
          _can(
            c,
            game: _game(category: category, status: GameStatus.finished),
          ),
          isFalse,
        );
        c.dispose();
      },
    );
  }

  testWidgets(
    'Chain later round and Big Game later session reject old outcomes',
    (tester) async {
      final c = LiveCalledNumbersController(_Host(), claimStorage: _Storage());
      await c.bindClaimRecoveryScope('user-1', 'session-1');
      final attempt = _begin(c);
      expect(
        c.claimOutcomeMatchesView(
          attempt,
          _game(category: GameCategory.chainGame, round: 2),
        ),
        isFalse,
      );
      expect(
        c.claimOutcomeMatchesView(
          attempt,
          _game(category: GameCategory.bigGame, session: 'session-next'),
        ),
        isFalse,
      );
      final original = [_cartela()];
      expect(
        identical(
          c.cartelasAfterClaimRecovery(
            attempt: attempt,
            result: _result(attempt.claimAttemptId, BingoClaimStatus.valid),
            game: _game(category: GameCategory.chainGame, round: 2),
            cartelas: original,
          ),
          original,
        ),
        isTrue,
      );
      c.dispose();
    },
  );

  test(
    'genuine reconnect rejoins same room once; uninterrupted apply does not',
    () {
      final membership = LiveSocketSessionMembership();
      final joined = <String>[];
      final left = <String>[];
      void apply(String? session) => membership.apply(
        session,
        join: (id) async {
          joined.add(id);
          return true;
        },
        leave: left.add,
      );
      apply('session-1');
      apply('session-1');
      expect(joined, ['session-1']);
      membership.onDisconnected();
      membership.onConnected();
      apply('session-1');
      apply('session-1');
      expect(joined, ['session-1', 'session-1']);
      expect(left, isEmpty);
      apply('session-2');
      expect(left, ['session-1']);
      expect(joined.last, 'session-2');
    },
  );

  testWidgets(
    'connection failure before dispatch cancels the unsent claim; no POST is ever sent',
    (tester) async {
      final c = LiveCalledNumbersController(
        _Host(),
        claimStorage: _FailSaveStorage(),
        claimNow: tester.binding.clock.now,
      );
      await c.bindClaimRecoveryScope('user-1', 'session-1');
      final attempt = _begin(c);
      // Held while persisting, mirroring the UI lock before the POST fires.
      expect(_can(c), isFalse);
      var threw = false;
      try {
        await c.persistClaimAttempt(attempt);
      } catch (_) {
        threw = true;
        // This is exactly the _claimBingo catch path for a pre-POST failure.
        expect(c.isCurrentClaimAttempt(attempt), isTrue);
        c.cancelUnsentClaim(attempt);
      }
      expect(threw, isTrue);
      expect(c.activeClaimAttemptIdByCartelaId, isEmpty);
      expect(c.claimingCartelaIds, isEmpty);
      expect(c.confirmingOrClaimingCartelaIds, isEmpty);
      // Never ambiguous, never retained — the claim never reached the network.
      expect(c.claimRecoveryFailedCartelaIds, isEmpty);
      expect(_can(c), isTrue);
      c.dispose();
    },
  );

  testWidgets(
    'same-UUID retry budget exhausted falls back to CONFIRMING + backoff, never auto-READY',
    (tester) async {
      var gets = 0;
      var posts = 0;
      final c = LiveCalledNumbersController(
        _Host(),
        claimStorage: _Storage(),
        claimNow: tester.binding.clock.now,
        recoverClaim: (_, uuid) async {
          gets++;
          throw ApiException(
            message: 'Bingo claim attempt not found',
            statusCode: 404,
          );
        },
        resubmitClaim: (attempt) async {
          posts++;
          throw ApiException(message: 'still unreachable');
        },
      );
      await c.bindClaimRecoveryScope('user-1', 'session-1');
      final attempt = _begin(c);
      c.finishClaimSubmission(attempt);
      await c.recoverClaimAttempt(attempt);
      expect(posts, 1);
      expect(attempt.sameUuidPostRetries, 1);
      expect(_can(c), isFalse);
      await tester.pump(const Duration(seconds: 1)); // backoff[0]
      expect(gets, 2);
      expect(posts, 2);
      expect(attempt.sameUuidPostRetries, 2);
      expect(_can(c), isFalse);
      await tester.pump(const Duration(seconds: 2)); // backoff[1]
      expect(gets, 3);
      // Budget (2) exhausted: no third same-UUID POST — only bounded GET backoff.
      expect(posts, 2);
      expect(attempt.sameUuidPostRetries, 2);
      expect(_can(c), isFalse);
      expect(c.isConfirmingClaim('gc-1'), isTrue);
      expect(c.activeClaimAttemptIdByCartelaId['gc-1'], attempt.claimAttemptId);
      c.dispose();
    },
  );

  testWidgets(
    'diagnostics correlate every stage by claimAttemptId and never log sensitive data',
    (tester) async {
      BingoClaimDiagnostics.clearForTest();
      const uuid = 'diag-attempt-1';
      BingoClaimDiagnostics.record(
        event: 'bingo.tap',
        claimAttemptId: uuid,
        sessionId: 'session-1',
        cartelaId: 'gc-1',
        state: 'claiming',
      );
      BingoClaimDiagnostics.record(
        event: 'bingo.post.start',
        claimAttemptId: uuid,
        sessionId: 'session-1',
        cartelaId: 'gc-1',
        elapsedMs: 5,
        state: 'post_in_flight',
      );
      BingoClaimDiagnostics.record(
        event: 'bingo.post.error',
        claimAttemptId: uuid,
        sessionId: 'session-1',
        cartelaId: 'gc-1',
        elapsedMs: 9000,
        dioType: 'receiveTimeout',
        detail: 'Could not reach the server. Please try again.',
        state: 'ambiguous',
      );
      BingoClaimDiagnostics.record(
        event: 'bingo.recovery.start',
        claimAttemptId: uuid,
        sessionId: 'session-1',
        cartelaId: 'gc-1',
        state: 'confirming',
      );
      BingoClaimDiagnostics.record(
        event: 'bingo.recovery.result',
        claimAttemptId: uuid,
        sessionId: 'session-1',
        cartelaId: 'gc-1',
        statusCode: 404,
        detail: 'Bingo claim attempt not found',
        state: 'get_error',
      );
      BingoClaimDiagnostics.record(
        event: 'bingo.retry.start',
        claimAttemptId: uuid,
        sessionId: 'session-1',
        cartelaId: 'gc-1',
        retryCount: 1,
        state: 'same_uuid_post',
      );
      BingoClaimDiagnostics.record(
        event: 'bingo.retry.result',
        claimAttemptId: uuid,
        sessionId: 'session-1',
        cartelaId: 'gc-1',
        claimStatus: 'valid',
        retryCount: 1,
        state: 'same_uuid_ok',
      );
      BingoClaimDiagnostics.record(
        event: 'bingo.terminal',
        claimAttemptId: uuid,
        sessionId: 'session-1',
        cartelaId: 'gc-1',
        claimStatus: 'valid',
        state: 'applied_http',
      );
      BingoClaimDiagnostics.record(
        event: 'bingo.state.transition',
        claimAttemptId: uuid,
        sessionId: 'session-1',
        cartelaId: 'gc-1',
        elapsedMs: 9500,
        retryCount: 1,
        state: 'terminal',
      );
      final log = BingoClaimDiagnostics.exportText(claimAttemptId: uuid);
      final lines = log.trim().split('\n');
      expect(lines.length, 9);
      for (final line in lines) {
        expect(line, contains('claimAttemptId=$uuid'));
      }
      const requiredEvents = [
        'bingo.tap',
        'bingo.post.start',
        'bingo.post.error',
        'bingo.recovery.start',
        'bingo.recovery.result',
        'bingo.retry.start',
        'bingo.retry.result',
        'bingo.terminal',
        'bingo.state.transition',
      ];
      for (final event in requiredEvents) {
        expect(log, contains('event=$event'));
      }
      const forbiddenSubstrings = [
        'bearer ',
        'password',
        'accesstoken',
        'refreshtoken',
        'authorization',
      ];
      final lowered = log.toLowerCase();
      for (final needle in forbiddenSubstrings) {
        expect(lowered, isNot(contains(needle)));
      }
      BingoClaimDiagnostics.clearForTest();
    },
  );

  testWidgets(
    'proven non-delivery (connectionTimeout POST + connection-level GET) auto-clears without a server round trip',
    (tester) async {
      var gets = 0;
      final c = LiveCalledNumbersController(
        _Host(),
        claimStorage: _Storage(),
        claimNow: tester.binding.clock.now,
        recoverClaim: (_, uuid) async {
          gets++;
          throw ApiException(
            message: 'Could not reach the server. Please try again.',
            dioExceptionType: 'connectionError',
          );
        },
      );
      await c.bindClaimRecoveryScope('user-1', 'session-1');
      final attempt = _begin(c);
      // Simulates the original POST failing with DioExceptionType.connectionTimeout.
      attempt.postConnectNeverCompleted = true;
      c.finishClaimSubmission(attempt);
      await c.recoverClaimAttempt(attempt);
      expect(gets, 1);
      expect(c.activeClaimAttemptIdByCartelaId, isEmpty);
      expect(c.isConfirmingClaim('gc-1'), isFalse);
      expect(c.claimAttemptFor('gc-1'), isNull);
      expect(c.claimRecoveryFailedCartelaIds, isEmpty);
      expect(_can(c), isTrue);
      c.dispose();
    },
  );

  testWidgets(
    'ambiguous failures stay retained unless BOTH the POST and the GET independently prove non-delivery',
    (tester) async {
      // (a) GET reached the server (404 — not connection-level): must retain
      // even though the POST side looked provable.
      var getsA = 0;
      final a = LiveCalledNumbersController(
        _Host(),
        claimStorage: _Storage(),
        claimNow: tester.binding.clock.now,
        recoverClaim: (_, uuid) async {
          getsA++;
          throw ApiException(message: 'not found', statusCode: 404);
        },
      );
      await a.bindClaimRecoveryScope('user-1', 'session-1');
      final attemptA = _begin(a);
      attemptA.postConnectNeverCompleted = true;
      a.finishClaimSubmission(attemptA);
      await a.recoverClaimAttempt(attemptA);
      expect(getsA, 1);
      expect(a.activeClaimAttemptIdByCartelaId['gc-1'], attemptA.claimAttemptId);
      expect(a.isConfirmingClaim('gc-1'), isTrue);
      a.dispose();

      // (b) The POST itself was only a receiveTimeout (not provably
      // pre-dispatch) even though the GET fails at the connection level:
      // must retain — a single connection-level signal is never enough.
      var getsB = 0;
      final b = LiveCalledNumbersController(
        _Host(),
        claimStorage: _Storage(),
        claimNow: tester.binding.clock.now,
        recoverClaim: (_, uuid) async {
          getsB++;
          throw ApiException(
            message: 'Could not reach the server. Please try again.',
            dioExceptionType: 'connectionError',
          );
        },
      );
      await b.bindClaimRecoveryScope('user-1', 'session-1');
      final attemptB = _begin(b);
      attemptB.postConnectNeverCompleted = false;
      b.finishClaimSubmission(attemptB);
      await b.recoverClaimAttempt(attemptB);
      expect(getsB, 1);
      expect(b.activeClaimAttemptIdByCartelaId['gc-1'], attemptB.claimAttemptId);
      expect(b.isConfirmingClaim('gc-1'), isTrue);
      b.dispose();
    },
  );

  testWidgets(
    'escalation banner appears once the same-UUID retry budget is exhausted and clears once resolved',
    (tester) async {
      final c = LiveCalledNumbersController(
        _Host(),
        claimStorage: _Storage(),
        claimNow: tester.binding.clock.now,
        recoverClaim: (_, uuid) async => throw ApiException(
          message: 'Bingo claim attempt not found',
          statusCode: 404,
        ),
        resubmitClaim: (attempt) async =>
            throw ApiException(message: 'still unreachable'),
      );
      await c.bindClaimRecoveryScope('user-1', 'session-1');
      final attempt = _begin(c);
      c.finishClaimSubmission(attempt);
      await c.recoverClaimAttempt(attempt);
      expect(attempt.sameUuidPostRetries, 1);
      expect(c.claimNeedingEscalation, isNull, reason: 'budget not yet exhausted');
      await tester.pump(const Duration(seconds: 1)); // backoff[0]
      expect(attempt.sameUuidPostRetries, 2);
      expect(c.claimNeedingEscalation, same(attempt));
      c.applyAuthoritativeClaimStatus(
        attempt,
        BingoClaimStatus.invalid,
        retryAllowed: false,
      );
      expect(c.claimNeedingEscalation, isNull, reason: 'resolved, no longer needs escalation');
      c.dispose();
    },
  );

  testWidgets(
    'escalation banner appears immediately when no same-UUID retry hook is configured',
    (tester) async {
      final c = LiveCalledNumbersController(
        _Host(),
        claimStorage: _Storage(),
        claimNow: tester.binding.clock.now,
        recoverClaim: (_, uuid) async => throw ApiException(message: 'offline'),
      );
      await c.bindClaimRecoveryScope('user-1', 'session-1');
      final attempt = _begin(c);
      c.finishClaimSubmission(attempt);
      await c.recoverClaimAttempt(attempt);
      expect(c.claimNeedingEscalation, same(attempt));
      c.dispose();
    },
  );

  testWidgets(
    'live screen: 6s claimPostReceiveTimeout after Nest already accepted the '
    'claim recovers the same attempt without duplicate validation',
    (tester) async {
      // Simulates the exact scenario claimPostReceiveTimeout=6s is designed
      // for: Nest committed the accept txn and is still mid-validation when
      // the client's 6s receive timeout fires. The POST never resolves; the
      // same claimAttemptId must be recovered via GET, not re-POSTed.
      var recoveryGets = 0;
      final repo = _Repo()
        ..failFirstGet = false
        ..recoveryGameStatus = GameStatus.winnerWindow
        ..recoveryWindowEndsAt = DateTime.now().add(const Duration(minutes: 5));
      repo.recoveryResponse = (uuid) {
        recoveryGets++;
        // First GET: Nest is still validating (CHECKING). Second GET: the
        // validate txn has since completed and Nest reports the real result.
        return recoveryGets == 1
            ? BingoClaimStatus.checking
            : BingoClaimStatus.valid;
      };
      final socket = _Socket();
      final sound = _Sound();
      await _pumpLive(tester, repo, socket, sound: sound);
      final host = tester.state(find.byType(LiveGameScreen)) as LiveGameHost;
      final c = host.controllers.calledNumbers;
      tester
          .widget<LiveCartelaCard>(find.byType(LiveCartelaCard).first)
          .onClaimBingo();
      await tester.pump();
      final originalUuid = repo.submittedUuid;
      expect(originalUuid, isNotNull);

      // The 6s client-side receiveTimeout fires. This must never be treated
      // as proof of non-delivery (it is not a connectionTimeout) and must
      // never be turned into INVALID/BLOCKED — only ambiguous + recovery.
      repo.post.completeError(
        ApiException(
          message: 'Could not reach the server. Please try again.',
          dioExceptionType: 'receiveTimeout',
        ),
      );
      await tester.pump();

      // Ambiguous only: original claimAttemptId retained, still CONFIRMING,
      // never auto-cleared (receiveTimeout cannot set postConnectNeverCompleted).
      expect(c.activeClaimAttemptIdByCartelaId['gc-1'], originalUuid);
      expect(c.isConfirmingClaim('gc-1'), isTrue);
      expect(c.claimRecoveryFailedCartelaIds, isEmpty);
      expect(recoveryGets, 1);
      // First GET reports CHECKING: wait for the authoritative result, do
      // not resolve and do not fire a same-UUID retry POST (that path is
      // 404-only).
      expect(repo.claimCards.length, 1, reason: 'no retry POST was sent');
      expect(find.widgetWithText(FilledButton, 'BINGO'), findsNothing);

      // Fixed 2s re-check interval for a non-terminal (CHECKING) status.
      await tester.pump(const Duration(seconds: 2));

      expect(recoveryGets, 2);
      expect(host.myCartelas.single.status, GameCartelaStatus.winner);
      expect(c.activeClaimAttemptIdByCartelaId, isEmpty);
      expect(c.isConfirmingClaim('gc-1'), isFalse);
      // Still exactly one POST for the whole lifecycle — recovery via GET
      // never mints a second validation of the same claim.
      expect(repo.claimCards.length, 1);
      expect(repo.submittedUuid, originalUuid);
      expect(
        sound.events.where((e) => e == SoundEvent.validBingo).length,
        1,
        reason: 'the claim is validated exactly once, not duplicated',
      );
      await BingoClaimAttemptStorage().load('user-1', 'session-1');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
