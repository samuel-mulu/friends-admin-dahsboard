import 'called_number_model.dart';

class CalledNumbersSnapshot {
  CalledNumbersSnapshot({
    required this.totalCount,
    required this.calledNumbers,
  });

  final int totalCount;
  final List<CalledNumberModel> calledNumbers;

  factory CalledNumbersSnapshot.fromJson(Map<String, dynamic> json) {
    final rawCalledNumbers = json['calledNumbers'];

    return CalledNumbersSnapshot(
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      calledNumbers: rawCalledNumbers is List
          ? rawCalledNumbers
                .whereType<Map<String, dynamic>>()
                .map(CalledNumberModel.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}
