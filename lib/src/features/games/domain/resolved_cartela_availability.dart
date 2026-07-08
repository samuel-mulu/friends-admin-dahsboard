import '../../../core/time/server_clock_service.dart';
import '../data/models/cartela_model.dart';
import '../data/models/game_model.dart';
import 'cartela_availability.dart';

/// Grid-facing cartela state after snapshot + confirmed patches + local pending UI.
class ResolvedCartelaAvailability {
  const ResolvedCartelaAvailability({
    required this.cartelaId,
    required this.cartelaNumber,
    required this.availability,
    this.isPending = false,
    this.isRegistering = false,
    this.expiresAt,
    this.reservationSecondsRemaining,
  });

  final String cartelaId;
  final int cartelaNumber;
  final CartelaAvailability availability;
  final bool isPending;
  final bool isRegistering;
  final DateTime? expiresAt;
  final int? reservationSecondsRemaining;

  bool get isAvailable => availability == CartelaAvailability.available;

  ResolvedCartelaAvailability copyWith({
    CartelaAvailability? availability,
    bool? isPending,
    bool? isRegistering,
    DateTime? expiresAt,
    int? reservationSecondsRemaining,
    bool clearReservationSecondsRemaining = false,
  }) {
    return ResolvedCartelaAvailability(
      cartelaId: cartelaId,
      cartelaNumber: cartelaNumber,
      availability: availability ?? this.availability,
      isPending: isPending ?? this.isPending,
      isRegistering: isRegistering ?? this.isRegistering,
      expiresAt: expiresAt ?? this.expiresAt,
      reservationSecondsRemaining: clearReservationSecondsRemaining
          ? null
          : (reservationSecondsRemaining ?? this.reservationSecondsRemaining),
    );
  }
}

/// Resolves one cartela chip from merged summary + local in-flight UI state.
ResolvedCartelaAvailability resolveCartelaAvailability({
  required CartelaModel cartela,
  required RegisteredCartelaSummary? summary,
  required bool isTrackedMine,
  required bool isSelecting,
  required bool isReservePending,
  required bool isRegistering,
  required DateTime? localHoldExpiresAt,
  required int cartelaHoldSeconds,
  required ServerClockService clock,
}) {
  var availability = isTrackedMine
      ? CartelaAvailability.mine
      : summary == null
      ? CartelaAvailability.available
      : availabilityFromRegistrationSummary(summary);

  if (localHoldExpiresAt != null && localHoldExpiresAt.isAfter(clock.nowLocal())) {
    availability = CartelaAvailability.reservedByMe;
  } else if (isSelecting) {
    availability = CartelaAvailability.available;
  }

  int? reservationSecondsRemaining;
  if (availability == CartelaAvailability.reservedByMe) {
    reservationSecondsRemaining = cartelaReservationSecondsRemaining(
      expiresAt: localHoldExpiresAt ?? summary?.expiresAt,
      cartelaHoldSeconds: cartelaHoldSeconds,
      clock: clock,
    );
    if (reservationSecondsRemaining == null) {
      availability = CartelaAvailability.available;
    }
  }

  return ResolvedCartelaAvailability(
    cartelaId: cartela.id,
    cartelaNumber: cartela.number,
    availability: availability,
    isPending: isReservePending && isSelecting,
    isRegistering: isRegistering,
    expiresAt: localHoldExpiresAt ?? summary?.expiresAt,
    reservationSecondsRemaining: reservationSecondsRemaining,
  );
}

CartelaAvailability availabilityFromRegistrationSummary(
  RegisteredCartelaSummary summary,
) {
  if (summary.isMine) {
    return CartelaAvailability.mine;
  }
  if (summary.isTaken) {
    return CartelaAvailability.taken;
  }
  if (summary.isReservedByMe) {
    return CartelaAvailability.reservedByMe;
  }
  if (summary.isReservedByOther) {
    return CartelaAvailability.reservedByOther;
  }
  return CartelaAvailability.available;
}
