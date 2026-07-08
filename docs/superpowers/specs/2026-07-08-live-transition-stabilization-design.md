# Live Transition Stabilization — Design Spec

**Date:** 2026-07-08  
**Status:** Documentation complete — implementation not started  
**Full audit:** [docs/audit/2026-07-08-live-transition-production-gaps.md](../../audit/2026-07-08-live-transition-production-gaps.md)

## Problem

Flutter live sync has competing writers of `_game`, called numbers, cartelas, presentation holds, and winner-pattern cache. Backend lifecycle is strong and frozen. Stabilize Flutter only.

## Chosen approach

**Controller-owned sync + atomic apply (no redesign).**

1. Delete duplicate screen canonical-refetch pipeline; all triggers go through `LiveRealtimeController`.
2. One terminal path for FINISHED / NO_WINNER / CANCELLED (`requestTerminalCanonicalRefetch` + single apply).
3. Keep safe socket patches: balls, `nextAutoCallAt`, registration metrics, winner/claim local UI.
4. Sticky winner patterns until session change; enrich via winner-results without clear.
5. Gate `app_resume` / `socket_reconnect` while terminal transition is active.
6. Normalize every socket payload before map access.

## Out of scope

Backend APIs, wallet, registration, bingo rules, UI redesign, new features.

## Success criteria

Socket → patch; Terminal → fetch once → apply once; Resume/manual → fetch once if needed → apply once. No mixed READY/live UI, no pattern flicker, no sync storms. Required handoff tests green.

## Next step after approval

Use `writing-plans` to produce a sequenced implementation plan from the gap audit §9–§12.
