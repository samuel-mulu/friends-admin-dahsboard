import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/support_repository.dart';

/// Unread admin-reply count for the shell feedback badge.
final supportUnreadCountProvider =
    AsyncNotifierProvider<SupportUnreadCountNotifier, int>(
      SupportUnreadCountNotifier.new,
    );

final supportUnreadBadgeCountProvider = Provider<int>((ref) {
  final unread = ref.watch(supportUnreadCountProvider);
  return unread.maybeWhen(data: (count) => count, orElse: () => 0);
});

class SupportUnreadCountNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    ref.listen(authControllerProvider, (previous, next) {
      final hadSession = previous?.session != null;
      final hasSession = next.session != null;
      if (hadSession && !hasSession) {
        state = const AsyncData(0);
      } else if (!hadSession && hasSession) {
        unawaited(refresh());
      }
    });

    if (ref.watch(authControllerProvider).session == null) {
      return 0;
    }

    return ref.read(supportRepositoryProvider).getUnreadReplyCount();
  }

  Future<void> refresh({bool quiet = false}) async {
    if (ref.read(authControllerProvider).session == null) {
      state = const AsyncData(0);
      return;
    }

    if (!quiet) {
      state = const AsyncLoading<int>();
    }

    final result = await AsyncValue.guard(
      () => ref.read(supportRepositoryProvider).getUnreadReplyCount(),
    );
    state = result;
  }

  /// Optimistic bump when `support:reply` arrives before HTTP refresh.
  void bumpFromSocket() {
    final current = state.value ?? 0;
    state = AsyncData(current + 1);
    unawaited(refresh(quiet: true));
  }

  Future<void> markSeenAndClear() async {
    if (ref.read(authControllerProvider).session == null) {
      state = const AsyncData(0);
      return;
    }

    state = const AsyncData(0);
    try {
      await ref.read(supportRepositoryProvider).markRepliesSeen();
    } catch (_) {
      unawaited(refresh(quiet: true));
    }
  }
}
