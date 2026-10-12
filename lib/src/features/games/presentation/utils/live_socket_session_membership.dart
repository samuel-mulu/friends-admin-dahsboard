import 'dart:async';

/// Tracks desired membership separately from a server-acknowledged join.
class LiveSocketSessionMembership {
  String? joinedSessionId;
  String? desiredSessionId;
  String? _userId;
  bool _connected = true;
  bool _foreground = true;
  bool _disposed = false;
  int _generation = 0;
  int _retries = 0;
  int? _inFlightGeneration;
  Timer? _retry;
  Future<bool> Function(String)? _join;
  void Function()? _onChanged;
  static const _backoff = [1, 2, 4, 8];

  void _invalidate() {
    _generation++;
    _retry?.cancel();
    _retry = null;
    _inFlightGeneration = null;
    _retries = 0;
    joinedSessionId = null;
  }

  void onDisconnected() {
    _connected = false;
    _invalidate();
    _onChanged?.call();
  }

  void onConnected() {
    _connected = true;
    _retries = 0;
  }

  void setForeground(bool foreground) {
    _foreground = foreground;
    _retry?.cancel();
    _retry = null;
    if (foreground) {
      _retries = 0;
      _tryJoin();
    }
  }

  void apply(
    String? sessionId, {
    required Future<bool> Function(String sessionId) join,
    required void Function(String sessionId) leave,
    String? userId,
    bool connected = true,
    void Function()? onChanged,
  }) {
    if (_disposed) return;
    _join = join;
    _onChanged = onChanged;
    _connected = connected;
    if (desiredSessionId != sessionId || _userId != userId) {
      final previous = desiredSessionId;
      _invalidate();
      desiredSessionId = sessionId;
      _userId = userId;
      // An unacknowledged request may still have joined on the server.
      if (previous != null && _connected) leave(previous);
      _onChanged?.call();
    }
    _tryJoin();
  }

  void _tryJoin() {
    final session = desiredSessionId;
    if (_disposed ||
        !_foreground ||
        !_connected ||
        session == null ||
        joinedSessionId == session ||
        _inFlightGeneration == _generation ||
        _retry != null ||
        _retries > _backoff.length) {
      return;
    }
    final generation = _generation;
    _inFlightGeneration = generation;
    unawaited(_completeJoin(session, generation));
  }

  Future<void> _completeJoin(String session, int generation) async {
    var acknowledged = false;
    try {
      acknowledged = await _join!(session);
    } catch (_) {
      // Unauthorized, missing ACK and network errors all remain unconfirmed.
    }
    if (_disposed || generation != _generation) return;
    _inFlightGeneration = null;
    if (acknowledged && _connected) {
      joinedSessionId = session;
      _retry?.cancel();
      _retry = null;
      _onChanged?.call();
    } else if (_foreground && _connected && _retries < _backoff.length) {
      _retry = Timer(Duration(seconds: _backoff[_retries++]), () {
        _retry = null;
        _tryJoin();
      });
    } else {
      // Exhaust this burst; reconnect/resume permits another bounded burst.
      _retries = _backoff.length + 1;
    }
  }

  void dispose() {
    _disposed = true;
    _invalidate();
    desiredSessionId = null;
    _onChanged = null;
  }
}
