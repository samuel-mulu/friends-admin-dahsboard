import '../data/models/game_cartela_model.dart';
import '../data/models/game_model.dart';

/// A finished game session the current player joined with at least one cartela.
class AttendedGameHistoryEntry {
  const AttendedGameHistoryEntry({
    required this.game,
    required this.myCartelas,
  });

  final GameModel game;
  final List<GameCartelaModel> myCartelas;

  bool get hasWinningCartela => myCartelas.any((cartela) => cartela.isWinner);

  List<GameCartelaModel> get sortedCartelas {
    return List<GameCartelaModel>.from(myCartelas)
      ..sort((left, right) => left.cartela.number.compareTo(right.cartela.number));
  }

  factory AttendedGameHistoryEntry.fromSessionJson(Map<String, dynamic> json) {
    final cartelasJson = json['myCartelas'];
    final cartelas = cartelasJson is List
        ? cartelasJson
              .whereType<Map<String, dynamic>>()
              .map(GameCartelaModel.fromJson)
              .toList(growable: false)
        : const <GameCartelaModel>[];

    return AttendedGameHistoryEntry(
      game: GameModel.fromSessionJson(json),
      myCartelas: cartelas,
    );
  }
}
