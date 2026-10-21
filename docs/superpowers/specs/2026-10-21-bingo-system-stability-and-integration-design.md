# Specification: Bingo System Stability, End-to-End Integration & Robust Concurrency

## 1. Executive Summary & Problem Scope

This specification defines the architectural enhancements and bug remediation across **FriendsBingo-backend** (NestJS + Prisma + PostgreSQL) and **friends-bingo-mobile** (Flutter + Riverpod). The primary mandate is to eliminate all stability bottlenecks, latency spikes, and edge-case failures across 5 core functional areas without introducing unwanted new features:

1. **Bingo Claim Latency & Freeze:** Ensure claim evaluations resolve in $\le 1$ second under high concurrency with unambiguous visual feedback for valid, invalid, and blocked claims.
2. **Auto & Manual Win-to-Next Transition:** Guarantee fail-safe session finalization to `FINISHED` when the winner window closes and seamless auto-progression to upcoming rounds on mobile.
3. **Deposit Error Remediation:** Establish single-pass atomic idempotent deposit processing, eliminating false `ALREADY_USED` errors and network dropouts.
4. **Cartela Multi-Registration & Visual Integrity:** Ensure zero card loss across multiple registration bursts via server-authoritative cumulative session snapshots, and eliminate unexpected modals, skipping, duplication, and card clipping.
5. **Game Rules & Pattern Evaluator Alignment:** Harmonize client-server pattern evaluation (including free center cell N3 handling and transparent late-claim diagnostics).

---

## 2. Issue-by-Issue Architectural Design & Solution

### 2.1 Issue 1: Sub-Second Bingo Claim Pipeline & Claim Freeze Fix

#### Root Cause Analysis
* In `src/bingo-claims/bingo-claims.service.ts`, `claimBingo()` executed within `prisma.$transaction`, but directly awaited `emitClaimSideEffects()`. This synchronously triggered repeated database `findUnique` operations, full game session payload serialization, operations cache invalidation, and broadcast across all Socket.IO public game channels *before* returning the HTTP response.
* In `live_game_called_numbers.dart:164-171, 228-234`, when a claim evaluated as `BLOCKED`, the handler recorded the blocked reason but returned immediately without setting `outcomeSnackbarMessage`. As a consequence, the claim button spun indefinitely or unlocked silently without explaining why the claim failed.
* In mobile, `_checkingCartelaMinimumDisplay` enforced an artificial `800ms` delay on non-winner claims, degrading perceived latency.

#### Architecture Specification
1. **Multi-Winner Window Preservation & Fast-Path Synchronous Evaluation (`FriendsBingo-backend`):**
   * **Multi-Winner Rule:** A game can have multiple valid winners. When the first valid claim arrives:
     * Set `GameSession.status = WINNER_WINDOW` and calculate `winnerWindowEndsAt = now + winnerWindowDuration`.
     * Number calling halts immediately to freeze the ball state.
     * **CRITICAL:** The winner window **MUST REMAIN OPEN** for its entire duration. It is NEVER prematurely closed upon the first winner.
     * Any other player who completed their pattern on that winning ball can submit their claim during the open `WINNER_WINDOW`.
     * Subsequent valid claims during the open window are also marked as `GameCartela.status = WINNER` (`isWinner = true`).
     * When `winnerWindowEndsAt` expires, the prize pool is divided equally among all co-winners.
   * **Bingo Claim Relational Integrity:**
     * To prevent inconsistent relationships, the service layer strictly enforces that `gameCartelaId` matches both `gameSessionId` and `userId` within the database transaction:
       ```typescript
       const gameCartela = await tx.gameCartela.findUnique({
         where: { id: gameCartelaId },
         select: { id: true, gameSessionId: true, userId: true, status: true, isWinner: true, cartela: true }
       });
       if (!gameCartela || gameCartela.gameSessionId !== sessionId || gameCartela.userId !== userId) {
         throw new ForbiddenException('Cartela does not belong to this user or session');
       }
       ```
     * `GameCartela.status === WINNER` is established as the sole canonical multi-winner source of truth. The legacy `GameSession.winnerCartelaId` is populated with the primary winner only for backward compatibility, while all payouts and winner displays iterate over all `GameCartela` records where `status === WINNER`.
   * **Fast-Path Performance (Target: $< 150\text{ ms}$):**
     * Rule evaluation and winner/blocked state writes execute in a single lean transaction.
     * Returns HTTP `200 OK` verdict payload directly to the player without waiting for downstream side effects.
2. **Decoupled Asynchronous Side Effects (`FriendsBingo-backend`):**
   * Wrap `emitClaimSideEffects()`, operations cache invalidation, and push notifications inside `setImmediate()` or an event emitter so they execute out-of-band without delaying the calling player's HTTP response.
3. **Mobile Client Immediate Feedback (`friends-bingo-mobile`):**
   * Remove artificial `_checkingCartelaMinimumDisplay` delays.
   * On claim response:
     * If `VALID`: Trigger winner dialog, haptics, and gold celebration overlay. The dialog displays "Winner Window Open" allowing other simultaneous winners to be celebrated upon window closure.
     * If `INVALID` / `BLOCKED`: Immediately display an explanatory warning banner/toast:
       * For `INVALID_LATE_CLAIM`: *"Late Claim: Ball #X completed the pattern, but Ball #Y was already called."*
       * For `INVALID_PATTERN`: *"Incomplete Pattern: Number(s) missing from active rule."*
     * Reset button state from `checking` to `idle` or `blocked` in $< 1$ second.

---

### 2.2 Issue 2: Fail-Safe Winner Window Progression to Next Round

#### Root Cause Analysis
* In `src/games/winner-window-finalizer.service.ts:50-58`, finalization queried `where: { status: GameStatus.WINNER_WINDOW, winnerWindowEndsAt: { lte: now }, prizeFinalizedAt: null }`.
* If `postGameRegistrationOpenerService.openNextAutoQueueRegistrationInTransaction()` encountered a conflict or error, the session remained stuck in `WINNER_WINDOW` with `status != FINISHED`, locking all players out of the next round.

#### Architecture Specification
1. **Guaranteed Transactional Finalization (`FriendsBingo-backend`):**
   * Decouple prize finalization from next-session creation.
   * If creating or opening the next auto-queue session fails or throws an exception, the current session is still unconditionally finalized to `GameStatus.FINISHED` with `finishedAt = new Date()`.
   * A secondary autonomous queue watchdog (`AutoReadyCountdownRepairService`) ensures any slot lacking an open session automatically spins up the next session within 2 seconds.
2. **Mobile Auto-Dismissal & Transition (`friends-bingo-mobile`):**
   * In `WinnerCartelaDialog`, when the winner window countdown reaches 0:
     1. Automatically close the dialog if still visible.
     2. Transition player state from the finished session to the upcoming round (`NEXT` / `READY`) via `liveGameStateNotifier`.

---

### 2.3 Issue 3: Single-Pass Atomic Idempotent Deposit System

#### Root Cause Analysis
* Mobile performed two consecutive network round-trips: `checkDepositReference` followed by `createDeposit`.
* In `deposits.service.ts:createAutomaticDeposit`, verification via external `verifyEtService` took 3–10 seconds without an initial database lock on `(provider, transactionRef)`. If network dropped or the player retried, the second request hit a unique constraint collision (`P2002`) and returned a false `ALREADY_USED` error.
* Mobile had short HTTP timeouts, triggering timeout failures while the bank verification was still in-flight.

#### Architecture Specification
1. **Single-Pass Submission (`friends-bingo-mobile`):**
   * Remove the redundant pre-flight `checkDepositReference` call.
   * Directly submit `POST /deposits` with a single, clear user interaction.
2. **Atomic In-Flight Lock & Idempotent Replay (`FriendsBingo-backend`):**
   * Before reaching out to `verify.et`, insert or claim a `PENDING` deposit record atomically with `(provider, transactionRef)`.
   * If a subsequent request arrives with the same `(provider, transactionRef)` for the **same user**:
     * If status is `APPROVED`: Gracefully return HTTP `200 OK` with the approved deposit and updated balance.
     * If status is `PENDING`: Return HTTP `200 OK` with `status: "PENDING"` and a verification progress notice, preventing user panic.
     * Only if the reference belongs to a **different user** does it reject with `ALREADY_USED`.
3. **Resilient Client UI Feedback:**
   * Extend client timeout for deposit verification to 25 seconds with an active progress indicator ("Verifying payment with payment provider...").
   * In the rare event of a network timeout, poll `/deposits/history` on app resume or screen focus rather than throwing a destructive error.

---

### 2.4 Issue 4: Zero Card Loss on Multi-Registration & Visual Grid Stability

#### Root Cause Analysis
* **Card Loss:** Mobile's `mergeRegisteredCartelas` dropped cards when `sessionId` mismatched or when the debounced `refreshMyCartelasSilently` (400ms delay) fired concurrently with a second in-flight registration, overwriting the local list with an obsolete snapshot.
* **Unexpected Popups:** `live_game_registration.dart:995` invoked `_scheduleAutoOpenIfNeeded` which opened `_openCartelaModal` even after the game moved past registration mode into `PLAYING`.
* **Skipping, Duplication & Clipping:** Fixed aspect ratio `SliverGrid` contained nested `LongPressDraggable` wrappers and unconstrained text elements that caused matrix clipping and layout flutter during reordering.

#### Architecture Specification
1. **Server-Authoritative Session Snapshot:**
   * Both `POST /games/sessions/:id/register-cartela` and `POST /games/slots/:slotId/register-cartelas-bulk` will return:
     ```json
     {
       "successes": [...],
       "failures": [...],
       "myCartelas": [
         { "id": "uuid", "cartelaId": "uuid", "cartela": { "number": 12, ... } }
       ]
     }
     ```
   * The mobile client replaces its active cartela state with `myCartelas`, eliminating client-side merge guesswork and race conditions.
2. **Registration Modal Suppression:**
   * Strictly disable `_scheduleAutoOpenIfNeeded` and dismiss any open preview modals once `GameStatus` transitions to `PLAYING` or `CHECKING`.
3. **Visual Grid Polish:**
   * Stabilize the 2-column grid inside `_InlineRegisteredCartelaList`: remove conflicting drag wrappers during live gameplay, enforce strict layout bounds on `LiveCartelaCard` cells, and prevent text overflow.

---

### 2.5 Issue 5: Game Rules & Pattern Evaluation Alignment

#### Root Cause Analysis
* Discrepancies between `cartela_pattern_evaluator.dart` (client) and `game-rule-evaluation.service.ts` (backend) regarding center free cell (index 12 / N3).
* Late claims (`INVALID_LATE_CLAIM`) failed without structured context, leading players to believe the game malfunctioned.

#### Architecture Specification
1. **Harmonized Evaluator Standard:**
   * Center cell (row 2, column 2 / index 12 / N3) is universally stamped in all pattern evaluations on both mobile and backend.
   * Coordinate checks in combo evaluators (`evaluators/combo/`) are strictly bounded to prevent index-out-of-bounds errors.
2. **Structured Rejection Diagnostics:**
   * Backend returns structured metadata on claim rejection:
     ```json
     {
       "reasonCode": "INVALID_LATE_CLAIM",
       "latestCalledNumber": 38,
       "winningBallNumber": 24
     }
     ```
   * Mobile displays immediate, transparent feedback explaining the exact reason.

---

## 3. High-Concurrency & Scale Roadmap (Backend & Mobile)

1. **Prisma Row-Lock Minimization:** Keep transactions $< 100\text{ ms}$ by locking only the targeted session and cartela.
2. **Realtime Broadcast Throttling:** Ensure called numbers and game updates are delivered without socket flooding.
3. **Future Scaling (No current code changes needed):**
   * Redis caching for active session boards.
   * BullMQ queue for decoupled notifications and audit logging.

---

## 4. Verification & Testing Criteria

* **Unit & Integration Tests:**
  * Backend claim latency and error codes test suite.
  * Backend deposit idempotency test suite (`P2002` replay prevention).
  * Backend cartela bulk registration cumulative snapshot test suite.
  * Mobile unit tests for pattern evaluator, claim feedback, and cartela list synchronization.
* **Verification Gates:**
  * `npm run build` & Jest tests passing in `FriendsBingo-backend`.
  * `flutter analyze lib test` with 0 errors and 0 warnings in `friends-bingo-mobile`.
  * `flutter test` with 100% passing tests in `friends-bingo-mobile`.
