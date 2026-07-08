# Friends Bingo — Live Transition Production Gaps & Stability Audit

**Date:** 2026-07-08  
**Scope:** Flutter live game sync (`friends-admin-dahsboard`) + NestJS backend contracts (`FriendsBingo`)  
**Mode:** Read-only audit / handoff documentation  
**Goal:** Make live UX boring and production-stable. **No new features.** Backend freeze unless bug-critical.

---

## 1. Executive summary

The product is close to production. Backend game rules, wallet ledger, registration, bonus cartelas, and bingo validation are strong and should be **frozen**. Remaining instability comes almost entirely from the **Flutter live screen**: too many independent writers can update `_game`, called numbers, cartelas, presentation holds, and winner-pattern cache at the same time.

**Root cause:** Competing state writers (socket patches, canonical refetch, terminal locals, resume sync, registration refresh, review controller clears) produce temporary impossible UI:

| Impossible / bad UI | Typical cause |
|---|---|
| READY game with live called numbers | Socket ball patch + ops still READY / incomplete session clear |
| Live phase with `status=READY`, `called=0` | Partial `_game` patch without atomic ops+balls together |
| Registration grid without READY banner | Banner/grid applied on different ticks |
| Cartelas disappear then return | Cleared mid-transition before snapshot replace |
| Winner pattern clear → reappear | Pattern cache cleared on advance *before* next session apply |
| Sync storm / reconnect loop | Dual canonical-refetch pipelines + preparing poll + resume |

**Product rule (non-negotiable):** Flutter must not invent game state. Backend owns status, `nextAutoCallAt`, called numbers, bingo validity, and wallet. Flutter renders, patches only when safe, and otherwise applies one atomic snapshot.

---

## 2. Intended KISS architecture (target)

```
Normal path
  socket event
    → local patch if safe
    → small widget update
    → done

Recovery path
  app resume / reconnect / manual refresh / mismatch
    → fetch required backend snapshot once
    → apply snapshot atomically
    → done

Terminal path
  CANCELLED / FINISHED / NO_WINNER
    → terminal_transition owner only
    → fetch operations/current once
    → wallet/cartelas only if needed
    → apply READY/review snapshot atomically
    → done
```

### What must be removed or disabled (violations)

- App resume recovery while terminal transition is active
- Socket reconnect recovery while terminal transition is active
- `operation_updated` canonical loop (especially for `number_called` / thin auto-call duplicates)
- Direct `_game` / cartela / called-number clearing during transition
- Same-session recovery that rolls called numbers backward
- Terminal coordinator completing twice
- Polling while socket is healthy
- Full-screen rebuild on every auto-call tick
- Raw socket payload access without normalization

---

## 3. Backend status (strong / freeze)

### 3.1 Session status machine

Canonical rule source: `FriendsBingo/src/games/game-status.rules.ts`  
Lifecycle doc: `FriendsBingo/docs/game-operations-lifecycle.md`

| Status | Meaning |
|---|---|
| `NEXT` | Slot-only queue identity |
| `READY` | Registration open |
| `PLAYING` | Live draw |
| `CHECKING` | Manual claim pending admin |
| `WINNER_WINDOW` | Co-winner window |
| `FINISHED` | Terminal with winners |
| `NO_WINNER` | Terminal after all balls + grace |
| `CANCELLED` | Terminal cancel + refund |

**Slot vs session dual status is intentional:**

- Slot `NEXT` + Session `READY` during registration is **correct**.
- Flutter must use **session status** for registration/live UI and treat slot status as queue helper.
- Canonical truth for live UI = `GameSession.status` + `GET /games/operations/current`.

### 3.2 What Flutter can trust from backend

| Guarantee | Notes |
|---|---|
| Session status is source of truth | Prefer ops snapshot / `rawStatus` |
| At most one global active live session | PLAYING / CHECKING / WINNER_WINDOW |
| Cancel owns refunds atomically | Same cancel transaction + `wallet:updated` |
| Auto-call owns `nextAutoCallAt` | Draw + thin `operation_updated` (`updatedReason: auto_call_changed`) |
| Late bingo rule is pattern-based | `completedByLatestNumber` — **not** a 2s server timer |
| Winner window co-winners | `winner_window_*` events + `GET .../winner-results` |
| Cancel → next READY / Finish → next READY | Post-game registration opener |

### 3.3 Backend caveats (Flutter must heal, prefer not to change backend)

1. **Event bursts** after cancel/finish/window — multiple socket events for one transition.
2. **Polymorphic `game:operation_updated`** — thin auto-call delta vs full ops payload.
3. Auto open emits `game:winner_window_started` / `joined`, **not** always `game:bingo_valid` (manual approve uses `bingo_valid`).
4. Ops current cache TTL ≈ **500ms** + handoff stickiness — sockets may look “ahead” of HTTP briefly.
5. Auto-call + claim race can briefly null then restore `nextAutoCallAt`.
6. No Redis Socket.IO adapter yet → multi-instance fan-out not guaranteed.
7. Finish may open next READY registration **before** finished emits finish — client can see two interesting sessions briefly.

### 3.4 Freeze zones (do not change unless critical)

- Status machine + `GameLifecycleService.cancelSession`
- NEXT+READY dual-status semantics
- `GET /games/operations/current` selection / handoff
- Auto-call ownership of `nextAutoCallAt`
- Winner window open/join/finalize + prize split
- Socket event **names** and cancel/finish burst structure
- Late-claim rule
- Wallet refund-in-cancel transaction
- Registration / bonus / bingo validation modules

**Backend fixes required for Flutter correctness today:** **None**, if Flutter follows snapshot-first reconnect and normalizes polymorphic events.

**Only consider backend later for:** Redis socket adapter + auto-call leader election (true multi-instance), or a single envelope transition event if Flutter normalization still fails under load.

---

## 4. Flutter architecture as-is (gaps)

### 4.1 Key files

| File | Role |
|---|---|
| `lib/.../screens/live_game_screen.dart` | State owner: `_game`, flags; derives `_liveUiMode` |
| `lib/.../screens/live_game_orchestration.dart` | Load/apply, terminal locals, number/bingo handlers, **duplicate** refetch pipeline |
| `lib/.../screens/live_game_realtime.dart` | Socket registration + resume/reconnect/manual triggers |
| `lib/.../screens/live_game_called_numbers.dart` | Strip UI + claim patches to `_game` |
| `lib/.../screens/live_game_registration.dart` | Registration writers / next-reg targets |
| `lib/.../controllers/live_realtime_controller.dart` | Intended sync owner (`syncLatest`, `scheduleCanonicalRefetch`, `requestTerminalCanonicalRefetch`) |
| `lib/.../controllers/live_transition_controller.dart` | READY lock / preparing poll — uses **controller** refetch |
| `lib/.../controllers/live_review_controller.dart` | Review hold, winner results, pattern cache clears |
| `lib/.../controllers/live_called_numbers_controller.dart` | Called list / gap buffers / claim holds |
| `lib/.../controllers/live_registration_controller.dart` | My cartelas / next-reg storage |
| `lib/.../utils/live_ui_mode.dart` | Derived presentation gates |
| `lib/.../utils/socket_payload_normalizer.dart` | Safe normalize (must be used everywhere) |
| `lib/.../utils/winner_cartela_live_display.dart` | Pattern cache |
| `lib/.../utils/live_game_finish_transition.dart` | Finish/cancel helpers — **cancel helper unused in production** |
| `lib/.../utils/next_ball_countdown.dart` | Client BINGO lock (`kBingoClaimLockSeconds = 2`) |

### 4.2 Critical architectural defect: dual refetch ownership

There are **two** canonical refetch pipelines:

1. **Screen/orchestration:** `_scheduleCanonicalRefetch` / `_refetchCanonical` / `_drainRefetchCanonicalQueue` + screen pending fields (`live_game_screen.dart` / `live_game_orchestration.dart`). Most socket handlers use this path.
2. **Controller:** `LiveRealtimeController.scheduleCanonicalRefetch` / `requestTerminalCanonicalRefetch` / `drainRefetchCanonicalQueue`. Transition lock / preparing poll use this path.

Result: two debounce queues, two pending flag sets, overlapping `_loadInitialState` runs → flicker, extra RPCs, racey apply order.

**Fix target:** Delete screen duplicate; route **all** callers through `LiveRealtimeController`.

### 4.3 No single atomic apply for terminal

Closest atomic function: `_applyCanonicalGame` in orchestration.

But finish is split:

- Apply may mark FINISHED / NO_WINNER
- Then `_handleGameFinishedLocally` / `_handleNoWinnerLocally` mutate again (leave room, start summary, refresh called numbers, schedule **another** refetch)

CANCELLED path:

- `_onGameCancelled` mostly refetch-only
- No first-class `_handleCancelledLocally`
- `shouldRunCancelTransition` exists in utils / tests but is **unused** in app code

---

## 5. Complete writer matrix

Disposition legend:

- **keep socket patch** — safe immediate local update
- **move behind atomic snapshot apply** — must land with coherent snapshot
- **delete duplicate** — remove competing write
- **UI-only safe** — presentation / bootstrap only

### 5.1 `_game`

| Writer | Location | Disposition |
|---|---|---|
| `_applyCanonicalGame` | orchestration | **Atomic apply** (make this the status owner) |
| `_enterFinishedReviewFromExpiredWindow` | orchestration | Move behind terminal atomic apply |
| `_handleGameFinishedLocally` | orchestration | Delete duplicate / fold into terminal apply |
| `_handleNoWinnerLocally` | orchestration | Delete duplicate / fold into terminal apply |
| `_onNumberCalled` status→playing | orchestration | **Do not invent PLAYING**; keep ball+schedule patch only |
| `_applyWinnerWindowState` | orchestration | Keep socket patch (status→winnerWindow + endsAt) |
| `_applyAutoCallScheduleFromPayload` | orchestration | Keep socket patch |
| Registration metrics patch | realtime | Keep socket patch (ops overwrite) |
| Registration session resolve | registration | Keep sessionId patch |
| Claim Bingo lock / pause patches | called_numbers | Keep schedule patches; confirm status via ops |
| `_game = null` on load empty/error | orchestration | Only via atomic apply / hold previous UI |
| Widget init `initialGame` | screen | UI-only safe bootstrap |

### 5.2 Called numbers

| Writer | Disposition |
|---|---|
| Canonical apply replace/fill | Atomic apply |
| `applyNumberCalledSocket` | Keep socket patch |
| Gap recovery `refetchCalledNumbersOnly` | Called-numbers fetch only |
| Session scope clear | Atomic apply only |
| Stagger hydrate | UI-only safe |
| Disconnected poll | Recovery called-numbers fetch only; stop when socket healthy |

### 5.3 My cartelas / next registration

| Writer | Disposition |
|---|---|
| Canonical apply `_myCartelas` / `_nextUpcomingGame` | Atomic apply |
| Bingo valid/invalid cartela map | Keep socket patch |
| Finished local winner map | Delete duplicate once terminal apply owns outcomes |
| Silent registration refresh | Keep post-action; coalesce into snapshot when syncing |
| Next-reg prefetch during review | UI-only safe under terminal pin |

### 5.4 Live phase / presentation (derived)

| Input | Disposition |
|---|---|
| `resolveLiveUiMode` / presentation phase | **UI-only safe — do not store** |
| Ready transition lock | Keep local hold |
| Registration countdown closed latch | Keep; clear only via apply/lock clear |
| Post-game summary review active | Keep terminal hold |
| Embedded ops snapshot refresh | Keep to align resolver before ops refetch |

### 5.5 Winner pattern cache

| Writer | Disposition |
|---|---|
| storeClaimSnapshot / storePatterns on bingo valid / winner window | Keep socket patch — sticky immediately |
| applySessionResult from winner-results | Enrich only; do not clear patterns first |
| clear on sessionChanged apply | Atomic apply only |
| `beginPostGameSummaryAdvance` → `clearFinishedReviewVisualState()` | **Bug** — clears **before** READY apply; defer until sessionChanged |
| Session-scoped review clear | Atomic apply only |

### 5.6 Terminal / review

| Writer | Disposition |
|---|---|
| Start post-game summary | Keep, single owner |
| Clear post-game hold | Via atomic apply / advance complete |
| Finished / no-winner locals after apply | Delete duplicate |
| CANCELLED local transition | **Missing** — add via `shouldRunCancelTransition` + terminal apply |

---

## 6. Complete sync-trigger matrix (prescribed action = one only)

| Trigger | Current behavior (summary) | **Prescribed action** |
|---|---|---|
| `app_resume` | Debounced `syncLatest` → full load | **canonical snapshot fetch** — **ignore/delay if terminal active** |
| `socket_reconnect` | Same resume path | **canonical snapshot fetch** — **ignore/delay if terminal active** |
| `manual_refresh` | Forced network ops | **canonical snapshot fetch** |
| `operation_updated` (full) | Often schedules canonical | **canonical snapshot fetch** (debounced) |
| `operation_updated` (`auto_call_changed`) | Local schedule patch | **local patch only** |
| `operation_updated` (`number_called` reason) | Should be ignored | **ignore** |
| `status_changed` non-terminal | Schedule canonical + called | **canonical snapshot fetch** |
| `status_changed` terminal | Immediate refetch | **terminal transition snapshot** |
| `game:cancelled` | Immediate refetch; no local cancel apply | **terminal transition snapshot** |
| `game:finished` | Immediate refetch; local finish via apply side effects | **terminal transition snapshot** |
| `wallet:updated` | Wallet invalidate only | **ignore** (wallet domain only) |
| Stale countdown (stage 1) | Called-numbers only | **called-numbers fetch only** |
| Stale countdown (stage 2) | Canonical | **canonical snapshot fetch** |
| Invalid payload | Coalesced canonical | **canonical snapshot fetch** (after normalize fail) |
| Number gap | Called-numbers recover | **called-numbers fetch only** |
| Number conflict / unreconciled | Canonical | **canonical snapshot fetch** |
| Number promotes non-live | Local PLAYING invent + canonical | **canonical snapshot fetch** (stop inventing status) |
| bingo_valid / winner_window | Local + often schedule | Patch **local only**; follow-up debounced **canonical** |
| bingo_invalid missing schedule | Schedule canonical | **canonical snapshot fetch** |
| Empty registration closed / preparing poll / lock timeout | Controller immediate refetch | **canonical snapshot fetch** |
| READY advance after review | Load with terminal allow | **terminal transition snapshot** |

---

## 7. Backend vs Flutter implementation differences

| Topic | Backend | Flutter today | Gap / risk |
|---|---|---|---|
| Status authority | Session status + ops current | Socket patches + ops + local holds | Mixed sources → derived mode can desync |
| 2s BINGO lock | **Not a backend timer**; late claim via pattern | Client `kBingoClaimLockSeconds = 2` | OK if treated as UX lock only |
| Auto-call schedule | Owned by backend; thin `operation_updated` | Local schedule patches + sometimes full refetch | Over-refetch / busy rebuilds |
| Winner open events | Prefer `winner_window_started/joined` for auto | Also listens to `bingo_valid` (manual) | Missing sticky patterns if only relying on bingo_valid |
| Cancel transition | Full cancel + refund + opener | Refetch-only; cancel helper unused | CANCELLED→READY ownership gap |
| Finish transition | Burst: status / finished / ops (+ next READY) | Local finish + apply + extra refetch | Double terminal side effects |
| Snapshot API | `GET /games/operations/current` | Used, but dual schedulers | Race / storm |
| Payload shapes | Polymorphic ops updates | Some Map branches skip normalize | `payload[$_get]` style web crashes historically |
| Reconnect truth | Prefer HTTP snapshot | Resume sync present; can race terminal | Resume during terminal not gated hard enough |
| Slot NEXT + READY | Intentional dual | Must not invent “slot==session” | Missed-game / registration target bugs if misunderstood |
| Ops TTL / handoff | Sticky up to ~500ms | Treating HTTP as always fresher than sockets can rewind balls | Same-session rollback risk |

---

## 8. Specific bugs / errors still needed

### 8.1 Socket payload normalization

**Symptom:** `payload[$_get] is not a function` / `normalizedPayload[$_get] is not a function` (web/JS interop).

**Status:** `socket_payload_normalizer.dart` exists and many paths use it.

**Remaining gaps:**

- `live_game_realtime.dart` `operation_updated` Map branch still reads raw keys (`payload['updatedReason']`, etc.) without mandatory normalize-first.
- Any handler that assumes Dart `Map` methods on JS objects can crash.
- Invalid payload must be ignored safely and optionally schedule **one** coalesced canonical refetch — never throw into UI.

**Rule:** No handler reads raw payload fields directly. Normalize → typed map → access. Invalid → ignore + optional refetch.

### 8.2 Auto-call cartela busy scroll / rebuild

**Symptom:** With many cartelas visible, each called number / BINGO lock update feels like the whole list “thrashes.”

**Cause:** Lock/countdown derived from game schedule rebuilds large subtrees; claim buttons rebuild with parent.

**Fix direction:**

- Isolate BINGO lock with `ValueListenable` / small notifier so only buttons rebuild
- Called number updates strip + active number + button enabled state, not whole page
- `RepaintBoundary` around cartela cards if missing
- No full-screen setState on every auto-call tick

### 8.3 Winner dialog delay / pattern flicker

**Symptom:** Valid bingo → winner window opens late; pattern appears, clears, reappears.

**Causes:**

1. Dialog gated on winner-results readiness instead of using `bingo_valid` / `winner_window_*` payload immediately.
2. `LiveReviewController.beginPostGameSummaryAdvance()` calls `clearFinishedReviewVisualState()` **before** READY snapshot apply → empty paint mid-advance.
3. Winner-results polling may apply results that lack patterns and overwrite sticky claim/window patterns.

**Fix direction:**

- `bingo_valid` / winner-window payload is enough for immediate local winner UI
- Store sticky `completedPatterns` immediately
- Polling **enriches only**; never clears patterns until session changes or a final replacement arrives with complete pattern data

### 8.4 Terminal transition UI (CANCELLED → READY)

**Symptom:** Banner/grid hide; live UI stuck; mixed live/ready.

**Causes:**

- No single cancel transition owner
- Old UI not held until new READY snapshot complete
- Banner + grid + game not applied together
- Resume/socket sync can interrupt terminal pin

**Fix direction:** Terminal path only; hold previous UI; atomic READY apply for game + banner + grid; wallet refresh once.

### 8.5 Transition case checklist (must be deterministic)

| Case | Required behavior |
|---|---|
| A. READY → PLAYING | Keep registered cartelas; switch live only after backend truth; do not jump to next READY if player owns cartelas in starting session |
| B. READY → READY | Hold old READY until new READY snapshot ready; replace banner+grid together; no “No game” flash unless backend empty |
| C. PLAYING → CANCELLED → READY | Single terminal owner; hold live UI until READY snapshot; wallet once; no mixed UI |
| D. PLAYING → WINNER_WINDOW → FINISHED → READY | Immediate winner UI from socket; no pattern clear/reappear; review then clean READY |
| E. Resume / reconnect | Short switch: no heavy sync; reconnect: rejoin + fetch once if needed; manual refresh: one sync; no clear on failure; no loops |

### 8.6 Other residual risks (from earlier audits still relevant)

- Release signing still debug keystore risk (see `docs/audit/production_readiness_cleanup_2026-06-24.md`)
- Multi-instance backend socket/cache coherence (infra, not Flutter fix)
- Preparing phase is UI-derived only (OK if lock + ops agree)

---

## 9. Improvement suggestions (ordered by risk / value)

### P0 — Stabilize state ownership

1. **Unify refetch ownership**  
   Delete screen `_scheduleCanonicalRefetch` / `_refetchCanonical` duplicates. All triggers → `LiveRealtimeController`.

2. **Single terminal apply path**  
   FINISHED / NO_WINNER / CANCELLED: one function that applies ops fields, pins review once, leaves room once, and does not schedule a second generic refetch unless satellites missing. Wire CANCELLED through `shouldRunCancelTransition`.

3. **Gate resume/reconnect during terminal**  
   If terminal transition / post-game hold / advancing → ignore or delay `app_resume` / `socket_reconnect` until terminal owner completes.

4. **Monotonic called numbers**  
   Same-session recovery must never roll called list backward. Socket `number_called` during recovery wins over stale HTTP when newer.

### P1 — Winner / pattern / payload

5. **Defer pattern-cache clear** until `sessionChanged` apply (remove clear from `beginPostGameSummaryAdvance`).

6. **Immediate winner UI** from socket payload; winner-results enrich only.

7. **Normalize every socket handler**; fix `operation_updated` raw Map branch; safe-ignore invalid payloads.

8. **Stop inventing PLAYING** from `number_called`; status from `status_changed` / ops only.

### P2 — Performance / UX polish

9. Isolate BINGO lock notifier; reduce cartela list rebuilds; `RepaintBoundary` where useful.

10. Pause preparing poll while `resumeSyncInFlight` / `canonicalRefetchInFlight`.

11. Reduce noisy logs; keep production monitoring hooks only.

12. Enforce “no polling while socket healthy” for called numbers (poll only disconnected path).

### Explicitly out of scope (freeze)

- Backend APIs / DB schema / game rules
- Wallet / registration / bonus logic
- UI visual redesign
- New features

---

## 10. Tests required / gaps

### Keep / extend existing

| Test area | Files (examples) |
|---|---|
| Socket-first number_called / invalid finished | `test/live_game_realtime_cleanup_test.dart` |
| Resume / reconnect debounce | `test/live_reconnect_current_state_sync_test.dart` |
| Ready transition lock | `test/live_ready_transition_lock_test.dart` |
| UI mode matrix | `test/live_ui_mode_test.dart` |
| Finish/cancel helpers + pin | `test/live_game_finish_transition_test.dart`, `live_game_terminal_pin_test.dart` |
| Called-number gap sync | `test/live_called_number_sync_test.dart` |
| Stale guard stages | `test/next_ball_stale_guard_test.dart` |
| Schedule patch normalize | `test/number_called_schedule_patch_test.dart` |
| BINGO lock windows | `test/bingo_claim_hold_test.dart`, `next_ball_countdown_test.dart` |
| Winner display/dialog | `test/winner_cartela_*`, `session_winner_results_for_display_test.dart` |

### Required additions (from handoff)

1. CANCELLED → READY shows registration banner + grid **together**
2. READY → PLAYING keeps registered cartelas; live only after backend truth
3. READY → READY (no players / cancel) shows **no** No-Game flash
4. Valid bingo / winner_window opens winner UI **immediately**
5. Winner pattern does **not** clear if canonical lacks pattern data
6. Same-session recovery cannot roll called numbers backward
7. Socket `number_called` during recovery wins over stale HTTP
8. `app_resume` during terminal is ignored/delayed
9. `operation_updated` duplicate does not start sync loop
10. Raw/JS socket payload does not crash
11. BINGO lock update does not rebuild full cartela list
12. Dual refetch path interaction (screen schedule + controller preparing poll) — assert eliminated after cleanup

---

## 11. Visible UI states (contract for cleanup)

Cleanup must preserve these player-visible states (not redesign them):

1. **Registration Open (READY)** — countdown if allowed; cartela grid + banner together
2. **Missed Game** — live exists; player has no cartelas; next READY registration available
3. **Live (PLAYING)** — cartelas, called strip, active number, BINGO under rule + 2s client lock
4. **Checking** — largely unchanged
5. **Winner Window** — immediate on sufficient socket payload
6. **Finished / Review** — continue/summary; next READY may exist behind review; after review, registration appears cleanly

---

## 12. Production readiness definition of done

Behavior must be boring:

- Socket event → patch UI  
- Terminal event → fetch once → apply once  
- App return → fetch once if needed → apply once  
- Manual refresh → fetch once → apply once  

No sync storm. No reconnect loop. No mixed state. No broken banner/grid. No pattern flicker. No cartela disappearing unless backend confirms it.

### Definition-of-done checklist

- [ ] Single refetch owner (`LiveRealtimeController` only)
- [ ] Single terminal owner including CANCELLED
- [ ] Atomic apply updates game + banner + grid (+ cartelas/called) together on READY replace
- [ ] Pattern cache sticky until session change / complete replacement
- [ ] Resume/reconnect delayed during terminal
- [ ] No invented PLAYING from `number_called`
- [ ] All socket handlers normalize payloads
- [ ] BINGO lock updates do not rebuild full cartela list
- [ ] Required tests green
- [ ] Freeze list honored (backend/wallet/registration untouched)

---

## 13. Post-cleanup freeze list

After cleanup, freeze:

- Registration module  
- Wallet module  
- Bingo validation  
- Backend lifecycle (unless bug-critical)  
- BINGO timing UX contract  
- Auto-call backend contract  

Only allow: bug fixes, production monitoring, load testing, documentation, small UX polish.

---

## 14. Essential implementation entry points

1. `live_game_orchestration.dart` — apply + terminal locals + socket writers  
2. `live_game_realtime.dart` — trigger matrix  
3. `live_realtime_controller.dart` — intended sync owner  
4. `live_transition_controller.dart` — READY handoff  
5. `live_review_controller.dart` + `winner_cartela_live_display.dart` — review/pattern  
6. `live_ui_mode.dart` + `live_presentation_phase.dart` — derived UI gates  
7. `live_game_finish_transition.dart` — pin/cancel/finish rules  
8. `socket_payload_normalizer.dart` — payload safety  
9. `live_game_screen.dart` — state fields + mode wiring  
10. Backend reference only: `game-operations-lifecycle.md`, `game-status.rules.ts`, `games.controller.ts` ops current  

---

## 15. Related documents

| Doc | Purpose |
|---|---|
| `docs/audit/full_live_game_audit.md` | Older full UX/reliability audit (2026-06-17) |
| `docs/audit/full_live_game_audit_detailed.md` | Detailed companion |
| `docs/audit/production_readiness_cleanup_2026-06-24.md` | APK / logging / signing readiness |
| `FriendsBingo/docs/game-operations-lifecycle.md` | Backend freeze lifecycle |
| Handoff brief in conversation | Live transition cleanup + player UI flow |

---

**Bottom line:** Production stability for live play is a **Flutter sync simplification problem**, not a rules rewrite. Collapse to one refetch owner, one atomic apply, and one terminal path (including CANCELLED). Keep socket-first patches only for balls, auto-call schedule, registration metrics, and claim/winner outcomes. Keep presentation derived. Make pattern cache sticky. Then freeze.
