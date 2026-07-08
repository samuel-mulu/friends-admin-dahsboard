import '../../data/models/game_model.dart';
import '../../domain/live_connection_status.dart';
import '../utils/live_presentation_phase.dart';

/// Snapshot of live-screen inputs needed to tick next-ball / winner-window UI.
class LiveCountdownTickContext {
  const LiveCountdownTickContext({
    required this.game,
    required this.presentationPhase,
    required this.isAnyClaimChecking,
    required this.isSyncingCalledNumbers,
    required this.autoCallActive,
    required this.allBallsDrawn,
    required this.connectionStatus,
    required this.socketAutoCallEnabled,
    required this.winnerWindowExpired,
    required this.effectiveWinnerWindowEndsAt,
    required this.shouldRunWinnerWindowTicker,
    this.highestKnownCalledOrder = 0,
  });

  final GameModel? game;
  final LivePresentationPhase presentationPhase;
  final bool isAnyClaimChecking;
  final bool isSyncingCalledNumbers;
  final bool autoCallActive;
  final bool allBallsDrawn;
  final LiveConnectionStatus connectionStatus;
  final bool? socketAutoCallEnabled;
  final bool winnerWindowExpired;
  final DateTime? effectiveWinnerWindowEndsAt;
  final bool shouldRunWinnerWindowTicker;
  final int highestKnownCalledOrder;
}
