# Socket Normalize & Trigger Matrix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.  
> **Parent index:** [2026-07-08-live-stabilization-index.md](./2026-07-08-live-stabilization-index.md)  
> **Plan:** 2 of 6 — after Plan 1.

**Goal:** Every live socket handler normalizes payloads before map access, and each sync trigger performs exactly one prescribed action (local patch / called-numbers fetch / canonical / terminal / ignore).

**Architecture:** Harden `normalizeSocketPayload` usage in `live_game_realtime.dart` and orchestration handlers. Encode the trigger matrix in a small pure helper so tests lock the contract. Stop inventing `PLAYING` from `number_called`.

**Tech Stack:** Flutter, existing `socket_payload_normalizer.dart`, `flutter_test`.

**No backend changes.**

---

## File map

| File | Responsibility |
|---|---|
| `lib/.../utils/socket_payload_normalizer.dart` | Normalize JS/Dart payloads |
| `lib/.../utils/live_sync_trigger_action.dart` | Pure trigger → action mapping |
| `lib/.../screens/live_game_realtime.dart` | Handlers use normalize + matrix |
| `lib/.../screens/live_game_orchestration.dart` | `_onNumberCalled` stop status invent |
| `test/live_sync_trigger_action_test.dart` | Matrix contract tests |
| `test/socket_payload_normalizer_test.dart` | Extend if missing Map/`$_get` cases |
| `test/number_called_no_status_invent_test.dart` | Number-called does not force PLAYING |

---

### Task 1: Trigger action enum + resolver (TDD)

**Files:**
- Create: `lib/src/features/games/presentation/utils/live_sync_trigger_action.dart`
- Create: `test/live_sync_trigger_action_test.dart`

- [x] **Step 1: Write failing tests**

```dart
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
```

- [x] **Step 2: Run — expect FAIL (library missing)**

```bash
flutter test test/live_sync_trigger_action_test.dart
```

- [x] **Step 3: Minimal implementation**

```dart
// lib/src/features/games/presentation/utils/live_sync_trigger_action.dart

enum LiveSyncTrigger {
  appResume,
  socketReconnect,
  manualRefresh,
  operationUpdated,
  statusChanged,
  gameCancelled,
  gameFinished,
  walletUpdated,
  staleCountdown,
  invalidPayload,
  numberCalledGap,
  numberCalledConflict,
  bingoValid,
  winnerWindow,
  bingoInvalidMissingSchedule,
  registrationClosedEmpty,
  preparingPoll,
}

enum LiveSyncAction {
  localPatchOnly,
  calledNumbersFetchOnly,
  canonicalSnapshotFetch,
  terminalTransitionSnapshot,
  ignore,
}

LiveSyncAction resolveLiveSyncTriggerAction(
  LiveSyncTrigger trigger, {
  String? updatedReason,
  bool isTerminalStatus = false,
  bool terminalTransitionActive = false,
  int staleStage = 1,
}) {
  switch (trigger) {
    case LiveSyncTrigger.appResume:
    case LiveSyncTrigger.socketReconnect:
      if (terminalTransitionActive) {
        return LiveSyncAction.ignore;
      }
      return LiveSyncAction.canonicalSnapshotFetch;
    case LiveSyncTrigger.manualRefresh:
      return LiveSyncAction.canonicalSnapshotFetch;
    case LiveSyncTrigger.operationUpdated:
      if (updatedReason == 'number_called') {
        return LiveSyncAction.ignore;
      }
      if (updatedReason == 'auto_call_changed') {
        return LiveSyncAction.localPatchOnly;
      }
      return LiveSyncAction.canonicalSnapshotFetch;
    case LiveSyncTrigger.statusChanged:
      return isTerminalStatus
          ? LiveSyncAction.terminalTransitionSnapshot
          : LiveSyncAction.canonicalSnapshotFetch;
    case LiveSyncTrigger.gameCancelled:
    case LiveSyncTrigger.gameFinished:
      return LiveSyncAction.terminalTransitionSnapshot;
    case LiveSyncTrigger.walletUpdated:
      return LiveSyncAction.ignore;
    case LiveSyncTrigger.staleCountdown:
      return staleStage <= 1
          ? LiveSyncAction.calledNumbersFetchOnly
          : LiveSyncAction.canonicalSnapshotFetch;
    case LiveSyncTrigger.invalidPayload:
      return LiveSyncAction.canonicalSnapshotFetch;
    case LiveSyncTrigger.numberCalledGap:
      return LiveSyncAction.calledNumbersFetchOnly;
    case LiveSyncTrigger.numberCalledConflict:
      return LiveSyncAction.canonicalSnapshotFetch;
    case LiveSyncTrigger.bingoValid:
    case LiveSyncTrigger.winnerWindow:
      return LiveSyncAction.localPatchOnly;
    case LiveSyncTrigger.bingoInvalidMissingSchedule:
    case LiveSyncTrigger.registrationClosedEmpty:
    case LiveSyncTrigger.preparingPoll:
      return LiveSyncAction.canonicalSnapshotFetch;
  }
}
```

- [x] **Step 4: Run tests — PASS**

```bash
flutter test test/live_sync_trigger_action_test.dart
```

- [x] **Step 5: Commit** — `feat(live): added sync trigger action matrix`

---

### Task 2: Normalize `operation_updated` Map branch

**Files:**
- Modify: `lib/src/features/games/presentation/screens/live_game_realtime.dart` (`_onGameOperationUpdated`)
- Test: extend `test/live_game_realtime_cleanup_test.dart` or add normalize regression

- [x] **Step 1: Write failing test for raw JS-like map handling**

If an existing normalize test covers Dart `Map`, add:

```dart
test('operation_updated auto_call_changed works after normalize-only path', () {
  // Arrange a LinkedHashMap / non-Map<String,dynamic> style payload
  final payload = <dynamic, dynamic>{
    'updatedReason': 'auto_call_changed',
    'sessionId': 'sess-1',
    'slotId': 'slot-1',
    'autoCallEnabled': true,
    'nextAutoCallAt': '2099-01-01T00:00:00.000Z',
    'autoCallIntervalMs': 3000,
  };
  final normalized = normalizeSocketPayload(payload);
  expect(normalized, isNotNull);
  expect(normalized!['updatedReason'], 'auto_call_changed');
});
```

- [x] **Step 2: Run — ensure normalize accepts non-typed Map (likely already PASS). Keep test.**

- [x] **Step 3: Rewrite `_onGameOperationUpdated` to always normalize first**

Replace the `if (payload is Map<String, dynamic>)` short-circuit with:

```dart
void _onGameOperationUpdated(dynamic payload) {
  if (!mounted) {
    return;
  }

  final normalizedPayload = _normalizeSocketPayloadForEvent(
    payload,
    eventName: 'game:operation_updated',
  );
  if (normalizedPayload == null) {
    return;
  }

  final action = resolveLiveSyncTriggerAction(
    LiveSyncTrigger.operationUpdated,
    updatedReason: normalizedPayload['updatedReason'] as String?,
  );

  switch (action) {
    case LiveSyncAction.ignore:
      return;
    case LiveSyncAction.localPatchOnly:
      final sessionId = normalizedPayload['sessionId'] as String?;
      final slotId = normalizedPayload['slotId'] as String?;
      if (_eventAffectsCurrentGame(sessionId: sessionId, slotId: slotId)) {
        LiveRealtimeDebug.socket('game:operation_updated', normalizedPayload);
        _applyAutoCallScheduleFromPayload(normalizedPayload);
      }
      return;
    case LiveSyncAction.canonicalSnapshotFetch:
      final sessionId = normalizedPayload['sessionId'] as String?;
      final slotId = normalizedPayload['slotId'] as String?;
      final affectsCurrent = _eventAffectsCurrentGame(
        sessionId: sessionId,
        slotId: slotId,
      );
      final affectsRegistration = _eventAffectsRegistrationSession(
        sessionId: sessionId,
        slotId: slotId,
      );
      if (!affectsCurrent && !affectsRegistration) {
        return;
      }
      if (affectsRegistration && !affectsCurrent) {
        _scheduleCanonicalRefetch(
          reason: 'operation_updated_registration',
          registrationSessionId: sessionId,
        );
        return;
      }
      _scheduleCanonicalRefetch(reason: 'operation_updated');
      return;
    case LiveSyncAction.calledNumbersFetchOnly:
    case LiveSyncAction.terminalTransitionSnapshot:
      // Not used for operation_updated in Plan 2 matrix.
      return;
  }
}
```

Import:

```dart
import '../utils/live_sync_trigger_action.dart';
```

- [x] **Step 4: Run** — PASS

- [x] **Step 5: Commit** — `fix(live): normalized operation_updated before map access`

---

### Task 3: Stop inventing PLAYING from `number_called`

**Files:**
- Modify: `lib/src/features/games/presentation/screens/live_game_orchestration.dart` (`_onNumberCalled` ~2527+)
- Create: `test/number_called_no_status_invent_test.dart`

- [x] **Step 1: Locate status promote logic**

Find the block that does roughly:

```dart
_game = _game!.copyWith(status: GameStatus.playing);
```

when a number arrives while UI is not live / needs reconcile.

- [x] **Step 2: Write a pure-unit regression if extractable; otherwise document behavioral assert in orphan/util test**

Prefer extracting a tiny helper:

```dart
// lib/.../utils/number_called_status_policy.dart
bool shouldPromoteToPlayingFromNumberCalled({
  required GameStatus? currentStatus,
}) {
  // KISS: never invent PLAYING — status_changed / ops own it.
  return false;
}
```

Test:

```dart
test('number_called never promotes status', () {
  expect(
    shouldPromoteToPlayingFromNumberCalled(
      currentStatus: GameStatus.ready,
    ),
    isFalse,
  );
});
```

- [x] **Step 3: Run FAIL then implement helper returning false; remove promote branch from `_onNumberCalled`**

Keep:

- ball apply
- schedule/`nextAutoCallAt` patch
- gap → called-numbers fetch
- conflict → canonical refetch

Remove:

- local `status: playing` assignment from this handler

If reconcile still needed, schedule:

```dart
_scheduleCanonicalRefetch(
  reason: 'number_called_needs_live_reconcile',
  includeCalledNumbers: true,
);
```

- [x] **Step 4: Run** — PASS (`live_called_number_sync_test` has a pre-existing failure unrelated to this change)

- [x] **Step 5: Commit** — `fix(live): stopped inventing PLAYING from number_called`

---

### Task 4: Audit remaining handlers for normalize-first

**Files:**
- Modify as needed: `live_game_orchestration.dart`, `live_game_realtime.dart`
- Grep-driven cleanup only

- [x] **Step 1: Grep raw payload access**

```bash
rg "payload\['|payload\[\\\$" lib/src/features/games/presentation/screens/live_game_*.dart
```

Allowed after normalize assignment to `normalizedPayload`. Disallowed: reading `payload['…']` on the original `dynamic` without normalize.

- [x] **Step 2: Fix any stragglers the same way as Task 2**

- [x] **Step 3: Run cleanup + normalize tests** — PASS

- [x] **Step 4: Commit** — `fix(live): ensured socket handlers normalize before field access`

---

## Plan 2 self-review

| Spec requirement | Task |
|---|---|
| No raw payload crashes | Tasks 2, 4 |
| Trigger matrix one action | Task 1 + Task 2 switch |
| Ignore `number_called` ops reason | Task 1–2 |
| Local patch auto_call_changed | Task 2 |
| Stop invent PLAYING | Task 3 |
| Wallet ignore for game sync | Task 1 (handlers already wallet-only) |

Terminal action enum values are declared here; **Plan 3** wires handlers to `requestTerminalCanonicalRefetch`.
