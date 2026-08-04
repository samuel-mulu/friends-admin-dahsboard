import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/resume_sync_guard.dart';
import '../../../../core/time/server_clock_provider.dart';
import '../../data/models/game_model.dart';
import '../../domain/live_connection_status.dart';
import '../debug/live_realtime_debug.dart';
import '../utils/game_operations_resume_cache.dart';
import '../utils/live_game_resume_owner_registry.dart';
import 'game_operations_sync_coordinator.dart';
import 'realtime_connection_provider.dart';

final currentGameOperationsProvider =
    AsyncNotifierProvider<CurrentGameOperationsNotifier, GameOperationsCurrentResponse?>(
      CurrentGameOperationsNotifier.new,
    );

class CurrentGameOperationsNotifier
    extends AsyncNotifier<GameOperationsCurrentResponse?> {
  DateTime? _suppressAutoRefreshUntil;

  @override
  Future<GameOperationsCurrentResponse?> build() async {
    ref.listen(realtimeConnectionProvider, (previous, next) {
      if (previous != LiveConnectionStatus.live &&
          next == LiveConnectionStatus.live) {
        if (_isAutoRefreshSuppressed ||
            ResumeSyncGuard.inFlight ||
            LiveGameResumeOwnerRegistry.isActive) {
          final skipReason = ResumeSyncGuard.inFlight
              ? 'resume_sync_in_flight'
              : LiveGameResumeOwnerRegistry.isActive
              ? 'live_game_resume_owner'
              : 'resume_sync_window';
          LiveRealtimeDebug.providerInvalidateSkipped(
            provider: 'currentGameOperations',
            reason: skipReason,
          );
          return;
        }
        unawaited(refresh());
      }
    });

    return _refreshViaCoordinator(
      reason: OperationsSyncReason.appStartup,
      emitLoading: false,
    );
  }

  bool get _isAutoRefreshSuppressed {
    final until = _suppressAutoRefreshUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  void suppressAutoRefreshUntil(DateTime until) {
    _suppressAutoRefreshUntil = until;
  }

  /// Seeds provider cache from live-game resume sync instead of refetching.
  void adoptResumeSnapshot(GameOperationsCurrentResponse snapshot) {
    GameOperationsResumeCache.shared.put(snapshot);
    ref.read(serverClockProvider).sync(snapshot.serverNow, snap: false);
    state = AsyncData(snapshot);
    suppressAutoRefreshUntil(
      DateTime.now().add(const Duration(seconds: 2)),
    );
    LiveRealtimeDebug.providerInvalidateSkipped(
      provider: 'currentGameOperations',
      reason: 'resume_snapshot_adopted',
    );
  }

  Future<GameOperationsCurrentResponse?> refreshFromResumeCacheOrNetwork() async {
    final cached = GameOperationsResumeCache.shared.getIfFresh();
    if (cached != null) {
      LiveRealtimeDebug.resumeCacheHit(type: 'operations_current');
      adoptResumeSnapshot(cached);
      return cached;
    }

    LiveRealtimeDebug.resumeCacheMiss(type: 'operations_current');
    return _refreshViaCoordinator(
      reason: OperationsSyncReason.appResume,
      emitLoading: false,
    );
  }

  Future<GameOperationsCurrentResponse?> refreshFromNetwork({
    OperationsSyncReason reason = OperationsSyncReason.manualRefresh,
    bool force = false,
  }) async {
    if (_isAutoRefreshSuppressed) {
      LiveRealtimeDebug.providerInvalidateSkipped(
        provider: 'currentGameOperations',
        reason: 'resume_sync_window',
      );
      return state.value;
    }
    return _refreshViaCoordinator(reason: reason, force: force);
  }

  Future<GameOperationsCurrentResponse?> _refreshViaCoordinator({
    required OperationsSyncReason reason,
    bool force = false,
    bool emitLoading = true,
  }) async {
    final coordinator = ref.read(gameOperationsSyncCoordinatorProvider);
    final currentSnapshot = state.value;
    final shouldShowLoading =
        emitLoading &&
        currentSnapshot == null &&
        !coordinator.hasInFlight &&
        !coordinator.shouldSkipDueToCooldown(reason, force: force);

    if (shouldShowLoading) {
      state = const AsyncLoading<GameOperationsCurrentResponse?>();
    }

    try {
      final result = await coordinator.sync(reason: reason, force: force);
      if (!ref.mounted) {
        return currentSnapshot;
      }

      final snapshot = result.snapshot;
      if (snapshot == null) {
        return currentSnapshot;
      }

      ref.read(serverClockProvider).sync(snapshot.serverNow, snap: false);
      GameOperationsResumeCache.shared.put(snapshot);
      state = AsyncData(snapshot);
      return snapshot;
    } catch (error, stackTrace) {
      if (!ref.mounted) {
        return currentSnapshot;
      }
      if (currentSnapshot != null) {
        state = AsyncData(currentSnapshot);
        return currentSnapshot;
      }
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<void> refresh({
    OperationsSyncReason reason = OperationsSyncReason.manualRefresh,
    bool force = false,
  }) async {
    await refreshFromNetwork(reason: reason, force: force);
  }
}
