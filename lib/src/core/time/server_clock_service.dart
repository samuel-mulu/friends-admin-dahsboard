/// Keeps device time aligned with backend canonical responses.
class ServerClockService {
  static const _snapDeltaMs = 2000;
  static const _emaNewWeight = 0.7;

  int? _offsetMs;
  DateTime? _lastServerNowUtc;

  bool get isSynced => _offsetMs != null;

  DateTime? get lastServerNowUtc => _lastServerNowUtc;

  Duration? get offset =>
      _offsetMs == null ? null : Duration(milliseconds: _offsetMs!);

  int? get offsetMs => _offsetMs;

  /// Aligns local clock to [serverNowUtc].
  ///
  /// When [snap] is true, or on first sync, or when the delta exceeds 2s,
  /// the offset is applied immediately. Otherwise it is smoothed with EMA.
  ///
  /// Returns false when [serverNowUtc] is older than the last accepted sample
  /// and [ignoreOlder] is true.
  bool sync(DateTime serverNowUtc, {bool snap = false, bool ignoreOlder = false}) {
    final normalized = serverNowUtc.toUtc();
    if (ignoreOlder &&
        _lastServerNowUtc != null &&
        normalized.isBefore(_lastServerNowUtc!)) {
      return false;
    }
    final deviceNowUtc = DateTime.now().toUtc();
    final newOffsetMs =
        normalized.millisecondsSinceEpoch - deviceNowUtc.millisecondsSinceEpoch;

    if (_offsetMs == null ||
        snap ||
        (newOffsetMs - _offsetMs!).abs() > _snapDeltaMs) {
      _offsetMs = newOffsetMs;
    } else {
      _offsetMs =
          (newOffsetMs * _emaNewWeight + _offsetMs! * (1 - _emaNewWeight))
              .round();
    }

    _lastServerNowUtc = normalized;
    return true;
  }

  DateTime nowUtc() {
    final offset = _offsetMs ?? 0;
    return DateTime.now().toUtc().add(Duration(milliseconds: offset));
  }

  DateTime nowLocal() => nowUtc().toLocal();
}
