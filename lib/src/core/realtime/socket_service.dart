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
  final Set<String> _boundDispatchEvents = <String>{};
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
    _ensureDispatchBound(event);
  }

  void off(String event, [SocketEventListener? listener]) {
    if (listener != null) {
      _listeners[event]?.remove(listener);
      if (_listeners[event]?.isEmpty ?? false) {
        _listeners.remove(event);
        _unbindDispatch(event);
      }
      return;
    }

    _listeners.remove(event);
    _unbindDispatch(event);
  }

  void _ensureDispatchBound(String event) {
    final socket = _socket;
    if (socket == null || _boundDispatchEvents.contains(event)) {
      return;
    }

    socket.on(event, (dynamic data) => _dispatch(event, data));
    _boundDispatchEvents.add(event);
  }

  void _unbindDispatch(String event) {
    if (!_boundDispatchEvents.remove(event)) {
      return;
    }
    _socket?.off(event);
  }

  void _dispatch(String event, dynamic data) {
    final listeners = _listeners[event];
    if (listeners == null || listeners.isEmpty) {
      return;
    }

    // Copy so listeners can safely register/unregister during dispatch.
    for (final listener in List<SocketEventListener>.from(listeners)) {
      try {
        listener(data);
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            '[SocketService] Listener error for $event: $error\n$stackTrace',
          );
        }
      }
    }
  }

  void _attachRegisteredListeners() {
    _boundDispatchEvents.clear();
    for (final event in _listeners.keys) {
      _ensureDispatchBound(event);
    }
  }

  void _disposeSocket() {
    _boundDispatchEvents.clear();
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
