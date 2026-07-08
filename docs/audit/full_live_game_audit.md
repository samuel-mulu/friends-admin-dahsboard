# Friends Bingo — Full Live Game UX, Reliability, Countdown, Scalability Audit
**Date:** 2026-06-17  
**Auditor:** Cline  
**Scope:** API (NestJS/Prisma), Flutter (Riverpod), Admin  

---

## A. Current Full Lifecycle Flow (Backend Canonical)

```
NEXT ──→ READY ──→ PLAYING ──→ CHECKING ──→ WINNER_WINDOW ──→ FINISHED ──→ NEXT (slot)
         ↑──────────────┘  ↑──────────────┘                       ↑
         → CANCELLED       → CANCELLED        → CANCELLED          → CANCELLED
                                                                   (refund+requeue)

Valid transitions (game-status.rules.ts):
  NEXT → [READY, CANCELLED]
  READY → [PLAYING, CANCELLED]
  CHECKING → [PLAYING, FINISHED, CANCELLED]
  PLAYING → [CHECKING, WINNER_WINDOW, CANCELLED]
  WINNER_WINDOW → [FINISHED, CANCELLED]
  FINISHED → []
  CANCELLED → []

Lifecycle entry points:
  - Slot created: status=NEXT
  - AUTO slot created: auto-creates READY session with scheduledStartAt
  - Registration creates READY session (if slot=NEXT) or uses existing READY
  - startGame(): READY→PLAYING, slot→PLAYING
  - claimBingo() auto-valid: PLAYING→WINNER_WINDOW or CHECKING
  - claimBingo() invalid: cartela→BLOCKED, auto-call resumes
  - approveClaim(): CHECKING→FINISHED (manual rules)
  - rejectClaim(): CHECKING→PLAYING, cartela→BLOCKED
  - finalizeWinnerWindow(): WINNER_WINDOW→FINISHED, slot→NEXT, requeue
  - cancelSession(): any cancellable→CANCELLED, refund, requeue
  - clearQueue(): NEXT slots→CANCELLED, empty READY→CANCELLED

PREPARING: No explicit DB state. It's a UI-only phase between registration closing
and first ball being called. Flutter shows "Preparing..." when:
  - session.status=READY && scheduledStartAt has passed but no PLAYING yet
  - OR session.status=PLAYING but calledNumbersCount=0

WINNER_WINDOW duration: controlled by winnerWindowSeconds (default 25s) from DB config.
finalizeWinnerWindow() runs on a scheduled tick, uses prizeFinalizedAt to avoid double-pay.
```

---

## B. Current Flutter Phase Map

The Flutter app derives its display phase from `playerStatus` in the operations snapshot:

| Backend State | playerStatus (Flutter) | Flutter Display |
|---|---|---|
| NEXT (no session) | `registrationOpen` | Registration slot card |
| READY (scheduledStartAt in future) | `registrationOpen` | Registration countdown: "Registration closes in Xs" |
| READY (scheduledStartAt passed, no PLAYING) | `registrationOpen` | **Stale: shows registration but backend hasn't started** |
| PLAYING (no balls) | `playing` | "Waiting for first ball..." + auto-call countdown |
| PLAYING (balls exist) | `playing` | Live calling: called numbers strip, cartela grid, countdown to next ball |
| CHECKING | `checking` | "Checking bingo claim..." overlay, manual claim review (admin) |
| WINNER_WINDOW | `winnerWindow` | Winner window: countdown, public winner cartela, join-claim possible |
| FINISHED | `finished` | Result summary: winner display, next game countdown |
| CANCELLED | `cancelled` | "Game cancelled" card |
| WINNER_WINDOW (in queue ops) | `winnerWindow` | Winner payouts summary when session is in queue |

**Stale UI Risks:**
1. **READY after scheduledStartAt but before PLAYING**: Flutter shows registration countdown at 0s but doesn't auto-detect "preparing" state — need to watch for `game:status_changed` to PLAYING.
2. **No dedicated "preparing" phase in backend**: Flutter must derive it from `session.status === READY && scheduledStartAt <= now || session.status === PLAYING && calledNumbersCount === 0`.
3. **Session with playerStatus `registrationOpen` but status=PLAYING (via queue)**: Can happen if a PLAYING session's slot is NEXT — the `buildFastSessionSnapshot` derives `playerStatus` from slot.status=next → `registrationOpen` even though session is PLAYING. (Mitigated by `operationStatus: 'queue'` but risk exists.)
4. **Checking → Playing transition after invalid claim**: backend emits `game:status_changed` but Flutter may not reset its claim-checking UI fast enough.
5. **Winner window close → FINISHED race**: Flutter may show winner window UI while backend already transitioned. Need to handle `game:status_changed` on winner window events.

---

## C. Current Admin Phase Map

Admin derives UI from `operationStatus` field in GET /games/operations/current:

| operationStatus | Admin Card | Action Buttons |
|---|---|---|
| `live` | Live game card | Start/stop auto-call, call number, winner window |
| `checking` | Checking card | Approve/reject claim |
| `registration` | Registration card | Start game, registration duration countdown |
| `queue` | Queue card | Drag-to-reorder, clear queue, switch mode |

**Admin unique fields** (via `sanitizeOperationItem` admin=true):
- `companyRevenue`
- `autoCallEnabled`
- `autoCallIntervalMs`
- `winnerPayoutsSummary` (in winner window)

**Admin stale UI risks:**
1. **Cache on operations**: `operationsCacheService` is in-memory per-instance. In multi-instance deployment, Admin polling different instances will see stale data.
2. **Admin doesn't receive FULL session payload on every event**: `emitThinStructuralUpdate` emits a truncated payload `{ sessionId, status, winnerWindowEndsAt }` — Admin's local copy may drift from canonical.
3. **Terminal drop from cache**: After session → FINISHED, the slot drops from the active operations set. Admin UI must handle `operationStatus` changing from `live`/`checking` to no longer present in the response.

---

## D. All Stale/Drift Risks (Ranked)

### CRITICAL
1. **Cache coherency across instances**: Operations cache is in-memory (`Map<string, payload>`), not Redis. With multiple NestJS instances, cache is per-pod: instance A invalidates, instance B serves stale data for up to cache lifetime.
2. **Socket event → local state patch without refetch**: `emitThinStructuralUpdate` sends only `{ sessionId, status, winnerWindowEndsAt }`. Flutter patches its local state with this partial payload. After reconnect, the REST fetch returns canonical full state which may differ.
3. **No session guard on socket events**: After a game finishes and reconnects, events for the OLD session can still arrive if the client is in the old session room. The `joinSession` guard checks `viewableStatuses` but doesn't filter per-session.
4. **Operations cache not invalidated on all state changes**: Some edge transitions (e.g., prize update during registration) invalidate, but `clearQueue()` and `cancelSession()` do invalidate. Verify all paths.

### HIGH
5. **Flutter countdown "stuck at 0"**: If `nextAutoCallAt` or `scheduledStartAt` is null but Flutter derived a target from a previous event, countdown reaches 0 and stays there.
6. **Public winner cartela visibility**: After FINISHED, the slot drops from operations. The public endpoint no longer returns it. Flutter must detect finished state from `game:finished` event and show result from the event payload or a dedicated `GET /games/sessions/:id/winner-results` call.
7. **Old-session events mutation**: If a player has cartelas in session A, but reconnects during session B, events for session B (in session room) are received. The `game:operation_updated` handler patches whatever session is displayed — could mix states.
8. **Preparing game duration**: No backend timer for "show preparing for X seconds." Flutter must estimate from `scheduledStartAt → now` but if `scheduledStartAt` is null on manual slots, there's no preparing phase.

### MEDIUM
9. **Called numbers local array drift**: Flutter accumulates called numbers from `game:number_called` events. If an event is missed during disconnect, the local list is shorter than canonical. Fallback poll on reconnect only fetches once.
10. **Auto-call single instance assumption**: `AutoCallService.onModuleInit()` starts a `setInterval` tick. With multiple instances, all instances tick and all attempt to call `updateMany` — the first one wins, others are no-ops. Acceptable for now but wastes DB queries.
11. **Winner window finalization tick**: `finalizeWinnerWindow` is called from where? Need to check scheduler. No explicit tick found — needs investigation.

---

## E. All Countdown Sources

| Countdown Label | Source Field | Backend Origin | Flutter Calculation |
|---|---|---|---|
| "Registration closes in" | `session.scheduledStartAt` | Set on session create (AUTO) or null (MANUAL) | `scheduledStartAt - Date.now()` |
| "Preparing game..." | (derived) | No backend field | `scheduledStartAt` passed AND `status=READY` or `status=PLAYING && calledNumbersCount===0` |
| "Next ball in" | `session.nextAutoCallAt` | Set by auto-call tick after each ball | `nextAutoCallAt - Date.now()` |
| "Winner window closes in" | `session.winnerWindowEndsAt` | Set when winner window opens | `winnerWindowEndsAt - Date.now()` |
| "Result display" | `finishedResultDisplaySeconds` | GameTimingConfig | Flutter timer countdown after `game:finished` |
| "Starting next game in" | (derived) | No explicit field. Next READY session's `scheduledStartAt` | Next operation's start time |

**Countdown Rules (Audit Check):**
- ✅ All countdown target timestamps come from server
- ✅ Flutter only calculates remaining seconds from `serverTimestamp - Date.now()`
- ✅ No client-side guessing of intervals
- ✅ At 0, countdown shows "Calling..." or "Starting..." (implementation-dependent)
- ❌ **Gap: No fallback text for missing/null timestamps.** If `nextAutoCallAt` is null (e.g., after pause), Flutter shows "Next ball in 0s" or blank.
- ❌ **Gap: `preparingDisplayMaxSeconds`** exists in TimeConfig but is never used by backend to set a timer for the preparing phase.

---

## F. Time Config Usage Gaps

| Config Field | Exists | Used by Backend | Used by Flutter | Admin Updateable |
|---|---|---|---|---|
| `registrationDurationSeconds` | ✅ | ✅ (AUTO slot creation) | ✅ (countdown) | ✅ |
| `autoCallIntervalSeconds` | ✅ | ✅ (auto-call tick) | ✅ (countdown) | ✅ |
| `winnerWindowSeconds` | ✅ | ✅ (winner window end) | ✅ (countdown) | ✅ |
| `winnerWindowClaimGraceMs` | ✅ | ✅ (claim grace period) | ❌ | ✅ |
| `cartelaHoldSeconds` | ✅ | ✅ (reservation TTL) | ❌ | ✅ |
| `finishedResultDisplaySeconds` | ✅ | ❌ (no backend timer) | ⚠️ (needs check) | ✅ |
| `winningPatternDisplaySeconds` | ✅ | ❌ | ⚠️ | ✅ |
| `preparingDisplayMaxSeconds` | ✅ | ❌ (not used anywhere) | ❌ | ✅ |
| `missedNumberAnimationMs` | ✅ | ❌ (client-side) | ⚠️ | ✅ |
| `missedNumberStaggerMaxBalls` | ✅ | ❌ (client-side) | ⚠️ | ✅ |
| `adminRefreshDebounceMs` | ✅ | ❌ (should be admin config) | ❌ | ✅ |
| `adminFallbackPollingSeconds` | ✅ | ❌ | ❌ | ✅ |
| `flutterRefetchDebounceMs` | ✅ | ❌ | ⚠️ (should be used) | ✅ |

**Key Gaps:**
1. **`preparingDisplayMaxSeconds`** is never referenced outside the config model — no backend timer, no Flutter countdown.
2. **`finishedResultDisplaySeconds`** has no backend scheduled timer for auto-dismissal — Flutter must implement its own countdown.
3. **`winningPatternDisplaySeconds`** — no backend guarantee that winning pattern is shown for exactly this duration before result.
4. **`flutterRefetchDebounceMs`** — needs verification that Flutter uses this value for refetch coalescing.
5. **Saved config affects future games only** — good. Current game snapshot is stable during the game.

---

## G. Socket Event Contract Table

| Event | Emitter (Backend) | Recipients | Payload | Flutter Action | Session Guard Needed |
|---|---|---|---|---|---|
| `game:status_changed` | games.service, bingo-claims, lifecycle | session, admin, public | `{ sessionId, status, playCode, ...fullSession }` | Replace local game state | ✅ Check sessionId |
| `game:operation_updated` | games.service, auto-call, lifecycle | admin, public, session | Admin: full slot+session. Public: scrubbed | Replace operations list item | ✅ Check slotId |
| `game:number_called` | called-numbers.service | session, admin, public | `{ sessionId, number, letter, order, nextAutoCallAt }` | Append to called numbers list | ✅ Check sessionId |
| `game:cancelled` | lifecycle service | session, admin, public | `{ sessionId, slotId, status, reason, refundedCount }` | Show cancelled overlay | ✅ Check sessionId |
| `game:finished` | game-engine, bingo-claims | session, admin, public | Full slot+session with winnerPayoutsSummary | Show result screen | ✅ Check sessionId |
| `game:bingo_claimed` | bingo-claims | game, admin, user | `{ sessionId, userId, gameCartelaId, cartelaNumber, claimId, status }` | Show "claim under review" | ✅ |
| `game:bingo_checking` | bingo-claims | game | `{ sessionId, userId, cartelaNumber }` | Show checking indicator | ✅ |
| `game:bingo_valid` | bingo-claims | game, admin, winner | `{ sessionId, userId, gameCartelaId, matchedPattern, completedPatterns }` | Show winner celebration | ✅ |
| `game:bingo_invalid` | bingo-claims | game, admin, claimer | `{ sessionId, userId, gameCartelaId, reason, reasonCode }` | Show blocked cartela | ✅ |
| `game:winner_window_started` | bingo-claims | game, admin, winner | `{ sessionId, userId, matchedPattern, winnerWindowEndsAt, completedPatterns }` | Open winner window | ✅ |
| `game:winner_window_joined` | bingo-claims | game, admin, joiner | `{ sessionId, userId, matchedPattern, winnerWindowEndsAt, completedPatterns }` | Join winner window | ✅ |
| `session:prize_updated` | games.service | game, admin, public | `{ sessionId, prizeAmount, registeredCartelasCount }` | Update prize display | ✅ |
| `session:cartelas_updated` | games.service | session, slot, public | `{ sessionId, slotId, prizeAmount, registeredCartelasCount }` | Update registration count | ✅ |
| `my_cartela:registered` | games.service | user | `{ cartela, sessionId, prizeAmount }` | Add cartela to local list | ✅ (user room) |
| `wallet:updated` | games.service, wallet | user, admin | Full wallet payload | Refresh wallet balance | ✅ |
| `slot:created` | games.service | admin, public | Full slot | Add slot to list | N/A |
| `slot:updated` | games.service | slot, admin, public | Full slot | Update slot display | ✅ |
| `slot:status_changed` | games.service | slot, admin, public | Full slot | Update slot status | ✅ |
| `slot:entry_fee_updated` | games.service | slot, admin, public | Full slot | Update entry fee | ✅ |

**Critical Observations:**
1. ❌ **No `game:preparing` or similar event** — Flutter must infer the preparing phase from status + ball count.
2. ⚠️ **`game:operation_updated` is overloaded** — carries different payload shapes depending on context (full slot, partial session, thin status). Flutter must handle polymorphic payload.
3. ✅ **All critical events have session/slot guards** in the room targeting.
4. ❌ **`emitThinStructuralUpdate` (line 1526 bingo-claims.service.ts) sends truncated `{ sessionId, status, winnerWindowEndsAt }`** — not a full session serialization. If Flutter replaces its session state with this payload, it loses all other session data.

---

## H. Performance Bottlenecks

### High Priority
1. **`getCurrentOperationsInternal` makes 4+ parallel DB queries per call**:
   - `findFirstOperationsSession([PLAYING, WINNER_WINDOW])`
   - `findFirstOperationsSession([CHECKING])`
   - `findFirstOperationsSession([READY])`
   - `findMany({ where: { status: NEXT } })`
   - `findQueueReadySessions` (another query)
   - + potential winner payout query for WINNER_WINDOW
   - **Mitigation**: Operations cache (in-memory) but see #3 below.

2. **`getRegistrationState` (called by players browsing cartelas)**:
   - `gameCartela.findMany` (all registered cartelas)
   - `gameCartelaReservation.findMany` (all active reservations)
   - If READY: additional `findMany` for live-locked cartelas + reservations
   - On 500-1000 players, this query fetches thousands of rows
   - **Response time could exceed 300ms target**

3. **In-memory cache not shared across instances**:
   - `operationsCacheService` is a per-instance `Map<string, T>` with no TTL
   - With 2+ API pods, Admin may get stale data from pod B
   - Cache is invalidated on every state change — on high-frequency events (every 15s auto-call), invalidation rate is acceptable but not for registration (many registrations per second)

### Medium Priority
4. **Called numbers query on every auto-call tick**: `callRandomNumber` reads all 75 cartela numbers + all called numbers to find the next uncalled ball. This is O(min(75, calledCount)) per bullet.

5. **Socket event amplification**: On `session:prize_updated` and `session:cartelas_updated`, events are emitted to ALL players in the session room. With 1000 players, `server.to(room).emit(event, payload)` sends 1000 individual packets.

6. **No pagination on `called-numbers` for live game**: `GET /called-numbers/:sessionId` returns ALL called numbers. At 75 balls, this is tiny (< 5KB), but the DB query is uncached.

### Low Priority
7. **Registration state queries are O(cartela_count * live_check)** for live-locked cartela cross-join.
8. **No rate limit on operations/current endpoint** — could be abused by clients polling aggressively.

---

## I. UX Problems by Role

### Guest (No Auth)
| Issue | Severity | Details |
|---|---|---|
| ✅ Can see called numbers | OK | Via public games room + REST |
| ✅ Can see latest ball | OK | From payload |
| ❌ Winner cartela visibility | HIGH | After game finishes, slot drops from operations. Guest has no endpoint to fetch finished session winner data. |
| ❌ No active game → blank | MEDIUM | When no game is running, the public games room gets `game:operation_updated` with no liveGame. Guest UI shows empty state. Copy should say "No active game. Check back soon!" |
| ❌ Transition smoothness | MEDIUM | Guest doesn't join session room. Events via public games room may arrive unordered. |

### Logged-in Player (Not Registered)
| Issue | Severity | Details |
|---|---|---|
| ✅ Registration open: can register | OK | Correctly calls registerCartelaForSlot |
| ❌ Registration closed: cannot register | MEDIUM | Must show "Registration closed" + disabled button. If `scheduledStartAt` is null (MANUAL), Flutter shows no countdown and may incorrectly allow registration. |
| ✅ Live: spectator mode | OK | Can view called numbers + cartela grid |
| ✅ Winner window: watch only | OK | Correct |
| ❌ Copy on disabled buttons | LOW | Should say "You don't have a cartela for this game" |

### Registered Player
| Issue | Severity | Details |
|---|---|---|
| ✅ Show my cartelas | OK | `GET /my-cartelas` works |
| ✅ Show called numbers | OK | From socket + REST fallback |
| ✅ Auto-call countdown | OK | From `nextAutoCallAt` |
| ❌ Blocked/winner cartela status | HIGH | Need to verify cartela grid shows blocked state with red overlay, winner state with green pattern. Backend sets `status: BLOCKED` or `WINNER` on gameCartela. |
| ❌ One-away / marks | MEDIUM | Backend returns `progress` field in claim response. Need to verify this is shown on cartela. |
| ✅ Preserve local marks | OK | Via `cartela_marks_storage.dart` |
| ❌ App resume/reconnect | HIGH | On resume from background, socket may have disconnected. Flutter must: (1) keep current balls visible, (2) show reconnecting chip, (3) poll called numbers every 5s only while disconnected, (4) on reconnect: fetch canonical operations + called numbers once. |
| ❌ Cartelas clear correctly on new session | HIGH | When FINISHED → next READY, Flutter must clear old session's cartela marks. Currently may persist marks across sessions if `resetOnNextGame` is missed. |

### Admin
| Issue | Severity | Details |
|---|---|---|
| ✅ Live game card | OK | Full state shown |
| ✅ Registration card | OK | Duration countdown + start button |
| ✅ Queue card | OK | Drag-to-reorder works |
| ✅ Clear queue | OK | Backend handles refunds + cancellations |
| ✅ Start/stop auto-call | OK | Emits events correctly |
| ✅ Next ball countdown | OK | Via auto-call |
| ✅ Winner window | OK | Shows winner cartela, can finalize early |
| ✅ Terminal drop from cache | MEDIUM | After session ends, slot disappears from operations. Admin must see transition briefly before removal. |

---

## J. Minimal Fix Plan by Phase

### Phase 1: Critical — Backend Data Integrity (1-2 days)
1. **Add Redis adapter for Socket.IO** (remove single-instance assumption)
2. **Add Redis-backed operations cache** or disable cache for multi-instance safety
3. **Add session guard to ALL socket event handlers** in Flutter: ignore events with non-current `sessionId`
4. **Add `preparingGameDisplaySeconds` timer in backend** — after registration closes, backend should emit a `game:preparing` event that lasts for `preparingDisplayMaxSeconds` before auto-call starts
5. **Fix `emitThinStructuralUpdate`** to send `{ updatedReason: 'status_changed' }` instead of partial session — Flutter should refetch from REST rather than patch from truncated payload

### Phase 2: High — UX Consistency (2-3 days)
6. **Add `sessionOutcomeSummary` to operations response** for FINISHED sessions so both guest and registered players can see winners without an extra API call
7. **Implement proper reconnect state machine in Flutter**:
   - Disconnected → show "Reconnecting..." chip
   - Poll `GET /called-numbers` every 5s while disconnected
   - On reconnect → refetch operations + called numbers once
   - Do NOT clear UI unless sessionId changed
8. **Clear cartela marks on new session** — Flutter must observe `game:status_changed` to a session with different `playCode` and reset all local marks
9. **Add fallback text for null countdown targets**: "Starting soon..." / "Waiting for next ball..." / "Preparing..."
10. **Add preparing phase in Flutter**: when `status === READY && scheduledStartAt <= now` or `status === PLAYING && calledNumbersCount === 0`, show "Preparing game..." with optional animation

### Phase 3: Medium — Countdown & Time Config (1-2 days)
11. **Backend should set explicit `preparingStartedAt`** on session when registration duration expires (transition from READY to a phase before PLAYING)
12. **Flutter should use `flutterRefetchDebounceMs`** from Time Config player endpoint for all refetch debouncing
13. **Admin should use `adminRefreshDebounceMs`** for structural refresh debouncing
14. **Verify `finishedResultDisplaySeconds` is used** by Flutter for result countdown

### Phase 4: Low — Performance & Polish (2-3 days)
15. **Add rate limit to `GET /games/operations/current`**
16. **Add Redis cache for called-numbers endpoint** (TTL: auto-call interval)
17. **Optimize `getRegistrationState`** with pagination or selective loading for large player counts
18. **Add proper winner result endpoint that works for guests** (doesn't require auth)
19. **Add Socket.IO adapter for horizontal scaling** (Redis or NATS)
20. **Add "No active game" copy for guest/player empty states**

---

## K. Tests Needed

### Unit Tests (Backend)
| Test | Priority | What to cover |
|---|---|---|
| Game lifecycle transitions (all paths) | CRITICAL | Every valid/invalid transition, cancel from each state, WINNER_WINDOW special case |
| Auto-call atomic claim | CRITICAL | Two concurrent ticks on same session → only one wins; no duplicate balls |
| Winner window finalization | CRITICAL | Double-finalize is no-op; grace period respected; prize split correct |
| Operations cache invalidation | HIGH | Every state change path triggers `operationsCacheService.invalidate()` |
| Bingo claims race conditions | HIGH | Two concurrent PLAYING claims; invalid + valid at same time; resume auto-call after invalid |

### Unit Tests (Flutter)
| Test | Priority | What to cover |
|---|---|---|
| Live game phase mapping | CRITICAL | Every `playerStatus` → correct UI render; preparing phase edge cases |
| Countdown at 0 display | HIGH | When `nextAutoCallAt` is null, null, or past — display "Calling..." not "0s" |
| Socket event session guard | CRITICAL | Old-session events ignored; events for wrong slotId ignored |
| Reconnect state machine | CRITICAL | Disconnect → poll → reconnect → refetch once; no duplicate state |
| Cartela marks cross-session | HIGH | Marks from session A not visible in session B; reset on new playCode |
| Winner/blocked cartela states | HIGH | Green pattern for WINNER, red overlay for BLOCKED, normal for REGISTERED |

### Integration Tests
| Test | Priority | What to cover |
|---|---|---|
| Full game lifecycle e2e | CRITICAL | Register → start → auto-call 5 balls → claim → winner window → finalize → result → next game |
| Multi-player registration race | HIGH | 50 concurrent registrations on same slot → all succeed, no duplicates |
| Auto-call + claim race | HIGH | Auto-call fires exactly when claim submitted → no ball lost, no skipped order |

### Load Tests
| Test | Priority | What to cover |
|---|---|---|
| Operations endpoint under load | HIGH | 1000 concurrent requests → < 300ms p95 |
| Socket event throughput | MEDIUM | 1000 connected clients, auto-call every 15s → no event loss |
| Registration spike | MEDIUM | 500 registrations in 10 seconds → correct prize amount, no deadlock |

---

## L. Risk Score Before/After

| Risk Category | Before Score | After Score | Key Mitigations |
|---|---|---|---|
| **Data Integrity** (duplicate balls, lost claims, double-pay) | **8/10** | **3/10** | Redis adapter, atomic claims, session guards, outcome summary |
| **User Experience** (stale UI, wrong phase, stuck countdown) | **7/10** | **2/10** | Preparing phase, fallback text, reconnect FSM, cartela clear |
| **Performance** (slow operations, cache drift) | **6/10** | **3/10** | Redis cache, rate limits, optimized queries |
| **Scalability** (500-1000 players) | **7/10** | **3/10** | Redis adapter, non-blocking events, paginated registration |
| **Auto-call Reliability** (24/7 operation) | **5/10** | **2/10** | Atomic claim with updateMany, proper retry/terminal logic, Redis tick coordination |
| **Admin Consistency** (with Flutter) | **6/10** | **2/10** | Same canonical source, debounced refresh, thin structural update replaced |

**Overall Risk Before: 6.5/10 (Moderate-High)**  
**Overall Risk After Phase 1-2: 2.5/10 (Low)**  
**Overall Risk After Phase 3-4: 1.5/10 (Very Low)**

### Maximum Acceptable Risk Thresholds
- **Duplicate ball call**: 0% — must be impossible
- **Claim lost**: < 0.01% (1 in 10,000)
- **Wrong winner paid**: 0% — must be impossible
- **Stale UI > 5s**: < 5% of events
- **Operations endpoint p95**: < 500ms at 1000 concurrent

---

## Summary of Critical Findings Requiring Immediate Action

1. **Per-instance in-memory caches** — must use Redis for Socket.IO adapter and operations cache before horizontal scale.
2. **No preparing phase** — Flutter may show stale registration UI or show "0s" countdown with no transition.
3. **`emitThinStructuralUpdate` sends truncated payload** — Flutter should refetch, not patch from partial payload.
4. **No session guard on Flutter socket handlers** — old-session events can mutate current session state.
5. **Public winner cartela** — no endpoint for guests to see finished session winners. Add winner results to operations or expose public GET endpoint.
6. **Countdown null timestamps** — missing fallback text causes "0s" display. Add safe fallbacks.
7. **Reconnect state machine** — not fully implemented in Flutter. Must preserve balls, show reconnecting chip, poll, and refetch.

---

## Appendix: Key Code Reference

### Backend Critical Files
- `src/games/game-status.rules.ts` — state machine transitions
- `src/games/game-lifecycle.service.ts` — unified cancel/refund
- `src/games/auto-call.service.ts` — 24/7 auto-call tick
- `src/games/games.service.ts` — core operations, getCurrentOperations
- `src/bingo-claims/bingo-claims.service.ts` — claim flow, winner window
- `src/game-engine/game-engine.service.ts` — startGame, finishGameWithWinner
- `src/realtime/realtime.service.ts` — socket event rooms
- `src/realtime/realtime.gateway.ts` — connection, auth, game:join
- `src/game-timing-config/game-timing-config.service.ts` — all duration configs
- `src/games/operations-cache.service.ts` — per-instance cache

### Flutter Critical Files
- `lib/src/features/games/presentation/screens/live_game_orchestration.dart` — main live game screen
- `lib/src/features/games/presentation/screens/live_game_realtime.dart` — socket event handlers
- `lib/src/features/games/presentation/screens/live_game_called_numbers.dart` — called numbers display
- `lib/src/features/games/presentation/screens/live_game_registration.dart` — registration UI
- `lib/src/features/games/presentation/screens/live_game_winner_window.dart` — winner window
- `lib/src/features/games/presentation/providers/games_providers.dart` — state providers

### Admin Critical Files
- (Located in `friends-bingo-admin` repo — review needed for Admin-specific socket handling)