import '../../../../core/time/server_clock_service.dart';
import '../../../../core/utils/api_date_time.dart';

/// Tiered countdown for the Big Game schedule banner.
///
/// - Under 1 hour: minutes + seconds
/// - 1 hour to under 1 day: hours + minutes + seconds
/// - 1 day to under 30 days: days + hours + minutes (no seconds)
/// - 30+ days: months + days + hours (no minutes or seconds)
String formatBigGameCountdown(
  DateTime? target, {
  ServerClockService? clock,
  DateTime? now,
}) {
  if (target == null) {
    return '--';
  }

  final totalSeconds = secondsUntilCeil(target, now: now, clock: clock);
  if (totalSeconds <= 0) {
    return '0 sec';
  }

  const secondsPerMinute = 60;
  const secondsPerHour = 3600;
  const secondsPerDay = 86400;
  const secondsPerMonth = 30 * secondsPerDay;

  if (totalSeconds >= secondsPerMonth) {
    final months = totalSeconds ~/ secondsPerMonth;
    final afterMonths = totalSeconds % secondsPerMonth;
    final days = afterMonths ~/ secondsPerDay;
    final hours = (afterMonths % secondsPerDay) ~/ secondsPerHour;
    return _joinCountdownParts([
      _countdownPart(months, 'month'),
      _countdownPart(days, 'day'),
      _countdownPart(hours, 'hour'),
    ]);
  }

  if (totalSeconds >= secondsPerDay) {
    final days = totalSeconds ~/ secondsPerDay;
    final afterDays = totalSeconds % secondsPerDay;
    final hours = afterDays ~/ secondsPerHour;
    final minutes = (afterDays % secondsPerHour) ~/ secondsPerMinute;
    return _joinCountdownParts([
      _countdownPart(days, 'day'),
      _countdownPart(hours, 'hour'),
      _countdownPart(minutes, 'min'),
    ]);
  }

  if (totalSeconds >= secondsPerHour) {
    final hours = totalSeconds ~/ secondsPerHour;
    final afterHours = totalSeconds % secondsPerHour;
    final minutes = afterHours ~/ secondsPerMinute;
    final seconds = afterHours % secondsPerMinute;
    return _joinCountdownParts([
      _countdownPart(hours, 'hour', shortLabel: 'h'),
      _countdownPart(minutes, 'min'),
      _countdownPart(seconds, 'sec'),
    ]);
  }

  final minutes = totalSeconds ~/ secondsPerMinute;
  final seconds = totalSeconds % secondsPerMinute;
  if (minutes > 0) {
    return _joinCountdownParts([
      _countdownPart(minutes, 'min'),
      _countdownPart(seconds, 'sec'),
    ]);
  }

  return _countdownPart(seconds, 'sec');
}

String _countdownPart(
  int value,
  String unit, {
  String? shortLabel,
}) {
  final label = value == 1 ? unit : '${unit}s';
  if (shortLabel != null && value < 10) {
    return '$value$shortLabel';
  }
  return '$value $label';
}

String _joinCountdownParts(List<String> parts) {
  return parts.where((part) => part.isNotEmpty).join(' ');
}
