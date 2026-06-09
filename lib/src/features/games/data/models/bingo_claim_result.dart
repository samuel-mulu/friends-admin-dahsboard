import 'game_cartela_model.dart';
import 'game_model.dart';

enum BingoClaimStatus {
  pending,
  valid,
  invalid;

  factory BingoClaimStatus.fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return BingoClaimStatus.pending;
      case 'VALID':
        return BingoClaimStatus.valid;
      case 'INVALID':
        return BingoClaimStatus.invalid;
      default:
        throw ArgumentError.value(value, 'value', 'Unsupported claim status');
    }
  }
}

class BingoClaimModel {
  BingoClaimModel({
    required this.id,
    required this.gameId,
    required this.userId,
    required this.gameCartelaId,
    required this.status,
    required this.checkedPattern,
    required this.reason,
    required this.createdAt,
    required this.checkedAt,
  });

  final String id;
  final String gameId;
  final String userId;
  final String gameCartelaId;
  final BingoClaimStatus status;
  final String? checkedPattern;
  final String? reason;
  final DateTime createdAt;
  final DateTime? checkedAt;

  factory BingoClaimModel.fromJson(Map<String, dynamic> json) {
    return BingoClaimModel(
      id: json['id'] as String,
      gameId: (json['gameId'] ?? json['gameSessionId']) as String,
      userId: json['userId'] as String,
      gameCartelaId: json['gameCartelaId'] as String,
      status: BingoClaimStatus.fromApi(json['status'] as String),
      checkedPattern: json['checkedPattern'] as String?,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      checkedAt: json['checkedAt'] is String
          ? DateTime.tryParse(json['checkedAt'] as String)
          : null,
    );
  }
}

class BingoClaimResult {
  BingoClaimResult({
    required this.claim,
    required this.progress,
    required this.isWinner,
    required this.gameStatus,
    required this.gameCartelaStatus,
  });

  final BingoClaimModel claim;
  final double? progress;
  final bool isWinner;
  final GameStatus gameStatus;
  final GameCartelaStatus gameCartelaStatus;

  factory BingoClaimResult.fromJson(Map<String, dynamic> json) {
    return BingoClaimResult(
      claim: BingoClaimModel.fromJson(json['claim'] as Map<String, dynamic>),
      progress: (json['progress'] as num?)?.toDouble(),
      isWinner: json['isWinner'] as bool? ?? false,
      gameStatus: GameStatus.fromApi(json['gameStatus'] as String),
      gameCartelaStatus: GameCartelaStatus.fromApi(
        json['gameCartelaStatus'] as String,
      ),
    );
  }
}
