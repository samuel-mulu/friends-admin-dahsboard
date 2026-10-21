# Friends Bingo — Full-Stack Game Flow & Reusable Architecture Specification

**Date:** 2026-10-20  
**Status:** In Review  
**Workspaces:** 
- `friends-bingo-mobile` (`d:\FILES\SELF\BINGO\friends-bingo-mobile`)
- `FriendsBingo-backend` (`d:\FILES\SELF\BINGO\FriendsBingo-backend`)

---

## 1. Objectives & Success Criteria

1. **Production-Grade Flow & Invariant Stability:**
   - Eliminate all impossible UI states, race conditions, competing state writers, and silent failures between Flutter mobile app and NestJS backend.
   - Enforce the global invariant: "Backend owns state (`GameSession.status`), clients render via atomic snapshots."
2. **Comprehensive Component Reusability (Mobile):**
   - Dismantle the 10,000+ line God Component (`live_game_screen.dart` and its 5 part-files: orchestration, registration, realtime, called numbers, winner window).
   - Create a clean library of 100% standalone, reusable widgets (`CartelaBoardWidget`, `BingoBallBadge`, `CalledNumbersStrip`, `GameCountdownRing`, `GameActionDock`).
   - Re-architect state management using dedicated Riverpod 3 StateNotifiers with immutable sealed states (`LiveGameState`).
3. **Backend Scalability & Clean Separation:**
   - Decompose `games.service.ts` (~5,500 lines) into isolated domain services.
   - Introduce Redis Socket.IO adapter for horizontal clustering.
   - Migrate in-memory `setInterval` schedulers to persistent BullMQ jobs.
4. **Resolution of Immediate Build Blockers:**
   - Resolve Flutter dependency version conflict for `intl: ^0.20.3`.
   - Remove dead code and orphaned folders (`lib/src/features/gamess`).
   - Enable Awash and BOA deposit options in mobile UI.

---

## 2. System Architecture & Flow Specifications

### 2.1 Complete Game Flow Lifecycle

```
[User Onboarding & Auth]
   ├── Phone validation (+251) & GeezSMS OTP challenge
   ├── Bcrypt password hashing & unique device install UUID welcome bonus check
   └── JWT Access Token + rotating Refresh Token + local PIN/biometric app lock

[Wallet & Financial Settlement]
   ├── Double-entry ledger (WalletTransaction with unique idempotency keys)
   ├── Real-time deposit verification via Verify.ET (Telebirr OCR, CBE, Awash, BOA)
   └── Admin-audited withdrawal locking and payouts

[Game Scheduling & Queue Management]
   ├── GameSlot (queue position, rule, fee, sortOrder) vs GameSession (active round)
   ├── Rule diversity algorithm avoiding consecutive duplicate patterns in top queue
   └── Canonical operations snapshot: GET /games/operations/current

[Ticket Selection & Reservation]
   ├── 75-ball standard cartela catalog pagination
   ├── Temporary hold: 10s individual reservation (120s bulk) via GameCartelaReservation
   ├── Payment resolution: bonus cartela balance first, money wallet balance second
   └── Batched realtime event: session:cartelas_updated & session:prize_updated

[Live Round & Ball Drawing]
   ├── Clock synchronization (ServerClockService offset calibration)
   ├── Transition READY -> PLAYING when scheduledStartAt arrives (auto-cancel if 0 players)
   ├── AutoCallService uniform random ball draw (1-75) every 18 seconds
   ├── Real-time broadcast: game:number_called
   └── Monotonic order validation & local SharedPreferences daub persistence

[Patterns, Claims & Winner Window]
   ├── 15 rule evaluators (FULL_HOUSE, MIX_01 through MIX_14)
   ├── Strict winning-ball invariant: winning pattern MUST include the latest called ball
   ├── False/late claims: claim INVALID, cartela BLOCKED, auto-call resumes immediately
   ├── Valid claim: triggers 25s WINNER_WINDOW (+ 750ms network grace) for co-winners
   └── Expiration: WinnerWindowFinalizerService splits prize equally among all verified winners

[Post-Game & Re-Queue]
   ├── Terminal transition WINNER_WINDOW -> FINISHED (or CANCELLED / NO_WINNER)
   ├── Ledger credits: PRIZE_WIN transactions for all winners
   ├── GameQueueService requeues slot with sortOrder = max + 1 (or removes if removeAfterFinish)
   └── PostGameRegistrationOpenerService opens next READY round after display delay
```

---

## 3. Mobile Modularization & Reusability Blueprint

### 3.1 Directory Structure & Decoupling Plan

```
lib/src/features/games/
├── domain/                      # Immutable domain models & state definitions
│   ├── models/                  # Freezed models: GameModel, CartelaModel, CalledNumberModel
│   └── live_game_state.dart     # Sealed class: Loading, Ready, Playing, WinnerWindow, Finished, Cancelled
├── application/                 # Riverpod Notifiers (Clean separation of concerns)
│   ├── live_game_session_notifier.dart   # Controls session phase & lifecycle transitions
│   ├── called_balls_notifier.dart        # Monotonic ball stream & animations
│   ├── player_cartelas_notifier.dart     # Player cards, local marks, auto-daubing & claims
│   ├── registration_notifier.dart        # Catalog browsing, 10s reservation holds & checkout
│   └── winner_window_notifier.dart       # Co-winner countdown & prize summary
└── presentation/
    ├── components/              # Standalone Pure Presentation Widgets
    │   ├── cartela_board_widget.dart     # 5x5 Grid: reusable in game, dialogs, preview, history
    │   ├── bingo_ball_badge.dart         # B-I-N-G-O ball with dynamic colorways & scale animations
    │   ├── called_numbers_strip.dart     # Auto-scrolling horizontal ball history
    │   ├── game_countdown_ring.dart      # Circular/linear countdown with audio cues
    │   ├── game_status_tag.dart          # Status & category pills
    │   └── game_action_dock.dart         # Floating action buttons (Reserve, Confirm, Claim Bingo)
    ├── dialogs/                 # Modular Dialogs
    │   ├── winner_cartela_dialog.dart
    │   ├── bulk_review_sheet.dart
    │   └── blocked_card_dialog.dart
    └── screens/
        ├── live_game_screen.dart         # Clean, thin coordinator widget (< 350 lines)
        ├── game_history_screen.dart
        └── big_game_screen.dart
```

### 3.2 Reusable Widget Contracts

1. **`CartelaBoardWidget`:**
   - Stateless / pure widget accepting: `cartela`, `markedCells`, `winningPatternCells`, `winningBallNumber`, `isBlocked`, `isWinner`, `interactive`, `onCellTapped`, and `boardSize` (`compact`, `standard`, `preview`).
   - Zero dependency on `LiveGameScreen` or Riverpod providers.
2. **`BingoBallBadge`:**
   - Derives letter (`B`, `I`, `N`, `G`, `O`) and colorway automatically from number:
     - 1–15: Red (`B`)
     - 16–30: Orange (`I`)
     - 31–45: Blue (`N`)
     - 46–60: Green (`G`)
     - 61–75: Purple (`O`)
3. **`CalledNumbersStrip`:**
   - Displays history with animated entry for latest drawn ball; emits `onBallTap` for detail popup.

---

## 4. Backend Refactoring & Scalability Blueprint

### 4.1 Decomposition of `games.service.ts`

Extract into 4 focused services under `src/games/services/`:
1. **`GameSlotService`:** Admin slot CRUD, category configuration, and queue sorting with rule diversity.
2. **`GameSessionService`:** State machine transitions (`NEXT -> READY -> PLAYING -> WINNER_WINDOW -> FINISHED`), empty-session auto-cancel, and requeuing.
3. **`GameRegistrationService`:** Reservation holds, expiry management, quota enforcement, and payment resolution (bonus balance vs wallet cash).
4. **`GameOperationsQueryService`:** `GET /games/operations/current` aggregation, caching, and cache invalidation.

### 4.2 Multi-Instance & Real-Time Scalability

1. **Redis Socket.IO Adapter:**
   - Integrate `@socket.io/redis-adapter` into `RealtimeGateway`.
   - Allows multiple NestJS nodes behind Nginx/load balancer to seamlessly broadcast socket events (`game:number_called`, `game:winner_window_started`) across nodes.
2. **Distributed Job Scheduling with BullMQ:**
   - Migrate `AutoCallService`, `GameAutoStartSchedulerService`, and `WinnerWindowFinalizerService` to BullMQ queues backed by Redis.
   - Guarantees exactly-once execution of ball draws even during process crashes or horizontal scaling.

---

## 5. Execution Roadmap: 4-Phase Sprint

- **Phase 1: Immediate Fixes & Hygiene (Day 1–3)**
  - Update `intl: ^0.20.3` and update `pubspec.lock`.
  - Remove empty directory `lib/src/features/gamess`.
  - Enable Awash and BOA in `deposit_screen.dart`.
- **Phase 2: Mobile Modularization & Reusable UI (Day 4–14)**
  - Build standalone presentation components: `CartelaBoardWidget`, `BingoBallBadge`, `CalledNumbersStrip`, `GameCountdownRing`.
  - Implement Riverpod 3 StateNotifiers (`LiveGameSessionNotifier`, `CalledBallsNotifier`, `PlayerCartelasNotifier`, `RegistrationNotifier`).
  - Refactor `LiveGameScreen`, eliminating the 5 part-files and 10,000 lines of boilerplate.
- **Phase 3: Backend Scalability & Invariant Hardening (Day 15–25)**
  - Configure Redis Socket.IO adapter.
  - Activate BullMQ distributed job scheduling.
  - Decompose `games.service.ts` into isolated domain services.
- **Phase 4: Admin Dashboard & Production Load Verification (Day 26–30)**
  - Fix Admin socket authentication.
  - Run multi-client concurrent claim load tests.
