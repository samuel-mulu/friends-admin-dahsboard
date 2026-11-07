# Smooth Warm Live Playing Game Screen & Cartelas Enhancement Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Friends Bingo mobile **Live Game Screen** (specifically the **Live Cartelas**, Board Grid, Called Numbers Strip, and Game Header) from eye-straining pure white into a soothing, casino-lounge warm palette ("Warm Amber & Emerald Lounge") inspired by the reference screenshot, without modifying the registration open / cartela registration flows.

**Architecture:**
1. Scope changes strictly to the Live Game experience and its core rendering components: `LiveCartelaCard`, `CartelaBoardWidget`, `CalledNumbersStrip`, `BingoBallBadge`, and the live play header in `live_game_views.dart`.
2. Enhance `AppBranding` and live theme tokens to replace stark `Colors.white` on live cards with warm ivory (`#FAF8F5`), soothing linen scaffolds (`#EDE7DD`), warm amber BINGO claim buttons (`#E8C86A`), and rich emerald green daub marks (`#22A45D`).
3. Retain complete stability and zero changes for all registration open widgets (`cartela_registration_sheet.dart`, `registration_open_pulse.dart`, `registration_cartela_card.dart`, `registration_catalog_controls.dart`).
4. Inject purposeful micro-delights (tactile dauber pop, glowing latest-ball pulse, warm sheen on BINGO button, red winning pattern outline).

**Tech Stack:** Flutter 3.47+, Dart 3.13+, Flutter Riverpod, Material 3.

## Global Constraints
- **Scope Restriction**: DO NOT TOUCH cartela registration (open registration, registration sheets, catalog controls, or reservation modals).
- **Zero White Glare on Live Play**: Eliminate raw `Colors.white` on live cartela cards, boards, and live scaffold in light mode.
- **WCAG AA Contrast**: Maintain at least 4.5:1 contrast for text numbers (deep purple/eggplant `#2A1845` on ivory cells, bold white on emerald dauber marks).
- **60 FPS Performance**: Fast scrolling across multiple live cartelas without frame drops; keep animations paused when `decorativeMotionAllowedListenable` is false.
- **Zero Business Logic Regressions**: Preserve all existing claim coordination, auto-daub, pattern check, and websocket handling.

---

### Task 1: "Warm Amber & Emerald Lounge" Live Palette Tokens in `AppBranding`

**Files:**
- Modify: `lib/src/core/theme/app_branding.dart`
- Test: `test/core/theme/warm_theme_contrast_test.dart`

**Interfaces:**
- Produces:
  - `AppBranding.warmScaffold` (`Color(0xFFEDE7DD)`)
  - `AppBranding.warmSurface` (`Color(0xFFF5EFE6)`)
  - `AppBranding.warmSurfaceRaised` (`Color(0xFFFAF7F2)`)
  - `AppBranding.warmSurfaceMuted` (`Color(0xFFE5DEC9)`)
  - `AppBranding.warmOutline` (`Color(0xFFD6CCA9)`)
  - `AppBranding.warmOnSurface` (`Color(0xFF2B0A57)`)
  - `AppBranding.warmOnSurfaceMuted` (`Color(0xFF5E566D)`)
  - `AppBranding.bingoGoldButton` (`Color(0xFFE8C86A)`)
  - `AppBranding.bingoGoldButtonText` (`Color(0xFF3B2205)`)
  - `AppBranding.emeraldDaubFill` (`Color(0xFF22A45D)`)
  - `AppBranding.emeraldDaubBorder` (`Color(0xFF1B874B)`)
  - Updated `AppBranding.cellBackground()` returning `#FFFFFF` with warm border on `#FAF8F5` card instead of glaring white-on-white.
  - Updated `AppBranding.cellForeground()` returning deep purple `#2A1845` for crisp readability.

- [ ] **Step 1: Write test verifying WCAG AA contrast for live cartela colors**
- [ ] **Step 2: Add warm palette tokens and update live surface helpers in `app_branding.dart`**
- [ ] **Step 3: Run test to verify contrast passes**
- [ ] **Step 4: Commit changes**

---

### Task 2: Live Cartela Card & Header Redesign (`live_cartela_card.dart`)

**Files:**
- Modify: `lib/src/features/games/cartelas/presentation/widgets/live_cartela_card.dart`
- Test: `test/features/games/cartelas/presentation/live_cartela_card_warm_test.dart`

**Interfaces:**
- Produces:
  - `LiveCartelaCard` surface: warm off-white / ivory card (`#FAF8F5`) with 16px corner radius and soft warm tinted shadow (`BoxShadow(color: Color(0x122B0A57), blurRadius: 10, offset: Offset(0, 3))`).
  - Cartela Header Bar:
    - Cartela ID Chip: Deep royal purple capsule (`#3A1859`) with bold white number (`1074`, `3801`).
    - BINGO Button: Golden amber pill button (`#E8C86A`) with bold dark brown text (`#3B2205`), subtle 3D rim, and ready pulse sheen when a winning pattern is achieved.
    - Status Indicator: Vibrant emerald green dot + dropdown icon.
    - Blocked/Winner states handled cleanly with smooth color transitions.

- [ ] **Step 1: Write widget test verifying `LiveCartelaCard` applies the warm card styling, cartela ID badge, and golden BINGO button**
- [ ] **Step 2: Run test to confirm it fails or tests the new visual tokens**
- [ ] **Step 3: Implement the warm card surface and header visual elements in `live_cartela_card.dart`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit changes**

---

### Task 3: Cartela Board 5x5 Grid & Tactile Emerald Dauber Cells (`cartela_board_widget.dart` & `cartela_mark_color.dart`)

**Files:**
- Modify: `lib/src/features/games/cartelas/presentation/widgets/cartela_board_widget.dart`
- Modify: `lib/src/features/games/cartelas/domain/cartela_mark_color.dart`
- Test: `test/features/games/cartelas/presentation/cartela_board_widget_warm_test.dart`

**Interfaces:**
- Produces:
  - B-I-N-G-O column letter bar:
    - B: Vibrant Blue (`#1E88E5`)
    - I: Coral Red (`#E53935`)
    - N: Emerald Green (`#2E7D32`)
    - G: Majestic Purple (`#8E24AA`)
    - O: Warm Amber (`#FB8C00`)
  - 5x5 Grid Cell Tiles:
    - **Unmarked Tiles**: Smooth ivory rounded tiles (`#FFFFFF`) sitting on warm grid surface with subtle outline (`#E5DEC9`), dark purple numbers (`#2A1845`).
    - **Marked Tiles (Default Green)**: Rich, tactile emerald green tiles (`#22A45D` gradient to `#1B874B`) with crisp bold white numbers.
    - **FREE Center Space**: Emerald green tile with white "FREE" text.
    - **Winning Pattern Highlight**: Smooth red rounded outline (`#E53935`, 2px) framing the winning pattern cells as shown in the reference.
    - **Daub Pop Animation**: Subtle micro-scale spring effect (`1.0` -> `1.12` -> `1.0` in 160ms) on cell mark toggle.

- [ ] **Step 1: Write widget test for `CartelaBoardWidget` verifying cell colors, B-I-N-G-O letters, and mark styling**
- [ ] **Step 2: Update `CartelaMarkColorPalette.forColor(CartelaMarkColor.green)` with rich emerald gradient and shadow**
- [ ] **Step 3: Update `cartela_board_widget.dart` with colorful column letters, ivory unmarked cells, emerald marked cells, and winning pattern box**
- [ ] **Step 4: Run widget tests to verify rendering passes**
- [ ] **Step 5: Commit changes**

---

### Task 4: Called Numbers Strip & 3D Bingo Balls Polish (`called_numbers_strip.dart` & `bingo_ball_badge.dart`)

**Files:**
- Modify: `lib/src/features/games/presentation/widgets/called_numbers_strip.dart`
- Modify: `lib/src/features/games/presentation/components/bingo_ball_badge.dart`
- Test: `test/features/games/presentation/called_numbers_strip_warm_test.dart`

**Interfaces:**
- Produces:
  - Container: Smooth rounded warm sand pill (`#EFECE4`) with soft borders and subtle shadow.
  - Latest Called Ball:
    - 52px diameter golden glowing orb (`#F5C542` to `#E8A217`) with radiant amber ring and deep indigo text.
  - History Balls:
    - 42px diameter glossy 3D spheres: B (Red `#E53935`), I (Amber `#FB8C00`), N (Blue `#1E88E5`), G (Green `#43A047`), O (Purple `#8E24AA`).
  - Blocked Cartelas Chips:
    - "Blocked cartela=" label with soft pastel coral pills (`#FEE2E2` fill, `#FCA5A5` border, `#DC2626` text) matching the screenshot (`204`, `9700`, `9998`).

- [ ] **Step 1: Write widget test for `CalledNumbersStrip` warm styling and ball presentation**
- [ ] **Step 2: Update `BingoBallBadge` and `CalledNumbersStrip` with warm capsule container, 3D spheres, and coral chips**
- [ ] **Step 3: Run test to verify it passes**
- [ ] **Step 4: Commit changes**

---

### Task 5: Live Game Screen Sticky Header & Status Integration (`live_game_views.dart`)

**Files:**
- Modify: `lib/src/features/games/presentation/screens/live_game_views.dart`
- Modify: `lib/src/features/games/presentation/widgets/live_status_chip.dart`
- Test: `test/features/games/presentation/live_game_header_warm_test.dart`

**Interfaces:**
- Produces:
  - Sticky Live Play Header:
    - Two-compartment warm cream card (`#FAF7F2`):
      - Left: "አሁን ይጫወታል" + info icon + rule name ("1 አራት ማዕዘን").
      - Right: "ሽልማት 3000 ETB" + "ምዝ 24".
      - Sub-row: Golden star badge "★ Normal Game" (`#FFF3D6`), fee & fixed prize chips.
    - Status Bar: "ተጫሯል:- 31", soft mint "Online" pill (`#E1F5EC`), and refresh action.

- [ ] **Step 1: Write test for the Live Game sticky header structure and styling**
- [ ] **Step 2: Implement the two-compartment lounge info card in `live_game_views.dart`**
- [ ] **Step 3: Update `LiveStatusChip` with soft mint pill styling (`#E1F5EC` fill, `#1E8E5A` text/dot)**
- [ ] **Step 4: Verify test passes and layout renders seamlessly on mobile viewports**
- [ ] **Step 5: Commit changes**

---

### Task 6: Reality Check, Contrast Verification & Performance Audit (`agency-reality-checker`)

**Files:**
- All modified live game files

**Verification Criteria:**
- `flutter analyze` runs with 0 errors and 0 warnings.
- All existing and new widget tests pass.
- Open registration files remain untouched (`git status` confirms zero modifications in `registration/presentation/widgets/`).
- WCAG AA contrast ratio verified ($\ge 4.5:1$ on text, $\ge 3:1$ on graphical UI elements).
- Smooth 60 FPS scrolling maintained across multi-cartela viewport.

- [ ] **Step 1: Run `flutter analyze` on modified paths**
- [ ] **Step 2: Run all game and cartela widget tests**
- [ ] **Step 3: Verify visual alignment against benchmark screenshot**
- [ ] **Step 4: Commit and report results**
