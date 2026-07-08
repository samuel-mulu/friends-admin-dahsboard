import '../../data/models/game_model.dart';

class NextBallStaleEvaluation {
  const NextBallStaleEvaluation({
    required this.shouldSyncCalledNumbers,
    required this.shouldRefetchCanonical,
    required this.zeroForMs,
    required this.sessionId,
    required this.target,
  });

  final bool shouldSyncCalledNumbers;
  final bool shouldRefetchCanonical;
  final int zeroForMs;
  final String? sessionId;
  final DateTime? target;
}

class NextBallStaleGuard {
  NextBallStaleGuard({DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  static const calledNumbersSyncAfterMs = 2000;
  static const canonicalRefetchAfterMs = 6000;

  DateTime? _zeroSince;
  String? _sessionId;
  DateTime? _target;
  bool _calledNumbersSyncDone = false;
  bool _canonicalRefetchDone = false;

  void reset() {
    _zeroSince = null;
    _sessionId = null;
    _target = null;
    _calledNumbersSyncDone = false;
    _canonicalRefetchDone = false;
  }

  void onScheduleOrBallEvent({
    required DateTime? target,
    required String? sessionId,
    required int rawRemaining,
  }) {
    final targetChanged =
        !_dateTimesEqual(target, _target) || sessionId != _sessionId;
    if (targetChanged) {
      _target = target;
      _sessionId = sessionId;
      _zeroSince = null;
      _calledNumbersSyncDone = false;
      _canonicalRefetchDone = false;
    }

    if (rawRemaining > 0) {
      _zeroSince = null;
      _calledNumbersSyncDone = false;
      _canonicalRefetchDone = false;
      return;
    }

    if (target != null) {
      _zeroSince ??= _now();
    }
  }

  void recordCalledNumbersSync(String? sessionId) {
    _calledNumbersSyncDone = true;
    _sessionId = sessionId;
  }

  void recordCanonicalRefetch(String? sessionId) {
    _canonicalRefetchDone = true;
    _sessionId = sessionId;
  }

  NextBallStaleEvaluation evaluate({
    required GameModel? game,
    required bool? socketAutoCallEnabled,
    required int rawRemaining,
    DateTime? effectiveTarget,
    bool useEffectiveTarget = false,
  }) {
    final sessionId = game?.sessionId ?? game?.id;
    final target = useEffectiveTarget ? effectiveTarget : game?.nextAutoCallAt;
    final now = _now();

    final zeroForMs = _zeroSince == null
        ? 0
        : now.difference(_zeroSince!).inMilliseconds;

    final autoCallActive = socketAutoCallEnabled == true ||
        (socketAutoCallEnabled == null && game?.operationMode == 'AUTO');

    final isStaleCalling = game != null &&
        game.status == GameStatus.playing &&
        autoCallActive &&
        target != null &&
        rawRemaining <= 0;

    final shouldSyncCalledNumbers = isStaleCalling &&
        zeroForMs >= calledNumbersSyncAfterMs &&
        !_calledNumbersSyncDone;

    final shouldRefetchCanonical = isStaleCalling &&
        zeroForMs >= canonicalRefetchAfterMs &&
        _calledNumbersSyncDone &&
        !_canonicalRefetchDone;

    return NextBallStaleEvaluation(
      shouldSyncCalledNumbers: shouldSyncCalledNumbers,
      shouldRefetchCanonical: shouldRefetchCanonical,
      zeroForMs: zeroForMs,
      sessionId: sessionId,
      target: target,
    );
  }

  bool _dateTimesEqual(DateTime? left, DateTime? right) {
    if (left == null && right == null) {
      return true;
    }
    if (left == null || right == null) {
      return false;
    }
    return left.isAtSameMomentAs(right);
  }
}
