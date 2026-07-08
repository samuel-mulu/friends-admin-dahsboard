import 'completed_pattern_model.dart';
import '../../domain/winning_ball_cell.dart';

export '../../domain/winning_ball_cell.dart'
    show SessionWinnerLastCalledNumber, cellIndexForCalledNumber, parseSessionWinnerLastCalledNumber;

class SessionWinnerResultModel {
  const SessionWinnerResultModel({
    required this.gameCartelaId,
    required this.cartelaId,
    required this.cartelaNumber,
    required this.amount,
    required this.columns,
    required this.completedPatterns,
    this.owner,
    this.winningBallCellIndex,
    this.lastCalledNumber,
  });

  final String gameCartelaId;
  final String cartelaId;
  final int cartelaNumber;
  final String amount;
  final String? owner;
  final List<List<String>> columns;
  final List<CompletedPatternModel> completedPatterns;
  final int? winningBallCellIndex;
  final SessionWinnerLastCalledNumber? lastCalledNumber;

  bool get isMine => owner == 'ME';

  SessionWinnerResultModel copyWith({
    String? amount,
    List<List<String>>? columns,
    List<CompletedPatternModel>? completedPatterns,
    SessionWinnerLastCalledNumber? lastCalledNumber,
    int? winningBallCellIndex,
  }) {
    return SessionWinnerResultModel(
      gameCartelaId: gameCartelaId,
      cartelaId: cartelaId,
      cartelaNumber: cartelaNumber,
      amount: amount ?? this.amount,
      owner: owner,
      columns: columns ?? this.columns,
      completedPatterns: completedPatterns ?? this.completedPatterns,
      winningBallCellIndex: winningBallCellIndex ?? this.winningBallCellIndex,
      lastCalledNumber: lastCalledNumber ?? this.lastCalledNumber,
    );
  }

  Set<int> get highlightCellIndexes =>
      CompletedPatternModel.mergedHighlightIndexes(completedPatterns);

  int? get resolvedWinningBallCellIndex => resolveWinningBallCellIndex(
        columns: columns,
        highlightCellIndexes: highlightCellIndexes,
        winningBallCellIndex: winningBallCellIndex,
        lastCalledNumber: lastCalledNumber,
      );

  String? get displayWinningBallLabel {
    final apiBall = lastCalledNumber;
    if (apiBall != null && apiBall.letter.isNotEmpty && apiBall.number > 0) {
      return apiBall.displayBall;
    }

    final cellIndex = resolvedWinningBallCellIndex;
    if (cellIndex == null) {
      return null;
    }

    final columnIndex = cellIndex % 5;
    final rowIndex = cellIndex ~/ 5;
    if (columnIndex < 0 ||
        columnIndex >= columns.length ||
        rowIndex < 0 ||
        rowIndex >= columns[columnIndex].length) {
      return null;
    }

    final value = columns[columnIndex][rowIndex];
    if (value == 'FREE') {
      return null;
    }

    final number = int.tryParse(value);
    if (number == null) {
      return null;
    }

    const letters = ['B', 'I', 'N', 'G', 'O'];
    return '${letters[columnIndex]}-$number';
  }

  factory SessionWinnerResultModel.fromJson(Map<String, dynamic> json) {
    final lastCalledRaw = json['lastCalledNumber'];
    return SessionWinnerResultModel(
      gameCartelaId: json['gameCartelaId'] as String,
      cartelaId: json['cartelaId'] as String,
      cartelaNumber: (json['cartelaNumber'] as num).toInt(),
      amount: json['amount']?.toString() ?? '0',
      owner: json['owner'] as String?,
      columns: _parseColumns(json),
      completedPatterns:
          CompletedPatternModel.parseList(json['completedPatterns']),
      winningBallCellIndex: (json['winningBallCellIndex'] as num?)?.toInt(),
      lastCalledNumber: lastCalledRaw is Map<String, dynamic>
          ? SessionWinnerLastCalledNumber.fromJson(lastCalledRaw)
          : null,
    );
  }

  static List<SessionWinnerResultModel> parseList(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(SessionWinnerResultModel.fromJson)
        .toList(growable: false);
  }

  static List<List<String>> _parseColumns(Map<String, dynamic> json) {
    List<String> column(Object? value) {
      if (value is! List) {
        return const [];
      }

      return value.map((item) => item.toString()).toList(growable: false);
    }

    return [
      column(json['b']),
      column(json['i']),
      column(json['n']),
      column(json['g']),
      column(json['o']),
    ];
  }
}
