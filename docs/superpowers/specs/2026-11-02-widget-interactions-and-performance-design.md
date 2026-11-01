# Widget Interactions & Screen Performance Design Document

**Date:** 2026-11-02  
**Status:** Approved  
**Topic:** Stream 3 — Widget Interactions, Tactile Haptic Feedback & GPU Repaint Isolation  
**Repositories:** `friends-bingo-mobile` (primary), `Friends-bingo-backend` (validation)  

---

## 1. Overview & Objectives

In live multiplayer bingo, user interaction latency, tactile feedback, and frame-rate consistency directly dictate the quality of player experience.

During our in-depth performance audit, three primary areas for optimization were identified:
1. **Cartela Board Tactile Feedback & Repaint Boundary Isolation:**
   - In [`CartelaBoardWidget`](file:///d:/PROJECTS/bingo/friends-bingo-mobile/lib/src/features/games/cartelas/presentation/widgets/cartela_board_widget.dart), tapping cells to manually daub numbers called `onCellTapped!(number)` without any haptic feedback.
   - In [`LiveRegisteredCartelaList`](file:///d:/PROJECTS/bingo/friends-bingo-mobile/lib/src/features/games/cartelas/presentation/widgets/live_registered_cartela_list.dart), multi-cartela grid cells were wrapped in `KeyedSubtree`. Whenever one cartela's 520ms `oneAwayPulseT` animation or manual daub state changed, Flutter repainted sibling cartelas on the same render layer.
2. **Called Numbers Strip Keyed Identity & Paint Isolation:**
   - In [`CalledNumbersStrip`](file:///d:/PROJECTS/bingo/friends-bingo-mobile/lib/src/features/games/presentation/widgets/called_numbers_strip.dart), the horizontal `recentCalls` list rendered `_CalledBall` instances without unique element keys.
   - Pulse animations from `LatestCallPulse` on the latest called number triggered paint passes across older called balls.
3. **Registration Grid & Action Dock Haptics & Debounce:**
   - In [`RegistrationCartelaGridCell`](file:///d:/PROJECTS/bingo/friends-bingo-mobile/lib/src/features/games/registration/presentation/widgets/registration_cartela_grid.dart), selecting or long-pressing cartela chips lacked haptic feedback.
   - In [`RegistrationActionDock`](file:///d:/PROJECTS/bingo/friends-bingo-mobile/lib/src/features/games/registration/presentation/widgets/registration_action_dock.dart) and [`CartelaRegistrationSheet`](file:///d:/PROJECTS/bingo/friends-bingo-mobile/lib/src/features/games/registration/presentation/widgets/cartela_registration_sheet.dart), critical actions ("Review" and "Register") lacked tactile confirmation and in-flight click debounce.

### Goals
- Deliver instant tactile confirmation (`HapticFeedback.selectionClick()` / `HapticFeedback.heavyImpact()`) across cell daubs, cartela selection, and registration actions.
- Isolate render layers using `RepaintBoundary` on `LiveRegisteredCartelaList` cells and `CalledNumbersStrip` ball badges to maintain smooth 60fps animations.
- Ensure item identity stability in horizontal called numbers list via `ValueKey`.
- Maintain 100% test suite passing with zero regressions across mobile and backend.

---

## 2. Detailed Technical Design

### 2.1 Cartela Board Cell Tap Haptics & Paint Isolation
- In [`lib/src/features/games/cartelas/presentation/widgets/cartela_board_widget.dart`](file:///d:/PROJECTS/bingo/friends-bingo-mobile/lib/src/features/games/cartelas/presentation/widgets/cartela_board_widget.dart):
  ```dart
  onTap: (interactive && !isFreeSpace && onCellTapped != null && number > 0)
      ? () {
          HapticFeedback.selectionClick();
          onCellTapped!(number);
        }
      : null,
  ```
- In [`lib/src/features/games/cartelas/presentation/widgets/live_registered_cartela_list.dart`](file:///d:/PROJECTS/bingo/friends-bingo-mobile/lib/src/features/games/cartelas/presentation/widgets/live_registered_cartela_list.dart):
  Replace `KeyedSubtree` in `_wrapReorderableCell` with `RepaintBoundary`:
  ```dart
  return RepaintBoundary(
    key: ValueKey('cartela_cell_${cartelas[index].id}'),
    child: wrapped,
  );
  ```

### 2.2 Called Numbers Strip Item Keys & Paint Isolation
- In [`lib/src/features/games/presentation/widgets/called_numbers_strip.dart`](file:///d:/PROJECTS/bingo/friends-bingo-mobile/lib/src/features/games/presentation/widgets/called_numbers_strip.dart):
  In `ListView.separated` for `recentCalls`:
  ```dart
  itemBuilder: (context, index) {
    final item = recentCalls[index];
    return RepaintBoundary(
      key: ValueKey('called_ball_${item.number}_${item.calledOrder}'),
      child: _CalledBall(
        calledNumber: item,
        size: _recentBallSize,
      ),
    );
  },
  ```

### 2.3 Registration Grid & Dock Feedback & Tap Protection
- In [`lib/src/features/games/registration/presentation/widgets/registration_cartela_grid.dart`](file:///d:/PROJECTS/bingo/friends-bingo-mobile/lib/src/features/games/registration/presentation/widgets/registration_cartela_grid.dart):
  In `RegistrationCartelaGridCell`:
  ```dart
  onTap: () {
    HapticFeedback.selectionClick();
    widget.onTap(widget.cartela, resolved);
  },
  onLongPress: () {
    HapticFeedback.mediumImpact();
    widget.onLongPress(widget.cartela, resolved);
  },
  ```
- In [`lib/src/features/games/registration/presentation/widgets/registration_action_dock.dart`](file:///d:/PROJECTS/bingo/friends-bingo-mobile/lib/src/features/games/registration/presentation/widgets/registration_action_dock.dart):
  Add `HapticFeedback.mediumImpact()` to `onReview` and `onCancelSelection`.
- In [`lib/src/features/games/registration/presentation/widgets/cartela_registration_sheet.dart`](file:///d:/PROJECTS/bingo/friends-bingo-mobile/lib/src/features/games/registration/presentation/widgets/cartela_registration_sheet.dart):
  Add `HapticFeedback.heavyImpact()` on `_register()` call, with in-flight guard `_isSubmitting`.

---

## 3. Testing & Verification Plan

1. **Cartela Board Tap Test:**
   - Verify `CartelaBoardWidget` triggers `onCellTapped` callback without errors when tapped.
2. **Called Numbers Strip Tests:**
   - Verify `CalledNumbersStrip` renders recent called numbers with `RepaintBoundary` and keys.
3. **Registration Grid & Action Dock Tests:**
   - Verify cartela selection and action dock continue functioning seamlessly with haptic invocations.
4. **Full Regression Testing:**
   - Run `flutter test` (all 642+ tests).
   - Run `npm test` in `Friends-bingo-backend` (all 73 suites).

