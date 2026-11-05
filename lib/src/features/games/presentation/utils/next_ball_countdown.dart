import '../../../../core/utils/api_date_time.dart';
import '../../../../core/time/server_clock_service.dart';
import '../../data/models/game_model.dart';
import '../../domain/live_connection_status.dart';

/// Standard bingo draw pool size (B–O columns 1–75).
const kMaxBingoBalls = 75;

int effectiveCalledNumbersCount({
  required int? calledNumbersCount,
  required int localCalledCount,
  int highestCalledOrder = 0,
}) {
  final serverCount = calledNumbersCount ?? 0;
  return [
    serverCount,
    localCalledCount,
    highestCalledOrder,
  ].reduce((left, right) => left > right ? left : right);
}

bool isAllBallsDrawn({
  required int? calledNumbersCount,
  required int localCalledCount,
  int highestCalledOrder = 0,
}) {
  return effectiveCalledNumbersCount(
        calledNumbersCount: calledNumbersCount,
        localCalledCount: localCalledCount,
        highestCalledOrder: highestCalledOrder,
      ) >=
      kMaxBingoBalls;
}

/// True when auto-call is off and there is no upcoming schedule to track.
bool isNextBallCountdownInactive({
  required bool autoCallActive,
  required DateTime? nextAutoCallAt,
}) {
  return !autoCallActive && nextAutoCallAt == null;
}

enum NextBallPlayPhase {
  counting,
  calling,
}

/// Active auto-call window for the calling UI and strip self-heal.
NextBallPlayPhase resolveNextBallPlayPhase({
  required GameStatus? gameStatus,
  required bool autoCallActive,
  required DateTime? nextAutoCallAt,
  DateTime? now,
  ServerClockService? clock,
}) {
  if (gameStatus != GameStatus.playing ||
      !autoCallActive ||
      nextAutoCallAt == null) {
    return NextBallPlayPhase.counting;
  }

  final seconds = nextBallCountdownSeconds(
    nextAutoCallAt,
    now: now,
    clock: clock,
  );
  if (seconds <= 0) {
    return NextBallPlayPhase.calling;
  }
  return NextBallPlayPhase.counting;
}

enum NextBallCountdownState {
  hidden,
  waiting,
  waitingFirstBall,
  counting,
  calling,
  allBallsDrawn,
}

NextBallCountdownState resolveNextBallCountdownState({
  required bool showCountdown,
  required bool hideForSync,
  required LiveConnectionStatus connectionStatus,
  required DateTime? nextAutoCallAt,
  required bool waitingForFirstBall,
  bool allBallsDrawn = false,
  DateTime? now,
  ServerClockService? clock,
}) {
  if (!showCountdown || hideForSync) {
    return NextBallCountdownState.hidden;
  }

  if (connectionStatus != LiveConnectionStatus.live) {
    return NextBallCountdownState.hidden;
  }

  if (allBallsDrawn) {
    return NextBallCountdownState.allBallsDrawn;
  }

  if (nextAutoCallAt == null) {
    return NextBallCountdownState.waiting;
  }

  final seconds = secondsUntilCeil(nextAutoCallAt, now: now, clock: clock);
  if (seconds <= 0) {
    return NextBallCountdownState.calling;
  }

  if (waitingForFirstBall) {
    return NextBallCountdownState.waitingFirstBall;
  }

  return NextBallCountdownState.counting;
}

int nextBallCountdownSeconds(
  DateTime? nextAutoCallAt, {
  DateTime? now,
  ServerClockService? clock,
}) {
  return secondsUntilCeil(nextAutoCallAt, now: now, clock: clock);
}

/// In the last N seconds before the next auto-call the countdown ticker runs
/// faster so the "calling" phase is detected promptly (display + strip heal).
const kNextBallFastTickWindowSeconds = 1;

/// Label for the called-numbers header badge (server-tracked seconds).
String? buildNextBallCountdownLabel({
  required NextBallCountdownState state,
  required int? trackedSeconds,
  required String waitingNextBallLabel,
  required String callingNextLabel,
  required String syncingNextBallLabel,
  required String allBallsDrawnLabel,
  required String Function(int seconds) nextBallInLabel,
  required String Function(int seconds) waitingFirstBallInLabel,
  bool isClaimChecking = false,
  String? claimCheckingLabel,
  int zeroForMs = 0,
  int staleAfterMs = 2000,
}) {
  if (isClaimChecking && claimCheckingLabel != null) {
    return claimCheckingLabel;
  }

  switch (state) {
    case NextBallCountdownState.hidden:
      return null;
    case NextBallCountdownState.allBallsDrawn:
      return allBallsDrawnLabel;
    case NextBallCountdownState.waiting:
      return waitingNextBallLabel;
    case NextBallCountdownState.calling:
      return zeroForMs >= staleAfterMs ? syncingNextBallLabel : callingNextLabel;
    case NextBallCountdownState.waitingFirstBall:
      return trackedSeconds == null
          ? waitingNextBallLabel
          : waitingFirstBallInLabel(trackedSeconds);
    case NextBallCountdownState.counting:
      return trackedSeconds == null
          ? waitingNextBallLabel
          : nextBallInLabel(trackedSeconds);
  }
}
