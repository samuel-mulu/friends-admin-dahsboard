import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';

/// Applies a saved display order to [cartelas]. Unknown ids are appended at the
/// end in cartela-number order; stale ids in [orderIds] are ignored.
List<GameCartelaModel> applyCartelaDisplayOrder({
  required List<GameCartelaModel> cartelas,
  required List<String> orderIds,
}) {
  if (cartelas.isEmpty || orderIds.isEmpty) {
    return cartelas;
  }

  final byId = <String, GameCartelaModel>{
    for (final cartela in cartelas) cartela.id: cartela,
  };
  final ordered = <GameCartelaModel>[];

  for (final id in orderIds) {
    final cartela = byId.remove(id);
    if (cartela != null) {
      ordered.add(cartela);
    }
  }

  final remaining = byId.values.toList(growable: false)
    ..sort((left, right) => left.cartela.number.compareTo(right.cartela.number));
  ordered.addAll(remaining);

  return ordered;
}

/// Reorders [cartelas] by moving the item at [fromIndex] to [toIndex].
List<String> reorderCartelaDisplayOrderIds({
  required List<GameCartelaModel> cartelas,
  required int fromIndex,
  required int toIndex,
}) {
  final ids = cartelas.map((cartela) => cartela.id).toList(growable: true);
  if (fromIndex < 0 ||
      toIndex < 0 ||
      fromIndex >= ids.length ||
      toIndex >= ids.length ||
      fromIndex == toIndex) {
    return ids;
  }

  final id = ids.removeAt(fromIndex);
  ids.insert(toIndex, id);
  return ids;
}

/// Returns true when the sequence of cartela ids in [nextOrder] differs from
/// [previousOrder].
bool hasCartelaDisplayOrderChanged({
  required List<GameCartelaModel>? previousOrder,
  required List<GameCartelaModel> nextOrder,
}) {
  if (previousOrder == null) {
    return nextOrder.isNotEmpty;
  }
  if (previousOrder.length != nextOrder.length) {
    return true;
  }
  for (var index = 0; index < nextOrder.length; index++) {
    if (previousOrder[index].id != nextOrder[index].id) {
      return true;
    }
  }
  return false;
}
