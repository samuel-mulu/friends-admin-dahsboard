# Widget Interactions & Screen Performance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement tactile haptic feedback on manual cartela cell taps and registration selections, and isolate render layers with `RepaintBoundary` on cartela cards and called number badges to guarantee 60fps stutter-free gameplay.

**Architecture:**
1. In `CartelaBoardWidget`, invoke `HapticFeedback.selectionClick()` on cell taps.
2. In `LiveRegisteredCartelaList`, wrap each cartela item in `RepaintBoundary` to isolate pulse animations and cell marks.
3. In `CalledNumbersStrip`, add `ValueKey` and `RepaintBoundary` to horizontal `_CalledBall` items.
4. In `RegistrationCartelaGridCell`, `RegistrationActionDock`, and `CartelaRegistrationSheet`, add tactile haptics on selection, review, and register actions.

**Tech Stack:** Flutter, Dart, Riverpod, flutter_test.

---

### Task 1: Cartela Board Haptics & Live Cartela Repaint Isolation

**Files:**
- Modify: `lib/src/features/games/cartelas/presentation/widgets/cartela_board_widget.dart`
- Modify: `lib/src/features/games/cartelas/presentation/widgets/live_registered_cartela_list.dart`
- Test: `test/features/games/cartela_board_widget_test.dart`

- [ ] **Step 1: Add `HapticFeedback.selectionClick()` in `CartelaBoardWidget`**

In `lib/src/features/games/cartelas/presentation/widgets/cartela_board_widget.dart`:
Ensure `import 'package:flutter/services.dart';` is present.
Update cell tap handler:
```dart
        onTap:
            (interactive && !isFreeSpace && onCellTapped != null && number > 0)
            ? () {
                HapticFeedback.selectionClick();
                onCellTapped!(number);
              }
            : null,
```

- [ ] **Step 2: Wrap cartela cards with `RepaintBoundary` in `LiveRegisteredCartelaList`**

In `lib/src/features/games/cartelas/presentation/widgets/live_registered_cartela_list.dart`:
In `_wrapReorderableCell`:
```dart
    return RepaintBoundary(
      key: ValueKey('cartela_cell_${cartelas[index].id}'),
      child: wrapped,
    );
```

- [ ] **Step 3: Run cartela board widget tests**

Run:
```powershell
flutter test test/features/games/cartela_board_widget_test.dart
```

- [ ] **Step 4: Commit changes**

Commit with conventional commits:
```bash
git commit -m "perf(cartelas): add cell tap haptic feedback and repaint boundary isolation"
```

---

### Task 2: Called Numbers Strip Keyed Identity & Paint Isolation

**Files:**
- Modify: `lib/src/features/games/presentation/widgets/called_numbers_strip.dart`
- Test: `test/features/games/called_numbers_strip_test.dart`

- [ ] **Step 1: Add `ValueKey` and `RepaintBoundary` to horizontal balls in `CalledNumbersStrip`**

In `lib/src/features/games/presentation/widgets/called_numbers_strip.dart`:
In `ListView.separated` of `recentCalls`:
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

- [ ] **Step 2: Run called numbers strip test**

Run:
```powershell
flutter test test/features/games/called_numbers_strip_test.dart
```

- [ ] **Step 3: Commit changes**

Commit with conventional commits:
```bash
git commit -m "perf(games): add keyed identity and repaint boundary to called numbers strip"
```

---

### Task 3: Registration Grid & Action Dock Haptics & Tap Protection

**Files:**
- Modify: `lib/src/features/games/registration/presentation/widgets/registration_cartela_grid.dart`
- Modify: `lib/src/features/games/registration/presentation/widgets/registration_action_dock.dart`
- Modify: `lib/src/features/games/registration/presentation/widgets/cartela_registration_sheet.dart`
- Test: `test/features/games/registration_cartela_grid_index_test.dart`

- [ ] **Step 1: Add tactile feedback to `RegistrationCartelaGridCell`**

In `lib/src/features/games/registration/presentation/widgets/registration_cartela_grid.dart`:
Ensure `import 'package:flutter/services.dart';` is imported.
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

- [ ] **Step 2: Add tactile feedback to `RegistrationActionDock`**

In `lib/src/features/games/registration/presentation/widgets/registration_action_dock.dart`:
Add `import 'package:flutter/services.dart';` and wrap `onReview` and `onCancelSelection`:
```dart
                  TextButton(
                    onPressed: selectedCount > 0 ? () {
                      HapticFeedback.selectionClick();
                      onCancelSelection();
                    } : null,
                    child: Text(l10n.gameClear),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: selectedCount > 0 ? () {
                      HapticFeedback.mediumImpact();
                      onReview();
                    } : null,
                    child: Text(l10n.gameReview(selectedCount)),
                  ),
```

- [ ] **Step 3: Add tactile feedback to `CartelaRegistrationSheet`**

In `lib/src/features/games/registration/presentation/widgets/cartela_registration_sheet.dart`:
Add `import 'package:flutter/services.dart';` and add `HapticFeedback.heavyImpact();` on `_register()`.

- [ ] **Step 4: Run registration tests**

Run:
```powershell
flutter test test/features/games/registration_cartela_grid_index_test.dart
```

- [ ] **Step 5: Commit changes**

Commit with conventional commits:
```bash
git commit -m "feat(registration): add tactile haptics to cartela selection and action docks"
```

---

### Task 4: Full Verification Across Mobile & Backend

- [ ] **Step 1: Run all mobile tests**

Run:
```powershell
flutter test
```
Confirm all 642+ tests pass with 0 failures.

- [ ] **Step 2: Run all backend tests**

Run:
```powershell
npm --prefix "D:\PROJECTS\bingo\Friends-bingo-backend" test
```
Confirm all 73 suites pass with 0 failures.
