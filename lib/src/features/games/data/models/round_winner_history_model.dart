import 'session_winner_result_model.dart';

/// One completed round's winners for final-summary "All Rounds Winners" UI.
class RoundWinnerHistoryRound {
  const RoundWinnerHistoryRound({
    required this.roundIndex,
    required this.sessionId,
    required this.status,
    required this.prizeAmount,
    this.winnerResults = const [],
  });

  final int roundIndex;
  final String sessionId;
  final RoundWinnerHistoryStatus status;
  final String prizeAmount;
  final List<SessionWinnerResultModel> winnerResults;

  bool get hasWinners => winnerResults.isNotEmpty;
  bool get isNoWinner =>
      status == RoundWinnerHistoryStatus.noWinner ||
      status == RoundWinnerHistoryStatus.forfeited;

  factory RoundWinnerHistoryRound.fromJson(Map<String, dynamic> json) {
    return RoundWinnerHistoryRound(
      roundIndex: (json['roundIndex'] as num?)?.toInt() ?? 1,
      sessionId: json['sessionId']?.toString() ?? '',
      status: RoundWinnerHistoryStatus.fromApi(json['status'] as String?),
      prizeAmount: json['prizeAmount']?.toString() ?? '0',
      winnerResults: SessionWinnerResultModel.parseList(json['winnerResults']),
    );
  }
}

enum RoundWinnerHistoryStatus {
  finished,
  noWinner,
  forfeited;

  factory RoundWinnerHistoryStatus.fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'NO_WINNER':
        return RoundWinnerHistoryStatus.noWinner;
      case 'FORFEITED':
        return RoundWinnerHistoryStatus.forfeited;
      default:
        return RoundWinnerHistoryStatus.finished;
    }
  }
}

/// Slot- or session-scoped multi-round winner history payload.
class RoundWinnerHistory {
  const RoundWinnerHistory({
    required this.roundCount,
    required this.rounds,
    this.slotId,
    this.sessionId,
  });

  final String? slotId;
  final String? sessionId;
  final int roundCount;
  final List<RoundWinnerHistoryRound> rounds;

  factory RoundWinnerHistory.fromJson(Map<String, dynamic> json) {
    final roundsRaw = json['rounds'];
    return RoundWinnerHistory(
      slotId: json['slotId']?.toString(),
      sessionId: json['sessionId']?.toString(),
      roundCount: (json['roundCount'] as num?)?.toInt() ??
          (roundsRaw is List ? roundsRaw.length : 0),
      rounds: roundsRaw is List
          ? roundsRaw
                .whereType<Map<String, dynamic>>()
                .map(RoundWinnerHistoryRound.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}
