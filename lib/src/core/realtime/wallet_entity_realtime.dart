import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-level bus for deposit/withdrawal status events from the socket.
enum WalletEntityKind { deposit, withdrawal }

@immutable
class WalletEntityUpdate {
  const WalletEntityUpdate({
    required this.kind,
    required this.id,
    required this.status,
    this.amount,
    this.transactionRef,
    this.message,
    this.provider,
    required this.receivedAt,
  });

  final WalletEntityKind kind;
  final String id;
  final String status;
  final String? amount;
  final String? transactionRef;
  final String? message;
  final String? provider;
  final DateTime receivedAt;

  bool get isApproved =>
      status == 'APPROVED' || status == 'PAID';

  bool get isRejected => status == 'REJECTED';

  bool get isTerminal => isApproved || isRejected;
}

@immutable
class WalletEntityRealtimeState {
  const WalletEntityRealtimeState({
    this.byId = const {},
    this.byTransactionRef = const {},
    this.revision = 0,
    this.lastUpdate,
  });

  final Map<String, WalletEntityUpdate> byId;
  final Map<String, WalletEntityUpdate> byTransactionRef;
  final int revision;
  final WalletEntityUpdate? lastUpdate;

  WalletEntityUpdate? find({
    required WalletEntityKind kind,
    String? id,
    String? transactionRef,
  }) {
    if (id != null && id.isNotEmpty) {
      final byIdMatch = byId[id];
      if (byIdMatch != null && byIdMatch.kind == kind) {
        return byIdMatch;
      }
    }
    if (transactionRef != null && transactionRef.isNotEmpty) {
      final byRefMatch = byTransactionRef['$kind:$transactionRef'];
      if (byRefMatch != null) {
        return byRefMatch;
      }
    }
    return null;
  }

  WalletEntityRealtimeState copyWith({
    Map<String, WalletEntityUpdate>? byId,
    Map<String, WalletEntityUpdate>? byTransactionRef,
    int? revision,
    WalletEntityUpdate? lastUpdate,
  }) {
    return WalletEntityRealtimeState(
      byId: byId ?? this.byId,
      byTransactionRef: byTransactionRef ?? this.byTransactionRef,
      revision: revision ?? this.revision,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

class WalletEntityRealtimeNotifier
    extends Notifier<WalletEntityRealtimeState> {
  @override
  WalletEntityRealtimeState build() => const WalletEntityRealtimeState();

  void applyDeposit(Map<String, dynamic> payload) {
    _apply(
      kind: WalletEntityKind.deposit,
      payload: payload,
      messageKey: 'rejectionReason',
    );
  }

  void applyWithdrawal(Map<String, dynamic> payload) {
    _apply(
      kind: WalletEntityKind.withdrawal,
      payload: payload,
      messageKey: 'adminNote',
    );
  }

  void clear(String id) {
    if (!state.byId.containsKey(id)) {
      return;
    }
    final nextById = Map<String, WalletEntityUpdate>.from(state.byId)
      ..remove(id);
    final nextByRef = Map<String, WalletEntityUpdate>.from(
      state.byTransactionRef,
    )..removeWhere((_, value) => value.id == id);
    state = state.copyWith(
      byId: nextById,
      byTransactionRef: nextByRef,
      revision: state.revision + 1,
    );
  }

  void _apply({
    required WalletEntityKind kind,
    required Map<String, dynamic> payload,
    required String messageKey,
  }) {
    final id = payload['id']?.toString().trim() ?? '';
    final status = payload['status']?.toString().trim().toUpperCase() ?? '';
    if (id.isEmpty || status.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[WalletRealtime] Ignoring $kind update missing id/status: $payload',
        );
      }
      return;
    }

    final transactionRef = payload['transactionRef']?.toString().trim();
    final update = WalletEntityUpdate(
      kind: kind,
      id: id,
      status: status,
      amount: payload['amount']?.toString(),
      transactionRef: transactionRef?.isEmpty == true ? null : transactionRef,
      message: payload[messageKey]?.toString(),
      provider: payload['provider']?.toString(),
      receivedAt: DateTime.now(),
    );

    final nextById = Map<String, WalletEntityUpdate>.from(state.byId)
      ..[id] = update;
    final nextByRef = Map<String, WalletEntityUpdate>.from(
      state.byTransactionRef,
    );
    if (update.transactionRef != null) {
      nextByRef['${update.kind}:${update.transactionRef}'] = update;
    }

    if (kDebugMode) {
      debugPrint(
        '[WalletRealtime] $kind ${update.id} → ${update.status}',
      );
    }

    state = state.copyWith(
      byId: nextById,
      byTransactionRef: nextByRef,
      revision: state.revision + 1,
      lastUpdate: update,
    );
  }
}

final walletEntityRealtimeProvider =
    NotifierProvider<WalletEntityRealtimeNotifier, WalletEntityRealtimeState>(
      WalletEntityRealtimeNotifier.new,
    );
