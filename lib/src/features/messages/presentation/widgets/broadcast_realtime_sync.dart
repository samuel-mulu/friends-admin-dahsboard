import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../games/presentation/utils/socket_payload_normalizer.dart';
import '../../data/models/admin_broadcast_model.dart';
import '../providers/broadcast_banner_provider.dart';
import '../providers/broadcasts_provider.dart';
import '../../../../core/realtime/socket_service.dart';

/// Keeps admin broadcast socket listeners bound while the shell is mounted.
///
/// On connect/reconnect: refreshes inbox only (does not unbind/rebind listeners).
/// New messages while connected arrive via [admin:broadcast].
class BroadcastRealtimeSync extends ConsumerStatefulWidget {
  const BroadcastRealtimeSync({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<BroadcastRealtimeSync> createState() =>
      _BroadcastRealtimeSyncState();
}

class _BroadcastRealtimeSyncState extends ConsumerState<BroadcastRealtimeSync> {
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

    _socketService.on('admin:broadcast', _onAdminBroadcast);
    _socketService.on('admin:broadcast_removed', _onAdminBroadcastRemoved);
    _socketService.on('connect', _onSocketConnect);
    _listenersBound = true;

    // connect already fired before we bound — catch up immediately.
    if (_socketService.isConnected) {
      _refreshInbox();
    }
  }

  void _unbindListeners() {
    if (!_listenersBound) {
      return;
    }

    _socketService.off('admin:broadcast', _onAdminBroadcast);
    _socketService.off('admin:broadcast_removed', _onAdminBroadcastRemoved);
    _socketService.off('connect', _onSocketConnect);
    _listenersBound = false;
  }

  void _refreshInbox() {
    if (!mounted || ref.read(authControllerProvider).session == null) {
      return;
    }

    unawaited(ref.read(broadcastsProvider.notifier).refresh(quiet: true));
  }

  void _onAdminBroadcast(dynamic payload) {
    if (!mounted) {
      return;
    }

    final normalized = normalizeSocketPayload(payload);
    if (normalized == null) {
      if (kDebugMode) {
        debugPrint(
          '[Broadcasts/Socket] Invalid admin:broadcast payload: '
          '${payload.runtimeType}',
        );
      }
      return;
    }

    try {
      final message = AdminBroadcastModel.fromJson(normalized);
      ref.read(broadcastsProvider.notifier).addFromSocket(message);
      ref.read(broadcastBannerProvider.notifier).showFromSocket(message);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[Broadcasts/Socket] Failed to parse admin:broadcast: $error\n'
          '$stackTrace',
        );
      }
    }
  }

  void _onAdminBroadcastRemoved(dynamic payload) {
    if (!mounted) {
      return;
    }

    final normalized = normalizeSocketPayload(payload);
    final id = readSocketEntityId(normalized);
    if (id == null) {
      if (kDebugMode) {
        final keys = normalized?.keys.join(', ') ?? 'null';
        debugPrint(
          '[Broadcasts/Socket] Invalid admin:broadcast_removed payload: '
          '${payload.runtimeType} keys=[$keys]',
        );
      }
      _refreshInbox();
      return;
    }

    ref.read(broadcastsProvider.notifier).removeFromSocket(id);
  }

  void _onSocketConnect(dynamic _) {
    // Do not unbind/rebind here — that drops listeners mid-connect.
    _refreshInbox();
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
          ref.invalidate(broadcastsProvider);
        }
      });
    });

    return widget.child;
  }
}
