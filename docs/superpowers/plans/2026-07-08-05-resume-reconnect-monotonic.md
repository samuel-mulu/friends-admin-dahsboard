# Resume/Reconnect Gates & Monotonic Called Numbers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.  
> **Parent index:** [2026-07-08-live-stabilization-index.md](./2026-07-08-live-stabilization-index.md)  
> **Plan:** 5 of 6 — after Plan 3 (may parallel Plan 4).

**Goal:** Ignore or delay `app_resume` / `socket_reconnect` during terminal transitions; prevent same-session called-number rollback; ensure socket balls win over stale HTTP during recovery.

**Architecture:** Gate `LiveRealtimeController.syncLatest` with Plan 2 trigger matrix `terminalTransitionActive`. Add pure monotonic merge for called numbers. Pause preparing poll while resume/canonical in flight.

**Tech Stack:** Flutter, `LiveRealtimeController`, `LiveCalledNumbersController`, `LiveTransitionController`, `flutter_test`.

**No backend changes.**

---

## File map

| File | Responsibility |
|---|---|
| `lib/.../utils/live_sync_trigger_action.dart` | Already returns ignore when terminal (Plan 2) |
| `lib/.../controllers/live_realtime_controller.dart` | Gate `syncLatest` |
| `lib/.../controllers/live_transition_controller.dart` | Pause preparing poll during sync |
| `lib/.../utils/live_called_number_monotonic.dart` | Merge policy |
| `lib/.../controllers/live_called_numbers_controller.dart` | Apply merge on HTTP replace |
| `test/live_resume_terminal_gate_test.dart` | Resume ignored during terminal |
| `test/live_called_number_monotonic_test.dart` | No rollback |

---

### Task 1: Terminal gate for syncLatest (TDD)

**Files:**
- Create: `lib/src/features/games/presentation/utils/live_resume_terminal_gate.dart`
- Create: `test/live_resume_terminal_gate_test.dart`
- Modify: `lib/src/features/games/presentation/controllers/live_realtime_controller.dart`

- [ ] **Step 1: Tests**

```dart
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
}
```

- [ ] **Step 2: Implement**

```dart
bool shouldRunResumeSync({
  required LiveSyncTrigger trigger,
  required bool postGameSummaryReviewActive,
  required bool postGameSummaryAdvancing,
  required bool terminalCanonicalRefetchInFlight,
}) {
  if (trigger == LiveSyncTrigger.manualRefresh) {
    return true;
  }

  final terminalActive = postGameSummaryReviewActive ||
      postGameSummaryAdvancing ||
      terminalCanonicalRefetchInFlight;

  final action = resolveLiveSyncTriggerAction(
    trigger,
    terminalTransitionActive: terminalActive,
  );
  return action != LiveSyncAction.ignore;
}
```

Map `syncLatest(reason:)` reason strings to triggers:

- `app_resume` → `LiveSyncTrigger.appResume`
- `socket_reconnect` → `LiveSyncTrigger.socketReconnect`
- `manual_refresh` → `LiveSyncTrigger.manualRefresh`

- [ ] **Step 3: Wire at top of `syncLatest`**

```dart
Future<void> syncLatest({required String reason}) async {
  if (!host.mounted) {
    return;
  }

  final trigger = liveSyncTriggerFromResumeReason(reason);
  final review = host.controllers.review;
  if (!shouldRunResumeSync(
    trigger: trigger,
    postGameSummaryReviewActive: review.postGameSummaryReviewActive,
    postGameSummaryAdvancing: review.postGameSummaryAdvancing,
    terminalCanonicalRefetchInFlight:
        canonicalRefetchInFlight &&
        (pendingRefetchReason?.startsWith('game_') == true ||
            pendingRefetchReason?.contains('terminal') == true ||
            lastTerminalCanonicalRefetchRequestedAt != null &&
                host.countdownNow()
                        .difference(lastTerminalCanonicalRefetchRequestedAt!) <
                    const Duration(seconds: 3)),
  )) {
    LiveRealtimeDebug.resumeSyncIgnored(reason: '${reason}_terminal_active');
    return;
  }

  // existing coalesce / debounce body...
}
```

Prefer reading an explicit `host.isTerminalTransitionActive` getter if easier — add to `LiveGameHost` if needed:

```dart
bool get isTerminalTransitionActive;
```

Implemented by screen as:

```dart
bool get isTerminalTransitionActive =>
    _review.postGameSummaryReviewActive ||
    _review.postGameSummaryAdvancing ||
    (_realtime.canonicalRefetchInFlight && _terminalRefetchActiveFlag);
```

Keep the gate **simple and deterministic** — prefer one boolean on host updated when terminal refetch starts/ends.

- [ ] **Step 4: Run**

```bash
flutter test test/live_resume_terminal_gate_test.dart \
  test/live_reconnect_current_state_sync_test.dart \
  test/live_resume_sync_test.dart
```

Update reconnect tests if they assumed resume during summary — adjust fixtures so terminal inactive OR expect ignore.

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/games/presentation/utils/live_resume_terminal_gate.dart \
  lib/src/features/games/presentation/controllers/live_realtime_controller.dart \
  lib/src/features/games/presentation/controllers/live_game_host.dart \
  lib/src/features/games/presentation/screens/live_game_screen.dart \
  test/live_resume_terminal_gate_test.dart
git commit -m "$(cat <<'EOF'
fix(live): ignore app resume and reconnect during terminal transitions

EOF
)"
```

---

### Task 2: Monotonic called-number merge

**Files:**
- Create: `lib/src/features/games/presentation/utils/live_called_number_monotonic.dart`
- Create: `test/live_called_number_monotonic_test.dart`
- Modify: called-numbers apply path in orchestration / `LiveCalledNumbersController`

- [ ] **Step 1: Tests**

```dart
void main() {
  test('same session refuses shorter HTTP list when local is ahead', () {
    final merged = mergeCalledNumbersMonotonic(
      sessionId: 's1',
      localSessionId: 's1',
      localOrders: const [1, 2, 3, 4],
      incomingOrders: const [1, 2, 3],
      preferIncomingIfNewerSocket: false,
    );
    expect(merged.orders, [1, 2, 3, 4]);
    expect(merged.rejectedRollback, isTrue);
  });

  test('session change accepts full incoming replace', () {
    final merged = mergeCalledNumbersMonotonic(
      sessionId: 's2',
      localSessionId: 's1',
      localOrders: const [1, 2, 3, 4],
      incomingOrders: const [1],
      preferIncomingIfNewerSocket: false,
    );
    expect(merged.orders, [1]);
    expect(merged.rejectedRollback, isFalse);
  });

  test('socket orders union wins when marked newer during recovery', () {
    final merged = mergeCalledNumbersMonotonic(
      sessionId: 's1',
      localSessionId: 's1',
      localOrders: const [1, 2, 3, 5], // socket ahead with gap filled locally
      incomingOrders: const [1, 2, 3, 4],
      preferIncomingIfNewerSocket: true,
      socketMaxOrder: 5,
      incomingMaxOrder: 4,
    );
    expect(merged.orders.contains(5), isTrue);
    expect(merged.rejectedRollback, isTrue);
  });
}
```

- [ ] **Step 2: Implement merge**

```dart
class CalledNumberMergeResult {
  const CalledNumberMergeResult({
    required this.orders,
    required this.rejectedRollback,
  });
  final List<int> orders;
  final bool rejectedRollback;
}

CalledNumberMergeResult mergeCalledNumbersMonotonic({
  required String? sessionId,
  required String? localSessionId,
  required List<int> localOrders,
  required List<int> incomingOrders,
  required bool preferIncomingIfNewerSocket,
  int? socketMaxOrder,
  int? incomingMaxOrder,
}) {
  if (sessionId != localSessionId) {
    return CalledNumberMergeResult(
      orders: List<int>.from(incomingOrders),
      rejectedRollback: false,
    );
  }

  final localMax = localOrders.isEmpty
      ? 0
      : localOrders.reduce((a, b) => a > b ? a : b);
  final incomingMax = incomingMaxOrder ??
      (incomingOrders.isEmpty
          ? 0
          : incomingOrders.reduce((a, b) => a > b ? a : b));
  final socketMax = socketMaxOrder ?? localMax;

  if (incomingMax < localMax ||
      (preferIncomingIfNewerSocket && socketMax > incomingMax)) {
    // Keep local (socket-forward) truth.
    return CalledNumberMergeResult(
      orders: List<int>.from(localOrders),
      rejectedRollback: true,
    );
  }

  return CalledNumberMergeResult(
    orders: List<int>.from(incomingOrders),
    rejectedRollback: false,
  );
}
```

Wire into HTTP replace / canonical apply for called numbers **same session** only. Map `orders` back to full called-number models by selecting from the richer of local vs incoming lists by order key (implement carefully using existing model equality — read `live_called_number_sync.dart` / controller replace API and adapt).

- [ ] **Step 3: Run**

```bash
flutter test test/live_called_number_monotonic_test.dart test/live_called_number_sync_test.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/src/features/games/presentation/utils/live_called_number_monotonic.dart \
  lib/src/features/games/presentation/controllers/live_called_numbers_controller.dart \
  lib/src/features/games/presentation/screens/live_game_orchestration.dart \
  test/live_called_number_monotonic_test.dart
git commit -m "$(cat <<'EOF'
fix(live): keep called numbers monotonic within a session

EOF
)"
```

---

### Task 3: Pause preparing poll during sync

**Files:**
- Modify: `lib/src/features/games/presentation/controllers/live_transition_controller.dart`

- [ ] **Step 1: Before scheduling preparing poll tick / catch-up refetch, skip when**

```dart
if (host.controllers.realtime.resumeSyncInFlight ||
    host.controllers.realtime.canonicalRefetchInFlight) {
  return;
}
```

- [ ] **Step 2: Add unit test if poll logic is extractable; else extend `live_ready_transition_lock_test.dart` with a documented skip callback**

- [ ] **Step 3: Run lock tests + Commit**

```bash
flutter test test/live_ready_transition_lock_test.dart
git add lib/src/features/games/presentation/controllers/live_transition_controller.dart
git commit -m "$(cat <<'EOF'
fix(live): pause preparing poll while resume or canonical refetch runs

EOF
)"
```

---

## Plan 5 self-review

| Spec | Task |
|---|---|
| app_resume during terminal ignored | Task 1 |
| Same-session no rollback | Task 2 |
| Socket wins over stale HTTP | Task 2 |
| No prepare poll overlap | Task 3 |
| No backend | Constraint |
