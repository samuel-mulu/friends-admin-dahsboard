/// Prevents countdown UI from jumping back to a large value after reaching 0
/// unless the backend publishes a newer deadline.
class CountdownTargetTracker {
  DateTime? _target;
  String? _scopeKey;
  bool _latchedAtZero = false;

  int apply({
    required DateTime? target,
    required String? scopeKey,
    required int rawRemaining,
  }) {
    if (target == null) {
      reset();
      return 0;
    }

    final targetChanged = _target != target || _scopeKey != scopeKey;
    if (targetChanged) {
      final isNewerTarget =
          _target != null && target.isAfter(_target!) && _scopeKey == scopeKey;
      _target = target;
      _scopeKey = scopeKey;
      if (isNewerTarget || !_latchedAtZero) {
        _latchedAtZero = rawRemaining <= 0;
        return rawRemaining > 0 ? rawRemaining : 0;
      }
    }

    if (_latchedAtZero && rawRemaining > 0) {
      return 0;
    }

    if (rawRemaining <= 0) {
      _latchedAtZero = true;
      return 0;
    }

    _latchedAtZero = false;
    return rawRemaining;
  }

  void reset() {
    _target = null;
    _scopeKey = null;
    _latchedAtZero = false;
  }
}
