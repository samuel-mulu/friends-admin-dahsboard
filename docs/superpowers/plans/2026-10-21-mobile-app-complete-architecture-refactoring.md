# Mobile App Complete Architecture Refactoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the entire mobile application (`friends-bingo-mobile`) into a feature-first clean architecture where no screen or file exceeds 600 lines (target < 250–400 lines), state is managed via testable Riverpod controllers and domain coordinators, presentation widgets are modular and decoupled, and zero functionality or real-time gaming behavior is degraded.

**Architecture:** 
1. **Domain-Driven Coordinators:** Deconstruct the 12,000+ line live game mixins into focused, single-responsibility lifecycle and state coordinators (`LiveChainGameCoordinator`, `LiveWinnerCelebrationCoordinator`, `LiveResumeSyncCoordinator`, `LiveBingoClaimCoordinator`, `LiveWinnerWindowCoordinator`).
2. **Pure Presentation Components:** Extract giant nested widget builders into isolated, reusable Flutter widgets that depend only on immutable data models and callbacks.
3. **Feature-First Organization:** Place all widgets, controllers, and domain utilities inside their respective feature folder (`lib/src/features/<feature>/presentation/...`).
4. **Strict Line Count Gating:** Hard rule: 0 files > 600 lines; target 150–350 lines per file.

**Tech Stack:** Flutter 3.x, Dart 3.x, Flutter Riverpod, GoRouter, audioplayers, socket_io_client.

## Global Constraints
- **Line Count Cap:** No single `.dart` file may exceed 600 lines. Any file reaching 400 lines must be reviewed for sub-component extraction.
- **Zero Real-Time Gameplay Regression:** Socket events (`game:number_called`, `game:status_changed`, `game:winner_window_started`, `game:bingo_checking`, `game:chain_round_started`), ball voice calls, auto-daubing, and claim idempotency must maintain 100% fidelity.
- **Static Analysis Gate:** `flutter analyze --no-fatal-infos lib test` must pass with 0 errors and 0 warnings after every single task.
- **Test Integrity:** All 564 existing mobile tests must continue to pass throughout every refactoring step, supplemented by new unit and widget tests for every extracted coordinator.

---

## File Line Count Audit & Target Roadmap

| Priority | Component / File | Current Lines | Target Lines | Phase |
|---|---|---|---|---|
| **P1** | `live_game_orchestration.dart` | 5,277 | < 450 | Phase 2 |
| **P1** | `live_game_screen.dart` | 3,616 | < 350 | Phase 2 |
| **P2** | `live_game_registration.dart` | 2,080 | < 350 | Phase 3 |
| **P2** | `live_game_called_numbers.dart` | 1,035 | < 300 | Phase 3 |
| **P2** | `cartela_registration_sheet.dart` | 1,095 | < 350 | Phase 3 |
| **P3** | `cartela_marked_pattern_evaluator.dart` | 1,528 | < 400 | Phase 4 |
| **P3** | `game_rule_pattern_preview.dart` | 1,194 | < 350 | Phase 4 |
| **P3** | `live_ui_mode.dart` | 1,075 | < 300 | Phase 4 |
| **P4** | `app_settings_drawer.dart` | 1,752 | < 350 | Phase 5 |
| **P4** | `game_history_detail_dialog.dart` | 668 | < 300 | Phase 5 |
| **Completed** | `withdraw_screen.dart` | 757 -> 130 | < 250 | Phase 1 (Done) |
| **Completed** | `deposit_screen.dart` | 1,585 -> 229 | < 250 | Phase 1 (Done) |

---

## Phase 2: Live Game Orchestration & Screen Decomposition

### Task 1: Extract `LiveChainGameCoordinator` (Chain Game Round Delays & Round Plan)

**Files:**
- Create: `lib/src/features/games/presentation/controllers/live_chain_game_coordinator.dart`
- Test: `test/features/games/live_chain_game_coordinator_test.dart`
- Modify: `lib/src/features/games/presentation/screens/live_game_orchestration.dart:30-80`

**Interfaces:**
- Consumes: `GameModel`, `ServerClockService`, `GamesRepository`
- Produces: `LiveChainGameCoordinator` managing chain pause countdown ticker, round transitions, and inter-round dialog latch.

- [ ] **Step 1: Write failing unit test for `LiveChainGameCoordinator`**

```dart
// test/features/games/live_chain_game_coordinator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_chain_game_coordinator.dart';

void main() {
  test('LiveChainGameCoordinator accurately computes remaining pause seconds', () {
    final now = DateTime.now();
    final pauseEndsAt = now.add(const Duration(seconds: 15));
    final coordinator = LiveChainGameCoordinator();
    
    coordinator.syncPauseDeadline(pauseEndsAt);
    expect(coordinator.isPaused, isTrue);
    expect(coordinator.remainingSeconds(now), 15);
    
    coordinator.clearPause();
    expect(coordinator.isPaused, isFalse);
    expect(coordinator.remainingSeconds(now), 0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/games/live_chain_game_coordinator_test.dart`  
Expected: FAIL (class not found).

- [ ] **Step 3: Implement `LiveChainGameCoordinator`**

```dart
// lib/src/features/games/presentation/controllers/live_chain_game_coordinator.dart
import 'package:flutter/foundation.dart';
import '../../data/models/chain_round_plan_model.dart';
import '../../data/models/game_model.dart';

class LiveChainGameCoordinator {
  final ValueNotifier<DateTime?> pauseEndsAtListenable = ValueNotifier(null);
  ChainRoundPlanModel? activePlan;

  bool get isPaused => pauseEndsAtListenable.value != null;

  void syncPauseDeadline(DateTime? deadline) {
    pauseEndsAtListenable.value = deadline;
  }

  void clearPause() {
    pauseEndsAtListenable.value = null;
  }

  int remainingSeconds(DateTime serverNow) {
    final deadline = pauseEndsAtListenable.value;
    if (deadline == null) return 0;
    final diff = deadline.difference(serverNow).inSeconds;
    return diff > 0 ? diff : 0;
  }

  void dispose() {
    pauseEndsAtListenable.dispose();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/games/live_chain_game_coordinator_test.dart`  
Expected: PASS.

- [ ] **Step 5: Wire coordinator into `live_game_orchestration.dart` and commit**

Replace lines 30-80 of `live_game_orchestration.dart` with delegated calls to `LiveChainGameCoordinator`. Run `flutter test` and `git commit -m "refactor(games): delegate chain game pause orchestration to LiveChainGameCoordinator"`.

---

### Task 2: Extract `LiveWinnerCelebrationCoordinator` (Winner Cards, Dialogs & Podium)

**Files:**
- Create: `lib/src/features/games/presentation/controllers/live_winner_celebration_coordinator.dart`
- Create: `lib/src/features/games/presentation/widgets/live_winner_celebration_overlay.dart`
- Test: `test/features/games/live_winner_celebration_coordinator_test.dart`
- Modify: `lib/src/features/games/presentation/screens/live_game_orchestration.dart:750-950`

**Interfaces:**
- Consumes: `SessionWinnerResultModel`, `GameCartelaModel`, `SoundService`
- Produces: `LiveWinnerCelebrationCoordinator` isolating winner history caching, dialog debounce, and winner audio fanfares.

- [ ] **Step 1: Write failing unit test for `LiveWinnerCelebrationCoordinator`**

```dart
// test/features/games/live_winner_celebration_coordinator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_winner_celebration_coordinator.dart';

void main() {
  test('LiveWinnerCelebrationCoordinator tracks winner cartelas without duplicates', () {
    final coordinator = LiveWinnerCelebrationCoordinator();
    coordinator.recordWinnerCartela(42);
    coordinator.recordWinnerCartela(42);
    coordinator.recordWinnerCartela(17);
    
    expect(coordinator.winnerCartelaNumbers, equals([42, 17]));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/games/live_winner_celebration_coordinator_test.dart`  
Expected: FAIL.

- [ ] **Step 3: Implement `LiveWinnerCelebrationCoordinator`**

```dart
// lib/src/features/games/presentation/controllers/live_winner_celebration_coordinator.dart
import 'package:flutter/foundation.dart';
import '../../data/models/session_winner_result_model.dart';
import '../../data/models/game_cartela_model.dart';

class LiveWinnerCelebrationCoordinator {
  final List<int> _winnerCartelaNumbers = [];
  final Map<int, GameCartelaModel> _winnerCards = {};
  bool isDialogOpen = false;

  List<int> get winnerCartelaNumbers => List.unmodifiable(_winnerCartelaNumbers);
  Map<int, GameCartelaModel> get winnerCards => Map.unmodifiable(_winnerCards);

  void recordWinnerCartela(int number, [GameCartelaModel? card]) {
    if (!_winnerCartelaNumbers.contains(number)) {
      _winnerCartelaNumbers.add(number);
    }
    if (card != null) {
      _winnerCards[number] = card;
    }
  }

  void reset() {
    _winnerCartelaNumbers.clear();
    _winnerCards.clear();
    isDialogOpen = false;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/games/live_winner_celebration_coordinator_test.dart`  
Expected: PASS.

- [ ] **Step 5: Wire coordinator into `live_game_orchestration.dart` and commit**

Delegate winner recording and review dialogs to `LiveWinnerCelebrationCoordinator`. Run `flutter test` and `git commit -m "refactor(games): delegate winner celebration and dialog tracking to LiveWinnerCelebrationCoordinator"`.

---

### Task 3: Extract `LiveResumeSyncCoordinator` (Reconnection, Socket Anchoring & Re-fetch)

**Files:**
- Create: `lib/src/features/games/presentation/controllers/live_resume_sync_coordinator.dart`
- Test: `test/features/games/live_resume_sync_coordinator_test.dart`
- Modify: `lib/src/features/games/presentation/screens/live_game_orchestration.dart:80-350`

**Interfaces:**
- Consumes: `GamesRepository`, `SocketService`, `ResumeSyncGuard`
- Produces: `LiveResumeSyncCoordinator` coordinating app resume, network reconnect, and operations cache refreshes.

- [ ] **Step 1: Write failing unit test for `LiveResumeSyncCoordinator`**

```dart
// test/features/games/live_resume_sync_coordinator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_resume_sync_coordinator.dart';

void main() {
  test('LiveResumeSyncCoordinator prevents concurrent resume runs', () async {
    final coordinator = LiveResumeSyncCoordinator();
    expect(coordinator.isSyncInProgress, isFalse);
    
    final lockAcquired = coordinator.tryAcquireSyncLock();
    expect(lockAcquired, isTrue);
    expect(coordinator.isSyncInProgress, isTrue);
    
    final secondLock = coordinator.tryAcquireSyncLock();
    expect(secondLock, isFalse);
    
    coordinator.releaseSyncLock();
    expect(coordinator.isSyncInProgress, isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/games/live_resume_sync_coordinator_test.dart`  
Expected: FAIL.

- [ ] **Step 3: Implement `LiveResumeSyncCoordinator`**

```dart
// lib/src/features/games/presentation/controllers/live_resume_sync_coordinator.dart
import 'package:flutter/foundation.dart';

class LiveResumeSyncCoordinator {
  bool _syncInProgress = false;
  DateTime? _lastSyncCompletedAt;

  bool get isSyncInProgress => _syncInProgress;
  DateTime? get lastSyncCompletedAt => _lastSyncCompletedAt;

  bool tryAcquireSyncLock() {
    if (_syncInProgress) return false;
    _syncInProgress = true;
    return true;
  }

  void releaseSyncLock() {
    _syncInProgress = false;
    _lastSyncCompletedAt = DateTime.now();
  }

  bool isSyncStale(Duration threshold) {
    final last = _lastSyncCompletedAt;
    if (last == null) return true;
    return DateTime.now().difference(last) > threshold;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/games/live_resume_sync_coordinator_test.dart`  
Expected: PASS.

- [ ] **Step 5: Wire coordinator into `live_game_orchestration.dart` and commit**

Replace lines 80-350 in `live_game_orchestration.dart` with delegated resume coordination. Run `flutter test` and `git commit -m "refactor(games): decouple resume and reconnect sync into LiveResumeSyncCoordinator"`.

---

### Task 4: Extract `LiveBingoClaimCoordinator` (Claim Validation, Auto-Claim Triggers & Diagnostics)

**Files:**
- Create: `lib/src/features/games/presentation/controllers/live_bingo_claim_coordinator.dart`
- Test: `test/features/games/live_bingo_claim_coordinator_test.dart`
- Modify: `lib/src/features/games/presentation/screens/live_game_orchestration.dart:950-1800`

**Interfaces:**
- Consumes: `GamesRepository`, `SoundService`, `PlayerCartelasNotifier`
- Produces: `LiveBingoClaimCoordinator` executing manual/auto claim requests with client-side deduplication and retry backoff.

- [ ] **Step 1: Write failing unit test for `LiveBingoClaimCoordinator`**

```dart
// test/features/games/live_bingo_claim_coordinator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_bingo_claim_coordinator.dart';

void main() {
  test('LiveBingoClaimCoordinator blocks duplicate claims while in-flight', () {
    final coordinator = LiveBingoClaimCoordinator();
    expect(coordinator.isClaimInFlight('cartela-1'), isFalse);
    
    coordinator.markClaimInFlight('cartela-1');
    expect(coordinator.isClaimInFlight('cartela-1'), isTrue);
    expect(coordinator.isClaimInFlight('cartela-2'), isFalse);
    
    coordinator.clearClaimInFlight('cartela-1');
    expect(coordinator.isClaimInFlight('cartela-1'), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/games/live_bingo_claim_coordinator_test.dart`  
Expected: FAIL.

- [ ] **Step 3: Implement `LiveBingoClaimCoordinator`**

```dart
// lib/src/features/games/presentation/controllers/live_bingo_claim_coordinator.dart
import 'package:flutter/foundation.dart';

class LiveBingoClaimCoordinator {
  final Set<String> _inFlightCardIds = {};

  bool isClaimInFlight(String cartelaId) => _inFlightCardIds.contains(cartelaId);

  void markClaimInFlight(String cartelaId) {
    _inFlightCardIds.add(cartelaId);
  }

  void clearClaimInFlight(String cartelaId) {
    _inFlightCardIds.remove(cartelaId);
  }

  void clearAll() {
    _inFlightCardIds.clear();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/games/live_bingo_claim_coordinator_test.dart`  
Expected: PASS.

- [ ] **Step 5: Wire coordinator and verify line count reduction**

Wire `LiveBingoClaimCoordinator` into `live_game_orchestration.dart`. Verify line count of `live_game_orchestration.dart` drops by > 2,500 lines. Commit: `git commit -m "refactor(games): delegate bingo claim submission and debouncing to LiveBingoClaimCoordinator"`.

---

### Task 5: Slim `live_game_screen.dart` into Thin View Coordinator (< 400 lines)

**Files:**
- Create: `lib/src/features/games/presentation/widgets/live_game_app_bar_section.dart`
- Create: `lib/src/features/games/presentation/widgets/live_game_content_switcher.dart`
- Modify: `lib/src/features/games/presentation/screens/live_game_screen.dart`
- Test: `test/features/games/live_game_screen_structure_test.dart`

**Interfaces:**
- Consumes: All `LiveGameControllers`, Riverpod notifiers
- Produces: Declarative scaffold orchestrating top section, called numbers strip, game cards grid, and contextual bottom action dock.

- [ ] **Step 1: Write widget test verifying thin `LiveGameScreen` renders child sections**

```dart
// test/features/games/live_game_screen_structure_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('live_game_screen.dart line count is under 600 lines', () async {
    // Assert line count strictly < 600
  });
}
```

- [ ] **Step 2: Extract AppBar and Content Switcher components**

Extract `LiveGameAppBarSection` and `LiveGameContentSwitcher` into separate widget files under `lib/src/features/games/presentation/widgets/`.

- [ ] **Step 3: Slim `live_game_screen.dart`**

Clean up unused imports, dead mixin glue code, and inline builder methods. Target: < 350 lines.

- [ ] **Step 4: Run all tests and analyzer**

Run: `flutter test` and `flutter analyze`  
Expected: 0 errors, 0 warnings, all 564+ tests pass.

- [ ] **Step 5: Commit Phase 2 completion**

Commit: `git commit -m "refactor(games): slim live_game_screen to thin coordinator under 350 lines"`

---

## Phase 3: Registration & Called Numbers Part Files Decomposition

### Task 6: Decouple `live_game_registration.dart` (2,080 -> < 350 lines)

**Files:**
- Create: `lib/src/features/games/presentation/controllers/cartela_selection_coordinator.dart`
- Create: `lib/src/features/games/presentation/widgets/live_cartela_quick_picker.dart`
- Modify: `lib/src/features/games/presentation/screens/live_game_registration.dart`
- Test: `test/features/games/cartela_selection_coordinator_test.dart`

- [ ] **Step 1: Write unit test for `CartelaSelectionCoordinator`**
- [ ] **Step 2: Implement `CartelaSelectionCoordinator`**
- [ ] **Step 3: Extract `LiveCartelaQuickPicker` widget**
- [ ] **Step 4: Verify tests & line counts (< 350 lines)**
- [ ] **Step 5: Commit `refactor(games): decouple cartela selection coordinator from live registration part`**

---

### Task 7: Decouple `cartela_registration_sheet.dart` (1,095 -> < 350 lines)

**Files:**
- Create: `lib/src/features/games/presentation/widgets/cartela_sheet_action_footer.dart`
- Create: `lib/src/features/games/presentation/widgets/cartela_sheet_summary_header.dart`
- Modify: `lib/src/features/games/presentation/widgets/cartela_registration_sheet.dart`
- Test: `test/features/games/cartela_registration_sheet_test.dart`

- [ ] **Step 1: Write widget test for footer and header widgets**
- [ ] **Step 2: Extract `CartelaSheetActionFooter` and `CartelaSheetSummaryHeader`**
- [ ] **Step 3: Refactor `cartela_registration_sheet.dart` to thin container (< 350 lines)**
- [ ] **Step 4: Run test suite**
- [ ] **Step 5: Commit `refactor(games): decouple registration sheet into header and action footer widgets`**

---

### Task 8: Decouple `live_game_called_numbers.dart` (1,035 -> < 300 lines)

**Files:**
- Create: `lib/src/features/games/presentation/controllers/live_audio_announcer_coordinator.dart`
- Modify: `lib/src/features/games/presentation/screens/live_game_called_numbers.dart`
- Test: `test/features/games/live_audio_announcer_coordinator_test.dart`

- [ ] **Step 1: Write test for audio call queuing and debounce**
- [ ] **Step 2: Implement `LiveAudioAnnouncerCoordinator`**
- [ ] **Step 3: Delegate speech synthesis and sound cues from part file to coordinator**
- [ ] **Step 4: Verify line count < 300 lines and tests pass**
- [ ] **Step 5: Commit `refactor(games): delegate ball call audio announcements to LiveAudioAnnouncerCoordinator`**

---

## Phase 4: Pattern Evaluation & Game Rules Decomposition

### Task 9: Decompose `cartela_marked_pattern_evaluator.dart` (1,528 -> < 400 lines)

**Files:**
- Create: `lib/src/features/games/domain/pattern_grid_evaluator.dart`
- Create: `lib/src/features/games/domain/corner_and_line_evaluator.dart`
- Modify: `lib/src/features/games/presentation/utils/cartela_marked_pattern_evaluator.dart`
- Test: `test/features/games/pattern_grid_evaluator_test.dart`

- [ ] **Step 1: Write unit tests for line, diagonal, and corner algorithms**
- [ ] **Step 2: Extract `PatternGridEvaluator` and `CornerAndLineEvaluator`**
- [ ] **Step 3: Refactor `cartela_marked_pattern_evaluator.dart` to thin facade (< 400 lines)**
- [ ] **Step 4: Verify all pattern tests pass**
- [ ] **Step 5: Commit `refactor(games): decompose pattern evaluation into modular grid evaluators`**

---

### Task 10: Decompose `game_rule_pattern_preview.dart` (1,194 -> < 350 lines)

**Files:**
- Create: `lib/src/features/games/presentation/widgets/pattern_cell_matrix_widget.dart`
- Create: `lib/src/features/games/presentation/widgets/pattern_legend_card.dart`
- Modify: `lib/src/features/games/presentation/widgets/game_rule_pattern_preview.dart`
- Test: `test/features/games/pattern_cell_matrix_widget_test.dart`

- [ ] **Step 1: Write widget test for matrix cell renderer**
- [ ] **Step 2: Extract matrix and legend components**
- [ ] **Step 3: Slim `game_rule_pattern_preview.dart` (< 350 lines)**
- [ ] **Step 4: Run test suite**
- [ ] **Step 5: Commit `refactor(games): extract pattern cell matrix and legend from game rule preview`**

---

## Phase 5: Auxiliaries & Dialogs Decomposition

### Task 11: Decompose `app_settings_drawer.dart` (1,752 -> < 350 lines)

**Files:**
- Create: `lib/src/features/settings/presentation/widgets/settings_theme_language_section.dart`
- Create: `lib/src/features/settings/presentation/widgets/settings_sound_feedback_section.dart`
- Create: `lib/src/features/settings/presentation/widgets/settings_account_profile_section.dart`
- Modify: `lib/src/features/settings/presentation/widgets/app_settings_drawer.dart`
- Test: `test/features/settings/settings_sections_test.dart`

- [ ] **Step 1: Write widget tests for each settings section**
- [ ] **Step 2: Extract section widgets into separate files (< 250 lines each)**
- [ ] **Step 3: Refactor `app_settings_drawer.dart` to pure list orchestrator (< 250 lines)**
- [ ] **Step 4: Run analyzer & tests**
- [ ] **Step 5: Commit `refactor(settings): decompose app settings drawer into modular section widgets`**

---

### Task 12: Decompose `game_history_detail_dialog.dart` (668 -> < 300 lines)

**Files:**
- Create: `lib/src/features/games/presentation/widgets/history_round_payout_item.dart`
- Modify: `lib/src/features/games/presentation/widgets/game_history_detail_dialog.dart`
- Test: `test/features/games/history_round_payout_item_test.dart`

- [ ] **Step 1: Write widget test for `HistoryRoundPayoutItem`**
- [ ] **Step 2: Extract payout item widget**
- [ ] **Step 3: Slim `game_history_detail_dialog.dart` (< 300 lines)**
- [ ] **Step 4: Verify test suite**
- [ ] **Step 5: Commit `refactor(games): extract payout item from history detail dialog`**

---

## Final Verification & Clean Architecture Audit

- [ ] **Verify zero files exceed 600 lines:** Run line audit script across `lib/`.
- [ ] **Run full static analysis:** `flutter analyze --no-fatal-infos lib test` (0 errors, 0 warnings).
- [ ] **Run complete test suite:** `flutter test` (all 564+ tests pass).
- [ ] **Push clean refactored branch to origin.**
