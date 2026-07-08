# Terminal Transition Single Owner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.  
> **Parent index:** [2026-07-08-live-stabilization-index.md](./2026-07-08-live-stabilization-index.md)  
> **Plan:** 3 of 6 — after Plans 1–2.

**Goal:** FINISHED, NO_WINNER, and CANCELLED go through one terminal owner that fetches once, applies once, pins review, and advances to READY without mixed live/registration UI.

**Architecture:** Route terminal sockets to `_realtime.requestTerminalCanonicalRefetch`. Wire `shouldRunCancelTransition`. Fold duplicate finish side effects so `_applyCanonicalGame` + one terminal enter function own leave-room / summary start. Hold previous UI until READY banner + grid apply together.

**Tech Stack:** Flutter, `live_game_finish_transition.dart`, `LiveRealtimeController`, `flutter_test`.

**No backend changes.**

---

## File map

| File | Responsibility |
|---|---|
| `lib/.../utils/live_game_finish_transition.dart` | Finish/cancel gates + pin rules (extend pin for cancelled) |
| `lib/.../controllers/live_realtime_controller.dart` | `requestTerminalCanonicalRefetch` |
| `lib/.../screens/live_game_orchestration.dart` | Cancel local + unify finish entry; `_onGameCancelled` |
| `lib/.../screens/live_game_realtime.dart` | Terminal status_changed / finished → terminal API |
| `lib/.../utils/live_ui_mode.dart` | Ensure cancelled presentation during pin |
| `test/live_game_finish_transition_test.dart` | Extend pin for cancelled |
| `test/live_terminal_cancel_ready_test.dart` | CANCELLED → READY banner+grid together (logic/helper) |
| `test/live_game_terminal_pin_test.dart` | Existing pin coverage |

---

### Task 1: Pin CANCELLED during review/transition (TDD)

**Files:**
- Modify: `lib/src/features/games/presentation/utils/live_game_finish_transition.dart`
- Modify: `test/live_game_finish_transition_test.dart`

- [ ] **Step 1: Write failing test**

```dart
test('shouldPinTerminalSession pins cancelled while summary review active', () {
  expect(
    shouldPinTerminalSession(
      status: GameStatus.cancelled,
      postGameSummaryReviewActive: true,
      winnerWindowExpired: false,
    ),
    isTrue,
  );
});

test('shouldPinTerminalSession pins cancelled status by default', () {
  expect(
    shouldPinTerminalSession(
      status: GameStatus.cancelled,
      postGameSummaryReviewActive: false,
      winnerWindowExpired: false,
    ),
    isTrue,
  );
});
```

- [ ] **Step 2: Run FAIL**

```bash
flutter test test/live_game_finish_transition_test.dart
```

Expected: FAIL — cancelled not pinned today.

- [ ] **Step 3: Minimal fix**

Update `shouldPinTerminalSession`:

```dart
bool shouldPinTerminalSession({
  required GameStatus? status,
  required bool postGameSummaryReviewActive,
  required bool winnerWindowExpired,
}) {
  if (postGameSummaryReviewActive) {
    return true;
  }

  return switch (status) {
    GameStatus.finished => true,
    GameStatus.noWinner => true,
    GameStatus.cancelled => true,
    GameStatus.winnerWindow => winnerWindowExpired,
    _ => false,
  };
}
```

- [ ] **Step 4: Run PASS**

```bash
flutter test test/live_game_finish_transition_test.dart test/live_game_terminal_pin_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/games/presentation/utils/live_game_finish_transition.dart \
  test/live_game_finish_transition_test.dart
git commit -m "$(cat <<'EOF'
fix(live): pin CANCELLED sessions during terminal handoff

EOF
)"
```

---

### Task 2: Route cancel/finish sockets to terminal refetch

**Files:**
- Modify: `lib/src/features/games/presentation/screens/live_game_orchestration.dart` (`_onGameCancelled`, `_onGameFinished` if present)
- Modify: `lib/src/features/games/presentation/screens/live_game_realtime.dart` (terminal `status_changed`)

- [ ] **Step 1: Add source-contract test**

```dart
// test/live_terminal_refetch_routing_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('_onGameCancelled uses requestTerminalCanonicalRefetch', () async {
    final source = await File(
      'lib/src/features/games/presentation/screens/live_game_orchestration.dart',
    ).readAsString();
    final cancelFnStart = source.indexOf('void _onGameCancelled');
    expect(cancelFnStart, greaterThanOrEqualTo(0));
    final snippet = source.substring(
      cancelFnStart,
      cancelFnStart + 1200,
    );
    expect(
      snippet.contains('requestTerminalCanonicalRefetch'),
      isTrue,
      reason: 'CANCELLED must use terminal coalesce path, not generic immediate',
    );
    expect(
      snippet.contains('_refetchCanonicalImmediate'),
      isFalse,
    );
  });
}
```

- [ ] **Step 2: Run FAIL**

```bash
flutter test test/live_terminal_refetch_routing_test.dart
```

- [ ] **Step 3: Rewrite `_onGameCancelled`**

```dart
void _onGameCancelled(dynamic payload) {
  if (!mounted) {
    return;
  }

  final normalizedPayload = _normalizeSocketPayloadForEvent(
    payload,
    eventName: 'game:cancelled',
    includeCalledNumbers: true,
  );
  if (normalizedPayload == null) {
    return;
  }

  final sessionId = normalizedPayload['sessionId'] as String?;
  final slotId = normalizedPayload['slotId'] as String?;
  if (!_eventAffectsCurrentGame(sessionId: sessionId, slotId: slotId)) {
    return;
  }

  if (!shouldRunCancelTransition(
    currentStatus: _game?.status,
    sessionRoomActive: _joinedGameId != null,
  )) {
    return;
  }

  _realtime.requestTerminalCanonicalRefetch(
    reason: 'game_cancelled',
    wallet: !_isGuest,
    registrationSessionId: _game?.sessionId,
    includeCalledNumbers: true,
    includeMyCartelas: false,
  );
}
```

For `game:finished` / terminal `status_changed` that currently call `_refetchCanonicalImmediate`, switch to:

```dart
_realtime.requestTerminalCanonicalRefetch(
  reason: 'game_finished', // or 'status_changed_terminal'
  wallet: !_isGuest,
  includeCalledNumbers: true,
);
```

Use Plan 2 matrix:

```dart
final action = resolveLiveSyncTriggerAction(
  LiveSyncTrigger.statusChanged,
  isTerminalStatus: isTerminalGameStatus(parsedStatus),
);
if (action == LiveSyncAction.terminalTransitionSnapshot) {
  _realtime.requestTerminalCanonicalRefetch(...);
  return;
}
```

- [ ] **Step 4: Run routing + finish tests PASS**

```bash
flutter test test/live_terminal_refetch_routing_test.dart \
  test/live_game_finish_transition_test.dart \
  test/live_game_realtime_cleanup_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/games/presentation/screens/live_game_orchestration.dart \
  lib/src/features/games/presentation/screens/live_game_realtime.dart \
  test/live_terminal_refetch_routing_test.dart
git commit -m "$(cat <<'EOF'
fix(live): route terminal sockets through requestTerminalCanonicalRefetch

EOF
)"
```

---

### Task 3: Single enter-terminal side effects (dedupe finish locals)

**Files:**
- Modify: `lib/src/features/games/presentation/screens/live_game_orchestration.dart` (`_handleGameFinishedLocally`, `_handleNoWinnerLocally`, `_applyCanonicalGame` terminal branches)
- Create: `test/live_terminal_side_effects_once_test.dart` (helper-level if pure extract)

- [ ] **Step 1: Extract pure guard helper**

```dart
// lib/.../utils/live_terminal_enter_policy.dart
bool shouldEnterTerminalSideEffects({
  required bool alreadyInSummary,
  required bool sessionRoomActive,
  required bool shouldRunTransition,
}) {
  if (!shouldRunTransition) {
    return false;
  }
  // Enter at most once: if summary already active and room already left, skip.
  if (alreadyInSummary && !sessionRoomActive) {
    return false;
  }
  return true;
}
```

Test:

```dart
test('skips second enter when summary active and room left', () {
  expect(
    shouldEnterTerminalSideEffects(
      alreadyInSummary: true,
      sessionRoomActive: false,
      shouldRunTransition: true,
    ),
    isFalse,
  );
});
```

- [ ] **Step 2: In `_applyCanonicalGame`, when merged status becomes finished/noWinner/cancelled, call one `_enterTerminalFromCanonical(...)` that:**

1. Checks `shouldEnterTerminalSideEffects` + `shouldRunFinishTransition` / `shouldRunCancelTransition`
2. Leaves session room once (`_applySocketSessionMembership(null)`)
3. Starts post-game summary once for finished/noWinner (cancelled may use shorter cancel notice + same advance path — match existing UI modes; do not invent new screens)
4. Does **not** call `_scheduleCanonicalRefetch` again unless cartelas/wallet satellites are explicitly missing
5. Avoids calling `_handleGameFinishedLocally` *and* another refetch schedule for the same apply

- [ ] **Step 3: Make socket-local finish helpers call the same `_enterTerminalFromCanonical` or become no-ops when apply already entered**

Prefer: socket finished → terminal refetch only; side effects only inside apply. Delete or narrow `_handleGameFinishedLocally` wallet/refetch tail:

```dart
// Remove this pattern from local finish helpers:
_scheduleCanonicalRefetch(wallet: !_isGuest);
```

- [ ] **Step 4: Run**

```bash
flutter test test/live_terminal_side_effects_once_test.dart \
  test/finished_review_ui_test.dart \
  test/live_game_terminal_pin_test.dart \
  test/live_ui_mode_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/games/presentation/utils/live_terminal_enter_policy.dart \
  lib/src/features/games/presentation/screens/live_game_orchestration.dart \
  test/live_terminal_side_effects_once_test.dart
git commit -m "$(cat <<'EOF'
fix(live): enter terminal side effects once from canonical apply

EOF
)"
```

---

### Task 4: READY replace applies banner + grid together

**Files:**
- Modify: `lib/src/features/games/presentation/screens/live_game_orchestration.dart` (`_applyCanonicalGame`, advance helpers)
- Create: `test/live_ready_atomic_apply_test.dart`

- [ ] **Step 1: Encode atomic READY visibility rule in pure function**

```dart
// lib/.../utils/live_ready_atomic_visibility.dart
class ReadyAtomicVisibility {
  const ReadyAtomicVisibility({
    required this.showBanner,
    required this.showGrid,
  });

  final bool showBanner;
  final bool showGrid;
}

ReadyAtomicVisibility resolveReadyAtomicVisibility({
  required bool hasReadyGame,
  required bool gridReady,
  required bool holdingPreviousReady,
}) {
  if (holdingPreviousReady && !hasReadyGame) {
    // Keep previous paint — callers should not flip mode yet.
    return const ReadyAtomicVisibility(showBanner: true, showGrid: true);
  }
  if (!hasReadyGame) {
    return const ReadyAtomicVisibility(showBanner: false, showGrid: false);
  }
  // Never show grid without banner or banner without grid when data incomplete.
  final both = gridReady;
  return ReadyAtomicVisibility(showBanner: both, showGrid: both);
}
```

Tests:

```dart
test('incomplete grid hides both banner and grid', () {
  final v = resolveReadyAtomicVisibility(
    hasReadyGame: true,
    gridReady: false,
    holdingPreviousReady: false,
  );
  expect(v.showBanner, isFalse);
  expect(v.showGrid, isFalse);
});

test('complete ready shows both', () {
  final v = resolveReadyAtomicVisibility(
    hasReadyGame: true,
    gridReady: true,
    holdingPreviousReady: false,
  );
  expect(v.showBanner, isTrue);
  expect(v.showGrid, isTrue);
});
```

- [ ] **Step 2: Integrate into apply / UI mode inputs**

When applying next READY after terminal:

1. Hold previous presentation until `gridReady` (cartelas/registration state loaded or confirmed empty)
2. Single `setState` / apply that sets `_game`, registration target, and cartela lists together
3. Clear called numbers only when `sessionChanged` (already intended)

Do **not** set `_game` to the new READY while leaving strip/cartelas from the cancelled live session visible — clear session-scoped play state in the **same** apply that installs READY.

- [ ] **Step 3: Run UI mode + ready visibility tests**

```bash
flutter test test/live_ready_atomic_apply_test.dart test/live_ui_mode_test.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/src/features/games/presentation/utils/live_ready_atomic_visibility.dart \
  lib/src/features/games/presentation/screens/live_game_orchestration.dart \
  lib/src/features/games/presentation/utils/live_ui_mode.dart \
  test/live_ready_atomic_apply_test.dart
git commit -m "$(cat <<'EOF'
fix(live): apply READY banner and registration grid atomically

EOF
)"
```

---

## Plan 3 self-review

| Spec item | Task |
|---|---|
| CANCELLED terminal owner | Tasks 1–2 |
| No double terminal complete | Task 3 |
| Banner+grid together | Task 4 |
| Wire `shouldRunCancelTransition` | Task 2 |
| No backend | Constraint |

Plan 5 will gate resume while `postGameSummaryReviewActive` / advancing / terminal refetch in flight.
