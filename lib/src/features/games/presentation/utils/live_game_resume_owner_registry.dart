/// Tracks active [LiveGameScreen] instances so global app-resume sync can defer
/// to the live game's coalesced resume path.
///
/// Intentionally not a Riverpod provider — updating provider state from widget
/// lifecycle or during another provider's build violates Riverpod rules.
class LiveGameResumeOwnerRegistry {
  LiveGameResumeOwnerRegistry._();

  static int _ownerCount = 0;
  static Future<void> Function()? _onMasterRefresh;

  static void activate() {
    _ownerCount++;
  }

  static void deactivate() {
    if (_ownerCount > 0) {
      _ownerCount--;
    }
    if (_ownerCount == 0) {
      _onMasterRefresh = null;
    }
  }

  static bool get isActive => _ownerCount > 0;

  /// Registers the live screen's soft-sync handler for the shell header refresh.
  static void setMasterRefresh(Future<void> Function()? handler) {
    _onMasterRefresh = handler;
  }

  /// Runs the live master-refresh handler when a live screen owns resume.
  /// Returns `true` when the live handler was invoked.
  static Future<bool> runMasterRefreshIfActive() async {
    final handler = _onMasterRefresh;
    if (!isActive || handler == null) {
      return false;
    }
    await handler();
    return true;
  }

  /// Visible for tests only.
  static int get ownerCount => _ownerCount;

  /// Visible for tests only.
  static void resetForTest() {
    _ownerCount = 0;
    _onMasterRefresh = null;
  }
}
