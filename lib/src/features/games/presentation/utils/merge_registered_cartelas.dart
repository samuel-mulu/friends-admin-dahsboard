import '../../data/models/game_cartela_model.dart';

/// Merges newly registered cartelas into the on-screen list for one session.
///
/// When [sessionId] is set, only cartelas whose [GameCartelaModel.gameId]
/// matches that session are kept — late responses from a prior round are dropped.
List<GameCartelaModel> mergeRegisteredCartelas({
  required List<GameCartelaModel> current,
  required List<GameCartelaModel> incoming,
  required String? sessionId,
}) {
  bool belongsToSession(GameCartelaModel cartela) {
    if (sessionId == null || sessionId.isEmpty) {
      return true;
    }
    if (cartela.gameId.isEmpty) {
      return true;
    }
    return cartela.gameId == sessionId;
  }

  final byId = <String, GameCartelaModel>{
    for (final cartela in current.where(belongsToSession)) cartela.id: cartela,
  };

  for (final cartela in incoming.where(belongsToSession)) {
    byId[cartela.id] = cartela;
  }

  final list = byId.values.toList(growable: false);
  list.sort(
    (left, right) => left.cartela.number.compareTo(right.cartela.number),
  );
  return list;
}
