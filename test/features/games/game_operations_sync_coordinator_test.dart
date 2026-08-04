import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/network/api_client.dart';
import 'package:friends_bingo_app/src/features/games/data/games_repository.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/live_connection_status.dart';
import 'package:friends_bingo_app/src/features/games/presentation/providers/current_game_operations_provider.dart';
import 'package:friends_bingo_app/src/features/games/presentation/providers/game_operations_sync_coordinator.dart';
import 'package:friends_bingo_app/src/features/games/presentation/providers/realtime_connection_provider.dart';

void main() {
  group('GameOperationsSyncCoordinator', () {
    test('manual refresh joins an existing request', () async {
      final repository = _FakeGamesRepository();
      final clock = _TestClock(DateTime.utc(2026, 8, 3, 12));
      final completer = Completer<GameOperationsCurrentResponse>();
      repository.onGetCurrentGameOperations = () => completer.future;
      final coordinator = GameOperationsSyncCoordinator(
        repository,
        clock: clock.call,
      );

      final first = coordinator.sync(reason: OperationsSyncReason.appResume);
      final second = coordinator.sync(reason: OperationsSyncReason.manualRefresh);

      expect(repository.currentOperationsCalls, 1);

      completer.complete(_operationsSnapshot(sessionId: 'session-a'));

      final firstResult = await first;
      final secondResult = await second;

      expect(firstResult.joinedInFlight, isFalse);
      expect(firstResult.ownerReason, OperationsSyncReason.appResume);
      expect(secondResult.joinedInFlight, isTrue);
      expect(secondResult.ownerReason, OperationsSyncReason.appResume);
    });

    test('app startup and session restore share one HTTP call', () async {
      final repository = _FakeGamesRepository();
      final clock = _TestClock(DateTime.utc(2026, 8, 3, 12));
      final completer = Completer<GameOperationsCurrentResponse>();
      repository.onGetCurrentGameOperations = () => completer.future;
      final coordinator = GameOperationsSyncCoordinator(
        repository,
        clock: clock.call,
      );

      final first = coordinator.sync(reason: OperationsSyncReason.appStartup);
      final second = coordinator.sync(reason: OperationsSyncReason.sessionRestore);

      expect(repository.currentOperationsCalls, 1);

      completer.complete(_operationsSnapshot(sessionId: 'session-a'));

      expect((await first).joinedInFlight, isFalse);
      expect((await second).joinedInFlight, isTrue);
    });

    test('socket reconnect and app resume share one HTTP call', () async {
      final repository = _FakeGamesRepository();
      final clock = _TestClock(DateTime.utc(2026, 8, 3, 12));
      final completer = Completer<GameOperationsCurrentResponse>();
      repository.onGetCurrentGameOperations = () => completer.future;
      final coordinator = GameOperationsSyncCoordinator(
        repository,
        clock: clock.call,
      );

      final first = coordinator.sync(
        reason: OperationsSyncReason.socketReconnect,
      );
      final second = coordinator.sync(reason: OperationsSyncReason.appResume);

      expect(repository.currentOperationsCalls, 1);

      completer.complete(_operationsSnapshot(sessionId: 'session-a'));

      expect((await first).joinedInFlight, isFalse);
      expect((await second).joinedInFlight, isTrue);
    });

    test('first missing-payload recovery runs immediately', () async {
      final repository = _FakeGamesRepository();
      final clock = _TestClock(DateTime.utc(2026, 8, 3, 12));
      final coordinator = GameOperationsSyncCoordinator(
        repository,
        clock: clock.call,
      );

      final result = await coordinator.sync(
        reason: OperationsSyncReason.missingPayloadRecovery,
      );

      expect(repository.currentOperationsCalls, 1);
      expect(result.skipped, isFalse);
      expect(result.snapshot, isNotNull);
    });

    test('repeated missing-payload recovery respects cooldown', () async {
      final repository = _FakeGamesRepository();
      final clock = _TestClock(DateTime.utc(2026, 8, 3, 12));
      final coordinator = GameOperationsSyncCoordinator(
        repository,
        clock: clock.call,
      );

      final first = await coordinator.sync(
        reason: OperationsSyncReason.missingPayloadRecovery,
      );
      final second = await coordinator.sync(
        reason: OperationsSyncReason.missingPayloadRecovery,
      );

      expect(repository.currentOperationsCalls, 1);
      expect(first.skipped, isFalse);
      expect(second.skipped, isTrue);
      expect(second.snapshot, isNotNull);
    });

    test('failed recovery does not create a tight retry loop', () async {
      final repository = _FakeGamesRepository();
      final clock = _TestClock(DateTime.utc(2026, 8, 3, 12));
      repository.onGetCurrentGameOperations = () async {
        throw StateError('boom');
      };
      final coordinator = GameOperationsSyncCoordinator(
        repository,
        clock: clock.call,
      );

      await expectLater(
        coordinator.sync(reason: OperationsSyncReason.missingPayloadRecovery),
        throwsStateError,
      );

      final second = await coordinator.sync(
        reason: OperationsSyncReason.missingPayloadRecovery,
      );

      expect(repository.currentOperationsCalls, 1);
      expect(second.skipped, isTrue);
      expect(second.snapshot, isNull);
    });
  });

  group('CurrentGameOperationsNotifier', () {
    test('skipped cooldown preserves snapshot and does not emit loading', () async {
      final repository = _FakeGamesRepository();
      final clock = _TestClock(DateTime.utc(2026, 8, 3, 12));
      final coordinator = GameOperationsSyncCoordinator(
        repository,
        clock: clock.call,
      );
      final container = ProviderContainer(
        overrides: [
          gameOperationsSyncCoordinatorProvider.overrideWithValue(coordinator),
          realtimeConnectionProvider.overrideWith(
            () => _StaticRealtimeConnectionNotifier(
              LiveConnectionStatus.offline,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final transitions = <AsyncValue<GameOperationsCurrentResponse?>>[];
      final subscription = container.listen<
        AsyncValue<GameOperationsCurrentResponse?>
      >(
        currentGameOperationsProvider,
        (_, next) => transitions.add(next),
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final initial = await container.read(currentGameOperationsProvider.future);
      expect(initial, isNotNull);
      expect(repository.currentOperationsCalls, 1);

      clock.advance(const Duration(seconds: 15));
      await container
          .read(currentGameOperationsProvider.notifier)
          .refreshFromNetwork(
            reason: OperationsSyncReason.missingPayloadRecovery,
          );
      expect(repository.currentOperationsCalls, 2);

      final beforeSkip = transitions.length;
      await container
          .read(currentGameOperationsProvider.notifier)
          .refreshFromNetwork(
            reason: OperationsSyncReason.missingPayloadRecovery,
          );

      expect(repository.currentOperationsCalls, 2);
      expect(container.read(currentGameOperationsProvider).value, isNotNull);
      expect(
        transitions.skip(beforeSkip).any((state) => state.isLoading),
        isFalse,
      );
    });

    test('failed refresh preserves the last valid snapshot', () async {
      final repository = _FakeGamesRepository();
      final clock = _TestClock(DateTime.utc(2026, 8, 3, 12));
      final coordinator = GameOperationsSyncCoordinator(
        repository,
        clock: clock.call,
      );
      final container = ProviderContainer(
        overrides: [
          gameOperationsSyncCoordinatorProvider.overrideWithValue(coordinator),
          realtimeConnectionProvider.overrideWith(
            () => _StaticRealtimeConnectionNotifier(
              LiveConnectionStatus.offline,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(currentGameOperationsProvider.future);
      repository.onGetCurrentGameOperations = () async {
        throw StateError('boom');
      };

      await container
          .read(currentGameOperationsProvider.notifier)
          .refreshFromNetwork(reason: OperationsSyncReason.manualRefresh);

      expect(container.read(currentGameOperationsProvider).value, same(initial));
    });
  });
}

class _FakeGamesRepository extends GamesRepository {
  _FakeGamesRepository() : super(ApiClient(Dio()));

  int currentOperationsCalls = 0;
  Future<GameOperationsCurrentResponse> Function()? onGetCurrentGameOperations;

  @override
  Future<GameOperationsCurrentResponse> getCurrentGameOperations() {
    currentOperationsCalls++;
    final callback = onGetCurrentGameOperations;
    if (callback != null) {
      return callback();
    }
    return Future<GameOperationsCurrentResponse>.value(
      _operationsSnapshot(sessionId: 'session-a'),
    );
  }
}

class _StaticRealtimeConnectionNotifier extends RealtimeConnectionNotifier {
  _StaticRealtimeConnectionNotifier(this._value);

  final LiveConnectionStatus _value;

  @override
  LiveConnectionStatus build() => _value;
}

class _TestClock {
  _TestClock(this._now);

  DateTime _now;

  DateTime call() => _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }
}

GameOperationsCurrentResponse _operationsSnapshot({
  required String sessionId,
  String status = 'READY',
  int calledNumbersCount = 0,
}) {
  const timestamp = '2026-08-03T12:00:00.000Z';
  return GameOperationsCurrentResponse.fromJson({
    'timestamp': timestamp,
    'serverNow': timestamp,
    'registrationOpenGame': {
      'id': 'slot-$sessionId',
      'slotId': 'slot-$sessionId',
      'sessionId': sessionId,
      'name': 'Game $sessionId',
      'status': status,
      'entryFee': '10',
      'prizePerCartela': '100',
      'prizeAmount': '1000',
      'companyRevenue': '0',
      'registeredCartelasCount': 2,
      'calledNumbersCount': calledNumbersCount,
      'canRegister': status == 'READY',
      'registrationOpen': status == 'READY',
      'scheduledStartAt': '2026-08-03T12:05:00.000Z',
      'operationMode': 'MANUAL',
    },
    'queue': const <Map<String, dynamic>>[],
  });
}
