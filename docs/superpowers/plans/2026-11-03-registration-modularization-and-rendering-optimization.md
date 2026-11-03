# Registration Modularization and Grid Rendering Optimization Implementation Plan

## Goal
1. **Optimize Cartela Grid Rendering Performance**:
   - Eliminate per-cell `Timer.periodic` instances by implementing a centralized countdown ticker.
   - Replace blunt InheritedWidget mass-invalidation in `RegistrationGridScope` with fine-grained aspect dependency via `InheritedModel<String>`, ensuring only affected cartelas rebuild on lock/hold/selection updates.
   - Optimize and minimize Riverpod subscription evaluations per grid cell.
2. **Modularize Game Registration**:
   - Extract `RegistrationCatalogControls` into a standalone reusable widget (Search bar, reshuffle, select mode toggle, bonus badges).
   - Create a decoupled composite `CartelaRegistrationView` that combines controls, catalog grid, and action dock, allowing it to be used standalone or embedded in live games.
   - Create a dedicated `GameRegistrationScreen` route.

---

## Tasks

### Task 1: Centralized Countdown Ticker & `InheritedModel<String>` in `RegistrationGridScope`
- Convert `RegistrationGridScope` to an `InheritedModel<String>`.
- Implement `updateShouldNotifyDependent` checking aspect (cartela ID) for hold, locked, selection, and pending changes.
- Add centralized `countdownTicker` in `RegistrationGridScope`.
- Refactor `_RegistrationCartelaGridCellState` to remove its internal `Timer.periodic`, listening instead to the centralized countdown ticker only when a reservation countdown is active.

### Task 2: Standalone `RegistrationCatalogControls` Component
- Create `lib/src/features/games/registration/presentation/widgets/registration_catalog_controls.dart`.
- Decouple from `live_game_registration.dart` private methods, taking clean callbacks (`onSearchChanged`, `onReshuffle`, `onSelectModeChanged`, etc.).
- Add unit test for `RegistrationCatalogControls`.

### Task 3: Composite `CartelaRegistrationView` and Standalone `GameRegistrationScreen`
- Create `lib/src/features/games/registration/presentation/widgets/cartela_registration_view.dart`.
- Create `lib/src/features/games/presentation/screens/game_registration_screen.dart`.
- Integrate into `_CartelaRegistrationPanel` in `live_game_registration.dart`.
- Add widget tests for `CartelaRegistrationView` and `GameRegistrationScreen`.

### Task 4: Full Verification & Benchmarking
- Run `flutter analyze` ensuring 0 issues.
- Run the full test suite (`flutter test test/features/games/`).
- Commit using Conventional Commits.

