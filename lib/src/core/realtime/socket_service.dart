import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';

class SocketService {
  SocketService(this._config);

  final AppConfig _config;
  io.Socket? _socket;
  String? _activeToken;

  bool get isConnected => _socket?.connected ?? false;

  bool get hasActiveSocket => _socket != null;

  void connect(String token) {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      return;
    }

    if (_socket != null && _activeToken == normalizedToken) {
      return;
    }

    disconnect();

    _socket = io.io(
      '${_config.socketBaseUrl}/realtime',
      io.OptionBuilder()
          .disableAutoConnect()
          .setPath('/socket.io')
          .setAuth({'token': normalizedToken})
          .enableForceNew()
          .disableMultiplex()
          .enableReconnection()
          .setTransports(kIsWeb ? ['polling', 'websocket'] : ['websocket'])
          .build(),
    );

    _activeToken = normalizedToken;
    _socket?.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _activeToken = null;
  }

  void joinSession(String sessionId) {
    _socket?.emit('game:join', {'sessionId': sessionId});
  }

  void leaveSession(String sessionId) {
    _socket?.emit('game:leave', {'sessionId': sessionId});
  }

  // Kept for backwards compatibility — delegates to joinSession/leaveSession.
  void joinGame(String sessionId) => joinSession(sessionId);
  void leaveGame(String sessionId) => leaveSession(sessionId);

  void on(String event, void Function(dynamic data) listener) {
    _socket?.on(event, listener);
  }

  void off(String event, [void Function(dynamic data)? listener]) {
    _socket?.off(event, listener);
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService(ref.watch(appConfigProvider));
  ref.onDispose(service.disconnect);
  return service;
});
