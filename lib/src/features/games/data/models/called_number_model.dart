class CalledNumberModel {
  CalledNumberModel({
    required this.id,
    required this.sessionId,
    required this.letter,
    required this.number,
    required this.order,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final String letter;
  final int number;
  final int order;
  final DateTime createdAt;

  factory CalledNumberModel.fromJson(Map<String, dynamic> json) {
    return CalledNumberModel(
      id: json['id'] as String,
      // Backend sends gameSessionId in the new architecture.
      sessionId: (json['gameSessionId'] as String?) ?? (json['gameId'] as String?) ?? '',
      letter: json['letter'] as String,
      number: (json['number'] as num).toInt(),
      order: (json['order'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String get displayValue => '$letter$number';
}
