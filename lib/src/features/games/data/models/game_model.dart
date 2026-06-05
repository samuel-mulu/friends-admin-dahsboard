class GameRuleModel {
  GameRuleModel({
    required this.id,
    required this.key,
    required this.name,
  });

  final String id;
  final String key;
  final String name;

  factory GameRuleModel.fromJson(Map<String, dynamic> json) {
    return GameRuleModel(
      id: json['id'] as String,
      key: json['key'] as String,
      name: json['name'] as String,
    );
  }
}

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

  // Registration is only allowed on PLAYING sessions in the new backend.
  bool get allowsRegistration {
    return this == GameStatus.playing;
  }
}

class GameModel {
  GameModel({
    required this.id,
    this.sessionId,
    required this.code,
    required this.name,
    required this.gameRule,
    required this.gameType,
    required this.entryFee,
    required this.prizeAmount,
    required this.status,
    required this.playOrder,
    required this.startedAt,
    required this.finishedAt,
    required this.winnerCartelaId,
    required this.createdAt,
    required this.updatedAt,
    required this.registeredCartelasCount,
  });

  // For sessions: id == sessionId (the live session id used for all API calls).
  // For NEXT slots: id == slotId, sessionId == null (no session exists yet).
  final String id;
  final String? sessionId;
  final String code;
  final String name;
  final GameRuleModel? gameRule;
  final String gameType;
  final String entryFee;
  final String prizeAmount;
  final GameStatus status;
  final int? playOrder;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? winnerCartelaId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int registeredCartelasCount;

  // Build from a session payload (status: PLAYING / CHECKING / FINISHED).
  // Session payload shape: { id, playCode, name, gameType, entryFee, prizeAmount,
  //   status, startedAt, finishedAt, winnerCartelaId, createdAt, updatedAt,
  //   gameSlot: { gameRule?, ... }, registeredCartelasCount }
  factory GameModel.fromSessionJson(Map<String, dynamic> json) {
    final slot = json['gameSlot'] as Map<String, dynamic>?;
    final gameRule = slot?['gameRule'] is Map<String, dynamic>
        ? GameRuleModel.fromJson(slot!['gameRule'] as Map<String, dynamic>)
        : null;
    final sessionId = json['id'] as String;
    return GameModel(
      id: sessionId,
      sessionId: sessionId,
      code: (json['playCode'] as String?) ?? '',
      name: (json['name'] as String?) ?? (slot?['name'] as String?) ?? '',
      gameRule: gameRule,
      gameType: (json['gameType'] as String?) ?? '',
      entryFee: json['entryFee']?.toString() ?? '0',
      prizeAmount: json['prizeAmount']?.toString() ?? '0',
      status: GameStatus.fromApi(json['status'] as String),
      playOrder: null,
      startedAt: _parseDate(json['startedAt']),
      finishedAt: _parseDate(json['finishedAt']),
      winnerCartelaId: json['winnerCartelaId'] as String?,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
      registeredCartelasCount:
          (json['registeredCartelasCount'] as num?)?.toInt() ?? 0,
    );
  }

  // Build from a slot payload (status: NEXT).
  // Slot payload shape: { id, staticCode, name, gameType, gameRule?,
  //   status, sortOrder, createdAt, updatedAt }
  factory GameModel.fromSlotJson(Map<String, dynamic> json) {
    final gameRule = json['gameRule'] is Map<String, dynamic>
        ? GameRuleModel.fromJson(json['gameRule'] as Map<String, dynamic>)
        : null;
    return GameModel(
      id: json['id'] as String,
      sessionId: null,
      code: (json['staticCode'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      gameRule: gameRule,
      gameType: (json['gameType'] as String?) ?? '',
      entryFee: '0',
      prizeAmount: '0',
      status: GameStatus.fromApi(json['status'] as String),
      playOrder: (json['sortOrder'] as num?)?.toInt(),
      startedAt: null,
      finishedAt: null,
      winnerCartelaId: null,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
      registeredCartelasCount: 0,
    );
  }

  GameModel copyWith({
    String? sessionId,
    GameStatus? status,
    int? playOrder,
    String? entryFee,
    String? prizeAmount,
    DateTime? startedAt,
    DateTime? finishedAt,
    String? winnerCartelaId,
    int? registeredCartelasCount,
  }) {
    return GameModel(
      id: id,
      sessionId: sessionId ?? this.sessionId,
      code: code,
      name: name,
      gameRule: gameRule,
      gameType: gameType,
      entryFee: entryFee ?? this.entryFee,
      prizeAmount: prizeAmount ?? this.prizeAmount,
      status: status ?? this.status,
      playOrder: playOrder ?? this.playOrder,
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

  String get ruleName => gameRule?.name ?? name;

  String get ruleKey => gameRule?.key ?? gameType;
}
