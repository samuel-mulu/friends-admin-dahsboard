import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/games_repository.dart';
import '../../data/models/game_model.dart';

enum OperationsSyncReason {
  appStartup,
  sessionRestore,
  appResume,
  socketReconnect,
  manualRefresh,
  missingPayloadRecovery,
  inconsistencyRecovery,
}

class OperationsSyncFetchResult {
  const OperationsSyncFetchResult({
    required this.snapshot,
    required this.requestStartedAt,
    required this.completedAt,
    required this.ownerReason,
    required this.skipped,
    required this.joinedInFlight,
  });

  final GameOperationsCurrentResponse? snapshot;
  final DateTime requestStartedAt;
  final DateTime completedAt;
  final OperationsSyncReason ownerReason;
  final bool skipped;
  final bool joinedInFlight;

  OperationsSyncFetchResult copyWith({
    GameOperationsCurrentResponse? snapshot,
    DateTime? requestStartedAt,
    DateTime? completedAt,
    OperationsSyncReason? ownerReason,
    bool? skipped,
    bool? joinedInFlight,
  }) {
    return OperationsSyncFetchResult(
      snapshot: snapshot ?? this.snapshot,
      requestStartedAt: requestStartedAt ?? this.requestStartedAt,
      completedAt: completedAt ?? this.completedAt,
      ownerReason: ownerReason ?? this.ownerReason,
      skipped: skipped ?? this.skipped,
      joinedInFlight: joinedInFlight ?? this.joinedInFlight,
    );
  }
}

class GameOperationsSyncCoordinator {
  GameOperationsSyncCoordinator(
    this._repository, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final GamesRepository _repository;
  final DateTime Function() _clock;

  Future<OperationsSyncFetchResult>? _inFlight;
  final Map<OperationsSyncReason, DateTime> _lastAttemptStartedAt =
      <OperationsSyncReason, DateTime>{};
  DateTime? _lastRequestStartedAt;
  DateTime? _lastRequestCompletedAt;
  OperationsSyncReason? _lastRequestReason;
  DateTime? _lastSuccessfulFetchAt;
  OperationsSyncReason? _lastSuccessfulReason;
  GameOperationsCurrentResponse? _lastSuccessfulSnapshot;

  bool get hasInFlight => _inFlight != null;

  bool shouldSkipDueToCooldown(
    OperationsSyncReason reason, {
    bool force = false,
    DateTime? now,
  }) {
    if (force || !_hasCooldown(reason)) {
      return false;
    }

    final lastAttemptAt = _lastAttemptStartedAt[reason];
    if (lastAttemptAt == null) {
      return false;
    }

    final elapsed = (now ?? _clock()).difference(lastAttemptAt);
    return elapsed < _cooldownFor(reason);
  }

  Future<OperationsSyncFetchResult> sync({
    required OperationsSyncReason reason,
    bool force = false,
  }) {
    final inFlight = _inFlight;
    if (inFlight != null) {
      _log(
        'operations_sync_joined_inflight '
        'ownerReason=${_formatReason(_lastRequestReason ?? reason)} '
        'joinedReason=${_formatReason(reason)}',
      );
      return inFlight.then(
        (result) => result.copyWith(joinedInFlight: true),
      );
    }

    final now = _clock();
    if (shouldSkipDueToCooldown(reason, force: force, now: now)) {
      final cooldown = _cooldownFor(reason);
      _log(
        'operations_sync_skipped reason=${_formatReason(reason)} '
        'cooldownMs=${cooldown.inMilliseconds}',
      );
      return Future<OperationsSyncFetchResult>.value(
        OperationsSyncFetchResult(
          snapshot: _lastSuccessfulSnapshot,
          requestStartedAt: now,
          completedAt: now,
          ownerReason: reason,
          skipped: true,
          joinedInFlight: false,
        ),
      );
    }

    final requestStartedAt = now;
    _lastAttemptStartedAt[reason] = requestStartedAt;
    _lastRequestStartedAt = requestStartedAt;
    _lastRequestReason = reason;

    _log('operations_sync_start reason=${_formatReason(reason)}');

    final future = _performSync(
      reason: reason,
      requestStartedAt: requestStartedAt,
    );
    _inFlight = future;

    return future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
  }

  Future<OperationsSyncFetchResult> _performSync({
    required OperationsSyncReason reason,
    required DateTime requestStartedAt,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final snapshot = await _repository.getCurrentGameOperations();
      final completedAt = _clock();
      _lastRequestCompletedAt = completedAt;
      _lastSuccessfulFetchAt = completedAt;
      _lastSuccessfulReason = reason;
      _lastSuccessfulSnapshot = snapshot;
      _log(
        'operations_sync_success reason=${_formatReason(reason)} '
        'durationMs=${stopwatch.elapsedMilliseconds}',
      );
      return OperationsSyncFetchResult(
        snapshot: snapshot,
        requestStartedAt: requestStartedAt,
        completedAt: completedAt,
        ownerReason: reason,
        skipped: false,
        joinedInFlight: false,
      );
    } catch (error) {
      _lastRequestCompletedAt = _clock();
      _log(
        'operations_sync_failed reason=${_formatReason(reason)} error=$error',
      );
      rethrow;
    }
  }

  bool _hasCooldown(OperationsSyncReason reason) {
    return switch (reason) {
      OperationsSyncReason.appStartup => false,
      OperationsSyncReason.sessionRestore => false,
      OperationsSyncReason.appResume => true,
      OperationsSyncReason.socketReconnect => true,
      OperationsSyncReason.manualRefresh => false,
      OperationsSyncReason.missingPayloadRecovery => true,
      OperationsSyncReason.inconsistencyRecovery => true,
    };
  }

  Duration _cooldownFor(OperationsSyncReason reason) {
    return switch (reason) {
      OperationsSyncReason.appStartup => Duration.zero,
      OperationsSyncReason.sessionRestore => Duration.zero,
      OperationsSyncReason.appResume => const Duration(seconds: 5),
      OperationsSyncReason.socketReconnect => const Duration(seconds: 2),
      OperationsSyncReason.manualRefresh => Duration.zero,
      OperationsSyncReason.missingPayloadRecovery => const Duration(
        seconds: 10,
      ),
      OperationsSyncReason.inconsistencyRecovery => const Duration(seconds: 2),
    };
  }

  String _formatReason(OperationsSyncReason reason) {
    return switch (reason) {
      OperationsSyncReason.appStartup => 'appStartup',
      OperationsSyncReason.sessionRestore => 'sessionRestore',
      OperationsSyncReason.appResume => 'appResume',
      OperationsSyncReason.socketReconnect => 'socketReconnect',
      OperationsSyncReason.manualRefresh => 'manualRefresh',
      OperationsSyncReason.missingPayloadRecovery => 'missingPayloadRecovery',
      OperationsSyncReason.inconsistencyRecovery => 'inconsistencyRecovery',
    };
  }

  void _log(String message) {
    final lastSuccessfulReason = _lastSuccessfulReason;
    AppLogger.debug(
      'OperationsSync',
      '$message '
      'lastRequestStartedAt=${_lastRequestStartedAt?.toIso8601String() ?? '-'} '
      'lastRequestCompletedAt=${_lastRequestCompletedAt?.toIso8601String() ?? '-'} '
      'lastSuccessfulAt=${_lastSuccessfulFetchAt?.toIso8601String() ?? '-'} '
      'lastSuccessfulReason=${lastSuccessfulReason == null ? '-' : _formatReason(lastSuccessfulReason)}',
    );
  }
}

final gameOperationsSyncCoordinatorProvider =
    Provider<GameOperationsSyncCoordinator>((ref) {
      ref.watch(
        authControllerProvider.select((state) => state.session?.accessToken),
      );
      return GameOperationsSyncCoordinator(ref.watch(gamesRepositoryProvider));
    });
