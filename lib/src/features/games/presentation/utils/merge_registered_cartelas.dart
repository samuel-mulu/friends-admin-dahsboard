import '../../data/models/bingo_claim_result.dart';
import '../../data/models/game_cartela_model.dart';

bool isTerminalCartelaStatus(GameCartelaStatus status) {
  return status == GameCartelaStatus.blocked ||
      status == GameCartelaStatus.winner ||
      status == GameCartelaStatus.cancelled;
}

/// Prefer durable terminal cartela status over a stale REGISTERED snapshot.
///
/// Rules:
/// - Incoming BLOCKED / WINNER / CANCELLED always replaces local REGISTERED.
/// - Local BLOCKED / CANCELLED is never downgraded by REGISTERED.
/// - Local WINNER is not downgraded by a stale REGISTERED snapshot.
///   Legitimate chain WINNER → REGISTERED is applied afterward by
///   [normalizeChainPlayableCartelas] only when
///   [hasAuthoritativeChainRoundAdvance] proves a newer round (pause metadata
///   or prior [GameModel.roundResults]), not by PLAYING alone or blind merge.
GameCartelaModel preferAuthoritativeCartela({
  required GameCartelaModel? current,
  required GameCartelaModel incoming,
}) {
  if (current == null) {
    return incoming;
  }
  if (isTerminalCartelaStatus(incoming.status)) {
    return incoming;
  }
  if (isTerminalCartelaStatus(current.status) &&
      incoming.status == GameCartelaStatus.registered) {
    return current;
  }
  return incoming;
}

/// Reconcile a full remote `/my-cartelas` list against the on-screen list.
List<GameCartelaModel> reconcileCartelaSnapshot({
  required List<GameCartelaModel> current,
  required List<GameCartelaModel> incoming,
}) {
  if (incoming.isEmpty) {
    return incoming;
  }
  final currentById = <String, GameCartelaModel>{
    for (final cartela in current) cartela.id: cartela,
  };
  return [
    for (final cartela in incoming)
      preferAuthoritativeCartela(
        current: currentById[cartela.id],
        incoming: cartela,
      ),
  ];
}

/// Patch one cartela to a terminal status (BLOCKED / WINNER / CANCELLED).
List<GameCartelaModel> patchCartelaTerminalStatus({
  required List<GameCartelaModel> cartelas,
  required String gameCartelaId,
  required GameCartelaStatus status,
  DateTime? now,
}) {
  if (!isTerminalCartelaStatus(status)) {
    return cartelas;
  }
  return [
    for (final cartela in cartelas)
      if (cartela.id != gameCartelaId)
        cartela
      else
        cartela.copyWith(
          status: status,
          isWinner: status == GameCartelaStatus.winner,
          blockedAt: status == GameCartelaStatus.blocked
              ? (cartela.blockedAt ?? now ?? DateTime.now())
              : null,
        ),
  ];
}

/// Map claim terminal outcome to cartela status. Null means no cartela
/// mutation (technical FAILED keeps the board playable when still REGISTERED).
GameCartelaStatus? cartelaStatusForClaimOutcome({
  required BingoClaimStatus status,
  GameCartelaStatus? reportedCartelaStatus,
}) {
  switch (status) {
    case BingoClaimStatus.valid:
      return GameCartelaStatus.winner;
    case BingoClaimStatus.invalid:
      return GameCartelaStatus.blocked;
    case BingoClaimStatus.failed:
    case BingoClaimStatus.alreadyResolved:
      if (reportedCartelaStatus == GameCartelaStatus.blocked ||
          reportedCartelaStatus == GameCartelaStatus.winner ||
          reportedCartelaStatus == GameCartelaStatus.cancelled) {
        return reportedCartelaStatus;
      }
      return null;
    case BingoClaimStatus.pending:
    case BingoClaimStatus.checking:
      return null;
  }
}

/// Merges newly registered cartelas into the on-screen list for one session.
///
/// When [sessionId] is set, only cartelas whose [GameCartelaModel.gameId]
/// matches that session are kept — late responses from a prior round are dropped.
/// Terminal statuses are preserved against stale REGISTERED overwrites.
List<GameCartelaModel> mergeRegisteredCartelas({
  required List<GameCartelaModel> current,
  required List<GameCartelaModel> incoming,
  required String? sessionId,
}) {
  bool belongsToSession(GameCartelaModel cartela) {
    if (sessionId == null) {
      return true;
    }
    if (cartela.gameId.isEmpty) {
      return false;
    }
    return cartela.gameId == sessionId;
  }

  final byId = <String, GameCartelaModel>{
    for (final cartela in current.where(belongsToSession)) cartela.id: cartela,
  };

  for (final cartela in incoming.where(belongsToSession)) {
    byId[cartela.id] = preferAuthoritativeCartela(
      current: byId[cartela.id],
      incoming: cartela,
    );
  }

  return byId.values.toList(growable: false);
}
