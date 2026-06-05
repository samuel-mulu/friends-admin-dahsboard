import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';

class SocketService {
  SocketService(this._config);

  final AppConfig _config;
  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String token) {
    disconnect();

    _socket = io.io(
      '${_config.socketBaseUrl}/realtime',
      io.OptionBuilder()
          .disableAutoConnect()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket?.connect();
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
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
