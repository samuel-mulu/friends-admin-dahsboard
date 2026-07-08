import '../data/models/cartela_model.dart';

/// In-memory cache of cartela boards for instant registration preview.
class CartelaBoardPreviewCache {
  CartelaBoardPreviewCache._();

  static final Map<String, CartelaModel> _boards = {};

  static CartelaModel? get(String cartelaId) => _boards[cartelaId];

  static CartelaModel? findByNumber(int number) {
    for (final cartela in _boards.values) {
      if (cartela.number == number) {
        return cartela;
      }
    }
    return null;
  }

  static void put(CartelaModel cartela) {
    if (!cartela.hasBoardValues) {
      return;
    }

    _boards[cartela.id] = cartela;
  }
}
