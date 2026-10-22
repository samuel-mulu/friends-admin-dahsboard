class SessionWinnerLastCalledNumber {
  const SessionWinnerLastCalledNumber({
    required this.letter,
    required this.number,
  });

  final String letter;
  final int number;

  String get displayBall => '$letter-$number';

  factory SessionWinnerLastCalledNumber.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('lastCalledNumber json is null');
    }

    return SessionWinnerLastCalledNumber(
      letter: json['letter'] as String? ?? '',
      number: (json['number'] as num?)?.toInt() ?? 0,
    );
  }
}

SessionWinnerLastCalledNumber? parseSessionWinnerLastCalledNumber(
  Object? value,
) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final letter = value['letter'] as String?;
  final number = (value['number'] as num?)?.toInt();
  if (letter == null || letter.isEmpty || number == null) {
    return null;
  }

  return SessionWinnerLastCalledNumber(letter: letter, number: number);
}

int? cellIndexForCalledNumber(
  List<List<String>> columns,
  int calledNumber,
) {
  for (var columnIndex = 0; columnIndex < columns.length; columnIndex++) {
    final column = columns[columnIndex];
    for (var rowIndex = 0; rowIndex < column.length; rowIndex++) {
      final value = column[rowIndex];
      if (value == 'FREE') {
        continue;
      }

      final parsed = int.tryParse(value);
      if (parsed == calledNumber) {
        return rowIndex * 5 + columnIndex;
      }
    }
  }

  return null;
}

int? resolveWinningBallCellIndex({
  required List<List<String>> columns,
  required Set<int> highlightCellIndexes,
  int? winningBallCellIndex,
  SessionWinnerLastCalledNumber? lastCalledNumber,
}) {
  if (winningBallCellIndex != null) {
    return winningBallCellIndex;
  }

  final calledNumber = lastCalledNumber?.number;
  if (calledNumber == null) {
    return null;
  }

  return cellIndexForCalledNumber(columns, calledNumber);
}
