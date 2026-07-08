import '../time/server_clock_service.dart';

/// Parses API timestamps into local [DateTime] for UI countdowns.
DateTime? parseApiDateTime(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value.toLocal();
  }

  if (value is String && value.isNotEmpty) {
    final parsed = DateTime.tryParse(value);
    return parsed?.toLocal();
  }

  if (value is num) {
    final millis = value.round();
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
  }

  return null;
}

DateTime _effectiveNow({DateTime? now, ServerClockService? clock}) {
  if (now != null) {
    return now;
  }
  if (clock?.isSynced == true) {
    return clock!.nowLocal();
  }
  return DateTime.now();
}

int secondsUntil(DateTime? target, {DateTime? now, ServerClockService? clock}) {
  if (target == null) {
    return 0;
  }

  final effectiveNow = _effectiveNow(now: now, clock: clock);
  final seconds = target.difference(effectiveNow).inSeconds;
  return seconds > 0 ? seconds : 0;
}

int secondsUntilCeil(DateTime? target, {DateTime? now, ServerClockService? clock}) {
  if (target == null) {
    return 0;
  }

  final effectiveNow = _effectiveNow(now: now, clock: clock);
  final millis = target.difference(effectiveNow).inMilliseconds;
  return millis > 0 ? (millis / 1000).ceil() : 0;
}
