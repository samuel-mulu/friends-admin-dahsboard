import 'cartela_reservation_model.dart';

class BulkReserveFailure {
  const BulkReserveFailure({
    required this.cartelaId,
    required this.reason,
  });

  final String cartelaId;
  final String reason;

  factory BulkReserveFailure.fromJson(Map<String, dynamic> json) {
    return BulkReserveFailure(
      cartelaId: json['cartelaId'] as String,
      reason: json['reason'] as String,
    );
  }
}

class BulkReserveCartelasResult {
  const BulkReserveCartelasResult({
    required this.sessionId,
    required this.reservations,
    this.failures = const [],
  });

  final String sessionId;
  final List<CartelaReservationModel> reservations;
  final List<BulkReserveFailure> failures;

  factory BulkReserveCartelasResult.fromJson(Map<String, dynamic> json) {
    final reservationItems = json['reservations'];
    final failureItems = json['failures'];
    return BulkReserveCartelasResult(
      sessionId: json['sessionId'] as String,
      reservations: reservationItems is List
          ? reservationItems
                .whereType<Map<String, dynamic>>()
                .map(
                  (item) => CartelaReservationModel(
                    id: item['id'] as String,
                    gameSessionId: json['sessionId'] as String,
                    cartelaId: item['cartelaId'] as String,
                    expiresAt: DateTime.parse(item['expiresAt'] as String),
                    status: item['status'] as String,
                  ),
                )
                .toList(growable: false)
          : const [],
      failures: failureItems is List
          ? failureItems
                .whereType<Map<String, dynamic>>()
                .map(BulkReserveFailure.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}
