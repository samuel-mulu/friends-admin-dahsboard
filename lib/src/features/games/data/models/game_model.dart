import 'package:flutter/material.dart';

import '../../../../core/utils/api_date_time.dart';
import '../../domain/backend_called_number_identity.dart';
import 'session_outcome_summary_model.dart';

const _copyWithKeep = Object();

class GameRuleModel {
  GameRuleModel({
    required this.id,
    required this.key,
    required this.name,
    this.description,
  });

  final String id;
  final String key;
  final String name;
  final String? description;

  factory GameRuleModel.fromJson(Map<String, dynamic> json) {
    final key = json['key'] as String? ?? '';
    return GameRuleModel(
      id: json['id'] as String? ?? key,
      key: key,
      name: json['name'] as String? ?? key,
      description: json['description'] as String?,
    );
  }
}

enum GameCategory {
  normal,
  bonus,
  bigGotd,
  bigGame;

  factory GameCategory.fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'BONUS':
        return GameCategory.bonus;
      case 'BIG_GOTD':
        return GameCategory.bigGotd;
      case 'BIG_GAME':
        return GameCategory.bigGame;
      case 'NORMAL':
      default:
        return GameCategory.normal;
    }
  }

  bool get isBonusLike =>
      this == GameCategory.bonus || this == GameCategory.bigGotd;

  bool get hasFreeEntry => this == GameCategory.bonus;

  /// Welcome bonus cartela credits apply only to normal games.
  bool get canUseBonusCartelaBalance => this == GameCategory.normal;
}

enum GameStatus {
  next,
  ready,
  checking,
  playing,
  winnerWindow,
  finished,
  noWinner,
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
      case 'NO_WINNER':
        return GameStatus.noWinner;
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
      case GameStatus.noWinner:
        return 'No Winner';
      case GameStatus.cancelled:
        return 'Cancelled';
    }
  }

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
      case GameStatus.noWinner:
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

class BlockingLiveGameSummary {
  const BlockingLiveGameSummary({
    required this.sessionId,
    required this.staticCode,
    this.playCode,
    required this.playerStatus,
  });

  final String sessionId;
  final String staticCode;
  final String? playCode;
  final String playerStatus;

  factory BlockingLiveGameSummary.fromJson(Map<String, dynamic> json) {
    return BlockingLiveGameSummary(
      sessionId: json['sessionId'] as String,
      staticCode: json['staticCode'] as String? ?? '',
      playCode: json['playCode'] as String?,
      playerStatus: json['playerStatus'] as String? ?? 'playing',
    );
  }
}

class BigGameLiveElsewhere {
  const BigGameLiveElsewhere({
    required this.sessionId,
    required this.phase,
  });

  final String sessionId;
  final String phase;

  bool get isLive => phase == 'live';
  bool get isHeld => phase == 'held';

  factory BigGameLiveElsewhere.fromJson(Map<String, dynamic> json) {
    return BigGameLiveElsewhere(
      sessionId: json['sessionId'] as String,
      phase: json['phase'] as String? ?? 'live',
    );
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
    this.cancelledReason,
    this.winnerCartelaId,
    this.winnerWindowEndsAt,
    this.noWinnerGraceEndsAt,
    this.noWinnerReason,
    this.nextAutoCallAt,
    this.autoCallIntervalMs,
    required this.createdAt,
    required this.updatedAt,
    required this.registeredCartelasCount,
    required this.calledNumbersCount,
    required this.registrationOpen,
    required this.canRegister,
    this.scheduledStartAt,
    this.registrationOpensAt,
    this.operationMode = 'MANUAL',
    this.registeredCartelasSummary,
    this.winnerPayoutsSummary,
    this.sessionOutcomeSummary,
    this.category = GameCategory.normal,
    this.fixedPrizeAmount,
    this.maxCartelasPerPlayer,
    this.heldWaitingForLiveSlot = false,
    this.blockingLiveGame,
    this.latestCalledNumberIdentity,
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

  /// 'no_players' | 'admin_cancelled' when status is CANCELLED.
  final String? cancelledReason;
  final String? winnerCartelaId;
  final DateTime? winnerWindowEndsAt;
  final DateTime? noWinnerGraceEndsAt;
  final String? noWinnerReason;
  final DateTime? nextAutoCallAt;
  final int? autoCallIntervalMs;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int registeredCartelasCount;
  final int calledNumbersCount;
  final bool registrationOpen;
  final bool canRegister;
  final DateTime? scheduledStartAt;
  final DateTime? registrationOpensAt;
  final String operationMode;
  final List<RegisteredCartelaSummary>? registeredCartelasSummary;
  final List<WinnerPayoutSummary>? winnerPayoutsSummary;
  final SessionOutcomeSummaryModel? sessionOutcomeSummary;
  final GameCategory category;
  final String? fixedPrizeAmount;
  final int? maxCartelasPerPlayer;
  final bool heldWaitingForLiveSlot;
  final BlockingLiveGameSummary? blockingLiveGame;
  final BackendCalledNumberIdentity? latestCalledNumberIdentity;

  /// Simplified player-facing status (combines NEXT + READY into Registration Open)
  PlayerGameStatus get playerStatus => status.playerStatus;

  bool get isBonus => category == GameCategory.bonus;

  bool get isBigGotd => category == GameCategory.bigGotd;

  bool get isBigGame => category == GameCategory.bigGame;

  bool get isBonusLike => category.isBonusLike;

  bool get hasFreeEntry => category.hasFreeEntry;

  bool get canUseBonusCartelaBalance => category.canUseBonusCartelaBalance;

  /// Whether this game shows as "Registration Open" to players
  bool get isRegistrationOpen =>
      status == GameStatus.next || status == GameStatus.ready;

  /// Whether this game is in a terminal state (finished or cancelled)
  bool get isTerminal =>
      status == GameStatus.finished ||
      status == GameStatus.noWinner ||
      status == GameStatus.cancelled;

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
    final latestSessionJson = json['latestSession'];
    final latestSessionStatus = latestSessionJson is Map<String, dynamic>
        ? _gameStatusFromApi(latestSessionJson['status'] as String?)
        : null;
    final payloadStatus = json['playerStatus'] is String
        ? _playerStatusToGameStatus(json['playerStatus'] as String)
        : GameStatus.fromApi(json['status'] as String);
    final status = _resolveLiveJsonStatus(
      payloadStatus: payloadStatus,
      latestSessionStatus: latestSessionStatus,
    );
    final latestWinnerWindowEndsAt = latestSessionJson is Map<String, dynamic>
        ? _parseDate(latestSessionJson['winnerWindowEndsAt'])
        : null;
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
      cancelledReason: json['cancelledReason'] as String?,
      winnerCartelaId: json['winnerCartelaId'] as String?,
      winnerWindowEndsAt:
          _parseDate(json['winnerWindowEndsAt']) ?? latestWinnerWindowEndsAt,
      noWinnerGraceEndsAt: _parseDate(json['noWinnerGraceEndsAt']),
      noWinnerReason: json['noWinnerReason'] as String?,
      nextAutoCallAt: _parseDate(json['nextAutoCallAt']),
      autoCallIntervalMs: _parseInt(json['autoCallIntervalMs']),
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
          json['registrationOpen'] as bool? ??
          (json['canRegister'] as bool? ?? false),
      canRegister:
          json['canRegister'] as bool? ??
          (json['registrationOpen'] as bool? ?? false),
      scheduledStartAt: _parseDate(json['scheduledStartAt']),
      registrationOpensAt: _parseDate(json['registrationOpensAt']),
      operationMode: json['operationMode'] as String? ?? 'MANUAL',
      registeredCartelasSummary: json['registeredCartelasSummary'] is List
          ? (json['registeredCartelasSummary'] as List)
                .map(
                  (item) => RegisteredCartelaSummary.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList()
          : null,
      winnerPayoutsSummary: WinnerPayoutSummary.parseList(
        json['winnerPayoutsSummary'],
      ),
      sessionOutcomeSummary: SessionOutcomeSummaryModel.parse(
        json['sessionOutcomeSummary'],
      ),
      category: _resolveGameCategory(json, fallback: gameSlot),
      fixedPrizeAmount: _parseOptionalMoney(
        json['fixedPrizeAmount'] ?? gameSlot?['fixedPrizeAmount'],
      ),
      maxCartelasPerPlayer: _parseInt(
        json['maxCartelasPerPlayer'] ?? gameSlot?['maxCartelasPerPlayer'],
      ),
      heldWaitingForLiveSlot: json['heldWaitingForLiveSlot'] == true,
      blockingLiveGame: json['blockingLiveGame'] is Map<String, dynamic>
          ? BlockingLiveGameSummary.fromJson(
              json['blockingLiveGame'] as Map<String, dynamic>,
            )
          : null,
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
    final rawStatus =
        json['rawStatus'] as String? ?? json['status'] as String? ?? 'NEXT';

    final status = _resolveOperationStatus(
      playerStatus: playerStatus,
      rawStatus: rawStatus,
    );

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
      cancelledReason: json['cancelledReason'] as String?,
      winnerCartelaId: json['winnerCartelaId'] as String?,
      winnerWindowEndsAt: _parseDate(json['winnerWindowEndsAt']),
      noWinnerGraceEndsAt: _parseDate(json['noWinnerGraceEndsAt']),
      noWinnerReason: json['noWinnerReason'] as String?,
      nextAutoCallAt: _parseDate(json['nextAutoCallAt']),
      autoCallIntervalMs: _parseInt(json['autoCallIntervalMs']),
      createdAt: DateTime.now(), // Not in operations response
      updatedAt: DateTime.now(), // Not in operations response
      registeredCartelasCount:
          (json['registeredCartelasCount'] as num?)?.toInt() ?? 0,
      calledNumbersCount: _resolveOperationCalledNumbersCount(json),
      registrationOpen:
          json['registrationOpen'] as bool? ??
          (json['canRegister'] as bool? ?? false),
      canRegister:
          json['canRegister'] as bool? ??
          (json['registrationOpen'] as bool? ?? false),
      scheduledStartAt: _parseDate(json['scheduledStartAt']),
      registrationOpensAt: _parseDate(json['registrationOpensAt']),
      operationMode: json['operationMode'] as String? ?? 'MANUAL',
      registeredCartelasSummary: json['registeredCartelasSummary'] is List
          ? (json['registeredCartelasSummary'] as List)
                .map(
                  (item) => RegisteredCartelaSummary.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList()
          : null,
      winnerPayoutsSummary: WinnerPayoutSummary.parseList(
        json['winnerPayoutsSummary'],
      ),
      sessionOutcomeSummary: SessionOutcomeSummaryModel.parse(
        json['sessionOutcomeSummary'],
      ),
      category: _resolveGameCategory(json),
      fixedPrizeAmount: _parseOptionalMoney(json['fixedPrizeAmount']),
      maxCartelasPerPlayer: _parseInt(json['maxCartelasPerPlayer']),
      latestCalledNumberIdentity: BackendCalledNumberIdentity.fromJson(
        json['latestCalledNumber'],
      ),
    );
  }

  String? myWinnerPayoutAmount(Set<String> myCartelaIds) {
    return WinnerPayoutSummary.totalForMyCartelas(
      payouts: winnerPayoutsSummary,
      myCartelaIds: myCartelaIds,
    );
  }

  static int _resolveOperationCalledNumbersCount(Map<String, dynamic> json) {
    final count = (json['calledNumbersCount'] as num?)?.toInt() ?? 0;
    final latest = json['latestCalledNumber'];
    if (latest is! Map<String, dynamic>) {
      return count;
    }

    final latestOrder = (latest['order'] as num?)?.toInt() ?? 0;
    return latestOrder > count ? latestOrder : count;
  }

  static GameCategory _parseGameCategory(
    Map<String, dynamic> json, {
    Map<String, dynamic>? fallback,
  }) {
    final rawCategory =
        json['category'] ??
        json['gameCategory'] ??
        json['slotCategory'] ??
        fallback?['category'];
    return GameCategory.fromApi(rawCategory?.toString());
  }

  static GameCategory _resolveGameCategory(
    Map<String, dynamic> json, {
    Map<String, dynamic>? fallback,
  }) {
    if (json['isBigGame'] == true) {
      return GameCategory.bigGame;
    }
    return _parseGameCategory(json, fallback: fallback);
  }

  static GameStatus _resolveOperationStatus({
    required String? playerStatus,
    required String rawStatus,
  }) {
    final fromRaw = GameStatus.fromApi(rawStatus);
    if (fromRaw == GameStatus.playing ||
        fromRaw == GameStatus.winnerWindow ||
        fromRaw == GameStatus.checking ||
        fromRaw == GameStatus.finished ||
        fromRaw == GameStatus.noWinner ||
        fromRaw == GameStatus.cancelled) {
      return fromRaw;
    }

    if (fromRaw == GameStatus.next || fromRaw == GameStatus.ready) {
      return fromRaw;
    }

    if (playerStatus != null) {
      return _playerStatusToGameStatus(playerStatus);
    }

    return fromRaw;
  }

  static GameStatus _playerStatusToGameStatus(String playerStatus) {
    switch (playerStatus) {
      case 'registrationOpen':
        return GameStatus.ready;
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

  static GameStatus? _gameStatusFromApi(String? value) {
    if (value == null) {
      return null;
    }

    try {
      return GameStatus.fromApi(value);
    } catch (_) {
      return null;
    }
  }

  static GameStatus _resolveLiveJsonStatus({
    required GameStatus payloadStatus,
    required GameStatus? latestSessionStatus,
  }) {
    if (latestSessionStatus == null) {
      return payloadStatus;
    }

    return _preferMoreLiveStatus(payloadStatus, latestSessionStatus);
  }

  static int _gameStatusRank(GameStatus status) {
    return switch (status) {
      GameStatus.next => 0,
      GameStatus.ready => 1,
      GameStatus.playing => 2,
      GameStatus.winnerWindow => 3,
      GameStatus.checking => 3,
      GameStatus.finished => 4,
      GameStatus.noWinner => 4,
      GameStatus.cancelled => 4,
    };
  }

  static GameStatus _preferMoreLiveStatus(GameStatus left, GameStatus right) {
    return _gameStatusRank(right) >= _gameStatusRank(left) ? right : left;
  }

  /// Keeps the more advanced session status when a canonical refetch briefly
  /// returns stale registration/playing data for the same live session.
  ///
  /// Phase B2: This method ALWAYS uses the incoming (canonical) game's metrics
  /// (prizeAmount, registeredCartelasCount, etc.) as the permanent truth.
  /// Socket patch optimistic updates are ALWAYS overwritten by this merge.
  ///
  /// Architecture:
  /// - Socket patches → temporary UI feedback only
  /// - operations/current (incoming) → permanent truth (this method)
  ///
  /// The only fields preserved from current are:
  /// - status (if more advanced)
  /// - winnerWindowEndsAt (if incoming is null but current has it)
  ///
  /// All other fields (including metrics) come from incoming.
  static GameModel mergeCanonicalSessionState({
    required GameModel? current,
    required GameModel incoming,
  }) {
    if (current == null) {
      return incoming;
    }

    final sameSession =
        current.sessionId != null && current.sessionId == incoming.sessionId;
    if (!sameSession) {
      // Phase B2: Different session → use incoming entirely (all metrics replaced).
      return incoming;
    }

    final mergedStatus = _preferMoreLiveStatus(current.status, incoming.status);
    if (mergedStatus == incoming.status &&
        mergedStatus == current.status &&
        incoming.winnerWindowEndsAt == null &&
        current.winnerWindowEndsAt != null) {
      // Phase B2: Same status, preserve winnerWindowEndsAt, but all metrics from incoming.
      return incoming.copyWith(winnerWindowEndsAt: current.winnerWindowEndsAt);
    }

    if (mergedStatus == incoming.status) {
      // Phase B2: Incoming status is preferred → use incoming entirely (all metrics replaced).
      return incoming;
    }

    // Phase B2: Current status is more advanced → use incoming with status override.
    // All metrics (prizeAmount, registeredCartelasCount, etc.) still come from incoming.
    return incoming.copyWith(
      status: mergedStatus,
      winnerWindowEndsAt: mergedStatus == GameStatus.winnerWindow
          ? (incoming.winnerWindowEndsAt ?? current.winnerWindowEndsAt)
          : incoming.winnerWindowEndsAt,
    );
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
    String? cancelledReason,
    String? winnerCartelaId,
    DateTime? winnerWindowEndsAt,
    Object? noWinnerGraceEndsAt = _copyWithKeep,
    Object? noWinnerReason = _copyWithKeep,
    Object? nextAutoCallAt = _copyWithKeep,
    int? autoCallIntervalMs,
    int? registeredCartelasCount,
    int? calledNumbersCount,
    bool? registrationOpen,
    bool? canRegister,
    DateTime? scheduledStartAt,
    DateTime? registrationOpensAt,
    String? operationMode,
    List<RegisteredCartelaSummary>? registeredCartelasSummary,
    List<WinnerPayoutSummary>? winnerPayoutsSummary,
    SessionOutcomeSummaryModel? sessionOutcomeSummary,
    GameCategory? category,
    Object? fixedPrizeAmount = _copyWithKeep,
    Object? maxCartelasPerPlayer = _copyWithKeep,
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
      cancelledReason: cancelledReason ?? this.cancelledReason,
      winnerCartelaId: winnerCartelaId ?? this.winnerCartelaId,
      winnerWindowEndsAt: winnerWindowEndsAt ?? this.winnerWindowEndsAt,
      noWinnerGraceEndsAt: identical(noWinnerGraceEndsAt, _copyWithKeep)
          ? this.noWinnerGraceEndsAt
          : noWinnerGraceEndsAt as DateTime?,
      noWinnerReason: identical(noWinnerReason, _copyWithKeep)
          ? this.noWinnerReason
          : noWinnerReason as String?,
      nextAutoCallAt: identical(nextAutoCallAt, _copyWithKeep)
          ? this.nextAutoCallAt
          : nextAutoCallAt as DateTime?,
      autoCallIntervalMs: autoCallIntervalMs ?? this.autoCallIntervalMs,
      createdAt: createdAt,
      updatedAt: updatedAt,
      registeredCartelasCount:
          registeredCartelasCount ?? this.registeredCartelasCount,
      calledNumbersCount: calledNumbersCount ?? this.calledNumbersCount,
      registrationOpen: registrationOpen ?? this.registrationOpen,
      canRegister: canRegister ?? this.canRegister,
      scheduledStartAt: scheduledStartAt ?? this.scheduledStartAt,
      registrationOpensAt: registrationOpensAt ?? this.registrationOpensAt,
      operationMode: operationMode ?? this.operationMode,
      registeredCartelasSummary:
          registeredCartelasSummary ?? this.registeredCartelasSummary,
      winnerPayoutsSummary: winnerPayoutsSummary ?? this.winnerPayoutsSummary,
      sessionOutcomeSummary:
          sessionOutcomeSummary ?? this.sessionOutcomeSummary,
      category: category ?? this.category,
      fixedPrizeAmount: identical(fixedPrizeAmount, _copyWithKeep)
          ? this.fixedPrizeAmount
          : fixedPrizeAmount as String?,
      maxCartelasPerPlayer: identical(maxCartelasPerPlayer, _copyWithKeep)
          ? this.maxCartelasPerPlayer
          : maxCartelasPerPlayer as int?,
    );
  }

  static DateTime? _parseDate(Object? value) => parseApiDateTime(value);

  static int? _parseInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return null;
  }

  static String? _parseOptionalMoney(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
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
    required this.serverNow,
    this.bigGameLiveElsewhere,
  });

  final GameModel? liveGame;
  final GameModel? checkingGame;
  final GameModel? registrationOpenGame;
  final List<GameModel> queue;
  final DateTime timestamp;
  final DateTime serverNow;
  final BigGameLiveElsewhere? bigGameLiveElsewhere;

  /// Get the current game for player display (priority: live > checking > registration)
  /// Returns null if no active game
  GameModel? get currentGameForPlayer {
    return liveGame ?? checkingGame ?? registrationOpenGame;
  }

  /// Check if there's any active game (not just queue)
  bool get hasActiveGame {
    return liveGame != null ||
        checkingGame != null ||
        registrationOpenGame != null;
  }

  /// Next game in queue that is not the [current] game (registration open first).
  GameModel? nextUpcomingGameFor({GameModel? current}) {
    bool matchesCurrent(GameModel candidate) {
      if (current == null) {
        return false;
      }
      if (candidate.id == current.id) {
        return true;
      }
      final currentSessionId = current.sessionId;
      final candidateSessionId = candidate.sessionId;
      return currentSessionId != null &&
          candidateSessionId != null &&
          currentSessionId == candidateSessionId;
    }

    final registration = registrationOpenGame;
    if (registration != null && !matchesCurrent(registration)) {
      return registration;
    }

    for (final item in queue) {
      if (!matchesCurrent(item)) {
        return item;
      }
    }

    return null;
  }

  /// Next round to load after a finished/cancelled session. Prefers a new
  /// registration-open game, then queue, then live/checking — never the same
  /// terminal session the player just left.
  GameModel? resolveAdvanceTargetFor({required GameModel terminalGame}) {
    bool isNewRound(GameModel candidate) {
      if (candidate.sessionId != null && terminalGame.sessionId != null) {
        return candidate.sessionId != terminalGame.sessionId;
      }
      if (candidate.id != terminalGame.id) {
        return true;
      }
      return candidate.status != GameStatus.finished &&
          candidate.status != GameStatus.noWinner &&
          candidate.status != GameStatus.cancelled;
    }

    final registration = registrationOpenGame;
    if (registration != null && isNewRound(registration)) {
      return registration;
    }

    for (final item in queue) {
      if (item.status == GameStatus.ready &&
          item.canRegister &&
          isNewRound(item)) {
        return item;
      }
    }

    for (final item in [liveGame, checkingGame]) {
      if (item != null && isNewRound(item)) {
        return item;
      }
    }

    return null;
  }

  factory GameOperationsCurrentResponse.fromJson(Map<String, dynamic> json) {
    final timestamp =
        DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now();
    final serverNowRaw = json['serverNow'] as String?;
    final serverNow = serverNowRaw == null
        ? timestamp.toUtc()
        : DateTime.tryParse(serverNowRaw)?.toUtc() ?? timestamp.toUtc();

    return GameOperationsCurrentResponse(
      liveGame: json['liveGame'] != null
          ? GameModel.fromOperationJson(
              json['liveGame'] as Map<String, dynamic>,
            )
          : null,
      checkingGame: json['checkingGame'] != null
          ? GameModel.fromOperationJson(
              json['checkingGame'] as Map<String, dynamic>,
            )
          : null,
      registrationOpenGame: json['registrationOpenGame'] != null
          ? GameModel.fromOperationJson(
              json['registrationOpenGame'] as Map<String, dynamic>,
            )
          : null,
      queue: (json['queue'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => GameModel.fromOperationJson(e))
          .toList(),
      timestamp: timestamp,
      serverNow: serverNow,
      bigGameLiveElsewhere: json['bigGameLiveElsewhere'] is Map<String, dynamic>
          ? BigGameLiveElsewhere.fromJson(
              json['bigGameLiveElsewhere'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
