# Friends Bingo — Mobile ↔ Backend Integration Analysis

**Date:** 2026-07-08
**Scope:** `friends-admin-dahsboard` (Flutter client) ↔ `FriendsBingo` (NestJS + PostgreSQL backend)
**Question answered:** Is the full game flow fully integrated, functional, stable, and production-ready — and what remains to close the last 10%?
**Method:** Read-only verification of the actual source (socket contract, HTTP contract, live orchestration, controllers), cross-checked against the *Live Transition Cleanup & Developer Handoff* brief and the prior `2026-07-08-live-transition-production-gaps.md` audit.

> **Update (this session):** the fixes in sections 4/4B were subsequently applied to the code, and **all automated test code was removed at the owner's request** (Flutter `test/`, backend `test/` + `*.spec.ts`, admin `*.test.ts`). See the [Session change log & remaining risk](#16-session-change-log--remaining-risk) at the end. References to specific test files elsewhere in this document describe coverage that existed at audit time and no longer exists.

---

## 1. Verdict

**The integration is complete and functional.** Every backend socket event has a matching Flutter handler, every live/registration HTTP endpoint the client needs exists and is consumed, and the game lifecycle (READY → PLAYING → CHECKING → WINNER_WINDOW → FINISHED/NO_WINNER/CANCELLED → next READY) is wired end-to-end on both sides.

**More importantly:** the majority of the cleanup described in the handoff brief has *already been implemented*. Several items the handoff and the earlier gap audit list as "still broken" are, in the current code, fixed and covered by dedicated tests. The remaining work is smaller than the brief implies and is mostly (a) one genuine architectural simplification still outstanding, (b) infrastructure/release items, and (c) polish.

The product is **not yet production-ready** for one hard reason unrelated to game logic: **the release build is signed with the debug keystore.** That is a ship blocker. The live-sync concerns are now largely stability polish rather than correctness bugs.

---

## 2. Integration completeness — verified

### 2.1 Socket event coverage (100%)

Every event the backend emits has a Flutter `.on()` handler.

| Backend emits (`FriendsBingo/src`) | Flutter handler (`lib/src`) |
|---|---|
| `game:status_changed` | ✅ |
| `game:operation_updated` | ✅ (routed through trigger matrix) |
| `game:number_called` | ✅ |
| `game:bingo_checking` / `bingo_claimed` / `bingo_valid` / `bingo_invalid` | ✅ (all four) |
| `game:winner_window_started` / `winner_window_joined` | ✅ |
| `game:finished` / `game:cancelled` | ✅ |
| `session:cartelas_updated` / `session:prize_updated` | ✅ |
| `slot:status_changed` / `slot:entry_fee_updated` | ✅ |
| `wallet:updated` / `withdrawal:updated` | ✅ |
| `my_cartela:registered` / `admin:broadcast(_removed)` | ✅ |

No dangling events on either side.

### 2.2 HTTP snapshot contract (complete)

The client consumes the full operations/registration surface: `GET /games/operations/current` (canonical live snapshot), `/games/sessions/:id/registration-state`, `/my-cartelas`, `/called-numbers`, `/winner-results`, `/bingo`, plus slot/session register, bulk reserve/confirm/cancel, time-config, history. This matches the backend controllers. Snapshot-first recovery is fully supported by the API.

### 2.3 Lifecycle wiring

Backend owns all state (`GameSession.status` + ops-current selection + auto-call `nextAutoCallAt`); the client renders and patches. The intended "backend decides, Flutter renders" rule from the brief is respected in code — the client no longer invents status (see 3.4).

---

## 3. Handoff cleanup items — what is already DONE

These were flagged as risks/bugs in the brief and the earlier gap audit. Verification shows they are implemented in the current tree. This is the biggest correction to the handoff narrative.

### 3.1 Single refetch owner — DONE (the headline architectural fix)
The earlier audit's "critical defect: dual refetch ownership" is resolved. `LiveRealtimeController` is now the single owner of canonical refetch. The screen-level methods (`_scheduleCanonicalRefetch`, `_refetchCanonical`, `_refetchCanonicalImmediate` in `live_game_orchestration.dart`) are now **thin delegates** that forward to `_realtime.*` — not a competing pipeline with its own debounce/pending state.
*Residual:* the wrapper methods still exist as pass-throughs (cosmetic dedup opportunity), but there is no longer a second live queue.

### 3.2 Sync-trigger matrix — DONE
`live_game_realtime.dart` routes `game:operation_updated` through `resolveLiveSyncTriggerAction(...)`, which returns exactly one action (`ignore` / `localPatchOnly` / `canonicalSnapshotFetch`). `auto_call_changed` → local patch only; `number_called`-reason ops → ignore; full ops → one debounced canonical fetch. This matches the prescribed one-action-per-trigger table in the brief.

### 3.3 Socket payload normalization — DONE
Every handler I inspected (`number_called`, `operation_updated`, `cancelled`, `status_changed`, `winner_window_*`, `entry_fee_updated`) calls `_normalizeSocketPayloadForEvent(...)` first and bails safely on `null`. Registration-metrics helpers receive an already-typed `Map<String,dynamic>`. Covered by `test/live_socket_normalize_first_test.dart`. The historical `payload[$_get] is not a function` web crash class is addressed.

### 3.4 No invented PLAYING from `number_called` — DONE
`_onNumberCalled` patches only called-numbers + auto-call schedule; it skips terminal statuses, and routes order-conflict / duplicate / session-mismatch to canonical refetch instead of mutating status. Covered by `test/number_called_no_status_invent_test.dart` and `live_called_number_monotonic_test.dart`.

### 3.5 Cancel transition ownership — WIRED (was reported unused)
`shouldRunCancelTransition(...)` is called in `_onGameCancelled` (`live_game_orchestration.dart:806`) and gates a single `requestTerminalCanonicalRefetch(reason: 'game_cancelled')`. The earlier audit's claim that this helper is "unused in production" is **stale**. (See 4.1 for the remaining nuance — it is refetch-only, not a held-UI atomic apply.)

### 3.6 Winner pattern sticky — DONE
`LiveReviewController.beginPostGameSummaryAdvance()` explicitly does **not** clear `winnerCartelaDisplay` (comment + code at line 404: "wait for sessionChanged apply"). The pattern-clear-then-reappear bug the brief describes (§8.3 point 2) is fixed. Covered by `test/winner_pattern_sticky_test.dart` and `winner_cartela_live_display_test.dart`.

### 3.7 Terminal side-effects run once + resume gating — DONE
`shouldEnterTerminalSideEffects(...)` guards finished/no-winner local handling so it cannot double-fire; resume/reconnect is gated during terminal via `live_terminal_enter_policy.dart`. Covered by `live_terminal_side_effects_once_test.dart`, `live_resume_terminal_gate_test.dart`, `live_terminal_refetch_routing_test.dart`.

### 3.8 BINGO-lock rebuild isolation — DONE
`RepaintBoundary` is present around cartela cards, and BINGO lock state uses `ValueListenable`/notifier rather than full-page setState. Covered by `test/bingo_lock_rebuild_isolation_test.dart`.

### 3.9 Test coverage for the brief's required cases — LARGELY PRESENT
Dedicated tests exist for essentially all 12 required additions: normalize-first, number-called monotonic/reconcile/no-invent, resume terminal gate, terminal refetch routing, terminal side-effects once, ready-transition lock, winner pattern sticky, winner dialog, reconnect current-state sync. This is strong for a pre-production codebase.

---

## 4. What still needs fixing / improving

Prioritized. P0 = production blocker, P1 = stability/correctness residual, P2 = polish/scale.

### P0 — Release blockers (not game logic)

**P0-1. Release build uses the debug keystore.**
`android/app/build.gradle` release block: `signingConfig = signingConfigs.getByName("debug")` with a `TODO`. No `key.properties`/`.jks` present. A debug-signed release cannot be safely distributed (no upgrade path, weak key). Create a real upload/signing keystore + `key.properties`, wire a `release` signing config, and keep the keystore out of VCS. **Must fix before shipping.**

### P1 — Live-sync residuals (correctness/UX, low risk)

**P1-1. CANCELLED → READY is refetch-only, not a held-UI atomic apply.**
`_onGameCancelled` is correctly gated and single-owner, but it relies on `requestTerminalCanonicalRefetch` to pull the next READY snapshot. There is no first-class "hold previous live UI, then apply banner + grid + game together" cancel apply equivalent to what finish/review has. Under a slow refetch this is the most likely place to still see a brief mixed or empty state between CANCELLED and the next READY. **Improve:** guarantee old UI is pinned until the READY snapshot lands, and apply banner+grid+game in one `setState`. Add the test "CANCELLED → READY shows registration banner + grid together" if not already asserted.

**P1-2. Finish path still has separate local mutators.**
`_handleGameFinishedLocally`, `_handleNoWinnerLocally`, and `_enterFinishedReviewFromExpiredWindow` still mutate `_game` alongside `_applyCanonicalGame`. They are gated (so no double-fire) but this is still multi-writer for the terminal outcome. **Improve (optional):** fold outcome fields into the single terminal atomic apply so there is exactly one writer for FINISHED/NO_WINNER. Lower risk than it sounds because the gate already prevents duplication.

**P1-3. Remove the screen-level refetch wrapper indirection.**
Now that `LiveRealtimeController` is the owner, the `_scheduleCanonicalRefetch` / `_refetchCanonical(Immediate)` pass-throughs in the screen add a layer without behavior. Deleting them and calling `_realtime.*` directly reduces the surface where a future edit could reintroduce a second pipeline.

**P1-4. Winner dialog immediacy — confirm gating on socket payload, not results poll.**
Sticky patterns are fixed (3.6). Verify the *dialog open* itself triggers on the `bingo_valid` / `winner_window_started` payload immediately and that `winner-results` polling only enriches. Tests exist (`winner_cartela_dialog_test`, `session_winner_results_for_display_test`); add an explicit "winner UI opens immediately from socket, before results arrive" assertion if missing.

### P2 — Scale & polish

**P2-1. No Redis Socket.IO adapter (single-instance only).**
`redis` is a dependency but no `createAdapter`/`useWebSocketAdapter` is wired in backend bootstrap. Rooms and broadcasts work only within one process. Horizontal scaling (multiple backend instances behind a load balancer) would silently drop cross-instance socket delivery, and auto-call has no leader election. Fine for a single-instance deployment; **required before multi-instance scale-out.** This is infra, not a client fix.

**P2-2. Inherent backend caveats the client must keep healing.**
These are contract realities, already handled but worth freezing as known behavior: event bursts on cancel/finish/window; polymorphic `operation_updated` (thin auto-call delta vs full ops); ops-current cache TTL (~500ms) so sockets can briefly lead HTTP; finish may open the next READY before the finished event. The client's monotonic called-number guard and snapshot-first recovery already absorb these; do not "fix" them by making HTTP always override sockets (that reintroduces ball rollback).

**P2-3. Logging / debug noise.**
`LiveRealtimeDebug` logging is pervasive in the live path. Gate behind a build flag for release to reduce overhead and log spam.

**P2-4. Manual/load verification.**
Run the backend `staging-registration-load-test` and a soak test on READY↔READY churn and cancel→ready with 10+ cartelas to confirm no rebuild thrash in practice (the isolation tests cover the widget contract; a device soak confirms the felt behavior).

---

## 4B. Deep-dive: app-resume duplication, transition glitch & KISS complexity

This section addresses the three specific concerns raised: (a) duplicate sync on app resume during a transition, (b) UI glitch when switching from one UI state to another, and (c) whether the design is more complex than KISS wants.

### 4B.1 App-resume / reconnect duplicate sync — mostly SOLVED, one hole

The duplicate-sync-at-transition case is guarded by **four** cooperating mechanisms, and in practice a double resume collapses into a single run:

1. **`AppBackgroundResumeGate`** — a quick foreground return (`< 2s`, socket still connected) is *skipped entirely* (`quick_return_*`). Only real away-time or a socket drop triggers a full sync.
2. **`shouldRunResumeSync` (terminal gate)** — `app_resume` and `socket_reconnect` are **ignored** while `postGameSummaryReviewActive || postGameSummaryAdvancing || terminalCanonicalRefetchInFlight`. So resume cannot fight a terminal apply.
3. **`ResumeSyncGuard.inFlight` + shared completer** — if a second resume/reconnect arrives while one is running, it does **not** start a second sync; its reason is added to `_collectedResumeReasons` and it awaits the same completer. App-resume + socket-reconnect firing together therefore coalesce into **one** network sync.
4. **Debounce timer + `ResumeAuxiliaryRefreshGate`** — resume-class reasons are debounced, and wallet/registration refetch is throttled to one per 2s on focus churn.

**The one real hole:** `shouldRunResumeSync` returns `true` unconditionally for `manual_refresh` (`live_resume_terminal_gate.dart:21`). A manual pull-to-refresh performed *during* a terminal transition is **not** terminal-gated and will run a full canonical sync that can race the terminal apply — the exact "duplicate at transition" symptom. **Fix:** gate `manual_refresh` behind the terminal check too (or queue it until the terminal owner completes), instead of exempting it.

### 4B.2 UI glitch when switching states — root causes

The remaining flicker at change-time is not a duplicate-data problem (that's coalesced); it is a **presentation** problem in two spots:

1. **Non-atomic CANCELLED → READY** (P1-1). This is the single biggest glitch source: the cancel path is refetch-only, so between the terminal event and the READY snapshot landing there is a window where the old live UI can drop before the new banner+grid arrives. Finish/review has a held atomic apply; cancel does not. **Fix:** pin previous UI and apply game+banner+grid in one `setState` on the READY snapshot, mirroring the finish path.
2. **Sync overlay / "current" badge churn.** `_prepareSyncUi` schedules a delayed `_syncOverlayVisible`, and `_clearSyncUi` runs a `_currentBadgeTimer`, each calling `markNeedsBuild()`. The delay avoids most flashes, but when a resume overlaps a state change the overlay/badge is an extra visual layer painting over held UI. **Fix:** suppress the sync overlay entirely while the ready-transition lock or terminal hold is active — the held UI should never show a spinner on top of itself.

Everything else (READY→PLAYING, WINNER_WINDOW, resume/reconnect) applies cleanly and is test-covered; the felt glitches concentrate on CANCELLED→READY.

### 4B.3 Why it looks complex vs. KISS

The KISS target is three sentences: *socket → patch; recovery → fetch once → apply once; terminal → fetch once → apply once.* The code **behaves** that way, but reasoning about it is hard because the resume path alone now spans **four guard objects across four files** (`ResumeSyncGuard`, `AppBackgroundResumeGate`, `ResumeAuxiliaryRefreshGate`, `shouldRunResumeSync`) plus a debounce timer, a coalescing completer, a sync-overlay timer, and a current-badge timer. Each was added to kill one specific glitch, and each is individually correct — but the layering is itself the anti-KISS smell: it is easy to add a *fifth* guard and hard to see the whole.

This is accidental complexity, not essential complexity. The essential complexity (backend event bursts, polymorphic `operation_updated`, ~500ms ops TTL) is small. Recommended simplification — behavior-preserving, no new features:

- Collapse the four resume guards into **one** `ResumeCoordinator` with a single documented decision (`skip | coalesce | run`) so there is one place to read the resume rules.
- Delete the screen-level refetch wrappers (P1-3) so `LiveRealtimeController` is unambiguously the only sync surface.
- Give CANCELLED the same single atomic apply as FINISH (P1-1), removing the separate finish local mutators (P1-2) at the same time.
- Add a one-page "sync ownership" doc/diagram at the top of `live_realtime_controller.dart` so the next developer sees the three-path model without tracing four files.

After that, the machinery matches the KISS diagram not just in behavior but in shape — which is what makes it stay boring.

## 5. Transition-case status (brief §A–E)

| Case | Status | Note |
|---|---|---|
| A. READY → PLAYING | ✅ Solid | No invented PLAYING; cartelas kept; live only on backend truth. |
| B. READY → READY | ⚠️ Mostly | Ready-transition lock holds old READY; confirm no "No game" flash on empty/cancel via `live_ready_transition_lock_test`. |
| C. PLAYING → CANCELLED → READY | ⚠️ Refetch-only | Gated single owner, but no held-UI atomic cancel apply (**P1-1**). Highest-residual case. |
| D. PLAYING → WINNER_WINDOW → FINISHED → READY | ✅ Good | Sticky patterns fixed; terminal side-effects once; verify dialog immediacy (**P1-4**). |
| E. Resume / reconnect | ✅ Good | Terminal-gated, snapshot-first, monotonic numbers; covered by resume/reconnect tests. |

---

## 6. Recommended freeze (after P0 + P1-1)

Consistent with the brief: freeze backend lifecycle, wallet, registration, bonus, bingo validation, BINGO 2s client lock, auto-call contract, and socket event **names**. Post-cleanup allow only bug fixes, monitoring, load testing, docs, and small UX polish.

---

## 7. Bottom line

The mobile↔backend integration is **functionally complete and largely stabilized** — most of the handoff cleanup is already in the tree. The remaining game-flow work is one atomic cancel→ready apply (P1-1) plus small dedup/polish. The only true production blocker is the **debug release signing (P0-1)**, and multi-instance scale needs the **Redis adapter (P2-1)** before horizontal scaling. Close those and the behavior meets the "boring" definition of done the brief asks for.

---

## 16. Session change log & remaining risk

### 16.1 Changes applied this session (Flutter client + Android config only)

All changes respect the freeze list — no backend, wallet, registration, game-rule, bonus, or UI-design code was touched.

1. **manual_refresh terminal gate** — `live_sync_trigger_action.dart` + `live_resume_terminal_gate.dart`. `manual_refresh` now resolves to `ignore` while a terminal transition is active, closing the one ungated race path (app_resume/reconnect were already gated). Outside terminal, manual refresh behaves exactly as before. Rationale: the terminal owner already fetches canonical truth, so a concurrent manual sync could only race the atomic apply.

2. **Sync overlay suppressed during terminal transition** — `live_realtime_controller.dart` `showSyncOverlay`. The sync spinner no longer paints over held UI while `isTerminalTransitionActive`, removing the "glitch at the change time" during CANCELLED/FINISHED → READY.

3. **CANCELLED/FINISHED → READY hold (no empty flash)** — `live_game_orchestration.dart` canonical-apply empty branch. When the backend transiently reports no current/queued game *during* a terminal transition, the previous UI is now held instead of being torn down; the next READY snapshot (delivered by the status/operation socket events that always follow) re-applies atomically. Self-bounding: `isTerminalTransitionActive` expires ~3s after the terminal refetch, after which a genuinely empty state clears normally. This is the direct fix for the P1-1 cancel glitch.

4. **Dead code removed** — deleted the unused `_refetchCanonical` screen wrapper (zero callers; `_refetchCanonicalImmediate` and `_scheduleCanonicalRefetch` are still used and unchanged).

5. **Release signing wired** — `android/app/build.gradle.kts` now signs release builds with a real upload keystore when `android/key.properties` exists, falling back to the debug key otherwise. Added `android/key.properties.example`. `key.properties` and `*.jks/*.keystore` were already gitignored. **The owner must still generate the keystore and create `key.properties`** — see the example file. This removes the code-level blocker; the operational step remains.

6. **All test code removed** across the three projects at the owner's request.

### 16.2 Verification status

These edits were verified by source inspection and cross-reference (call-site checks, scope checks, brace balance). **They were not compiled or run** — there is no Flutter/Dart toolchain in this environment, and the automated test suite has been deleted. Before shipping, a developer must run `flutter analyze` and `flutter build apk --release` (and `flutter build appbundle`) on a real toolchain to confirm compilation and signing.

### 16.3 Remaining risk (ordered)

- **[Blocker – operational] Release keystore not yet created.** Code is ready; the owner must generate the upload keystore and `android/key.properties`. Until then release builds still fall back to the debug key.
- **[High – process] No automated tests.** The suite that guarded live-sync invariants (normalize-first, monotonic numbers, terminal gating, sticky patterns, no-invent-status, refetch ownership) is gone. Any future change to the live path now has no safety net; regressions will only surface in manual/device testing. Recommend re-introducing at least the live-sync invariant tests before further live-path edits.
- **[Medium] Terminal-hold reliability depends on a follow-up event.** The CANCELLED→READY hold assumes the next READY status/operation socket event (or the ~3s terminal-window expiry) will re-trigger the apply. This is how the flow already completed pre-change, so risk is low, but if those events are dropped the UI holds the finished game until manual refresh (which works once the terminal window expires). Manual device verification of cancel→ready recommended.
- **[Medium] Manual refresh is a no-op for ~≤3s during a terminal transition.** Intended trade-off to prevent the race. A user pulling to refresh in that window gets fresh data from the terminal fetch, not their manual one; it works normally immediately after.
- **[Medium – scale] No Redis Socket.IO adapter (P2-1).** Single-instance only; horizontal scale-out still requires the adapter + auto-call leader election. Unchanged this session.
- **[Low] Finish path retains separate local mutators (P1-2)** and the screen refetch wrappers still exist as thin delegates (P1-3). Gated and correct, not touched this session to limit blast radius without a test net. Optional future dedup.
- **[Low] Guard consolidation (`ResumeCoordinator`) not done.** The four resume guards still work correctly; consolidation deferred as it is a behavior-preserving refactor best done with tests in place.
