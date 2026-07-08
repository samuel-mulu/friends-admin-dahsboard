import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/resume_sync_guard.dart';
import '../../../../core/time/server_clock_provider.dart';
import '../../data/games_repository.dart';
import '../../data/models/game_model.dart';
import '../../domain/live_connection_status.dart';
import '../debug/live_realtime_debug.dart';
import '../utils/game_operations_resume_cache.dart';
import '../utils/live_game_resume_owner_registry.dart';
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

    return _load();
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
    return refreshFromNetwork();
  }

  Future<GameOperationsCurrentResponse?> refreshFromNetwork() async {
    if (_isAutoRefreshSuppressed) {
      LiveRealtimeDebug.providerInvalidateSkipped(
        provider: 'currentGameOperations',
        reason: 'resume_sync_window',
      );
      return state.value;
    }
    LiveRealtimeDebug.providerInvalidated(
      provider: 'currentGameOperations',
      reason: 'refresh',
    );
    state = const AsyncLoading<GameOperationsCurrentResponse?>();
    state = await AsyncValue.guard(_load);
    final snapshot = state.value;
    if (snapshot != null) {
      GameOperationsResumeCache.shared.put(snapshot);
    }
    return snapshot;
  }

  Future<GameOperationsCurrentResponse?> _load() async {
    final response =
        await ref.read(gamesRepositoryProvider).getCurrentGameOperations();
    ref.read(serverClockProvider).sync(response.serverNow, snap: false);
    return response;
  }

  Future<void> refresh() async {
    await refreshFromNetwork();
  }
}
