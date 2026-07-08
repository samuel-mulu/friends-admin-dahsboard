class GameTimingConfigModel {
  static const defaultWinningPatternDisplaySeconds = 10;
  static const defaultRegistrationDurationSeconds = 180;
  static const defaultCartelaHoldSeconds = 10;
  static const defaultBulkSelectionHoldSeconds = 120;
  static const defaultAutoCallIntervalSeconds = 18;
  static const defaultWinnerWindowSeconds = 25;
  static const defaultFinishedResultDisplaySeconds = 60;
  static const defaultMissedNumberAnimationMs = 150;
  static const defaultMissedNumberStaggerMaxBalls = 10;
  static const defaultFlutterRefetchDebounceMs = 400;

  static const fallback = GameTimingConfigModel(
    registrationDurationSeconds: defaultRegistrationDurationSeconds,
    autoCallIntervalSeconds: defaultAutoCallIntervalSeconds,
    winnerWindowSeconds: defaultWinnerWindowSeconds,
    cartelaHoldSeconds: defaultCartelaHoldSeconds,
    bulkSelectionHoldSeconds: defaultBulkSelectionHoldSeconds,
    finishedResultDisplaySeconds: defaultFinishedResultDisplaySeconds,
    winningPatternDisplaySeconds: defaultWinningPatternDisplaySeconds,
    preparingDisplayMaxSeconds: null,
    missedNumberAnimationMs: defaultMissedNumberAnimationMs,
    missedNumberStaggerMaxBalls: defaultMissedNumberStaggerMaxBalls,
    flutterRefetchDebounceMs: defaultFlutterRefetchDebounceMs,
  );

  const GameTimingConfigModel({
    required this.registrationDurationSeconds,
    required this.autoCallIntervalSeconds,
    required this.winnerWindowSeconds,
    required this.cartelaHoldSeconds,
    required this.bulkSelectionHoldSeconds,
    required this.finishedResultDisplaySeconds,
    required this.winningPatternDisplaySeconds,
    required this.preparingDisplayMaxSeconds,
    required this.missedNumberAnimationMs,
    required this.missedNumberStaggerMaxBalls,
    required this.flutterRefetchDebounceMs,
    this.serverNow,
  });

  final int registrationDurationSeconds;
  final int autoCallIntervalSeconds;
  final int winnerWindowSeconds;
  final int cartelaHoldSeconds;
  final int bulkSelectionHoldSeconds;
  final int finishedResultDisplaySeconds;
  final int winningPatternDisplaySeconds;
  final int? preparingDisplayMaxSeconds;
  final int missedNumberAnimationMs;
  final int missedNumberStaggerMaxBalls;
  final int flutterRefetchDebounceMs;
  final DateTime? serverNow;

  factory GameTimingConfigModel.fromJson(Map<String, dynamic> json) {
    final serverNowRaw = json['serverNow'] as String?;
    return GameTimingConfigModel(
      registrationDurationSeconds:
          _requireInt(json['registrationDurationSeconds']),
      autoCallIntervalSeconds: _requireInt(json['autoCallIntervalSeconds']),
      winnerWindowSeconds: _optionalInt(json['winnerWindowSeconds']) ??
          defaultWinnerWindowSeconds,
      cartelaHoldSeconds: _requireInt(json['cartelaHoldSeconds']),
      bulkSelectionHoldSeconds: _optionalInt(json['bulkSelectionHoldSeconds']) ??
          defaultBulkSelectionHoldSeconds,
      finishedResultDisplaySeconds:
          _requireInt(json['finishedResultDisplaySeconds']),
      winningPatternDisplaySeconds: _optionalInt(
            json['winningPatternDisplaySeconds'],
          ) ??
          defaultWinningPatternDisplaySeconds,
      preparingDisplayMaxSeconds: json['preparingDisplayMaxSeconds'] == null
          ? null
          : _requireInt(json['preparingDisplayMaxSeconds']),
      missedNumberAnimationMs: _requireInt(json['missedNumberAnimationMs']),
      missedNumberStaggerMaxBalls:
          _requireInt(json['missedNumberStaggerMaxBalls']),
      flutterRefetchDebounceMs: _requireInt(json['flutterRefetchDebounceMs']),
      serverNow: serverNowRaw == null
          ? null
          : DateTime.tryParse(serverNowRaw)?.toUtc(),
    );
  }

  Duration get finishedSummaryMinimumHold {
    final seconds = finishedResultDisplaySeconds > winningPatternDisplaySeconds
        ? finishedResultDisplaySeconds
        : winningPatternDisplaySeconds;
    return Duration(seconds: seconds);
  }

  Duration get winningPatternDisplayHold =>
      Duration(seconds: winningPatternDisplaySeconds);

  Duration get preparingPhaseStaleAfter =>
      preparingDisplayMax ??
      Duration(seconds: registrationDurationSeconds);

  /// Optional admin-configured cap for the "Preparing game" phase.
  Duration? get preparingDisplayMax => preparingDisplayMaxSeconds == null
      ? null
      : Duration(seconds: preparingDisplayMaxSeconds!);

  Duration get missedNumberStaggerInterval =>
      Duration(milliseconds: missedNumberAnimationMs);

  Duration get canonicalRefetchDebounce =>
      Duration(milliseconds: flutterRefetchDebounceMs);

  Duration get autoCallInterval =>
      Duration(seconds: autoCallIntervalSeconds);

  Duration get winnerWindowDuration =>
      Duration(seconds: winnerWindowSeconds);
}

int _requireInt(Object? value, {String? fieldName}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.round();
  }

  throw FormatException(
    'Missing or invalid timing config field${fieldName == null ? '' : ': $fieldName'}',
  );
}

int? _optionalInt(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.round();
  }

  return null;
}
