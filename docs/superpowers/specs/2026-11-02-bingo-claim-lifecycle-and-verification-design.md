# Bingo Claim Lifecycle & Verification Design Document

**Date:** 2026-11-02  
**Status:** Approved  
**Topic:** Stream 1 — Bingo Claim Lifecycle, Mobile Button Feedback & Test Modernization  
**Repositories:** `friends-bingo-mobile` (primary), `Friends-bingo-backend` (contract verification)  

---

## 1. Overview & Objective

During comprehensive end-to-end audit and testing across the Friends Bingo mobile app and NestJS backend, 23 test failures were identified in `test/features/games/bingo_claim_recovery_lifecycle_test.dart`.

The root cause was traced to an assertion mismatch: `BingoClaimButton` was redesigned into a custom, branded, glowing animated widget (`Material` + `InkWell`), whereas the test suite still searched for `find.widgetWithText(FilledButton, 'BINGO')`.

The objective of this design is to:
1. Modernize the `bingo_claim_recovery_lifecycle_test.dart` harness to accurately target `BingoClaimButton` and `InkWell.onTap`.
2. Harden `BingoClaimButton` with local tap debouncing, haptic feedback on touch, expanded hit-test areas, and accessible `Semantics`.
3. Confirm 100% contractual alignment between NestJS `BingoClaimsService` DTOs and Flutter `BingoClaimResult` / `BingoClaimAttemptStatus` models.

---

## 2. Test Harness Modernization

### 2.1 Problem Diagnosis
In `test/features/games/bingo_claim_recovery_lifecycle_test.dart`:
```dart
// Previous outdated assertion (fails because button is no longer a FilledButton):
void _expectBingoAvailable(WidgetTester tester, bool enabled) {
  final buttons = find.widgetWithText(FilledButton, 'BINGO');
  if (buttons.evaluate().isEmpty) {
    expect(enabled, isFalse, reason: 'BINGO is unavailable in terminal presentation');
  } else {
    expect(tester.widget<FilledButton>(buttons.first).onPressed, enabled ? isNotNull : isNull);
  }
}
```

### 2.2 Modernized Assertion Contract
Update test helpers and finders across the test suite:
- **Button Finder**: Target `find.byType(BingoClaimButton)` directly.
- **Availability & Enabling Assertion**:
  ```dart
  void _expectBingoAvailable(WidgetTester tester, bool enabled) {
    final buttons = find.byType(BingoClaimButton);
    if (buttons.evaluate().isEmpty) {
      expect(
        enabled,
        isFalse,
        reason: 'BINGO is unavailable in terminal presentation',
      );
    } else {
      final buttonWidget = tester.widget<BingoClaimButton>(buttons.first);
      final inkWellFinder = find.descendant(
        of: buttons.first,
        matching: find.byType(InkWell),
      );
      final inkWell = tester.widget<InkWell>(inkWellFinder);
      if (enabled) {
        expect(buttonWidget.canClaim, isTrue);
        expect(inkWell.onTap, isNotNull);
      } else {
        expect(inkWell.onTap, isNull);
      }
    }
  }
  ```
- **Tap Targets**:
  Replace `find.widgetWithText(FilledButton, 'BINGO').first` with `find.byType(BingoClaimButton).first`.
- **In-Flight & Invisibility Checks**:
  During checking / confirming states where `LiveCartelaCard` displays `Text(context.l10n.gameCheckingTitle)`, assert `expect(find.byType(BingoClaimButton), findsNothing)`.

---

## 3. Mobile Button Feedback & Interaction Hardening

### 3.1 Touch Target & Fast Tapping
In live gameplay, players tap eagerly upon completing a line. `BingoClaimButton` has a compact visual height (`height: 20`, `padding: EdgeInsets.symmetric(horizontal: 10)`).
- Ensure the button's `InkWell` touch area provides responsive hit testing across the header bar without disrupting the card layout.
- Call `HapticFeedback.heavyImpact()` immediately in `onTap` prior to forwarding to `widget.onPressed`.

### 3.2 In-Flight Tap Debouncing
Add widget-level debounce state in `_BingoClaimButtonState`:
```dart
bool _tapInFlight = false;

void _handleTap() {
  if (_tapInFlight || !isEnabled) return;
  setState(() => _tapInFlight = true);
  HapticFeedback.heavyImpact();
  widget.onPressed();
}
```
Reset `_tapInFlight = false` inside `didUpdateWidget` when `isClaiming` toggles or `canClaim` changes.

### 3.3 Accessibility Semantics
Wrap the button in `Semantics`:
```dart
Semantics(
  button: true,
  enabled: isEnabled,
  label: 'Claim Bingo',
  value: widget.isClaiming ? 'Checking claim' : (isEnabled ? 'Ready to claim' : 'Unavailable'),
  child: snugButton,
)
```

---

## 4. End-to-End Contract & Data Flow

### 4.1 Claim Lifecycle State Machine
```
[User Tap / Auto-Bingo]
      │
      ├──> Instant HapticFeedback.heavyImpact() + local debounce
      │
      ├──> LiveBingoClaimCoordinator persists claimAttemptId to local storage
      │
      ├──> POST /games/sessions/:id/claims
      │       ├── Backend validates called numbers & pattern rules
      │       ├── Emits WS: 'game:bingo_checking'
      │       ├── If Valid: emits 'game:bingo_valid', 'game:winner_window_started', 'session:prize_updated'
      │       ├── If Invalid: emits 'game:bingo_invalid'
      │       └── If Failed: emits 'game:bingo_claim_failed'
      │
      └──> Response Handling:
              ├── Success: updates cartela status (Winner/Blocked/Retryable), clears local pending UUID
              └── Timeout: recovery GET /games/sessions/:id/bingo-claims/:claimAttemptId
```

### 4.2 Schema Verification
- **POST `/sessions/:id/claims`**:
  Returns `BingoClaimResult` with `claim`, `isWinner`, `gameStatus`, `gameCartelaStatus`, `retryAllowed`, `winnerWindowEndsAt`, `completedPatterns`.
- **GET `/sessions/:id/bingo-claims/:claimAttemptId`**:
  Returns `BingoClaimAttemptStatus` with `claimAttemptId`, `status`, `gameCartelaStatus`, `gameStatus`, `isWinner`, `retryAllowed`, `reasonCode`, `failureCode`, `winnerWindowEndsAt`.

Both contracts parse ISO dates safely through `parseApiDateTime()`, preventing format exceptions.

---

## 5. Verification Plan

1. **Targeted Regression Suite**:
   Run `flutter test test/features/games/bingo_claim_recovery_lifecycle_test.dart` and confirm all 68+ test cases pass (0 failures).
2. **Full Mobile Suite**:
   Run `flutter test` and confirm all 637+ tests pass.
3. **Backend Integration**:
   Confirm backend unit tests (`npm test` in `Friends-bingo-backend`) continue passing with 0 regressions.

---

## 6. Roadmap: Subsequent Streams

- **Stream 2**: Game State Machine & Screen Transitions (`NEXT` → `PLAYING` → `CHECKING` → `WINNER_WINDOW` → `FINISHED`, inter-round pauses, and resume synchronization).
- **Stream 3**: Widget Interactions & Screen Performance (Registration grid responsiveness, action dock, cartela review sheet, buttons, tactile/haptic feedback, sound triggers, and safe-area transitions).
- **Stream 4**: Realtime Socket & REST Payload Contract Alignment (Comprehensive audit of all socket events and REST response contracts).
