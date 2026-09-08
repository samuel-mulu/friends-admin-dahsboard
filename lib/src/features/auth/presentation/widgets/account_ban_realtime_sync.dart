import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/socket_service.dart';
import '../../../games/presentation/utils/socket_payload_normalizer.dart';
import '../../session/session_manager.dart';
import '../controllers/auth_controller.dart';
import '../providers/account_ban_provider.dart';

/// Listens for per-user ban / unban socket events while authenticated.
class AccountBanRealtimeSync extends ConsumerStatefulWidget {
  const AccountBanRealtimeSync({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AccountBanRealtimeSync> createState() =>
      _AccountBanRealtimeSyncState();
}

class _AccountBanRealtimeSyncState
    extends ConsumerState<AccountBanRealtimeSync> {
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

    _socketService.on('user:blocked', _onUserBlocked);
    _socketService.on('user:unblocked', _onUserUnblocked);
    _listenersBound = true;
  }

  void _unbindListeners() {
    if (!_listenersBound) {
      return;
    }

    _socketService.off('user:blocked', _onUserBlocked);
    _socketService.off('user:unblocked', _onUserUnblocked);
    _listenersBound = false;
  }

  void _onUserBlocked(dynamic payload) {
    if (!mounted) {
      return;
    }

    final normalized = normalizeSocketPayload(payload);
    final reason = normalized?['reason'];
    ref.read(accountBanProvider.notifier).show(
          reason: reason is String ? reason : null,
        );

    unawaited(
      ref.read(sessionManagerProvider.notifier).clearLocalSession(),
    );
  }

  void _onUserUnblocked(dynamic _) {
    if (!mounted) {
      return;
    }

    ref.read(accountBanProvider.notifier).clear();
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
      });
    });

    return widget.child;
  }
}
