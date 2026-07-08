/// Tracks which game session room the client has joined over the socket.
class LiveSocketSessionMembership {
  String? joinedSessionId;

  /// Applies [sessionId] as the sole active membership.
  ///
  /// Leaves the previous session before joining a new one. Passing null clears
  /// membership. Repeated calls with the same id are no-ops.
  void apply(
    String? sessionId, {
    required void Function(String sessionId) join,
    required void Function(String sessionId) leave,
  }) {
    if (joinedSessionId == sessionId) {
      return;
    }

    final previousSessionId = joinedSessionId;
    joinedSessionId = sessionId;

    if (previousSessionId != null) {
      leave(previousSessionId);
    }

    if (sessionId != null) {
      join(sessionId);
    }
  }
}
