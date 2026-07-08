class CalledNumberModel {
  CalledNumberModel({
    required this.id,
    required this.sessionId,
    this.slotId,
    required this.letter,
    required this.number,
    required this.order,
    required this.createdAt,
    this.playerStatus,
  });

  final String id;
  final String sessionId;
  final String? slotId;
  final String letter;
  final int number;
  final int order;
  final DateTime createdAt;
  final String? playerStatus;

  factory CalledNumberModel.fromJson(Map<String, dynamic> json) {
    return CalledNumberModel(
      id: json['id'] as String,
      // Backend sends gameSessionId in the new architecture.
      sessionId:
          (json['gameSessionId'] as String?) ??
          (json['gameId'] as String?) ??
          '',
      slotId: (json['slotId'] as String?) ?? (json['gameSlotId'] as String?),
      letter: json['letter'] as String,
      number: (json['number'] as num).toInt(),
      order: (json['order'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      playerStatus: json['playerStatus'] as String?,
    );
  }

  String get displayValue => '$letter$number';
}
