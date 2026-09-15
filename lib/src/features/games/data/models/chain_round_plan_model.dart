import 'game_model.dart';

/// The full Chain Game round ladder for one session.
///
/// A chain fixes every round's pattern and prize at creation and never reopens
/// registration, so the whole ladder is known from round 1. The app fetches this
/// once per chain session to render the rounds dialog and the "next pattern"
/// hint during an inter-round break.
class ChainRoundPlan {
  const ChainRoundPlan({
    required this.sessionId,
    required this.roundCount,
    required this.currentRound,
    required this.totalPrizeAmount,
    required this.currentRoundPrizeAmount,
    required this.rounds,
    this.roundPausedUntil,
  });

  final String sessionId;
  final int roundCount;
  final int currentRound;
  final String totalPrizeAmount;
  final String currentRoundPrizeAmount;
  final List<ChainRoundPlanEntry> rounds;
  final DateTime? roundPausedUntil;

  ChainRoundPlanEntry? roundAt(int roundIndex) {
    for (final round in rounds) {
      if (round.roundIndex == roundIndex) {
        return round;
      }
    }
    return null;
  }

  /// Registration-open fallback when the chain-rounds API has not loaded yet.
  /// Uses slot `roundPrizes` so players still see every round's prize.
  factory ChainRoundPlan.fromGame(GameModel game) {
    final prizes = game.roundPrizes ?? const <String>[];
    final roundCount =
        prizes.isNotEmpty ? prizes.length : game.displayRoundCount;
    final current = game.displayRoundIndex;
    final currentName = game.gameRule?.name;
    final currentKey = game.gameRule?.key;

    return ChainRoundPlan(
      sessionId: game.sessionId ?? '',
      roundCount: roundCount < 1 ? 1 : roundCount,
      currentRound: current,
      totalPrizeAmount: game.prizeAmount,
      currentRoundPrizeAmount:
          game.effectiveRoundPrizeAmount ?? game.prizeAmount,
      roundPausedUntil: game.roundPausedUntil,
      rounds: List<ChainRoundPlanEntry>.generate(
        roundCount < 1 ? 1 : roundCount,
        (index) {
          final roundIndex = index + 1;
          final isCurrent = roundIndex == current;
          return ChainRoundPlanEntry(
            roundIndex: roundIndex,
            prizeAmount: index < prizes.length
                ? prizes[index]
                : (isCurrent
                      ? (game.effectiveRoundPrizeAmount ?? game.prizeAmount)
                      : '0'),
            state: isCurrent
                ? ChainRoundState.current
                : roundIndex < current
                ? ChainRoundState.won
                : ChainRoundState.upcoming,
            gameRuleName: isCurrent ? currentName : null,
            gameRuleKey: isCurrent ? currentKey : null,
          );
        },
      ),
    );
  }

  factory ChainRoundPlan.fromJson(Map<String, dynamic> json) {
    final rawRounds = json['rounds'];
    return ChainRoundPlan(
      sessionId: json['sessionId'] as String? ?? '',
      roundCount: (json['roundCount'] as num?)?.toInt() ?? 1,
      currentRound: (json['currentRound'] as num?)?.toInt() ?? 1,
      totalPrizeAmount: json['totalPrizeAmount']?.toString() ?? '0',
      currentRoundPrizeAmount:
          json['currentRoundPrizeAmount']?.toString() ?? '0',
      roundPausedUntil: json['roundPausedUntil'] is String
          ? DateTime.tryParse(json['roundPausedUntil'] as String)?.toLocal()
          : null,
      rounds: rawRounds is List
          ? rawRounds
                .whereType<Map<String, dynamic>>()
                .map(ChainRoundPlanEntry.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}

enum ChainRoundState {
  won,
  forfeited,
  current,
  upcoming;

  factory ChainRoundState.fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'WON':
        return ChainRoundState.won;
      case 'FORFEITED':
        return ChainRoundState.forfeited;
      case 'CURRENT':
        return ChainRoundState.current;
      default:
        return ChainRoundState.upcoming;
    }
  }

  bool get isDecided =>
      this == ChainRoundState.won || this == ChainRoundState.forfeited;
}

class ChainRoundPlanEntry {
  const ChainRoundPlanEntry({
    required this.roundIndex,
    required this.prizeAmount,
    required this.state,
    this.gameRuleKey,
    this.gameRuleName,
    this.paidAmount,
    this.finalizedAt,
    this.winnerCartelaNumbers = const [],
  });

  final int roundIndex;
  final String prizeAmount;
  final ChainRoundState state;
  final String? gameRuleKey;
  final String? gameRuleName;
  final String? paidAmount;
  final DateTime? finalizedAt;
  final List<int> winnerCartelaNumbers;

  factory ChainRoundPlanEntry.fromJson(Map<String, dynamic> json) {
    final winners = json['winners'];
    return ChainRoundPlanEntry(
      roundIndex: (json['roundIndex'] as num?)?.toInt() ?? 1,
      prizeAmount: json['prizeAmount']?.toString() ?? '0',
      state: ChainRoundState.fromApi(json['state'] as String?),
      gameRuleKey: json['gameRuleKey'] as String?,
      gameRuleName: json['gameRuleName'] as String?,
      paidAmount: json['paidAmount']?.toString(),
      finalizedAt: json['finalizedAt'] is String
          ? DateTime.tryParse(json['finalizedAt'] as String)?.toLocal()
          : null,
      winnerCartelaNumbers: winners is List
          ? winners
                .whereType<Map<String, dynamic>>()
                .map((winner) => (winner['cartelaNumber'] as num?)?.toInt() ?? 0)
                .where((number) => number > 0)
                .toList(growable: false)
          : const [],
    );
  }
}
