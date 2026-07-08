class SessionOutcomeSummaryModel {
  const SessionOutcomeSummaryModel({
    required this.winnerCartelaNumbers,
    required this.blockedCartelaNumbers,
  });

  final List<int> winnerCartelaNumbers;
  final List<int> blockedCartelaNumbers;

  factory SessionOutcomeSummaryModel.fromJson(Map<String, dynamic> json) {
    return SessionOutcomeSummaryModel(
      winnerCartelaNumbers: _parseNumbers(json['winnerCartelaNumbers']),
      blockedCartelaNumbers: _parseNumbers(json['blockedCartelaNumbers']),
    );
  }

  static SessionOutcomeSummaryModel? parse(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }

    return SessionOutcomeSummaryModel.fromJson(value);
  }

  static List<int> _parseNumbers(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<num>()
        .map((number) => number.toInt())
        .toList(growable: false)
      ..sort();
  }
}

List<int> mergeSortedCartelaNumbers(Iterable<int> values) {
  return values.toSet().toList(growable: false)..sort();
}
