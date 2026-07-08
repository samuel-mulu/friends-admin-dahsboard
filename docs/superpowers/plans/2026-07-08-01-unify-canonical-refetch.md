# Unify Canonical Refetch Ownership Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.  
> **Parent index:** [2026-07-08-live-stabilization-index.md](./2026-07-08-live-stabilization-index.md)  
> **Plan:** 1 of 6 — do this first.

**Goal:** Make `LiveRealtimeController` the only owner of canonical refetch scheduling so socket handlers and transition poll cannot race two debounce queues.

**Architecture:** Thin screen wrappers delegate to `_realtime.scheduleCanonicalRefetch` / `requestTerminalCanonicalRefetch` / `refetchCanonicalImmediate`. Delete duplicate screen timers and pending flags. Keep `_loadInitialState` as the apply entry used by the controller drain path.

**Tech Stack:** Flutter, Riverpod, existing `LiveRealtimeController`, `flutter_test`.

**No backend changes.**

---

## File map

| File | Responsibility |
|---|---|
| `lib/.../controllers/live_realtime_controller.dart` | Sole debounce + terminal coalesce + drain → `host.runInitialLoad` |
| `lib/.../screens/live_game_screen.dart` | Remove duplicate refetch fields; keep host wiring |
| `lib/.../screens/live_game_orchestration.dart` | Replace local refetch impl with delegators |
| `lib/.../screens/live_game_realtime.dart` | Call wrappers (unchanged call sites OK if wrappers delegate) |
| `lib/.../screens/live_game_registration.dart` | Same |
| `lib/.../screens/live_game_called_numbers.dart` | Same |
| `test/live_refetch_owner_test.dart` | Prove controller owns schedule/immediate; screen helpers thin |

---

### Task 1: Failing test — controller schedule is the owner API

**Files:**
- Create: `test/live_refetch_owner_test.dart`
- Modify (later): `lib/src/features/games/presentation/screens/live_game_orchestration.dart`
- Modify (later): `lib/src/features/games/presentation/screens/live_game_screen.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Documents the refetch ownership contract for Plan 1.
/// After migration, screen code must not keep parallel debounce timers.
void main() {
  test('LiveRealtimeController owns schedule + terminal + immediate APIs', () async {
    final controllerSource = await File(
      'lib/src/features/games/presentation/controllers/live_realtime_controller.dart',
    ).readAsString();
    for (final method in const [
      'void scheduleCanonicalRefetch(',
      'void requestTerminalCanonicalRefetch(',
      'Future<void> refetchCanonicalImmediate(',
      'void cancelCanonicalRefetchDebounce(',
      'Future<void> syncLatest(',
    ]) {
      expect(
        controllerSource.contains(method),
        isTrue,
        reason: 'Missing owner API: $method',
      );
    }
  });

  test('screen must not declare duplicate refetch timers after migration', () async {
    final screenSource = await File(
      'lib/src/features/games/presentation/screens/live_game_screen.dart',
    ).readAsString();
    expect(
      screenSource.contains('Timer? _canonicalRefetchDebounceTimer'),
      isFalse,
      reason: 'Duplicate screen debounce timer must be deleted; use LiveRealtimeController',
    );
    expect(
      screenSource.contains('Future<void>? _refetchCanonicalLoop'),
      isFalse,
      reason: 'Duplicate drain loop must live only on LiveRealtimeController',
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
cd D:/FILES/SELF/BINGO/friends-admin-dahsboard
flutter test test/live_refetch_owner_test.dart
```

Expected: FAIL — `_canonicalRefetchDebounceTimer` / `_refetchCanonicalLoop` still present in `live_game_screen.dart`.

- [ ] **Step 3: Do not implement yet — commit the failing test only if your TDD policy allows red commits; otherwise keep uncommitted until Step 5 of Task 2**

---

### Task 2: Delegate screen schedule helpers to `_realtime`

**Files:**
- Modify: `lib/src/features/games/presentation/screens/live_game_orchestration.dart` (methods around `_cancelCanonicalRefetchDebounce` / `_scheduleCanonicalRefetch` / `_refetchCanonicalImmediate` / `_refetchCanonical` / `_drainRefetchCanonicalQueue`)
- Modify: `lib/src/features/games/presentation/screens/live_game_screen.dart` (fields ~226–236)

- [ ] **Step 1: Replace screen schedule methods with thin delegates**

Replace the bodies of:

- `_cancelCanonicalRefetchDebounce`
- `_scheduleCanonicalRefetch`
- `_refetchCanonicalImmediate`
- `_refetchCanonical`

with:

```dart
void _cancelCanonicalRefetchDebounce() {
  _realtime.cancelCanonicalRefetchDebounce();
}

void _scheduleCanonicalRefetch({
  bool wallet = false,
  String? registrationSessionId,
  bool includeCalledNumbers = false,
  bool includeMyCartelas = false,
  String reason = 'screen_schedule',
}) {
  _realtime.scheduleCanonicalRefetch(
    reason: reason,
    wallet: wallet,
    registrationSessionId: registrationSessionId,
    includeCalledNumbers: includeCalledNumbers,
    includeMyCartelas: includeMyCartelas,
  );
}

Future<void> _refetchCanonicalImmediate({
  bool wallet = false,
  String? registrationSessionId,
  bool includeCalledNumbers = true,
  bool includeMyCartelas = false,
  String reason = 'screen_immediate',
}) {
  return _realtime.refetchCanonicalImmediate(
    reason: reason,
    wallet: wallet,
    registrationSessionId: registrationSessionId,
    includeCalledNumbers: includeCalledNumbers,
    includeMyCartelas: includeMyCartelas,
  );
}

Future<void> _refetchCanonical({
  bool wallet = false,
  bool includeCalledNumbers = false,
  bool includeMyCartelas = false,
  String reason = 'screen_refetch',
}) {
  return _realtime.refetchCanonical(
    reason: reason,
    wallet: wallet,
    includeCalledNumbers: includeCalledNumbers,
    includeMyCartelas: includeMyCartelas,
  );
}
```

- [ ] **Step 2: Delete the old local debounce/drain implementation**

Delete local:

- `_drainRefetchCanonicalQueue` screen copy (controller already has `drainRefetchCanonicalQueue`)
- any code that sets `_pendingRefetchWallet` / `_canonicalRefetchDebounceTimer` on the screen

Confirm controller `drainRefetchCanonicalQueue` already calls `host.runInitialLoad(...)`. If screen drain had unique logging, port `LiveRealtimeDebug.refetch` calls into the controller drain only if missing — do not leave a second drain.

- [ ] **Step 3: Remove duplicate fields from `live_game_screen.dart`**

Delete:

```dart
Timer? _canonicalRefetchDebounceTimer;
bool _canonicalRefetchIncludeWallet = false;
bool _canonicalRefetchIncludeRegistrationState = false;
bool _canonicalRefetchIncludeCalledNumbers = false;
bool _canonicalRefetchIncludeMyCartelas = false;
String? _canonicalRefetchRegistrationSessionId;
bool _pendingRefetchWallet = false;
bool _pendingRefetchIncludeCalledNumbers = false;
bool _pendingRefetchIncludeMyCartelas = false;
Future<void>? _refetchCanonicalLoop;
```

Also remove getters/usages clearing those fields in `dispose` / load-reset (~648–649). Use `_realtime.cancelCanonicalRefetchDebounce()` in dispose instead of cancelling a screen timer.

Remove unused `_canonicalRefetchDebounce` getter if it only served the deleted timer.

- [ ] **Step 4: Run ownership test + existing reconnect tests**

```bash
flutter test test/live_refetch_owner_test.dart test/live_reconnect_current_state_sync_test.dart test/live_game_realtime_cleanup_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add test/live_refetch_owner_test.dart \
  lib/src/features/games/presentation/screens/live_game_screen.dart \
  lib/src/features/games/presentation/screens/live_game_orchestration.dart \
  lib/src/features/games/presentation/controllers/live_realtime_controller.dart
git commit -m "$(cat <<'EOF'
fix(live): route canonical refetch through LiveRealtimeController only

EOF
)"
```

---

### Task 3: Point READY transition paths at terminal/controller APIs with reasons

**Files:**
- Modify: `lib/src/features/games/presentation/screens/live_game_realtime.dart`
- Modify: `lib/src/features/games/presentation/screens/live_game_orchestration.dart` (call sites that used immediate refetch for terminal)
- Modify: `lib/src/features/games/presentation/controllers/live_transition_controller.dart` (verify it already uses controller; add reason strings if missing)

- [ ] **Step 1: Add explicit reasons at high-traffic call sites**

Examples:

```dart
_scheduleCanonicalRefetch(
  reason: 'operation_updated',
);

_scheduleCanonicalRefetch(
  reason: 'registration_metrics',
  registrationSessionId: sessionId,
);

await _refetchCanonicalImmediate(
  reason: 'status_changed_non_terminal',
  includeCalledNumbers: true,
);
```

For CANCELLED / FINISHED / terminal status (placeholders for Plan 3 wiring): keep calling immediate for now but use reason prefixes:

```dart
await _refetchCanonicalImmediate(
  reason: 'game_cancelled',
  wallet: !_isGuest,
  includeCalledNumbers: true,
);
```

Do **not** switch to `requestTerminalCanonicalRefetch` yet unless Plan 3 is implemented in the same session — Plan 3 owns that migration. If you are chaining plans without pause, jump to Plan 3 Task that replaces these with `requestTerminalCanonicalRefetch`.

- [ ] **Step 2: Run transition lock + cleanup tests**

```bash
flutter test test/live_ready_transition_lock_test.dart test/live_game_realtime_cleanup_test.dart
```

Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/src/features/games/presentation/screens/live_game_realtime.dart \
  lib/src/features/games/presentation/screens/live_game_orchestration.dart
git commit -m "$(cat <<'EOF'
chore(live): tag canonical refetch call sites with explicit reasons

EOF
)"
```

---

### Task 4: Plan 1 verification

- [ ] **Step 1: Grep for leftover screen pending flags**

```bash
rg "_canonicalRefetchDebounceTimer|_pendingRefetchWallet|_drainRefetchCanonicalQueue" lib/src/features/games/presentation/screens
```

Expected: no matches (except possibly comments). Delegators `_scheduleCanonicalRefetch` may remain as thin wrappers — that is OK.

- [ ] **Step 2: Run broader live suite**

```bash
flutter test test/live_reconnect_current_state_sync_test.dart \
  test/live_resume_sync_test.dart \
  test/live_game_realtime_cleanup_test.dart \
  test/live_refetch_owner_test.dart
```

Expected: PASS.

---

## Plan 1 self-review

| Spec gap item | Task |
|---|---|
| Dual refetch piping | Tasks 1–2 |
| Delete screen schedule fields | Task 2 |
| Single owner via controller | Tasks 2–3 |
| Backend untouched | Constraint |

No placeholders remaining.
