class CalledNumberMergeResult {
  const CalledNumberMergeResult({
    required this.orders,
    required this.rejectedRollback,
  });

  final List<int> orders;
  final bool rejectedRollback;
}

/// Same-session called-number orders must not shrink behind local/socket truth.
CalledNumberMergeResult mergeCalledNumbersMonotonic({
  required String? sessionId,
  required String? localSessionId,
  required List<int> localOrders,
  required List<int> incomingOrders,
  required bool preferIncomingIfNewerSocket,
  int? socketMaxOrder,
  int? incomingMaxOrder,
}) {
  if (sessionId != localSessionId) {
    return CalledNumberMergeResult(
      orders: List<int>.from(incomingOrders),
      rejectedRollback: false,
    );
  }

  final localMax = localOrders.isEmpty
      ? 0
      : localOrders.reduce((a, b) => a > b ? a : b);
  final resolvedIncomingMax = incomingMaxOrder ??
      (incomingOrders.isEmpty
          ? 0
          : incomingOrders.reduce((a, b) => a > b ? a : b));
  final socketMax = socketMaxOrder ?? localMax;

  if (resolvedIncomingMax < localMax ||
      (preferIncomingIfNewerSocket && socketMax > resolvedIncomingMax)) {
    return CalledNumberMergeResult(
      orders: List<int>.from(localOrders),
      rejectedRollback: true,
    );
  }

  return CalledNumberMergeResult(
    orders: List<int>.from(incomingOrders),
    rejectedRollback: false,
  );
}
