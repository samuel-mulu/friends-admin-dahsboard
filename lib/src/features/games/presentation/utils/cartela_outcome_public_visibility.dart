import '../../data/models/game_cartela_model.dart';
import '../../data/models/game_model.dart';

List<int> _sortedUnique(Iterable<int> values) {
  return values.toSet().toList(growable: false)..sort();
}

/// Blocked cartela numbers shown in the called-numbers strip.
///
/// Only the current player's blocked cartelas are ever shown.
List<int> blockedCartelaNumbersForStrip({
  required List<GameCartelaModel> myCartelas,
}) {
  return _sortedUnique(
    myCartelas
        .where((cartela) => cartela.status == GameCartelaStatus.blocked)
        .map((cartela) => cartela.cartela.number),
  );
}

/// Winner cartela numbers shown in the called-numbers strip.
///
/// During session-wide outcome phases, all session winners are public.
/// Outside those phases, only the current player's winners are shown.
List<int> winnerCartelaNumbersForStrip({
  required bool useSessionWideOutcomeChips,
  required List<int> sessionWinnerCartelaNumbers,
  required List<GameCartelaModel> myCartelas,
}) {
  final ownWinners = myCartelas
      .where(
        (cartela) =>
            cartela.isWinner || cartela.status == GameCartelaStatus.winner,
      )
      .map((cartela) => cartela.cartela.number);

  if (useSessionWideOutcomeChips) {
    return _sortedUnique([
      ...sessionWinnerCartelaNumbers,
      ...ownWinners,
    ]);
  }

  return _sortedUnique(ownWinners);
}

/// Checking cartela numbers shown in the called-numbers strip.
///
/// Only the current player's in-flight claims are shown.
List<int> checkingCartelaNumbersForStrip({
  required Set<String> claimingCartelaIds,
  required List<GameCartelaModel> myCartelas,
}) {
  if (claimingCartelaIds.isEmpty) {
    return const [];
  }

  return _sortedUnique(
    myCartelas
        .where((cartela) => claimingCartelaIds.contains(cartela.id))
        .map((cartela) => cartela.cartela.number),
  );
}

/// Whether the called-numbers strip should be visible to everyone watching
/// the live round, including guests and players without cartelas.
bool shouldShowPublicCalledNumbersPanel({
  required GameModel? game,
  required bool showsInlinePlayCartelas,
}) {
  return game != null && !game.isRegistrationOpen && showsInlinePlayCartelas;
}
