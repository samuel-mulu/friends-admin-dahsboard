import '../../data/models/game_model.dart';

/// Presentation phase for the missed-player read-only live preview.
enum MissedPreviewPhase {
  none,
  livePlaying,
  checking,
  winnerWindow,
}

/// Pure result of [resolveMissedLivePreview].
class MissedLivePreviewResolution {
  const MissedLivePreviewResolution({
    required this.previewSession,
    required this.phase,
    required this.showPreview,
  });

  final GameModel? previewSession;
  final MissedPreviewPhase phase;
  final bool showPreview;

  static const MissedLivePreviewResolution none = MissedLivePreviewResolution(
    previewSession: null,
    phase: MissedPreviewPhase.none,
    showPreview: false,
  );
}

/// Whether Player 2 should see a read-only preview of an unowned live round.
///
/// Canonical operations are authoritative. Priority:
/// winner-window liveGame → checkingGame → playing liveGame.
///
/// When live/checking clear, returns [MissedLivePreviewResolution.none]
/// immediately — no stored previous session.
MissedLivePreviewResolution resolveMissedLivePreview({
  required GameOperationsCurrentResponse? operations,
  required bool Function(String? sessionId) ownsSession,
}) {
  if (operations == null) {
    return MissedLivePreviewResolution.none;
  }

  final live = operations.liveGame;
  if (live != null &&
      live.status == GameStatus.winnerWindow &&
      !ownsSession(live.sessionId)) {
    return MissedLivePreviewResolution(
      previewSession: live,
      phase: MissedPreviewPhase.winnerWindow,
      showPreview: true,
    );
  }

  final checking = operations.checkingGame;
  if (checking != null && !ownsSession(checking.sessionId)) {
    return MissedLivePreviewResolution(
      previewSession: checking,
      phase: MissedPreviewPhase.checking,
      showPreview: true,
    );
  }

  if (live != null &&
      live.status == GameStatus.playing &&
      !ownsSession(live.sessionId)) {
    return MissedLivePreviewResolution(
      previewSession: live,
      phase: MissedPreviewPhase.livePlaying,
      showPreview: true,
    );
  }

  return MissedLivePreviewResolution.none;
}
