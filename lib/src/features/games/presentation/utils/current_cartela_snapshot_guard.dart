class CurrentCartelaSnapshotToken {
  const CurrentCartelaSnapshotToken({
    required this.sessionId,
    required this.revisionAtStart,
    this.requestSeq,
  });

  final String sessionId;
  final int revisionAtStart;
  final int? requestSeq;
}

class CurrentCartelaSnapshotGuard {
  String? _currentSessionId;
  int _currentRevision = 0;
  int _nextRequestSeq = 0;
  int _lastAppliedRequestSeq = 0;

  String? get currentSessionId => _currentSessionId;
  int get currentRevision => _currentRevision;
  int get lastAppliedRequestSeq => _lastAppliedRequestSeq;

  void reset(String? sessionId) {
    if (_currentSessionId == sessionId) {
      return;
    }
    _currentSessionId = sessionId;
    _currentRevision = 0;
    _nextRequestSeq = 0;
    _lastAppliedRequestSeq = 0;
  }

  void bumpForConfirmedRegistration(String sessionId) {
    if (_currentSessionId != sessionId) {
      return;
    }
    _currentRevision += 1;
    _nextRequestSeq = 0;
    _lastAppliedRequestSeq = 0;
  }

  /// Legacy capture for next-registration guard (revision only, no request seq).
  CurrentCartelaSnapshotToken capture(String sessionId) {
    final revisionAtStart = _revisionAtStartFor(sessionId);
    return CurrentCartelaSnapshotToken(
      sessionId: sessionId,
      revisionAtStart: revisionAtStart,
    );
  }

  /// Remote `/my-cartelas` fetch: assigns monotonic request sequence per revision.
  CurrentCartelaSnapshotToken captureForFetch(String sessionId) {
    final revisionAtStart = _revisionAtStartFor(sessionId);
    final requestSeq = ++_nextRequestSeq;
    return CurrentCartelaSnapshotToken(
      sessionId: sessionId,
      revisionAtStart: revisionAtStart,
      requestSeq: requestSeq,
    );
  }

  int _revisionAtStartFor(String sessionId) {
    return _currentSessionId == sessionId ? _currentRevision : 0;
  }

  bool canApply(
    CurrentCartelaSnapshotToken token, {
    required String responseSessionId,
  }) {
    return responseSessionId == _currentSessionId &&
        token.sessionId == _currentSessionId &&
        token.revisionAtStart == _currentRevision;
  }

  bool canApplyRemote(
    CurrentCartelaSnapshotToken token, {
    required String responseSessionId,
  }) {
    final requestSeq = token.requestSeq;
    if (requestSeq == null) {
      return false;
    }
    if (!canApply(token, responseSessionId: responseSessionId)) {
      return false;
    }
    return requestSeq > _lastAppliedRequestSeq;
  }

  void markRemoteApplied(CurrentCartelaSnapshotToken token) {
    final requestSeq = token.requestSeq;
    if (requestSeq == null) {
      return;
    }
    if (requestSeq > _lastAppliedRequestSeq) {
      _lastAppliedRequestSeq = requestSeq;
    }
  }
}
