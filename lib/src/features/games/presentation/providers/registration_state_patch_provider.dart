import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/game_model.dart';
import '../../domain/registration_state_patch.dart';

// Temporary debug logging for ghost reserved bug investigation
void _patchDebugLog(String message) {
  if (kDebugMode) {
    debugPrint('[bulk_debug] $message');
  }
}

/// Confirmed realtime deltas keyed by [gameSessionId].
///
/// Pending UI state (selecting, modal preparing, etc.) must not be stored here.
class RegistrationStatePatchState {
  const RegistrationStatePatchState({
    this.patches = const {},
    this.removedCartelaIds = const {},
  });

  final Map<String, RegisteredCartelaSummary> patches;
  final Set<String> removedCartelaIds;
}

class RegistrationStatePatchNotifier
    extends Notifier<Map<String, RegistrationStatePatchState>> {
  @override
  Map<String, RegistrationStatePatchState> build() {
    return const {};
  }

  RegistrationStatePatchState stateFor(String sessionId) {
    return state[sessionId] ?? const RegistrationStatePatchState();
  }

  /// Applies confirmed socket/API cartela changes for [sessionId].
  void applyConfirmedChanges(
    String sessionId,
    List<RegistrationCartelaChange> changes,
  ) {
    applyChanges(sessionId, changes);
  }

  void applyChanges(
    String sessionId,
    List<RegistrationCartelaChange> changes,
  ) {
    if (sessionId.isEmpty || changes.isEmpty) {
      return;
    }

    final current = stateFor(sessionId);
    final nextPatches = Map<String, RegisteredCartelaSummary>.from(
      current.patches,
    );
    final nextRemoved = Set<String>.from(current.removedCartelaIds);

    for (final change in changes) {
      final summary = change.toSummary();
      if (summary == null) {
        // Debug log #9: Patch applied - AVAILABLE (remove)
        _patchDebugLog(
          'patch_apply cartela=${change.cartelaNumber} state=AVAILABLE session=$sessionId source=local',
        );
        nextPatches.remove(change.cartelaId);
        nextRemoved.add(change.cartelaId);
        continue;
      }

      // Debug log #9: Patch applied
      _patchDebugLog(
        'patch_apply cartela=${change.cartelaNumber} state=${change.owner} session=$sessionId source=local',
      );

      nextRemoved.remove(change.cartelaId);
      final existing = nextPatches[change.cartelaId];
      nextPatches[change.cartelaId] = existing == null
          ? summary
          : _preferHigherPrioritySummary(existing, summary);
    }

    state = {
      ...state,
      sessionId: RegistrationStatePatchState(
        patches: nextPatches,
        removedCartelaIds: nextRemoved,
      ),
    };
  }

  RegisteredCartelaSummary _preferHigherPrioritySummary(
    RegisteredCartelaSummary existing,
    RegisteredCartelaSummary incoming,
  ) {
    final existingRank = _ownerPriority(existing.owner);
    final incomingRank = _ownerPriority(incoming.owner);
    return incomingRank >= existingRank ? incoming : existing;
  }

  int _ownerPriority(String owner) {
    return switch (owner) {
      'ME' || 'OTHER' => 3,
      'RESERVED_ME' || 'RESERVED_OTHER' => 2,
      _ => 0,
    };
  }

  void onSnapshotLoaded(String sessionId) {
    clear(sessionId);
  }

  void clear(String sessionId) {
    if (!state.containsKey(sessionId)) {
      return;
    }

    final next = Map<String, RegistrationStatePatchState>.from(state);
    next.remove(sessionId);
    state = next;
  }

  void clearExcept(Set<String> activeSessionIds) {
    if (state.keys.every(activeSessionIds.contains)) {
      return;
    }

    state = {
      for (final entry in state.entries)
        if (activeSessionIds.contains(entry.key)) entry.key: entry.value,
    };
  }
}

final registrationStatePatchProvider =
    NotifierProvider<RegistrationStatePatchNotifier,
        Map<String, RegistrationStatePatchState>>(
  RegistrationStatePatchNotifier.new,
);

RegistrationStatePatchState registrationStatePatchForSession(
  Map<String, RegistrationStatePatchState> allPatches,
  String sessionId,
) {
  if (sessionId.isEmpty) {
    return const RegistrationStatePatchState();
  }
  return allPatches[sessionId] ?? const RegistrationStatePatchState();
}
