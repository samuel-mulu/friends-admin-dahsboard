import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/admin_broadcast_model.dart';
import '../../data/repositories/broadcasts_repository.dart';

class BroadcastBellBadgeState {
  const BroadcastBellBadgeState({
    this.dismissibleCount = 0,
    this.pinnedCount = 0,
  });

  final int dismissibleCount;
  final int pinnedCount;

  bool get shouldBlink => dismissibleCount > 0;

  bool get showBadge => dismissibleCount > 0 || pinnedCount > 0;

  bool get isPinnedOnly => pinnedCount > 0 && dismissibleCount == 0;

  int get displayCount =>
      dismissibleCount > 0 ? dismissibleCount : pinnedCount;
}

final broadcastsProvider =
    AsyncNotifierProvider<BroadcastsNotifier, PlayerBroadcastsState>(
      BroadcastsNotifier.new,
    );

final unreadBroadcastCountProvider = Provider<int>((ref) {
  final broadcasts = ref.watch(broadcastsProvider);
  return broadcasts.maybeWhen(
    data: (state) => state.unreadCount,
    orElse: () => 0,
  );
});

final broadcastBellBadgeProvider = Provider<BroadcastBellBadgeState>((ref) {
  final broadcasts = ref.watch(broadcastsProvider);
  return broadcasts.maybeWhen(
    data: (state) => BroadcastBellBadgeState(
      dismissibleCount: state.unreadCount,
      pinnedCount: state.pinnedCount,
    ),
    orElse: () => const BroadcastBellBadgeState(),
  );
});

final forcedBroadcastProvider = Provider<AdminBroadcastModel?>((ref) {
  final broadcasts = ref.watch(broadcastsProvider);
  return broadcasts.maybeWhen(
    data: (state) => state.forcedBroadcast,
    orElse: () => null,
  );
});

final hasActiveForcedBroadcastProvider = Provider<bool>((ref) {
  return ref.watch(forcedBroadcastProvider) != null;
});

class BroadcastsNotifier extends AsyncNotifier<PlayerBroadcastsState> {
  @override
  Future<PlayerBroadcastsState> build() async {
    ref.listen(authControllerProvider, (previous, next) {
      final hadSession = previous?.session != null;
      final hasSession = next.session != null;
      if (hadSession && !hasSession) {
        state = const AsyncData(PlayerBroadcastsState());
      } else if (!hadSession && hasSession) {
        unawaited(refresh());
      }
    });

    if (ref.watch(authControllerProvider).session == null) {
      return const PlayerBroadcastsState();
    }

    final response =
        await ref.read(broadcastsRepositoryProvider).getMyBroadcasts();
    return PlayerBroadcastsState.fromResponse(response);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<PlayerBroadcastsState>();
    state = await AsyncValue.guard(() async {
      final response =
          await ref.read(broadcastsRepositoryProvider).getMyBroadcasts();
      return PlayerBroadcastsState.fromResponse(response);
    });
  }

  Future<void> dismiss(String id) async {
    final previous = state.value ?? const PlayerBroadcastsState();
    state = AsyncData(
      PlayerBroadcastsState.normalize(
        inboxBroadcasts: previous.inboxBroadcasts
            .where((broadcast) => broadcast.id != id)
            .toList(),
        forcedBroadcast: previous.forcedBroadcast,
      ),
    );

    try {
      await ref.read(broadcastsRepositoryProvider).dismissBroadcast(id);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
    }
  }

  void addFromSocket(AdminBroadcastModel message) {
    final current = state.value ?? const PlayerBroadcastsState();

    if (message.isForced) {
      state = AsyncData(
        PlayerBroadcastsState.normalize(
          inboxBroadcasts: current.inboxBroadcasts,
          forcedBroadcast: message,
          unreadCount: current.unreadCount,
        ),
      );
      return;
    }

    if (current.inboxBroadcasts.any((broadcast) => broadcast.id == message.id)) {
      return;
    }

    final inboxBroadcasts = [message, ...current.inboxBroadcasts];
    state = AsyncData(
      PlayerBroadcastsState.normalize(
        inboxBroadcasts: inboxBroadcasts,
        forcedBroadcast: current.forcedBroadcast,
      ),
    );
  }

  void removeFromSocket(String id) {
    final current = state.value ?? const PlayerBroadcastsState();
    final hadForced = current.forcedBroadcast?.id == id;

    state = AsyncData(
      PlayerBroadcastsState.normalize(
        inboxBroadcasts: current.inboxBroadcasts
            .where((broadcast) => broadcast.id != id)
            .toList(),
        forcedBroadcast: hadForced ? null : current.forcedBroadcast,
      ),
    );

    if (hadForced) {
      unawaited(refresh());
    }
  }
}
