class CartelaReservationModel {
  const CartelaReservationModel({
    required this.id,
    required this.gameSessionId,
    required this.cartelaId,
    required this.expiresAt,
    required this.status,
  });

  final String id;
  final String gameSessionId;
  final String cartelaId;
  final DateTime expiresAt;
  final String status;

  factory CartelaReservationModel.fromJson(Map<String, dynamic> json) {
    return CartelaReservationModel(
      id: json['id'] as String,
      gameSessionId: json['gameSessionId'] as String,
      cartelaId: json['cartelaId'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      status: json['status'] as String,
    );
  }
}
