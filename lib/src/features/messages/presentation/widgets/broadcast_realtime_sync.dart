import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/resume_sync_guard.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../games/presentation/utils/live_game_resume_owner_registry.dart';
import '../../../games/presentation/utils/socket_payload_normalizer.dart';
import '../../data/models/admin_broadcast_model.dart';
import '../providers/broadcast_banner_provider.dart';
import '../providers/broadcasts_provider.dart';
import 'broadcast_message_snackbar.dart';
import '../../../../core/realtime/socket_service.dart';

/// Keeps admin broadcast socket listeners fresh across all tabs.
///
/// Does not run resume/reconnect fetches — [syncAppAfterResume] and live-game
/// resume sync own canonical refresh.
class BroadcastRealtimeSync extends ConsumerStatefulWidget {
  const BroadcastRealtimeSync({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<BroadcastRealtimeSync> createState() =>
      _BroadcastRealtimeSyncState();
}

class _BroadcastRealtimeSyncState extends ConsumerState<BroadcastRealtimeSync> {
  SocketService? _socketService;
  ProviderSubscription<AuthState>? _authSubscription;
  bool _socketListenersBound = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _install();
    });
  }

  void _install() {
    _socketService ??= ref.read(socketServiceProvider);
    _syncBroadcastListener();

    _authSubscription ??= ref.listenManual<AuthState>(
      authControllerProvider,
      (previous, next) {
        final hadSession = previous?.session != null;
        final hasSession = next.session != null;
        if (hadSession == hasSession) {
          return;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }

          _syncBroadcastListener();
          if (hasSession) {
            ref.invalidate(broadcastsProvider);
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _authSubscription = null;
    _unbindSocketListeners();
    super.dispose();
  }

  void _syncBroadcastListener() {
    final socket = _socketService;
    if (socket == null) {
      return;
    }

    _unbindSocketListeners();

    if (ref.read(authControllerProvider).session == null) {
      return;
    }

    socket.on('admin:broadcast', _onAdminBroadcast);
    socket.on('admin:broadcast_removed', _onAdminBroadcastRemoved);
    socket.on('connect', _onSocketReconnect);
    _socketListenersBound = true;
  }

  void _unbindSocketListeners() {
    final socket = _socketService;
    if (socket == null || !_socketListenersBound) {
      return;
    }

    socket.off('admin:broadcast', _onAdminBroadcast);
    socket.off('admin:broadcast_removed', _onAdminBroadcastRemoved);
    socket.off('connect', _onSocketReconnect);
    _socketListenersBound = false;
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

    final message = AdminBroadcastModel.fromJson(normalized);
    ref.read(broadcastsProvider.notifier).addFromSocket(message);
    ref.read(broadcastBannerProvider.notifier).showFromSocket(message);
    showBroadcastMessageSnackBar(context, ref, message);
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
      unawaited(ref.read(broadcastsProvider.notifier).refresh());
      return;
    }

    ref.read(broadcastsProvider.notifier).removeFromSocket(id);
  }

  void _onSocketReconnect(dynamic _) {
    if (!mounted) {
      return;
    }

    if (ResumeSyncGuard.inFlight || LiveGameResumeOwnerRegistry.isActive) {
      return;
    }

    _syncBroadcastListener();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
