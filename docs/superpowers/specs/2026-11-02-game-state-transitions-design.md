# Game State Machine & Screen Transitions Design Document

**Date:** 2026-11-02  
**Status:** Approved  
**Topic:** Stream 2 — Game State Machine, Screen Transitions, Transition Lock Optimization & Resume Sync  
**Repositories:** `friends-bingo-mobile` (primary), `Friends-bingo-backend` (synchronization alignment)  

---

## 1. Overview & Objectives

In the Friends Bingo architecture, live games transition through multiple phases:
`Registration Open` $\rightarrow$ `Preparing to Play` $\rightarrow$ `Live Playing` $\rightarrow$ `Checking` $\rightarrow$ `Winner Window` $\rightarrow$ `Review / Terminal`.

During in-depth code audit of this lifecycle, four critical performance and stability issues were identified:
1. **Transition Lock 9-Second Timeout Refetch Race:** When a game enters `preparingToPlay`, a `ReadyTransitionLock` is established with a 9-second timeout (`kReadyTransitionLockTimeout`). When the game successfully transitions to `playing` via socket (`game:status_changed`), the lock was not marked cleared because `shouldClearReadyTransitionLock` only checked for terminal statuses (`cancelled`, `finished`, `noWinner`) or canonical HTTP `operations.liveGame` arrival. Consequently, after 9 seconds, `expireReadyTransitionLockIfNeeded()` would trigger `refetchCanonicalImmediate(reason: 'ready_transition_lock_expired')` right during early ball calling (balls 3–5), creating unnecessary network traffic, UI rebuilds, and potential sync indicator flickering mid-game.
2. **Content Switcher 450ms Latency & Double-Buffering:** In `LiveGameContentSwitcher`, transition duration between registration and live play was 450ms with a vertical slide tween. During this window, both the full registration widget subtree (cartela grid, buy dock, pricing cards) and the full live play subtree (called balls strip, sticky headers, cartela list) were concurrently kept alive and rendered, causing frame drops on mid-range devices.
3. **Chain Game Inter-Round Pattern Boundary:** In Chain Games, the `sessionId` remains identical across rounds. When transitioning between rounds (`chain:round_finished` $\rightarrow$ 20s pause $\rightarrow$ `chain:round_started`), round 1 winner pattern highlights must not bleed into round 2 before the new round's ball draw commences.
4. **Resume Sync Throttling & Deduplication:** `LiveResumeSyncCoordinator.shouldThrottleResumeSync()` existed with unit tests but was never wired into `LiveRealtimeController`. Furthermore, `AppBackgroundResumeGate.evaluateFullResumeSync()` cleared its backgrounded timestamp on the first query, creating potential edge cases for secondary callers.

### Goals
- Ensure `ReadyTransitionLock` is released immediately when `pinnedGame` advances to active play (`playing`, `checking`, `winnerWindow`), completely preventing the 9-second mid-game refetch glitch.
- Reduce `LiveGameContentSwitcher` animation duration from 450ms to a crisp 240ms with smooth cross-fade, eliminating double-buffer frame drops.
- Ensure Chain Game round transitions cleanly reset round-specific pattern states.
- Connect `LiveResumeSyncCoordinator` directly into `LiveRealtimeController`'s resume orchestration.
- Maintain 100% test passing across the test suite (638+ tests).

---

## 2. Detailed Technical Design

### 2.1 Transition Lock Clearing Predicate Hardening
In [`lib/src/features/games/presentation/utils/live_ready_transition_lock.dart`](file:///d:/PROJECTS/bingo/friends-bingo-mobile/lib/src/features/games/presentation/utils/live_ready_transition_lock.dart):
Currently:
```dart
  if (pinnedGame != null &&
      pinnedGame.sessionId == lockSessionId &&
      isTransitionLockTerminalStatus(pinnedGame.status)) {
    return true;
  }
```
Update to:
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
**Invariant:** If the pinned session has already progressed past the preparing phase into active gameplay, the ready transition lock has completed its purpose and must be released immediately.

### 2.2 Content Switcher Performance Tuning
In [`lib/src/features/games/presentation/widgets/live_game_content_switcher.dart`](file:///d:/PROJECTS/bingo/friends-bingo-mobile/lib/src/features/games/presentation/widgets/live_game_content_switcher.dart):
Currently:
```dart
    return AnimatedSwitcher(
      duration: hasCompletedInitialPaint
          ? const Duration(milliseconds: 450)
          : Duration.zero,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        if (!hasCompletedInitialPaint) {
          return child;
        }
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<String>(transitionKey),
        child: child,
      ),
    );
```
Optimization:
- Reduce duration to `Duration(milliseconds: 240)` for an instant, responsive feel.
- Use `Curves.easeOutCubic` for switch-in and `Curves.easeInCubic` for switch-out.
- Eliminate the vertical slide offset (`Offset(0, 0.03)` $\rightarrow$ `Offset.zero` or pure `FadeTransition`) so the header and body don't jump vertically during phase transitions.

### 2.3 Chain Game Inter-Round Reset
In [`lib/src/features/games/application/controllers/live_chain_game_coordinator.dart`](file:///d:/PROJECTS/bingo/friends-bingo-mobile/lib/src/features/games/application/controllers/live_chain_game_coordinator.dart) and [`lib/src/features/games/presentation/screens/live_game_orchestration.dart`](file:///d:/PROJECTS/bingo/friends-bingo-mobile/lib/src/features/games/presentation/screens/live_game_orchestration.dart):
- Ensure that when a chain round finishes and starts the inter-round break, winner cartela numbers are captured in `_review.sessionWinnerCartelaNumbers` for the winner banner, while `_chainBingoArmedAfterCalledCount` is set to the current called ball count.
- When `chain:round_started` fires for round $N+1$, ensure `claimEligibilityRevision` is bumped and any transient round-specific pattern caches are cleared so round $N$ patterns do not evaluate as active wins.

### 2.4 LiveResumeSyncCoordinator Integration
In [`lib/src/features/games/application/controllers/live_realtime_controller.dart`](file:///d:/PROJECTS/bingo/friends-bingo-mobile/lib/src/features/games/application/controllers/live_realtime_controller.dart):
- Utilize `LiveResumeSyncCoordinator.shouldThrottleResumeSync()` inside `shouldRunResumeSync()` to prevent redundant rapid resume sync executions within the throttle window (default 750ms).

---

## 3. Testing & Verification Plan

1. **Unit Tests for Transition Lock:**
   - Add test cases in `test/features/games/live_ready_transition_lock_test.dart`:
     - Test that `shouldClearReadyTransitionLock` returns `true` when `pinnedGame` has status `playing`.
     - Test that `shouldClearReadyTransitionLock` returns `true` when `pinnedGame` has status `checking`.
     - Test that `shouldClearReadyTransitionLock` returns `true` when `pinnedGame` has status `winnerWindow`.
2. **Content Switcher Tests:**
   - Verify `LiveGameContentSwitcher` renders correctly and completes transitions with 240ms duration.
3. **Full Regression Testing:**
   - Run `flutter test test/features/games/live_ready_transition_lock_test.dart`.
   - Run `flutter test test/features/games/live_resume_sync_coordinator_test.dart`.
   - Run entire Flutter test suite: `flutter test`.
   - Run NestJS backend test suite: `npm test` in `Friends-bingo-backend`.

