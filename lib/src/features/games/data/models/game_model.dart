import 'package:flutter/material.dart';

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
  ready,
  checking,
  playing,
  winnerWindow,
  finished,
  cancelled;

  factory GameStatus.fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'NEXT':
        return GameStatus.next;
      case 'READY':
        return GameStatus.ready;
      case 'CHECKING':
        return GameStatus.checking;
      case 'PLAYING':
        return GameStatus.playing;
      case 'WINNER_WINDOW':
        return GameStatus.winnerWindow;
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
      case GameStatus.ready:
        return 'Ready';
      case GameStatus.checking:
        return 'Checking';
      case GameStatus.playing:
        return 'Playing';
      case GameStatus.winnerWindow:
        return 'Winner Window';
      case GameStatus.finished:
        return 'Finished';
      case GameStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get allowsRegistration =>
      this == GameStatus.playing || this == GameStatus.ready || this == GameStatus.next;

  /// Simplified player-facing status that hides backend complexity
  /// NEXT and READY both show as "registrationOpen" to players
  PlayerGameStatus get playerStatus {
    switch (this) {
      case GameStatus.next:
      case GameStatus.ready:
        return PlayerGameStatus.registrationOpen;
      case GameStatus.playing:
        return PlayerGameStatus.playing;
      case GameStatus.winnerWindow:
        return PlayerGameStatus.winnerWindow;
      case GameStatus.checking:
        return PlayerGameStatus.checking;
      case GameStatus.finished:
        return PlayerGameStatus.finished;
      case GameStatus.cancelled:
        return PlayerGameStatus.cancelled;
    }
  }
}

/// Simplified player-facing game status
/// Hides backend distinction between NEXT and READY
enum PlayerGameStatus {
  registrationOpen,
  playing,
  winnerWindow,
  checking,
  finished,
  cancelled;

  String get label {
    switch (this) {
      case PlayerGameStatus.registrationOpen:
        return 'Registration Open';
      case PlayerGameStatus.playing:
        return 'Playing';
      case PlayerGameStatus.winnerWindow:
        return 'Winner Window';
      case PlayerGameStatus.checking:
        return 'Checking';
      case PlayerGameStatus.finished:
        return 'Finished';
      case PlayerGameStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get displayMessage {
    switch (this) {
      case PlayerGameStatus.registrationOpen:
        return 'Register your cartelas now!';
      case PlayerGameStatus.playing:
        return 'Game in progress - mark your numbers!';
      case PlayerGameStatus.winnerWindow:
        return 'Bingo accepted. Waiting 15 seconds for other winners.';
      case PlayerGameStatus.checking:
        return 'Bingo claim under review...';
      case PlayerGameStatus.finished:
        return 'Game finished';
      case PlayerGameStatus.cancelled:
        return 'Game cancelled';
    }
  }

  Color get badgeColor {
    switch (this) {
      case PlayerGameStatus.registrationOpen:
        return Colors.blue;
      case PlayerGameStatus.playing:
        return Colors.green;
      case PlayerGameStatus.winnerWindow:
        return Colors.deepPurple;
      case PlayerGameStatus.checking:
        return Colors.orange;
      case PlayerGameStatus.finished:
        return Colors.grey;
      case PlayerGameStatus.cancelled:
        return Colors.red;
    }
  }
}

class WinnerPayoutSummary {
  const WinnerPayoutSummary({
    required this.cartelaId,
    required this.cartelaNumber,
    required this.amount,
    this.owner,
  });

  final String cartelaId;
  final int cartelaNumber;
  final String amount;
  final String? owner;

  bool get isMine => owner == 'ME';

  factory WinnerPayoutSummary.fromJson(Map<String, dynamic> json) {
    return WinnerPayoutSummary(
      cartelaId: json['cartelaId'] as String,
      cartelaNumber: (json['cartelaNumber'] as num).toInt(),
      amount: json['amount']?.toString() ?? '0',
      owner: json['owner'] as String?,
    );
  }

  static List<WinnerPayoutSummary>? parseList(Object? value) {
    if (value is! List) {
      return null;
    }

    return value
        .map(
          (item) => WinnerPayoutSummary.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  static String? totalForMyCartelas({
    required List<WinnerPayoutSummary>? payouts,
    required Set<String> myCartelaIds,
  }) {
    if (payouts == null || payouts.isEmpty) {
      return null;
    }

    final myPayouts = payouts.where(
      (payout) => payout.isMine || myCartelaIds.contains(payout.cartelaId),
    );
    if (myPayouts.isEmpty) {
      return null;
    }

    var totalCents = 0;
    for (final payout in myPayouts) {
      final normalized = payout.amount.replaceAll(',', '');
      final parts = normalized.split('.');
      final whole = int.tryParse(parts.first) ?? 0;
      final fraction = parts.length > 1
          ? int.tryParse(parts[1].padRight(2, '0').substring(0, 2)) ?? 0
          : 0;
      totalCents += whole * 100 + fraction;
    }

    final whole = totalCents ~/ 100;
    final fraction = (totalCents % 100).toString().padLeft(2, '0');
    return '$whole.$fraction';
  }
}

// Model for registered cartela summary from backend
class RegisteredCartelaSummary {
  const RegisteredCartelaSummary({
    required this.cartelaId,
    required this.cartelaNumber,
    required this.owner,
    required this.status,
    this.expiresAt,
  });

  final String cartelaId;
  final int cartelaNumber;
  final String owner; // ME | OTHER | RESERVED_ME | RESERVED_OTHER
  final String status; // REGISTERED | WINNER | BLOCKED | RESERVED
  final DateTime? expiresAt;

  bool get isMine => owner == 'ME';
  bool get isTaken => owner == 'OTHER';
  bool get isReservedByMe => owner == 'RESERVED_ME';
  bool get isReservedByOther => owner == 'RESERVED_OTHER';

  factory RegisteredCartelaSummary.fromJson(Map<String, dynamic> json) {
    return RegisteredCartelaSummary(
      cartelaId: json['cartelaId'] as String,
      cartelaNumber: (json['cartelaNumber'] as num).toInt(),
      owner: json['owner'] as String,
      status: json['status'] as String,
      expiresAt: json['expiresAt'] is String
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
    );
  }
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
    this.winnerCartelaId,
    this.winnerWindowEndsAt,
    required this.createdAt,
    required this.updatedAt,
    required this.registeredCartelasCount,
    required this.calledNumbersCount,
    required this.registrationOpen,
    this.registeredCartelasSummary,
    this.winnerPayoutsSummary,
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
  final DateTime? winnerWindowEndsAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int registeredCartelasCount;
  final int calledNumbersCount;
  final bool registrationOpen;
  final List<RegisteredCartelaSummary>? registeredCartelasSummary;
  final List<WinnerPayoutSummary>? winnerPayoutsSummary;

  /// Simplified player-facing status (combines NEXT + READY into Registration Open)
  PlayerGameStatus get playerStatus => status.playerStatus;

  /// Whether this game shows as "Registration Open" to players
  bool get isRegistrationOpen =>
      status == GameStatus.next || status == GameStatus.ready;

  /// Whether this game is in a terminal state (finished or cancelled)
  bool get isTerminal => status == GameStatus.finished || status == GameStatus.cancelled;

  /// Automatic rules resolve claims on the server without admin review.
  bool get isAutomaticRule {
    final key = (gameRule?.key ?? gameType).trim().toUpperCase();
    return key != 'MANUAL';
  }

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
    final status = json['playerStatus'] is String
        ? _playerStatusToGameStatus(json['playerStatus'] as String)
        : GameStatus.fromApi(json['status'] as String);
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
      winnerWindowEndsAt: _parseDate(json['winnerWindowEndsAt']),
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
      registeredCartelasSummary: json['registeredCartelasSummary'] is List
          ? (json['registeredCartelasSummary'] as List)
              .map((item) => RegisteredCartelaSummary.fromJson(
                  item as Map<String, dynamic>))
              .toList()
          : null,
      winnerPayoutsSummary:
          WinnerPayoutSummary.parseList(json['winnerPayoutsSummary']),
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

  /// Parse from canonical operations endpoint (GET /games/operations/current)
  /// Backend decides which game is live/checking/registration/queue
  factory GameModel.fromOperationJson(Map<String, dynamic> json) {
    final gameRule = json['gameRule'] is Map<String, dynamic>
        ? GameRuleModel.fromJson(json['gameRule'] as Map<String, dynamic>)
        : null;

    // Map playerStatus to GameStatus for backward compatibility
    final playerStatus = json['playerStatus'] as String?;
    final rawStatus = json['rawStatus'] as String? ?? json['status'] as String? ?? 'NEXT';
    
    // Use playerStatus if available, otherwise fall back to rawStatus
    final status = playerStatus != null
        ? _playerStatusToGameStatus(playerStatus)
        : GameStatus.fromApi(rawStatus);

    return GameModel(
      id: json['slotId'] as String? ?? json['id'] as String,
      sessionId: json['sessionId'] as String?,
      staticCode: json['staticCode'] as String? ?? '',
      playCode: json['playCode'] as String?,
      name: gameRule?.name ?? json['name'] as String? ?? 'Game',
      gameRule: gameRule,
      gameType: gameRule?.key ?? json['gameType'] as String? ?? '',
      entryFee: json['entryFee']?.toString() ?? '0',
      prizePerCartela: json['prizePerCartela']?.toString() ?? '0',
      companyFeePerCartela: '0', // Not included in operations response
      prizeAmount: json['prizeAmount']?.toString() ?? '0',
      companyRevenue: json['companyRevenue']?.toString() ?? '0',
      status: status,
      playOrder: (json['sortOrder'] as num?)?.toInt(),
      startedAt: _parseDate(json['startedAt']),
      finishedAt: _parseDate(json['finishedAt']),
      winnerCartelaId: json['winnerCartelaId'] as String?,
      winnerWindowEndsAt: _parseDate(json['winnerWindowEndsAt']),
      createdAt: DateTime.now(), // Not in operations response
      updatedAt: DateTime.now(), // Not in operations response
      registeredCartelasCount: (json['registeredCartelasCount'] as num?)?.toInt() ?? 0,
      calledNumbersCount: (json['calledNumbersCount'] as num?)?.toInt() ?? 0,
      registrationOpen: json['registrationOpen'] as bool? ?? 
          (status == GameStatus.next || status == GameStatus.ready || status == GameStatus.playing),
      registeredCartelasSummary: json['registeredCartelasSummary'] is List
          ? (json['registeredCartelasSummary'] as List)
              .map((item) => RegisteredCartelaSummary.fromJson(
                  item as Map<String, dynamic>))
              .toList()
          : null,
      winnerPayoutsSummary:
          WinnerPayoutSummary.parseList(json['winnerPayoutsSummary']),
    );
  }

  String? myWinnerPayoutAmount(Set<String> myCartelaIds) {
    return WinnerPayoutSummary.totalForMyCartelas(
      payouts: winnerPayoutsSummary,
      myCartelaIds: myCartelaIds,
    );
  }

  static GameStatus _playerStatusToGameStatus(String playerStatus) {
    switch (playerStatus) {
      case 'registrationOpen':
        return GameStatus.next; // Frontend treats NEXT/READY the same
      case 'playing':
        return GameStatus.playing;
      case 'winnerWindow':
        return GameStatus.winnerWindow;
      case 'checking':
        return GameStatus.checking;
      case 'finished':
        return GameStatus.finished;
      case 'cancelled':
        return GameStatus.cancelled;
      default:
        return GameStatus.next;
    }
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
    DateTime? winnerWindowEndsAt,
    int? registeredCartelasCount,
    int? calledNumbersCount,
    bool? registrationOpen,
    List<RegisteredCartelaSummary>? registeredCartelasSummary,
    List<WinnerPayoutSummary>? winnerPayoutsSummary,
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
      winnerWindowEndsAt: winnerWindowEndsAt ?? this.winnerWindowEndsAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      registeredCartelasCount:
          registeredCartelasCount ?? this.registeredCartelasCount,
      calledNumbersCount: calledNumbersCount ?? this.calledNumbersCount,
      registrationOpen: registrationOpen ?? this.registrationOpen,
      registeredCartelasSummary:
          registeredCartelasSummary ?? this.registeredCartelasSummary,
      winnerPayoutsSummary:
          winnerPayoutsSummary ?? this.winnerPayoutsSummary,
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

/// CANONICAL SOURCE OF TRUTH response from backend
/// Backend decides which game is live/checking/registration/queue
/// Frontend MUST NOT apply additional filtering/sorting
class GameOperationsCurrentResponse {
  const GameOperationsCurrentResponse({
    required this.liveGame,
    required this.checkingGame,
    required this.registrationOpenGame,
    required this.queue,
    required this.timestamp,
  });

  final GameModel? liveGame;
  final GameModel? checkingGame;
  final GameModel? registrationOpenGame;
  final List<GameModel> queue;
  final DateTime timestamp;

  /// Get the current game for player display (priority: live > checking > registration)
  /// Returns null if no active game
  GameModel? get currentGameForPlayer {
    return liveGame ?? checkingGame ?? registrationOpenGame;
  }

  /// Check if there's any active game (not just queue)
  bool get hasActiveGame {
    return liveGame != null || checkingGame != null || registrationOpenGame != null;
  }

  factory GameOperationsCurrentResponse.fromJson(Map<String, dynamic> json) {
    final timestamp = DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now();

    return GameOperationsCurrentResponse(
      liveGame: json['liveGame'] != null
          ? GameModel.fromOperationJson(json['liveGame'] as Map<String, dynamic>)
          : null,
      checkingGame: json['checkingGame'] != null
          ? GameModel.fromOperationJson(json['checkingGame'] as Map<String, dynamic>)
          : null,
      registrationOpenGame: json['registrationOpenGame'] != null
          ? GameModel.fromOperationJson(json['registrationOpenGame'] as Map<String, dynamic>)
          : null,
      queue: (json['queue'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => GameModel.fromOperationJson(e))
          .toList(),
      timestamp: timestamp,
    );
  }
}
