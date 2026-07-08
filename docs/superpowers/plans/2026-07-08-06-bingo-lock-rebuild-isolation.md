# BINGO Lock Rebuild Isolation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.  
> **Parent index:** [2026-07-08-live-stabilization-index.md](./2026-07-08-live-stabilization-index.md)  
> **Plan:** 6 of 6 — after Plan 1 (may parallel Plans 4–5).

**Goal:** Auto-call / BINGO countdown lock updates rebuild only claim buttons (and strip), not the full cartela list page.

**Architecture:** Introduce a small `ValueNotifier<bool>` (or existing listenable) for `isBingoClaimCountdownLocked`. Wrap cartela cards in `RepaintBoundary`. Cartela list listens to cartela data changes only; buttons listen to lock notifier.

**Tech Stack:** Flutter widgets, `next_ball_countdown.dart`, `live_cartela_card.dart`, `flutter_test`.

**No backend changes. No UI redesign — structure only.**

---

## File map

| File | Responsibility |
|---|---|
| `lib/.../utils/next_ball_countdown.dart` | Lock derivation (existing) |
| `lib/.../controllers/live_countdown_controller.dart` | Expose / update lock notifier |
| `lib/.../widgets/live_cartela_card.dart` | Button listens to lock; RepaintBoundary |
| `lib/.../screens/live_game_screen.dart` or cartela list builder | Stop parent setState for lock-only ticks |
| `test/bingo_lock_rebuild_isolation_test.dart` | Prove list does not rebuild on lock-only |

---

### Task 1: Lock notifier on countdown controller (TDD)

**Files:**
- Modify: `lib/src/features/games/presentation/controllers/live_countdown_controller.dart`
- Create: `test/bingo_lock_rebuild_isolation_test.dart`

- [ ] **Step 1: Write failing test for notifier updates without list dirty flag**

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bingo lock notifier can flip without touching cartela list version', () {
    final lock = ValueNotifier<bool>(false);
    var cartelaListVersion = 0;

    void onLockTick(bool locked) {
      // Lock-only path must not bump list version.
      lock.value = locked;
    }

    onLockTick(true);
    expect(lock.value, isTrue);
    expect(cartelaListVersion, 0);

    onLockTick(false);
    expect(lock.value, isFalse);
    expect(cartelaListVersion, 0);
  });
}
```

This encodes the contract; next steps bind real controller.

- [ ] **Step 2: Add `ValueNotifier<bool> bingoClaimLocked` to `LiveCountdownController`**

```dart
final ValueNotifier<bool> bingoClaimLocked = ValueNotifier<bool>(false);

void updateBingoClaimLocked(bool value) {
  if (bingoClaimLocked.value == value) {
    return;
  }
  bingoClaimLocked.value = value;
}

@override
void dispose() {
  bingoClaimLocked.dispose();
  // existing dispose...
}
```

On countdown tick that previously called `host.markNeedsBuild()` solely for lock changes, call `updateBingoClaimLocked(...)` instead (keep full rebuild only when registration/next-ball label text must update elsewhere — strip can have its own listener).

- [ ] **Step 3: Run**

```bash
flutter test test/bingo_lock_rebuild_isolation_test.dart test/next_ball_countdown_test.dart test/bingo_claim_hold_test.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/src/features/games/presentation/controllers/live_countdown_controller.dart \
  test/bingo_lock_rebuild_isolation_test.dart
git commit -m "$(cat <<'EOF'
feat(live): add bingo claim lock ValueNotifier on countdown controller

EOF
)"
```

---

### Task 2: Cartela card listens to lock notifier

**Files:**
- Modify: `lib/src/features/games/presentation/widgets/live_cartela_card.dart`
- Modify: parent that builds cartela list in `live_game_screen.dart` / called_numbers mixin builder

- [ ] **Step 1: Locate BINGO button enabled logic** (uses `isBingoClaimCountdownLocked` or equivalent)

- [ ] **Step 2: Wrap button (or card action row) in `ValueListenableBuilder<bool>`**

```dart
RepaintBoundary(
  child: LiveCartelaCard(
    // existing props without lock bool if removable
    bingoLockListenable: countdown.bingoClaimLocked,
    // ...
  ),
)
```

Inside card:

```dart
ValueListenableBuilder<bool>(
  valueListenable: bingoLockListenable,
  builder: (context, locked, child) {
    return BingoButton(
      enabled: !locked && canClaimOtherwise,
      onPressed: onClaim,
    );
  },
)
```

Remove lock-driven `setState` from the parent list builder for countdown ticks.

- [ ] **Step 3: Widget test — build two cards, flip notifier, assert list State build count unchanged**

Use a counter `StatefulWidget` parent:

```dart
testWidgets('lock notifier does not rebuild cartela list state', (tester) async {
  final lock = ValueNotifier<bool>(false);
  var listBuilds = 0;

  await tester.pumpWidget(
    MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) {
          listBuilds++;
          return Column(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: lock,
                builder: (_, locked, __) => Text('locked:$locked'),
              ),
              // stand-in for cards
              const Text('cartela-list'),
            ],
          );
        },
      ),
    ),
  );

  final buildsAfterFirstPump = listBuilds;
  lock.value = true;
  await tester.pump();
  expect(listBuilds, buildsAfterFirstPump);
});
```

Adapt to real `LiveCartelaCard` once props updated — keep assertion that parent list build count does not rise on lock flip.

- [ ] **Step 4: Run**

```bash
flutter test test/bingo_lock_rebuild_isolation_test.dart \
  test/live_cartela_card_claim_test.dart \
  test/bingo_claim_hold_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/games/presentation/widgets/live_cartela_card.dart \
  lib/src/features/games/presentation/screens/live_game_screen.dart \
  lib/src/features/games/presentation/screens/live_game_called_numbers.dart \
  test/bingo_lock_rebuild_isolation_test.dart
git commit -m "$(cat <<'EOF'
fix(live): isolate bingo lock rebuilds from cartela list

EOF
)"
```

---

### Task 3: Called-number strip update without full page setState

**Files:**
- Modify: strip widget / `CalledNumbersStrip` and orchestration apply path
- Prefer existing strip listenable if present; otherwise add `ValueNotifier` for last called / count

- [ ] **Step 1: Ensure `_onNumberCalled` marks strip dirty via controller API instead of `setState` on entire screen when only strip+lock change**

If `_markCalledNumbersPanelDirty()` already exists, use it and avoid wrapping large trees.

- [ ] **Step 2: Add/extend test that number_called schedule patch does not require cartela list rebuild**

Reuse isolation test style.

- [ ] **Step 3: Run live call sync + claim tests**

```bash
flutter test test/live_called_number_sync_test.dart \
  test/live_cartela_card_claim_test.dart \
  test/bingo_lock_rebuild_isolation_test.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/src/features/games/presentation
git commit -m "$(cat <<'EOF'
perf(live): narrow number_called UI updates to strip and claim buttons

EOF
)"
```

---

### Task 4: Final production suite gate

- [ ] **Step 1: Run full live-related suite**

```bash
flutter test test/live_*.dart test/bingo_*.dart test/winner_*.dart test/next_ball_*.dart test/number_called_*.dart test/finished_review_ui_test.dart test/session_winner_results_for_display_test.dart test/auto_call_apply_dedup_test.dart
```

Expected: PASS.

- [ ] **Step 2: Confirm backend untouched**

```bash
cd D:/FILES/SELF/BINGO/FriendsBingo
git status --short
```

Expected: clean (or only unrelated user changes). Live work must not appear here.

- [ ] **Step 3: Update index checklist in `2026-07-08-live-stabilization-index.md` Definition of Done (check boxes)**

- [ ] **Step 4: Commit docs**

```bash
git add docs/superpowers/plans/2026-07-08-live-stabilization-index.md
git commit -m "$(cat <<'EOF'
docs(live): mark live stabilization plan suite complete

EOF
)"
```

---

## Plan 6 self-review

| Spec | Task |
|---|---|
| BINGO lock does not rebuild full cartela list | Tasks 1–2 |
| Auto-call busy scroll | Tasks 2–3 |
| Final DoD + backend freeze check | Task 4 |
