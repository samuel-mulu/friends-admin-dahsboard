class CompletedPatternModel {
  const CompletedPatternModel({
    required this.type,
    required this.numbers,
    required this.highlightCellIndexes,
    this.key,
  });

  final String type;
  final String? key;
  final List<int> numbers;
  final Set<int> highlightCellIndexes;

  factory CompletedPatternModel.fromJson(Map<String, dynamic> json) {
    final cells = json['cells'];
    final indexes = <int>{};

    if (cells is List) {
      for (final cell in cells) {
        if (cell is List && cell.length >= 2) {
          final row = (cell[0] as num).toInt();
          final col = (cell[1] as num).toInt();
          indexes.add(row * 5 + col);
        }
      }
    }

    return CompletedPatternModel(
      type: json['type'] as String? ?? '',
      key: json['key'] as String?,
      numbers: (json['numbers'] as List<dynamic>? ?? const [])
          .map((value) => (value as num).toInt())
          .toList(growable: false),
      highlightCellIndexes: indexes,
    );
  }

  static Set<int> mergedHighlightIndexes(
    Iterable<CompletedPatternModel> patterns,
  ) {
    return patterns
        .expand((pattern) => pattern.highlightCellIndexes)
        .toSet();
  }

  static List<CompletedPatternModel> parseList(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(CompletedPatternModel.fromJson)
        .toList(growable: false);
  }
}
