import 'package:flutter/foundation.dart';
import '../../data/models/chain_round_plan_model.dart';
import '../../data/models/game_model.dart';

/// Coordinates Chain Game round breaks, latched pause state during socket refetching,
/// countdown ticker listeners, and caching of the multi-round ChainRoundPlan.
class LiveChainGameCoordinator {
  DateTime? _latchedChainRoundPausedUntil;
  String? _latchedChainPauseSessionId;

  ChainRoundPlan? _chainRoundPlan;
  String? _chainRoundPlanKey;
  bool _chainRoundPlanInFlight = false;

  /// Live [GameModel.roundPausedUntil] for winner dialogs and delay tickers.
  final ValueNotifier<DateTime?> pauseEndsAtListenable =
      ValueNotifier<DateTime?>(null);

  /// Round 2+: Bingo stays off until called count exceeds this. Fallback for
  /// when session data cannot yet prove a new ball (see
  /// `isChainBingoArmedAfterNewBall`).
  int? chainBingoArmedAfterCalledCount;

  /// Round the [chainBingoArmedAfterCalledCount] threshold belongs to. The
  /// threshold is recorded once per round (at round finish, or at resume if
  /// the finish was missed) and never moved forward, so a late resume event
  /// cannot re-lock Bingo after the round's first new ball already arrived.
  int? chainBingoArmedForRoundIndex;

  /// Records the fallback threshold for [roundIndex] unless one already exists.
  void armBingoForRound({required int roundIndex, required int calledCount}) {
    if (chainBingoArmedForRoundIndex == roundIndex &&
        chainBingoArmedAfterCalledCount != null) {
      return;
    }
    chainBingoArmedForRoundIndex = roundIndex;
    chainBingoArmedAfterCalledCount = calledCount;
  }

  void clearBingoArming() {
    chainBingoArmedForRoundIndex = null;
    chainBingoArmedAfterCalledCount = null;
  }

  DateTime? get latchedPausedUntil => _latchedChainRoundPausedUntil;
  String? get latchedSessionId => _latchedChainPauseSessionId;

  ChainRoundPlan? get chainRoundPlan => _chainRoundPlan;
  String? get chainRoundPlanKey => _chainRoundPlanKey;
  bool get isPlanInFlight => _chainRoundPlanInFlight;

  bool get isPaused => pauseEndsAtListenable.value != null;

  void syncPauseDeadline(DateTime? deadline) {
    pauseEndsAtListenable.value = deadline;
  }

  void syncPauseEndsAt(DateTime? endsAt) {
    if (pauseEndsAtListenable.value != endsAt) {
      pauseEndsAtListenable.value = endsAt;
    }
  }

  void clearPause() {
    pauseEndsAtListenable.value = null;
  }

  int remainingSeconds(DateTime serverNow) {
    final deadline = pauseEndsAtListenable.value;
    if (deadline == null) return 0;
    final diff = deadline.difference(serverNow).inSeconds;
    return diff > 0 ? diff : 0;
  }

  void syncPauseLatch({
    required bool isChainGame,
    required String? sessionId,
    required DateTime? roundPausedUntil,
  }) {
    if (isChainGame && roundPausedUntil != null && sessionId != null) {
      _latchedChainRoundPausedUntil = roundPausedUntil;
      _latchedChainPauseSessionId = sessionId;
    }
  }

  void clearPauseLatch() {
    _latchedChainRoundPausedUntil = null;
    _latchedChainPauseSessionId = null;
  }

  bool isRefetchLatchActive({
    required bool canonicalRefetchInFlight,
    required String? currentSessionId,
    required DateTime now,
  }) {
    if (!canonicalRefetchInFlight) {
      return false;
    }
    final latched = _latchedChainRoundPausedUntil;
    if (latched == null || currentSessionId != _latchedChainPauseSessionId) {
      return false;
    }
    return now.isBefore(latched);
  }

  void setPlan(ChainRoundPlan plan, {required String key}) {
    _chainRoundPlan = plan;
    _chainRoundPlanKey = key;
    _chainRoundPlanInFlight = false;
  }

  void clearPlan() {
    _chainRoundPlan = null;
    _chainRoundPlanKey = null;
    _chainRoundPlanInFlight = false;
  }

  void invalidatePlanKey() {
    _chainRoundPlanKey = null;
  }

  void startPlanFetch(String key) {
    _chainRoundPlanKey = key;
    _chainRoundPlanInFlight = true;
  }

  void markPlanInFlight(bool inFlight) {
    _chainRoundPlanInFlight = inFlight;
  }

  String? resolveCurrentRuleName(GameModel? game) {
    if (game == null) {
      return null;
    }
    final fromPlan = _chainRoundPlan
        ?.roundAt(game.displayRoundIndex)
        ?.gameRuleName;
    return fromPlan ?? game.gameRule?.name;
  }

  void reset() {
    clearPauseLatch();
    clearPlan();
    clearPause();
    clearBingoArming();
  }

  void dispose() {
    pauseEndsAtListenable.dispose();
  }
}
