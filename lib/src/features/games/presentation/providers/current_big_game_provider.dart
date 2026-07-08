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

    return ref.read(gamesRepositoryProvider).getCurrentBigGame();
  }

  Future<void> refresh() async {
    if (ref.read(authControllerProvider).session == null) {
      state = const AsyncData(null);
      return;
    }

    state = await AsyncValue.guard(
      () => ref.read(gamesRepositoryProvider).getCurrentBigGame(),
    );
  }
}
