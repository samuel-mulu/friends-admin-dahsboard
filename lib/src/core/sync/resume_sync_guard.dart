/// Global in-flight flag for the canonical live resume/reconnect sync.
///
/// When true, every other resume/reconnect handler must return immediately.
class ResumeSyncGuard {
  ResumeSyncGuard._();

  static bool inFlight = false;

  /// Visible for tests only.
  static void resetForTest() {
    inFlight = false;
    ResumeAuxiliaryRefreshGate.resetForTest();
    AppBackgroundResumeGate.resetForTest();
  }
}

/// Whether a foreground return should trigger the full resume/reconnect sync path.
class AppBackgroundResumeDecision {
  const AppBackgroundResumeDecision._({
    required this.shouldRunFullResumeSync,
    required this.reason,
  });

  final bool shouldRunFullResumeSync;
  final String reason;

  factory AppBackgroundResumeDecision.run(String reason) {
    return AppBackgroundResumeDecision._(
      shouldRunFullResumeSync: true,
      reason: reason,
    );
  }

  factory AppBackgroundResumeDecision.skip(String reason) {
    return AppBackgroundResumeDecision._(
      shouldRunFullResumeSync: false,
      reason: reason,
    );
  }
}

/// Tracks how long the app was backgrounded and whether the socket dropped.
class AppBackgroundResumeGate {
  AppBackgroundResumeGate._();

  static DateTime? _backgroundedAt;
  static bool _socketDisconnectedWhileBackgrounded = false;
  static bool _isBackgrounded = false;

  static const resumeThreshold = Duration(seconds: 2);

  static bool get isBackgrounded => _isBackgrounded;

  static void onAppBackgrounded({DateTime? at}) {
    _isBackgrounded = true;
    _backgroundedAt ??= at ?? DateTime.now();
  }

  static void onSocketDisconnected() {
    if (_isBackgrounded || _backgroundedAt != null) {
      _socketDisconnectedWhileBackgrounded = true;
    }
  }

  static AppBackgroundResumeDecision evaluateFullResumeSync({
    required bool socketConnectedNow,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final backgroundedAt = _backgroundedAt;
    final disconnectedWhileAway = _socketDisconnectedWhileBackgrounded;

    _backgroundedAt = null;
    _socketDisconnectedWhileBackgrounded = false;
    _isBackgrounded = false;

    if (backgroundedAt == null) {
      return AppBackgroundResumeDecision.run('no_background_record');
    }

    final away = at.difference(backgroundedAt);

    if (disconnectedWhileAway) {
      return AppBackgroundResumeDecision.run('socket_disconnected_while_away');
    }

    if (!socketConnectedNow) {
      return AppBackgroundResumeDecision.run('socket_disconnected_on_resume');
    }

    if (away < resumeThreshold) {
      return AppBackgroundResumeDecision.skip(
        'quick_return_${away.inMilliseconds}ms',
      );
    }

    return AppBackgroundResumeDecision.run('away_${away.inSeconds}s');
  }

  /// Visible for tests only.
  static void resetForTest() {
    _backgroundedAt = null;
    _socketDisconnectedWhileBackgrounded = false;
    _isBackgrounded = false;
  }

  /// Visible for tests only.
  static void setBackgroundedAtForTest(
    DateTime at, {
    bool socketDisconnectedWhileBackgrounded = false,
  }) {
    _backgroundedAt = at;
    _isBackgrounded = true;
    _socketDisconnectedWhileBackgrounded = socketDisconnectedWhileBackgrounded;
  }
}

/// Throttles wallet + registration refetches on rapid [app_resume] focus churn.
class ResumeAuxiliaryRefreshGate {
  ResumeAuxiliaryRefreshGate._();

  static DateTime? _lastWalletRegistrationRefreshAt;
  static const _window = Duration(seconds: 2);

  static bool shouldRunWalletRegistration({
    required String syncReason,
    required bool force,
  }) {
    if (force || !syncReason.contains('app_resume')) {
      _lastWalletRegistrationRefreshAt = DateTime.now();
      return true;
    }

    final now = DateTime.now();
    final last = _lastWalletRegistrationRefreshAt;
    if (last != null && now.difference(last) < _window) {
      return false;
    }

    _lastWalletRegistrationRefreshAt = now;
    return true;
  }

  /// Visible for tests only.
  static void resetForTest() {
    _lastWalletRegistrationRefreshAt = null;
  }
}
