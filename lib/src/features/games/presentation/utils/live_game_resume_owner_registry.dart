/// Tracks active [LiveGameScreen] instances so global app-resume sync can defer
/// to the live game's coalesced resume path.
///
/// Intentionally not a Riverpod provider — updating provider state from widget
/// lifecycle or during another provider's build violates Riverpod rules.
class LiveGameResumeOwnerRegistry {
  LiveGameResumeOwnerRegistry._();

  static int _ownerCount = 0;

  static void activate() {
    _ownerCount++;
  }

  static void deactivate() {
    if (_ownerCount > 0) {
      _ownerCount--;
    }
  }

  static bool get isActive => _ownerCount > 0;

  /// Visible for tests only.
  static int get ownerCount => _ownerCount;

  /// Visible for tests only.
  static void resetForTest() {
    _ownerCount = 0;
  }
}
