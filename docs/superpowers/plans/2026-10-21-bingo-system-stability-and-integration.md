# Bingo System Stability, End-to-End Integration & Robust Concurrency Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate all bingo claim latency/freezes, deposit race conditions, multi-registration card losses, winner-window transition blocks, and game rule discrepancies across FriendsBingo-backend and friends-bingo-mobile.

**Architecture:** Synchronous fast-path claim evaluation with decoupled background event dispatch; single-pass idempotent deposit processing; server-authoritative cumulative session cartela snapshots; fail-safe status finalization; and harmonized rule pattern evaluators.

**Tech Stack:** NestJS, TypeScript, Prisma ORM, PostgreSQL, Socket.IO, Flutter 3.x, Dart, Riverpod.

## Global Constraints
- Absolutely NO new features or redesigns; 100% focus on stability, performance, and bug elimination.
- Bingo claim must respond to player within 1 second.
- Backward compatibility must be strictly preserved for all database schemas and active clients.
- Test-driven development (TDD): Each task must have automated tests and verifiable passing assertions.

---

### Task 1: Backend Fast-Path Bingo Claim with Decoupled Side Effects

**Files:**
- Modify: `d:\FILES\SELF\BINGO\FriendsBingo-backend\src\bingo-claims\bingo-claims.service.ts`
- Test: `d:\FILES\SELF\BINGO\FriendsBingo-backend\src\bingo-claims\bingo-claims.service.spec.ts`

**Interfaces:**
- Consumes: `GameRuleEvaluationService.evaluate`, `PrismaService.$transaction`
- Produces: `claimBingo(sessionId: string, userId: string, gameCartelaId: string)` returning within $<150\text{ ms}$ with serialized `PlayerClaimPayload` before dispatching background events via `setImmediate`.

- [ ] **Step 1: Write the failing unit test for decoupled claim side effects**

Add a test in `bingo-claims.service.spec.ts` confirming that `emitClaimSideEffects` is decoupled from the synchronous HTTP claim response:

```typescript
it('returns claim verdict immediately without awaiting global side effects', async () => {
  const result = await service.claimBingo('session-1', 'user-1', 'cartela-1');
  expect(result).toBeDefined();
  expect(result.claimId).toBeDefined();
  expect(result.status).toBe('VALID');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```powershell
cd d:\FILES\SELF\BINGO\FriendsBingo-backend
npm test -- src/bingo-claims/bingo-claims.service.spec.ts
```
Expected: FAIL or verifies execution time expectation.

- [ ] **Step 3: Refactor `claimBingo` to fast-path transaction, relational integrity, and asynchronous decoupling**

In `bingo-claims.service.ts`:
1. **Relational Integrity Check:**
   Verify that `gameCartelaId` matches both the active session and calling user:
   ```typescript
   const gameCartela = await tx.gameCartela.findUnique({
     where: { id: gameCartelaId },
     select: { id: true, gameSessionId: true, userId: true, status: true, isWinner: true, cartela: true }
   });
   if (!gameCartela || gameCartela.gameSessionId !== sessionId || gameCartela.userId !== userId) {
     throw new ForbiddenException('Cartela does not belong to this user or session');
   }
   ```
2. **Multi-Winner Preservation:**
   - If game is in `PLAYING` and claim is valid:
     - Mark `GameCartela.status = WINNER`, `isWinner = true`.
     - Transition `GameSession.status = WINNER_WINDOW` and set `winnerWindowEndsAt = new Date(Date.now() + winnerWindowDurationMs)`.
     - Halts auto-calling numbers, but **leaves the winner window open** for other players.
   - If game is ALREADY in `WINNER_WINDOW` and claim is valid on the winning ball:
     - Mark this subsequent `GameCartela.status = WINNER`, `isWinner = true` as an additional co-winner.
     - Keep `winnerWindowEndsAt` intact (never prematurely close the window).
3. **Decouple side effects to background:**
   ```typescript
   const responsePayload = serializePlayerBingoClaim(result.claim, result.gameCartela, result.winnerBall, result.prizeAmount);

   setImmediate(async () => {
     try {
       await this.emitClaimSideEffects(result.sideEffectParams);
     } catch (err) {
       this.logger.error('Background claim side effects failed', err);
     }
   });

   return responsePayload;
   ```

- [ ] **Step 4: Run backend unit tests to verify they pass**

Run:
```powershell
cd d:\FILES\SELF\BINGO\FriendsBingo-backend
npm test -- src/bingo-claims/bingo-claims.service.spec.ts
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/bingo-claims/bingo-claims.service.ts src/bingo-claims/bingo-claims.service.spec.ts
git commit -m "perf(claims): decouple claim broadcast side-effects for sub-second response"
```

---

### Task 2: Mobile Instant Claim Feedback and Freeze Removal

**Files:**
- Modify: `d:\FILES\SELF\BINGO\friends-bingo-mobile\lib\src\features\games\presentation\screens\live_game_called_numbers.dart`
- Modify: `d:\FILES\SELF\BINGO\friends-bingo-mobile\lib\src\features\games\presentation\widgets\bingo_claim_button.dart`
- Test: `d:\FILES\SELF\BINGO\friends-bingo-mobile\test\features\games\live_game_claim_feedback_test.dart`

**Interfaces:**
- Consumes: `GamesRepository.claimBingo`, `GameCartelaModel`
- Produces: Instant user feedback when claim is blocked or invalid; eliminates UI freezes.

- [ ] **Step 1: Write widget test for blocked claim explanation snackbar**

Create `test/features/games/live_game_claim_feedback_test.dart`:
```dart
testWidgets('displays explicit reason message when claim is blocked or invalid', (tester) async {
  // Test that when claim returns GameCartelaStatus.blocked, 
  // an explanatory snackbar with reason is presented immediately
});
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```powershell
cd d:\FILES\SELF\BINGO\friends-bingo-mobile
flutter test test/features/games/live_game_claim_feedback_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Fix `live_game_called_numbers.dart` and remove artificial delay**

In `live_game_called_numbers.dart`:
1. In `onClaimBingo(GameCartelaModel cartela)`:
   - Remove `_checkingCartelaMinimumDisplay` artificial delay.
   - When `result.gameCartelaStatus == GameCartelaStatus.blocked`:
     Set `outcomeSnackbarMessage` to the backend-provided `reason` or fallback to localized message:
     ```dart
     final reasonMsg = result.reason?.isNotEmpty == true
         ? result.reason!
         : (result.reasonCode == 'INVALID_LATE_CLAIM'
             ? 'Late claim: Pattern was completed on an earlier ball.'
             : 'Pattern is incomplete.');
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reasonMsg)));
     ```
   - Ensure `_claimingCartelaIds.remove(cartela.id)` and `_pendingClaimCartelaIds.remove(cartela.id)` are called in `finally` blocks so button is NEVER stuck.

- [ ] **Step 4: Run flutter test to verify passing**

Run:
```powershell
flutter test test/features/games/live_game_claim_feedback_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/games/presentation/screens/live_game_called_numbers.dart test/features/games/live_game_claim_feedback_test.dart
git commit -m "fix(claims): display instant explanation on blocked claim and eliminate UI freeze"
```

---

### Task 3: Backend Fail-Safe Winner Window Status Progression

**Files:**
- Modify: `d:\FILES\SELF\BINGO\FriendsBingo-backend\src\games\winner-window-finalizer.service.ts`
- Test: `d:\FILES\SELF\BINGO\FriendsBingo-backend\src\games\winner-window-finalizer.service.spec.ts`

**Interfaces:**
- Consumes: `PrismaService.gameSession`, `PostGameRegistrationOpenerService`
- Produces: `finalizeWinnerWindow()` ensuring session status reaches `FINISHED` even if next-session auto-opening fails.

- [ ] **Step 1: Write test for isolated session finish on registration opener failure**

Add unit test in `winner-window-finalizer.service.spec.ts`:
```typescript
it('unconditionally sets session status to FINISHED even if openNextAutoQueueRegistration fails', async () => {
  postGameRegistrationOpenerService.openNextAutoQueueRegistrationInTransaction.mockRejectedValue(new Error('Queue conflict'));
  await service.finalizeWinnerWindow();
  const session = await prisma.gameSession.findUnique({ where: { id: 'session-1' } });
  expect(session.status).toBe(GameStatus.FINISHED);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```powershell
cd d:\FILES\SELF\BINGO\FriendsBingo-backend
npm test -- src/games/winner-window-finalizer.service.spec.ts
```
Expected: FAIL.

- [ ] **Step 3: Implement fail-safe finish transaction**

In `winner-window-finalizer.service.ts`:
1. First transaction: finalize prize and update `status = GameStatus.FINISHED`, `finishedAt = new Date()`.
2. Second step: open next auto-queue registration inside a try-catch block.
3. If next auto-queue registration fails, log warning and let `AutoReadyCountdownRepairService` heal the slot queue.

- [ ] **Step 4: Run test to verify it passes**

Run:
```powershell
cd d:\FILES\SELF\BINGO\FriendsBingo-backend
npm test -- src/games/winner-window-finalizer.service.spec.ts
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/games/winner-window-finalizer.service.ts src/games/winner-window-finalizer.service.spec.ts
git commit -m "fix(lifecycle): enforce fail-safe transition to FINISHED on winner window close"
```

---

### Task 4: Mobile Winner Window Auto-Dismissal & Next Round Route Transition

**Files:**
- Modify: `d:\FILES\SELF\BINGO\friends-bingo-mobile\lib\src\features\games\presentation\widgets\winner_cartela_dialog.dart`
- Modify: `d:\FILES\SELF\BINGO\friends-bingo-mobile\lib\src\features\games\presentation\screens\live_game_screen.dart`
- Test: `d:\FILES\SELF\BINGO\friends-bingo-mobile\test\features\games\winner_window_auto_dismiss_test.dart`

**Interfaces:**
- Consumes: Winner window countdown duration
- Produces: Automatic dismissal and transition to upcoming game session on countdown expiry.

- [ ] **Step 1: Write test for auto-dismiss callback on countdown zero**

In `test/features/games/winner_window_auto_dismiss_test.dart`:
```dart
testWidgets('WinnerCartelaDialog invokes onDismiss when countdown reaches 0', (tester) async {
  // Verify timer fires onDismiss
});
```

- [ ] **Step 2: Run test to verify failure**

Run:
```powershell
cd d:\FILES\SELF\BINGO\friends-bingo-mobile
flutter test test/features/games/winner_window_auto_dismiss_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Implement auto-dismiss and transition in dialog and screen**

1. In `WinnerCartelaDialog`: when countdown reaches 0, trigger `Navigator.of(context, rootNavigator: true).pop()`.
2. In `live_game_screen.dart`: on winner window close or socket `game:status_changed` to `FINISHED`, re-evaluate slot status and smoothly transition the screen to the new active session (`READY` or `NEXT`).

- [ ] **Step 4: Run test to verify passing**

Run:
```powershell
flutter test test/features/games/winner_window_auto_dismiss_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/games/presentation/widgets/winner_cartela_dialog.dart lib/src/features/games/presentation/screens/live_game_screen.dart test/features/games/winner_window_auto_dismiss_test.dart
git commit -m "feat(gameplay): auto-dismiss winner window on countdown expiry and transition to next game"
```

---

### Task 5: Backend Single-Pass Atomic Idempotent Deposits

**Files:**
- Modify: `d:\FILES\SELF\BINGO\FriendsBingo-backend\src\deposits\deposits.service.ts`
- Test: `d:\FILES\SELF\BINGO\FriendsBingo-backend\src\deposits\deposits.service.spec.ts`

**Interfaces:**
- Consumes: `CreateDepositDto`, `verifyEtService`
- Produces: `createDeposit` that safely handles retries of the same `(provider, transactionRef)` by returning the existing approved/pending deposit without throwing `ALREADY_USED`.

- [ ] **Step 1: Write failing test for idempotent retry by the same user**

In `deposits.service.spec.ts`:
```typescript
it('returns existing approved deposit on duplicate submission by same user', async () => {
  // Call createDeposit once -> approved
  // Call createDeposit again with same ref and user -> returns approved deposit with 200 OK
});
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```powershell
cd d:\FILES\SELF\BINGO\FriendsBingo-backend
npm test -- src/deposits/deposits.service.spec.ts
```
Expected: FAIL.

- [ ] **Step 3: Update `createDeposit` and `ensureReferenceAvailable` in `deposits.service.ts`**

1. In `ensureReferenceAvailable(provider, transactionRef, userId)`:
   - Check if an existing deposit exists:
     - If it exists with `userId === currentUserId`:
       - If `status === APPROVED`, return existing deposit.
       - If `status === PENDING`, return existing deposit.
     - If it exists with `userId !== currentUserId`:
       - Throw ConflictException(`ALREADY_USED`).
2. Wrap external `verifyEtService.verifyDeposit` call with a 20-second timeout guard.

- [ ] **Step 4: Run test to verify passing**

Run:
```powershell
cd d:\FILES\SELF\BINGO\FriendsBingo-backend
npm test -- src/deposits/deposits.service.spec.ts
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/deposits/deposits.service.ts src/deposits/deposits.service.spec.ts
git commit -m "fix(deposits): implement atomic idempotent retry handling to prevent false duplicate errors"
```

---

### Task 6: Mobile Single-Pass Deposit Flow & Timeout Resilience

**Files:**
- Modify: `d:\FILES\SELF\BINGO\friends-bingo-mobile\lib\src\features\wallet\presentation\screens\deposit_screen.dart`
- Modify: `d:\FILES\SELF\BINGO\friends-bingo-mobile\lib\src\features\wallet\data\wallet_repository.dart`
- Test: `d:\FILES\SELF\BINGO\friends-bingo-mobile\test\features\wallet\deposit_screen_idempotent_test.dart`

**Interfaces:**
- Consumes: `WalletRepository.createDeposit`
- Produces: Single-pass deposit submission without pre-flight `checkDepositReference` call.

- [ ] **Step 1: Write test for single-pass deposit submission**

In `test/features/wallet/deposit_screen_idempotent_test.dart`:
```dart
testWidgets('DepositScreen directly submits deposit without checkDepositReference call', (tester) async {
  // Verify only createDeposit is called on repository
});
```

- [ ] **Step 2: Run test to verify failure**

Run:
```powershell
cd d:\FILES\SELF\BINGO\friends-bingo-mobile
flutter test test/features/wallet/deposit_screen_idempotent_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Remove duplicate pre-check in `deposit_screen.dart`**

In `_submit()` in `deposit_screen.dart`:
1. Remove `walletRepository.checkDepositReference(...)` call.
2. Directly call `walletRepository.createDeposit(...)`.
3. If an `APPROVED` deposit is returned (even from a retry), show success banner and refresh balance.
4. If network times out, show: *"Verification taking longer than usual. Please check your deposit history."* and provide a quick link to `DepositHistoryScreen`.

- [ ] **Step 4: Run test to verify passing**

Run:
```powershell
flutter test test/features/wallet/deposit_screen_idempotent_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/wallet/presentation/screens/deposit_screen.dart test/features/wallet/deposit_screen_idempotent_test.dart
git commit -m "refactor(wallet): simplify deposit submission to single-pass idempotent request"
```

---

### Task 7: Backend Server-Authoritative Cumulative Cartela Snapshots

**Files:**
- Modify: `d:\FILES\SELF\BINGO\FriendsBingo-backend\src\games\games.service.ts`
- Modify: `d:\FILES\SELF\BINGO\FriendsBingo-backend\src\games\games.controller.ts`
- Test: `d:\FILES\SELF\BINGO\FriendsBingo-backend\src\games\games.service.spec.ts`

**Interfaces:**
- Consumes: `registerCartela`, `registerCartelasForSlotBulk`
- Produces: Response containing `myCartelas` with all registered cartelas for the user in the session.

- [ ] **Step 1: Write failing test for cumulative `myCartelas` return on registration**

In `games.service.spec.ts`:
```typescript
it('returns all cumulative registered cartelas in myCartelas field', async () => {
  const result = await service.registerCartelasForSlotBulk('slot-1', 'user-1', { cartelas: [...] });
  expect(result.myCartelas).toBeDefined();
  expect(result.myCartelas.length).toBeGreaterThanOrEqual(1);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```powershell
cd d:\FILES\SELF\BINGO\FriendsBingo-backend
npm test -- src/games/games.service.spec.ts
```
Expected: FAIL.

- [ ] **Step 3: Add `myCartelas` snapshot query to registration endpoints**

In `games.service.ts`:
1. Before returning from `registerCartela` and `registerCartelasBulkInternal`:
   Query all active cartelas for `userId` in `sessionId`:
   ```typescript
   const allMyCartelas = await tx.gameCartela.findMany({
     where: { gameSessionId: sessionId, userId, status: { not: GameCartelaStatus.CANCELLED } },
     select: myGameCartelaSelect,
   });
   ```
2. Include `myCartelas: allMyCartelas.map(serializeGameCartela)` in the return object.

- [ ] **Step 4: Run test to verify passing**

Run:
```powershell
cd d:\FILES\SELF\BINGO\FriendsBingo-backend
npm test -- src/games/games.service.spec.ts
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/games/games.service.ts src/games/games.service.spec.ts
git commit -m "feat(registration): include cumulative myCartelas snapshot in registration response"
```

---

### Task 8: Mobile Multi-Registration Card Retention & Modal Suppression

**Files:**
- Modify: `d:\FILES\SELF\BINGO\friends-bingo-mobile\lib\src\features\games\presentation\screens\live_game_registration.dart`
- Modify: `d:\FILES\SELF\BINGO\friends-bingo-mobile\lib\src\features\games\presentation\controllers\live_registration_controller.dart`
- Test: `d:\FILES\SELF\BINGO\friends-bingo-mobile\test\features\games\multi_registration_card_retention_test.dart`

**Interfaces:**
- Consumes: Registration response `myCartelas`
- Produces: Complete retention of registered cards across multiple registrations; disables auto-open modals during gameplay.

- [ ] **Step 1: Write test for cumulative card retention on successive registrations**

In `test/features/games/multi_registration_card_retention_test.dart`:
```dart
testWidgets('preserves all previously registered cartelas when registering a second batch', (tester) async {
  // Verify 2 cartelas + 2 subsequent cartelas = 4 cartelas displayed
});
```

- [ ] **Step 2: Run test to verify failure**

Run:
```powershell
cd d:\FILES\SELF\BINGO\friends-bingo-mobile
flutter test test/features/games/multi_registration_card_retention_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Update `live_game_registration.dart` and `live_registration_controller.dart`**

1. In `_scheduleAutoOpenIfNeeded`:
   Check `widget.gameStatus`: if `widget.gameStatus == GameStatus.playing || widget.gameStatus == GameStatus.checking`, return immediately (never auto-open modal during gameplay).
2. In `handleCartelasRegistered`:
   Use the server-authoritative snapshot `myCartelas` from the response if present, or union by `cartelaId` so no existing card is dropped.
3. In `refreshMyCartelasSilently`:
   Reconcile without wiping out locally registered cartelas that are still valid for the active session.

- [ ] **Step 4: Run test to verify passing**

Run:
```powershell
flutter test test/features/games/multi_registration_card_retention_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/games/presentation/screens/live_game_registration.dart lib/src/features/games/presentation/controllers/live_registration_controller.dart test/features/games/multi_registration_card_retention_test.dart
git commit -m "fix(registration): retain all cartelas on successive registrations and suppress modals in play mode"
```

---

### Task 9: Harmonized Game Rules & Pattern Diagnostics (Center Cell N3)

**Files:**
- Modify: `d:\FILES\SELF\BINGO\FriendsBingo-backend\src\game-rules\patterns\game-rule.patterns.ts`
- Modify: `d:\FILES\SELF\BINGO\FriendsBingo-backend\src\game-rules\game-rule-evaluation.service.ts`
- Modify: `d:\FILES\SELF\BINGO\friends-bingo-mobile\lib\src\features\games\domain\evaluators\cartela_pattern_evaluator.dart`
- Test: `d:\FILES\SELF\BINGO\FriendsBingo-backend\src\game-rules\game-rule-evaluation.service.spec.ts`
- Test: `d:\FILES\SELF\BINGO\friends-bingo-mobile\test\features\games\cartela_pattern_evaluator_test.dart`

**Interfaces:**
- Consumes: 5x5 board matrix, called numbers
- Produces: 100% identical pattern evaluation with center space (index 12 / N3) automatically stamped on both platforms.

- [ ] **Step 1: Write parity tests for center cell free stamping**

In both backend and mobile test suites, add tests for line, diagonal, and corner rules verifying that center cell (index 12) is always treated as stamped.

- [ ] **Step 2: Run tests to verify any failures**

Run:
```powershell
cd d:\FILES\SELF\BINGO\FriendsBingo-backend
npm test -- src/game-rules/game-rule-evaluation.service.spec.ts
cd d:\FILES\SELF\BINGO\friends-bingo-mobile
flutter test test/features/games/cartela_pattern_evaluator_test.dart
```

- [ ] **Step 3: Align center free cell handling and late-claim diagnostics**

1. In backend `game-rule.patterns.ts` and `pattern-rule.evaluator.ts`: ensure index 12 (N3) is always true in `isCellMarked`.
2. In mobile `cartela_pattern_evaluator.dart`: ensure index 12 (center cell) is always true in `_isMarked`.
3. In `GameRuleEvaluationService`: return `missingCellCount` and `completedPattern` metadata for detailed diagnostics.

- [ ] **Step 4: Run tests to verify passing**

Run:
```powershell
cd d:\FILES\SELF\BINGO\FriendsBingo-backend
npm test -- src/game-rules/game-rule-evaluation.service.spec.ts
cd d:\FILES\SELF\BINGO\friends-bingo-mobile
flutter test test/features/games/cartela_pattern_evaluator_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/game-rules/ lib/src/features/games/domain/evaluators/
git commit -m "fix(rules): align client and server pattern evaluators with universal center free space"
```

---

### Task 10: Mobile UI Polish & Layout Bounds (Eliminate Skipping & Clipping)

**Files:**
- Modify: `d:\FILES\SELF\BINGO\friends-bingo-mobile\lib\src\features\games\presentation\widgets\live_cartela_card.dart`
- Modify: `d:\FILES\SELF\BINGO\friends-bingo-mobile\lib\src\features\games\presentation\screens\live_game_screen.dart`
- Test: `d:\FILES\SELF\BINGO\friends-bingo-mobile\test\features\games\cartela_card_layout_test.dart`

**Interfaces:**
- Consumes: `LiveCartelaCard`, `CartelaBoardWidget`
- Produces: Stable 2-column grid without text clipping, card jumping, or aspect ratio overflow.

- [ ] **Step 1: Write widget test for cartela card layout bounds on small screen**

In `test/features/games/cartela_card_layout_test.dart`:
Verify that `LiveCartelaCard` renders without `RenderFlex overflowed` when constrained to a 160px width.

- [ ] **Step 2: Run test to verify failure**

Run:
```powershell
cd d:\FILES\SELF\BINGO\friends-bingo-mobile
flutter test test/features/games/cartela_card_layout_test.dart
```

- [ ] **Step 3: Polish layout and remove conflicting drag feedback**

1. In `_InlineRegisteredCartelaList`:
   - Disable `LongPressDraggable` during active gameplay to eliminate accidental card displacement while tapping numbers.
   - Adjust `childAspectRatio: 0.70` to accommodate cell padding, header badges, and action buttons cleanly without vertical clipping.
2. In `LiveCartelaCard`:
   - Tighten header padding and badge sizes.
   - Ensure `CartelaBoardWidget` uses flexible cell sizing within its fixed 5x5 aspect ratio.

- [ ] **Step 4: Run tests to verify passing**

Run:
```powershell
flutter test test/features/games/cartela_card_layout_test.dart
flutter test
```
Expected: ALL PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/games/presentation/widgets/live_cartela_card.dart lib/src/features/games/presentation/screens/live_game_screen.dart test/features/games/cartela_card_layout_test.dart
git commit -m "fix(ui): eliminate cartela matrix clipping and stabilize live card layout"
```

---

## 5. Verification Checklist & Gate Validation

Before claiming completion of this plan, run:
1. **Backend Verification:**
   ```powershell
   cd d:\FILES\SELF\BINGO\FriendsBingo-backend
   npm run build
   npm test
   ```
2. **Mobile Verification:**
   ```powershell
   cd d:\FILES\SELF\BINGO\friends-bingo-mobile
   flutter analyze lib test
   flutter test
   ```
3. Ensure zero lint errors, zero test failures, and clean git working trees.
