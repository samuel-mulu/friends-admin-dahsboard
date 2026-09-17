import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../data/games_repository.dart';
import '../../data/models/game_model.dart';
import '../../domain/live_connection_status.dart';
import '../debug/big_game_debug.dart';
import 'realtime_connection_provider.dart';

final currentBigGameProvider =
    AsyncNotifierProvider<CurrentBigGameNotifier, GameModel?>(
      CurrentBigGameNotifier.new,
    );

class CurrentBigGameNotifier extends AsyncNotifier<GameModel?> {
  Future<GameModel?>? _inFlight;
  Timer? _refreshDebounce;
  static const _structuralRefreshDebounce = Duration(milliseconds: 350);

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

    final socket = ref.read(socketServiceProvider);
    void onStructural(dynamic payload) {
      if (!_payloadTouchesBigGame(payload)) {
        return;
      }
      _scheduleStructuralRefresh();
    }

    void onCancelled(dynamic payload) {
      // Always refresh — cancelled Big Game should clear the card.
      _scheduleStructuralRefresh(immediate: true);
    }

    const events = <String>[
      'game:status_changed',
      'game:operation_updated',
      'game:finished',
      'session:cartelas_updated',
      'session:prize_updated',
      'slot:status_changed',
    ];

    for (final event in events) {
      socket.on(event, onStructural);
    }
    socket.on('game:cancelled', onCancelled);

    ref.onDispose(() {
      _refreshDebounce?.cancel();
      for (final event in events) {
        socket.off(event, onStructural);
      }
      socket.off('game:cancelled', onCancelled);
    });

    return _loadBigGame();
  }

  void _scheduleStructuralRefresh({bool immediate = false}) {
    _refreshDebounce?.cancel();
    if (immediate) {
      unawaited(refresh());
      return;
    }
    _refreshDebounce = Timer(_structuralRefreshDebounce, () {
      unawaited(refresh());
    });
  }

  bool _payloadTouchesBigGame(dynamic payload) {
    if (payload is! Map) {
      // Unknown shape — refresh once so we never miss a handoff.
      return true;
    }

    final map = Map<Object?, Object?>.from(payload);
    final category = map['category']?.toString().toUpperCase();
    final isBigGame =
        category == 'BIG_GAME' || map['isBigGame'] == true;
    if (isBigGame) {
      return true;
    }

    final current = state.value;
    if (current == null) {
      // No cache yet — only refresh when category is clearly Big Game.
      return false;
    }

    final sessionId =
        map['sessionId']?.toString() ?? map['id']?.toString();
    String? slotId =
        map['slotId']?.toString() ?? map['gameSlotId']?.toString();
    final gameSlot = map['gameSlot'];
    if (slotId == null && gameSlot is Map) {
      slotId = gameSlot['id']?.toString();
    }

    if (sessionId != null &&
        (sessionId == current.sessionId ||
            sessionId == current.previousRound?.sessionId ||
            sessionId == current.nextRoundRegistration?.sessionId ||
            sessionId ==
                current.nextRoundRegistration?.previousRound?.sessionId)) {
      return true;
    }
    if (slotId != null && slotId == current.id) {
      return true;
    }
    return false;
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
      final previous = state.value;
      final roundChanged =
          previous?.sessionId != next?.sessionId ||
          previous?.status != next?.status ||
          previous?.roundIndex != next?.roundIndex ||
          previous?.nextRoundRegistration?.sessionId !=
              next?.nextRoundRegistration?.sessionId ||
          previous?.scheduledStartAt != next?.scheduledStartAt ||
          previous?.canRegister != next?.canRegister;
      if (roundChanged) {
        BigGameDebug.snapshot(next, reason: 'refresh_round_change');
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
