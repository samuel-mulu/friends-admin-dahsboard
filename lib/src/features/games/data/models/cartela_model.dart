class CartelaModel {
  CartelaModel({
    required this.id,
    required this.number,
    required this.b,
    required this.i,
    required this.n,
    required this.g,
    required this.o,
    required this.createdAt,
  });

  final String id;
  final int number;
  final List<String> b;
  final List<String> i;
  final List<String> n;
  final List<String> g;
  final List<String> o;
  final DateTime createdAt;

  factory CartelaModel.fromJson(Map<String, dynamic> json) {
    return CartelaModel(
      id: json['id'] as String,
      number: json['number'] as int,
      b: _parseColumn(json['b']),
      i: _parseColumn(json['i']),
      n: _parseColumn(json['n']),
      g: _parseColumn(json['g']),
      o: _parseColumn(json['o']),
      createdAt: DateTime.parse(json['createdAt'] as String),
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
