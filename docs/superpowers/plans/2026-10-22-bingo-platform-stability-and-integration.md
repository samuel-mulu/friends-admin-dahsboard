# Bingo Platform Stability, End-to-End Integration & Robust Concurrency Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the real-money Bingo platform into an ultra-reliable, bug-free, and high-concurrency production system across the NestJS backend (`FriendsBingo-backend`) and Flutter mobile app (`friends-bingo-mobile`) by eliminating the 5 core game-breaking issues (Bingo claim latency/freezing, auto-advance failure after winner window, deposit errors, card loss/clipping on registration, and game rule/combo evaluator discrepancies) with zero added fluff or unnecessary features.

**Architecture:** 
- **Backend (NestJS + Prisma + PostgreSQL + Redis):** Streamline `claimBingo` into a single fast-path transaction (<300ms) with deferred non-critical fanouts; repair `combo-solver` parallel line preference for latest called number; guarantee atomic `finalizeWinnerWindow` fail-safe completion; and implement idempotent single-pass deposit verification.
- **Mobile (Flutter + Riverpod + Socket.IO):** Eliminate socket event dropping in `_reconcileActiveClaimSocket` for instant (<1s) claim verdicts; fix `_advanceToNextGame` to auto-transition on winner window closure and round completion; correct `_reconcileBulkRegistration` and `reconcileCartelaSnapshot` to guarantee zero card loss across multiple registration bursts; eliminate layout clipping via responsive auto-fitting grid cells; and polish UI headers and status badges.

**Tech Stack:** NestJS 11, Prisma ORM, PostgreSQL, Socket.IO, Redis, Flutter 3.x, Riverpod, Dart 3.

## Global Constraints
- **Zero New Features:** Do not introduce unrequested features or rewrite intact business logic; focus exclusively on stability, concurrency safety, edge-case remediation, and visual elegance.
- **Sub-Second Claim Guarantee:** Bingo claim verdict (valid, invalid, or blocked) MUST display to the player in $\le 1$ second upon confirmation.
- **Zero Card Loss:** All cards registered across single or multiple registration actions MUST be preserved and rendered accurately.
- **Multi-Winner Window Integrity:** The winner window MUST remain open for its configured duration to allow simultaneous co-winners, dividing the prize equally upon closing.
- **Strict Session Isolation:** No card from an unconfirmed or historical session may appear in active gameplay.
- **Responsive Layout:** Live cartela cards must never show RenderFlex yellow/black stripe overflow or text clipping on any mobile DPI or text scale factor.

---

### Task 1: Fix Mobile Real-Time Dropped Events & Enable Instant Sub-Second Bingo Claim UI

**Files:**
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/presentation/screens/live_game_orchestration.dart:3650-3810`
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/presentation/screens/live_game_called_numbers.dart:250-390`
- Test: `d:/FILES/SELF/BINGO/friends-bingo-mobile/test/features/games/live_game_bingo_claim_test.dart`

**Interfaces:**
- Consumes: Socket events `game:bingo_valid`, `game:bingo_invalid`, `game:winner_window_started`, `game:winner_window_joined`.
- Produces: `_reconcileActiveClaimSocket` returns `false` or directly applies the terminal verdict to `attempt` and `_myCartelas`, clearing `isClaiming` in under 1 second without waiting for an ambiguous HTTP GET recovery.

- [ ] **Step 1: Write failing unit test for real-time claim resolution**
Write test asserting that when `game:bingo_valid` or `game:bingo_invalid` arrives over socket while a claim attempt is in-flight, the cartela status is immediately updated to `winner` or `blocked` and `claimingCartelaIds` is cleared immediately without requiring a secondary HTTP round-trip.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/games/live_game_bingo_claim_test.dart`
Expected: FAIL (currently suppressed by `_reconcileActiveClaimSocket` returning `true` and doing early `return`).

- [ ] **Step 3: Update `live_game_orchestration.dart` to apply socket payload immediately**
In `_reconcileActiveClaimSocket`, when an active attempt matches the payload:
1. Immediately resolve the attempt locally using `status` from payload (`valid` -> `winner`, `invalid` -> `blocked`).
2. Update `_myCartelas` with `_cn.applyPresentedTerminalCartela(...)`.
3. Clear `_cn.claimingCartelaIds.remove(cartelaId)` and `pendingClaimCartelaIds.remove(cartelaId)`.
4. Trigger sound and celebration if winner; display clear snackbar/banner if blocked.
5. Return `false` so the event handler completes full state synchronization rather than skipping UI rendering.

- [ ] **Step 4: Streamline `_submitBingoClaim` in `live_game_called_numbers.dart`**
1. Reduce any artificial pre-claim wait timer.
2. Race the HTTP POST with incoming socket events: if socket event arrives first, avoid re-running conflicting state mutations when HTTP POST completes.
3. On HTTP response, if already resolved via socket, gracefully acknowledge and exit in $< 1$s.

- [ ] **Step 5: Run tests to verify pass**
Run: `flutter test test/features/games/live_game_bingo_claim_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**
```bash
git add lib/src/features/games/presentation/screens/live_game_orchestration.dart lib/src/features/games/presentation/screens/live_game_called_numbers.dart test/features/games/live_game_bingo_claim_test.dart
git commit -m "fix(games): resolve bingo claim verdict instantly via realtime socket events"
```

---

### Task 2: Backend Fast-Path Single-Transaction Bingo Claim & Non-Blocking Side Effects

**Files:**
- Modify: `d:/FILES/SELF/BINGO/FriendsBingo-backend/src/bingo-claims/bingo-claims.service.ts:350-550`
- Test: `d:/FILES/SELF/BINGO/FriendsBingo-backend/src/bingo-claims/bingo-claims-claim-latency.spec.ts`

**Interfaces:**
- Consumes: `POST /games/sessions/:id/bingo-claims` with `claimAttemptId`, `gameCartelaId`.
- Produces: Verdict payload returned to client in $< 300\text{ ms}$; asynchronous non-blocking dispatch of operations cache invalidation and notification fanouts.

- [ ] **Step 1: Write integration/latency test for `claimBingo`**
Assert that `claimBingo` executes in a single database transaction, completes within 300ms, and defers cache broadcast outside the critical transaction path.

- [ ] **Step 2: Run test to verify baseline performance**
Run: `npm test -- src/bingo-claims/bingo-claims-claim-latency.spec.ts`

- [ ] **Step 3: Consolidate `acceptClaimAttempt` and `createAutoValidatedClaim` in `bingo-claims.service.ts`**
1. Eliminate the two-step serial transaction model. Perform row locking (`lockGameSessionRow`), cartela ownership verification, pattern evaluation against called numbers, and claim creation in **one single atomic transaction**.
2. Avoid double-reading `GameCartela` and `GameSession`.
3. Wrap all non-critical side effects (`runDeferredClaimStructuralRefresh`, `auditLogService`, push notifications) in `setImmediate()` or asynchronous fire-and-forget background workers.
4. Return HTTP response payload immediately upon transaction commit.

- [ ] **Step 4: Run test to verify it passes**
Run: `npm test -- src/bingo-claims/bingo-claims-claim-latency.spec.ts`
Expected: PASS with execution time $< 300\text{ ms}$.

- [ ] **Step 5: Commit**
```bash
git add src/bingo-claims/bingo-claims.service.ts src/bingo-claims/bingo-claims-claim-latency.spec.ts
git commit -m "perf(bingo-claims): optimize claim validation into single fast-path transaction"
```

---

### Task 3: Backend Game Rules & Combo Solver Alignment (Parallel Lines & Latest Ball Preference)

**Files:**
- Modify: `d:/FILES/SELF/BINGO/FriendsBingo-backend/src/game-rules/combo/combo-solver.ts:416-435`
- Modify: `d:/FILES/SELF/BINGO/FriendsBingo-backend/src/game-rules/combo/combo-rule.evaluator.ts:42-65`
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/presentation/utils/cartela_marked_pattern_evaluator.dart:140-175`
- Test: `d:/FILES/SELF/BINGO/FriendsBingo-backend/test/game-rules/combo-parallel-lines.spec.ts`
- Test: `d:/FILES/SELF/BINGO/friends-bingo-mobile/test/features/games/cartela_pattern_evaluator_test.dart`

**Interfaces:**
- Consumes: `calledNumbers`, `latestCalledNumber`, `ComboPattern`.
- Produces: `completedByLatestNumber == true` whenever ANY valid combination of patterns satisfies the winning condition and includes the latest called number.

- [ ] **Step 1: Write failing test for combo solver with parallel line constraint**
Create a test case where a cartela has two valid winning combinations for a parallel line rule: combination A does not contain the newest ball, but combination B does. Assert that `solveComboWithParallelLineConstraint` selects combination B and returns `completedByLatestNumber == true`.

- [ ] **Step 2: Run test to verify failure**
Run: `npm test -- test/game-rules/combo-parallel-lines.spec.ts`
Expected: FAIL (currently picks `combinations[0]` blindly).

- [ ] **Step 3: Update `combo-solver.ts` in NestJS backend**
Update `solveComboWithParallelLineConstraint`:
```typescript
export function solveComboWithParallelLineConstraint(
  combo: ComboPattern,
  instances: PatternInstance[],
  options?: SolveComboOptions,
): ComboSolveResult {
  const combinations = findAllWithParallelLineConstraint(combo, instances);
  const selectedPatterns = pickPreferredCombination(
    combinations,
    options?.preferLatestCalledNumber,
  );
  if (!selectedPatterns) {
    return { isWinner: false, selectedPatterns: [] };
  }
  return { isWinner: true, selectedPatterns };
}
```
Pass `options: { preferLatestCalledNumber: latestCalledNumber }` in `ComboRuleEvaluator`.

- [ ] **Step 4: Update Flutter client evaluator in `cartela_marked_pattern_evaluator.dart`**
In `CartelaPatternUiResult.evaluate()`:
Instead of only checking `best.coveredCells`, evaluate if `latestCalledNumber` is contained in *any* completed winning pattern combination. Only set `isLateClaim = true` if no winning combination contains the newest ball.

- [ ] **Step 5: Run tests on backend and mobile**
Run backend: `npm test -- test/game-rules/combo-parallel-lines.spec.ts`
Run mobile: `flutter test test/features/games/cartela_pattern_evaluator_test.dart`
Expected: PASS on both.

- [ ] **Step 6: Commit**
```bash
git add src/game-rules/combo/combo-solver.ts src/game-rules/combo/combo-rule.evaluator.ts test/game-rules/combo-parallel-lines.spec.ts
git commit -m "fix(game-rules): prioritize latest called ball in combo parallel line solver"
```

---

### Task 4: Fix Auto/Manual Win Winner Window Auto-Advance to Next Game / Round

**Files:**
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/presentation/screens/live_game_orchestration.dart:5050-5210`
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/presentation/widgets/winner_cartela_dialog.dart:860-885`
- Modify: `d:/FILES/SELF/BINGO/FriendsBingo-backend/src/bingo-claims/winner-window-finalizer.service.ts:60-105`
- Test: `d:/FILES/SELF/BINGO/friends-bingo-mobile/test/features/games/live_game_winner_window_advance_test.dart`

**Interfaces:**
- Consumes: Winner window expiration or user dismissal of winner window dialog.
- Produces: Seamless transition of the live screen from `WINNER_WINDOW` / `FINISHED` into the next active session or round (`READY` / `PLAYING`).

- [ ] **Step 1: Write test for winner window auto-advance on dialog close**
Assert that when `showWinnerCartelaDialog` completes while session is still finalizing, `_advanceToNextGame` polls `operations/current` and advances to the next session or round rather than aborting with `finishedWithoutTarget`.

- [ ] **Step 2: Run test to verify failure**
Run: `flutter test test/features/games/live_game_winner_window_advance_test.dart`
Expected: FAIL.

- [ ] **Step 3: Modify `_advanceToNextGame` in `live_game_orchestration.dart`**
1. Expand the terminal status check: allow `_advanceToNextGame` to proceed if `currentGame.status == GameStatus.winnerWindow` and `_winnerWindowExpired` is true.
2. If `nextGame` is not yet available in the first `_syncOperationsSnapshot`, schedule an exponential backoff retry (every 1s up to 5s) instead of dropping the advance.
3. Handle Chain Game round transition: when round finishes, advance immediately to the inter-round pause countdown and load the next round's cartelas.

- [ ] **Step 4: Ensure fail-safe finalization in backend `winner-window-finalizer.service.ts`**
In `WinnerWindowFinalizerService.tick()`, if `openNextAutoQueueRegistrationInTransaction` fails, ensure the current session status is still unconditionally marked `FINISHED`, winners are paid out, and `emitSessionFinished` is triggered so clients receive the terminal event.

- [ ] **Step 5: Run tests to verify pass**
Run: `flutter test test/features/games/live_game_winner_window_advance_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**
```bash
git add lib/src/features/games/presentation/screens/live_game_orchestration.dart lib/src/features/games/presentation/widgets/winner_cartela_dialog.dart
git commit -m "fix(games): auto-advance to next round upon winner window close"
```

---

### Task 5: Eliminate Cartela Registration Loss on Rapid Multiple Submissions

**Files:**
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/data/games_repository.dart:460-475`
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/presentation/utils/merge_registered_cartelas.dart:38-55`
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/presentation/controllers/live_registration_controller.dart:165-210`
- Test: `d:/FILES/SELF/BINGO/friends-bingo-mobile/test/features/games/cartela_multi_registration_test.dart`

**Interfaces:**
- Consumes: Multiple rapid `registerCartelasForSlot` requests for the same session.
- Produces: `myCartelas` preserves ALL successfully registered cards across bursts without any dropped or missing cards.

- [ ] **Step 1: Write test for multiple rapid cartela registrations**
Simulate registering 2 cartelas in batch 1, immediately followed by registering 2 cartelas in batch 2 before batch 1's silent background refetch returns. Assert that `myCartelas` contains all 4 cartelas.

- [ ] **Step 2: Run test to verify failure**
Run: `flutter test test/features/games/cartela_multi_registration_test.dart`
Expected: FAIL (batch 2 cartelas are dropped by `reconcileCartelaSnapshot` in batch 1's remote apply).

- [ ] **Step 3: Fix `_reconcileBulkRegistration` in `games_repository.dart`**
Ensure `myCartelas` from the decoded server payload is preserved when constructing the final `BulkRegisterResult`:
```dart
return BulkRegisterResult(
  successes: successByCartelaId.values.toList(growable: false),
  failures: failuresByCartelaId.values.toList(growable: false),
  myCartelas: result.myCartelas ?? successByCartelaId.values.toList(growable: false),
);
```

- [ ] **Step 4: Update `reconcileCartelaSnapshot` in `merge_registered_cartelas.dart`**
Modify `reconcileCartelaSnapshot` so it does NOT drop cards that exist in `current` but are missing in `incoming`:
```dart
List<GameCartelaModel> reconcileCartelaSnapshot({
  required List<GameCartelaModel> current,
  required List<GameCartelaModel> incoming,
}) {
  if (incoming.isEmpty) return current;
  final incomingById = <String, GameCartelaModel>{
    for (final cartela in incoming) cartela.id: cartela,
  };
  final result = <String, GameCartelaModel>{};
  
  // 1. Keep authoritative incoming cartelas
  for (final cartela in incoming) {
    result[cartela.id] = cartela;
  }
  
  // 2. Preserve any local registered cartelas that haven't been cancelled
  for (final currentCartela in current) {
    if (!result.containsKey(currentCartela.id)) {
      if (currentCartela.status != GameCartelaStatus.cancelled) {
        result[currentCartela.id] = currentCartela;
      }
    } else {
      result[currentCartela.id] = preferAuthoritativeCartela(
        current: currentCartela,
        incoming: result[currentCartela.id]!,
      );
    }
  }
  return result.values.toList();
}
```

- [ ] **Step 5: Run test to verify pass**
Run: `flutter test test/features/games/cartela_multi_registration_test.dart`
Expected: PASS (all 4 cards preserved).

- [ ] **Step 6: Commit**
```bash
git add lib/src/features/games/data/games_repository.dart lib/src/features/games/presentation/utils/merge_registered_cartelas.dart test/features/games/cartela_multi_registration_test.dart
git commit -m "fix(registration): preserve all cartelas across multiple rapid registration bursts"
```

---

### Task 6: Stop Unexpected Mid-Game Cartela Popups, Duplication & Grid Clipping

**Files:**
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/presentation/screens/live_game_registration.dart:375-405`
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/presentation/screens/live_game_screen.dart:2690-2750`
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/presentation/widgets/live_cartela_card.dart:130-225`
- Test: `d:/FILES/SELF/BINGO/friends-bingo-mobile/test/features/games/live_cartela_grid_layout_test.dart`

**Interfaces:**
- Consumes: Registered cartelas and live game screen layout constraints.
- Produces: Strict session ID gating preventing historical card injection; fluid responsive grid eliminating RenderFlex overflow/clipping.

- [ ] **Step 1: Write widget test for live cartela card responsive layout**
Assert that on 320dp width with 1.3x accessibility text scale factor, `LiveCartelaCard` renders without RenderFlex overflow exceptions.

- [ ] **Step 2: Run test to verify failure**
Run: `flutter test test/features/games/live_cartela_grid_layout_test.dart`
Expected: FAIL (RenderFlex overflowed by X pixels).

- [ ] **Step 3: Enforce strict session scoping in `live_game_registration.dart`**
1. In `_notifyRegistered()` and `_scheduleAutoOpenIfNeeded()`, verify that `cartela.gameId == _effectiveSessionId`. Drop any cartela with missing or mismatched session ID.
2. If `_game.status` is `PLAYING` or `CHECKING` or `WINNER_WINDOW`, suppress all automatic registration dialogs or bottom sheets.

- [ ] **Step 4: Refactor `LiveCartelaCard` and grid aspect ratio for zero clipping**
1. In `live_game_screen.dart`, calculate `childAspectRatio` dynamically based on screen height and width using `LayoutBuilder` rather than hardcoded magic numbers (0.72).
2. Inside `LiveCartelaCard`:
   - Replace rigid Column spacing with flexible constraints and `FittedBox` on the 5x5 numbers grid.
   - Ensure the card header (number, badge, BINGO button) never pushes the 5x5 grid below the card boundary.
   - Ensure `BingoClaimButton` maintains a minimum 44x36 tap target while scaling gracefully.

- [ ] **Step 5: Run layout test to verify pass**
Run: `flutter test test/features/games/live_cartela_grid_layout_test.dart`
Expected: PASS with 0 layout overflows.

- [ ] **Step 6: Commit**
```bash
git add lib/src/features/games/presentation/screens/live_game_registration.dart lib/src/features/games/presentation/screens/live_game_screen.dart lib/src/features/games/presentation/widgets/live_cartela_card.dart
git commit -m "fix(ui): eliminate card clipping and suppress unexpected mid-game registration popups"
```

---

### Task 7: Single-Pass Idempotent Deposit Verification & Polling Recovery

**Files:**
- Modify: `d:/FILES/SELF/BINGO/FriendsBingo-backend/src/deposits/deposits.service.ts:100-240`
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/wallet/presentation/controllers/deposit_controller.dart:400-500`
- Test: `d:/FILES/SELF/BINGO/FriendsBingo-backend/src/deposits/deposit-verification-attempt.concurrency.spec.ts`
- Test: `d:/FILES/SELF/BINGO/friends-bingo-mobile/test/features/wallet/deposit_controller_test.dart`

**Interfaces:**
- Consumes: Deposit transaction reference (Telebirr / CBE).
- Produces: Unambiguous verification state handling; elimination of false `ALREADY_USED` errors on network retry; automatic wallet balance refresh on approval.

- [ ] **Step 1: Write backend concurrency test for duplicate deposit submission**
Assert that submitting the same `(provider, transactionRef)` concurrently by the same user does not throw `P2002` conflict or `ALREADY_USED`, but returns the active verification attempt or existing approved deposit.

- [ ] **Step 2: Run test to verify failure**
Run: `npm test -- src/deposits/deposit-verification-attempt.concurrency.spec.ts`

- [ ] **Step 3: Update `deposits.service.ts` in NestJS**
1. In `createDeposit`: before invoking external verification, insert or lock the deposit row with `status: PENDING`.
2. On duplicate attempt by the *same user*:
   - If `status == APPROVED`: return the approved deposit and update wallet snapshot.
   - If `status == PENDING`: return the active verification status with `retryAfterSeconds` without error.
   - If owned by *another user*: reject with `ALREADY_USED`.
3. Standardize reference normalization between CBE URLs (extract transaction ID) and Telebirr SMS bodies.

- [ ] **Step 4: Update `deposit_controller.dart` in Flutter**
1. Separate transient network timeouts from permanent deposit rejections.
2. In `catch (error)` in `submitDeposit`: if error is connectivity or timeout, transition to `verificationInProgress` and poll `getActiveVerificationAttempt()` rather than showing "Rejected".
3. When `wallet:updated` arrives, immediately invalidate `myWalletProvider` and transition deposit UI to `approved`.

- [ ] **Step 5: Run tests on backend and mobile**
Run backend: `npm test -- src/deposits/deposit-verification-attempt.concurrency.spec.ts`
Run mobile: `flutter test test/features/wallet/deposit_controller_test.dart`
Expected: PASS on both.

- [ ] **Step 6: Commit**
```bash
git add src/deposits/deposits.service.ts lib/src/features/wallet/presentation/controllers/deposit_controller.dart
git commit -m "fix(deposits): implement single-pass idempotent verification and resilient retry recovery"
```

---

### Task 8: End-to-End System Verification, Load Testing & Concurrency Readiness

**Files:**
- Test: `d:/FILES/SELF/BINGO/FriendsBingo-backend/src/bingo-claims/bingo-claims-concurrency-verification.postgres.spec.ts`
- Test: `d:/FILES/SELF/BINGO/friends-bingo-mobile/test/features/games/live_game_orchestration_test.dart`

**Interfaces:**
- Consumes: Complete game lifecycle from registration -> ball draw -> simultaneous claims -> winner window -> payout -> next game.
- Produces: Verified 0-error execution log across both backend and client under simulated concurrency.

- [ ] **Step 1: Run complete backend test suite**
Run: `npm test` in `FriendsBingo-backend`
Expected: All suites passing, 0 concurrency deadlocks, 0 unhandled promise rejections.

- [ ] **Step 2: Run complete Flutter test suite**
Run: `flutter test` in `friends-bingo-mobile`
Expected: All unit and widget tests passing, 0 layout overflow exceptions.

- [ ] **Step 3: Verify build clean in both repositories**
Backend: `npm run build`
Mobile: `flutter analyze`
Expected: 0 errors, 0 warnings.

- [ ] **Step 4: Commit**
```bash
git commit --allow-empty -m "chore(platform): end-to-end verification passing across backend and mobile"
```

---

## 🚀 Scalability & Future Upgrade Recommendations (High Player Counts)

1. **Redis Socket.IO Adapter Deployment:**
   - Configure `@socket.io/redis-adapter` with Redis cluster to enable horizontal scaling of backend NestJS instances across multiple CPU cores/nodes without losing real-time room broadcasts.
2. **Read-Heavy Query Caching:**
   - Cache `GET /games/operations/current` and `GET /cartelas/catalog` in Redis with 300ms–500ms TTL and atomic key invalidation on session transitions to reduce database CPU usage during high player surges.
3. **Database Index Optimization:**
   - Verify composite indexes on `GameCartela(gameSessionId, userId, status)`, `CalledNumber(gameSessionId, order)`, and `BingoClaim(gameSessionId, status)` to ensure query plans use Index Scans rather than Bitmap Heap Scans during claim peaks.
4. **Client-Side Virtualized Rendering:**
   - Keep `RepaintBoundary` strictly isolated around individual cartela cards and ball announcement strips so that auto-call ticks only repaint the called ball strip rather than triggering whole-screen Flutter build trees.
