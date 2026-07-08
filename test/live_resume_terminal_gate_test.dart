import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_resume_terminal_gate.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_sync_trigger_action.dart';

void main() {
  test('app_resume ignored while post-game summary active', () {
    expect(
      shouldRunResumeSync(
        trigger: LiveSyncTrigger.appResume,
        postGameSummaryReviewActive: true,
        postGameSummaryAdvancing: false,
        terminalCanonicalRefetchInFlight: false,
      ),
      isFalse,
    );
  });

  test('socket_reconnect ignored while terminal refetch in flight', () {
    expect(
      shouldRunResumeSync(
        trigger: LiveSyncTrigger.socketReconnect,
        postGameSummaryReviewActive: false,
        postGameSummaryAdvancing: false,
        terminalCanonicalRefetchInFlight: true,
      ),
      isFalse,
    );
  });

  test('manual_refresh always allowed', () {
    expect(
      shouldRunResumeSync(
        trigger: LiveSyncTrigger.manualRefresh,
        postGameSummaryReviewActive: true,
        postGameSummaryAdvancing: true,
        terminalCanonicalRefetchInFlight: true,
      ),
      isTrue,
    );
  });

  test('app_resume allowed when idle', () {
    expect(
      shouldRunResumeSync(
        trigger: LiveSyncTrigger.appResume,
        postGameSummaryReviewActive: false,
        postGameSummaryAdvancing: false,
        terminalCanonicalRefetchInFlight: false,
      ),
      isTrue,
    );
  });

  test('liveSyncTriggerFromResumeReason maps known reasons', () {
    expect(
      liveSyncTriggerFromResumeReason('app_resume'),
      LiveSyncTrigger.appResume,
    );
    expect(
      liveSyncTriggerFromResumeReason('socket_reconnect'),
      LiveSyncTrigger.socketReconnect,
    );
    expect(
      liveSyncTriggerFromResumeReason('manual_refresh'),
      LiveSyncTrigger.manualRefresh,
    );
  });
}
