import '../../data/models/game_model.dart';

/// Short-lived snapshot cache for `operations/current` during resume bursts.
class GameOperationsResumeCache {
  GameOperationsResumeCache._();

  static final GameOperationsResumeCache shared = GameOperationsResumeCache._();

  static const ttl = Duration(seconds: 2);

  GameOperationsCurrentResponse? _snapshot;
  DateTime? _capturedAt;

  void put(GameOperationsCurrentResponse snapshot, {DateTime? capturedAt}) {
    _snapshot = snapshot;
    _capturedAt = capturedAt ?? DateTime.now();
  }

  GameOperationsCurrentResponse? getIfFresh({DateTime? now}) {
    final capturedAt = _capturedAt;
    final snapshot = _snapshot;
    if (capturedAt == null || snapshot == null) {
      return null;
    }

    final clock = now ?? DateTime.now();
    if (clock.difference(capturedAt) > ttl) {
      clear();
      return null;
    }

    return snapshot;
  }

  void clear() {
    _snapshot = null;
    _capturedAt = null;
  }

  void resetForTest() {
    clear();
  }
}
