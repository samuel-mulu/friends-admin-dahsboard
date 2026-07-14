import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for tracking active registered cartelas and live-game back handling.
class ActiveRegisteredCartelasState {
  const ActiveRegisteredCartelasState({
    this.activeSessionId,
    this.registeredCartelaCount = 0,
    this.requiresLeaveConfirmation = false,
  });

  final String? activeSessionId;
  final int registeredCartelaCount;
  final bool requiresLeaveConfirmation;

  bool get hasActiveRegisteredCartelas =>
      activeSessionId != null && registeredCartelaCount > 0;

  bool get shouldConfirmLiveGameBack =>
      requiresLeaveConfirmation || hasActiveRegisteredCartelas;

  ActiveRegisteredCartelasState copyWith({
    String? activeSessionId,
    int? registeredCartelaCount,
    bool? requiresLeaveConfirmation,
  }) {
    return ActiveRegisteredCartelasState(
      activeSessionId: activeSessionId ?? this.activeSessionId,
      registeredCartelaCount:
          registeredCartelaCount ?? this.registeredCartelaCount,
      requiresLeaveConfirmation:
          requiresLeaveConfirmation ?? this.requiresLeaveConfirmation,
    );
  }
}

/// Notifier for managing active registered cartelas state
class HasActiveRegisteredCartelasNotifier
    extends Notifier<ActiveRegisteredCartelasState> {
  @override
  ActiveRegisteredCartelasState build() {
    return const ActiveRegisteredCartelasState();
  }

  /// Update the active session and cartela count
  /// Call this when:
  /// - User joins a live game session
  /// - User registers/unregisters cartelas
  /// - User leaves a session (clear by passing null sessionId)
  void updateSessionState(
    String? sessionId,
    int cartelaCount, {
    bool requiresLeaveConfirmation = false,
  }) {
    state = state.copyWith(
      activeSessionId: sessionId,
      registeredCartelaCount: cartelaCount,
      requiresLeaveConfirmation: requiresLeaveConfirmation,
    );
  }

  /// Clear the active session state
  /// Call this when user leaves live game or session ends
  void clear() {
    state = const ActiveRegisteredCartelasState();
  }

  /// Update just the cartela count (when cartelas are registered/unregistered)
  void updateCartelaCount(int count) {
    state = state.copyWith(registeredCartelaCount: count);
  }
}

/// Provider for checking if user has active registered cartelas in current session
final hasActiveRegisteredCartelasProvider = NotifierProvider<
    HasActiveRegisteredCartelasNotifier, ActiveRegisteredCartelasState>(
  HasActiveRegisteredCartelasNotifier.new,
);

/// Convenience provider for boolean check
final hasActiveRegisteredCartelas = Provider<bool>((ref) {
  final state = ref.watch(hasActiveRegisteredCartelasProvider);
  return state.hasActiveRegisteredCartelas;
});
