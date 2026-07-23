import '../../data/models/called_number_model.dart';
import '../../data/models/game_model.dart';
import 'next_ball_countdown.dart';

/// How many recent called numbers to show in the missed-player ball strip
/// (active + recent). Higher fills the tray; ListView still scrolls if needed.
const int kMissedPreviewRecentLimit = 12;

/// Recent called numbers for the missed-player preview (order preserved).
List<CalledNumberModel> filterMissedPreviewCalledNumbers({
  required List<CalledNumberModel> sharedCalledNumbers,
  required String? previewSessionId,
  int previewLimit = kMissedPreviewRecentLimit,
}) {
  if (previewSessionId == null || previewSessionId.isEmpty) {
    return const [];
  }

  final previewNumbers = sharedCalledNumbers
      .where((entry) => entry.sessionId == previewSessionId)
      .toList(growable: false);

  if (previewNumbers.length <= previewLimit) {
    return previewNumbers;
  }

  return previewNumbers.sublist(previewNumbers.length - previewLimit);
}

int? missedPreviewActiveNumber(List<CalledNumberModel> previewNumbers) {
  if (previewNumbers.isEmpty) {
    return null;
  }
  return previewNumbers.last.number;
}

int missedPreviewRemainingCount({
  required GameModel? previewSession,
  required int filteredPreviewLength,
}) {
  final calledCount = previewSession?.calledNumbersCount ?? 0;
  final used = calledCount > 0 ? calledCount : filteredPreviewLength;
  return (kMaxBingoBalls - used).clamp(0, kMaxBingoBalls);
}
