import '../../data/models/called_number_model.dart';
import '../../data/models/game_model.dart';
import 'next_ball_countdown.dart';

/// Highest draw order on the committed strip (not deferred/buffer).
int committedMaxCalledOrder(List<CalledNumberModel> committed) {
  if (committed.isEmpty) {
    return 0;
  }
  return committed.last.order;
}

/// Server-side draw count for drift checks (monotonic with local game model).
int authoritativeCalledNumbersCount({
  required int gameCalledNumbersCount,
  int? payloadCalledNumbersCount,
}) {
  final payloadCount = payloadCalledNumbersCount;
  if (payloadCount == null) {
    return gameCalledNumbersCount;
  }
  return payloadCount > gameCalledNumbersCount
      ? payloadCount
      : gameCalledNumbersCount;
}

bool stripBehindAuthoritativeCount({
  required int committedMax,
  required int authoritativeCount,
}) {
  return authoritativeCount > committedMax;
}

/// Whether a thin [auto_call_changed] schedule patch should trigger one
/// existing called-numbers HTTP gap fill (no canonical ops fetch).
bool shouldHealAfterAutoCallSchedulePatch({
  required GameStatus? gameStatus,
  required bool autoCallActive,
  required bool scheduleChanged,
  required int committedMax,
  required int gameCalledNumbersCount,
  int? payloadCalledNumbersCount,
  required bool wasInCallingPhase,
  int? callingBaselineOrder,
}) {
  if (gameStatus != GameStatus.playing || !autoCallActive) {
    return false;
  }

  final authoritative = authoritativeCalledNumbersCount(
    gameCalledNumbersCount: gameCalledNumbersCount,
    payloadCalledNumbersCount: payloadCalledNumbersCount,
  );

  if (stripBehindAuthoritativeCount(
    committedMax: committedMax,
    authoritativeCount: authoritative,
  )) {
    return true;
  }

  if (payloadCalledNumbersCount != null) {
    return false;
  }

  if (!scheduleChanged || !wasInCallingPhase) {
    return false;
  }

  final baseline = callingBaselineOrder ?? committedMax;
  return committedMax <= baseline;
}

int? parseCalledNumbersCountFromSchedulePayload(Map<String, dynamic> payload) {
  final raw = payload['calledNumbersCount'];
  if (raw is num) {
    return raw.round();
  }
  return null;
}

bool wasInCallingPlayPhase(NextBallPlayPhase phase) {
  return phase == NextBallPlayPhase.calling;
}
