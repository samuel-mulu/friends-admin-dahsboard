class CurrentCartelaSnapshotToken {
  const CurrentCartelaSnapshotToken({
    required this.sessionId,
    required this.revisionAtStart,
  });

  final String sessionId;
  final int revisionAtStart;
}

class CurrentCartelaSnapshotGuard {
  String? _currentSessionId;
  int _currentRevision = 0;

  String? get currentSessionId => _currentSessionId;
  int get currentRevision => _currentRevision;

  void reset(String? sessionId) {
    if (_currentSessionId == sessionId) {
      return;
    }
    _currentSessionId = sessionId;
    _currentRevision = 0;
  }

  void bumpForConfirmedRegistration(String sessionId) {
    if (_currentSessionId != sessionId) {
      return;
    }
    _currentRevision += 1;
  }

  CurrentCartelaSnapshotToken capture(String sessionId) {
    final revisionAtStart = _currentSessionId == sessionId
        ? _currentRevision
        : 0;
    return CurrentCartelaSnapshotToken(
      sessionId: sessionId,
      revisionAtStart: revisionAtStart,
    );
  }

  bool canApply(
    CurrentCartelaSnapshotToken token, {
    required String responseSessionId,
  }) {
    return responseSessionId == _currentSessionId &&
        token.sessionId == _currentSessionId &&
        token.revisionAtStart == _currentRevision;
  }
}
