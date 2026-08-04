import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/games_repository.dart';
import '../../data/models/game_model.dart';
import '../../domain/live_connection_status.dart';
import 'realtime_connection_provider.dart';

final currentBigGameProvider =
    AsyncNotifierProvider<CurrentBigGameNotifier, GameModel?>(
      CurrentBigGameNotifier.new,
    );

class CurrentBigGameNotifier extends AsyncNotifier<GameModel?> {
  Future<GameModel?>? _inFlight;

  @override
  Future<GameModel?> build() async {
    ref.watch(authControllerProvider);
    if (ref.read(authControllerProvider).session == null) {
      return null;
    }

    ref.listen(realtimeConnectionProvider, (previous, next) {
      if (previous != LiveConnectionStatus.live &&
          next == LiveConnectionStatus.live) {
        unawaited(refresh());
      }
    });

    return _loadBigGame();
  }

  Future<void> refresh() async {
    if (ref.read(authControllerProvider).session == null) {
      state = const AsyncData(null);
      return;
    }

    final current = state.value;
    if (current == null) {
      state = const AsyncLoading<GameModel?>();
    }

    try {
      final next = await _loadBigGame();
      if (!ref.mounted) {
        return;
      }
      state = AsyncData(next);
    } catch (error, stackTrace) {
      if (!ref.mounted) {
        return;
      }
      if (current != null) {
        state = AsyncData(current);
        return;
      }
      state = AsyncError(error, stackTrace);
    }
  }

  Future<GameModel?> _loadBigGame() {
    final inFlight = _inFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final future = ref.read(gamesRepositoryProvider).getCurrentBigGame();
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
  }
}
