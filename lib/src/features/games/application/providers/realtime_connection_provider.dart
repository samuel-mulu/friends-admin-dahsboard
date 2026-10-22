import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/socket_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/live_connection_status.dart';

final realtimeConnectionProvider =
    NotifierProvider<RealtimeConnectionNotifier, LiveConnectionStatus>(
  RealtimeConnectionNotifier.new,
);

class RealtimeConnectionNotifier extends Notifier<LiveConnectionStatus> {
  void Function(dynamic)? _onConnect;
  void Function(dynamic)? _onDisconnect;
  void Function(dynamic)? _onConnectError;

  @override
  LiveConnectionStatus build() {
    ref.watch(authControllerProvider);
    final socket = ref.watch(socketServiceProvider);
    _bind(socket);
    ref.onDispose(() => _unbind(socket));
    return _readStatus(socket);
  }

  LiveConnectionStatus _readStatus(SocketService socket) {
    if (socket.isConnected) {
      return LiveConnectionStatus.live;
    }
    if (socket.hasActiveSocket) {
      return LiveConnectionStatus.reconnecting;
    }
    return LiveConnectionStatus.offline;
  }

  void _sync(SocketService socket) {
    final next = _readStatus(socket);
    if (next != state) {
      state = next;
    }
  }

  void _bind(SocketService socket) {
    _unbind(socket);
    _onConnect = (_) => _sync(socket);
    _onDisconnect = (_) => _sync(socket);
    _onConnectError = (_) => _sync(socket);
    socket.on('connect', _onConnect!);
    socket.on('disconnect', _onDisconnect!);
    socket.on('connect_error', _onConnectError!);
  }

  void _unbind(SocketService socket) {
    if (_onConnect != null) {
      socket.off('connect', _onConnect);
    }
    if (_onDisconnect != null) {
      socket.off('disconnect', _onDisconnect);
    }
    if (_onConnectError != null) {
      socket.off('connect_error', _onConnectError);
    }
    _onConnect = null;
    _onDisconnect = null;
    _onConnectError = null;
  }
}
