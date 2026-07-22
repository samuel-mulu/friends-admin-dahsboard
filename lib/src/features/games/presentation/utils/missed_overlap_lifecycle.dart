import '../../data/models/game_model.dart';
import 'missed_live_preview_resolver.dart';

/// Missed-player layout lifecycle after Game A ends.
///
/// Overlap = unowned live/checking/WW exists alongside registration.
/// Handoff = Game A cleared; hold a calm "opening next" beat before showing
/// clean Game B registration (no stale "Missed · Game A" card).
enum MissedOverlapPhase {
  none,
  overlapping,
  handoff,
}

class MissedOverlapLifecycle {
  const MissedOverlapLifecycle({
    required this.phase,
    required this.blockingLiveGame,
    required this.showMissedRoundWrapper,
    required this.showHandoffHold,
  });

  final MissedOverlapPhase phase;
  final GameModel? blockingLiveGame;
  final bool showMissedRoundWrapper;
  final bool showHandoffHold;

  static const MissedOverlapLifecycle none = MissedOverlapLifecycle(
    phase: MissedOverlapPhase.none,
    blockingLiveGame: null,
    showMissedRoundWrapper: false,
    showHandoffHold: false,
  );
}

/// Pure next-step for the missed-player layout after a preview-ops poll.
MissedOverlapLifecycle resolveMissedOverlapLifecycle({
  required MissedOverlapPhase previousPhase,
  required MissedLivePreviewResolution resolution,
  required GameOperationsCurrentResponse? operations,
  required bool isGuest,
}) {
  if (resolution.showPreview && resolution.previewSession != null) {
    return MissedOverlapLifecycle(
      phase: MissedOverlapPhase.overlapping,
      blockingLiveGame: resolution.previewSession,
      showMissedRoundWrapper: !isGuest,
      showHandoffHold: false,
    );
  }

  // Preview just ended (or we are already in handoff): hold until registration
  // is clearly open for the next game without a blocking live round.
  if (previousPhase == MissedOverlapPhase.overlapping ||
      previousPhase == MissedOverlapPhase.handoff) {
    final registration = operations?.registrationOpenGame;
    final live = operations?.liveGame;
    final checking = operations?.checkingGame;
    final blockingCleared = live == null && checking == null;
    final registrationReady = registration != null &&
        registration.status == GameStatus.ready &&
        registration.canRegister;

    if (blockingCleared && registrationReady) {
      return MissedOverlapLifecycle.none;
    }

    return MissedOverlapLifecycle(
      phase: MissedOverlapPhase.handoff,
      blockingLiveGame: null,
      showMissedRoundWrapper: false,
      showHandoffHold: true,
    );
  }

  return MissedOverlapLifecycle.none;
}
