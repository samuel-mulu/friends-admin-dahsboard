import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/socket_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../games/presentation/utils/socket_payload_normalizer.dart';
import '../providers/support_messages_provider.dart';
import '../providers/support_unread_provider.dart';

/// Keeps support-reply socket listeners bound while the shell is mounted.
///
/// New admin replies arrive via [support:reply] to the signed-in player.
class SupportRealtimeSync extends ConsumerStatefulWidget {
  const SupportRealtimeSync({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<SupportRealtimeSync> createState() =>
      _SupportRealtimeSyncState();
}

class _SupportRealtimeSyncState extends ConsumerState<SupportRealtimeSync> {
  late final SocketService _socketService;
  bool _listenersBound = false;

  @override
  void initState() {
    super.initState();
    _socketService = ref.read(socketServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncListeners();
    });
  }

  @override
  void dispose() {
    _unbindListeners();
    super.dispose();
  }

  void _syncListeners() {
    _unbindListeners();

    if (ref.read(authControllerProvider).session == null) {
      return;
    }

    _socketService.on('support:reply', _onSupportReply);
    _socketService.on('connect', _onSocketConnect);
    _listenersBound = true;

    if (_socketService.isConnected) {
      _refreshUnread();
    }
  }

  void _unbindListeners() {
    if (!_listenersBound) {
      return;
    }

    _socketService.off('support:reply', _onSupportReply);
    _socketService.off('connect', _onSocketConnect);
    _listenersBound = false;
  }

  void _refreshUnread() {
    if (!mounted || ref.read(authControllerProvider).session == null) {
      return;
    }

    unawaited(
      ref.read(supportUnreadCountProvider.notifier).refresh(quiet: true),
    );
  }

  void _onSupportReply(dynamic payload) {
    if (!mounted) {
      return;
    }

    final normalized = normalizeSocketPayload(payload);
    if (normalized == null) {
      if (kDebugMode) {
        debugPrint(
          '[Support/Socket] Invalid support:reply payload: '
          '${payload.runtimeType}',
        );
      }
      _refreshUnread();
      return;
    }

    ref.read(supportUnreadCountProvider.notifier).bumpFromSocket();
    ref.invalidate(mySupportMessagesProvider);
  }

  void _onSocketConnect(dynamic _) {
    _refreshUnread();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      final hadSession = previous?.session != null;
      final hasSession = next.session != null;
      if (hadSession == hasSession) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _syncListeners();
        if (hasSession) {
          ref.invalidate(supportUnreadCountProvider);
        }
      });
    });

    return widget.child;
  }
}
