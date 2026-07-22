import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';

typedef SocketEventListener = void Function(dynamic data);

class SocketService {
  SocketService(this._config);

  static const _guestMarker = '__guest__';

  final AppConfig _config;
  final Map<String, List<SocketEventListener>> _listeners =
      <String, List<SocketEventListener>>{};
  io.Socket? _socket;
  String? _activeAuthSignature;

  bool get isConnected => _socket?.connected ?? false;

  bool get hasActiveSocket => _socket != null;

  bool get isGuestConnection =>
      _activeAuthSignature?.startsWith('guest:') ?? false;

  void connect(String token, {String? deviceId}) {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      return;
    }

    final authSignature = _buildAuthSignature(
      mode: 'auth',
      token: normalizedToken,
      deviceId: deviceId,
    );

    if (_socket != null && _activeAuthSignature == authSignature) {
      return;
    }

    _disposeSocket();

    _socket = io.io(
      '${_config.socketBaseUrl}/realtime',
      io.OptionBuilder()
          .disableAutoConnect()
          .setPath('/socket.io')
          .setAuth({
            'token': normalizedToken,
            if (deviceId != null && deviceId.trim().isNotEmpty)
              'deviceId': deviceId.trim(),
          })
          .enableForceNew()
          .disableMultiplex()
          .enableReconnection()
          .setTransports(kIsWeb ? ['polling', 'websocket'] : ['websocket'])
          .build(),
    );

    _activeAuthSignature = authSignature;
    _attachRegisteredListeners();
    _socket?.connect();
  }

  void connectAsGuest({String? deviceId}) {
    final authSignature = _buildAuthSignature(
      mode: 'guest',
      token: _guestMarker,
      deviceId: deviceId,
    );

    if (_socket != null && _activeAuthSignature == authSignature) {
      return;
    }

    _disposeSocket();

    _socket = io.io(
      '${_config.socketBaseUrl}/realtime',
      io.OptionBuilder()
          .disableAutoConnect()
          .setPath('/socket.io')
          .setAuth({
            if (deviceId != null && deviceId.trim().isNotEmpty)
              'deviceId': deviceId.trim(),
          })
          .enableForceNew()
          .disableMultiplex()
          .enableReconnection()
          .setTransports(kIsWeb ? ['polling', 'websocket'] : ['websocket'])
          .build(),
    );

    _activeAuthSignature = authSignature;
    _attachRegisteredListeners();
    _socket?.connect();
  }

  void disconnect() {
    _disposeSocket();
    _activeAuthSignature = null;
  }

  void joinSession(String sessionId) {
    if (isGuestConnection) {
      return;
    }

    _socket?.emit('game:join', {'sessionId': sessionId});
  }

  void leaveSession(String sessionId) {
    if (isGuestConnection) {
      return;
    }

    _socket?.emit('game:leave', {'sessionId': sessionId});
  }

  void joinGame(String sessionId) => joinSession(sessionId);
  void leaveGame(String sessionId) => leaveSession(sessionId);

  void on(String event, SocketEventListener listener) {
    final listeners = _listeners.putIfAbsent(event, () => []);
    if (listeners.contains(listener)) {
      return;
    }

    listeners.add(listener);
    _socket?.on(event, listener);
  }

  void off(String event, [SocketEventListener? listener]) {
    if (listener != null) {
      _listeners[event]?.remove(listener);
      if (_listeners[event]?.isEmpty ?? false) {
        _listeners.remove(event);
      }
      _socket?.off(event, listener);
      return;
    }

    _listeners.remove(event);
    _socket?.off(event);
  }

  void _attachRegisteredListeners() {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    for (final entry in _listeners.entries) {
      for (final listener in entry.value) {
        socket.on(entry.key, listener);
      }
    }
  }

  void _disposeSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  String _buildAuthSignature({
    required String mode,
    required String token,
    String? deviceId,
  }) {
    return '$mode:$token:${deviceId?.trim() ?? ''}';
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService(ref.watch(appConfigProvider));
  ref.onDispose(service.disconnect);
  return service;
});
