class GameRuleModel {
  GameRuleModel({required this.id, required this.key, required this.name});

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

  bool get allowsRegistration =>
      this == GameStatus.playing || this == GameStatus.next;
}

class GameModel {
  GameModel({
    required this.id,
    required this.sessionId,
    required this.staticCode,
    required this.playCode,
    required this.name,
    required this.gameRule,
    required this.gameType,
    required this.entryFee,
    required this.prizePerCartela,
    required this.companyFeePerCartela,
    required this.prizeAmount,
    required this.companyRevenue,
    required this.status,
    required this.playOrder,
    required this.startedAt,
    required this.finishedAt,
    required this.winnerCartelaId,
    required this.createdAt,
    required this.updatedAt,
    required this.registeredCartelasCount,
    required this.calledNumbersCount,
    required this.registrationOpen,
  });

  final String id;
  final String? sessionId;
  final String staticCode;
  final String? playCode;
  final String name;
  final GameRuleModel? gameRule;
  final String gameType;
  final String entryFee;
  final String prizePerCartela;
  final String companyFeePerCartela;
  final String prizeAmount;
  final String companyRevenue;
  final GameStatus status;
  final int? playOrder;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? winnerCartelaId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int registeredCartelasCount;
  final int calledNumbersCount;
  final bool registrationOpen;

  factory GameModel.fromLiveJson(Map<String, dynamic> json) {
    final gameRule = json['gameRule'] is Map<String, dynamic>
        ? GameRuleModel.fromJson(json['gameRule'] as Map<String, dynamic>)
        : (json['gameSlot'] is Map<String, dynamic> &&
              (json['gameSlot'] as Map<String, dynamic>)['gameRule']
                  is Map<String, dynamic>)
        ? GameRuleModel.fromJson(
            (json['gameSlot'] as Map<String, dynamic>)['gameRule']
                as Map<String, dynamic>,
          )
        : null;
    final gameSlot = json['gameSlot'] as Map<String, dynamic>?;
    final status = GameStatus.fromApi(json['status'] as String);
    final isSessionPayload =
        json['playCode'] is String &&
        (json['playCode'] as String).trim().isNotEmpty &&
        gameSlot != null;

    return GameModel(
      id: json['id'] as String,
      sessionId: isSessionPayload
          ? (json['sessionId'] as String?) ?? json['id'] as String
          : null,
      staticCode:
          (json['staticCode'] as String?) ??
          (gameSlot?['staticCode'] as String?) ??
          '',
      playCode: (json['playCode'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['playCode'] as String?,
      name: (json['name'] as String?) ?? (gameSlot?['name'] as String?) ?? '',
      gameRule: gameRule,
      gameType:
          (json['gameType'] as String?) ??
          (gameSlot?['gameType'] as String?) ??
          '',
      entryFee: json['entryFee']?.toString() ?? '0',
      prizePerCartela: json['prizePerCartela']?.toString() ?? '0',
      companyFeePerCartela: json['companyFeePerCartela']?.toString() ?? '0',
      prizeAmount: json['prizeAmount']?.toString() ?? '0',
      companyRevenue: json['companyRevenue']?.toString() ?? '0',
      status: status,
      playOrder:
          (json['playOrder'] as num?)?.toInt() ??
          (json['sortOrder'] as num?)?.toInt(),
      startedAt: _parseDate(json['startedAt']),
      finishedAt: _parseDate(json['finishedAt']),
      winnerCartelaId: json['winnerCartelaId'] as String?,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
      registeredCartelasCount:
          (json['registeredCartelasCount'] as num?)?.toInt() ??
          (json['registrationCount'] as num?)?.toInt() ??
          0,
      calledNumbersCount:
          (json['calledNumbersCount'] as num?)?.toInt() ??
          (json['calledNumberCount'] as num?)?.toInt() ??
          0,
      registrationOpen:
          json['registrationOpen'] as bool? ?? (status == GameStatus.playing),
    );
  }

  factory GameModel.fromSessionJson(Map<String, dynamic> json) {
    return GameModel.fromLiveJson({
      ...json,
      'sessionId': (json['sessionId'] as String?) ?? json['id'],
    });
  }

  factory GameModel.fromSlotJson(Map<String, dynamic> json) {
    return GameModel.fromLiveJson(json);
  }

  GameModel copyWith({
    String? sessionId,
    String? staticCode,
    String? playCode,
    GameStatus? status,
    int? playOrder,
    String? entryFee,
    String? prizePerCartela,
    String? companyFeePerCartela,
    String? prizeAmount,
    String? companyRevenue,
    DateTime? startedAt,
    DateTime? finishedAt,
    String? winnerCartelaId,
    int? registeredCartelasCount,
    int? calledNumbersCount,
    bool? registrationOpen,
  }) {
    return GameModel(
      id: id,
      sessionId: sessionId ?? this.sessionId,
      staticCode: staticCode ?? this.staticCode,
      playCode: playCode ?? this.playCode,
      name: name,
      gameRule: gameRule,
      gameType: gameType,
      entryFee: entryFee ?? this.entryFee,
      prizePerCartela: prizePerCartela ?? this.prizePerCartela,
      companyFeePerCartela: companyFeePerCartela ?? this.companyFeePerCartela,
      prizeAmount: prizeAmount ?? this.prizeAmount,
      companyRevenue: companyRevenue ?? this.companyRevenue,
      status: status ?? this.status,
      playOrder: playOrder ?? this.playOrder,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      winnerCartelaId: winnerCartelaId ?? this.winnerCartelaId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      registeredCartelasCount:
          registeredCartelasCount ?? this.registeredCartelasCount,
      calledNumbersCount: calledNumbersCount ?? this.calledNumbersCount,
      registrationOpen: registrationOpen ?? this.registrationOpen,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  String get code =>
      status == GameStatus.next ? staticCode : (playCode ?? staticCode);

  String get ruleName => gameRule?.name ?? name;

  String get ruleKey => gameRule?.key ?? gameType;

  String get codeLabel {
    if (status != GameStatus.next && playCode != null && playCode!.isNotEmpty) {
      return '$playCode / $staticCode';
    }

    return staticCode;
  }
}
