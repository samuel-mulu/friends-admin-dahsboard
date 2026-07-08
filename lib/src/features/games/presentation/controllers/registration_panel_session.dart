import 'dart:async';

import '../../data/models/game_cartela_model.dart';

class SelectionReservationHold {
  const SelectionReservationHold({
    required this.reservationId,
    required this.sessionId,
    required this.cartelaId,
    required this.cartelaNumber,
    required this.expiresAt,
  });

  final String reservationId;
  final String sessionId;
  final String cartelaId;
  final int cartelaNumber;
  final DateTime expiresAt;
}

/// Per-slot registration grid selection, reservation, and bulk-register state.
class RegistrationPanelSession {
  bool selectModeEnabled = false;
  bool reviewSheetOpen = false;
  final Set<String> selectedCartelaIds = <String>{};
  final Map<String, int> selectedCartelaNumbers = <String, int>{};
  final Map<String, SelectionReservationHold> selectionReservations =
      <String, SelectionReservationHold>{};
  Timer? bulkReserveDebounceTimer;
  final Set<String> pendingBulkReserveIds = <String>{};
  bool bulkReserveInFlight = false;
  int bulkReserveGeneration = 0;
  final Set<String> registeringCartelaIds = <String>{};
  final Set<String> togglingCartelaIds = <String>{};
  List<GameCartelaModel> trackedRegisteredCartelas = const [];
  String? resolvedSessionId;

  int get selectionCount => selectedCartelaIds.length;

  void dispose() {
    bulkReserveGeneration += 1;
    bulkReserveDebounceTimer?.cancel();
    bulkReserveDebounceTimer = null;
    pendingBulkReserveIds.clear();
    selectionReservations.clear();
    selectedCartelaIds.clear();
    selectedCartelaNumbers.clear();
    registeringCartelaIds.clear();
    togglingCartelaIds.clear();
  }

  void clearSelection() {
    selectedCartelaIds.clear();
    selectedCartelaNumbers.clear();
  }

  void exitSelectMode() {
    selectModeEnabled = false;
    clearSelection();
  }
}
