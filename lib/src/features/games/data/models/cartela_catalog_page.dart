import 'cartela_model.dart';

class CartelaCatalogPage {
  const CartelaCatalogPage({
    required this.items,
    this.nextCursor,
    this.total,
  });

  final List<CartelaModel> items;
  final String? nextCursor;
  final int? total;

  factory CartelaCatalogPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return CartelaCatalogPage(
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(CartelaModel.fromJson)
                .toList(growable: false)
          : const [],
      nextCursor: json['nextCursor'] as String?,
      total: json['total'] as int?,
    );
  }
}
