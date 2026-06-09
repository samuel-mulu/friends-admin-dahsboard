/// How long a player may hold a cartela before confirming registration.
const kCartelaReservationHoldSeconds = 10;

enum CartelaAvailability {
  available,
  mine,
  taken,
  reservedByMe,
  reservedByOther,
}

int? cartelaReservationSecondsRemaining({
  DateTime? holdStartedAt,
  DateTime? expiresAt,
}) {
  if (holdStartedAt != null) {
    final remaining =
        kCartelaReservationHoldSeconds -
        DateTime.now().difference(holdStartedAt).inSeconds;
    if (remaining <= 0) {
      return null;
    }
    return remaining;
  }

  if (expiresAt == null) {
    return null;
  }

  final remaining = expiresAt.difference(DateTime.now()).inSeconds;
  if (remaining <= 0) {
    return null;
  }

  return remaining > kCartelaReservationHoldSeconds
      ? kCartelaReservationHoldSeconds
      : remaining;
}
