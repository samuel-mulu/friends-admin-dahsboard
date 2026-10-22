class CartelaModel {
  CartelaModel({
    required this.id,
    required this.number,
    required this.createdAt,
    List<String>? b,
    List<String>? i,
    List<String>? n,
    List<String>? g,
    List<String>? o,
  })  : b = b ?? const [],
        i = i ?? const [],
        n = n ?? const [],
        g = g ?? const [],
        o = o ?? const [];

  final String id;
  final int number;
  final List<String> b;
  final List<String> i;
  final List<String> n;
  final List<String> g;
  final List<String> o;
  final DateTime createdAt;

  bool get hasBoardValues =>
      b.isNotEmpty || i.isNotEmpty || n.isNotEmpty || g.isNotEmpty || o.isNotEmpty;

  factory CartelaModel.fromJson(Map<String, dynamic> json) {
    return CartelaModel(
      id: json['id'] as String,
      number: json['number'] as int,
      b: json.containsKey('b') ? _parseColumn(json['b']) : const [],
      i: json.containsKey('i') ? _parseColumn(json['i']) : const [],
      n: json.containsKey('n') ? _parseColumn(json['n']) : const [],
      g: json.containsKey('g') ? _parseColumn(json['g']) : const [],
      o: json.containsKey('o') ? _parseColumn(json['o']) : const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  CartelaModel copyWithBoard({
    required List<String> b,
    required List<String> i,
    required List<String> n,
    required List<String> g,
    required List<String> o,
  }) {
    return CartelaModel(
      id: id,
      number: number,
      createdAt: createdAt,
      b: b,
      i: i,
      n: n,
      g: g,
      o: o,
    );
  }

  List<List<String>> get columns => [b, i, n, g, o];

  static List<String> _parseColumn(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .map((item) {
          if (item == null) {
            return 'FREE';
          }

          final text = item.toString().trim();
          return text.isEmpty ? 'FREE' : text;
        })
        .toList(growable: false);
  }
}
