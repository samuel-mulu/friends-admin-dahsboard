import 'cartela_model.dart';

enum GameCartelaStatus {
  registered,
  winner,
  blocked,
  cancelled;

  factory GameCartelaStatus.fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'REGISTERED':
        return GameCartelaStatus.registered;
      case 'WINNER':
        return GameCartelaStatus.winner;
      case 'BLOCKED':
        return GameCartelaStatus.blocked;
      case 'CANCELLED':
        return GameCartelaStatus.cancelled;
      default:
        throw ArgumentError.value(
          value,
          'value',
          'Unsupported game cartela status',
        );
    }
  }

  String get label {
    switch (this) {
      case GameCartelaStatus.registered:
        return 'Registered';
      case GameCartelaStatus.winner:
        return 'Winner';
      case GameCartelaStatus.blocked:
        return 'Blocked';
      case GameCartelaStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class GameCartelaModel {
  GameCartelaModel({
    required this.id,
    required this.gameId,
    required this.userId,
    required this.cartelaId,
    required this.status,
    required this.isWinner,
    required this.blockedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.cartela,
  });

  final String id;
  final String gameId;
  final String userId;
  final String cartelaId;
  final GameCartelaStatus status;
  final bool isWinner;
  final DateTime? blockedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CartelaModel cartela;

  factory GameCartelaModel.fromJson(Map<String, dynamic> json) {
    return GameCartelaModel(
      id: json['id'] as String,
      gameId: json['gameId'] as String,
      userId: json['userId'] as String,
      cartelaId: json['cartelaId'] as String,
      status: GameCartelaStatus.fromApi(json['status'] as String),
      isWinner: json['isWinner'] as bool? ?? false,
      blockedAt: json['blockedAt'] is String
          ? DateTime.tryParse(json['blockedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      cartela: CartelaModel.fromJson(json['cartela'] as Map<String, dynamic>),
    );
  }

  GameCartelaModel copyWith({
    GameCartelaStatus? status,
    bool? isWinner,
    DateTime? blockedAt,
  }) {
    return GameCartelaModel(
      id: id,
      gameId: gameId,
      userId: userId,
      cartelaId: cartelaId,
      status: status ?? this.status,
      isWinner: isWinner ?? this.isWinner,
      blockedAt: blockedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      cartela: cartela,
    );
  }
}
