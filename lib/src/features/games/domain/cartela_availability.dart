import '../../../core/time/server_clock_service.dart';
import '../../../core/utils/api_date_time.dart';

enum CartelaAvailability {
  available,
  mine,
  taken,
  reservedByMe,
  reservedByOther,
}

int? cartelaReservationSecondsRemaining({
  required int cartelaHoldSeconds,
  DateTime? holdStartedAt,
  DateTime? expiresAt,
  ServerClockService? clock,
}) {
  if (holdStartedAt != null) {
    final elapsed = _effectiveNow(clock: clock).difference(holdStartedAt).inSeconds;
    final remaining = cartelaHoldSeconds - elapsed;
    if (remaining <= 0) {
      return null;
    }
    return remaining;
  }

  if (expiresAt == null) {
    return null;
  }

  final remaining = secondsUntilCeil(expiresAt, clock: clock);
  if (remaining <= 0) {
    return null;
  }

  return remaining > cartelaHoldSeconds ? cartelaHoldSeconds : remaining;
}

DateTime _effectiveNow({ServerClockService? clock}) {
  if (clock?.isSynced == true) {
    return clock!.nowLocal();
  }
  return DateTime.now();
}
