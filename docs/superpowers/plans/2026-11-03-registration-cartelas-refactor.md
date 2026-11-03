# Registration Cartelas Decoupling & Reusability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the open registration live screen cartelas presentation by decoupling the monolithic grid/list into a standalone `RegistrationCartelaCard` and `RegistrationCartelaListContainer`, while resolving all `flutter analyze` deprecations and warnings.

**Architecture:** Extract two decoupled, reusable presentation components: a standalone `RegistrationCartelaCard` representing an individual cartela card with its visual states (availability, reserved hold timer, selection badge) and a `RegistrationCartelaListContainer` managing the scrollable viewport, search filtering, empty states, and selection integration. Clean up deprecated Flutter 3.47 APIs (`scrollCacheExtent`) and analyzer warnings.

**Tech Stack:** Flutter 3.47+, Dart 3.13+, Flutter Riverpod, Material 3.

---

### Task 1: Fix Existing `flutter analyze` Deprecations & Warnings

**Files:**
- Modify: `lib/src/features/games/cartelas/presentation/widgets/live_cartela_viewport.dart:80`
- Modify: `lib/src/features/games/registration/presentation/widgets/registration_cartela_grid.dart:18`
- Modify: `test/features/games/post_game_summary_dialog_hold_test.dart:125`
- Modify: `test/features/games/bingo_lock_claim_resolver_test.dart`
- Modify: `test/features/games/live_cartela_one_away_pulse_test.dart`

- [ ] **Step 1: Replace deprecated `cacheExtent` with `scrollCacheExtent` in `live_cartela_viewport.dart`**
- [ ] **Step 2: Remove unused import in `registration_cartela_grid.dart`**
- [ ] **Step 3: Remove unused variable `advanceRuns` in `post_game_summary_dialog_hold_test.dart`**
- [ ] **Step 4: Remove unused import and simplify underscores in test files**
- [ ] **Step 5: Run `flutter analyze` to verify the 10 issues are resolved**
- [ ] **Step 6: Commit changes**

---

### Task 2: Create Standalone `RegistrationCartelaCard` Widget

**Files:**
- Create: `lib/src/features/games/registration/presentation/widgets/registration_cartela_card.dart`
- Create: `test/features/games/registration_cartela_card_test.dart`

**Interfaces:**
- Produces: `RegistrationCartelaCard` stateless/lightweight widget accepting:
  - `cartelaNumber`: `int`
  - `availability`: `CartelaAvailability`
  - `isMine`: `bool`
  - `isReservedByMe`: `bool`
  - `isReservedByOther`: `bool`
  - `isRegisteredByOther`: `bool`
  - `isBlocked`: `bool`
  - `isSelected`: `bool`
  - `selectModeEnabled`: `bool`
  - `onTap`: `VoidCallback?`
  - `onLongPress`: `VoidCallback?`

- [ ] **Step 1: Write widget test for `RegistrationCartelaCard` covering available, selected, reserved, and registered states**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement `RegistrationCartelaCard` with `RepaintBoundary`, proper styling, badges, and tap feedback**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit changes**

---

### Task 3: Create Standalone `RegistrationCartelaListContainer` Widget

**Files:**
- Create: `lib/src/features/games/registration/presentation/widgets/registration_cartela_list_container.dart`
- Create: `test/features/games/registration_cartela_list_container_test.dart`

**Interfaces:**
- Produces: `RegistrationCartelaListContainer` widget accepting:
  - `items`: `List<CartelaModel>`
  - `itemBuilder`: `Widget Function(BuildContext, CartelaModel)`
  - `searchQuery`: `String`
  - `isLoading`: `bool`
  - `error`: `Object?`
  - `emptyMessage`: `String?`
  - `header`: `Widget?`
  - `footer`: `Widget?`
  - `padding`: `EdgeInsetsGeometry`

- [ ] **Step 1: Write widget test for `RegistrationCartelaListContainer` testing empty, loading, error, and list items rendering**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement `RegistrationCartelaListContainer` with scroll isolation and performance optimizations**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit changes**

---

### Task 4: Integrate `RegistrationCartelaCard` into `RegistrationCartelaGrid`

**Files:**
- Modify: `lib/src/features/games/registration/presentation/widgets/registration_cartela_grid.dart`

- [ ] **Step 1: Update `RegistrationCartelaGridCell` to delegate its UI rendering to `RegistrationCartelaCard`**
- [ ] **Step 2: Run existing registration grid tests to verify backwards compatibility**
- [ ] **Step 3: Commit changes**

---

### Task 5: End-to-End Verification & Analyzer Pass

- [ ] **Step 1: Run `flutter analyze` ensuring 0 warnings/errors**
- [ ] **Step 2: Run `flutter test` across all game test suites**
- [ ] **Step 3: Commit all changes**

