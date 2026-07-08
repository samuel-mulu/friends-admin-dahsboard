import '../../data/models/called_number_model.dart';

/// Stable dedup key for a drawn ball within a session.
String calledDrawDedupKey({
  required String sessionId,
  required int order,
  required int number,
}) {
  return '$sessionId|$order|$number';
}

String calledDrawDedupKeyFor(CalledNumberModel calledNumber) {
  return calledDrawDedupKey(
    sessionId: calledNumber.sessionId,
    order: calledNumber.order,
    number: calledNumber.number,
  );
}

List<CalledNumberModel> normalizeCalledNumbers(
  Iterable<CalledNumberModel> numbers,
) {
  final seenIds = <String>{};
  final seenOrders = <int>{};
  final unique = <CalledNumberModel>[];

  for (final number in numbers) {
    if (!seenIds.add(number.id)) {
      continue;
    }
    if (!seenOrders.add(number.order)) {
      continue;
    }
    unique.add(number);
  }

  unique.sort((left, right) => left.order.compareTo(right.order));
  return unique;
}

List<CalledNumberModel> mergeCalledNumbers({
  required Iterable<CalledNumberModel> current,
  required Iterable<CalledNumberModel> incoming,
}) {
  return normalizeCalledNumbers([...current, ...incoming]);
}

List<CalledNumberModel> pruneDeferredCalledNumbers({
  required Iterable<CalledNumberModel> committed,
  required Iterable<CalledNumberModel> deferred,
}) {
  final committedIds = committed.map((item) => item.id).toSet();
  final committedOrders = committed.map((item) => item.order).toSet();

  return normalizeCalledNumbers(
    deferred.where(
      (item) =>
          !committedIds.contains(item.id) &&
          !committedOrders.contains(item.order),
    ),
  );
}

class LiveCalledNumberReconcileResult {
  const LiveCalledNumberReconcileResult({
    required this.committed,
    required this.deferred,
    required this.accepted,
    required this.isDuplicate,
    required this.requiresCalledNumbersSync,
    required this.requiresCanonicalSync,
    this.expectedNextOrder,
    this.incomingOrder,
  });

  final List<CalledNumberModel> committed;
  final List<CalledNumberModel> deferred;
  final List<CalledNumberModel> accepted;
  final bool isDuplicate;
  final bool requiresCalledNumbersSync;
  final bool requiresCanonicalSync;
  final int? expectedNextOrder;
  final int? incomingOrder;
}

LiveCalledNumberReconcileResult applyLiveCalledNumberNotification({
  required Iterable<CalledNumberModel> committed,
  required Iterable<CalledNumberModel> deferred,
  required CalledNumberModel incoming,
}) {
  final normalizedCommitted = normalizeCalledNumbers(committed);
  final normalizedDeferred = pruneDeferredCalledNumbers(
    committed: normalizedCommitted,
    deferred: deferred,
  );

  final incomingDrawKey = calledDrawDedupKeyFor(incoming);

  final committedAtOrder = normalizedCommitted.where(
    (item) => item.order == incoming.order,
  );
  if (committedAtOrder.isNotEmpty) {
    if (committedAtOrder.any(
      (item) => calledDrawDedupKeyFor(item) == incomingDrawKey,
    )) {
      return LiveCalledNumberReconcileResult(
        committed: normalizedCommitted,
        deferred: normalizedDeferred,
        accepted: const [],
        isDuplicate: true,
        requiresCalledNumbersSync: false,
        requiresCanonicalSync: false,
      );
    }

    return LiveCalledNumberReconcileResult(
      committed: normalizedCommitted,
      deferred: normalizedDeferred,
      accepted: const [],
      isDuplicate: false,
      requiresCalledNumbersSync: false,
      requiresCanonicalSync: true,
      expectedNextOrder: normalizedCommitted.isEmpty
          ? 1
          : normalizedCommitted.last.order + 1,
      incomingOrder: incoming.order,
    );
  }

  final knownIds = {
    ...normalizedCommitted.map((item) => item.id),
    ...normalizedDeferred.map((item) => item.id),
  };
  final knownDrawKeys = {
    ...normalizedCommitted.map(calledDrawDedupKeyFor),
    ...normalizedDeferred.map(calledDrawDedupKeyFor),
  };

  if (knownIds.contains(incoming.id) ||
      knownDrawKeys.contains(incomingDrawKey)) {
    return LiveCalledNumberReconcileResult(
      committed: normalizedCommitted,
      deferred: normalizedDeferred,
      accepted: const [],
      isDuplicate: true,
      requiresCalledNumbersSync: false,
      requiresCanonicalSync: false,
    );
  }

  final conflictingAtOrder = normalizedDeferred.where(
    (item) => item.order == incoming.order,
  );
  if (conflictingAtOrder.isNotEmpty &&
      !conflictingAtOrder.any(
        (item) => calledDrawDedupKeyFor(item) == incomingDrawKey,
      )) {
    return LiveCalledNumberReconcileResult(
      committed: normalizedCommitted,
      deferred: normalizedDeferred,
      accepted: const [],
      isDuplicate: false,
      requiresCalledNumbersSync: false,
      requiresCanonicalSync: true,
      expectedNextOrder: normalizedCommitted.isEmpty
          ? 1
          : normalizedCommitted.last.order + 1,
      incomingOrder: incoming.order,
    );
  }

  final expectedNextOrder = normalizedCommitted.isEmpty
      ? 1
      : normalizedCommitted.last.order + 1;
  if (incoming.order != expectedNextOrder) {
    return LiveCalledNumberReconcileResult(
      committed: normalizedCommitted,
      deferred: mergeCalledNumbers(
        current: normalizedDeferred,
        incoming: [incoming],
      ),
      accepted: const [],
      isDuplicate: false,
      requiresCalledNumbersSync: true,
      requiresCanonicalSync: false,
      expectedNextOrder: expectedNextOrder,
      incomingOrder: incoming.order,
    );
  }

  final nextCommitted = <CalledNumberModel>[...normalizedCommitted, incoming];
  final nextDeferred = <CalledNumberModel>[...normalizedDeferred];
  final accepted = <CalledNumberModel>[incoming];

  while (true) {
    final nextExpectedOrder = nextCommitted.last.order + 1;
    final deferredIndex = nextDeferred.indexWhere(
      (item) => item.order == nextExpectedOrder,
    );
    if (deferredIndex < 0) {
      break;
    }

    final deferredNumber = nextDeferred.removeAt(deferredIndex);
    nextCommitted.add(deferredNumber);
    accepted.add(deferredNumber);
  }

  return LiveCalledNumberReconcileResult(
    committed: nextCommitted,
    deferred: nextDeferred,
    accepted: accepted,
    isDuplicate: false,
    requiresCalledNumbersSync: false,
    requiresCanonicalSync: false,
    expectedNextOrder: expectedNextOrder,
    incomingOrder: incoming.order,
  );
}

/// Whether the called-numbers strip should freeze and buffer new balls.
bool shouldPauseCalledNumbersStripForClaim({
  required bool claimStripHoldActive,
  required bool hasClaimingCartelaIds,
  required bool hasSessionCheckingCartelaNumbers,
}) {
  return claimStripHoldActive ||
      hasClaimingCartelaIds ||
      hasSessionCheckingCartelaNumbers;
}
