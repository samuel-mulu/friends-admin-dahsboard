class BackendCalledNumberIdentity {
  const BackendCalledNumberIdentity({
    required this.order,
    required this.letter,
    required this.number,
  });

  final int order;
  final String letter;
  final int number;

  static BackendCalledNumberIdentity? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    final letter = json['letter'] as String?;
    final number = (json['number'] as num?)?.toInt();
    final order = (json['order'] as num?)?.toInt();
    if (letter == null || letter.isEmpty || number == null || order == null) {
      return null;
    }

    return BackendCalledNumberIdentity(
      order: order,
      letter: letter,
      number: number,
    );
  }
}
