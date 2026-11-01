# Game State Machine & Screen Transitions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate the 9-second transition lock mid-game refetch glitch, optimize `LiveGameContentSwitcher` duration and rendering for 60fps stutter-free phase transitions, harden Chain Game round-reset boundaries, and wire `LiveResumeSyncCoordinator` throttling.

**Architecture:** 
1. Update `shouldClearReadyTransitionLock()` in `live_ready_transition_lock.dart` to release the lock immediately when `pinnedGame` advances to active play statuses (`playing`, `checking`, `winnerWindow`).
2. Optimize `LiveGameContentSwitcher` animation duration from 450ms to 240ms with smooth cubic crossfade and zero vertical slide offset.
3. Wire `LiveResumeSyncCoordinator.shouldThrottleResumeSync()` into `LiveRealtimeController`.
4. Verify with TDD unit tests and full test suite passes on both mobile and backend.

**Tech Stack:** Flutter, Dart, Riverpod, NestJS, Socket.IO, flutter_test.

---

### Task 1: Transition Lock Clearing Logic Hardening (TDD)

**Files:**
- Modify: `lib/src/features/games/presentation/utils/live_ready_transition_lock.dart`
- Test: `test/features/games/live_ready_transition_lock_test.dart`

- [ ] **Step 1: Write failing unit tests for active play status clearing in `live_ready_transition_lock_test.dart`**

Add unit tests in `test/features/games/live_ready_transition_lock_test.dart`:
```dart
    test('clears when pinnedGame enters PLAYING even without operations', () {
      final lock = _lock();
      final pinnedPlaying = _game(sessionId: 'a', status: GameStatus.playing);

      expect(
        shouldClearReadyTransitionLock(
          lock: lock,
          operations: null,
          pinnedGame: pinnedPlaying,
          now: _now,
        ),
        isTrue,
      );
    });

    test('clears when pinnedGame enters CHECKING or WINNER_WINDOW', () {
      final lock = _lock();
      final pinnedChecking = _game(sessionId: 'a', status: GameStatus.checking);
      final pinnedWinnerWindow = _game(sessionId: 'a', status: GameStatus.winnerWindow);

      expect(
        shouldClearReadyTransitionLock(
          lock: lock,
          operations: null,
          pinnedGame: pinnedChecking,
          now: _now,
        ),
        isTrue,
      );
      expect(
        shouldClearReadyTransitionLock(
          lock: lock,
          operations: null,
          pinnedGame: pinnedWinnerWindow,
          now: _now,
        ),
        isTrue,
      );
    });
```

- [ ] **Step 2: Run test to observe failure**

Run:
```powershell
flutter test test/features/games/live_ready_transition_lock_test.dart
```
Confirm the new tests fail as expected.

- [ ] **Step 3: Implement fix in `live_ready_transition_lock.dart`**

In `lib/src/features/games/presentation/utils/live_ready_transition_lock.dart`:
Update `shouldClearReadyTransitionLock`:
```dart
  if (pinnedGame != null && pinnedGame.sessionId == lockSessionId) {
    if (isTransitionLockTerminalStatus(pinnedGame.status) ||
        pinnedGame.status == GameStatus.playing ||
        pinnedGame.status == GameStatus.checking ||
        pinnedGame.status == GameStatus.winnerWindow) {
      return true;
    }
  }
```

- [ ] **Step 4: Run test to verify pass**

Run:
```powershell
flutter test test/features/games/live_ready_transition_lock_test.dart
```
Verify all tests pass.

- [ ] **Step 5: Commit changes**

Commit with conventional commits:
```bash
git commit -m "fix(games): clear ready transition lock on active play status transition"
```

---

### Task 2: Content Switcher Performance & Smoothness Tuning

**Files:**
- Modify: `lib/src/features/games/presentation/widgets/live_game_content_switcher.dart`

- [ ] **Step 1: Optimize duration and transition curve in `live_game_content_switcher.dart`**

In `lib/src/features/games/presentation/widgets/live_game_content_switcher.dart`:
Change duration to 240ms and remove the vertical slide offset to prevent layout jumping:
```dart
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: hasCompletedInitialPaint
          ? const Duration(milliseconds: 240)
          : Duration.zero,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        if (!hasCompletedInitialPaint) {
          return child;
        }
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey<String>(transitionKey),
        child: child,
      ),
    );
  }
```

- [ ] **Step 2: Verify existing widget tests**

Run:
```powershell
flutter test test/features/games/
```
Verify no layout or widget rendering regressions.

- [ ] **Step 3: Commit changes**

Commit with conventional commits:
```bash
git commit -m "perf(games): optimize live game content switcher transition to 240ms crossfade"
```

---

### Task 3: LiveResumeSyncCoordinator Throttling Integration

**Files:**
- Modify: `lib/src/features/games/application/controllers/live_realtime_controller.dart`
- Test: `test/features/games/live_resume_sync_coordinator_test.dart`

- [ ] **Step 1: Wire coordinator throttling into `LiveRealtimeController.shouldRunResumeSync`**

In `lib/src/features/games/application/controllers/live_realtime_controller.dart`:
Check `host.controllers.resumeSync.shouldThrottleResumeSync()` when evaluating unforced resume sync triggers.

- [ ] **Step 2: Run test suite**

Run:
```powershell
flutter test test/features/games/live_resume_sync_coordinator_test.dart
```

- [ ] **Step 3: Commit changes**

Commit with conventional commits:
```bash
git commit -m "feat(sync): wire live resume sync coordinator throttling into realtime controller"
```

---

### Task 4: Full Suite Verification & Backend Compatibility Check

- [ ] **Step 1: Mobile full test suite run**

Run:
```powershell
flutter test
```
Confirm all 638+ tests pass with 0 failures.

- [ ] **Step 2: Backend test suite run**

Run:
```powershell
cd D:\PROJECTS\bingo\Friends-bingo-backend
npm test
```
Confirm all 73 suites pass with 0 failures.
