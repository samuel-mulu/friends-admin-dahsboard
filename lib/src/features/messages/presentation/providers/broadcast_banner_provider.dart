import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/admin_broadcast_model.dart';
import 'broadcasts_provider.dart';

class BroadcastBannerState {
  const BroadcastBannerState({this.visibleMessage});

  final AdminBroadcastModel? visibleMessage;

  bool get isVisible => visibleMessage != null;
}

final broadcastBannerProvider =
    NotifierProvider<BroadcastBannerNotifier, BroadcastBannerState>(
      BroadcastBannerNotifier.new,
    );

class BroadcastBannerNotifier extends Notifier<BroadcastBannerState> {
  @override
  BroadcastBannerState build() {
    ref.listen(authControllerProvider, (previous, next) {
      final hadSession = previous?.session != null;
      final hasSession = next.session != null;
      if (hadSession && !hasSession) {
        state = const BroadcastBannerState();
      }
    });

    // Keep banner in sync with inbox/forced state, but never auto-open from
    // HTTP load — only [showFromSocket] opens the banner.
    ref.listen(
      broadcastsProvider,
      (previous, next) {
        next.whenData(_onBroadcastsUpdated);
      },
      fireImmediately: true,
    );

    return const BroadcastBannerState();
  }

  void _onBroadcastsUpdated(PlayerBroadcastsState broadcasts) {
    if (ref.read(authControllerProvider).session == null) {
      state = const BroadcastBannerState();
      return;
    }

    if (broadcasts.forcedBroadcast != null) {
      state = const BroadcastBannerState();
      return;
    }

    final visible = state.visibleMessage;
    if (visible == null) {
      return;
    }

    // Hide if the currently shown message left the inbox (dismissed/removed).
    final stillInInbox = broadcasts.inboxBroadcasts.any(
      (message) => message.id == visible.id,
    );
    if (!stillInInbox) {
      state = const BroadcastBannerState();
    }
  }

  void showFromSocket(AdminBroadcastModel message) {
    if (message.isForced) {
      return;
    }

    state = BroadcastBannerState(visibleMessage: message);
  }

  void hideBanner() {
    state = const BroadcastBannerState();
  }

  Future<void> closeBanner() async {
    final message = state.visibleMessage;
    if (message == null) {
      return;
    }

    hideBanner();

    if (message.canDismiss) {
      await ref.read(broadcastsProvider.notifier).dismiss(message.id);
    }
  }
}
