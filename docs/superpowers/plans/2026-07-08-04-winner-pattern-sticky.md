# Sticky Winner Pattern & Immediate Winner UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.  
> **Parent index:** [2026-07-08-live-stabilization-index.md](./2026-07-08-live-stabilization-index.md)  
> **Plan:** 4 of 6 — after Plan 3.

**Goal:** Open winner UI immediately from `bingo_valid` / `winner_window_*` payloads, keep completed patterns sticky, and let winner-results polling enrich without clearing patterns.

**Architecture:** Stop clearing pattern cache in `beginPostGameSummaryAdvance`. Clear only on session change or `clearSessionScopedReviewState`. Dialog auto-show can use sticky claim/window data before HTTP results are ready.

**Tech Stack:** Flutter, `WinnerCartelaDisplayCache` / `live_review_controller.dart`, `flutter_test`.

**No backend changes.**

---

## File map

| File | Responsibility |
|---|---|
| `lib/.../controllers/live_review_controller.dart` | Advance without pattern clear; dialog readiness |
| `lib/.../utils/winner_cartela_live_display.dart` | Sticky store / merge rules |
| `lib/.../screens/live_game_orchestration.dart` | bingo_valid / winner_window store patterns |
| `test/winner_pattern_sticky_test.dart` | Clear policy tests |
| `test/winner_cartela_dialog_test.dart` | Existing — extend for immediate show |
| `test/winner_cartela_live_display_test.dart` | Existing display cache |

---

### Task 1: Pattern clear policy (TDD)

**Files:**
- Create: `lib/src/features/games/presentation/utils/winner_pattern_clear_policy.dart`
- Create: `test/winner_pattern_sticky_test.dart`

- [ ] **Step 1: Failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/winner_pattern_clear_policy.dart';

void main() {
  test('advance begin must not clear patterns', () {
    expect(
      shouldClearWinnerPatterns(
        WinnerPatternClearReason.postGameAdvanceBegin,
      ),
      isFalse,
    );
  });

  test('session changed clears patterns', () {
    expect(
      shouldClearWinnerPatterns(WinnerPatternClearReason.sessionChanged),
      isTrue,
    );
  });

  test('canonical without patterns does not clear', () {
    expect(
      shouldClearWinnerPatterns(
        WinnerPatternClearReason.canonicalMissingPatterns,
      ),
      isFalse,
    );
  });

  test('complete replacement may clear then store', () {
    expect(
      shouldClearWinnerPatterns(
        WinnerPatternClearReason.completePatternReplacement,
      ),
      isTrue,
    );
  });
}
```

- [ ] **Step 2: Run FAIL**

```bash
flutter test test/winner_pattern_sticky_test.dart
```

- [ ] **Step 3: Implement**

```dart
enum WinnerPatternClearReason {
  postGameAdvanceBegin,
  sessionChanged,
  canonicalMissingPatterns,
  completePatternReplacement,
  clearSessionScopedReview,
}

bool shouldClearWinnerPatterns(WinnerPatternClearReason reason) {
  return switch (reason) {
    WinnerPatternClearReason.postGameAdvanceBegin => false,
    WinnerPatternClearReason.canonicalMissingPatterns => false,
    WinnerPatternClearReason.sessionChanged => true,
    WinnerPatternClearReason.completePatternReplacement => true,
    WinnerPatternClearReason.clearSessionScopedReview => true,
  };
}
```

- [ ] **Step 4: PASS + Commit**

```bash
flutter test test/winner_pattern_sticky_test.dart
git add lib/src/features/games/presentation/utils/winner_pattern_clear_policy.dart \
  test/winner_pattern_sticky_test.dart
git commit -m "$(cat <<'EOF'
feat(live): define sticky winner pattern clear policy

EOF
)"
```

---

### Task 2: Remove clear from `beginPostGameSummaryAdvance`

**Files:**
- Modify: `lib/src/features/games/presentation/controllers/live_review_controller.dart`
- Modify: `test/winner_cartela_live_display_test.dart` or new widget/controller test

- [ ] **Step 1: Source-contract failing test**

```dart
test('beginPostGameSummaryAdvance does not clear winner patterns', () async {
  final source = await File(
    'lib/src/features/games/presentation/controllers/live_review_controller.dart',
  ).readAsString();
  final start = source.indexOf('void beginPostGameSummaryAdvance');
  final snippet = source.substring(start, start + 500);
  expect(snippet.contains('clearFinishedReviewVisualState'), isFalse);
  expect(snippet.contains('winnerCartelaDisplay.clear'), isFalse);
});
```

- [ ] **Step 2: Run FAIL (currently clears)**

- [ ] **Step 3: Change advance method**

```dart
void beginPostGameSummaryAdvance() {
  if (!postGameSummaryReviewActive || postGameSummaryAdvancing) {
    return;
  }

  winnerCartelaDialogVisible = false;
  // Do NOT clear winnerCartelaDisplay here — wait for sessionChanged apply.
  finishTransitionTimer?.cancel();
  finishTransitionTimer = null;
  postGameSummaryCountdownTicker?.cancel();
  postGameSummaryCountdownTicker = null;
  postGameSummaryHoldBypassed = true;
  postGameSummaryAdvancing = true;
  host.markNeedsBuild();
}
```

Keep `clearFinishedReviewVisualState()` available for `clearPostGameSummaryHold` / session-scoped clears that run when the new session actually applies.

Gate clears with policy:

```dart
void clearFinishedReviewVisualState({
  WinnerPatternClearReason reason =
      WinnerPatternClearReason.clearSessionScopedReview,
}) {
  if (!shouldClearWinnerPatterns(reason)) {
    return;
  }
  winnerCartelaDisplay.clear();
}
```

- [ ] **Step 4: Run**

```bash
flutter test test/winner_pattern_sticky_test.dart \
  test/winner_cartela_live_display_test.dart \
  test/winner_cartela_dialog_test.dart \
  test/finished_review_ui_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/games/presentation/controllers/live_review_controller.dart \
  test/winner_pattern_sticky_test.dart
git commit -m "$(cat <<'EOF'
fix(live): keep winner patterns sticky across post-game advance

EOF
)"
```

---

### Task 3: Winner-results enrich without wiping patterns

**Files:**
- Modify: `lib/src/features/games/presentation/utils/winner_cartela_live_display.dart` (`applySessionResult` / store paths)
- Modify: orchestration/review fetch that applies results

- [ ] **Step 1: Test merge behavior**

```dart
test('applySessionResult without patterns leaves sticky claim patterns', () {
  final cache = WinnerCartelaDisplayCache();
  cache.storePatterns(
    cartelaId: 'c1',
    patterns: const [
      /* use existing CompletedPattern fixture from sibling tests */
    ],
  );
  // Apply a session result that has empty/missing patterns — must not wipe.
  cache.applySessionResult(/* result with empty patterns */);
  expect(cache.hasPatternsFor('c1'), isTrue);
});
```

Adapt to the real cache API names found in `winner_cartela_live_display.dart` (read file before coding). If method names differ, write the same assertion against the public API that exists.

- [ ] **Step 2: FAIL then fix `applySessionResult` to skip clear when incoming patterns empty**

```dart
// Pseudocode matching real types:
if (incomingPatterns.isEmpty && existingPatterns.isNotEmpty) {
  // enrich metadata only; keep patterns
  return;
}
```

- [ ] **Step 3: Run winner display tests PASS + Commit**

```bash
flutter test test/winner_cartela_live_display_test.dart test/session_winner_results_for_display_test.dart
git add lib/src/features/games/presentation/utils/winner_cartela_live_display.dart
git commit -m "$(cat <<'EOF'
fix(live): enrich winner results without clearing sticky patterns

EOF
)"
```

---

### Task 4: Immediate dialog eligibility from socket payload

**Files:**
- Modify: `lib/src/features/games/presentation/controllers/live_review_controller.dart` (auto-show gate)
- Modify: `lib/src/features/games/presentation/screens/live_game_orchestration.dart` (`_onBingoValid`, `_onWinnerWindowEvent`)
- Test: `test/winner_cartela_dialog_test.dart`

- [ ] **Step 1: Add pure readiness helper**

```dart
bool winnerDialogReadyForImmediateShow({
  required bool summaryOrWinnerWindowVisible,
  required bool hasStickyWinnerPayload,
  required bool winnerResultsLoaded,
}) {
  if (!summaryOrWinnerWindowVisible) {
    return false;
  }
  // Socket payload is enough; HTTP results optional.
  return hasStickyWinnerPayload || winnerResultsLoaded;
}
```

Test both sticky-only true and results-only true.

- [ ] **Step 2: On bingo_valid / winner_window handlers (already store patterns) — call maybe-auto-show without waiting for HTTP**

Ensure store happens **before** any canonical refetch schedule:

```dart
// order:
// 1) normalize
// 2) storePatterns / storeClaimSnapshot
// 3) apply winner window state
// 4) maybeAutoShow dialog
// 5) optional debounced canonical (enrich only)
```

- [ ] **Step 3: Run dialog tests**

```bash
flutter test test/winner_cartela_dialog_test.dart test/winner_cartela_live_display_test.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/src/features/games/presentation/controllers/live_review_controller.dart \
  lib/src/features/games/presentation/screens/live_game_orchestration.dart \
  test/winner_cartela_dialog_test.dart
git commit -m "$(cat <<'EOF'
fix(live): show winner dialog immediately from socket sticky payload

EOF
)"
```

---

## Plan 4 self-review

| Spec | Task |
|---|---|
| Pattern flicker | Tasks 1–2 |
| Canonical lacks pattern data | Task 3 |
| Immediate winner UI | Task 4 |
| No backend | Constraint |
