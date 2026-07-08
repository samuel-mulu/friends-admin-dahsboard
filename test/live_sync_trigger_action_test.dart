import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_sync_trigger_action.dart';

void main() {
  group('resolveLiveSyncTriggerAction', () {
    test('operation_updated number_called is ignore', () {
      expect(
        resolveLiveSyncTriggerAction(
          LiveSyncTrigger.operationUpdated,
          updatedReason: 'number_called',
        ),
        LiveSyncAction.ignore,
      );
    });

    test('operation_updated auto_call_changed is localPatchOnly', () {
      expect(
        resolveLiveSyncTriggerAction(
          LiveSyncTrigger.operationUpdated,
          updatedReason: 'auto_call_changed',
        ),
        LiveSyncAction.localPatchOnly,
      );
    });

    test('operation_updated full payload is canonicalSnapshotFetch', () {
      expect(
        resolveLiveSyncTriggerAction(LiveSyncTrigger.operationUpdated),
        LiveSyncAction.canonicalSnapshotFetch,
      );
    });

    test('wallet_updated is ignore', () {
      expect(
        resolveLiveSyncTriggerAction(LiveSyncTrigger.walletUpdated),
        LiveSyncAction.ignore,
      );
    });

    test('game_cancelled is terminalTransitionSnapshot', () {
      expect(
        resolveLiveSyncTriggerAction(LiveSyncTrigger.gameCancelled),
        LiveSyncAction.terminalTransitionSnapshot,
      );
    });

    test('game_finished is terminalTransitionSnapshot', () {
      expect(
        resolveLiveSyncTriggerAction(LiveSyncTrigger.gameFinished),
        LiveSyncAction.terminalTransitionSnapshot,
      );
    });

    test('status_changed terminal is terminalTransitionSnapshot', () {
      expect(
        resolveLiveSyncTriggerAction(
          LiveSyncTrigger.statusChanged,
          isTerminalStatus: true,
        ),
        LiveSyncAction.terminalTransitionSnapshot,
      );
    });

    test('status_changed non-terminal is canonicalSnapshotFetch', () {
      expect(
        resolveLiveSyncTriggerAction(
          LiveSyncTrigger.statusChanged,
          isTerminalStatus: false,
        ),
        LiveSyncAction.canonicalSnapshotFetch,
      );
    });

    test('app_resume during terminal is ignore', () {
      expect(
        resolveLiveSyncTriggerAction(
          LiveSyncTrigger.appResume,
          terminalTransitionActive: true,
        ),
        LiveSyncAction.ignore,
      );
    });

    test('app_resume otherwise is canonicalSnapshotFetch', () {
      expect(
        resolveLiveSyncTriggerAction(LiveSyncTrigger.appResume),
        LiveSyncAction.canonicalSnapshotFetch,
      );
    });

    test('stale countdown stage1 is calledNumbersFetchOnly', () {
      expect(
        resolveLiveSyncTriggerAction(
          LiveSyncTrigger.staleCountdown,
          staleStage: 1,
        ),
        LiveSyncAction.calledNumbersFetchOnly,
      );
    });

    test('stale countdown stage2 is canonicalSnapshotFetch', () {
      expect(
        resolveLiveSyncTriggerAction(
          LiveSyncTrigger.staleCountdown,
          staleStage: 2,
        ),
        LiveSyncAction.canonicalSnapshotFetch,
      );
    });
  });
}
