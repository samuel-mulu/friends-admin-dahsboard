import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/admin_broadcast_model.dart';
import 'broadcasts_provider.dart';

const broadcastBannerAutoDismissDuration = Duration(seconds: 8);

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
  Timer? _autoDismissTimer;
  final Set<String> _hiddenBannerIds = <String>{};

  @override
  BroadcastBannerState build() {
    ref.listen(authControllerProvider, (previous, next) {
      final hadSession = previous?.session != null;
      final hasSession = next.session != null;
      if (hadSession && !hasSession) {
        _reset();
      }
    });

    ref.listen(
      broadcastsProvider,
      (previous, next) {
        next.whenData(_onBroadcastsUpdated);
      },
      fireImmediately: true,
    );

    ref.onDispose(() {
      _autoDismissTimer?.cancel();
    });

    return const BroadcastBannerState();
  }

  void _reset() {
    _autoDismissTimer?.cancel();
    _hiddenBannerIds.clear();
    state = const BroadcastBannerState();
  }

  void _onBroadcastsUpdated(PlayerBroadcastsState broadcasts) {
    if (ref.read(authControllerProvider).session == null) {
      _reset();
      return;
    }

    if (broadcasts.forcedBroadcast != null) {
      _hideVisible();
      return;
    }

    final candidate = _pickBannerCandidate(broadcasts.inboxBroadcasts);
    if (candidate == null) {
      _hideVisible();
      return;
    }

    if (_hiddenBannerIds.contains(candidate.id)) {
      return;
    }

    if (state.visibleMessage?.id == candidate.id) {
      return;
    }

    _show(candidate);
  }

  AdminBroadcastModel? _pickBannerCandidate(
    List<AdminBroadcastModel> inboxBroadcasts,
  ) {
    for (final message in inboxBroadcasts) {
      if (!message.isForced) {
        return message;
      }
    }
    return null;
  }

  void showFromSocket(AdminBroadcastModel message) {
    if (message.isForced) {
      return;
    }

    _hiddenBannerIds.remove(message.id);
    _show(message);
  }

  void _show(AdminBroadcastModel message) {
    _autoDismissTimer?.cancel();
    state = BroadcastBannerState(visibleMessage: message);
    _autoDismissTimer = Timer(broadcastBannerAutoDismissDuration, hideBanner);
  }

  void hideBanner() {
    final messageId = state.visibleMessage?.id;
    if (messageId != null) {
      _hiddenBannerIds.add(messageId);
    }
    _hideVisible();
  }

  void _hideVisible() {
    _autoDismissTimer?.cancel();
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
