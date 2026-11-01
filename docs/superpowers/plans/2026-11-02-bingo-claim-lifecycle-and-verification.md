# Bingo Claim Lifecycle & Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modernize the mobile bingo claim lifecycle test harness, harden `BingoClaimButton` with debouncing, haptics, and accessibility semantics, and verify end-to-end claim contract integrity between Flutter and NestJS.

**Architecture:** Update assertions in `bingo_claim_recovery_lifecycle_test.dart` to target `BingoClaimButton` and `InkWell.onTap`. Add widget-level tap debouncing, immediate `HapticFeedback.heavyImpact()`, and `Semantics` wrapper in `BingoClaimButton`. Confirm full suite passing across all 637+ tests and verify backend compatibility.

**Tech Stack:** Flutter, Dart, Riverpod, NestJS, Socket.IO, flutter_test.

---

### Task 1: Modernize `bingo_claim_recovery_lifecycle_test.dart` Test Harness

**Files:**
- Modify: `test/features/games/bingo_claim_recovery_lifecycle_test.dart:520-535, 956, 1783-1810, 2773`
- Test: `test/features/games/bingo_claim_recovery_lifecycle_test.dart`

- [ ] **Step 1: Update `_expectBingoAvailable` helper and import `BingoClaimButton`**

In `test/features/games/bingo_claim_recovery_lifecycle_test.dart`, ensure `BingoClaimButton` is imported:
```dart
import 'package:friends_bingo_app/src/features/games/presentation/components/bingo_claim_button.dart';
```

Replace lines 520-534 with:
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

- [ ] **Step 2: Update tap actions and visibility assertions in `bingo_claim_recovery_lifecycle_test.dart`**

Update line 956:
```dart
await tester.tap(find.byType(BingoClaimButton).first);
```

Update lines 1783-1808:
```dart
      final bingoButton = find.byType(BingoClaimButton).first;
      final inkWellFinder = find.descendant(
        of: bingoButton,
        matching: find.byType(InkWell),
      );
      expect(tester.widget<InkWell>(inkWellFinder).onTap, isNotNull);
      await tester.ensureVisible(bingoButton);
      await tester.tap(bingoButton);
      await tester.pump();
      expect(repo.submittedUuid, isNotNull);
      final original = repo.submittedUuid;
      repo.post.completeError(ApiException(message: 'HTTP timeout'));
      await tester.pump();
      expect(repo.recoveryGets, 1);
      expect(controller.claimRecoveryFailedCartelaIds, contains('gc-1'));
      expect(controller.activeClaimAttemptIdByCartelaId['gc-1'], original);
      expect(controller.isConfirmingClaim('gc-1'), isTrue);
      await tester.pump();
      // CONFIRMING shows checking label — not a silent gray BINGO.
      expect(find.text('Checking bingo claim'), findsWidgets);
      expect(find.byType(BingoClaimButton), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(repo.recoveryGets, 2);
      await tester.pump();
      expect(find.byType(BingoClaimButton), findsWidgets);
      final restoredInkWellFinder = find.descendant(
        of: find.byType(BingoClaimButton).first,
        matching: find.byType(InkWell),
      );
      expect(
        tester.widget<InkWell>(restoredInkWellFinder).onTap,
        isNotNull,
      );
```

Update line 2773:
```dart
      expect(find.byType(BingoClaimButton), findsNothing);
```

- [ ] **Step 3: Run targeted test to verify all 23 failing tests are resolved**

Run: `flutter test test/features/games/bingo_claim_recovery_lifecycle_test.dart`
Expected: All 68+ tests pass with 0 failures.

- [ ] **Step 4: Commit test modernization**

```bash
git add test/features/games/bingo_claim_recovery_lifecycle_test.dart
git commit -m "test(games): modernize bingo claim recovery lifecycle assertions to target BingoClaimButton"
```

---

### Task 2: Harden `BingoClaimButton` with Debounce, Haptics, and Accessibility

**Files:**
- Modify: `lib/src/features/games/presentation/components/bingo_claim_button.dart`
- Test: `test/features/games/bingo_claim_button_test.dart`

- [ ] **Step 1: Add widget-level tap debouncing, haptic feedback, and accessibility semantics**

In `lib/src/features/games/presentation/components/bingo_claim_button.dart`:
Add import:
```dart
import 'package:flutter/services.dart';
```

In `_BingoClaimButtonState`:
1. Add `bool _tapInFlight = false;`
2. In `didUpdateWidget`:
```dart
    if (oldWidget.canClaim != widget.canClaim ||
        oldWidget.showReadyPulse != widget.showReadyPulse ||
        oldWidget.isClaiming != widget.isClaiming) {
      _syncAnimation();
      if (widget.isClaiming || !widget.canClaim) {
        _tapInFlight = false;
      }
    }
```
3. In `build()`, implement guarded `_handleTap`:
```dart
    void handleTap() {
      if (_tapInFlight || !isEnabled) return;
      setState(() => _tapInFlight = true);
      HapticFeedback.heavyImpact();
      widget.onPressed();
    }
```
4. Bind `onTap: isEnabled ? handleTap : null` to `InkWell`.
5. Wrap the returned button in `Semantics`:
```dart
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: 'Claim Bingo',
      value: widget.isClaiming
          ? 'Checking claim'
          : (isEnabled ? 'Ready to claim' : 'Unavailable'),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final t = _pulse.value;
          return Transform.scale(
            scale: 1.0 + (t * 0.045),
            child: snugButton,
          );
        },
      ),
    );
```

- [ ] **Step 2: Run component tests to verify button behavior**

Run: `flutter test test/features/games/bingo_claim_button_test.dart`
Expected: All component tests pass cleanly.

- [ ] **Step 3: Commit component hardening**

```bash
git add lib/src/features/games/presentation/components/bingo_claim_button.dart
git commit -m "perf(games): add tap debouncing haptic feedback and accessibility semantics to BingoClaimButton"
```

---

### Task 3: Full Mobile Test Suite & Verification

**Files:**
- Test: All mobile test suites

- [ ] **Step 1: Run the full mobile test suite**

Run: `flutter test`
Expected: 0 failures across all 637+ tests.

---

### Task 4: Backend Integration & Schema Verification

**Files:**
- Location: `D:\PROJECTS\bingo\Friends-bingo-backend`

- [ ] **Step 1: Run backend test suite**

Run: `cd D:\PROJECTS\bingo\Friends-bingo-backend && npm test`
Expected: All 73 suites pass, 501 tests pass, 0 failed.

- [ ] **Step 2: Verify git status across both repositories**

Run: `git status` in both repos to confirm clean working trees and structured commit history.
