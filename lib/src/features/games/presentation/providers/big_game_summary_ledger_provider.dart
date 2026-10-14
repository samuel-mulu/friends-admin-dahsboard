import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/big_game_summary_ledger_storage.dart';

/// In-memory + SharedPreferences dismissal ledger for Big Game summaries.
///
/// [markDismissed] updates memory immediately so pin/retention never resurrect
/// a dismissed summary while prefs I/O is still in flight.
class BigGameSummaryLedgerState {
  const BigGameSummaryLedgerState({
    required this.ready,
    required this.dismissedKeys,
  });

  final bool ready;
  final Set<String> dismissedKeys;

  static const notReady = BigGameSummaryLedgerState(
    ready: false,
    dismissedKeys: {},
  );

  bool isDismissed({
    required String userId,
    required String slotId,
    required String sessionId,
  }) {
    return dismissedKeys.contains(
      BigGameSummaryLedgerStorage.entryKey(
        userId: userId,
        slotId: slotId,
        sessionId: sessionId,
      ),
    );
  }

  BigGameSummaryLedgerState copyWith({
    bool? ready,
    Set<String>? dismissedKeys,
  }) {
    return BigGameSummaryLedgerState(
      ready: ready ?? this.ready,
      dismissedKeys: dismissedKeys ?? this.dismissedKeys,
    );
  }
}

final bigGameSummaryLedgerProvider =
    NotifierProvider<BigGameSummaryLedgerNotifier, BigGameSummaryLedgerState>(
      BigGameSummaryLedgerNotifier.new,
    );

class BigGameSummaryLedgerNotifier extends Notifier<BigGameSummaryLedgerState> {
  BigGameSummaryLedgerStorage? _storage;
  Future<void>? _loadFuture;

  @override
  BigGameSummaryLedgerState build() {
    ref.watch(authControllerProvider.select((s) => s.session?.user.id));
    unawaited(_ensureLoaded());
    return BigGameSummaryLedgerState.notReady;
  }

  Future<void> _ensureLoaded() {
    final existing = _loadFuture;
    if (existing != null) {
      return existing;
    }
    final future = _load();
    _loadFuture = future;
    return future.whenComplete(() {
      if (identical(_loadFuture, future)) {
        _loadFuture = null;
      }
    });
  }

  Future<void> _load() async {
    final userId = ref.read(authControllerProvider).session?.user.id;
    if (userId == null) {
      state = const BigGameSummaryLedgerState(ready: true, dismissedKeys: {});
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted) {
        return;
      }
      final storage = BigGameSummaryLedgerStorage(prefs);
      _storage = storage;

      // Merge prefs into memory; never drop keys already marked dismissed
      // before this load completed (async race protection).
      final resolved = <String>{...state.dismissedKeys};
      final index =
          prefs.getStringList(BigGameSummaryLedgerStorage.indexKey(userId)) ??
          const <String>[];
      for (final key in index) {
        final raw = prefs.getString(key);
        if (raw == null || raw.isEmpty) {
          continue;
        }
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic> && decoded['dismissed'] == true) {
            resolved.add(key);
          }
        } catch (_) {}
      }

      if (!ref.mounted) {
        return;
      }
      state = BigGameSummaryLedgerState(ready: true, dismissedKeys: resolved);
      unawaited(storage.pruneBounded(userId: userId, now: DateTime.now()));
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = BigGameSummaryLedgerState(
        ready: true,
        dismissedKeys: {...state.dismissedKeys},
      );
    }
  }

  bool isDismissed({
    required String slotId,
    required String sessionId,
  }) {
    final userId = ref.read(authControllerProvider).session?.user.id;
    if (userId == null) {
      return false;
    }
    return state.isDismissed(
      userId: userId,
      slotId: slotId,
      sessionId: sessionId,
    );
  }

  /// Immediate memory update, then async prefs. Never clears a dismissed key
  /// when a slow load completes afterward.
  void markDismissed({
    required String slotId,
    required String sessionId,
  }) {
    final userId = ref.read(authControllerProvider).session?.user.id;
    if (userId == null || slotId.isEmpty || sessionId.isEmpty) {
      return;
    }
    final key = BigGameSummaryLedgerStorage.entryKey(
      userId: userId,
      slotId: slotId,
      sessionId: sessionId,
    );
    if (!state.dismissedKeys.contains(key)) {
      state = state.copyWith(
        ready: true,
        dismissedKeys: {...state.dismissedKeys, key},
      );
    } else if (!state.ready) {
      state = state.copyWith(ready: true);
    }
    unawaited(
      _persistDismissed(
        userId: userId,
        slotId: slotId,
        sessionId: sessionId,
      ),
    );
  }

  Future<void> _persistDismissed({
    required String userId,
    required String slotId,
    required String sessionId,
  }) async {
    try {
      final storage =
          _storage ??
          BigGameSummaryLedgerStorage(await SharedPreferences.getInstance());
      _storage ??= storage;
      await storage.markDismissed(
        userId: userId,
        slotId: slotId,
        sessionId: sessionId,
      );
    } catch (_) {}
  }
}
