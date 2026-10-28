# Friends Bingo Mobile UI Cleanup & Alignment Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Friends Bingo mobile game UI into a clean, aligned, visually balanced, and premium gaming experience through subtle architectural and styling refinements without altering socket or game logic.

**Architecture:** 
1. Rationalize spacing tokens to a true 8-point grid in [`app_spacing.dart`](file:///d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/core/theme/app_spacing.dart) and harmonize the color system (60/30/10).
2. Consolidate stacking sticky banners into a single cohesive game status strip in [`live_game_views.dart`](file:///d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/presentation/screens/live_game_views.dart).
3. Refine the called numbers tray layout and edge masking in [`called_numbers_strip.dart`](file:///d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/presentation/widgets/called_numbers_strip.dart).
4. De-clutter and align the live cartela card headers and grid numbers in [`live_cartela_card.dart`](file:///d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/cartelas/presentation/widgets/live_cartela_card.dart) and [`cartela_board_widget.dart`](file:///d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/cartelas/presentation/widgets/cartela_board_widget.dart).
5. Clean up the top shell app bar action cluster in [`app_shell_app_bar.dart`](file:///d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/home/presentation/widgets/app_shell_app_bar.dart).

**Tech Stack:** Flutter / Dart, Riverpod, Material 3, Custom Painters.

## Global Constraints
- Do NOT alter realtime socket controllers, game state transitions, or claim verification logic.
- Keep touch targets >= 44×44pt on mobile.
- All spacing must be multiples of 4 or 8 (8-point grid).
- Maintain high contrast and dark/light mode compatibility.

---

### Task 1: Strict 8-Point Grid Spacing & Typography Alignment

**Files:**
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/core/theme/app_spacing.dart`
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/core/theme/app_theme.dart`

**Interfaces:**
- Consumes: Flutter standard layout constants
- Produces: Normalized `AppSpacing` tokens (4, 8, 12, 16, 24, 32) eliminating sub-pixel 6/10 oddities

- [ ] **Step 1: Normalize Spacing Tokens in `app_spacing.dart`**
Align all tokens to 4/8 multiples:
```dart
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;     // was 6
  static const double md = 8;
  static const double lg = 12;    // was 10
  static const double xl = 12;
  static const double xxl = 16;
  static const double xxxl = 24;  // was 20
  static const double jumbo = 32; // was 24

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: xxl, vertical: sm);
  static const EdgeInsets screenPaddingDense = EdgeInsets.all(sm);
  static const EdgeInsets cardPadding = EdgeInsets.all(xxl);
  static const EdgeInsets cardPaddingDense = EdgeInsets.all(xl);
}
```

- [ ] **Step 2: Enforce Tabular Figures for Numbers in `app_theme.dart`**
Add `FontFeature.tabularFigures()` to `textTheme.bodyMedium`, `textTheme.titleMedium`, and `textTheme.headlineSmall` so numerical counters (called numbers, countdowns, balances, cartela cells) remain stably aligned without digit jitter.

- [ ] **Step 3: Verify build**
Run: `flutter analyze lib/src/core/theme/app_spacing.dart`
Expected: 0 errors.

---

### Task 2: Simplify Top Shell App Bar Actions

**Files:**
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/home/presentation/widgets/app_shell_app_bar.dart`

**Interfaces:**
- Consumes: `authControllerProvider`, `realtimeConnectionProvider`
- Produces: Streamlined app bar actions with balanced visual breathing room

- [ ] **Step 1: Reduce Right-Hand Icon Cluster in `AppShellAppBar`**
Currently, the right side packs 4 action icons: Refresh Button, ConnectionStatusDot, Broadcast Bell, Feedback speech bubble.
Consolidate the Connection Status into a subtle status pill beside the title or balance, and integrate the refresh indicator cleanly:
```dart
actions: [
  _MasterRefreshButton(headerForeground: headerForeground),
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    child: ConnectionStatusDot(
      status: switch (ref.watch(realtimeConnectionProvider)) {
        LiveConnectionStatus.live => LiveConnectionState.online,
        LiveConnectionStatus.reconnecting => LiveConnectionState.reconnecting,
        LiveConnectionStatus.offline => LiveConnectionState.offline,
      },
      theme: theme,
    ),
  ),
  if (!isGuest && !ref.watch(hasActiveForcedBroadcastProvider))
    _BroadcastMessageButton(headerForeground: headerForeground),
  const SizedBox(width: AppSpacing.xs),
]
```

- [ ] **Step 2: Verify App Bar formatting**
Run: `flutter analyze lib/src/features/home/presentation/widgets/app_shell_app_bar.dart`
Expected: 0 errors.

---

### Task 3: Streamline Called Numbers Strip & Edge Mask

**Files:**
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/presentation/widgets/called_numbers_strip.dart`

**Interfaces:**
- Consumes: `CalledNumberModel`, `recentCalls`
- Produces: Visually centered, edge-scrimmed ball tray with no cut-off balls

- [ ] **Step 1: Remove Redundant Connection Dot & Duplicate Refresh from `_CollapsedCallHeader`**
In `called_numbers_strip.dart`, remove the internal `ConnectionStatusDot` and `_CalledNumbersRefreshButton` since they are already present in the sticky app bar.

- [ ] **Step 2: Add Smooth Fade Mask to Recent Calls Shelf**
Wrap the horizontal `ListView.separated` of `recentCalls` in a `ShaderMask` with a linear gradient fade at the right edge, so balls smoothly fade in as they roll from the draw machine instead of abruptly clipping:
```dart
ShaderMask(
  shaderCallback: (Rect bounds) {
    return const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.black, Colors.black, Colors.black, Colors.transparent],
      stops: [0.0, 0.75, 0.92, 1.0],
    ).createShader(bounds);
  },
  blendMode: BlendMode.dstIn,
  child: ListView.separated(...),
)
```

- [ ] **Step 3: Align Ball Heights & Shadows**
Ensure latest ball (64px) and previous balls (44px) are vertically centered along a unified baseline with soft ambient gold glow (`Color(0xFFF5C542).withValues(alpha: 0.25)`).

- [ ] **Step 4: Verify Called Numbers Strip**
Run: `flutter analyze lib/src/features/games/presentation/widgets/called_numbers_strip.dart`
Expected: 0 errors.

---

### Task 4: Harmonize Cartela Card Headers & Grid Cell Typography

**Files:**
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/cartelas/presentation/widgets/live_cartela_card.dart`
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/cartelas/presentation/widgets/cartela_board_widget.dart`
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/cartelas/domain/cartela_board_layout.dart`

**Interfaces:**
- Consumes: `GameCartelaModel`, `CartelaBoardLayout`
- Produces: Elegant, non-distracting 5×5 cartela grid with balanced dauber marks

- [ ] **Step 1: Simplify Card Header in `LiveCartelaCard`**
Remove competing saturated gradients for inactive cartelas. Keep a clean, tinted obsidian header:
- Left: Cartela # Badge in a soft circle chip.
- Center: Status or BINGO claim button.
- Right: Subtle dauber color indicator icon (20px).
Standardize header padding to `EdgeInsets.symmetric(horizontal: 8, vertical: 6)`.

- [ ] **Step 2: Tone Down Rainbow B-I-N-G-O Letter Header Bar**
In `cartela_board_widget.dart` (`_buildBingoLetterBar`), replace harsh 100% saturated primary colors with elegant tonal badges using 85% opacity on dark backgrounds, with subtle column dividers.

- [ ] **Step 3: Increase Legibility of Cell Numbers**
In `cartela_board_layout.dart`:
Set `liveExpandedCellNumberFactor = 0.54` and add letter-spacing `0.2` with `FontWeight.w700` so numbers like `11`, `19`, `72` are crisp, centered, and easy to read during rapid live calls.

- [ ] **Step 4: Verify Cartela Component compilation**
Run: `flutter analyze lib/src/features/games/cartelas/presentation/widgets/`
Expected: 0 errors.

---

### Task 5: Consolidate Sticky Banners into Single Status Command Strip

**Files:**
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/presentation/screens/live_game_views.dart`
- Modify: `d:/FILES/SELF/BINGO/friends-bingo-mobile/lib/src/features/games/presentation/widgets/collapsible_live_top_section.dart`

**Interfaces:**
- Consumes: `GameModel`, `LivePresentationPhase`
- Produces: Compact, single-surface game status banner preventing header bloat

- [ ] **Step 1: Unify Banners in `_buildStickyLiveHeader()`**
Rather than rendering `_buildLiveStatusBanner()`, `_buildChainGameInfoStrip()`, `_buildChainInterRoundSummaryBanner()`, and `_buildPostGameSummaryBanner()` as 4 separate stacked cards with individual borders and vertical margins:
Combine them into a single contextual status strip using an `AnimatedSwitcher` to transition states smoothly.
This immediately recovers 80–120dp of vertical viewport height, bringing the player's cartelas directly into the primary thumb zone.

- [ ] **Step 2: Verify Live Game Views**
Run: `flutter analyze lib/src/features/games/presentation/screens/live_game_views.dart`
Expected: 0 errors.
