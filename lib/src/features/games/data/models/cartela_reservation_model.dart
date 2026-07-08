import 'cartela_model.dart';

class CartelaReservationModel {
  const CartelaReservationModel({
    required this.id,
    required this.gameSessionId,
    required this.cartelaId,
    required this.expiresAt,
    required this.status,
    this.cartela,
  });

  final String id;
  final String gameSessionId;
  final String cartelaId;
  final DateTime expiresAt;
  final String status;
  final CartelaModel? cartela;

  factory CartelaReservationModel.fromJson(Map<String, dynamic> json) {
    final cartelaJson = json['cartela'];
    return CartelaReservationModel(
      id: json['id'] as String,
      gameSessionId: json['gameSessionId'] as String,
      cartelaId: json['cartelaId'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      status: json['status'] as String,
      cartela: cartelaJson is Map<String, dynamic>
          ? CartelaModel.fromJson(cartelaJson)
          : null,
    );
  }
}
