
/// Coordinates app resume, background-to-foreground transitions,
/// network reconnect lock-outs, and operations cache refreshes.
class LiveResumeSyncCoordinator {
  bool _syncInProgress = false;
  DateTime? _lastSyncCompletedAt;

  bool get isSyncInProgress => _syncInProgress;
  DateTime? get lastSyncCompletedAt => _lastSyncCompletedAt;

  bool tryAcquireSyncLock() {
    if (_syncInProgress) return false;
    _syncInProgress = true;
    return true;
  }

  void releaseSyncLock() {
    _syncInProgress = false;
    _lastSyncCompletedAt = DateTime.now();
  }

  bool isSyncStale(Duration threshold) {
    final last = _lastSyncCompletedAt;
    if (last == null) return true;
    return DateTime.now().difference(last) > threshold;
  }

  bool shouldThrottleResumeSync({Duration throttle = const Duration(milliseconds: 750)}) {
    final last = _lastSyncCompletedAt;
    if (last == null) return false;
    return DateTime.now().difference(last) < throttle;
  }

  void reset() {
    _syncInProgress = false;
    _lastSyncCompletedAt = null;
  }

  void dispose() {
    reset();
  }
}
