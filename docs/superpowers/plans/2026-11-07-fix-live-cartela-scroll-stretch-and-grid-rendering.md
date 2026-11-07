# Live Cartela Scroll Stretching and Grid Rendering Fix Implementation Plan

## Problem Summary & Diagnostic Findings

### 1. Visual Defect Analysis

Comparison between **Image 1** (`media_1794034886277_b48db623.jpg`) and **Image 2** (`media_1794034927389_a9de4501.jpg`):

- **Image 1 (Broken Stretch):**
  - When scrolling up or down, the cartela cards stretch vertically into distorted tall rectangles.
  - Pixel measurements on Image 1 show cell `8` has width = 32px, height = 50px (aspect ratio ~0.47 to 0.64 instead of 1.0).
  - Circular pattern highlight rings (e.g. around numbers 69, 12, 7, 68) distort into tall vertical ellipses.
  - Multi-cell pattern overlays (e.g., 2×2 blocks around 8, 23, 5, 22) distort into elongated vertical boxes.
- **Image 2 (Scrolled Listing):**
  - When scrolled down, cartelas retain squarer proportions, but the third cartela (`7695`) sits alone on the left with empty whitespace on the right.
  - Header and content scrolling can cause overscroll bounce physics to trigger stretching.

### 2. Root Cause Analysis

1. **Overscroll Stretch Effect (Android 12+ Stretch Scroll Behavior):**
   - In Flutter 3+ on Android 12+, `ScrollBehavior` defaults to `StretchingOverscrollIndicator`.
   - In `LiveCartelaViewport` (`CustomScrollView`) and `live_game_views.dart` (`ListView`), no `ScrollConfiguration` or overscroll override exists.
   - When the user drags/swipes to scroll, overscroll activates and physically transforms the viewport via non-uniform scale, distorting all rounded rectangles, text, borders, and custom painters into stretched tall shapes.
2. **Missing Strict Square AspectRatio Constraint on Cells:**
   - In `cartela_board_widget.dart` (`_buildCell`, lines 638–646):
     ```dart
     if (cellExtent != null) {
       return Padding(padding: EdgeInsets.all(padding), child: cellBody);
     }
     return Padding(
       padding: EdgeInsets.all(padding),
       child: AspectRatio(aspectRatio: 1.0, child: cellBody),
     );
     ```
     When `cellExtent != null` is passed (in live play), `AspectRatio(aspectRatio: 1.0)` was omitted! If the cell slot expands vertically under flex or overscroll, `cellBody` expands into a tall rectangle.
3. **Double-Card Redundancy & Height Mismatch:**
   - `LiveCartelaCard` wraps its contents in a `Card(margin: EdgeInsets.zero, shape: RoundedRectangleBorder(...))`.
   - Inside it, `CartelaBoardWidget` wraps itself in a second `Card(margin: EdgeInsets.zero, shape: RoundedRectangleBorder(...))`.
   - When embedded in `LiveCartelaCard` with `showHeader: false`, `CartelaBoardWidget` should not render a nested `Card`.
4. **Grid Row & Column Flex:**
   - In `_buildSquareLiveGrid`, the 5 rows use `Expanded`, and each row has 5 `Expanded` columns. If the container receives excess height or overscroll, the rows expand vertically.
   - Enforcing `AspectRatio(aspectRatio: 1.0)` and strict dimensions prevents any vertical distortion.

---

## Proposed Changes

### Task 1: Disable Overscroll Stretching on Live Cartela Viewports

**Files:**

- `lib/src/features/games/cartelas/presentation/widgets/live_cartela_viewport.dart`
- `lib/src/features/games/presentation/screens/live_game_views.dart`

**Changes:**

1. In `LiveCartelaViewport`:
   Wrap `CustomScrollView` in a `ScrollConfiguration` that disables stretch overscroll:
   ```dart
   ScrollConfiguration(
     behavior: ScrollConfiguration.of(context).copyWith(
       overscroll: false,
       physics: const ClampingScrollPhysics(),
     ),
     child: CustomScrollView(...),
   )
   ```
2. In `live_game_views.dart`:
   Ensure any fallback `ListView` also uses `ClampingScrollPhysics()` and `overscroll: false` to prevent bounce-stretch distortion.

---

### Task 2: Lock Cell & Board Geometry to Strict 1:1 Aspect Ratio

**Files:**

- `lib/src/features/games/cartelas/presentation/widgets/cartela_board_widget.dart`

**Changes:**

1. In `_buildCell`:
   Always enforce `AspectRatio(aspectRatio: 1.0, child: cellBody)` or `SizedBox.square(dimension: cellExtent, child: cellBody)` regardless of whether `cellExtent` is null.
2. In `_buildSquareLiveGrid`:
   Wrap the 5×5 grid in `AspectRatio(aspectRatio: 1.0)` so the entire 5×5 board is strictly square under all layout circumstances.
3. Remove nested `Card` in `CartelaBoardWidget` when `showHeader: false` (or when embedded), returning a clean container to avoid border/padding padding bloat.

---

### Task 3: Refine 2-Col Grid Tile Aspect Ratio & Odd Item Presentation

**Files:**

- `lib/src/features/games/cartelas/domain/cartela_board_layout.dart`
- `lib/src/features/games/cartelas/presentation/widgets/live_registered_cartela_list.dart`

**Changes:**

1. Audit `CartelaBoardLayout.liveTwoUpTileAspectRatio`:
   Ensure tile height precisely accommodates the outer cartela header (with badge and claim/status button) and the square 5×5 board without any excess vertical slack.
2. For odd number of cartelas (e.g. 3 cards):
   Ensure the lone card maintains identical width, height, and square cells matching the 2-column cards.

---

### Task 4: Verification & Automated Tests

**Files:**

- `test/features/games/cartela_board_square_aspect_ratio_test.dart`
- Run existing test suites:
  - `flutter test test/features/games/live_cartela_warm_theme_test.dart`
  - `flutter test test/core/theme/warm_theme_contrast_test.dart`
  - `flutter analyze`

---

## Execution Status & Verification Results

- [x] **Task 1: Disable Overscroll Stretching:**
  - `LiveCartelaViewport`: Wrapped `CustomScrollView` in `ScrollConfiguration` with `overscroll: false` and `ClampingScrollPhysics`.
  - `live_game_views.dart`: Wrapped `ListView` in `ScrollConfiguration` with `overscroll: false` and `ClampingScrollPhysics` parent.
- [x] **Task 2: Lock 1:1 Aspect Ratio Unconditionally:**
  - `_buildCell`: Changed to unconditional `AspectRatio(aspectRatio: 1.0, child: cellBody)`.
  - `_buildSquareLiveGrid`: Wrapped in `AspectRatio(aspectRatio: 1.0)` and used `SizedBox.square(dimension: cellSize)` for cell slots.
- [x] **Task 3: Eliminate Nested Card Redundancy:**
  - `_buildBoardCard`: When `showHeader: false`, returns `content` directly rather than wrapping in a duplicate `Card`.
- [x] **Task 4: Dedicated BINGO Header Background:**
  - `_buildBingoLetterBar`: Added dedicated subtle warm background tint (`AppBranding.warmSurfaceMuted.withValues(alpha: 0.50)` in light mode, `primary.withValues(alpha: 0.10)` in dark mode) with rounded corners and letter chips.
- [x] **Task 5: Calibrate Tile Sizing & Listing:**
  - `_wrapReorderableCell`: Sized every grid tile strictly to `cellWidth x cellHeight`.
- [x] **Task 6: Verification:**
  - `flutter analyze`: Passed with 0 errors, 0 warnings.
  - `cartela_board_square_aspect_ratio_test.dart`: Passed (2/2).
  - `live_cartela_warm_theme_test.dart`: Passed (4/4).
  - `warm_theme_contrast_test.dart`: Passed (6/6).
