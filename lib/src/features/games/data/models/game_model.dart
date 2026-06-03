enum GameStatus {
  next,
  checking,
  playing,
  finished,
  cancelled;

  factory GameStatus.fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'NEXT':
        return GameStatus.next;
      case 'CHECKING':
        return GameStatus.checking;
      case 'PLAYING':
        return GameStatus.playing;
      case 'FINISHED':
        return GameStatus.finished;
      case 'CANCELLED':
        return GameStatus.cancelled;
      default:
        throw ArgumentError.value(value, 'value', 'Unsupported game status');
    }
  }

  String get label {
    switch (this) {
      case GameStatus.next:
        return 'Next';
      case GameStatus.checking:
        return 'Checking';
      case GameStatus.playing:
        return 'Playing';
      case GameStatus.finished:
        return 'Finished';
      case GameStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get allowsRegistration {
    return this == GameStatus.next || this == GameStatus.checking;
  }
}

class GameModel {
  GameModel({
    required this.id,
    required this.code,
    required this.name,
    required this.gameType,
    required this.entryFee,
    required this.prizeAmount,
    required this.status,
    required this.startsAt,
    required this.startedAt,
    required this.finishedAt,
    required this.winnerCartelaId,
    required this.createdAt,
    required this.updatedAt,
    required this.registeredCartelasCount,
  });

  final String id;
  final String code;
  final String name;
  final String gameType;
  final String entryFee;
  final String prizeAmount;
  final GameStatus status;
  final DateTime? startsAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? winnerCartelaId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int registeredCartelasCount;

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      gameType: json['gameType'] as String,
      entryFee: json['entryFee'] as String,
      prizeAmount: json['prizeAmount'] as String,
      status: GameStatus.fromApi(json['status'] as String),
      startsAt: _parseDate(json['startsAt']),
      startedAt: _parseDate(json['startedAt']),
      finishedAt: _parseDate(json['finishedAt']),
      winnerCartelaId: json['winnerCartelaId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      registeredCartelasCount:
          (json['registeredCartelasCount'] as num?)?.toInt() ?? 0,
    );
  }

  GameModel copyWith({
    GameStatus? status,
    DateTime? startsAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    String? winnerCartelaId,
    int? registeredCartelasCount,
  }) {
    return GameModel(
      id: id,
      code: code,
      name: name,
      gameType: gameType,
      entryFee: entryFee,
      prizeAmount: prizeAmount,
      status: status ?? this.status,
      startsAt: startsAt ?? this.startsAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      winnerCartelaId: winnerCartelaId ?? this.winnerCartelaId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      registeredCartelasCount:
          registeredCartelasCount ?? this.registeredCartelasCount,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
